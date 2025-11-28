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
	if Input.is_action_just_pressed("ui_down"):
		selected_index += 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if Input.is_action_just_pressed("ui_up"):
		selected_index -= 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if scroll_container != null:
		scroll_container.scroll_vertical = float(lerpf(0.0, scroll_container.get_v_scroll_bar().max_value, inverse_lerp(0.0, options.size() - 1, selected_index - 2)))
	selected_index = wrapi(selected_index, minimum_idx, options.size())

func auto_get_options() -> void:
	options.clear()
	selected_index = 0
	for i in get_children():
		if i is HBoxContainer:
			options.append(i)
