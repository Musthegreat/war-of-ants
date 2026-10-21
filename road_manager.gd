extends Node2D
class_name RoadManager

@onready var city_manager: CityManager = $"../CityManager"

var active_paths: Dictionary

func begin_travel(team: String, amount: int, path: Array) -> void:
	if !multiplayer.is_server():
		return
	
	var path_id: int = randi()
	_sync_begin_travel.rpc(team, amount, path, path_id)

@rpc("authority", "call_local", "unreliable_ordered")
func _sync_begin_travel(team: String, amount: int, path: Array, path_id: int) -> void:
	active_paths[path_id] = path
	_travel_along_path(team, amount, path_id)

func _travel_along_path(team: String, amount: int, path_id: int) -> void:
	var city_1: int
	var city_2: int
	
	if active_paths[path_id].size() > 1:
		city_1 = active_paths[path_id].pop_front()
		city_2 = active_paths[path_id][0]
	elif active_paths[path_id].size() == 1:
		city_manager.troops_arrived_at_city(team, amount, active_paths[path_id][0])
		return
	
	var road: Road = find_road_by_connection(city_1, city_2)
	
	if road != null:
		road.move_troops(team, amount, path_id, city_1)

func find_road_by_connection(city_uid: int, connection_uid: int) -> Road:
	for road: Road in get_children():
		if road.city_1.uid == city_uid and road.city_2.uid == connection_uid:
			return road
	
	for road: Road in get_children():
		if road.city_2.uid == city_uid and road.city_1.uid == connection_uid:
			return road
	
	return null
