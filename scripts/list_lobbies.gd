extends Button

@onready var game_manager = get_tree().get_first_node_in_group("GameManager")

@onready var list_lobby_btn = $"."

func _ready():
	var list_lobby = Callable(game_manager, "list_steam_lobbies")
	if game_manager:
		list_lobby_btn.pressed.connect(list_lobby)
		
	
	
