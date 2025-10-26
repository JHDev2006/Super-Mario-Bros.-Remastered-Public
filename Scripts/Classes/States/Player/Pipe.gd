extends PlayerState

const ENTER_SPEED := 50

func enter(_msg := {}) -> void:
	player.can_hurt = false
	player.velocity = Vector2.ZERO
	player.z_index = -5
	physics_update(0)

func physics_update(delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.global_position += (ENTER_SPEED * (player.pipe_enter_direction * player.pipe_move_direction)) * delta
	if player.pipe_enter_direction.x != 0:
		player.sprite.speed_scale = 1
		player.play_animation("PipeWalk")
		player.direction = int(player.pipe_enter_direction.x)
		player.sprite.scale.x = player.direction
	else:
		player.sprite.speed_scale = 1
		player.play_animation("Pipe")

func exit() -> void:
	player.can_hurt = true
	player.z_index = 1
	player.show()
