extends PlayerState

func physics_update(delta: float) -> void:
	player.can_run = false
	player.input_direction = 1
	player.normal_state.handle_movement(delta)
	player.input_direction = 1
	player.direction = 1
	player.normal_state.handle_animations()
	for i in $"../../Hitbox".get_overlapping_areas():
		if i.owner is PipeArea:
			if i.owner.exit_only == false:
				player.enter_pipe(i.owner, true)
