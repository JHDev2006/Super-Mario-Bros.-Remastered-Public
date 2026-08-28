class_name OffScreenDespawner
extends Node

var can_despawn := false

static var editor_testing_safety := false

func _ready() -> void:
	can_despawn = false
	await get_tree().create_timer(0.5, false).timeout
	can_despawn = true

func on_screen_exited() -> void:
	if editor_testing_safety:
		return
	if Global.level_editor != null:
		if Global.level_editor.current_state == LevelEditor.EditorState.PLAYTESTING or Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
			if can_despawn:
				owner.queue_free()
	else:
		owner.queue_free()
