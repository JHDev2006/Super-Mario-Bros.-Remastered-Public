class_name LevelTransition
extends Node

const PIPE_CUTSCENE_LEVELS := {
	"SMB1": [[1, 2], [2, 2], [4, 2], [7, 2]],
	"SMBLL": [[1, 2], [3, 2], [5, 2], [6, 2], [10, 2], [11, 2]],
	"SMBS": [[1, 2], [2, 2], [3, 1], [7, 2], [8, 3]],
	"SMBANN": []
	}

const PIPE_CUTSCENE_OVERRIDE := {
	"SMB1": {[2, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn", [7, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn"},
	"SMBLL": {[3, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn", [11, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn"},
	"SMBS": {[3, 1]: "res://Scenes/Levels/SMBS/SPCastlePipeCutscene.tscn", [7, 2]: "res://Scenes/Levels/PipeCutsceneWater.tscn"},
	"SMBANN": {}
}


var can_transition := false
var level_best_time := 0.0

static var level_to_transition_to := "res://Scenes/Levels/World1/1-1.tscn":
	set(value):
		level_to_transition_to = value
		pass

@export var text_shadows: Array[Label] = []

func _ready() -> void:
	WarpPipeArea.has_warped = false
	Global.level_theme = "Underground"
	$BG/Control/MarathonPB.visible = Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE
	$BG/Control/LivesCount.visible = Global.current_game_mode != Global.GameMode.MARATHON_PRACTICE
	Level.can_set_time = true
	ResourceSetterNew.cache.clear()
	ResourceSetterNew.property_cache.clear()
	AudioManager.current_level_theme = ""
	Level.vine_return_level = ""
	Level.vine_warp_level = ""
	Level.in_vine_level = false
	Global.p_switch_active = false
	Lakitu.present = false
	Global.p_switch_timer = -1
	if Checkpoint.passed_checkpoints.is_empty() == false:
		Door.unlocked_doors = Checkpoint.unlocked_doors.duplicate()
	else:
		Door.unlocked_doors = []
	if Global.current_campaign == "SMBANN":
		DiscoLevel.reset_values()
	DiscoLevel.first_load = true
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		Global.clear_saved_values()
		if SpeedrunHandler.ghost_enabled:
			SpeedrunHandler.load_best_marathon()
		SpeedrunHandler.ghost_active = false
		show_best_time()
		Level.first_load = true
		SpeedrunHandler.ghost_idx = -1
		SpeedrunHandler.timer_active = false
		SpeedrunHandler.timer = 0
	get_tree().call_group("PlayerGhosts", "delete")
	get_tree().paused = false
	$Timer.start()
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.NONE, true)
	AudioManager.music_player.stop()
	PipeArea.exiting_pipe_id = -1
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
	$BG/Control/WorldNum.text = str(world_num) +"-" + str(Global.level_num)
	if [Global.GameMode.CUSTOM_LEVEL, Global.GameMode.LEVEL_EDITOR].has(Global.current_game_mode):
		$BG/Control/LivesCount.text = "☠ * " + str(Global.total_deaths)
	elif Settings.file.difficulty.inf_lives:
		$BG/Control/LivesCount.text = "*  ∞"
	elif Global.lives < 100:
		$BG/Control/LivesCount.text = "* " + (str(Global.lives).lpad(2, " "))
	else:
		$BG/Control/LivesCount.text = "*  ♕"
	if Global.current_game_mode == Global.GameMode.CHALLENGE:
		handle_challenge_mode_transition()
	if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
		$BG/Control/World.hide()
		$BG/Control/WorldNum.hide()
		%CustomLevelAuthor.show()
		%CustomLevelName.show()
		%CustomLevelAuthor.text = "By " + LevelEditor.level_author
		%CustomLevelName.text = LevelEditor.level_name
		
	await get_tree().create_timer(0.1, false).timeout
	can_transition = true

func handle_challenge_mode_transition() -> void:
	$BG/Control/LivesCount.hide()
	$BG/Control/Sprite.hide()
	%ChallengeScore.show()
	%ChallengeScoreText.show()
	%ChallengeScoreText/Target.show()
	%ChallengeCoins2.show()
	%ChallengeCoins.show()
	%ChallengeScoreText.text = str(int(ChallengeModeHandler.top_challenge_scores[Global.world_num - 1][Global.level_num - 1]))
	var idx = 0
	for i in %ChallengeCoins.get_children():
		if ChallengeModeHandler.is_coin_collected(idx, ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1]):
			i.frame = 1
		else:
			i.frame = 0
		idx += 1
	%ChallengeScoreText/Target.text = "/ " + str(ChallengeModeHandler.CHALLENGE_TARGETS[Global.current_campaign][Global.world_num - 1][Global.level_num - 1])

	
func transition() -> void:
	Global.can_time_tick = true
	if PIPE_CUTSCENE_LEVELS[Global.current_campaign].has([Global.world_num, Global.level_num]) and not PipeCutscene.seen_cutscene and Global.current_game_mode != Global.GameMode.MARATHON_PRACTICE and Global.current_game_mode !=Global.GameMode.BOO_RACE:
		if PIPE_CUTSCENE_OVERRIDE[Global.current_campaign].has([Global.world_num, Global.level_num]):
			Global.transition_to_scene(PIPE_CUTSCENE_OVERRIDE[Global.current_campaign][[Global.world_num, Global.level_num]])
		else:
			Global.transition_to_scene("res://Scenes/Levels/PipeCutscene.tscn")
	else:
		Global.transition_to_scene(level_to_transition_to)

func show_best_time() -> void:
	var best_time = SpeedrunHandler.best_time
	if SpeedrunHandler.best_time <= 0:
		$BG/Control/MarathonPB.text = "\nNO PB"
		return
	var string = "PB\n" + SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(SpeedrunHandler.best_time))
	$BG/Control/MarathonPB.text = string

func _process(_delta: float) -> void:
	if can_transition:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump_0"):
			transition()

func _exit_tree() -> void:
	Global.death_load = false
