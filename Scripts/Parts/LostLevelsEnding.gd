extends Level

var can_exit := false

var seen := false

func _enter_tree() -> void:
	update_next_level_info()
	seen = Global.game_beaten
	Global.game_beaten = true
	Global.can_time_tick = false
	Global.current_level = self
	if Global.world_num > 8:
		Global.extra_worlds_win = true
	update_theme()
	Global.current_campaign = campaign

func _ready() -> void:
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.ENDING, 9999999, false)
	Global.can_time_tick = false
	SaveManager.visited_levels[SaveManager.get_level_idx(9, 1)] = "1"
	$Text2/Hero.text = tr("CUTSCENE_LL_PEACH_4" if Global.player_characters[0] != 3 else "CUTSCENE_LL_PEACH_4F")
	$Text2/Hurrah.text = tr("CUTSCENE_LL_PEACH_3").replace("{PLAYER}", tr(Player.CHARACTER_NAMES[int(Global.player_characters[0])]))
	$ThankYou.text = tr("CUTSCENE_CASTLE_PEACH_1").replace("{PLAYER}", tr(Player.CHARACTER_NAMES[int(Global.player_characters[0])]))
func _process(_delta: float) -> void:
	if can_exit and Input.is_action_just_pressed("jump_0"):
		SaveManager.write_save()
		if Global.current_campaign == "SMBANN":
			Global.open_disco_results()
		elif seen or Global.world_num > 8 or Global.current_game_mode != Global.GameMode.CAMPAIGN:
			Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
		else:
			CreditsLevel.go_to_title_screen = false
			Global.transition_to_scene("res://Scenes/Levels/Credits.tscn")
	$LevelBG.combo_progress = 1
	DiscoLevel.can_meter_tick = false

func tally_score() -> void:
	add_lives_to_score()

func add_lives_to_score() -> void:
	for i in Global.lives:
		AudioManager.play_global_sfx("1_up")
		Global.score += 100000
		await get_tree().create_timer(0.5, false).timeout

func show_toads() -> void:
	for i in $Toads.get_children():
		i.show()
		AudioManager.play_global_sfx("coin")
		await get_tree().create_timer(0.7, false).timeout
	await get_tree().create_timer(1, false).timeout
	can_exit = true
