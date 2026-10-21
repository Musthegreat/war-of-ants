extends ItemList
class_name StatsList

var curr_wins: int = 0
var curr_losses: int = 0
var curr_ratio: float = 0.0

func update_stats() -> void:
	clear()
	
	Steam.requestUserStats(Steam.getSteamID())

func _ready() -> void:
	Steam.user_stats_received.connect(_recieved_user_stats)

func _recieved_user_stats(_game_id: int, _result: int, _user_id: int) -> void:
	curr_wins = Steam.getStatInt("wins")
	curr_losses = Steam.getStatInt("loss")
	curr_ratio = Steam.getStatInt("wl_ratio")
	
	add_item("Wins: " + str(curr_wins), null, false)
	add_item("Losses: " + str(curr_losses), null, false)
	add_item("W/L Ratio: " + str(curr_ratio), null, false)
