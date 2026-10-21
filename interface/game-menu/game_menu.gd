extends Control
class_name GameMenu

signal game_started

@onready var city_manager: CityManager = $"../../CityManager"

func _ready() -> void:
	%StartGame.pressed.connect(
		func():
			%StartGame.hide()
			game_started.emit()
	)

func _process(_delta: float) -> void:
	update_troops()

func show_start_game_button() -> void:
	%Status.hide()
	%StartGame.show()

func update_status_to_ready() -> void:
	%Status.text = "Waiting for host to start the game..."

func update_troops() -> void:
	var total_amount: int = 0
	
	for city: City in city_manager.city_selections:
		total_amount += city.data.troops
	
	if total_amount != 0:
		%TranslatedAmountMax.text = str(total_amount)
	else:
		%TranslatedAmountMax.text = "Select Troops"

func update_player_board() -> void:
	%Status.hide()
	%TeamList.clear()
	
	for team in Variables.game.players.keys():
		if Variables.game.players[team].is_empty():
			continue
		
		%TeamList.add_item(team + ": " + str(city_manager.cities_by_team[team].size()) + " cities", null, false)

func change_team_color(team: String) -> void:
	if team == "spectator":
		return
	
	%MoveAmountContainer.self_modulate = City.TEAM_COLORS[team]
	%Small.self_modulate = City.TEAM_COLORS[team]
	%Medium.self_modulate = City.TEAM_COLORS[team]
	%Large.self_modulate = City.TEAM_COLORS[team]
	%Max.self_modulate = City.TEAM_COLORS[team]
