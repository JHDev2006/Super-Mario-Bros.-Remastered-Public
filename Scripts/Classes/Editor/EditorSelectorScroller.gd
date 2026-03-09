class_name EditorSelectorScroller
extends Control

@export var selected_index := 0

var selectors: Array[Control] = []

var duped_selectors: Array[Control] = []

var expanded := false

func _ready() -> void:
	for i in get_children():
		if i is EditorTileSelector:
			selectors.append(i)
			i.get_node("Button").mouse_entered.connect(set_physics_process.bind(true))
			i.get_node("Button").mouse_exited.connect(set_physics_process.bind(false))
	_physics_process(0)
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	handle_inputs()
	for i in selectors.size():
		selectors[i].visible = i == selected_index

func handle_inputs() -> void:
	var old_selected := selected_index
	if Global.multibind_action_just_pressed("scroll_up"):
		selected_index += 1
	if Global.multibind_action_just_pressed("scroll_down"):
		selected_index -= 1
	selected_index = clamp(selected_index, 0, selectors.size() - 1)
	if old_selected != selected_index:
		selectors[selected_index].get_node("Button").mouse_entered.emit()
