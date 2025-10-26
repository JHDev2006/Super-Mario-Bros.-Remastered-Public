class_name SelectableInputOption
extends HBoxContainer

@export var settings_category := "video"
@export var selected := false
@export var can_bind_escape := false

@export var action_names := [""]
@export var title := ""

@export_enum("Keyboard", "Controller") var type := 0
@export var player_idx := 0

signal input_changed(action_name: String, input_event: InputEvent)

var awaiting_input := false

static var rebinding_input := false

var event_name := ""

var can_remap := true

var current_device_brand := 0

var current_binding_idx := 0

var input_events: Array[InputEvent] = [null, null]

const button_id_translation := [
	["A", "B", "✕"],
	["B", "A", "○"],
	["X", "Y", "□"],
	["Y", "X", "△"],
	["Select", "-", "Share"],
	"Home",
	["Start", "+", "Options"],
	["LS Push", "LS Push", "L3"],
	["RS Push", "RS Push", "R3"],
	["LB", "L", "L1"],
	["RB", "R", "R1"],
	"DPad U",
	"DPad D",
	"DPad L",
	"DPad R" 
]

func _ready() -> void:
	update_value()

func _process(_delta: float) -> void:
	if selected:
		handle_inputs()
	$Cursor.modulate.a = int(selected)

func update_value() -> void:
	$Title.text = tr(title) + ":"
	if awaiting_input:
		$Value.text = "Press Any..."
	else:
		if current_binding_idx == 0:
			$Value.text = "(" + get_event_string(input_events[0]) + "), " + get_event_string(input_events[1]) + " "
		else:
			$Value.text = " " + get_event_string(input_events[0]) + " ,(" + get_event_string(input_events[1]) + ")"

func handle_inputs() -> void:
	if can_remap:
		if selected:
			if Input.is_action_just_pressed("ui_accept"):
				begin_remap()
		if Input.is_action_just_pressed("ui_right"):
			current_binding_idx = 1
			update_value()
		elif Input.is_action_just_pressed("ui_left"):
			current_binding_idx = 0
			update_value()

func begin_remap() -> void:
	$Timer.stop()
	$Timer.start()
	rebinding_input = true
	can_remap = false
	get_parent().can_input = false
	await get_tree().create_timer(0.1).timeout
	awaiting_input = true
	update_value()

func _input(event: InputEvent) -> void:
	if awaiting_input == false: return
	
	if event.is_pressed() == false:
		return
	
	if event is InputEventKey and not can_bind_escape:
		if event.as_text_physical_keycode() == "Escape":
			map_event_to_action(null, current_binding_idx)
			return
	
	if type == 0 and event is InputEventKey:
		map_event_to_action(event, current_binding_idx)
	elif type == 1 and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		if event is InputEventJoypadMotion:
			event.axis_value = sign(event.axis_value)
		map_event_to_action(event, current_binding_idx)

func map_event_to_action(event, idx := 0) -> void:
	for action_name in action_names:
		var action = action_name
		if action.contains("ui_") == false and action != "pause":
			action = action_name + "_" + str(player_idx)
		var replace_event = null
		var events = InputMap.action_get_events(action).duplicate()
		var matching_type_events := []
		for i in events:
			if type == 0 and i is InputEventKey:
				matching_type_events.append(i)
			elif type == 1 and (i is InputEventJoypadButton or i is InputEventJoypadMotion):
				matching_type_events.append(i)
		if matching_type_events.size() - 1 < idx or matching_type_events.is_empty():
			events.append(event)
		else:
			replace_event = matching_type_events[clamp(idx, 0, matching_type_events.size() - 1)]
			var itr := 0
			for i in events:
				if i == replace_event:
					events[itr] = event
				itr += 1
		InputMap.action_erase_events(action)
		for i in events:
			InputMap.action_add_event(action, i)
		input_changed.emit(action, event)
		input_events[idx] = event
	awaiting_input = false
	await get_tree().create_timer(0.1).timeout
	rebinding_input = false
	get_parent().can_input = true
	can_remap = true
	update_value()

func get_event_string(event: InputEvent) -> String:
	var event_string := ""
	if event == null:
		return "---"
	if event is InputEventKey:
		event_string = OS.get_keycode_string(event.keycode)
	elif event is InputEventJoypadButton:
		var translation = button_id_translation[event.button_index]
		if translation is Array:
			translation = translation[current_device_brand]
		event_string = translation
	elif event is InputEventJoypadMotion:
		var stick = "LS"
		var direction = "Left"
		if event.axis == JOY_AXIS_TRIGGER_LEFT:
			return ["LT", "ZL", "L2"][current_device_brand]
		elif event.axis == JOY_AXIS_TRIGGER_RIGHT:
			return ["RT", "ZR", "R2"][current_device_brand]
		
		if event.axis == JOY_AXIS_RIGHT_X or event.axis == JOY_AXIS_RIGHT_Y:
			stick = "RS"
		if (event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_RIGHT_X):
			if event.axis_value < 0:
				direction = "Left"
			else:
				direction = "Right"
		elif (event.axis == JOY_AXIS_LEFT_Y or event.axis == JOY_AXIS_RIGHT_Y):
			if event.axis_value < 0:
				direction = "Up"
			else:
				direction = "Down"
		event_string = stick + " " + direction
	else:
		pass
	return event_string

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventJoypadButton and event is not InputEventJoypadMotion:
		return
	var device_name = Input.get_joy_name(event.device)
	var old_brand = current_device_brand
	if device_name.to_upper().contains("NINTENDO") or device_name.to_upper().contains("SWITCH") or device_name.to_upper().contains("WII"):
		current_device_brand = 1
	elif device_name.to_upper().contains("PS") or device_name.to_upper().contains("PLAYSTATION"):
		current_device_brand = 2
	else:
		current_device_brand = 0
	if old_brand != current_device_brand:
		update_value()

func cancel_remap() -> void:
	awaiting_input = false
	await get_tree().create_timer(0.1).timeout
	rebinding_input = false
	get_parent().can_input = true
	can_remap = true
	update_value()
