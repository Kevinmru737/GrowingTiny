extends CharacterBody2D
# Used for cutscenes as a fake version of the player
const INTRO_WALK_SPEED = 300
const gravity = 2000
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	velocity.y = gravity
	animated_sprite.play("idle")
	if $Camera2D:
		$Camera2D.add_to_group("cameras")
func _physics_process(_delta):
	move_and_slide()


func walk_right():
	animated_sprite.play("right_walk")
	velocity.x = INTRO_WALK_SPEED
	
