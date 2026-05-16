class_name CustomLineEdit
extends Label

const FONT_MAIN = preload("uid://bl7sbw4nx3l1t")

var focused := false

static var editing := false

var can_input := false

var input_text := ""

var time := 0.0

signal text_submitted(text: String)

@export var needs_enter := false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and focused:
		if can_input:
			if event.keycode == KEY_BACKSPACE: 
				input_text = input_text.erase(input_text.length() - 1, 1)
			else:
				var character := (char(event.unicode).to_upper())
				var idx := character.unicode_at(0)
				if FONT_MAIN.base_font.has_char(idx):
					input_text += character
			if (!needs_enter && input_text != ""):
				text_submitted.emit(input_text)
			else:
				if (event.keycode == KEY_ENTER):
					text_submitted.emit(input_text)

	elif event.is_released():
		can_input = true

func _process(delta: float) -> void:
	time += 2 * delta
	if focused:
		text = input_text + ("_" if int(time) % 2 == 0 else " ")
	else:
		text = input_text

func on_focus_entered() -> void:
	editing = true
	focused = true

func on_focus_exited() -> void:
	editing = false
	focused = false

func pressed_button() -> void:
	text_submitted.emit(input_text)
