class_name LevelTransition
extends Node

const PIPE_CUTSCENE_LEVELS := {
	"SMB1": [[1, 2], [2, 2], [4, 2], [7, 2]],
	"SMBLL": [[1, 2], [3, 2], [5, 2], [6, 2], [10, 2], [11, 2]],
	"SMBS": [[1, 2], [2, 2], [3, 1], [7, 2], [8, 3]],
	"SMBANN": [[1, 2], [2, 2], [4, 2], [7, 2]]
	}

const PIPE_CUTSCENE_OVERRIDE := {
	"SMB1": {[2, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn", [7, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn"},
	"SMBLL": {[3, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn", [6, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn", [11, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn"},
	"SMBS": {[2, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn", [3, 1]: "res://Scenes/Levels/SMBS/SPCastlePipeCutscene.tscn", [7, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn"},
	"SMBANN": {[2, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn", [7, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn"},
}


var can_transition := false
var level_best_time := 0.0

static var level_to_transition_to := "res://Scenes/Levels/World1/1-1.tscn":
	set(value):
		level_to_transition_to = value
		pass

@export var text_shadows: Array[Label] = []

func _ready() -> void:
	Global.level_theme = "Underground"
	value_cleanup()
	get_tree().call_group("PlayerGhosts", "delete")
	get_tree().paused = false
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.NONE, true)
	AudioManager.music_player.stop()
	var world_num = str(Global.world_num)
	if world_num == "-1":
		world_num = " "
	if Global.world_num >= 10:
		world_num = ["A", "B", "C", "D"][Global.world_num % 10]
	
	var lvl_idx := SaveManager.get_level_idx(Global.world_num, Global.level_num)
	SaveManager.visited_levels[lvl_idx] = "1"
	
	if Global.current_game_mode == Global.GameMode.CAMPAIGN:
		SaveManager.write_save(Global.current_campaign)
	DiscordManager.set_discord_status("Playing " + Global.current_campaign + ": " + str(world_num) + "-" + str(Global.level_num))
	%WorldNum.text = str(world_num) +"-" + str(Global.level_num)
	if Settings.file.difficulty.inf_lives:
		%LivesCount.text = "*  ∞"
	elif Global.lives < 100:
		%LivesCount.text = "* " + (str(Global.lives).lpad(2, " "))
	else:
		%LivesCount.text = "*  ♕"
	%DeathCount.text = "☠* " + str(Global.total_deaths).lpad(2, " ")
	if Global.current_game_mode == Global.GameMode.CHALLENGE:
		handle_challenge_mode_transition()
	if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
		%CustomLevel.show()
		%Default.hide()
		%CustomLevelAuthor.text = "By " + LevelEditor.level_author
		%CustomLevelName.text = LevelEditor.level_name
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		%LivesCount.hide()
		%Marathon.show()
		show_best_time()
	await get_tree().create_timer(0.1, false).timeout
	$TextShadowColourChanger.queue_free()
	begin_transition_wait()

func begin_transition_wait() -> void:
	if Global.current_game_mode != Global.GameMode.CUSTOM_LEVEL and not Global.in_custom_campaign():
		can_transition = true
		$Timer.start()
	else:
		if NewLevelBuilder.sub_levels == [null, null, null, null, null]:
			if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
				Global.clear_saved_values()
			Global.reset_values()
			wait_for_build_completion()
			%Loading.show()
			await get_tree().create_timer(0.1, false).timeout
			if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
				NewLevelBuilder.load_level(LevelEditor.level_file)
			else:
				var level_file_name = Global.custom_campaign_jsons[Global.current_custom_campaign].levels[Global.custom_level_idx]
				var path = Global.config_path.path_join("level_packs").path_join(Global.current_custom_campaign).path_join(level_file_name)
				Level.first_load = true
				var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
				NewLevelBuilder.load_level(json)
		else:
			$Timer.start()
			await get_tree().create_timer(0.1, false).timeout
			can_transition = true


func wait_for_build_completion() -> void:
	await NewLevelBuilder.level_building_complete
	can_transition = true
	%Loading.hide()

func handle_challenge_mode_transition() -> void:
	%LivesCount.hide()
	%PlayerSprite.hide()
	%ChallengeMode.show()
	%ChallengeScoreText.text = str(int(ChallengeModeHandler.top_challenge_scores[Global.world_num - 1][Global.level_num - 1]))
	var idx = 0
	for i in %ChallengeCoins.get_children():
		if ChallengeModeHandler.is_coin_collected(idx, ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1]):
			i.frame = 1
		else:
			i.frame = 0
		idx += 1
	%ChallengeScoreText/Target.text = "/ " + str(ChallengeModeHandler.CHALLENGE_TARGETS[Global.current_campaign][Global.world_num - 1][Global.level_num - 1])

func value_cleanup() -> void:
	WarpPipeArea.has_warped = false
	Level.can_set_time = true
	PipeArea.exiting_pipe_id = -1
	ResourceSetterNew.clear_cache()
	AudioManager.current_level_theme = ""
	Level.vine_return_level = ""
	Level.vine_warp_level = ""
	Level.in_vine_level = false
	Global.p_switch_active = false
	Lakitu.present = false
	Door.exiting_door_id = -1
	Global.p_switch_timer = -1
	ConditionalClear.valid = true
	ConditionalClear.checked = false
	if Checkpoint.passed_checkpoints.is_empty() == false:
		Door.unlocked_doors = Checkpoint.unlocked_doors.duplicate()
		KeyItem.total_collected = Checkpoint.keys_collected
		LevelPersistance.active_nodes = Checkpoint.old_state.duplicate(true)
		GlobalCounter.amounts = Checkpoint.global_counters.duplicate()
		Broadcaster.active_channels = Checkpoint.broadcasters.duplicate()
	else:
		GlobalCounter.amounts.clear()
		Broadcaster.active_channels.clear()
		LevelPersistance.reset_states()
		Door.unlocked_doors = []
		KeyItem.total_collected = 0
	if Global.current_game_mode == Global.GameMode.DISCO:
		DiscoLevel.reset_values()
	DiscoLevel.first_load = true
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		Global.clear_saved_values()
		SpeedrunHandler.ghost_active = false
		Level.first_load = true
		SpeedrunHandler.ghost_idx = -1
		SpeedrunHandler.timer_active = false
		SpeedrunHandler.timer = 0

func transition() -> void:
	Global.can_time_tick = true
	if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL or Global.in_custom_campaign():
		Global.transition_to_scene(NewLevelBuilder.sub_levels[Checkpoint.sublevel_id])
	else:
		if PIPE_CUTSCENE_LEVELS[Global.current_campaign].has([Global.world_num, Global.level_num]) and not PipeCutscene.seen_cutscene and [Global.GameMode.BOO_RACE, Global.GameMode.MARATHON_PRACTICE].has(Global.current_game_mode) == false:
			if PIPE_CUTSCENE_OVERRIDE[Global.current_campaign].has([Global.world_num, Global.level_num]):
				Global.transition_to_scene(PIPE_CUTSCENE_OVERRIDE[Global.current_campaign][[Global.world_num, Global.level_num]])
			else:
				Global.transition_to_scene("res://Scenes/Levels/PipeCutscene.tscn")
		else:
			Global.transition_to_scene(level_to_transition_to)

func show_best_time() -> void:
	var best_time = SpeedrunHandler.best_time
	if SpeedrunHandler.best_time <= 0:
		%MarathonPB.text = "\nNO PB"
		return
	var string = "PB\n" + SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(SpeedrunHandler.best_time))
	%MarathonPB.text = string

func _process(_delta: float) -> void:
	if can_transition:
		if Global.multibind_action_just_pressed("ui_accept") or Global.multibind_action_just_pressed("jump_0"):
			transition()

func _exit_tree() -> void:
	Global.death_load = false
