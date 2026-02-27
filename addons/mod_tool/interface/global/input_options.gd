@tool
class_name ModToolInterfaceInputOptions
extends ModToolInterfaceInput


@export var input_options: Array[String]: set = set_input_options


func set_input_options(new_options: Array[String]) -> void:
	input_options = new_options
	var input: OptionButton = get_node_or_null("%Input") as OptionButton
	if not input or new_options.is_empty(): return # node can't be found directly after reloading the plugin

	input.clear()
	for option in input_options:
		input.add_item(option)
	input.select(0)


func get_input_value() -> int:
	return ($"%Input" as OptionButton).get_selected_id()


func get_input_string() -> String:
	if get_input_value() == -1:
		return ""
	return input_options[get_input_value()]


func validate(condition: bool) -> bool:
	# Check if input is required and empty
	if is_required and get_input_value() == -1:
		is_valid = false
		return false

	# Invalidate field if the condition is not met
	is_valid = condition
	return is_valid


func _on_Input_item_selected(index: int) -> void:
	emit_signal("value_changed", get_input_string(), self)
