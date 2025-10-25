extends Enemy

var target_player: Player = null

const MOVE_SPEED := 100.0
const ACCEL := 1.0

func _physics_process(delta: float) -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	var dir = sign(target_player.global_position.x - global_position.x)
	if dir != 0:
		direction = dir
	$Sprite.scale.x = direction
	handle_movement(delta)

func handle_movement(delta: float) -> void:
	apply_enemy_gravity(delta)
	if is_on_wall():
		velocity.x = (MOVE_SPEED / 2) * get_wall_normal().x
		velocity.y = -100
	velocity.x = lerpf(velocity.x, MOVE_SPEED * direction, delta * ACCEL)
	move_and_slide()
