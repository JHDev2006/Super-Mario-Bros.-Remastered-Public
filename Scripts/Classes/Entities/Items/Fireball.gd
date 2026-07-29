class_name FireBall
extends Projectile

var can_rotate := true

const FIREBALL_EXPLOSION = preload("res://Scenes/Prefabs/Particles/FireballExplosion.tscn")

func _ready() -> void:
	if can_rotate:
		$Sprite/Animation.play("Spin")
	await get_tree().create_timer(0.5, false).timeout
	if $VisibleOnScreenNotifier2D.is_on_screen() == false:
		queue_free()

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	$Sprite/Animation.speed_scale = direction * 2
	handle_movement(delta)
