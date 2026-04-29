extends CanvasLayer

@onready var dialog_box = $Anchor/DialogBox
@onready var name_box = $Anchor/NameBox
@onready var curr_npc = $".."
@onready var textbox_sound = $TextAdvance
@onready var camera_switcher = $CameraSwitcher
@onready var voice_player = $VoicePlayer
const NICK_DIALOG1 = [
	"NickShroom:Good luck! If you see the Sunburnt Unicorn, say hi for me!"
]
var voice_tracks = {}
var speaker_name
var dialog_line
var dialog_index = 0
var dialog_done = false
func _ready():
	$Anchor/TaterAnim.play("idle")
	$Anchor/DellaAnim.play("idle")
	_load_voice_tracks()
	curr_npc.dialogue_start.connect(_dialogue_started)

func _load_voice_tracks():
	voice_tracks[0] = preload("res://sound/nick_vt/Maraj_Tahsya_GrowingTiny_Nickshroom_Voicetrack6.wav")

func _play_voice(dialog_idx: int):
	if dialog_idx in voice_tracks:
		voice_player.stream = voice_tracks[dialog_idx]
		voice_player.volume_db = -10
		#voice_player.play()
		
func _dialogue_started():
	process_line()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("next_line") and curr_npc.dialogue_in_prog and not dialog_done:
		if dialog_index == len(NICK_DIALOG1):
			rpc("end_dialogue")
		
		if dialog_index < len(NICK_DIALOG1):
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
	
	var line = NICK_DIALOG1[dialog_index]
	var line_info = parse_line(line)
	name_box.text = line_info["speaker_name"]
	dialog_box.text = line_info["dialog_line"]
	
	# Play voice track for this dialog index
	await get_tree().create_timer(2).timeout
	_play_voice(dialog_index)
	
	dialog_index += 1
	
@rpc ("any_peer", "call_local", "reliable")
func end_dialogue():
	dialog_done = true
	print("dialogue ended")
	self.hide()
	#Moving Players
	for player in get_tree().get_nodes_in_group("Players"):
		if multiplayer.get_unique_id() == player.player_id:
			camera_switcher.blend_to(player.get_node("Camera2D"), 2)
			await get_tree().create_timer(2).timeout
		player.input_allowed = true
	
	
