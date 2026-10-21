extends Node2D
class_name City

signal new_selection(city: City)
signal additional_selection(city: City)
signal remove_selection(city: City)

signal mouse_entered(city: City)
signal mouse_exited()

@onready var type_visual: Node2D = %TypeVisual
@onready var label: RichTextLabel = %Label

const factory_tick_boost: int = 10
const powerplant_tick_boost: int = 20
const capital_tick_boost: int = 20
const fort_defence_boost: int = 10
const artillery_defence_boost: int = 10

const factory_cost: int = 500
const powerplant_cost: int = 2500
const fort_cost: int = 400
const artillery_cost: int = 4000

const TEAM_COLORS: Dictionary = {
	"": Color("787878"),
	"red": Color.RED,
	"blue": Color.BLUE,
	"green": Color.GREEN,
	"yellow": Color.YELLOW,
	"orange": Color.ORANGE,
	"black": Color.BLACK
}

enum TYPE {
	default,
	capital,
	factory,
	powerplant,
	fort,
	artillery
}

var city_manager: CityManager
var road_manager: RoadManager

var is_owned: bool = false
var is_neighbor: bool = false
var is_selected: bool = false
var in_combat: bool = false
var troops_per_tick: int = 0
var defence_boost: int = 0
var troops_against_city: Dictionary[String, int]

var data: Dictionary:
	set(value):
		data = value

@rpc("authority", "call_local", "unreliable_ordered")
func sync_city(team: String, type: TYPE = TYPE.default, troops: int = -1) -> void:
	in_combat = false
	data.ownership = team
	data.type = type
	
	clear_selection()
	
	set_type(type)
	
	type_visual.modulate = TEAM_COLORS[team]
	
	if troops != -1:
		data.troops = troops
		troop_text_visual_goal = troops
	
	if team != "":
		if !Variables.game.players[team].is_empty():
			set_multiplayer_authority(Variables.game.players[team][0][0], true)
	
	if multiplayer.is_server():
		city_manager.organize_cities_by_team.rpc()

func set_type(type: TYPE) -> void:
	change_visual(type)
	
	troops_per_tick = 0
	
	if data.type == TYPE.factory:
		troops_per_tick = factory_tick_boost
	elif data.type == TYPE.capital:
		troops_per_tick = capital_tick_boost
		troop_text_visual_goal = data.troops
	
	if data.type == TYPE.fort:
		defence_boost += fort_defence_boost
	
	for neighbor_uid in data.connections_from + data.connections_to:
		var city: City = city_manager.find_city(neighbor_uid)
		if city.data.ownership != data.ownership:
			continue
		
		if city.data.type == TYPE.powerplant and data.type != TYPE.default:
			troops_per_tick += powerplant_tick_boost
		
		if city.data.type == TYPE.artillery:
			defence_boost += artillery_defence_boost

func change_visual(type: TYPE) -> void:
	for visual in %TypeVisual.get_children():
		visual.hide()
	
	match type:
		TYPE.default:
			%Default.show()
		TYPE.capital:
			%Capital.show()
		TYPE.factory:
			%Factory.show()
		TYPE.powerplant:
			%Powerplant.show()
		TYPE.fort:
			%Fort.show()
		TYPE.artillery:
			%Artillery.show()

func handle_input(event: InputEvent, radius_select: bool) -> void:
	if !is_multiplayer_authority():
		return
	
	if data.ownership == "" or data.ownership == "spectator":
		return
	
	if event.is_action_released("select_city", true) and radius_select:
		additional_selection.emit(self)
		
	elif event.is_action_released("select_city", true) and !radius_select:
		if is_selected:
			remove_selection.emit(self)
		else:
			new_selection.emit(self)
		
	elif event.is_action_released("multi_select_city", true) and radius_select:
		additional_selection.emit(self)
		
	elif event.is_action_released("multi_select_city", true) and !radius_select:
		if is_selected:
			remove_selection.emit(self)
		else:
			additional_selection.emit(self)

func set_selection() -> void:
	is_selected = true
	%Selection.show()

func clear_selection() -> void:
	is_selected = false
	%Selection.hide()

func tick() -> void:
	if in_combat:
		combat_tick()
	else:
		data.troops += troops_per_tick

