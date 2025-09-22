extends PlayerState

var direction := 0

var fall_off := 0.0

func enter(_msg := {}) -> void:
	fall_off = 0.0
	direction = -player.direction

func physics_update(delta: float) -> void:
	if player.input_direction == direction or player.input_direction == 0:
		fall_off += 4 * delta
	
	player.play_animation("WallSlide")
	
	var grav := player.WALL_SLIDE_GRAVITY * 60 * delta
	player.velocity.y = min(player.velocity.y + grav, player.WALL_SLIDE_SPEED)
	player.velocity.x = -50 * direction
	
	player.sprite.scale.x = direction * player.gravity_vector.y
	
	if Global.player_action_just_pressed("jump", player.player_id):
		jump_off()
	
	if player.is_on_floor() or player.is_on_wall() == false or fall_off >= 1:
		player.velocity.x = player.WALL_SLIDE_EJECT_SPEED * player.input_direction
		state_machine.transition_to("Normal")
	
	player.move_and_slide()

func jump_off() -> void:
	AudioManager.play_sfx("bump", player.global_position)
	player.state_machine.transition_to("Normal")
	player.jump()
	player.direction = direction
	player.velocity.x = player.WALL_JUMP_SPEED * direction
