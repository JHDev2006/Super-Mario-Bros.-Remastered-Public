extends PlayerState

const SLOW_SPEED := 300.0
const FAST_SPEED := 800.0

var old_layers := []

func enter(_msg := {}) -> void:
	player.can_hurt = false
	for i in 3:
		player.set_collision_mask_value(i + 1, false)

func physics_update(_delta: float) -> void:
	player.velocity = Input.get_vector("move_left_0", "move_right_0", "move_up_0", "move_down_0") * (FAST_SPEED if Input.is_action_pressed("run_0") else SLOW_SPEED)
	player.move()

func exit() -> void:
	player.can_hurt = false
	for i in 3:
		player.set_collision_mask_value(i + 1, true)
	player.velocity = Vector2.ZERO
