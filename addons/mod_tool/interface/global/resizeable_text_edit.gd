@tool
extends VSplitContainer

var previous_size := 0
var is_pressed := false
@onready var text_edit := get_child(0) as TextEdit
@onready var min_size_y := text_edit.custom_minimum_size.y as int


func _ready() -> void:
	connect("dragged", Callable(self, "_on_dragged"))
	connect("gui_input", Callable(self, "_on_gui_input"))
	if get_child_count() < 2:
		add_child(Control.new())


func _on_dragged(offset: int) -> void:
	# offset is cumulative for the whole drag move
	var new_size := previous_size + offset

	if new_size < min_size_y:
		text_edit.custom_minimum_size.y = min_size_y
	else:
		text_edit.custom_minimum_size.y = new_size


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not is_pressed:
				is_pressed = true
				previous_size = text_edit.custom_minimum_size.y
			else:
				is_pressed = false


func _get_configuration_warnings() -> PackedStringArray:
	if not get_child(0) is TextEdit:
		return ["First child needs to be a TextEdit"]
	return [""]
