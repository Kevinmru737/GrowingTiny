extends Node

#signal game_started_signal
signal players_connected_signal

@onready var title_scene = preload("res://scenes/ui/title_screen.tscn")
#@onready var tutorial_scene = preload("res://scenes/tutorial.tscn")
@onready var scene_container = $"Scene Container"
@onready var title_node = title_scene.instantiate()
@onready var pause_screen = $"../PauseScreen"
#All Scenes to be loaded in chronological order
var scene_list = ["res://scenes/levels/level_1.tscn", "res://scenes/levels/level_2.tscn","res://scenes/ui/credit_screen.tscn"]
var tilemap_original_state = {}
var player2_id
var players_connected = false
var game_started = false



func _ready():
	add_to_group("GameManager")
	load_scene(title_scene)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("settings"):
		if pause_screen.visible:
			pause_screen.hide()
		else:
			pause_screen.show()
	
func next_scene():
	var scene_to_load = scene_list[0]
	if scene_to_load == "res://scenes/levels/level_1.tscn" and multiplayer.is_server():
		rpc("start_game")
		print("loading scene", scene_to_load)
	if scene_to_load:
		MultiplayerManager.request_scene_change(scene_list[0])
		scene_list.remove_at(0)
		
func load_scene(scene_resource):
	# Clear previous scene
	for child in scene_container.get_children():
		child.queue_free()
	# Add new scene
	var new_node = scene_resource.instantiate()
	scene_container.add_child(new_node)
	return new_node

func become_host():
	print("Become host pressed")
	MultiplayerManager.become_host()
	
	#testing dialogue fast
	#MultiplayerManager.request_scene_change("res://scenes/level_1.tscn")
	
@rpc("authority", "reliable")
func start_game():
	MultiplayerManager.request_scene_change("res://scenes/levels/level_1.tscn")

func join_as_player_2(ip):
	print("Join as player 2 pressed")
	MultiplayerManager.join_as_player_2(ip)
	
@rpc("any_peer", "reliable")
func join_as_player_2_connected():
	print("connected player 2")
	players_connected_signal.emit()
	
func list_steam_lobbies():
	print("Listing Steam Lobbies...")
	pass
	
func save_spec_tiles():
	var tilemap = get_tree().get_first_node_in_group("SpecialInteract")
	tilemap_original_state.clear()
	
	# Get all cells in the tilemap
	for cell in tilemap.get_used_cells():
		var source_id = tilemap.get_cell_source_id(cell)
		var atlas_coords = tilemap.get_cell_atlas_coords(cell)
		tilemap_original_state[cell] = {"source": source_id, "atlas": atlas_coords}

func reset_tilemap():
	var tilemap = get_tree().get_first_node_in_group("SpecialInteract")
	tilemap.clear()
	
	# Restore all tiles from the saved state
	for cell in tilemap_original_state:
		var data = tilemap_original_state[cell]
		tilemap.set_cell(cell, data["source"], data["atlas"])
	
	
	
func init_player_after_load():
	pass
	#await get_tree().process_frame # make a better solution future kevin
	#MultiplayerManager.request_scene_change("res://scenes/level_1.tscn")
	
