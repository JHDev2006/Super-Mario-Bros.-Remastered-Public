class_name Thwomp
extends Enemy

enum States{IDLE, FALLING, LANDED, RISING}

var current_state := States.IDLE

@onready var starting_y := global_position.y

var can_fall := true

func _physics_process(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 20)
	match current_state:
		States.IDLE:
			handle_idle(delta)
		States.FALLING:
			handle_falling(delta)
		States.RISING:
			handle_rising(delta)
		_:
			pass
	move_and_slide()

func handle_idle(delta: float) -> void:
	var target_player = get_tree().get_first_node_in_group("Players")
	var x_distance = abs(target_player.global_position.x - global_position.x)
	velocity = Vector2.ZERO
	if x_distance < 24 and can_fall:
		can_fall = false
		current_state = States.FALLING
		$TrackJoint.detach()
	elif x_distance < 48:
		%Sprite.play("Look")
	else:
		%Sprite.play("Idle")

func handle_falling(delta: float) -> void:
	%Sprite.play("Fall")
	velocity.y += (15 ) * delta * 60.0
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
	handle_block_breaking()
	if is_on_floor():
		land()

func handle_block_breaking() -> void:
	for i in %BlockBreakingHitbox.get_overlapping_bodies():
		if i is Block and i.get("destructable") == true:
			i.destroy()

func land() -> void:
	AudioManager.play_sfx("cannon", global_position)
	current_state = States.LANDED
	await get_tree().create_timer(1, false).timeout
	current_state = States.RISING

func handle_rising(delta: float) -> void:
	velocity.y = -50
	%Sprite.play("Idle")
	if global_position.y <= starting_y:
		global_position.y = starting_y
	if global_position.y <= starting_y or is_on_ceiling():
		current_state = States.IDLE
		await get_tree().create_timer(0.5, false).timeout
		can_fall = true
