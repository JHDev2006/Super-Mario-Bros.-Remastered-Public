class_name PlantFireball
extends Projectile

const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	$Sprite/Animation.speed_scale = direction * 2
	handle_movement(delta)
