extends PathFollow2D
class_name Troops

var team: String
var amount: int
var path_id: int
var starting_point: int
var is_hidden: bool
var road_manager: RoadManager

func _ready() -> void:
	%Area2D.area_entered.connect(_check_merge_troops)

func _check_merge_troops(area: Area2D) -> void:
	var troops: Troops = area.get_parent()
	
	if road_manager.active_paths[path_id] != road_manager.active_paths[troops.path_id]:
		return
	
	if is_multiplayer_authority() and amount > troops.amount:
		_merge_troops.rpc(amount + troops.amount)
		troops.get_merged.rpc(troops.path_id)

@rpc("authority", "call_local", "unreliable_ordered")
func _merge_troops(merge_amount: int) -> void:
	amount = merge_amount
	
	var circle_scale_amount: float = 10 + (amount * 0.005)
	scale = Vector2(circle_scale_amount, circle_scale_amount)
	
	%TextMesh.mesh.text = str(amount)

@rpc("authority", "call_local", "unreliable_ordered")
func get_merged(merged_troop_path_id: int) -> void:
	road_manager.active_paths.erase(merged_troop_path_id)
	queue_free()

func display_and_move_along_path(curr_team: String, curr_amount: int, curr_path_id: int, curr_starting_point: int, curr_is_hidden: bool, curr_road_manager: RoadManager) -> void:
	team = curr_team
	amount = curr_amount
	path_id = curr_path_id
	starting_point = curr_starting_point
	is_hidden = curr_is_hidden
	road_manager = curr_road_manager
	
	var circle_scale_amount: float = 10 + (amount * 0.005)
	scale = Vector2(circle_scale_amount, circle_scale_amount)
	
	%TextMesh.mesh.text = str(amount)
	
	%MeshInstance2D.modulate = City.TEAM_COLORS[team]
	
	if is_hidden:
		hide()
	
	if starting_point == 1:
		progress_ratio = 1

func _process(delta: float) -> void:
	if starting_point == 1:
		if progress_ratio == 0:
				road_manager._travel_along_path(team, amount, path_id)
				queue_free()
				return
		
		progress_ratio -= (delta / (1 + log(amount)))# * 0.01))
		
	else:
		if progress_ratio == 1:
			road_manager._travel_along_path(team, amount, path_id)
			queue_free()
			return
		
		progress_ratio += (delta / (1 + log(amount)))# * 0.01))
