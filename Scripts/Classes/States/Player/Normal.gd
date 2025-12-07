extends PlayerState

var swim_up_meter := 0.0

var jump_queued := false

var jump_buffer := 0

var run_buffer := 0

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
	run_buffer -= 1
	if jump_buffer <= 0:
		jump_queued = false
	if Global.player_action_pressed("run", player.player_id):
		run_buffer = player.physics_params("RUN_STOP_BUFFER") / delta
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
		player.has_spring_jumped = false
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
			AudioManager.play_sfx("crouch", player.global_position)
			AudioManager.kill_sfx("uncrouch")
	else:
		can_wall_push = player.test_move(player.global_transform, Vector2.UP * 8 * player.gravity_vector.y) and player.physics_params("CAN_BE_WALL_EJECTED")
		if Global.player_action_pressed("move_down", player.player_id) == false:
			if can_wall_push:
				wall_pushing = true
			else:
				wall_pushing = false
				player.crouching = false
				AudioManager.play_sfx("uncrouch", player.global_position)
				AudioManager.kill_sfx("crouch")
		else:
			player.crouching = true
			wall_pushing = false
		if wall_pushing:
			player.global_position.x += (-50 * player.direction * delta)
	if not player.looking_up:
		if Global.player_action_pressed("move_up", player.player_id) and not player.crouching:
			player.looking_up = true
			AudioManager.play_sfx("look_up", player.global_position)
			AudioManager.kill_sfx("stop_look_up")
	else:
		if not Global.player_action_pressed("move_up", player.player_id) and not player.crouching:
			player.looking_up = false
			AudioManager.play_sfx("stop_look_up", player.global_position)
			AudioManager.kill_sfx("look_up")

func handle_ground_movement(delta: float) -> void:
	var skid_conditions = sign(player.input_direction * player.velocity_direction) < 0.0 and abs(player.velocity.x) > player.physics_params("SKID_THRESHOLD") if not player.physics_params("CLASSIC_SKID_CONDITIONS") else sign(player.direction * player.velocity_direction) < 0.0
	if player.skidding:
		ground_skid(delta)
	elif not player.crouching and skid_conditions:
		player.skidding = true # TODO: player skids regardless of current input direction, add it as a param
	elif player.input_direction != 0 and not player.crouching:
		ground_acceleration(delta)
	else:
		deceleration(delta)

func ground_acceleration(delta: float) -> void:
	var target_move_speed: float = player.physics_params("WALK_SPEED")
	if player.in_water or player.flight_meter > 0:
		target_move_speed = player.physics_params("SWIM_GROUND_SPEED")
	var target_accel: float = player.physics_params("GROUND_WALK_ACCEL")
	var walk_speed_requirement = abs(player.velocity.x) >= player.physics_params("WALK_SPEED") if not player.physics_params("CAN_RUN_ACCEL_EARLY") else true
	if ((Global.player_action_pressed("run", player.player_id) or run_buffer > 0) and walk_speed_requirement) and (not player.in_water and player.flight_meter <= 0) and player.can_run:
		target_move_speed = player.physics_params("RUN_SPEED")
		target_accel = player.physics_params("GROUND_RUN_ACCEL")
	if player.input_direction != player.velocity_direction:
		if (Global.player_action_pressed("run", player.player_id) or run_buffer > 0) and player.can_run:
			target_accel = player.physics_params("RUN_SKID")
		else:
			target_accel = player.physics_params("WALK_SKID")
	var clamp_values = [-target_move_speed, target_move_speed] if player.physics_params("CLAMP_GROUND_SPEED") else [-INF, INF]
	player.velocity.x = clamp(move_toward(player.velocity.x, target_move_speed * player.input_direction, (target_accel / delta) * delta), clamp_values[0], clamp_values[1])
	if abs(player.velocity.x) < player.physics_params("MINIMUM_SPEED"):
		player.velocity.x = player.physics_params("MINIMUM_SPEED") * player.input_direction

func deceleration(delta: float, airborne := false) -> void:
	var decel_type = player.physics_params("AIR_DECEL")
	if not airborne:
		decel_type = player.physics_params("GROUND_DECEL")
	elif player.in_water or player.has_wings:
		decel_type = player.physics_params("SWIM_DECEL")
	player.velocity.x = move_toward(player.velocity.x, 0, (decel_type / delta) * delta)

