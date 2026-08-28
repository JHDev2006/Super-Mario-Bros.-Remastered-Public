extends Label

signal action_pressed
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and has_focus():
		if event.keycode == KEY_ENTER:
			action_pressed.emit()
