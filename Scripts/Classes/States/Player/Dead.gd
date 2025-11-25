extends PlayerState

var can_fall := false

func enter(msg := {}) -> void:
	player.z_index = 20
	can_fall = false
	player.velocity = Vector2.ZERO
	player.stop_all_timers()
	await get_tree().create_timer(0.5).timeout
	can_fall =true
	for i in 16:
		player.set_collision_mask_value(i + 1, false)
	player.gravity = player.JUMP_GRAVITY
	if msg["Pit"] == false: 
		player.velocity.y = -player.DEATH_JUMP_HEIGHT * player.gravity_vector.y # nabbup : Flip death gravity when upside down

func physics_update(delta: float) -> void:
	if can_fall:
		player.play_animation("Die")
	else:
		player.play_animation("DieFreeze")
	player.sprite.speed_scale = 1
	if can_fall:
		# nabbup : Flip death gravity when upside down
		player.velocity.y += (player.JUMP_GRAVITY) * delta * 60.0 * player.gravity_vector.y
		player.velocity.y = clamp(player.velocity.y, -player.MAX_FALL_SPEED, player.MAX_FALL_SPEED) # wish this could be better than just substituting -INF but you can't win em all ~ nabbup
		player.move_and_slide()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump_0"):
			player.death_load()
