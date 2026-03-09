extends Node2D

var total_inputs := 0

@export_enum("AND", "OR", "NOT", "XOR") var type := 0

signal condition_met
signal condition_lost

var condition_filled := false

func _ready() -> void:
	if Global.level_editor_is_editing() == false:
		update.call_deferred()

func input_added() -> void:
	total_inputs += 1
	update()

func update() -> void:
	#this line was causing a one frame delay in all scenarios, which is not very good
	#if is_inside_tree():
		#await get_tree().process_frame
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
	input_added()
	input_lost()


func input_lost() -> void:
	total_inputs -= 1
	update()


func on_visibility_changed() -> void:
	pass # Replace with function body.
