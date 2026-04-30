extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

 #local host

var multiplayer_scene1 = preload("res://scenes/multiplayer/players/multiplayer_player1.tscn")
var multiplayer_scene2 = preload("res://scenes/multiplayer/players/multiplayer_player2.tscn")

var _player_spawn_node
var host_mode_enabled = false
var multiplayer_mode_enabled = false
var respawn_point = Vector2(187, -350)

func become_host():
	print("Starting Host!")
	
	_player_spawn_node = get_tree().get_current_scene().get_node("Players")
	multiplayer_mode_enabled = true
	host_mode_enabled = true
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_del_player)
	
	_add_player_to_game(1, 1)
	
func join_as_player_2(ip):
	print("Player 2 creation attempt")
	multiplayer_mode_enabled = true
	var client_peer =  ENetMultiplayerPeer.new()
	print("join ip:", ip)
	client_peer.create_client(ip, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	
	multiplayer.connected_to_server.connect(_on_client_connected)
	
# character = 1 = tater_po, character = 2 = della_daisy
func _add_player_to_game(id: int, character: int):
	print("Player %s joined the game." % id)
	var player_to_add
	if character == 1:
		player_to_add = multiplayer_scene1.instantiate()
	elif character == 2:
		player_to_add = multiplayer_scene2.instantiate()
	else:
		return
	player_to_add.player_id = id
	player_to_add.name = str(id)
	player_to_add.add_to_group("Players")
	PlayerRef.player_ref.append({
		"id": id,
		"character": character
	})
	# After spawning the new player on the server
	if multiplayer.is_server() and id != multiplayer.get_unique_id():
		# Send entire player list to the new client
		rpc_id(id, "send_player_list", PlayerRef.player_ref)
	_player_spawn_node.add_child(player_to_add, true)
	
# On client after create_client
func _on_client_connected():
	print("Client connected to server")
	var game_manager = get_tree().get_first_node_in_group("GameManager")
	game_manager.join_as_player_2_connected()
	
	
func _on_peer_connected(id: int):
	print("Peer Connected")
	_add_player_to_game(id, 2)


func _del_player(id: int):
	print("Player %s has left the game." % id)
	if not _player_spawn_node.has_node(str(id)):
		return
	_player_spawn_node.get_node(str(id)).queue_free()
	
func request_scene_change(new_scene_path):
	if multiplayer.is_server():
		print("Server scene change request")
		server_receive_scene_request(new_scene_path)
	else:
		print("Client scene change request")
		server_receive_scene_request(new_scene_path)
		#rpc_id(1, "server_receive_scene_request", new_scene_path)

#@rpc("any_peer", "reliable")
func server_receive_scene_request(new_scene_path):
	if multiplayer.is_server():
		#var sender = multiplayer.get_remote_sender_id()
		#if sender == 0:
			# Server local call
		print("Server scene change requested")
		var game_manager = get_tree().get_first_node_in_group("GameManager")
		game_manager.load_scene(load(new_scene_path))
	else:
		print("Client scene change requested")
		# Tell client to load scene
		var game_manager = get_tree().get_first_node_in_group("GameManager")
		game_manager.load_scene(load(new_scene_path))
		#rpc_id(multiplayer.get_remote_sender_id(), "client_load_scene", new_scene_path)


#@rpc("any_peer", "reliable")
func client_load_scene(new_scene_path):
	print("Client scene load requested")
	var game_manager = get_tree().get_first_node_in_group("GameManager")
	game_manager.load_scene(load(new_scene_path))
	
@rpc("authority", "reliable")
func send_player_list(players):
	print("sendingList")
	PlayerRef.player_ref = players
	_player_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	# Find existing player nodes and add them to group
	for player_data in players:
		if _player_spawn_node.has_node(str(player_data["id"])):
			var player_node = _player_spawn_node.get_node(str(player_data["id"]))
			player_node.add_to_group("Players")
	
	var game_manager = get_tree().get_first_node_in_group("GameManager")
	game_manager.init_player_after_load()
	
@rpc("any_peer", "reliable")
func _sync_animation(target_anim, player_id):
	#Player nodes are placed under "Players" and named with their player_id
	var players_root = get_tree().get_current_scene().get_node("Players")
	
	if players_root.has_node(str(player_id)):
		var player_node = players_root.get_node(str(player_id))
		var sprite = player_node.get_node("AnimatedSprite2D")
		sprite.play(target_anim)
	else:
		print("Player node", player_id, "not found on this peer.")	
			
@rpc("reliable")
func client_remove_scene(old_node_path):
	var old_scene = get_node(old_node_path)
	if old_scene:
		print("removed old scene")
		old_scene.queue_free()
