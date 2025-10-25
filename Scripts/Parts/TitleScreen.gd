class_name TitleScreen
extends Level

var selected_index := 0

var active := true
static var title_first_load = true
static var return_to := TITLE_RETURN.OPTIONS1
static var return_selected_index := 0

var title_return: TITLE_RETURN

enum TITLE_RETURN{OPTIONS1, OPTIONS2, EXTRAS, STORYOPTIONS, CHALLENGEOPTIONS}

@onready var cursor = %Cursor

static var last_theme := "Overworld"
var last_campaign := "SMB1"
var has_achievements_to_unlock := false
@export var active_options: TitleScreenOptions = null

var star_offset_x := 0
var star_offset_y := 0

func _enter_tree() -> void:
	check_for_unlocked_achievements()
	Global.debugged_in = false
	Global.current_campaign = Settings.file.game.campaign
	Global.in_title_screen = true
	Global.current_game_mode = Global.GameMode.NONE
	last_campaign = Global.current_campaign
	title_first_load = false

func _ready() -> void:
	setup_stars()
	Global.level_theme_changed.connect(setup_stars)
	DiscoLevel.in_disco_level = false
	get_tree().paused = false
	AudioManager.stop_all_music()
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.NONE, true)
	Global.reset_values()
	Global.second_quest = false
	SpeedrunHandler.timer = 0
	SpeedrunHandler.timer_active = false
	SpeedrunHandler.show_timer = false
	SpeedrunHandler.ghost_active = false
	SpeedrunHandler.ghost_enabled = false
	Global.player_ghost.apply_data()
	get_tree().call_group("PlayerGhosts", "delete")
	Global.current_level = null
	Global.world_num = clamp(Global.world_num, 1, get_world_count())
	update_title()
	if return_to == TITLE_RETURN.OPTIONS2:
		%Options1.close()
		%Options2.open()
		%Options2.selected_index = return_selected_index
	elif return_to == TITLE_RETURN.EXTRAS:
		%Options1.close()
		%Extras.open()
		%Extras.selected_index = return_selected_index
	elif return_to == TITLE_RETURN.STORYOPTIONS:
		get_highscore()
		%Options1.close()
		%StoryOptions.open()
		%StoryOptions.selected_index = return_selected_index
	elif return_to == TITLE_RETURN.CHALLENGEOPTIONS:
		%Options1.close()
		%ChallengeOptions.open()
		%ChallengeOptions.selected_index = return_selected_index
	return_to = TITLE_RETURN.OPTIONS1
	return_selected_index = 0

func update_title() -> void:
	SaveManager.apply_save(SaveManager.load_save(Global.current_campaign))
	level_id = Global.level_num - 1
	world_id = Global.world_num
	update_theme()
	await get_tree().physics_frame
	$LevelBG.time_of_day = ["Day", "Night"].find(Global.theme_time)
	$LevelBG.update_visuals()

func play_bgm() -> void:
	if has_achievements_to_unlock:
		await get_tree().create_timer(3, false).timeout
		has_achievements_to_unlock = false
	if Settings.file.audio.menu_bgm == 1:
		await get_tree().physics_frame
		$BGM.play()

func _process(_delta: float) -> void:
	Global.can_time_tick = false
	cursor.global_position = active_options.options[active_options.selected_index].global_position - Vector2(8, -4)
	$BGM.stream_paused = Settings.file.audio.menu_bgm == 0
	if $BGM.is_playing() == false and Settings.file.audio.menu_bgm == 1 and has_achievements_to_unlock == false:
		$BGM.play()

func campaign_selected() -> void:
	if last_campaign != Global.current_campaign:
		last_campaign = Global.current_campaign
		update_title()
	if Global.current_campaign == "SMBANN":
		Global.current_game_mode = Global.GameMode.CAMPAIGN
		$CanvasLayer/AllNightNippon/WorldSelect.open()
		return
	$CanvasLayer/Options1.close()
	$CanvasLayer/Options2.open()

