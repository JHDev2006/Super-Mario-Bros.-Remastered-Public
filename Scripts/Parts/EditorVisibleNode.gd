class_name LevelEditorVisibleNode
extends Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	update()
	if Global.level_editor != null:
		Global.level_editor.editor_start.connect(update)
		Global.level_editor.level_start.connect(update)

func update() -> void:
	visible = !LevelEditor.playing_level and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR
