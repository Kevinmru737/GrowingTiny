extends player_state


func update(delta: float):
	player.handle_falling(delta)
	player.handle_jump()
	player.x_movement(delta)
	
	if player.direction != 0:
		player.change_state(states.run)
	
	handle_animations()
	
func handle_animations():
	player.new_anim = "idle"