func open_story_options() -> void:
	if Global.game_beaten:
		%QuestSelect.open()
		await %QuestSelect.selected
	$CanvasLayer/StoryMode/StoryOptions.selected_index = 1
	%Options2.close()
	$CanvasLayer/StoryMode/StoryOptions/HighScore.text = "Top- " + str(Global.high_score).pad_zeros(6)
	$CanvasLayer/Options1.close()
	$CanvasLayer/StoryMode/StoryOptions.open()

func continue_story() -> void:
	Global.current_game_mode = Global.GameMode.CAMPAIGN
	if Global.game_beaten or Global.debug_mode:
		go_back_to_first_level()
		$CanvasLayer/StoryMode/QuestSelect.open()
	else:
		$CanvasLayer/StoryMode/NoBeatenCharSelect.open()

func check_for_warpless() -> void:
	SpeedrunHandler.is_warp_run = false
	SpeedrunHandler.ghost_enabled = false
	if SpeedrunHandler.WARP_LEVELS[Global.current_campaign].has(str(Global.world_num) + "-" + str(Global.level_num)):
		%SpeedrunTypeSelect.open()
	elif (SpeedrunHandler.best_level_any_times.get(str(Global.world_num) + "-" + str(Global.level_num), -1) > -1 or SpeedrunHandler.best_level_warpless_times[Global.world_num - 1][Global.level_num - 1] > -1):
		$CanvasLayer/MarathonMode/HasRan/GhostSelect.open()
	else: $CanvasLayer/MarathonMode/CharacterSelect.open()

func check_for_ghost() -> void:
	SpeedrunHandler.ghost_enabled = false
	if SpeedrunHandler.is_warp_run and SpeedrunHandler.best_level_any_times.get(str(Global.world_num) + "-" + str(Global.level_num), -1) > -1:
		$CanvasLayer/MarathonMode/HasRan/GhostSelect.open()
	elif SpeedrunHandler.best_level_warpless_times[Global.world_num - 1][Global.level_num - 1] > -1 and SpeedrunHandler.is_warp_run == false:
		$CanvasLayer/MarathonMode/HasRan/GhostSelect.open()
	else:
		$CanvasLayer/MarathonMode/HasWarp/CharacterSelect.open()

func get_highscore() -> void:
	%HighScore.text = "TOP- " + str(Global.high_score).pad_zeros(6)
	if Global.world_num == 1 and Global.level_num == 1 and Global.score <= 0:
		%StoryOptions.selected_index = 0
	else:
		%StoryOptions.selected_index = 1

func clear_stats() -> void:
	Global.clear_saved_values()

func go_back_to_first_level() -> void:
	Global.world_num = 1
	Global.level_num = 1
	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)

func start_game() -> void:
	PipeCutscene.seen_cutscene = false
	first_load = true
	Global.reset_values()
	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func start_full_run() -> void:
	Global.second_quest = false
	Global.current_game_mode = Global.GameMode.MARATHON
	SpeedrunHandler.timer = 0
	if SpeedrunHandler.is_warp_run:
		SpeedrunHandler.best_time = SpeedrunHandler.marathon_best_any_time
	else:
		SpeedrunHandler.best_time = SpeedrunHandler.marathon_best_warpless_time
	SpeedrunHandler.show_timer = true
	SpeedrunHandler.timer_active = false
	Global.clear_saved_values()
	Global.reset_values()
	Global.world_num = 1
	Global.level_num = 1
	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func start_level_run() -> void:
	Global.second_quest = false
	Global.current_game_mode = Global.GameMode.MARATHON_PRACTICE
	SpeedrunHandler.timer = 0
	if SpeedrunHandler.is_warp_run:
		SpeedrunHandler.best_time = SpeedrunHandler.best_level_any_times.get(str(Global.world_num) + "-" + str(Global.level_num), -1)
	else:
		SpeedrunHandler.best_time = SpeedrunHandler.best_level_warpless_times[Global.world_num - 1][Global.level_num - 1]
	SpeedrunHandler.show_timer = true
	SpeedrunHandler.timer_active = false
	SpeedrunHandler.enable_recording = true
	Global.clear_saved_values()
	Global.reset_values()
	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func _exit_tree() -> void:
	Global.in_title_screen = false

