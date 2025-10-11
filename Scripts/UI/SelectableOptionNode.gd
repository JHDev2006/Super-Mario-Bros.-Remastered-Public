extends HBoxContainer

@export var option_key := ""
@export var title := ""
@export var value_descs: Array[String] = []
@export var values := []
@export var settings_category := "video"
@export var selected := false

signal value_changed(new_value)

var selected_index := 0:
	set(value):
		selected_index = value

func _ready() -> void:
	await get_tree().process_frame
	update_starting_values()

func update_starting_values() -> void:
	if Settings.file.has(settings_category):
		if Settings.file[settings_category].has(option_key):
			if Settings.file[settings_category][option_key] is String:
				selected_index = values.find(Settings.file[settings_category][option_key])
			else:
				selected_index = Settings.file[settings_category][option_key]
				
func _process(_delta: float) -> void:
	if selected:
		handle_inputs()
	$Cursor.modulate.a = int(selected)
	for i in [$AutoScrollContainer, %AutoScrollContainer2]:
		i.is_focused = selected
	%Title.text = tr(title) + ":"
	%Value.text = tr(str(values[selected_index]))
	%LeftArrow.modulate.a = int(selected and selected_index > 0)
	%RightArrow.modulate.a = int(selected and selected_index < values.size() - 1)

func set_selected(active := false) -> void:
	selected = active

func handle_inputs() -> void:
	var old := selected_index
	if Input.is_action_just_pressed("ui_left"):
		selected_index -= 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if Input.is_action_just_pressed("ui_right"):
		selected_index += 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	selected_index = clamp(selected_index, 0, values.size() - 1)
	if old != selected_index:
		value_changed.emit(selected_index)
	
