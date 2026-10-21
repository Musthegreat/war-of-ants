extends Node2D
class_name Road

@onready var curve: Curve2D = %Path3D.curve

const TROOPS = preload("uid://bmfkv4grbay3w")

enum DIRECTION {
	FORWARD,
	REVERSE
}

var road_manager: RoadManager

var city_1: Dictionary
var city_2: Dictionary
var travelers: Array

func connect_road(city: Dictionary, connection: Dictionary, map_scale: Vector2) -> void:
	city_1 = city
	city_2 = connection
	
	curve.add_point((city_1.position + city_1.jitter) * map_scale + Vector2(40, 40))
	curve.add_point((city_2.position + city_2.jitter) * map_scale + Vector2(40, 40))
	
	%Line2D.add_point((city_1.position + city_1.jitter) * map_scale + Vector2(40, 40))
	%Line2D.add_point((city_2.position + city_2.jitter) * map_scale + Vector2(40, 40))

func move_troops(team: String, amount: int, order_id: int, starting_point_uid: int) -> void:
	var new_troops: Troops = TROOPS.instantiate()
	%Path3D.add_child(new_troops)
	
	var troop_hidden: bool
	if city_1.ownership != Variables.my_team and !road_manager.city_manager.neighboring_cities.has(city_1.uid):
		if city_2.ownership != Variables.my_team and !road_manager.city_manager.neighboring_cities.has(city_2.uid):
			troop_hidden = true
	else:
		troop_hidden = false
	
	if starting_point_uid == city_1.uid:
		new_troops.display_and_move_along_path(team, amount, order_id, 0, troop_hidden, road_manager)
	else:
		new_troops.display_and_move_along_path(team, amount, order_id, 1, troop_hidden, road_manager)
