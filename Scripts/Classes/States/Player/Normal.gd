extends PlayerState

var swim_up_meter := 0.0

var jump_queued := false

var jump_buffer := 0

var walk_frame := 0

var bubble_meter := 0.0

var wall_pushing := false

var can_wall_push := false

func enter(_msg := {}) -> void:
	jump_queued = false

func physics_update(delta: float) -> void:
	if player.is_actually_on_floor():
		grounded(delta)
	else:
		in_air()
	handle_movement(delta)
	handle_animations()
	handle_death_pits()

func handle_death_pits() -> void:
	if player.global_position.y > 64 and not Level.in_vine_level and player.auto_death_pit and player.gravity_vector == Vector2.DOWN:
		player.die(true)
	elif player.global_position.y < Global.current_level.vertical_height - 32 and player.gravity_vector == Vector2.UP:
		player.die(true)

func handle_movement(delta: float) -> void:
	jump_buffer -= 1
	if jump_buffer <= 0:
		jump_queued = false
	player.apply_gravity(delta)
	if player.is_actually_on_floor():
		var player_transform = player.global_transform
		player_transform.origin += Vector2.UP * 1
	if player.is_actually_on_floor():
		handle_ground_movement(delta)
	elif player.in_water or player.flight_meter > 0:
		handle_swimming(delta)
	else:
		handle_air_movement(delta)
	player.move_and_slide()
	player.moved.emit()

func grounded(delta: float) -> void:
	player.jump_cancelled = false
	if player.velocity.y >= 0:
		player.has_jumped = false
	if Global.player_action_just_pressed("jump", player.player_id):
		player.handle_water_detection()
		if player.in_water or player.flight_meter > 0:
			swim_up()
			return
		else:
			player.jump()
	if jump_queued and not (player.in_water or player.flight_meter > 0):
		if player.spring_bouncing == false:
			player.jump()
		jump_queued = false
	if not player.crouching:
		if Global.player_action_pressed("move_down", player.player_id):
			player.crouching = true
	else:
		can_wall_push = player.test_move(player.global_transform, Vector2.UP * 8 * player.gravity_vector.y) and player.power_state.hitbox_size != "Small"
		if Global.player_action_pressed("move_down", player.player_id) == false:
			if can_wall_push:
				wall_pushing = true
			else:
				wall_pushing = false
				player.crouching = false
		else:
			player.crouching = true
			wall_pushing = false
		if wall_pushing:
			player.global_position.x += (-50 * player.direction * delta)

func handle_ground_movement(delta: float) -> void:
	if player.skidding:
		ground_skid(delta)
	elif (player.input_direction != player.velocity_direction) and player.input_direction != 0 and abs(player.velocity.x) > player.SKID_THRESHOLD and not player.crouching:
		print([player.input_direction, player.velocity_direction])
		player.skidding = true
	elif player.input_direction != 0 and not player.crouching:
		ground_acceleration(delta)
	else:
		deceleration(delta)

func ground_acceleration(delta: float) -> void:
	var target_move_speed := player.WALK_SPEED
	if player.in_water or player.flight_meter > 0:
		target_move_speed = player.SWIM_GROUND_SPEED
	var target_accel := player.GROUND_WALK_ACCEL
	if (Global.player_action_pressed("run", player.player_id) and abs(player.velocity.x) >= player.WALK_SPEED) and (not player.in_water and player.flight_meter <= 0) and player.can_run:
		target_move_speed = player.RUN_SPEED
		target_accel = player.GROUND_RUN_ACCEL
	if player.input_direction != player.velocity_direction:
		if Global.player_action_pressed("run", player.player_id) and player.can_run:
			target_accel = player.RUN_SKID
		else:
			target_accel = player.WALK_SKID
	player.velocity.x = move_toward(player.velocity.x, target_move_speed * player.input_direction, (target_accel / delta) * delta)

func deceleration(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0, (player.DECEL / delta) * delta)

func ground_skid(delta: float) -> void:
	var target_skid := player.RUN_SKID
	player.skid_frames += 1
	player.velocity.x = move_toward(player.velocity.x, 1 * player.input_direction, (target_skid / delta) * delta)
	if abs(player.velocity.x) < 10 or player.input_direction == player.velocity_direction or player.input_direction == 0:
		player.skidding = false
		player.skid_frames = 0

func in_air() -> void:
	if Global.player_action_just_pressed("jump", player.player_id):
		if player.in_water or player.flight_meter > 0:
			swim_up()
		else:
			jump_queued = true
			jump_buffer = 4

func handle_air_movement(delta: float) -> void:
	if player.input_direction != 0 and player.velocity_direction != player.input_direction:
		air_skid(delta)
	if player.input_direction != 0:
		air_acceleration(delta)
		
	if Global.player_action_pressed("jump", player.player_id) == false and player.has_jumped and not player.jump_cancelled:
		player.jump_cancelled = true
		if sign(player.gravity_vector.y * player.velocity.y) < 0.0:
			player.velocity.y /= player.JUMP_CANCEL_DIVIDE
			player.gravity = player.FALL_GRAVITY

func air_acceleration(delta: float) -> void:
	var target_speed = player.WALK_SPEED
	if abs(player.velocity.x) >= player.WALK_SPEED and Global.player_action_pressed("run", player.player_id) and player.can_run:
		target_speed = player.RUN_SPEED
	player.velocity.x = move_toward(player.velocity.x, target_speed * player.input_direction, (player.AIR_ACCEL / delta) * delta)

