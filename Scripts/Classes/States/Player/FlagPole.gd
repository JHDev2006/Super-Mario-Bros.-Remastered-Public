extends PlayerState

var can_land := true

@export var castle: Node = null

func enter(_msg := {}) -> void:
	player.in_cutscene = true
	player.direction = 1
	player.stop_all_timers()
	if not ending_params("FLAG_SKIP_GRAB"):
		await Global.level_complete_begin
		if ending_params("FLAG_JUMP_SPEED") > 0 and player.is_actually_on_floor():
			player.velocity.y = player.calculate_jump_height(ending_params("FLAG_JUMP_SPEED"), ending_params("FLAG_JUMP_INCR")) * player.gravity_vector.y
	player.velocity.x = ending_params("FLAG_INITIAL_X_VELOCITY")
	state_machine.transition_to("LevelExit")

func physics_update(_delta: float) -> void:
	player.velocity.y = ending_params("FLAG_SLIDE_SPEED")
	player.velocity.x = 0
	player.sprite.scale.x = player.direction
	if player.is_on_floor():
		if can_land:
			can_land = false
			player.global_position.x += 10
			player.direction = -1
		player.sprite.speed_scale = 0
	else:
		player.sprite.speed_scale = 2
	player.play_animation("FlagSlide")
	player.move_and_slide()

func ending_params(type := ""):
	return player.physics_params(type, player.ENDING_PARAMETERS)
