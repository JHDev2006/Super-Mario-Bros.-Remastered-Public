extends PlayerState

var direction := 0

var fall_off := 0.0

func enter(_msg := {}) -> void:
	fall_off = 0
	direction = player.direction
	player.direction *= -1

func physics_update(delta: float) -> void:
	if player.input_direction == player.direction or player.input_direction == 0:
		fall_off += 4 * delta
	player.apply_gravity(delta)
	player.velocity.y = clamp(player.velocity.y, -INF, 50)
	player.sprite.play("Skid")
	player.velocity.x = 50 * direction
	if Global.player_action_just_pressed("jump", player.player_id):
		jump_off()
	if player.is_on_floor() or player.is_on_wall() == false or fall_off >= 1:
		player.velocity.x = 50 * player.input_direction
		state_machine.transition_to("Normal")
	player.move()

func jump_off() -> void:
	AudioManager.play_sfx("bump", player.global_position)
	player.state_machine.transition_to("Normal")
	player.jump()
	player.velocity.x = 120 * player.direction
