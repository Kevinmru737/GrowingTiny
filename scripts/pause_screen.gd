extends CanvasLayer

@onready var settings_ui = $Control/Settings

func _ready():
	self.hide()
	
	

func _on_back_button_pressed():
	hide()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	# fix later: back to main menu doesn't sync with 2nd player.
