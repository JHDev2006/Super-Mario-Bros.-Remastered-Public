extends PowerUpItem

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		AudioManager.play_global_sfx("power_up")
		$ScoreNoteSpawner.spawn_note(1000)
		DiscoLevel.combo_amount += 1
		area.owner.hammer_get()
		queue_free()
