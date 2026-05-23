extends Node2D

@export_range(2, 99) var amount := 2
@export_range(0, 1, 0) var delay := 0.0

func recieved_pulse() -> void:
	for i in amount:
		$SignalExposer.emit_pulse()
		if delay > 0:
			await get_tree().create_timer(delay, false).timeout
		if $SignalExposer.signals_recieved >= $SignalExposer.RECURSIVE_LIMIT:
			return

func recieved_power() -> void:
	for i in amount:
		$SignalExposer.turn_on()
		if delay > 0:
			await get_tree().create_timer(delay, false).timeout
		if $SignalExposer.signals_recieved >= $SignalExposer.RECURSIVE_LIMIT:
			return

func lost_power() -> void:
	for i in amount:
		$SignalExposer.turn_off()
		if delay > 0:
			await get_tree().create_timer(delay, false).timeout
		if $SignalExposer.signals_recieved >= $SignalExposer.RECURSIVE_LIMIT:
			return
