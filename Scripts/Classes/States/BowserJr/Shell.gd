extends State

var can_move := false

func enter(_msg := {}) -> void:
	%Sprite.play("Shell")
	await get_tree().create_timer(0.5, false).timeout
	can_move = true
	await get_tree().create_timer(3, false).timeout
	can_move = false
	await get_tree().create_timer(0.5, false).timeout
	owner.velocity.y = -150
	state_machine.transition_to("Idle")

func physics_update(delta: float) -> void:
	var direction = 0
	if owner.is_on_wall():
		if abs(owner.velocity.x) < 100:
			owner.velocity.x = 100 * sign(owner.velocity.x)
		owner.velocity.x = -(owner.velocity.x)
	if can_move:
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_sfx("shell_spin", owner.global_position, 1.0, false)
		if get_tree().get_first_node_in_group("Players") != null:
			direction = sign(get_tree().get_first_node_in_group("Players").global_position.x - owner.global_position.x)
	owner.velocity.x = lerpf(owner.velocity.x, 150 * direction, delta * 2)
	%Movement.apply_gravity(delta)
	owner.move_and_slide()
