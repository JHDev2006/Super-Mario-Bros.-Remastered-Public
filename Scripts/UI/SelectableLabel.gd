extends Label

signal pressed

func _process(_delta: float) -> void:
	if Global.multibind_action_just_pressed("ui_accept"):
		pressed.emit()

func toggle_process(enabled := false) -> void:
	set_process(enabled)
