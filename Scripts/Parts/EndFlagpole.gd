extends Node2D

const FLAG_POINTS := [100, 400, 800, 2000, 5000]

const FLAG_POINTS_MODERN := [100, 200, 800, 4000, 10000]

signal player_reached

signal sequence_begin

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		player_touch(area.owner)

func player_touch(player: Player) -> void:
	player_reached.emit()
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		SpeedrunHandler.is_warp_run = false
		SpeedrunHandler.run_finished()
	Global.can_pause = false
	if get_node_or_null("Top") != null:
		$Top.queue_free()
	$Hitbox.queue_free()
	get_tree().call_group("Enemies", "flag_die")
	give_points(player)
	Global.can_time_tick = false
	if player.can_pose == false:
		player.z_index = -2
	player.global_position.x = $Flag.global_position.x + 3
	$Animation.play("FlagDown")
	player.state_machine.transition_to("FlagPole")
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.FLAG_POLE, 99, false)
	await get_tree().create_timer(1.5, false).timeout
	sequence_begin.emit()
	if Global.current_game_mode == Global.GameMode.BOO_RACE:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.RACE_WIN, 99, false)
	else:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.LEVEL_COMPLETE, 99, false)
	Global.level_complete_begin.emit()
	await get_tree().create_timer(1, false).timeout
	if [Global.GameMode.BOO_RACE].has(Global.current_game_mode) == false:
		Global.tally_time()

func give_points(player: Player) -> void:
	var value = clamp(int(lerp(0, 4, (player.global_position.y / -144))), 0, 4)
	var nearest_value = FLAG_POINTS[value]
	if Settings.file.difficulty.flagpole_style:
		nearest_value = FLAG_POINTS_MODERN[value]
	$Score.text = str(nearest_value)
	if nearest_value == 10000 and not [Global.GameMode.CHALLENGE, Global.GameMode.BOO_RACE].has(Global.current_game_mode) and not Settings.file.difficulty.inf_lives:
		AudioManager.play_sfx("1_up", global_position)
		Global.lives += 1
		$ScoreNoteSpawner.spawn_one_up_note()
	else:
		Global.score += nearest_value
		$Score/Animation2.play("ScoreRise")
