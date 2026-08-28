extends HBoxContainer

enum Number {Float, Integer}

@export var selectMode := Number.Float
@export var settings_category := "video"
@export var option_key := ""

@export_category("Information")
@export var title := ""
@export var extraInfo := ""
@export var value_descs := ""

@export_category("Options")
@export var minimum := 0.0
@export var maximum := 1.0
@export var step = 0.1

@onready var selected := false

signal value_changed(new_value: Variant)

var selected_index := 0.0:
	set(value):
		selected_index = value

var value := 0.5

var holding = false
var bufferingDelay = 0
var bufferFull

func _ready() -> void:
	await get_tree().process_frame
	update_starting_values()

func _process(_delta: float) -> void:
	bufferFull = 0.5 * Engine.get_frames_per_second()
	
	if selected:
		handle_inputs()
	$Cursor.modulate.a = int(selected)
	
	if (selectMode == Number.Float):
		%Value.text = str(Settings.file[settings_category][option_key]).pad_decimals(str(step).length() - 2)
		while (%Value.text.length() < str(step).length()):
			%Value.text += "0"
	else:
		var intConv := int(Settings.file[settings_category][option_key])
		%Value.text = str(intConv)

	if (extraInfo != ""):
		%Value.text += " " + extraInfo
	
	%LeftArrow.modulate.a = int(selected and selected_index > minimum)
	%RightArrow.modulate.a = int(selected and selected_index < maximum)
	%Title.text = tr(title) + ":"
	$AutoScrollContainer.is_focused = selected

func update_starting_values() -> void:
	if Settings.file.has(settings_category):
		if Settings.file[settings_category].has(option_key):
			selected_index = Settings.file[settings_category][option_key]

func handle_inputs() -> void:
	var pressed = false
	var old := selected_index
	if Input.is_action_pressed("ui_left"):
		pressed = true
		if ((!holding && bufferingDelay == 0) || holding):
			selected_index -= step
			if Settings.file.audio.extra_sfx == 1:
				AudioManager.play_global_sfx("menu_move")
		
		if (!holding):
			bufferingDelay += 1
			if (bufferingDelay >= bufferFull):
				holding = true
	if Input.is_action_pressed("ui_right"):
		pressed = true
		if ((!holding && bufferingDelay == 0) || holding):
			selected_index += step
			if Settings.file.audio.extra_sfx == 1:
				AudioManager.play_global_sfx("menu_move")
		
		if (!holding):
			bufferingDelay += 1
			if (bufferingDelay >= bufferFull):
				holding = true
	
	selected_index = clamp(selected_index, minimum, maximum)
	if (!pressed):
		holding = false
		bufferingDelay = 0
	
	if old != selected_index:
		value_changed.emit(selected_index)

func set_selected(active := false) -> void:
	selected = active
