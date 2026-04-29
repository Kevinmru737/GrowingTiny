extends AnimatableBody2D
@onready var sprite = $AnimatableBody2D
@onready var camera_switcher = $"../CameraSwitcher"

# Dialogue Variables
var players_in_area = {}  # Track which players are in the area
var target_dialogue = "GruncleIntro"
var gruncle_layout
var dialogue_in_prog = false

func _ready():
	sprite.play("idle")
	$DialogueUI.hide()

func _process(_delta: float) -> void:
	if not dialogue_in_prog and players_in_area.size() > 0:
		if Input.is_action_just_pressed("interact_object"):
			initiate_dialogue.rpc()
	
	if dialogue_in_prog:
		$InteractHint.hide()

func _on_dialogue_detection_body_entered(body: Node2D) -> void:
	if body.has_method("spawn_player"):
		print("npc range entered")
		$InteractHint.show()
		# Sync to all clients
		_sync_player_in_area.rpc(body.player_id, true)

@rpc("any_peer", "call_local", "reliable")
func initiate_dialogue():
	# Prevent dialogue from being initiated twice
	if dialogue_in_prog:
		return
	
	print("dialogue initiated")
	dialogue_in_prog = true
	SceneTransitionAnimation.fade_in()
	await SceneTransitionAnimation.scene_transition_animation_player.animation_finished
	camera_switcher.cut_to($Camera2D)
	
	# Moving Players
	for player in get_tree().get_nodes_in_group("Players"):
		if player.player_id == 1:
			player.teleport_player($TaterSP.global_position)
		else:
			player.teleport_player($DellaSP.global_position)
		player.input_allowed = false
		player.hide()
	
	SceneTransitionAnimation.fade_out()
	$DialogueUI.show()

func _on_dialogue_detection_body_exited(body: Node2D) -> void:
	if body.has_method("spawn_player"):
		if gruncle_layout:
			gruncle_layout.hide()
		# Sync to all clients
		_sync_player_in_area.rpc(body.player_id, false)
		if players_in_area.size() == 0:
			$InteractHint.hide()

@rpc("any_peer", "call_local", "reliable")
func _sync_player_in_area(player_id: int, in_area: bool):
	if in_area:
		players_in_area[player_id] = true
	else:
		players_in_area.erase(player_id)
