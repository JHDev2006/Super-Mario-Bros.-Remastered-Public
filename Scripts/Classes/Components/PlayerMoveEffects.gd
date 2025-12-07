extends Node

func _process(_delta):
	handle_move_fx(get_parent(), get_tree().paused or Global.game_paused)

func handle_move_fx(player: Player, force_kill: bool) -> void:
	var vel_x: float = abs(player.velocity.x)
	var on_floor: bool = player.is_actually_on_floor()
	var on_wall: bool = player.is_actually_on_wall()
	var moving: bool = vel_x >= 5 and not on_wall
	var running: bool = vel_x >= player.physics_params("RUN_SPEED") - 10
	
	var grounded_walk_sfx = not player.physics_params("GROUNDED_WALK_SFX", player.COSMETIC_PARAMETERS)
	var grounded_run_sfx = not player.physics_params("GROUNDED_RUN_SFX", player.COSMETIC_PARAMETERS)
	var walk_sfx = player.physics_params("WALK_SFX", player.COSMETIC_PARAMETERS)
	var run_sfx = player.physics_params("RUN_SFX", player.COSMETIC_PARAMETERS)
	var skid_sfx = player.physics_params("SKID_SFX", player.COSMETIC_PARAMETERS)
	
	var extra_sfx = Settings.file.audio.extra_sfx == 1
	var extra_particles = Settings.file.visuals.extra_particles == 1

	# Walking
	var can_walk = (on_floor or grounded_walk_sfx) and moving
	if AudioManager.active_sfxs.has(walk_sfx):
		if force_kill or not (can_walk and not running):
			AudioManager.kill_sfx(walk_sfx)
	elif not force_kill and can_walk and not running and extra_sfx:
		AudioManager.play_sfx(walk_sfx, player.global_position, 1.0, false)

	# Running
	var can_run = (on_floor or grounded_run_sfx) and running
	if AudioManager.active_sfxs.has(run_sfx):
		if force_kill or not can_run:
			AudioManager.kill_sfx(run_sfx)
	elif not force_kill and can_run and extra_sfx:
		AudioManager.play_sfx(run_sfx, player.global_position, 1.0, false)

	# Skidding
	%SkidParticles.visible = extra_particles
	%SkidParticles.emitting = (
		extra_particles
		and on_floor
		and (player.skidding and player.skid_frames > 2 or player.crouching)
		and vel_x > 25
	)

	var skid_active := on_floor and player.skidding
	if AudioManager.active_sfxs.has(skid_sfx):
		if force_kill or not skid_active:
			AudioManager.kill_sfx(skid_sfx)
	elif not force_kill and skid_active and Settings.file.audio.skid_sfx == 1:
		AudioManager.play_sfx(skid_sfx, player.global_position, 1.0, false)
