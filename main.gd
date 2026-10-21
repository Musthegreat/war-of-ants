extends Node2D
class_name Main

@onready var city_manager: CityManager = $CityManager
@onready var road_container: Node2D = $RoadManager
@onready var image_texture: ImageTexture = %MiniMap.texture
@onready var network: Network = $network

const MAP_SCALE := Vector2(200, 170)

const CITY = preload("uid://cjxxvr2jbidvq")
const ROAD = preload("uid://darqwm76he5cd")

func _ready() -> void:
	%MainMenu.create_lobby.connect(_host_game)
	%MainMenu.join_lobby.connect(
		func(lobby_id: int):
			if !ProjectSettings.get_setting("steam/initialization/initialize_on_startup"):
					network.join()
					%MainMenu.hide()
					%GameMenu.show()
			else:
				print(lobby_id)
				network.steam_join(lobby_id)
				%MainMenu.hide()
				%GameMenu.show()
	)
	%MainMenu.rebuild_clicked.connect(
		func(game_settings: Dictionary):
			Variables.game.map = MapGenerator.generate_map(game_settings["map_size"], game_settings["road_connections"], game_settings["city_amount"])
			build_map()
	)
	
	Variables.game.map = MapGenerator.generate_map(MapGenerator.SIZE.small, MapGenerator.CONNECTIONS.min, MapGenerator.AMOUNT.min)
	build_map()

func build_map() -> void:
	city_manager.build_map()

func _host_game() -> void:
	%MainMenu.hide()
	%GameMenu.show()
	
	if ProjectSettings.get_setting("steam/initialization/initialize_on_startup"):
		network.steam_host()
	else:
		network.host()
