@icon("res://Assets/Sprites/Editor/Level.svg")
class_name Level
extends Node

@export var music: JSON = null
static var extra_music: JSON = null
@export var room_type := RoomType.NORMAL
@export_enum("Overworld", "Underground", "Desert", "Snow", "Jungle", "Beach", "Garden", "Mountain", "Skyland", "Autumn", "Pipeland", "Space", "Underwater", "Volcano", "Castle", "CastleWater", "Airship", "Bonus") var theme := "Overworld"

@export_enum("Day", "Night") var theme_time := "Day"

const THEME_IDXS := ["Overworld", "Underground", "Desert", "Snow", "Jungle", "Beach", "Garden", "Mountain", "Skyland", "Autumn", "Pipeland", "Space", "Underwater", "Volcano", "GhostHouse", "Castle", "CastleWater", "Airship", "Bonus"]

enum RoomType{NORMAL, BONUS_ROOM, COIN_HEAVEN, PIPE_CUTSCENE, TITLE_SCREEN, SublevelExit}
const ROOM_STRINGS := ["MainRoom", "BonusRoom", "CoinHeaven", "PipeCutscene", "TitleScreen", "SublevelExit"]

static var WORLD_COUNTS := {
	"SMB1": 8,
	"SMBLL": 13,
	"SMBS": 8,
	"SMBANN": 8
}

static var WORLD_THEMES := {
	"SMB1": SMB1_THEMES,
	"SMBLL": SMB1_THEMES,
	"SMBS": SMBS_THEMES,
	"SMBANN": SMB1_THEMES
}

const SMB1_THEMES := {
	-1: "Overworld",
	1: "Overworld",
	2: "Desert",
	3: "Snow",
	4: "Jungle",
	5: "Desert",
	6: "Snow",
	7: "Jungle",
	8: "Overworld",
	9: "Space",
	10: "Autumn",
	11: "Pipeland",
	12: "Skyland",
	13: "Volcano"
}

const SMBS_THEMES := {
	1: "Overworld",
	2: "Garden",
	3: "Beach",
	4: "Mountain",
	5: "Garden",
	6: "Beach",
	7: "Mountain",
	8: "Overworld"
}

@export var auto_set_theme := false

@export var time_limit := 400

@export var campaign := "SMB1"

@export var world_id := 1
@export var level_id := 1

@export var vertical_height := -208
@export var can_backscroll := false

static var next_world := 1
static var next_level := 2
static var next_level_file_path := ""
static var first_load := true

static var start_level_path := ""
static var vine_warp_level := ""
static var vine_return_level := ""
static var in_vine_level := false

static var can_set_time := true

@export_storage var enforce_resolution := Vector2.ZERO

func _enter_tree() -> void:
	Global.level_metadata.clear()
	Level.extra_music = null
	Global.current_level = self
	Global.current_room_type = room_type
	if is_inside_tree():
		update_theme()
	SpeedrunHandler.timer_active = true
	SpeedrunHandler.ghost_active = true
	Global.stop_all_timers()
	if can_set_time:
		can_set_time = false
		Global.time = time_limit
	if first_load:
		start_level_path = scene_file_path
		Global.can_time_tick = true
		inf_time_check()
		Global.level_num = level_id
		Global.world_num = world_id
		PlayerGhost.idx = 0
		SpeedrunHandler.current_recording = ""
		if SpeedrunHandler.timer <= 0:
			SpeedrunHandler.start_time = Time.get_ticks_msec()
		if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
			SpeedrunHandler.load_best_marathon()
	else:
		level_id = Global.level_num
		world_id = Global.world_num
	if Settings.file.gameplay.back_scroll == 1 and Global.current_game_mode != Global.GameMode.CUSTOM_LEVEL:
		can_backscroll = true
	first_load = false
	if Global.connected_players > 1:
		spawn_in_extra_players()
	Global.current_campaign = campaign
	await get_tree().process_frame
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.NONE, true)
	apply_resolution_enforcement()
	tree_exiting.connect(reset_resolution)
	tree_exiting.connect(func(): OnOffSwitcher.active = false)

