extends Node


@onready var game_manager = get_tree().get_first_node_in_group("GameManager")
@onready var cam_switcher = $CameraSwitcher
#Main UI Buttons
@onready var host_button = $"Multiplayer HUD/Panel/HBoxContainer/HostGame"
@onready var join_button = $"Multiplayer HUD/Panel/HBoxContainer/JoinAsPlayer2"
@onready var quit_button = $"Multiplayer HUD/Panel/HBoxContainer/QuitGame"

#Title (img)
@onready var title = $TitleScreenBG/Parallax2DTitle/Title

#Join UI Buttons
@onready var join_ui = $"Multiplayer HUD/Panel/JoinUI"
@onready var host_ip_input = $"Multiplayer HUD/Panel/JoinUI/IPLineEdit"
@onready var join_host = $"Multiplayer HUD/Panel/JoinUI/JoinButton"

# button animating
var original_scale: Vector2
var tween: Tween
@export var hover_scale: float = 1.2  # Scale multiplier on hover (20% larger)
@export var animation_speed: float = 0.2  # Duration of scale animation in seconds

# Fake players
@onready var fake_po_scene = preload("res://scenes/characters/player_tater_po.tscn")
@onready var fake_daisy_scene = preload("res://scenes/characters/player_della_daisy.tscn")


func _ready():
	join_ui.visible = false
	join_ui.focus_mode = Control.FOCUS_NONE
	$Camera2D.add_to_group("cameras")
	if game_manager:
		#chat gpt stuff - i think the problem was something else but this fixed some stuf?
		var host_method1 = Callable(game_manager, "become_host")
		if not host_button.is_connected("pressed", host_method1):
			host_button.pressed.connect(host_method1)
		var host_method = Callable(self, "waiting_for_player_2")
		if not host_button.is_connected("pressed", host_method):
			host_button.pressed.connect(host_method)
		var join_method = Callable(self, "join_enter_ip")
		if not join_button.is_connected("pressed", join_method):
			join_button.pressed.connect(join_method)
		var quit_method = Callable(self, "quit_game")
		if not join_button.is_connected("pressed", quit_method):
			quit_button.pressed.connect(quit_method)
		
		game_manager.players_connected_signal.connect(_on_players_connected)
		
		host_button.focus_mode = Control.FOCUS_NONE
		join_button.focus_mode = Control.FOCUS_NONE
		add_fake_players()
	

func _on_players_connected():
	rpc("start_intro_walk")

@rpc("any_peer", "reliable", "call_local")
func start_intro_walk():
	make_run()
	join_ui.hide()
	$"Multiplayer HUD/Panel/HostWaiting".hide()
	
func waiting_for_player_2():
	var main_ui = $"Multiplayer HUD/Panel/HBoxContainer"
	main_ui.hide()
	$"Multiplayer HUD/Panel/HostWaiting".show()
	title.hide()
	
	
	
func make_run():
	cam_switcher.blend_to(get_tree().get_first_node_in_group("FakePlayers").get_node("Camera2D"), 3)
	await get_tree().create_timer(3).timeout
	for player in get_tree().get_nodes_in_group("FakePlayers"):
		player.walk_right()
	
		
			
	
			
func join_enter_ip():
	print("client entering ip...")
	join_ui.visible = true
	join_host.focus_mode = Control.FOCUS_NONE
	var main_ui = $"Multiplayer HUD/Panel/HBoxContainer"
	main_ui.hide()
	title.hide()
		
func _on_join_button_pressed() -> void:
	var ip = host_ip_input.text.strip_edges()
	if ip != "":
		print(ip)
		game_manager.join_as_player_2(ip)
	else:
		print("Invalid IP Address")
		
func add_fake_players():
	var fake_po = fake_po_scene.instantiate()
	var fake_daisy = fake_daisy_scene.instantiate()
	get_tree().get_current_scene().get_node("Players").add_child(fake_po)
	get_tree().get_current_scene().get_node("Players").add_child(fake_daisy)
	fake_po.add_to_group("FakePlayers")
	fake_daisy.add_to_group("FakePlayers")
	
	var fake_po_spawn = $FakePlayerSpawn/Spawn.global_position
	fake_po.global_position = fake_po_spawn
	print(fake_po_spawn)
	fake_daisy.global_position = fake_po_spawn + Vector2(150, 0)
	


func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_steam_pressed() -> void:
	SteamManager.initialize_steam()
