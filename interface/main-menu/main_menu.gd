extends Control

signal rebuild_clicked(game_settings: Dictionary)
signal create_lobby
signal join_lobby(lobby_id: int)

var curr_lobbies: Array

var curr_game_settings: Dictionary = {
	"map_size": 0,
	"city_amount": 0,
	"road_connections": 0
}

func _ready() -> void:
	Steam.getNumberOfCurrentPlayers()
	Steam.number_of_current_players.connect(_set_basic_info)
	
	%CreateLobby.pressed.connect(func(): %Screens.current_tab = 2)
	%JoinLobby.pressed.connect(func(): %Screens.current_tab = 1)
	%SearchBack.pressed.connect(func(): %Screens.current_tab = 0)
	%CreatorBack.pressed.connect(func(): %Screens.current_tab = 0)
	
	%MapSize.tab_changed.connect(_change_lobby_setting.bind("map_size"))
	%CityAmount.tab_changed.connect(_change_lobby_setting.bind("city_amount"))
	%RoadConnections.tab_changed.connect(_change_lobby_setting.bind("road_connections"))
	%Rebuild.pressed.connect(func(): rebuild_clicked.emit(curr_game_settings))
	
	%InitLobby.pressed.connect(func(): create_lobby.emit())
	%QuickPlay.pressed.connect(func(): join_lobby.emit(1))
	
	Steam.requestLobbyList()
	
	%Refresh.pressed.connect(Steam.requestLobbyList)
	
	Steam.lobby_match_list.connect(_load_lobbies)

func _load_lobbies(lobbies: Array) -> void:
	curr_lobbies = lobbies
	
	for lobby in %ServerContainer.get_children():
		lobby.queue_free()
	
	for lobby in lobbies:
		var owner_name: String# = Steam.getPlayerNickname(Steam.getLobbyOwner(lobby))
		var curr_player_count: int = Steam.getNumLobbyMembers(lobby)
		var max_player_count: int = Steam.getLobbyMemberLimit(lobby)
		var status: String = Steam.getLobbyData(lobby, "status")
		
		var button := Button.new()
		button.text = owner_name + "'s Game | " + str(curr_player_count) + "|" + str(max_player_count) + " | " + status 
		button.pressed.connect(func(): join_lobby.emit(lobby))
		%ServerContainer.add_child(button)

func _set_basic_info(_success: int, players: int) -> void:
		%PlayersOnline.text = str(players) + " Players Playing"
		%StatsList.update_stats()
		
		var player_name = Steam.getPersonaName()
		if player_name == null:
			%Welcome.text = "Welcome Back Player"
		else:
			%Welcome.text = "Welcome Back " + player_name

func _change_lobby_setting(value: int, setting: String) -> void:
	curr_game_settings[setting] = value
	
	rebuild_clicked.emit(curr_game_settings)
