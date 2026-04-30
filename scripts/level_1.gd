extends Node

var spawn_point: Vector2
@onready var game_manager = get_tree().get_first_node_in_group("GameManager")

var curr_bg = "Backgrounds"
var tilemap_original_state = {}

func _ready():
	var spawn_node = get_tree().get_first_node_in_group("SpawnPoint")
	if spawn_node:
		spawn_point = spawn_node.position
	else:
		push_error("SpawnPoint not found!")
	print("level 1 started")
	MultiplayerManager.respawn_point = spawn_point
	get_tree().create_timer(0.1).timeout.connect(init_player_after_load) #fix race condition
	SceneTransitionAnimation.fade_out()
	switch_backgrounds("Backgrounds", "GruncHouse")
	game_manager.save_spec_tiles()
	
	PlayerRef.player_in_transit = false

func init_player_after_load():
	get_tree().call_group("Players", "change_camera_limit", 0, -1080, 0, 12300)
	get_tree().call_group("Players", "spawn_player")
	get_tree().call_group("Players", "show")
	rpc("turn_on_camera")

@rpc("any_peer", "reliable", "call_local")
func turn_on_camera():
	print(get_tree().get_nodes_in_group("Players"))
	for player in get_tree().get_nodes_in_group("Players"):
		if multiplayer.get_unique_id() == player.player_id:
			print("found player to turn camera on")
			var player_cam = player.get_node("Camera2D")
			player_cam.enabled = true
			player_cam.make_current()


func switch_backgrounds(old_bg: String, new_bg: String):
	print("switching backgrounds:", old_bg, " to ", new_bg)
	var old_bg_node = get_node(old_bg)
	var new_bg_node = get_node(new_bg)
	
	curr_bg = new_bg
	old_bg_node.fade_out()
	new_bg_node.fade_in()

func _on_bg_switch_body_entered(body: Node2D) -> void:
	if multiplayer.get_unique_id() == body.player_id:
		if curr_bg == "GruncHouse":
			switch_backgrounds(curr_bg, "Backgrounds")
	


func _on_bg_switch_2_body_entered(body: Node2D) -> void:
	if multiplayer.get_unique_id() == body.player_id:
		if curr_bg == "Backgrounds":
			switch_backgrounds(curr_bg, "GruncHouse")
