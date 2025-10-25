extends PowerUpItem

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		AudioManager.play_sfx("hachisuke", global_position)
		$ScoreNoteSpawner.spawn_note(8000)
		DiscoLevel.combo_amount += 1
		queue_free()
