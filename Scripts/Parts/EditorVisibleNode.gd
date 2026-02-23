extends Node

@export var is_gizmo := true

func _ready() -> void:
	update()
	if Global.level_editor != null:
		Global.level_editor.editor_start.connect(update)
		Global.level_editor.level_start.connect(update)

func update() -> void:
	var is_visible = (Global.level_editor_is_editing())
	if is_gizmo == false:
		if is_visible == false:
			set("visible", false)
			return
	if Global.level_editor != null:
		is_visible = Global.level_editor.gizmos_visible or Global.level_editor_is_editing()
	set("visible", is_visible)
