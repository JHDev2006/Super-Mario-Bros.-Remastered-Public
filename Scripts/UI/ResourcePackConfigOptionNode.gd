class_name PackConfigOption
extends HBoxContainer

@export var selected := false

var values := []

signal value_changed(this: PackConfigOption)

var config_name := ""

var selected_index := 0

var is_bool := false

func _process(_delta: float) -> void:
	if selected:
		handle_inputs()
	$Cursor.modulate.a = int(selected)
	$Title.text = tr(config_name) + ":"
	$Value.text = ("◄" if selected_index > 0 and selected else " ") + tr(str(values[selected_index])) + ("►" if selected_index < values.size() - 1 and selected else " ")

func handle_inputs() -> void:
	var old := selected_index
	if Global.multibind_action_just_pressed("ui_left"):
		selected_index -= 1
	if Global.multibind_action_just_pressed("ui_right"):
		selected_index += 1
	selected_index = clamp(selected_index, 0, values.size() - 1)
	if old != selected_index:
		value_changed.emit(self)
	
