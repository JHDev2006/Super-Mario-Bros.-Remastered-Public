class_name PlantFireball
extends Projectile

var can_rotate := true

const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

func _ready() -> void:
	if can_rotate:
		$Sprite/Animation.play("Spin")

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	$Sprite/Animation.speed_scale = direction * 2
	handle_movement(delta)
