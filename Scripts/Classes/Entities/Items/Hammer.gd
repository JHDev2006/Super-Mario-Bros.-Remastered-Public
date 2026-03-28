class_name Hammer
extends Projectile

var can_rotate := true

func _ready() -> void:
	if can_rotate:
		$Animations.play("Rotate")

func _physics_process(delta: float) -> void:
	$Sprite.flip_h = direction == 1
	$Animations.speed_scale = -direction
	handle_movement(delta)
