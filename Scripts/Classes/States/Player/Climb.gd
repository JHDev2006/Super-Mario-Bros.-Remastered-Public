extends PlayerState

var climb_direction := 0

var vine: Vine = null

var cutscene := false

var auto_climb := false

func enter(msg := {}) -> void:
	vine = msg.get("Vine")
	cutscene = msg.has("Cutscene")

func physics_update(_delta: float) -> void:
	player.velocity.x = 0
	if player.input_direction != 0 and climb_direction == 0 and not cutscene:
		player.direction = -player.input_direction
	player.sprite.scale.x = player.direction
	player.global_position.x = vine.global_position.x - (player.physics_params("CLIMB_OFFSET") * player.direction)
	if not cutscene and not auto_climb:
		climb_direction = sign(Input.get_axis("move_up" + "_" + str(player.player_id),"move_down" + "_" + str(player.player_id)))
	if vine.can_tele and player.global_position.y - 64 < vine.top_point and climb_direction == -1:
		climb_direction = -1
		auto_climb = true
	var climb_speed = player.physics_params("CLIMB_DOWN_SPEED") if climb_direction >= 1 else player.physics_params("CLIMB_UP_SPEED")
	player.velocity.y = climb_speed * climb_direction
	player.sprite.play("Climb")
	player.sprite.speed_scale = abs(climb_direction * 1.5)
	player.move_and_slide()
	if Global.player_action_just_pressed("jump", player.player_id) and not cutscene:
		state_machine.transition_to("Normal")
		player.jump()