func air_skid(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 1 * player.input_direction, (player.AIR_SKID / delta) * delta)

func handle_swimming(delta: float) -> void:
	bubble_meter += delta
	if bubble_meter >= 1 and player.flight_meter <= 0:
		player.summon_bubble()
		bubble_meter = 0
	swim_up_meter -= delta
	player.skidding = (player.input_direction != player.velocity_direction) and player.input_direction != 0 and abs(player.velocity.x) > 100 and not player.crouching
	if player.skidding:
		ground_skid(delta)
	elif player.input_direction != 0 and not player.crouching:
		swim_acceleration(delta)
	else:
		deceleration(delta)

func swim_acceleration(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, player.SWIM_SPEED * player.input_direction, (player.GROUND_WALK_ACCEL / delta) * delta)

func swim_up() -> void:
	if player.swim_stroke:
		player.play_animation("SwimIdle")
	player.velocity.y = -player.SWIM_HEIGHT * player.gravity_vector.y
	AudioManager.play_sfx("swim", player.global_position)
	swim_up_meter = 0.5
	player.crouching = false

func handle_animations() -> void:
	if (player.is_actually_on_floor() or player.in_water or player.flight_meter > 0 or player.can_air_turn) and player.input_direction != 0 and not player.crouching:
		player.direction = player.input_direction
	var animation = get_animation_name()
	player.sprite.speed_scale = 1
	if ["Walk", "Move", "Run"].has(animation):
		player.sprite.speed_scale = abs(player.velocity.x) / 40
	player.play_animation(animation)
	if player.sprite.animation == "Move":
		walk_frame = player.sprite.frame
	player.sprite.scale.x = player.direction * player.gravity_vector.y

func get_animation_name() -> String:
	if player.attacking:
		if player.crouching:
			return "CrouchAttack"
		elif player.is_actually_on_floor():
			if player.skidding:
				return "SkidAttack"
			elif abs(player.velocity.x) >= 5 and not player.is_actually_on_wall():
				if player.in_water:
					return "SwimAttack"
				elif player.flight_meter > 0:
					return "FlyAttack"
				elif abs(player.velocity.x) < player.RUN_SPEED - 10:
					return "WalkAttack"
				else:
					return "RunAttack"
			else:
				return "IdleAttack"
		else:
			if player.in_water:
				return "SwimAttack"
			elif player.flight_meter > 0:
				return "FlyAttack"
			else:
				return "AirAttack"
	if player.kicking and player.can_kick_anim:
		return "Kick"
	if player.crouching and not wall_pushing:
		if player.bumping and player.can_bump_crouch:
			return "CrouchBump"
		elif player.is_on_floor() == false:
			if player.velocity.y >= 0:
				return "CrouchFall"
			elif player.velocity.y < 0:
				return "CrouchJump"
		elif player.is_actually_on_floor():
			if abs(player.velocity.x) >= 5 and not player.is_actually_on_wall():
				if player.in_water:
					return "WaterCrouchMove"
				elif player.flight_meter > 0:
					return "WingCrouchMove"
				else:
					return "CrouchMove"
			else:
				if player.in_water:
					return "WaterCrouch"
				elif player.flight_meter > 0:
					return "WingCrouch"
				else:
					return "Crouch"
	if player.is_actually_on_floor():
		if player.skidding:
			return "Skid"
		elif abs(player.velocity.x) >= 5 and not player.is_actually_on_wall():
			if player.in_water:
				return "WaterMove"
			elif player.flight_meter > 0:
				return "WingMove"
			elif abs(player.velocity.x) < player.RUN_SPEED - 10:
				return "Walk"
			else:
				return "Run"
		else:
			if Global.player_action_pressed("move_up", player.player_id):
				if player.in_water:
					return "WaterLookUp"
				elif player.flight_meter > 0:
					return "WingLookUp"
				else:
					return "LookUp"
			else:
				if player.in_water:
					return "WaterIdle"
				elif player.flight_meter > 0:
					return "WingIdle"
				else:
					return "Idle"
	else:
		if player.in_water:
			if swim_up_meter > 0:
				if player.bumping and player.can_bump_swim:
					return "SwimBump"
				else:
					return "SwimUp"
			else:
				return "SwimIdle"
		elif player.flight_meter > 0:
			if swim_up_meter > 0:
				if player.bumping and player.can_bump_fly:
					return "FlyBump"
				else:
					return "FlyUp"
			else:
				return "FlyIdle"
		if player.has_jumped:
			if player.bumping and player.can_bump_jump:
				if abs(player.velocity_x_jump_stored) < player.RUN_SPEED - 10:
					return "JumpBump"
				else:
					return "RunJumpBump"
			elif player.velocity.y < 0:
				if player.is_invincible:
					return "StarJump"
				elif abs(player.velocity_x_jump_stored) < player.RUN_SPEED - 10:
					return "Jump"
				else:
					return "RunJump"
			else:
				if player.is_invincible:
					return "StarFall"
				elif abs(player.velocity_x_jump_stored) < player.RUN_SPEED - 10:
					return "JumpFall"
				else:
					return "RunJumpFall"
		else:
			# guzlad: Fixes characters with fall anims not playing them, but also prevents old characters without that anim not being accurate
			if !player.sprite.sprite_frames.has_animation("Fall"):
				player.sprite.frame = walk_frame
			return "Fall"

func exit() -> void:
	if owner.has_hammer:
		owner.on_hammer_timeout()
	owner.skidding = false
