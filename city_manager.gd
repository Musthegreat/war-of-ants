extends Node2D
class_name CityManager

@onready var input_manager: SelectionManager = $"../InputManager"
@onready var road_manager: RoadManager = $"../RoadManager"
@onready var pathfinding := CustomAStar2D.new()

const ROAD = preload("uid://darqwm76he5cd")
const CITY = preload("uid://cjxxvr2jbidvq")
const MAP_SCALE := Vector2(200, 170)

var cities_by_team: Dictionary = {
	"red": [],
	"blue": [],
	"green": [],
	"yellow": [],
	"orange": [],
	"black": []
}

var spawn_points: Dictionary

var city_selections: Array
var neighboring_cities: Array

func send_troops_by_selection(amount: String, target_city: City) -> void:
	var send_amount: int = -1
	var send_all: bool = false
	
	match amount:
		"send_1":
			send_amount = 50
		"send_2":
			send_amount = 100
		"send_3":
			send_amount = 525
		"send_4":
			send_all = true
	
	for city: City in city_selections:
		if city.data.ownership == Variables.my_team:
			var travel_path: PackedInt64Array
			if Array(city.data.connections_to + city.data.connections_from).has(target_city.data.uid):
				travel_path = [city.data.uid, target_city.data.uid]
				city.send_troops.rpc(send_amount, travel_path, send_all)
			else:
				travel_path = pathfinding.get_id_path(city.data.uid, target_city.data.uid)
				city.send_troops.rpc(send_amount, travel_path, send_all)

func troops_arrived_at_city(team: String, amount: int, city_uid: int) -> void:
	if multiplayer.is_server():
		var city: City = find_city(city_uid)
		
		if city.data.ownership == team:
			city.receieve_troops.rpc(amount)
		else:
			city.begin_combat.rpc(team, amount)

func _new_selection(selected_city: City) -> void:
	city_selections.clear()
	for city: City in get_children():
		city.clear_selection()
	
	city_selections.append(selected_city)
	selected_city.set_selection()

func _additional_selection(selected_city: City) -> void:
	city_selections.append(selected_city)
	selected_city.set_selection()

func clear_selection() -> void:
	city_selections.clear()
	for city: City in get_children():
		city.clear_selection()

func _remove_selection(city: City) -> void:
	city_selections.erase(city)
	city.clear_selection()

func find_city(uid: int) -> City:
	for city: City in get_children():
		if city.data.uid == uid:
			return city
	return null

func find_empty_city() -> int:
	var found_city: bool = false
	var search_retry_limit: int = 12
	var city_uid: int
	while found_city == false:
		var candidate_city: City = get_child(randi_range(0, get_child_count() - 1))
		if search_retry_limit < 0:
			printerr("uh oh stinky... cant find room to pick a spawn point")
			return -1
		
		if candidate_city.data.ownership != "":
			search_retry_limit -= 1
			continue
		
		city_uid = candidate_city.data.uid
		found_city = true
	return city_uid

func set_spawn_points() -> void:
	if !multiplayer.is_server():
		return
	
	for team in Variables.game.players.keys():
		if Variables.game.players[team].is_empty():
			continue
		else:
			if !spawn_points.has(team):
				spawn_points[team] = find_empty_city()
	
	# sync up all spawnpoints and transfer auth
	for team in spawn_points.keys():
		if spawn_points[team] == -1:
			continue
		
		find_city(spawn_points[team]).sync_city.rpc(team, City.TYPE.capital)
	
	organize_cities_by_team.rpc()

@rpc("authority", "call_local", "unreliable")
func organize_cities_by_team() -> void:
	for team in cities_by_team.keys():
		cities_by_team[team].clear()
	
	for city: City in get_children():
		if city.data.ownership != "":
			cities_by_team[city.data.ownership].append(city)
	
	update_pathfinding()
	update_fog_of_war()

func update_pathfinding() -> void:
	if Variables.my_team == "":
		return
	
	# set all cities to 99
	for city: City in get_children():
		pathfinding.set_point_weight_scale(city.data.uid, 99)
	
	for city: City in cities_by_team[Variables.my_team]:
		pathfinding.set_point_weight_scale(city.data.uid, 1)
		
		for connection_uid in city.data.connections_from + city.data.connections_to:
			var connected_city: City = find_city(connection_uid)
			
			if connected_city.data.ownership != Variables.my_team:
				pathfinding.set_point_weight_scale(city.data.uid, 1.1)

func update_fog_of_war() -> void:
	for city: City in get_children():
		city.type_visual.modulate = City.TEAM_COLORS[""]
		city.label.hide()
		city.change_visual(City.TYPE.default)
		city.is_neighbor = false
		city.is_owned = true
	
	var team: String = Variables.my_team
	if team == "":
		for spectator in Variables.game.spectators:
			if multiplayer.get_unique_id() == spectator[0]:
				for city: City in get_children():
					city.type_visual.modulate = City.TEAM_COLORS[city.data.ownership]
					city.label.show()
					city.change_visual(city.data.type)
		return
	
	for city: City in cities_by_team[team]:
		city.type_visual.modulate = City.TEAM_COLORS[team]
		city.label.show()
		city.change_visual(city.data.type)
		city.is_neighbor = false
		
		for neighbor_uid in city.data.connections_to + city.data.connections_from:
			var neighbor: City = find_city(neighbor_uid)
			neighbor.type_visual.modulate = City.TEAM_COLORS[neighbor.data.ownership]
			neighbor.label.show()
			neighbor.change_visual(neighbor.data.type)
			neighbor.is_neighbor = true
			neighbor.is_owned = false
			neighboring_cities.append(neighbor_uid)

func city_tick() -> void:
	for city: City in get_children():
		city.tick()

func build_map() -> void:
	for city in get_children():
		city.queue_free()
	
	for road in road_manager.get_children():
		road.queue_free()
	
	for row: Array in Variables.game.map.cities:
		for city in row:
			if city == null:
				continue
			
			var new_city: City = CITY.instantiate()
			new_city.name = str(city.uid)
			add_child(new_city)
			
			new_city.city_manager = self
			new_city.road_manager = road_manager
			new_city.data = city
			new_city.global_position = (city.position + city.jitter) * MAP_SCALE
			
			new_city.new_selection.connect(_new_selection)
			new_city.additional_selection.connect(_additional_selection)
			new_city.remove_selection.connect(_remove_selection)
			new_city.mouse_entered.connect(input_manager.change_hovered_city)
			new_city.mouse_exited.connect(input_manager.hide_hovered_city)
			
			pathfinding.add_point(city.uid, (city.position) * MAP_SCALE, 1.0)
			
			for UID in city.connections_to:
				var connection: Dictionary = Variables.game.map.find_city_template(UID)
				
				if connection == null or connection.is_empty():
					continue
				
				var new_road: Road = ROAD.instantiate()
				road_manager.add_child(new_road)
				
				new_road.road_manager = road_manager
				new_road.connect_road(city, connection, MAP_SCALE)
	
	for city: City in get_children():
		for connection_uid: int in city.data.connections_to:
			pathfinding.connect_points(city.data.uid, connection_uid)
