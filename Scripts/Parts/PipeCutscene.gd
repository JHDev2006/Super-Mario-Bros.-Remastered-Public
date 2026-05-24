class_name PipeCutscene
extends Level

static var seen_cutscene := false

func _enter_tree() -> void:
	Global.current_room_type = room_type
	if is_inside_tree():
		update_theme()

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
