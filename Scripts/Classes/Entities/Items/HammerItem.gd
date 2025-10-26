extends PowerUpItem

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		area.owner.hammer_get()
		queue_free()
