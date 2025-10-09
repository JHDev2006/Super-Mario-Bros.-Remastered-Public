extends PowerUpItem

const MOVE_SPEED := 65

func _physics_process(delta: float) -> void:
	$BasicEnemyMovement.handle_movement(delta)

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		if has_meta("is_poison"):
			area.owner.damage()
			queue_free()
		elif has_meta("is_oneup"):
			give_life(area.owner)
		else:
			collect_item(area.owner)

func give_life(_player: Player) -> void:
	DiscoLevel.combo_amount += 1
	AudioManager.play_sfx("1_up", global_position)
	if Global.current_game_mode == Global.GameMode.CHALLENGE or Settings.file.difficulty.inf_lives:
		Global.score += 2000
		$ScoreNoteSpawner.spawn_note(2000)
	else:
		Global.lives += 1
		$ScoreNoteSpawner.spawn_one_up_note()
	queue_free()