func combat_tick() -> void:
	var attack_amount: float
	
	troops_against_city[data.ownership] = data.troops
	
	for team in troops_against_city.keys():
		attack_amount = troops_against_city[team] * 0.5
	attack_amount /= troops_against_city.size() + 1
	
	for team in troops_against_city.keys():
		troops_against_city[team] -= 10 + round(attack_amount * (1 + (defence_boost / 100.0)))
		if data.ownership == team:
			data.troops = troops_against_city[team]
	
	var culled_contestants: Dictionary[String, int]
	for team in troops_against_city.keys():
		if troops_against_city[team] <= 0:
			continue
		else:
			culled_contestants[team] = troops_against_city[team]
	
	troops_against_city = culled_contestants
	
	if troops_against_city.size() == 1:
		for winner in troops_against_city.keys():
			sync_city(winner, data.type, troops_against_city[winner])
	else:
		_resolve_combat_label(troops_against_city)

@rpc("authority", "call_local", "unreliable_ordered")
func send_troops(send_amount: int, path: PackedInt64Array, send_all: bool) -> void:
	var troops_to_send: int
	if send_amount >= data.troops or send_all:
		troops_to_send = data.troops
		data.troops = 0
	else:
		troops_to_send = send_amount
		data.troops -= send_amount
	
	if troops_to_send == 0:
		return
	
	road_manager.begin_travel(data.ownership, troops_to_send, Array(path))
	
	troop_text_visual_goal = data.troops

@rpc("any_peer", "call_local", "unreliable_ordered")
func receieve_troops(amount: int) -> void:
	data.troops += amount
	troop_text_visual_goal = data.troops

@rpc("any_peer", "call_local", "unreliable_ordered")
func begin_combat(team: String, amount: int) -> void:
	if troops_against_city.has(team):
		troops_against_city[team] += amount
	else:
		troops_against_city[team] = amount
	in_combat = true

@rpc("authority", "call_local", "unreliable_ordered")
func attempt_upgrade(type: TYPE) -> void:
	if data.type == TYPE.capital:
		return
	
	match type:
		TYPE.factory:
			if data.troops >= factory_cost:
				data.troops -= factory_cost
				data.type = type
				set_type(type)
		TYPE.powerplant:
			if data.troops >= powerplant_cost:
				data.troops -= powerplant_cost
				data.type = type
				set_type(type)
		TYPE.fort:
			if data.troops >= fort_cost:
				data.troops -= fort_cost
				data.type = type
				set_type(type)
		TYPE.artillery:
			if data.troops >= artillery_cost:
				data.troops -= artillery_cost
				data.type = type
				set_type(type)
		_:
			return
	
	troop_text_visual_goal = data.troops

func _ready() -> void:
	%Area2D.mouse_entered.connect(
		func():
			mouse_entered.emit(self)
	)
	%Area2D.mouse_exited.connect(
		func():
			mouse_exited.emit()
	)

var troop_text_visual_goal: float = 0
func _process(_delta: float) -> void:
	troop_text_visual_goal = move_toward(troop_text_visual_goal, data.troops, 0.2)
	if !in_combat:
		%Label.clear()
		if data.ownership == "black":
			%Label.push_outline_color(Color.WHITE)
		else:
			%Label.push_outline_color(Color.BLACK)
		%Label.push_outline_size(4)
		%Label.push_color(TEAM_COLORS[data.ownership])
		%Label.append_text(str(int(round(troop_text_visual_goal))))
		%Label.pop_all()

func _resolve_combat_label(culled_contestants: Dictionary) -> void:
	%Label.clear()
	%Label.push_outline_color(Color.BLACK)
	%Label.push_outline_size(4)
	
	culled_contestants.sort()
	var culled_contestants_keys: Array = culled_contestants.keys()
	culled_contestants_keys.reverse()
	
	for contestants in culled_contestants_keys:
		%Label.push_color(TEAM_COLORS[contestants])
		if %Label.get_parsed_text() == "":
			if contestants == "":
				%Label.append_text("neutral" + ": " + str(culled_contestants[contestants]))
			else:
				%Label.append_text(contestants + ": " + str(culled_contestants[contestants]))
		else:
			if contestants == "":
				%Label.newline()
				%Label.append_text("neutral" + ": " + str(culled_contestants[contestants]))
			else:
				%Label.newline()
				%Label.append_text(contestants + ": " + str(culled_contestants[contestants]))
	
	%Label.pop_all()
