extends AnimatedSprite2D
@onready var camera_switcher = $"../CameraSwitcher"

# Dialogue Variables
var player_in_area = false
var dialogue_in_prog = false
signal dialogue_start

func _ready():
	self.play("default")
	$DialogueUI.hide()

func _process(_delta: float) -> void:
	if player_in_area and not dialogue_in_prog:
			rpc("initiate_dialogue")
		

func _on_dialogue_detection_body_entered(body: Node2D) -> void:
	if body.has_method("spawn_player"):
		print("npc range entered")
		player_in_area = true


@rpc ("any_peer", "call_local")
func initiate_dialogue():
	print("dialogue initiated")
	for player in get_tree().get_nodes_in_group("Players"):
		player.input_allowed = false
		player.direction = 0
	dialogue_in_prog = true
	dialogue_start.emit()
	
	await get_tree().create_timer(0.5).timeout

	camera_switcher.blend_to($Camera2D, 2)

	await get_tree().create_timer(2).timeout
	
	$DialogueUI.show()
	
	
	
func _on_dialogue_detection_body_exited(body: Node2D) -> void:
	if body.has_method("spawn_player"):
		player_in_area = false
		
