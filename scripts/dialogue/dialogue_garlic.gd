extends CanvasLayer

@onready var dialog_box = $Anchor/DialogBox
@onready var name_box = $Anchor/NameBox
@onready var curr_npc = $".."
@onready var textbox_sound = $TextAdvance
@onready var camera_switcher = $CameraSwitcher
const GARLIC_DIALOG1 = [
	"Rescued Garlic:Wow thanks! You're a life saver!",
	"Rescued Garlic:I hope you had fun! Thanks for playing!"
]

var speaker_name
var dialog_line
var dialog_index = 0
var dialog_done = false
func _ready():
	$Anchor/TaterAnim.play("idle")
	$Anchor/DellaAnim.play("idle")
	process_line()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("next_line") and curr_npc.dialogue_in_prog and not dialog_done:
		if dialog_index == len(GARLIC_DIALOG1):
			rpc("end_dialogue")
		
		if dialog_index < len(GARLIC_DIALOG1):
			rpc("process_line")
		

func parse_line(line: String):
	var line_info = line.split(":")
	assert(len(line_info) >= 2)
	return {
		"speaker_name": line_info[0],
		"dialog_line": line_info[1]
	}
	
@rpc("any_peer", "call_local","reliable")
func process_line():
	if dialog_index > 0:
		textbox_sound.play()
	var line = GARLIC_DIALOG1[dialog_index]
	var line_info = parse_line(line)
	name_box.text = line_info["speaker_name"]
	dialog_box.text = line_info["dialog_line"]
	dialog_index += 1
	
@rpc ("any_peer", "call_local", "reliable")
func end_dialogue():
	dialog_done = true
	print("dialogue ended")
	SceneTransitionAnimation.fade_in()
	await SceneTransitionAnimation.scene_transition_animation_player.animation_finished
	SceneTransitionAnimation.fade_out()
	self.hide()
	var game_manager = get_tree().get_first_node_in_group("GameManager")
	game_manager.next_scene()
	
	
