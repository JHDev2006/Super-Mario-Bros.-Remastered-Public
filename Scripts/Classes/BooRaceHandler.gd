class_name BooRaceHandler
extends Node

@export var boo: Node2D = null
static var boo_colour := 0
@export var boo_block_times := [5, 4, 4.5, 3, 3]

@export var level_id := 0

static var current_level_id := 0

@export var is_custom := false

static var countdown_active := false

static var best_times := [
	-1.0, -1.0, -1.0, -1.0,
	-1.0, -1.0, -1.0, -1.0
]

static var cleared_boo_levels := "00000000"
const SILENCE = preload("res://Assets/Audio/BGM/Silence.json")
func _ready() -> void:
	SpeedrunHandler.show_timer = true
	SpeedrunHandler.timer = 0
	SpeedrunHandler.timer_active = false
	SpeedrunHandler.best_time = best_times[level_id]
	TimedBooBlock.can_tick = false
	current_level_id = level_id
	if is_custom == false:
		Global.current_game_mode = Global.GameMode.BOO_RACE 
		do_countdown()
		

func do_countdown() -> void:
	var old_music = Global.current_level.music
	Global.current_level.music = SILENCE
	countdown_active = true
	get_tree().paused = false
	await get_tree().physics_frame
	TimedBooBlock.can_tick = false
	$Animation.play("CountdownBeep")
	Global.can_time_tick = false
	for i in get_tree().get_nodes_in_group("Players"):
		i.state_machine.transition_to("Freeze")
	await get_tree().create_timer(3, false).timeout
	Global.can_time_tick = true
	for i in get_tree().get_nodes_in_group("Players"):
		i.state_machine.transition_to("Normal")
	$Timer.wait_time = boo_block_times[boo_colour]
	$Timer.start()
	countdown_active = false
	SpeedrunHandler.start_timer()
	boo.move_tween()
	TimedBooBlock.can_tick = true
	await get_tree().create_timer(0.5, false).timeout
	Global.current_level.music = old_music

func tally_time() -> void:
	pass

func player_win_race() -> void:
	SpeedrunHandler.run_finished()
	run_best_time_check()
	TimedBooBlock.can_tick = false
	
	var cleared_boo: int = 0
	for boo_time in boo.time_needed:
		if SpeedrunHandler.timer < boo_time:
			cleared_boo += 1
		else:
			break
	
	if int(BooRaceHandler.cleared_boo_levels[level_id]) <= cleared_boo:
		BooRaceHandler.cleared_boo_levels[level_id] = str(cleared_boo)
	print(BooRaceHandler.cleared_boo_levels)
	SaveManager.write_save(Global.current_campaign)
	boo.flag_die()
	if cleared_boo_levels.contains("0") == false:
		match Global.current_campaign:
			"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_BOO)
			"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_BOO)
			"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_BOO)
	if cleared_boo_levels == "55555555":
		match Global.current_campaign:
			"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_GOLD_BOO)
			"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_GOLD_BOO)
			"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_GOLD_BOO)
	await tree_exiting
	if boo_colour < 4:
		boo_colour += 1

func run_best_time_check() -> void:
	if SpeedrunHandler.timer <= best_times[level_id] or best_times[level_id] < 0:
		best_times[level_id] = SpeedrunHandler.timer

func _exit_tree() -> void:
	countdown_active = false

func on_timeout() -> void:
	if boo.moving:
		boo.play_laugh_animation()
		AudioManager.play_global_sfx("boo_laugh")
		await get_tree().create_timer(1, false).timeout
		get_tree().call_group("BooSwitchBlocks", "on_boo_hit")
