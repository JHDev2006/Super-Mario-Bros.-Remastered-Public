@icon("res://Assets/Sprites/Editor/Level.png")
class_name Level
extends Node

@export var music: JSON = null
@export_enum("Overworld", "Underground", "Desert", "Snow", "Jungle", "Beach", "Garden", "Mountain", "Skyland", "Autumn", "Pipeland", "Space", "Underwater", "Volcano", "Castle", "CastleWater", "Airship", "Bonus") var theme := "Overworld"

@export_enum("Day", "Night") var theme_time := "Day"

const THEME_IDXS := ["Overworld", "Underground", "Desert", "Snow", "Jungle", "Beach", "Garden", "Mountain", "Skyland", "Autumn", "Pipeland", "Space", "Underwater", "Volcano", "GhostHouse", "Castle", "CastleWater", "Airship", "Bonus"]

const WORLD_COUNTS := {
	"SMB1": 8,
	"SMBLL": 13,
	"SMBS": 8,
	"SMBANN": 8
}

const WORLD_THEMES := {
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

func _enter_tree() -> void:
	Global.current_level = self
	update_theme()
	SpeedrunHandler.timer_active = true
	SpeedrunHandler.ghost_active = true
	if can_set_time:
		can_set_time = false
		Global.time = time_limit
	if first_load:
		start_level_path = scene_file_path
		Global.can_time_tick = true
		Global.level_num = level_id
		Global.world_num = world_id
		PlayerGhost.idx = 0
		SpeedrunHandler.current_recording = ""
		if SpeedrunHandler.timer <= 0:
			SpeedrunHandler.start_time = Time.get_ticks_msec()
	else:
		level_id = Global.level_num
		world_id = Global.world_num
	if Settings.file.difficulty.back_scroll == 1 and Global.current_game_mode != Global.GameMode.CUSTOM_LEVEL:
		can_backscroll = true
	first_load = false
	if Global.connected_players > 1:
		spawn_in_extra_players()
	Global.current_campaign = campaign
	await get_tree().process_frame
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.NONE, true)

const PLAYER = preload("res://Scenes/Prefabs/Entities/Player.tscn")

func spawn_in_extra_players() -> void:
	await ready
	for i in Global.connected_players - 1:
		var player_node = PLAYER.instantiate()
		player_node.player_id = i + 1
		player_node.global_position = get_tree().get_first_node_in_group("Players").global_position + Vector2(16 * (i + 1), 0)
		add_child(player_node)

func update_theme() -> void:
	if auto_set_theme:
		theme = WORLD_THEMES[Global.current_campaign][Global.world_num]
		campaign = Global.current_campaign
		if Global.world_num > 4 and Global.world_num < 9:
			theme_time = "Night"
		else:
			theme_time = "Day"
		if Global.current_campaign == "SMBANN":
			theme_time = "Night"
		ResourceSetterNew.cache.clear()
	Global.current_campaign = campaign
	Global.level_theme = theme
	Global.theme_time = theme_time
	TitleScreen.last_theme = theme
	$LevelBG.update_visuals()

func update_next_level_info() -> void:
	next_level = wrap(level_id + 1, 1, 5)
	next_world = world_id if level_id != 4 else world_id + 1 
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