func ground_skid(delta: float) -> void:
	var target_skid: float = player.physics_params("RUN_SKID") if (Global.player_action_pressed("run", player.player_id) or run_buffer > 0) and player.can_run else player.physics_params("WALK_SKID")
	player.skid_frames += 1
	player.velocity.x = move_toward(player.velocity.x, 1 * player.input_direction, (target_skid / delta) * delta)
	if abs(player.velocity.x) < player.physics_params("SKID_STOP_THRESHOLD") or sign(player.input_direction * player.velocity_direction) > 0:
		player.skidding = false
		player.skid_frames = 0
	if abs(player.velocity.x) < player.physics_params("SKID_STOP_THRESHOLD") and player.physics_params("CAN_INSTANT_STOP_SKID"):
		player.velocity.x = 0

func in_air() -> void:
	if Global.player_action_just_pressed("jump", player.player_id):
		if player.in_water or player.flight_meter > 0:
			swim_up()
		else:
			jump_queued = true
			jump_buffer = 4

func handle_air_movement(delta: float) -> void:
	if player.input_direction != 0:
		air_acceleration(delta)
	else:
		deceleration(delta, true)
	if Global.player_action_pressed("jump", player.player_id) == false and player.has_jumped and not player.jump_cancelled:
		player.jump_cancelled = true
		if sign(player.gravity_vector.y * player.velocity.y) < 0.0:
			player.velocity.y /= player.physics_params("JUMP_CANCEL_DIVIDE")
			player.gravity = player.calculate_speed_param("FALL_GRAVITY", player.velocity_x_jump_stored)

func air_acceleration(delta: float) -> void:
	# SkyanUltra: Code graciously provided by Jdaster64!
	var target_speed = player.physics_params("WALK_SPEED")
	var target_accel = player.physics_params("AIR_WALK_ACCEL")
	var run_pressed = (
		Global.player_action_pressed("run", player.player_id)
		and player.can_run
		and not (
			abs(player.velocity.x) <= player.physics_params("WALK_SPEED")
			and player.physics_params("LOCK_AIR_SPEED")
			)
		)
	var use_run_accel = run_pressed and player.physics_params("CAN_AIR_RUN_EARLY")
	var use_back_accel = sign(player.velocity.x * player.direction) < 0.0 and player.physics_params("USE_BACKWARDS_ACCEL")
	var use_skid = (
		sign(player.velocity_direction * player.input_direction) < 0.0
		and (
			player.physics_params("CAN_AIR_SKID_ALWAYS")
			or abs(player.velocity_x_jump_stored) >= player.physics_params("AIR_SKID_JUMP_SPEED_MINIMUM")
			)
		)
	# Set running speed target, opt. allowing maintaining speed without run button.
	if (abs(player.velocity.x) > player.physics_params("WALK_SPEED") or player.has_spring_jumped) and (run_pressed or player.physics_params("CAN_AIR_RUN_WITHOUT_RUN_BUTTON")):
		target_speed = player.physics_params("RUN_SPEED")
		use_run_accel = true
	elif abs(player.velocity.x) == player.physics_params("WALK_SPEED") and run_pressed:
		target_speed = player.physics_params("RUN_SPEED")
		use_run_accel = true
	# Set acceleration based on what conditions the player currently meets.
	if use_skid:
		if use_back_accel:
			target_accel = player.physics_params("AIR_BACKWARDS_SKID_ACCEL")
		elif use_run_accel:
			target_accel = player.physics_params("AIR_RUN_SKID_ACCEL")
		else:
			target_accel = player.physics_params("AIR_WALK_SKID_ACCEL")
	else:
		if use_back_accel:
			target_accel = player.physics_params("AIR_BACKWARDS_ACCEL")
		elif use_run_accel:
			target_accel = player.physics_params("AIR_RUN_ACCEL")
	player.velocity.x = move_toward(player.velocity.x, target_speed * player.input_direction, (target_accel / delta) * delta)

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
		deceleration(delta, true)

func swim_acceleration(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, player.physics_params("SWIM_SPEED") * player.input_direction, (player.physics_params("GROUND_WALK_ACCEL") / delta) * delta)

func swim_up() -> void:
	if player.swim_stroke:
		player.play_animation("SwimIdle")
	player.velocity.y = -player.physics_params("SWIM_HEIGHT") * player.gravity_vector.y
	AudioManager.play_sfx("swim", player.global_position)
	swim_up_meter = 0.5
	player.crouching = false

