extends CanvasLayer
@onready var dialog_box = $Anchor/DialogBox
@onready var name_box = $Anchor/NameBox
@onready var curr_npc = $".."
@onready var textbox_sound = $TextAdvance
@onready var camera_switcher = $CameraSwitcher
const GRUNC_DIALOG1 = [
	"Gruncle:Welcome!",
	"Gruncle:I see you've been on a long journey... I've been meaning to set out on one myself actually.",
	"Gruncle:Strange things have been happening in these parts... The forest seems to be dyin' cause of it.",
	"Gruncle:But I've heard a rumor y'see... of a land where these strange objects can't reach...",
    "Gruncle:That's where I'm headed once I finish packing. You best be headed that way too, now off you go!"
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
		if dialog_index == 5:
			rpc("end_dialogue")

		if dialog_index < len(GRUNC_DIALOG1):
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
	var line = GRUNC_DIALOG1[dialog_index]
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
	#Moving Players
	for player in get_tree().get_nodes_in_group("Players"):
		player.input_allowed = true
		player.show()
		if multiplayer.get_unique_id() == player.player_id:
			camera_switcher.cut_to(player.get_node("Camera2D"))
	SceneTransitionAnimation.fade_out()
	self.hide()
