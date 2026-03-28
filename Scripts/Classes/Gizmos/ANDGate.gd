extends Node2D

var total_inputs := 0

@export_enum("AND", "OR", "NOT", "XOR") var type := 0

signal condition_met
signal condition_lost
signal positive_pulse

signal finished_check

var condition_filled := false

var checking := false

func _ready() -> void:
	if Global.level_editor_is_editing() == false:
		update.call_deferred()

func input_added() -> void:
	total_inputs += 1
	update.call_deferred()

func update() -> void:
	total_inputs = clamp(total_inputs, 0, INF)
	var test_condition = get_condition()
	if test_condition != condition_filled:
		if test_condition == true:
			condition_met.emit()
		else:
			condition_lost.emit()
	condition_filled = test_condition

func get_condition() -> bool:
	match type:
		0:
			return total_inputs >= $SignalExposer.total_inputs
		1:
			return total_inputs > 0
		2:
			return total_inputs == 0
		3:
			return total_inputs > 0 and total_inputs < $SignalExposer.total_inputs
		_:
			return false

func pulse_recieved() -> void:
	total_inputs += 1
	check_pulse.call_deferred()
	await finished_check
	total_inputs -= 1

func check_pulse() -> void:
	if checking:
		return
	checking = true
	if get_condition():
		positive_pulse.emit()
	checking = false
	finished_check.emit()

func input_lost() -> void:
	total_inputs -= 1
	update.call_deferred()


func on_visibility_changed() -> void:
	pass # Replace with function body.
