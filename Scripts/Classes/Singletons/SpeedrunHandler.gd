extends Node

var timer := 0.0
var best_time := 0.0

var marathon_best_any_time := 0.0
var marathon_best_warpless_time := 0.0

var timer_active := false

var show_timer := false

signal level_finished

var paused_time := 0.0

var start_time := 0.0

const GHOST_RECORDING_TEMPLATE := {
	"position": Vector2.ZERO,
	"character": "Mario",
	"power_state": "Small",
	"animation": "Idle",
	"frame": 0,
	"direction": 1,
	"level": ""
}

var enable_recording := false

var current_recording := ""
var ghost_recording := ""
var ghost_active := false
var ghost_idx := -1
var ghost_visible := false
var ghost_enabled := false
var levels := []
var anim_list := []
var show_pb_diff := true

var is_warp_run := false

var ghost_path := []

var best_time_campaign := ""

var best_level_any_times := {}

var best_level_warpless_times := [
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1]
]

const GOLD_ANY_TIMES := {
	"SMB1": 390,
	"SMBLL": 660,
	"SMBS": 1440
}

const GOLD_WARPLESS_TIMES := {
	"SMB1": 1320,
	"SMBLL": 1380,
	"SMBS": 1440
}

const WARP_LEVELS := {
	"SMB1": SMB1_WARP_LEVELS,
	"SMBLL": SMBLL_WARP_LEVELS,
	"SMBS": SMBS_WARP_LEVELS
}

const LEVEL_GOLD_WARPLESS_TIMES := {
	"SMB1": SMB1_LEVEL_GOLD_WARPLESS_TIMES,
	"SMBLL": SMBLL_LEVEL_GOLD_WARPLESS_TIMES,
	"SMBS": SMBS_LEVEL_GOLD_TIMES
}

const LEVEL_GOLD_ANY_TIMES := {
	"SMB1": SMB1_LEVEL_GOLD_ANY_TIMES,
	"SMBLL": SMBLL_LEVEL_GOLD_ANY_TIMES,
	"SMBS": SMBS_LEVEL_GOLD_ANY_TIMES
}

const SMB1_LEVEL_GOLD_WARPLESS_TIMES := [
	[17, 24, 17, 16],  # World 1
	[23, 38, 25, 16],  # World 2
	[23, 23, 17, 16],  # World 3
	[24, 25, 16, 22],  # World 4
	[22, 22, 17, 16],  # World 5
	[21, 25, 18, 16],  # World 6
	[20, 38, 25, 23],  # World 7
	[40, 24, 24, 50],  # World 8
	[-1, -1, -1, -1],  # World 9
	[-1, -1, -1, -1],  # World A
	[-1, -1, -1, -1],  # World B
	[-1, -1, -1, -1],  # World C
	[-1, -1, -1, -1]   # World D
]

const SMBLL_LEVEL_GOLD_WARPLESS_TIMES := [
	[21, 25, 19, 17],
	[26, 34, 21, 18],
	[21, 39, 21, 20],
	[22, 23, 21, 25],
	[43, 28, 25, 24],
	[28, 39, 23, 29],
	[21, 26, 32, 36],
	[24, 27, 25, 60],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1]
]

const SMB1_LEVEL_GOLD_ANY_TIMES := {
	"1-2": 25,
	"4-2": 26
}

const SMBLL_LEVEL_GOLD_ANY_TIMES := {
	"1-2": 40,
	"3-1": 22,
	"5-1": 52,
	"5-2": 35,
	"8-1": 44
}

const SMBS_LEVEL_GOLD_ANY_TIMES := {
	"4-2": 30
}

const SMBS_LEVEL_GOLD_TIMES := [
	[28, 21, 32, 19],
	[27, 40, 31, 19],
	[31, 11, 16, 20],
	[26, 30, 25, 32],
	[28, 26, 19, 19],
	[24, 21, 23, 20],
	[24, 40, 30, 27],
	[30, 35, 30, 43],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1]
]

const SMB1_WARP_LEVELS := ["1-2", "4-2"]

const SMBLL_WARP_LEVELS := ["1-2", "3-1", "5-1", "5-2", "8-1"]

const SMBS_WARP_LEVELS := ["4-2"]

const MEDAL_CONVERSIONS := [2, 1.5, 1]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(delta: float) -> void:
	if timer_active:
		if Global.game_paused and Global.current_game_mode != Global.GameMode.MARATHON:
			paused_time += delta
		else:
			timer = (abs(start_time - Time.get_ticks_msec()) / 1000) - paused_time
		if enable_recording:
			if get_tree().get_first_node_in_group("Players") != null:
				record_frame(get_tree().get_first_node_in_group("Players"))
	else:
		paused_time = 0
	Global.player_ghost.visible = ghost_visible
	if ghost_active and ghost_enabled:
		ghost_idx += 1
		if ghost_idx >= ghost_path.size():
			ghost_active = false
			return
		Global.player_ghost.apply_data(ghost_path[ghost_idx])

func start_timer() -> void:
	timer = 0
	paused_time = 0
	timer_active = true
	show_timer = true
	start_time = Time.get_ticks_msec()

