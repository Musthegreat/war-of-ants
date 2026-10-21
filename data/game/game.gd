extends Resource
class_name Game

var has_game_started: bool = false

var map: Map
var players_required: int = 2
var players: Dictionary = {
	"red": [],
	"blue": [],
	"green": [],
	"yellow": [],
	"orange": [],
	"black": []
}

var spectators: Array

func assign_player_to_team(peer_id: int, steam_id: int = -1) -> void:
	var empty_team: String = find_empty_team()
	if empty_team == "":
		printerr("cant assign player to team, lobby is full")
		return
	
	players[empty_team].append([peer_id, steam_id])

func get_player_count() -> int:
	var count: int = 0
	
	for team in players.keys():
		count += players[team].size()
	
	return count

func check_for_players_required() -> bool:
	if get_player_count() >= players_required:
		return true
	else:
		return false

func find_empty_team() -> String:
	var teams: Array = players.keys()
	teams.shuffle()
	
	for team in teams:
		if team == "" or team == "spectators":
			continue
		
		if players[team].is_empty():
			return team
	return ""

func find_players_team(peer_id: int) -> String:
	for team in players.keys():
		for player in players[team]:
			if player[0] == peer_id:
				return team
	return ""
