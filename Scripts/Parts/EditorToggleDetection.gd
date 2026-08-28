class_name LevelEditorToggleDetection
extends Node

signal toggled

signal level_start
signal editor_start

func _ready() -> void:
	if is_instance_valid(Global.level_editor):
		Global.level_editor.level_start.connect(toggled.emit)
		Global.level_editor.level_start.connect(level_start.emit)
		Global.level_editor.editor_start.connect(editor_start.emit)
		Global.level_editor.editor_start.connect(toggled.emit)
		if Global.level_editor_is_playtesting():
			await get_tree().process_frame
			level_start.emit()
		return
	await get_tree().process_frame
	level_start.emit()