func inf_time_check() -> void:
	Global.inf_time = false
	if time_limit >= 999:
		Global.can_time_tick = false
		Global.inf_time = true

func apply_resolution_enforcement() -> void:
	if enforce_resolution != Vector2.ZERO:
		get_tree().root.content_scale_size = enforce_resolution
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	else:
		reset_resolution()

func reset_resolution() -> void:
	var idx = Settings.file.video.size
	var res = Global.RESOLUTIONS[idx]
	get_tree().root.content_scale_size = res
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if idx == Global.RESOLUTIONS.size() - 1 else Window.CONTENT_SCALE_ASPECT_KEEP


func spawn_in_extra_players() -> void:
	# Fuck you lmao, no multiplayer
	return

func update_theme() -> void:
	Global.update_theme()
	if auto_set_theme:
		if Global.CAMPAIGNS.has(Global.current_campaign) == false and first_load:
			Global.current_campaign = "SMB1"
		if Global.in_custom_campaign() == false:
			theme = WORLD_THEMES[Global.current_campaign][Global.world_num]
			if Global.world_num > 4 and Global.world_num < 9:
				theme_time = "Night"
			else:
				theme_time = "Day"
			if Global.current_campaign == "SMBANN":
				theme_time = "Night"
		else:
			theme = Global.custom_campaign_jsons[Global.current_custom_campaign].world_themes[Global.world_num - 1][0]
			theme_time = Global.custom_campaign_jsons[Global.current_custom_campaign].world_themes[Global.world_num - 1][1]
		campaign = Global.current_campaign
		ResourceSetterNew.clear_cache()
	Global.current_campaign = campaign
	Global.level_theme = theme
	Global.theme_time = theme_time
	TitleScreen.last_theme = theme
	if get_node_or_null("LevelBG") != null:
		$LevelBG.update_visuals()

func update_next_level_info() -> void:
	Global.custom_level_idx += 1
	var level_limit = 4
	if Global.in_custom_campaign():
		LevelEditor.sub_areas = [null, null, null, null, null]
		level_limit = Global.custom_campaign_jsons[Global.current_custom_campaign].levels_per_world[Global.world_num - 1]
	next_level = wrap(level_id + 1, 1, level_limit + 1)
	next_world = world_id if level_id != level_limit else world_id + 1 
	next_level_file_path = get_scene_string(next_world, next_level)
	LevelTransition.level_to_transition_to = next_level_file_path

static func get_scene_string(world_num := 0, level_num := 0) -> String:
	return "res://Scenes/Levels/" + Global.current_campaign + "/World" + str(world_num) + "/" + str(world_num) + "-" + str(level_num) + ".tscn"

static func get_world_count() -> int:
	return WORLD_COUNTS[Global.current_campaign]

func transition_to_next_level() -> void:
	if Global.current_game_mode == Global.GameMode.CHALLENGE:
		Global.transition_to_scene("res://Scenes/Levels/ChallengeModeResults.tscn")
		return
	if Global.current_game_mode == Global.GameMode.BOO_RACE:
		Global.transition_to_scene("res://Scenes/Levels/BooRaceMenu.tscn")
		return
	if Global.in_custom_campaign():
		if Global.custom_campaign_jsons[Global.current_custom_campaign].levels.size() - 1 <= Global.custom_level_idx:
			Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
			Global.game_beaten = true
			SaveManager.write_save()
			return
	update_next_level_info()
	PipeCutscene.seen_cutscene = false
	if WarpPipeArea.has_warped == false:
		Global.level_num = next_level
		Global.world_num = next_world
		LevelTransition.level_to_transition_to = get_scene_string(next_world, next_level)
	first_load = true
	SaveManager.write_save()
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")
	Checkpoint.passed_checkpoints.clear()

func reload_level() -> void:
	LevelTransition.level_to_transition_to = Level.start_level_path
	if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
		LevelTransition.level_to_transition_to = "res://Scenes/Levels/LevelEditor.tscn"
	if Global.current_game_mode == Global.GameMode.BOO_RACE:
		LevelPersistance.reset_states()
		Global.transition_to_scene(LevelTransition.level_to_transition_to)
	else:
		Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")
