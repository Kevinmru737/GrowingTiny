extends CharacterBody2D

const MOVEMENT_SPEED = 300.0
var jump_velocity = -1000.0
var DEFAULT_GRAVITY =  2 * ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity = DEFAULT_GRAVITY

@onready var animated_sprite = $AnimatedSprite2D
@onready var walking_sound = $WalkingSound

# Multiplayer variables
var direction = 1
var do_jump = false
var _is_on_floor = true
var alive = true
var input_allowed = true

# Jumping logic
var is_jumping = false
var can_move_during_jump = false
var jump_velocity_applied = false
var prev_y = 0
var target_anim = ""
var last_anim = ""
var jump_type = "delay" #default is nothing which is the previous jump

#walking variables
var walking_sound_cooldown: float = 0.0
var is_walking = false
var walk_sound_interval: float = 0.5  # seconds between footsteps


@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

func _ready():
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
	# disable for titlescreen
		$Camera2D.enabled = false
	self.hide()
	add_to_group("Players")
	
	# Adjusting Tater Po's jump height
	if player_id == 1:
		jump_velocity = -900
		jump_type = "instant"
	else:
		jump_type = "slow"
	


func _process(delta: float) -> void:
	# Decrease cooldown timer
	if walking_sound_cooldown > 0:
		walking_sound_cooldown -= delta
	
	# Play walking sound at intervals
	if multiplayer.get_unique_id() == player_id and is_walking:
		if walking_sound_cooldown <= 0:
			rpc("_play_walking_sound")
			walking_sound_cooldown = walk_sound_interval
	else:
		walking_sound.stop()
		walking_sound_cooldown = 0  # Reset when not walking
		
@rpc("any_peer", "call_local")
func _play_walking_sound():
	walking_sound.play()
	
	
func _physics_process(delta):
	_is_on_floor = is_on_floor()
	prev_y = velocity.y

	if is_multiplayer_authority():
		_movement(delta)
		_anim_handler(prev_y)
	
	if multiplayer.is_server():
		if not alive && is_on_floor():
			_set_alive()
	
func _anim_handler(prev_y_vel):
	var new_anim = ""

	# Walk animation
	if _is_on_floor and not is_jumping:
		new_anim = _apply_walk_anim()
	else:
		new_anim = _apply_jump_anim(prev_y_vel)

	# Only play/send animation if it changed
	if new_anim != last_anim:
		animated_sprite.play(new_anim)
		last_anim = new_anim

		# Send RPC only if we are the server / authority
		if multiplayer.is_server() or is_multiplayer_authority():
			MultiplayerManager._sync_animation.rpc(new_anim, player_id)

func _apply_walk_anim():
	
	if direction > 0:
		return "right_walk"
	elif direction < 0:
		return "left_walk"
	else:
		return "idle"

func _apply_jump_anim(prev_velocity):
	var anim_suffix = "right" if direction >= 0 else "left"
	var curr_anim = animated_sprite.animation

	# Pre-jump
	if _is_on_floor and curr_anim != "jump_" + anim_suffix + "_land" and is_jumping and input_allowed:
		can_move_during_jump = false
		if jump_type == "slow":
			return "jump_" + anim_suffix + "_pre1"
		else:
			return "jump_" + anim_suffix + "_up"

	# Rising
	elif velocity.y < 0 and not _is_on_floor:
		can_move_during_jump = true
		return "jump_" + anim_suffix + "_up"

	# Falling
	elif velocity.y > 0 and not _is_on_floor:
		can_move_during_jump = true
		return "jump_" + anim_suffix + "_down"

	# Landing
	elif prev_velocity > 0 and is_jumping:
		can_move_during_jump = false
		return "jump_" + anim_suffix + "_land_instant"

	return curr_anim  # fallback, keep current animation

func _movement(delta):
	if input_allowed:
		direction = %InputSynchronizer.input_direction

	# Start jump
	if do_jump and _is_on_floor and not is_jumping:
		do_jump = false
		is_jumping = true
		jump_velocity_applied = false
		velocity.x = 0

	# Stop horizontal movement on landing
	if _is_on_floor and is_jumping:
		velocity.x = 0

	# Jump processing
	if is_jumping:
		_process_jump(delta)

	if can_move_during_jump or not is_jumping:
		if direction != 0:
			velocity.x = direction * MOVEMENT_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, MOVEMENT_SPEED)
	
	# to determine if walking sounds should be played
	if _is_on_floor and velocity.x != 0:
		is_walking = true
	else:
		is_walking = false

	# Apply gravity
	if not _is_on_floor:
		velocity.y += gravity * delta

	move_and_slide()

func _process_jump(_delta):
	var curr_anim = animated_sprite.animation
	var curr_frame = animated_sprite.frame

	# Apply jump velocity during pre-jump
	if curr_anim in ["jump_right_pre1", "jump_left_pre1"]:
		if curr_frame == 3 and not jump_velocity_applied:
			velocity.y = jump_velocity
			jump_velocity_applied = true
	if jump_type == "instant" and curr_anim in ["jump_right_up", "jump_left_up"]:
		if curr_frame == 0 and not jump_velocity_applied:
			velocity.y = jump_velocity
			jump_velocity_applied = true
	# Landing completed
	elif curr_anim in ["jump_right_land_instant", "jump_left_land_instant"]:
		# Only set to false once at the start
		#if curr_frame == 0:
		#	input_allowed = false
		# Re-enable input when animation stops playing
		#if not animated_sprite.is_playing():
			is_jumping = false
			input_allowed = true
			
func change_camera_limit(left, top, bottom, right):
	print("Changing camera limits...")
	$Camera2D.limit_left = left
	$Camera2D.limit_top = top
	$Camera2D.limit_right = right
	$Camera2D.limit_bottom = bottom
	

func mark_dead():
	print("Mark player dead!")
	alive = false
	SceneTransitionAnimation.fade_in()
	$CollisionShape2D.set_deferred("disabled", true)
	$DeathTimer.start()
	gravity = 0
	
func teleport_player(new_position: Vector2):
	self.position = new_position

func spawn_player():
	print("spawning player:", player_id)
	print(player_id, "position", self.position)
	position = MultiplayerManager.respawn_point
	

func _respawn():
	position = MultiplayerManager.respawn_point
	gravity = DEFAULT_GRAVITY
	print("respawned at:", position)
	$CollisionShape2D.set_deferred("disabled", false)
	SceneTransitionAnimation.fade_out()
	
func _set_alive():
	print("actually alive")
	alive = true
