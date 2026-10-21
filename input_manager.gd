extends Node2D
class_name SelectionManager

@onready var city_manager: CityManager = $"../CityManager"

var multi_select_mode: bool = false

func change_hovered_city(city: City) -> void:
	if !Variables.game.has_game_started or !city.is_neighbor:
		%HoverVisual.hide()
		return
	
	if %HoverVisual.hidden:
		%HoverVisual.show()
	
	%HoverVisual.global_position = city.global_position

func hide_hovered_city() -> void:
	%HoverVisual.hide()

func _process(_delta: float) -> void:
	if multi_select_mode:
		var selection_size: float = %SelectionContainer.global_position.distance_to(get_global_mouse_position())
		%SelectionContainer.scale = Vector2(selection_size, selection_size)

func _unhandled_input(event: InputEvent) -> void:
	if !Variables.game.has_game_started:
		return
	
	if event.is_action_pressed("select_city"):
		multi_select_mode = true
		%SelectionContainer.global_position = get_global_mouse_position()
		
		%OutlineVisual.show()
		
	elif event.is_action_released("select_city") and multi_select_mode:
		multi_select_mode = false
		
		%UpgradePopup.hide()
		%OutlineVisual.hide()
		
		var cities := _check_for_cities()
		
		if cities.is_empty():
			city_manager.clear_selection()
			%SelectionContainer.scale = Vector2.ONE * 10
		
		for city: City in cities:
			#if city.is_selectable:
			if %SelectionContainer.scale >= Vector2.ONE * 10:
				city.handle_input(event, true)
			else:
				city.handle_input(event, false)
		
		%SelectionContainer.scale = Vector2.ONE * 10
		
	elif event.is_action_pressed("upgrade_city"):
		var cities := _check_for_cities()
		
		if cities.size() != 1:
			return
		
		#if !cities[0].is_selectable:
		#	return
		
		city_manager.clear_selection()
		city_manager._additional_selection(cities[0])
		
		%UpgradePopup.show()
		%UpgradePopup.selected_city = cities[0]
	
	elif event.is_action_pressed("send_1"):
		var cities := _check_for_cities()
		
		if cities.size() != 1:
			return
		
		for city: City in cities:
			#if city.is_selectable:
			city_manager.send_troops_by_selection("send_1", city)
		
	elif event.is_action_pressed("send_2"):
		var cities := _check_for_cities()
		
		if cities.size() != 1:
			return
		
		for city: City in cities:
			#if city.is_selectable:
			city_manager.send_troops_by_selection("send_2", city)
		
	elif event.is_action_pressed("send_3"):
		var cities := _check_for_cities()
		
		if cities.size() != 1:
			return
		
		for city: City in cities:
			#if city.is_selectable:
			city_manager.send_troops_by_selection("send_3", city)
		
	elif event.is_action_pressed("send_4"):
		var cities := _check_for_cities()
		
		if cities.size() != 1:
			return
		
		for city: City in cities:
			#if city.is_selectable:
			city_manager.send_troops_by_selection("send_4", city)

func _check_for_cities() -> Array:
	var cities: Array
	
	%SelectionContainer.global_position = get_global_mouse_position()
	%CircleSelect.force_shapecast_update()
	if %CircleSelect.is_colliding():
		for collision in %CircleSelect.get_collision_count():
			var collider = %CircleSelect.get_collider(collision).get_parent()
			if collider is City:
				if collider.is_owned or collider.is_neighbor:
					cities.append(collider)
	
	return cities