func record_frame(player: Player) -> void:
	var data := ""
	if levels.has(Global.current_level.scene_file_path) == false:
		levels.append(Global.current_level.scene_file_path)
	data += str(int(player.global_position.x)) + "="
	data += str(int(player.global_position.y)) + "="
	data += str(["Small", "Big", "Fire"].find(player.power_state.state_name)) + "="
	if anim_list.has(player.sprite.animation) == false:
		anim_list.append(player.sprite.animation)
	data += str(anim_list.find(player.sprite.animation)) + "="
	data += str(player.sprite.frame) + "="
	data += str(player.sprite.scale.x) + "="
	data += str(levels.find(Global.current_level.scene_file_path))
	current_recording += data + ","

func format_time(time_time := 0.0) -> Dictionary:
	var floor_time = floor(abs(time_time * 100))
	var mils = int(floor_time) % 100
	var secs = int(floor_time / 100) % 60
	var mins = floor_time / 6000
	return {"mils": int(mils), "secs": int(secs), "mins": int(mins)}
	
func met_target_time(record_time := -1.0, target_time := 0.0) -> bool:
	if record_time < 0.0:
		return false
	# Ignore units of time smaller than a centisecond, as they're not displayed.
	# Matching time exactly counts as beating it.
	return int(record_time * 100) <= int(target_time * 100)

func gen_time_string(timer_dict := {}) -> String:
	return str(int(timer_dict["mins"])).pad_zeros(2) + ":" + str(int(timer_dict["secs"])).pad_zeros(2) + ":" + str(int(timer_dict["mils"])).pad_zeros(2)

func save_recording() -> void:
	var recording := [timer, current_recording, levels, str(["Mario", "Luigi", "Toad", "Toadette"].find(get_tree().get_first_node_in_group("Players").character)), anim_list]
	var recording_dir = Global.config_path.path_join("marathon_recordings/" + Global.current_campaign)
	DirAccess.make_dir_recursive_absolute(recording_dir)
	var file = FileAccess.open(recording_dir + "/" + str(Global.world_num) + "-" + str(Global.level_num) + ("warp" if is_warp_run else "") + ".json", FileAccess.WRITE)
	file.store_string(compress_recording(JSON.stringify(recording, "", false, true)))
	current_recording = ""
	file.close()
	levels.clear()

func compress_recording(recording := "") -> String:
	print(recording)
	var bytes = recording.to_ascii_buffer()
	var compressed_bytes = bytes.compress(FileAccess.CompressionMode.COMPRESSION_DEFLATE)
	var b64 = Marshalls.raw_to_base64(compressed_bytes)
	return b64

func decompress_recording(recording := "") -> Array:
	var compressed_bytes = Marshalls.base64_to_raw(recording)
	var bytes = compressed_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_DEFLATE)
	var string = bytes.get_string_from_ascii()
	var json = JSON.parse_string(string)
	return json

func load_best_marathon() -> void:
	var recording = load_recording(Global.world_num, Global.level_num, not is_warp_run, Global.current_campaign)
	if recording == []:
		best_time = -1
		ghost_active = false
		ghost_recording = ""
		ghost_path = []
		levels = []
		anim_list = []
	else:
		ghost_active = true
		ghost_recording = recording[1]
		ghost_path = ghost_recording.split(",", false)
		levels = recording[2].duplicate()
		anim_list = recording[4].duplicate()

func load_recording(world_num := 0, level_num := 0, is_warpless := true, campaign := "SMB1") -> Array:
	var recording_dir = Global.config_path.path_join("marathon_recordings/" + campaign)
	var path = recording_dir + "/" + str(world_num) + "-" + str(level_num) + ("" if is_warpless else "warp") + ".json"
	print(path)
	if FileAccess.file_exists(path) == false:
		return []
	var file = FileAccess.open(path, FileAccess.READ)
	var text = decompress_recording(file.get_as_text())
	file.close()
	return text

func load_best_times(campaign = Global.current_campaign) -> void:
	if best_time_campaign == campaign:
		return
	best_time_campaign = campaign
	best_level_any_times.clear()
	for world_num in 13:
		for level_num in 4:
			var path = Global.config_path.path_join("marathon_recordings/" + campaign + "/" + str(world_num + 1) + "-" + str(level_num + 1) + ".json")
			if FileAccess.file_exists(path):
				best_level_warpless_times[world_num][level_num] = load_recording(world_num + 1, level_num + 1, true, campaign)[0]
			else:
				best_level_warpless_times[world_num][level_num] = -1
			path = Global.config_path.path_join("marathon_recordings/" + campaign + "/" + str(world_num + 1) + "-" + str(level_num + 1) +"warp" + ".json")
			if FileAccess.file_exists(path):
				best_level_any_times[str(world_num + 1) + "-" + str(level_num + 1)] = load_recording(world_num + 1, level_num + 1, false, campaign)[0]
	check_for_medal_achievement()

