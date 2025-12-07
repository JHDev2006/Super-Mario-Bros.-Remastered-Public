class_name Hammer
extends Projectile

func _physics_process(delta: float) -> void:
	$Sprite.flip_h = direction == 1
	$Animations.speed_scale = -direction
	handle_movement(delta)
