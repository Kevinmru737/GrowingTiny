class_name player_state extends Node

var states = null
var player = null
var state_name: String = "NULL"

func enter_state():
	state_name = self.name
	
func exit_state():
	pass
	
func draw():
	pass
	
func update(delta: float):
	pass
	
# Every state should handle it's own animation playing 
func handle_animations():
	pass
