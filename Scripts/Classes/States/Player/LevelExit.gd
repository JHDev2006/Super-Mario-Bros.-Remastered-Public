extends PlayerState

func enter(_msg := {}) -> void:
	player.can_hurt = false
	player.has_jumped = false
	player.crouching = false
	player.get_node("CameraCenterJoint/RightWall").set_collision_layer_value(1, false)

func physics_update(delta: float) -> void:
	if player.is_posing: 
		player.velocity.x = 0
		return
	player.input_direction = 1
	player.can_run = false
	player.normal_state.handle_movement(delta)
	player.normal_state.handle_animations()
