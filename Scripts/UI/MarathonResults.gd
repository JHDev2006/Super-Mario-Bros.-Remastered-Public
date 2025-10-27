extends Control

var selected_index := 0

func setup_visuals() -> void:
	%Time.text = SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(SpeedrunHandler.timer))
	var best_time = SpeedrunHandler.best_time
	if best_time <= 0 or SpeedrunHandler.best_time > SpeedrunHandler.timer:
		best_time = SpeedrunHandler.timer
		AudioManager.stop_all_music()
		$PBSfx.play()
	%PB.text = SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(best_time))
	%NewPB.visible = SpeedrunHandler.timer < SpeedrunHandler.best_time or SpeedrunHandler.best_time <= 0
	var target_time = -1
	%LevelSelect.visible = Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		if SpeedrunHandler.is_warp_run:
			target_time = SpeedrunHandler.LEVEL_GOLD_ANY_TIMES[Global.current_campaign][str(Global.world_num) + "-" + str(Global.level_num)]
		else:
			target_time = SpeedrunHandler.LEVEL_GOLD_WARPLESS_TIMES[Global.current_campaign][Global.world_num - 1][Global.level_num - 1]
	else:
		if SpeedrunHandler.is_warp_run:
			target_time = SpeedrunHandler.GOLD_ANY_TIMES[Global.current_campaign]
		else:
			target_time = SpeedrunHandler.GOLD_WARPLESS_TIMES[Global.current_campaign]
	%Target.text = SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(target_time))
	var medal_index := -1
	if SpeedrunHandler.timer <= target_time:
		medal_index = 2
	elif SpeedrunHandler.timer <= target_time * SpeedrunHandler.MEDAL_CONVERSIONS[1]:
		medal_index = 1
	elif SpeedrunHandler.timer <= target_time * SpeedrunHandler.MEDAL_CONVERSIONS[0]:
		medal_index = 0
	%Medal.get_node("Full").visible = medal_index >= 0
	%Medal.get_node("Full").region_rect.position = Vector2(8 * medal_index, 0)
	if medal_index >= 0:
		%Time.modulate = [Color("C6691D"), Color("BCBCBC"), Color("FFB259")][medal_index]
	else:
		%Time.modulate = Color.WHITE

func open() -> void:
	set_focus(true)
	setup_visuals()
	show()
	return_focus()

func return_focus() -> void:
	await get_tree().physics_frame
	[%Restart, %LevelSelect, %Return][selected_index].grab_focus()

func check_for_warp() -> void:
	SpeedrunHandler.is_warp_run = false
	if SpeedrunHandler.WARP_LEVELS[Global.current_campaign].has(str(Global.world_num) + "-" + str(Global.level_num)) or Global.current_game_mode == Global.GameMode.MARATHON:
		$SpeedrunTypeSelect.open()
	else:
		restart_level()

func set_focus(enabled := false) -> void:
	for i in [%Restart, %LevelSelect, %Return]:
		i.focus_mode = 0 if enabled == false else 2

func check_for_warp_level_select_edition() -> void:
	SpeedrunHandler.is_warp_run = false
	if SpeedrunHandler.WARP_LEVELS[Global.current_campaign].has(str(Global.world_num) + "-" + str(Global.level_num)):
		$SpeedrunTypeSelectLevelSelect.open()
	else:
		restart_level()

func restart_level() -> void:
	var path := ""
	SpeedrunHandler.timer = 0
	Global.reset_values()
	Global.clear_saved_values()
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		path = Level.get_scene_string(Global.world_num, Global.level_num)
	else:
		Global.world_num = 1
		Global.level_num = 1
		path = Level.get_scene_string(1, 1)
	SpeedrunHandler.best_time = SpeedrunHandler.get_best_time()
	Level.start_level_path = path
	LevelTransition.level_to_transition_to = path
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")
	close()

func go_to_menu() -> void:
	TitleScreen.return_to = TitleScreen.TITLE_RETURN.OPTIONS2
	TitleScreen.return_selected_index = 2
	Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func close() -> void:
	hide()
