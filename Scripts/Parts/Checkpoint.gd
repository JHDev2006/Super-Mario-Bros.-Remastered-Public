class_name Checkpoint
extends Node2D

@export var nodes_to_delete: Array[Node] = []

@export var optional := false

signal crossed(player: Player)
signal respawned

static var passed := false
static var respawn_position := Vector2.ZERO
static var level := ""
static var sublevel_id := 0
static var keys_collected := 0
static var old_state := [[], []]
static var unlocked_doors := []

func _enter_tree() -> void:
	if Global.level_editor != null:
		if sublevel_id != Global.level_editor.sub_level_id and passed:
			passed = false
	if passed:
		LevelPersistance.active_nodes = old_state.duplicate(true)

func _ready() -> void:
	if [Global.GameMode.CHALLENGE, Global.GameMode.MARATHON_PRACTICE].has(Global.current_game_mode):
		queue_free()
		return
	if has_meta("is_flag") == false:
		hide()
		if Settings.file.difficulty.checkpoint_style != 0:
			queue_free()
	if passed and PipeArea.exiting_pipe_id == -1 and Global.current_game_mode != Global.GameMode.LEVEL_EDITOR and Level.vine_return_level == "":
		for i in nodes_to_delete:
			i.queue_free()
		for i in get_tree().get_nodes_in_group("Players"):
			i.global_position = self.global_position
			i.reset_physics_interpolation()
			i.recenter_camera()
		KeyItem.total_collected = keys_collected
		respawned.emit()


func _exit_tree() -> void:
	pass

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player and not passed:
		var player: Player = area.owner
		player.passed_checkpoint()
		passed = true
		keys_collected = KeyItem.total_collected
		old_state = LevelPersistance.active_nodes.duplicate(true)
		unlocked_doors = Door.unlocked_doors.duplicate()
		Level.start_level_path = Global.current_level.scene_file_path
		if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR or Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
			sublevel_id = Global.level_editor.sub_level_id
		if Settings.file.difficulty.checkpoint_style == 2 and has_meta("is_flag"):
			if player.power_state.state_name == "Small":
				player.get_power_up("Big")
		respawn_position = global_position
		crossed.emit(area.owner)


func on_tree_exiting() -> void:
	pass # Replace with function body.
