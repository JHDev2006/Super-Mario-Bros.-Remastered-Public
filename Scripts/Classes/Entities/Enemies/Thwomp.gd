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
		play_animation("Look")
	else:
		play_animation("Idle")

func handle_falling(delta: float) -> void:
	play_animation("Fall")
	velocity.y += (15 / delta) * delta
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
	handle_block_breaking()
	if is_on_floor() and velocity.y > 0:
		land()

func handle_block_breaking() -> void:
	for i in %BlockBreakingHitbox.get_overlapping_bodies():
		if i is Block and i.get("destructable") == true:
			i.destroy()
			land()
		if i is Crate:
			i.destroy(false)
			velocity.y = 0

func land() -> void:
	AudioManager.play_sfx("thwomp_land", global_position)
	current_state = States.LANDED
	Global.screen_shaker.shake_screen(8.0, 0.05)
	await get_tree().create_timer(1, false).timeout
	current_state = States.RISING

func handle_rising(delta: float) -> void:
	velocity.y = -50
	play_animation("Idle")
	if global_position.y <= starting_y:
		global_position.y = starting_y
	if global_position.y <= starting_y or is_on_ceiling():
		current_state = States.IDLE
		await get_tree().create_timer(0.5, false).timeout
		can_fall = true

func play_animation(animation_name := "") -> void:
	if %Sprite.animation != animation_name:
		%Sprite.play(animation_name)
