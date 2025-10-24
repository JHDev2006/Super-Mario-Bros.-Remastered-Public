extends "res://Scripts/UI/StoryPause.gd"

func _ready() -> void:
	close()

func _process(_delta: float) -> void:
	if active:
		handle_inputs()
		is_pause = true
		Global.game_paused = true
	cursor.global_position.y = options[selected_index].global_position.y + 4
	cursor.global_position.x = options[selected_index].global_position.x - 10

func handle_inputs() -> void:
	if Input.is_action_just_pressed("ui_down"):
		selected_index += 1
	if Input.is_action_just_pressed("ui_up"):
		selected_index -= 1
	selected_index = clamp(selected_index, 0, options.size() - 1)
	if Input.is_action_just_pressed("ui_accept"):
		option_selected()
	elif (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_back") or (Input.is_action_just_pressed("editor_play") and Global.level_editor_is_playtesting())):
		close_all()

func close_all() -> void:
	if (%SettingsMenu != null):
		%SettingsMenu.close()
		await %SettingsMenu.closed
	close()

func exit_to_editor() -> void:
	close_all()
	Checkpoint.passed_checkpoints.clear()
	Global.level_editor.stop_testing()

func quit_to_menu() -> void:
	Checkpoint.passed_checkpoints.clear()
	Global.level_editor.stop_testing()
	await get_tree().create_timer(1.5).timeout
	# Global.level_editor.save_level()
	# Hide the cancel button
	#Global.level_editor.get_node("Info").get_node("QuitDialog").get_node("Cancel").visible = false
	#Global.level_editor.quit_editor()
	#await Global.level_editor.level_saved
	#await get_tree().create_timer(1.0).timeout
	AudioManager.stop_all_music()
	Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")
	get_tree().paused = true
	await Global.current_level.tree_exited
	close()