func challenge_hunt_selected() -> void:
	Global.second_quest = false
	Global.current_game_mode = Global.GameMode.CHALLENGE
	Global.reset_values()
	Global.clear_saved_values()
	Global.score = 0
	$CanvasLayer/ChallengeHunt/WorldSelect.open()

func challenge_hunt_start() -> void:
	Global.second_quest = false
	PipeCutscene.seen_cutscene = false
	first_load = true
	ChallengeModeHandler.red_coins = 0
	var value = int(ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1])
	for i in [1, 2, 4, 8, 16]: # 5 bits (you can expand this as needed)
		if value & i:
			ChallengeModeHandler.red_coins += 1


	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
	ChallengeModeHandler.current_run_red_coins_collected = ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num -1]
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func world_9_selected() -> void:
	Global.second_quest = false
	Global.current_game_mode = Global.GameMode.CAMPAIGN
	Global.reset_values()
	Global.clear_saved_values()
	Global.world_num = 9
	Global.level_num = 1
	%ExtraWorldSelect.open()

func setup_stars() -> void:
	var idx := 0
	$Logo/Control/HFlowContainer.position = Vector2(96, 12) + Vector2(star_offset_x, star_offset_y)
	$Logo/Control/HFlowContainer.visible = Global.achievements.contains("1")
	for i in Global.achievements:
		$Logo/Control/HFlowContainer.get_child(idx).visible = (i == "1")
		idx += 1

func go_to_achievement_menu() -> void:
	Global.transition_to_scene("res://Scenes/Levels/AchievementMenu.tscn")

func go_to_boo_menu() -> void:
	Global.transition_to_scene("res://Scenes/Levels/BooRaceMenu.tscn")

func open_options() -> void:
	$CanvasLayer/SettingsMenu.open()
	active_options.active = false
	await $CanvasLayer/SettingsMenu.closed
	active_options.active = true

func quit_game() -> void:
	get_tree().quit()

func new_game_selected() -> void:
	Global.second_quest = false
	Global.current_game_mode = Global.GameMode.CAMPAIGN
	if Global.game_beaten:
		%QuestSelect.open()
	else:
		$CanvasLayer/StoryMode/NewUnbeatenGame/NoBeatenCharSelect.open()

func continue_game() -> void:
	SaveManager.apply_save(SaveManager.load_save(Global.current_campaign))
	Global.current_game_mode = Global.GameMode.CAMPAIGN
	if Global.game_beaten or Global.debug_mode:
		$CanvasLayer/StoryMode/ContinueBeatenGame/WorldSelect.open()
	else:
		$CanvasLayer/StoryMode/ContinueUnbeatenGame/CharacterSelect.open()

func on_story_options_closed() -> void:
	$CanvasLayer/Options2.open()

func go_to_credits() -> void:
	CreditsLevel.go_to_title_screen = true
	CreditsLevel.view_from_menu = true
	Global.transition_to_scene("res://Scenes/Levels/Credits.tscn")
 
func check_for_unlocked_achievements() -> void:
	var new_achievements := []
	var idx := 0
	for i in Global.achievements:
		if AchievementMenu.unlocked_achievements[idx] != i and i == "1":
			new_achievements.append(idx)
		idx += 1
	if new_achievements.is_empty() == false:
		has_achievements_to_unlock = true
		%AchievementUnlock.show_popup(new_achievements)
	AchievementMenu.unlocked_achievements = Global.achievements

func get_room_type() -> Global.Room:
	return Global.Room.TITLE_SCREEN
