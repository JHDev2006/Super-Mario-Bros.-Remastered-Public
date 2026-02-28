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
			duped_selectors.append(i.duplicate())
	add_expanded()

func add_expanded() -> void:
	return
	for i in duped_selectors:
		add_sibling(i)
		i.hide()

func _process(_delta: float) -> void:
	handle_inputs()
	for i in selectors.size():
		selectors[i].visible = i == selected_index
		selectors[i].notification(NOTIFICATION_MOUSE_ENTER)

func handle_inputs() -> void:
	var hovered = false
	for i in selectors:
		if i.get_node("Button").is_hovered():
			hovered = true
			break
	if not hovered:
		return
	if Global.multibind_action_just_pressed("scroll_up"):
		selected_index += 1
		warp_mouse(get_local_mouse_position())
	if Global.multibind_action_just_pressed("scroll_down"):
		selected_index -= 1
		warp_mouse(get_local_mouse_position())
	selected_index = clamp(selected_index, 0, selectors.size() - 1)
