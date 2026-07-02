class_name SuperballProjectile
extends Projectile

func _ready() -> void:
	await get_tree().physics_frame
	if $VisibleOnScreenNotifier2D.is_on_screen() == false:
		queue_free()

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	handle_movement(delta)
