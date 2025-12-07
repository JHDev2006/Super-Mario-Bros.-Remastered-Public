class_name FireBall
extends Projectile

func _physics_process(delta: float) -> void:
	$Sprite.flip_h = direction == 1
	$Sprite/Animation.speed_scale = direction * 2
	handle_movement(delta)
