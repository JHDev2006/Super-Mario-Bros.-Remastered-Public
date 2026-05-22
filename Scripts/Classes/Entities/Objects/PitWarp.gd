class_name PitWarp
extends Node2D

@export_enum("Room 1", "Room 2", "Room 3", "Room 4", "Room 5") var target_sub_level := 0

static var warping := false

func _ready() -> void:
	get_tree().get_first_node_in_group("Players").auto_death_pit = false

func warp_back(player: Player) -> void:
	warping = true
	player.state_machine.transition_to("Freeze")
	await get_tree().create_timer(1, false).timeout
	PipeArea.exiting_pipe_id = -1
	if Global.level_editor != null:
		Global.level_editor.transition_to_sublevel(target_sub_level)
	else:
		Global.transition_to_scene(LevelEditor.sub_areas[target_sub_level])

func _exit_tree() -> void:
	get_tree().get_first_node_in_group("Players").auto_death_pit = true
