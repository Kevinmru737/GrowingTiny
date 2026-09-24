extends MultiplayerSynchronizer

@onready var player = $".."
var input_direction

func _ready():
	
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
		
	if player.movement_allowed:
		input_direction = Input.get_axis("move_left", "move_right") 
	
func _physics_process(_delta):
	if player.movement_allowed:
		input_direction = Input.get_axis("move_left", "move_right")
	else:
		# If we turn movement off we want the player to stop moving
		input_direction = 0
	
	
func _process(_delta):
	if Input.is_action_just_pressed("jump") and player.movement_allowed:
		jump.rpc()

@rpc("call_local")
func jump():
	if multiplayer.is_server():
		print(player.is_jumping, player.do_jump, player._is_on_floor)
		if not player.is_jumping and player.gravity != 0:
			player.do_jump = true