func handle_animations() -> void:
	if (player.is_actually_on_floor() or player.in_water or player.flight_meter > 0 or player.physics_params("CAN_AIR_TURN")) and player.input_direction != 0 and not player.crouching:
		player.direction = player.input_direction
	var animation = get_animation_name()
	player.sprite.speed_scale = 1
	if ["Walk", "Move", "Run"].has(animation):
		player.sprite.speed_scale = abs(player.velocity.x) / player.physics_params("MOVE_ANIM_SPEED_DIV", player.COSMETIC_PARAMETERS)
	player.play_animation(animation)
	if player.sprite.animation == "Move":
		walk_frame = player.sprite.frame
	player.sprite.scale.x = player.direction * player.gravity_vector.y

func get_animation_name() -> String:
	# SkyanUltra: Simplified animation table and optimized nesting.
	var vel_x: float = abs(player.velocity.x)
	var vel_y : float = player.actual_velocity_y()
	var on_floor := player.is_actually_on_floor()
	var on_wall := player.is_actually_on_wall()
	var airborne := not on_floor
	var has_flight := player.has_wings
	var moving := vel_x >= 5 and not on_wall
	var pushing := player.input_direction != 0 and on_wall
	var running: float = vel_x >= player.physics_params("RUN_SPEED") - 10
	var run_jump: bool = abs(player.velocity_x_jump_stored) >= player.physics_params("RUN_SPEED") - 10

	var state_context := ""
	if player.in_water: state_context = "Water"
	elif has_flight: state_context = "Wing"

	var state = func(anim_name: String) -> String:
		return state_context + anim_name

	var jump_context := ""
	if player.has_spring_jumped: jump_context = "Spring"
	elif player.has_star: jump_context = "Star"
	elif run_jump: jump_context = "Run"
	
	var jump = func(anim_name: String) -> String:
		return jump_context + anim_name

	# --- Attack Animations ---
	if player.attacking:
		if player.crouching:
			return "CrouchAttack"
		if on_floor:
			if player.skidding:
				return "SkidAttack"
			if moving:
				if player.in_water:
					return "SwimAttack"
				if has_flight:
					return "FlyAttack"
				return "RunAttack" if running else "WalkAttack"
			return "IdleAttack"
		else:
			if player.in_water:
				return "SwimAttack"
			if has_flight:
				return "FlyAttack"
			return "AirAttack"

	# --- Kick Animation ---
	if player.kicking and player.can_kick_anim:
		return state.call("Kick")

	# --- Crouch Animations ---
	if player.crouching and not wall_pushing:
		if player.bumping and player.can_bump_crouch_anim:
			return "CrouchBump"
		if airborne:
			return "CrouchFall" if vel_y >= 0 else "CrouchJump"
		if moving:
			return state.call("CrouchMove")
		return state.call("Crouch")
		
	# --- Grounded Animations ---
	if on_floor:
		if player.spring_bouncing and player.can_spring_land_anim:
			return "SpringLand"
		if player.skidding:
			return "Skid"
		if pushing and player.can_push_anim:
			return state.call("Push")
		if moving:
			if state_context != "":
				return state.call("Move")
			return "Run" if running else "Walk"
		# Idle States
		if player.looking_up:
			return state.call("LookUp")
		return state.call("Idle")

	# --- Airborne Animations ---
	if player.in_water:
		if swim_up_meter > 0:
			if player.bumping and player.can_bump_swim_anim:
				return "SwimBump"
			return "SwimUp"
		return "SwimIdle"

	if has_flight:
		if swim_up_meter > 0:
			if player.bumping and player.can_bump_fly_anim:
				return "FlyBump"
			return "FlyUp"
		return "FlyIdle"

	if player.has_jumped:
		if player.bumping and player.can_bump_jump_anim:
			return jump.call("JumpBump")
		if vel_y < 0:
			return jump.call("Jump")
		else:
			return jump.call("JumpFall")
	else:
		# guzlad: Fixes characters with fall anims not playing them, but also prevents old characters without that anim not being accurate
		if not player.sprite.sprite_frames.has_animation("Fall"):
			player.sprite.frame = walk_frame
		return "Fall"

func exit() -> void:
	if owner.has_hammer:
		owner.on_hammer_timeout()
	owner.skidding = false
