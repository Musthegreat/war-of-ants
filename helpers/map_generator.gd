extends RefCounted
class_name MapGenerator

enum SIZE {
	small,
	medium,
	large,
	x_large
}

enum AMOUNT {
	min,
	medium,
	max,
	insane
}

enum CONNECTIONS {
	min,
	medium,
	max,
	insane
}

static func resolve_settings(map_size: SIZE, city_connection_amount: CONNECTIONS, city_spawn_amount: AMOUNT) -> Dictionary:
	var grid_size: int
	var connection_amount: float
	var spawn_amount: float
	match map_size:
		SIZE.small:
			grid_size = 12
		SIZE.medium:
			grid_size = 16
		SIZE.large:
			grid_size = 22
		SIZE.x_large:
			grid_size = 32
	
	match city_spawn_amount:
		AMOUNT.min:
			spawn_amount = 0.6
		AMOUNT.medium:
			spawn_amount = 0.4
		AMOUNT.max:
			spawn_amount = 0.3
		AMOUNT.insane:
			spawn_amount = 0.2
	
	match city_connection_amount:
		CONNECTIONS.min:
			connection_amount = 3
		CONNECTIONS.medium:
			connection_amount = 4
		CONNECTIONS.max:
			connection_amount = 6
		CONNECTIONS.insane:
			connection_amount = 10
	
	return {
		"grid_size": grid_size,
		"spawn_amount": spawn_amount,
		"connection_amount": connection_amount
	}

static func generate_map(map_size: SIZE, city_connection_amount: CONNECTIONS, city_spawn_amount: AMOUNT) -> Map:
	var resolved_settings = resolve_settings(map_size, city_connection_amount, city_spawn_amount)
	
	var grid_size: int = resolved_settings.grid_size
	var connection_amount: float = resolved_settings.connection_amount
	var spawn_amount: float = resolved_settings.spawn_amount
	
	var map := Map.new()
	var temp_map: Array
	
	# create a grid that is sparsly populated with cities
	for x in grid_size:
		var row: Array
		row.resize(grid_size)
		for y in grid_size:
			var chance: float = randf_range(0, 1)
			
			if chance > spawn_amount:
				var new_city := Map.new_city()
				new_city.position = Vector2(x, y)
				new_city.jitter = Vector2(randf_range(0.2, 0.8), randf_range(0.2, 0.8))
				
				row[y] = new_city
			else:
				continue
		
		map.cities.append(row)
		temp_map.append(row)
	
	# draw connections between cities
	for row in temp_map.size():
		for column in temp_map[row].size():
			var search_distance: int = 1
			var search_complete: bool = false
			
			while search_complete == false:
				for neighbor_x in range(-search_distance, search_distance):
					for neighbor_y in range(-search_distance, search_distance):
						var index := Vector2i(clamp(row + neighbor_x, 0, grid_size - 1), clamp(column + neighbor_y, 0, grid_size - 1))
						
						if temp_map[row][column] == null:
							continue
						
						if temp_map[index.x][index.y] == null:
							continue
						
						if index == Vector2i(row, column):
							continue
						
						# check if the connection hasnt been made yet
						if temp_map[index.x][index.y].connections_to.has(temp_map[row][column].uid):
							continue
						
						if temp_map[index.x][index.y].connections_from.has(temp_map[row][column].uid):
							continue
						
						if temp_map[row][column].connections_to.size() + temp_map[row][column].connections_from.size() < connection_amount:
							temp_map[row][column].connections_to.append(temp_map[index.x][index.y].uid)
							temp_map[index.x][index.y].connections_from.append(temp_map[row][column].uid)
							
							search_complete = true
				
				search_distance += 1
				
				if search_distance > grid_size:
					search_complete = true
	
	# remove cities with no connections
	for row in temp_map.size():
		for column in temp_map[row].size():
			if temp_map[row][column] == null:
				map.cities[row][column] = null
				
			elif temp_map[row][column].connections_to.is_empty() and temp_map[row][column].connections_from.is_empty():
				map.cities[row][column] = null
				
			else:
				map.cities[row][column] = temp_map[row][column]
	
	return map
