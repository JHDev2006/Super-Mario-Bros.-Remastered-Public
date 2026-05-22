extends HBoxContainer

var selected := false
@export var title := ""
var selected_index := 0
@export var values: Array[String] = []
@export var add_colon := true

signal value_changed(new_index: int)

func _process(_delta: float) -> void:
	if selected:
		handle_inputs()
	$Title/Cursor.visible = (selected)
	$Title.text = tr(title) + (":" if add_colon else "")
	$Value.text = ("◄" if selected_index > 0 and selected else " ") + tr(str(values[selected_index])) + ("►" if selected_index < values.size() - 1 and selected else " ")

func set_selected(active := false) -> void:
	selected = active

func handle_inputs() -> void:
	var old := selected_index
	var scroll_up := mouse_filter == Control.MOUSE_FILTER_STOP and Input.is_action_just_pressed("scroll_up")
	var scroll_down := mouse_filter == Control.MOUSE_FILTER_STOP and Input.is_action_just_pressed("scroll_down")
	
	
	if Global.multibind_action_just_pressed("ui_left") or scroll_up:
		selected_index -= 1
	if Global.multibind_action_just_pressed("ui_right") or scroll_down:
		selected_index += 1
	selected_index = clamp(selected_index, 0, values.size() - 1)
	if old != selected_index:
		value_changed.emit(selected_index)
	
