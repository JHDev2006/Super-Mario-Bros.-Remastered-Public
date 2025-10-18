class_name TextValidator
extends Node

const valid_chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-*!.^/+:,'()?_;<> \n"

@export var node_to_validate: Control = null
const FONT = preload("res://Assets/Sprites/UI/Font.fnt")
signal text_validated(new_text: String)

func validate_text() -> void:
	var idx := 0
	var text = node_to_validate.text.to_upper()
	node_to_validate.clear()
	for i in text:
		if FONT.has_char(text.unicode_at(idx)) == false and valid_chars.contains(i) == false:
			text = text.replace(i, " ")
		idx += 1
	node_to_validate.insert_text_at_caret(text)
