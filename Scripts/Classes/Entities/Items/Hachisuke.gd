extends PowerUpItem

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		AudioManager.play_sfx("hachisuke", global_position)
		Global.score += 8000
		$ScoreNoteSpawner.spawn_note(8000)
		queue_free()