func run_finished() -> void:
	if timer_active == false:
		return
	SpeedrunHandler.ghost_active = false
	SpeedrunHandler.ghost_idx = -1
	SpeedrunHandler.timer_active = false
	if Global.current_game_mode == Global.GameMode.BOO_RACE:
		pass
	else:
		var best := -1
		if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
			if is_warp_run:
				best = best_level_any_times.get(str(Global.world_num) + "-" + str(Global.level_num), -1)
			else:
				best = best_level_warpless_times[Global.world_num - 1][Global.level_num - 1]
		else:
			if is_warp_run:
				best = marathon_best_any_time
			else:
				best = marathon_best_warpless_time
		
		if best <= 0 or best > timer:
			if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
				save_recording()
				if is_warp_run:
					best_level_any_times[str(Global.world_num) + "-" + str(Global.level_num)] = timer
				else:
					best_level_warpless_times[Global.world_num - 1][Global.level_num - 1] = timer
			else:
				if is_warp_run:
					marathon_best_any_time = timer
				else:
					marathon_best_warpless_time = timer
		if Global.current_game_mode == Global.GameMode.MARATHON:
			match Global.current_campaign:
				"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_RUN)
				"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_RUN)
				"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_RUN)
		check_for_medal_achievement()
	SaveManager.write_save(Global.current_campaign)

func get_best_time() -> float:
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		if is_warp_run:
			return best_level_any_times[str(Global.world_num) + "-" + str(Global.level_num)]
		else:
			return best_level_warpless_times[Global.world_num - 1][Global.level_num - 1]
	else:
		if is_warp_run:
			return marathon_best_any_time
		else:
			return marathon_best_warpless_time

func check_for_medal_achievement() -> void:

	var has_gold_levels_warpless := true
	var has_gold_levels_any := true
	var has_gold_full := false
	
	var has_silver_levels_warpless := true
	var has_silver_levels_any := true
	var has_silver_full := false
	
	var has_bronze_levels_warpless := true
	var has_bronze_levels_any := true
	var has_bronze_full := false
	
	if Global.current_campaign == "SMBANN":
		return
	
	
	for i in LEVEL_GOLD_ANY_TIMES[Global.current_campaign]:
		if best_level_any_times.has(i):
			if not met_target_time(best_level_any_times[i], LEVEL_GOLD_ANY_TIMES[Global.current_campaign][i]):
				has_gold_levels_any = false
			if not met_target_time(best_level_any_times[i], LEVEL_GOLD_ANY_TIMES[Global.current_campaign][i] * MEDAL_CONVERSIONS[1]):
				has_silver_levels_any = false
			if not met_target_time(best_level_any_times[i], LEVEL_GOLD_ANY_TIMES[Global.current_campaign][i] * MEDAL_CONVERSIONS[0]):
				has_bronze_levels_any = false
		else:
			has_gold_levels_any = false
			has_silver_levels_any = false
			has_bronze_levels_any = false
	
	var world := 0
	for i in best_level_warpless_times:
		var level := 0
		for x in i:
			if not met_target_time(x, LEVEL_GOLD_WARPLESS_TIMES[Global.current_campaign][world][level]):
				has_gold_levels_warpless = false
			if not met_target_time(x, LEVEL_GOLD_WARPLESS_TIMES[Global.current_campaign][world][level] * MEDAL_CONVERSIONS[1]):
				has_silver_levels_warpless = false
			if not met_target_time(x, LEVEL_GOLD_WARPLESS_TIMES[Global.current_campaign][world][level] * MEDAL_CONVERSIONS[0]):
				has_bronze_levels_warpless = false
			level += 1
		world += 1
	
	if (met_target_time(marathon_best_any_time, GOLD_ANY_TIMES[Global.current_campaign]) and 
		met_target_time(marathon_best_warpless_time, GOLD_WARPLESS_TIMES[Global.current_campaign])):
		has_gold_full = true
	if (met_target_time(marathon_best_any_time, GOLD_ANY_TIMES[Global.current_campaign] * MEDAL_CONVERSIONS[1]) and 
		met_target_time(marathon_best_warpless_time, GOLD_WARPLESS_TIMES[Global.current_campaign] * MEDAL_CONVERSIONS[1])):
		has_silver_full = true
	if (met_target_time(marathon_best_any_time, GOLD_ANY_TIMES[Global.current_campaign] * MEDAL_CONVERSIONS[0]) and 
		met_target_time(marathon_best_warpless_time, GOLD_WARPLESS_TIMES[Global.current_campaign] * MEDAL_CONVERSIONS[0])):
		has_bronze_full = true
	
	if has_gold_levels_warpless and has_gold_levels_any and has_gold_full:
		match Global.current_campaign:
			"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_GOLD)
			"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_GOLD)
			"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_GOLD)
	
	if has_silver_levels_any and has_silver_levels_warpless and has_silver_full:
		match Global.current_campaign:
			"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_SILVER)
			"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_SILVER)
			"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_SILVER)
	
	if has_bronze_levels_warpless and has_bronze_levels_any and has_bronze_full:
		match Global.current_campaign:
			"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_BRONZE)
			"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_BRONZE)
			"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_BRONZE)
