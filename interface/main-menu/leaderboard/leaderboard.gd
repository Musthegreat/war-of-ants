extends MarginContainer

@onready var back: Button = $VBoxContainer/Back

var current_handle: int = 0
var leaderboard_handles: Dictionary[StringName, int] = {
	"leaderboard1_api_name": 0,
	"leaderboard2_api_name": 0,
	"leaderboard3_api_name": 0,
}

func _ready() -> void:
	Steam.findLeaderboard("Wins Leaderboard")
	
	%Screens.tab_changed.connect(
		func(tab: int):
			if tab != 3:
				return
			
			_refresh_leaderboard()
	)
	
	back.pressed.connect(
		func():
			%Screens.current_tab = 0
	)
	
	Steam.avatar_loaded.connect(_on_avatar_loaded)
	Steam.leaderboard_find_result.connect(_on_leaderboard_find_result)
	Steam.leaderboard_score_uploaded.connect(_on_leaderboard_score_uploaded)
	Steam.leaderboard_scores_downloaded.connect(_on_leaderboard_scores_downloaded)

func _refresh_leaderboard() -> void:
	pass

func _on_avatar_loaded(avatar_id: int, size: int, data: Array) -> void:
	pass

func _on_leaderboard_find_result(leaderboard_handle: int, found: int) -> void:
	if found != 1:
		print("Leaderboard handle could not be found: ", found)
		return
	
	current_handle = leaderboard_handle
	 
	var api_name: String = Steam.getLeaderboardName(leaderboard_handle)
	leaderboard_handles[api_name] = current_handle
	
	print("Leaderboard %s handle found: %s" % [api_name, current_handle])

func _on_leaderboard_score_uploaded(success: bool, this_handle: int, this_score: Dictionary) -> void:
	pass

func _on_leaderboard_scores_downloaded(message: String, leaderboard_handle: int, leaderboard_entries: Array) -> void:
	pass
