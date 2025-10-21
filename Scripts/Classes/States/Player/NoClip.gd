extends PlayerState

const SLOW_SPEED := 300.0
const FAST_SPEED := 800.0

var old_layers := []

func enter(_msg := {}) -> void:
	player.can_hurt = false
	player.set_collision_mask_value(1, false)
	player.set_collision_mask_value(2, false)

func physics_update(_delta: float) -> void:
	player.velocity = Input.get_vector("move_left_0", "move_right_0", "move_up_0", "move_down_0") * (FAST_SPEED if Input.is_action_pressed("run_0") else SLOW_SPEED)
	player.move_and_slide()

func exit() -> void:
	player.can_hurt = false
	player.set_collision_mask_value(1, true)
	player.set_collision_mask_value(2, true)
	player.velocity = Vector2.ZERO
