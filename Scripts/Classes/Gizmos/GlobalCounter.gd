class_name GlobalCounter
extends Gizmo

var amount := 0
@export_range(0, 99) var channel := 0
@export_range(0, 99) var total_needed := -1
@export var reset_on_total_reached := false

static var amounts := {}

signal total_reached

func _process(_delta: float) -> void:
	%Total.text = str(amount)
	var old_amount = amount
	amount = amounts.get(channel, 0)
	if old_amount != amount:
		update(true)

func increment() -> void:
	amounts[channel] = amounts.get(channel, 0) + 1
	update()

func update(greater := false) -> void:
	if total_needed <= 0:
		$SignalExposer.update_animation()
	if amount == total_needed:
		total_reached.emit()
		if reset_on_total_reached:
			amounts[channel] = amount % total_needed
	elif greater and amount >= total_needed:
		total_reached.emit()
		if reset_on_total_reached:
			amounts[channel] = amount % total_needed


func on_visibility_changed() -> void:
	pass # Replace with function body.
