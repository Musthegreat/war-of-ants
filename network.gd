extends Node
class_name Network

@onready var main: Main = $".."
@onready var tick: Timer = $tick

var peer: MultiplayerPeer

const testing_ip: String = "127.0.0.1" # good to go!
const testing_port: int = 62334
const LOBBY_SECRET: String = "12239322"

var max_peers: int = 9
var lobby_id: int

func _ready() -> void:
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_created.connect(_on_lobby_created)
	
	multiplayer.peer_connected.connect(_joined_game)
	
	tick.timeout.connect(
		func():
			if multiplayer.is_server():
				_sync_tick.rpc()
	)
	%GameMenu.game_started.connect(_start_game)

func _joined_game(peer_id: int) -> void:
	if multiplayer.is_server():
		
		# send new player the map
		_sync_map_template.rpc_id(peer_id, Variables.game.map.cities)
		
		# resolve and send all players new teams
		if !Variables.game.has_game_started:
			print("assigning new player to team")
			Variables.game.assign_player_to_team(peer_id)
			%GameMenu.show_start_game_button()
		else:
			print("adding spectator")
			Variables.game.spectators.append([peer_id, -1])
		
		Variables.my_team = Variables.game.find_players_team(multiplayer.get_unique_id())
		_sync_teams.rpc(Variables.game.players)
		
		print("synced teams")
		
		# check if the game can start
		if Variables.game.check_for_players_required():
			print("required players reached")
			
			main.city_manager.set_spawn_points()
			
			%GameMenu.update_player_board()

func _start_game() -> void:
	Steam.setLobbyData(lobby_id, "status", "Ongoing Match")
	_start_game_notification.rpc()

@rpc("authority", "call_local", "reliable")
func _start_game_notification() -> void:
	if multiplayer.is_server():
		tick.start()
		Variables.game.has_game_started = true
	
	Variables.game.has_game_started = true
	
	%GameMenu.change_team_color(Variables.my_team)

@rpc("authority", "call_local", "reliable")
func _sync_tick() -> void:
	main.city_manager.city_tick()
	%GameMenu.update_player_board()

@rpc("authority", "call_remote", "reliable")
func _sync_teams(players: Dictionary) -> void:
	Variables.game.players = players
	
	Variables.my_team = Variables.game.find_players_team(multiplayer.get_unique_id())
	
	if Variables.game.check_for_players_required():
		%GameMenu.update_status_to_ready()
		%GameMenu.update_player_board()

@rpc("authority", "call_remote", "reliable")
func _sync_map_template(cities: Array) -> void:
	var new_map := Map.new()
	new_map.cities = cities
	Variables.game.map = new_map
	main.build_map()

#region Boilerplate
func host() -> void:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(testing_port)
	print(error_string(err))
	
	multiplayer.multiplayer_peer = peer
	Variables.game.assign_player_to_team(1)

func join() -> void:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(testing_ip, testing_port)
	print(error_string(err))
	
	multiplayer.multiplayer_peer = peer

func steam_host() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_peers)

func steam_join(_lobby_id) -> void:
	Steam.joinLobby(int(_lobby_id))

func _on_lobby_created(_connect: int, _lobby_id: int):
	print("_on_lobby_created", _connect)
	if _connect == 1:
		lobby_id = _lobby_id
		Steam.setLobbyData(_lobby_id, "status", "Waiting for players")
		create_socket()
		print("Create lobby id:", str(lobby_id))
	else:
		print("Error on create lobby!")

func _on_lobby_joined(lobby: int, _permissions: int, _locked: bool, response: int):
	print("_on_lobby_joined")
	if response == 1:
		var id = Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():
			connect_socket(id)
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2: FAIL_REASON = "This lobby no longer exists."
			3: FAIL_REASON = "You don't have permission to join this lobby."
			4: FAIL_REASON = "The lobby is now full."
			5: FAIL_REASON = "Uh... something unexpected happened!"
			6: FAIL_REASON = "You are banned from this lobby. What did you do?"
			7: FAIL_REASON = "You cannot join due to having a limited account."
			8: FAIL_REASON = "This lobby is locked or disabled."
			9: FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		print(FAIL_REASON)

func create_socket():
	print("create_socket")
	
	peer = SteamMultiplayerPeer.new()
	# Example of peer config
	#peer.set_config(SteamPeerConfig.NETWORKING_CONFIG_SEND_BUFFER_SIZE, 524288)
	peer.create_host(0)
	multiplayer.set_multiplayer_peer(peer)
	Variables.game.assign_player_to_team(1)

func connect_socket(steam_id: int):
	print("connect_socket")
	
	peer = SteamMultiplayerPeer.new()
	# Example of peer config
	# peer.set_config(SteamPeerConfig.NETWORKING_CONFIG_SEND_BUFFER_SIZE, 524288)
	peer.create_client(steam_id, 0)
	multiplayer.set_multiplayer_peer(peer)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
#endregion
