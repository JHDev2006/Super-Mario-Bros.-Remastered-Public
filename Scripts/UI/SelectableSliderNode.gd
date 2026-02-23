extends HBoxContainer

@export var option_key := ""
@export var title := ""

@export var selected := false

signal value_changed(new_value: int)

var selected_index := 5
var value := 0.5
@onready var sfx: AudioStreamPlayer = $SFX

func _ready() -> void:
	update_starting_values()

func update_starting_values() -> void:
	selected_index = Settings.file.audio[option_key]

func _process(_delta: float) -> void:
	if selected:
		handle_inputs()
	$Cursor.modulate.a = int(selected)
	$Value.text = generate_text()
	%Title.text = tr(title) + ":"
	$AutoScrollContainer.is_focused = selected

func generate_text() -> String:
	var string := ""
	string += "◄" if selected and selected_index > 0 else " "
	string += "├"
	for i in 11:
		if i == selected_index:
			string += "┼"
		else:
			string += "-"
	string += "┤"
	string += "►" if selected and selected_index < 10 else " "
	return string

func handle_inputs() -> void:
	var old := selected_index
	if Global.multibind_action_just_pressed("ui_left"):
		selected_index -= 1
		sfx.play()
	if Global.multibind_action_just_pressed("ui_right"):
		selected_index += 1
		sfx.play()
	selected_index = clamp(selected_index, 0, 10)
	if old != selected_index:
		value_changed.emit(selected_index)
	
