extends CanvasLayer

@onready var main_controls: Control = $PauseMenu/main_controls
@onready var audio_controls: Control = $PauseMenu/audio_controls
@onready var display_controls: Control = $PauseMenu/display_controls

# Just to track what "panel" user is on (back button functionality)
var current_panel =  null

func _ready():
	self.hide()

func _reset_to_main():
	audio_controls.hide()
	display_controls.hide()
	main_controls.show()
	current_panel = null

func _on_back_button_pressed():
	if current_panel == audio_controls or current_panel == display_controls:
		audio_controls.hide()
		display_controls.hide()
		main_controls.show()
		current_panel = null
	else:
		_reset_to_main()
		hide()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	# Fix later: back to main menu doesn't sync with 2nd player.

func _on_audio_settings_button_pressed():
	# Making a note here: types of music -> Music, SFX, Voiceover(?), Master, etc..
	current_panel = audio_controls
	main_controls.visible = false
	audio_controls.visible = true

func _on_display_settings_button_pressed():
	current_panel = display_controls
	main_controls.visible = false
	display_controls.visible = true
	
	
