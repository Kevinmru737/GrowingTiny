extends player_state


func update(delta: float):
	player.x_movement(delta)
	player.handle_jump()
	player.handle_falling(delta)
	handle_idle()
	handle_animations()
	
func handle_idle():
	if(player.direction == 0):
		player.change_state(states.idle)

func handle_animations():
	if player.direction > 0:
		player.new_anim = "right_walk"
	elif player.direction < 0:
		player.new_anim = "left_walk"
	
