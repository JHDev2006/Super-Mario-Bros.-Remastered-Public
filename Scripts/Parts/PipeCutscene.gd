class_name PipeCutscene
extends Level

static var seen_cutscene := false

func _enter_tree() -> void:
	Global.game_paused = false
	theme = WORLD_THEMES[Global.current_campaign][Global.world_num]
	if Global.world_num > 4 and Global.world_num <= 8:
		theme_time = "Night"
	else:
		theme_time = "Day"
	Global.current_room = get_room_type()
	Global.level_theme = theme
	Global.theme_time = theme_time

func _ready() -> void:
	Global.current_level = null
	seen_cutscene = true
	first_load = true
	$Music.play()

func update_next_level_info() -> void:
	pass

func go_to_level() -> void:
	first_load = true
	Global.transition_to_scene(LevelTransition.level_to_transition_to)

func play_pipe_sfx() -> void:
	AudioManager.play_sfx("pipe", $Player1.global_position)

func get_room_type() -> Global.Room:
	return Global.Room.PIPE_CUTSCENE
