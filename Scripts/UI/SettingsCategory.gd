extends VBoxContainer

@export var category_name := "Hi"
@export var options: Array[Control] = []

var selected_index := -1

@export var minimum_idx := -1

@export var active := true

@export var description_node: Control = null
@export var scroll_container: ScrollContainer = null
@export var scroll_step := 8

var can_input := true

func _process(_delta: float) -> void:
	visible = active
	if active and can_input:
		handle_input()
	var idx := 0
	for i in options:
		if i != null:
			i.selected = selected_index == idx and active and can_input
			idx += 1
	if description_node != null and selected_index >= 0 and options[selected_index] != null:
		description_node.text = options[selected_index].value_descs[options[selected_index].selected_index]
	if not active:
		selected_index = minimum_idx

func handle_input() -> void:
	var old_idx := selected_index
	if Global.multibind_action_just_pressed("ui_down"):
		selected_index += 1
	if Global.multibind_action_just_pressed("ui_up"):
		selected_index -= 1
	if scroll_container != null:
		scroll_container.follow_focus = selected_index > minimum_idx
		if selected_index <= minimum_idx:
			scroll_container.scroll_vertical = 0
	selected_index = clamp(selected_index, minimum_idx, options.size() - 1)
	if old_idx != selected_index:
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
		options[selected_index].grab_focus()

func auto_get_options() -> void:
	options.clear()
	selected_index = 0
	for i in get_children():
		if i is HBoxContainer:
			options.append(i)
