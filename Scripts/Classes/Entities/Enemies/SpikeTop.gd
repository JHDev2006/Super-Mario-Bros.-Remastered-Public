extends Enemy

var surface_normal := Vector2.UP

var can_move := false

var can_turn := false

const MOVE_SPEED := 32

var fall_velocity := 0.0

var can_fall := true

@export_enum("Down", "Up", "Left", "Right") var starting_direction := 0
@export_enum("Forwards", "Backwards") var movement_direction := 0

func _ready() -> void:
	on_modifier_applied()
	can_turn = true

func _physics_process(delta: float) -> void:
	%RotationJoint.scale.x = -direction
	if can_move:
		handle_movement(delta)
	elif can_fall:
		velocity.x = MOVE_SPEED * direction
		apply_enemy_gravity(delta)
		move_and_slide()
		if %FloorCheck.is_colliding() or %WallCheck.is_colliding() or is_on_floor():
			can_fall = false
			can_move = true
			if %WallCheck.is_colliding():
				turn(%WallCheck.get_collision_normal(), %WallCheck.get_collision_point())
		else:
			%RotationJoint.rotation = lerp_angle(%RotationJoint.rotation, 0, delta * 10)


func handle_movement(delta: float) -> void:
	global_position += MOVE_SPEED * surface_normal.rotated(deg_to_rad(90 * direction)) * delta
	if %FloorCheck.is_colliding():
		can_turn = true
	if (%FloorCheck.is_colliding() or %WallCheck.is_colliding() or %CornerCheck.is_colliding()) == false and can_turn:
		can_fall = true
		can_move = false
		return
	if %FloorCheck.is_colliding() and %FloorCheck.get_collision_normal().is_equal_approx(surface_normal) == false and can_turn:
		turn(%FloorCheck.get_collision_normal(), %FloorCheck.get_collision_point())
	elif %WallCheck.is_colliding() and can_turn:
		turn(%WallCheck.get_collision_normal(), %WallCheck.get_collision_point())
	elif %FloorCheck.is_colliding() == false and can_turn:
		if %CornerCheck.is_colliding():
			turn(%CornerCheck.get_collision_normal(), %CornerCheck.get_collision_point())

func turn(new_normal := Vector2.UP, new_point := Vector2.ZERO) -> void:
	velocity = Vector2.ZERO
	if can_turn == false:
		return
	can_turn = false
	can_move = false
	var start_angle = %RotationJoint.global_rotation + (deg_to_rad(180) if direction == 1 else 0)
	var new_angle = new_normal.rotated(deg_to_rad(90)).angle()
	var duration = abs(rad_to_deg(angle_difference(start_angle, new_angle))) / 180
	if duration < 0.35:
		can_move = true
		can_turn = true
	else:
		move_to_collision_point(new_point, duration)
	var tween = create_tween().tween_method(func(t): %RotationJoint.global_rotation = (lerp_angle(start_angle, new_angle, t)), 0.0, 1.0, duration)
	surface_normal = new_normal
	await get_tree().create_timer(duration + 0.016, false).timeout
	can_move = true

func move_to_collision_point(point := Vector2.ZERO, duration := 0.25) -> void:
	var tween = create_tween().tween_property(self, "global_position", point, duration)


func on_modifier_applied() -> void:
	direction = [-1, 1][movement_direction]
	%RotationJoint.global_rotation_degrees = [0, 180, 90, -90][starting_direction]
	surface_normal = Vector2.from_angle(%RotationJoint.global_rotation - deg_to_rad(90))
	can_move = true
	%RotationJoint.scale.x = -direction
	global_position = get_meta("tile_position") * 16 + Vector2i(8, 16)
	global_position += [Vector2.ZERO, Vector2(0, -16), Vector2(-8, -8), Vector2(8, -8)][starting_direction]
