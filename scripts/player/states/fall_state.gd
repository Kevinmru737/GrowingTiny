extends player_state


func update(delta: float):
	player.handle_falling(delta)
	player.x_movement(delta)
	
	handle_animations()
	
	if player._is_on_floor:
		if player.direction == 0:
			player.change_state(states.landing)
		else:
			player.change_state(states.run)
		
func handle_animations():
	#if player.
	
	pass
