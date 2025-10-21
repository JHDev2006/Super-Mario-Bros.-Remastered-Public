extends PowerUpItem

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		AudioManager.play_sfx("clock_get", global_position)
		$Label/AnimationPlayer.play("Appear")
		Global.time = clamp(Global.time + 100, 0, 999)
		Global.score += 1000
