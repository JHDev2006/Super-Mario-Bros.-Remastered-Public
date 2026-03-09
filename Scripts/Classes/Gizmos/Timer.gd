extends Node2D

@export_range(0, 5.0, 0) var duration := 1.0:
	set(value):
		duration = value
		$Timer.wait_time = duration

@export var loop := false
@export var reset_when_lost_power := false

func level_start() -> void:
	await get_tree().physics_frame
	if $SignalExposer.total_inputs <= 0:
		start_timer()

func timeout() -> void:
	%Label.modulate = Color.GREEN
	if loop:
		start_timer()

func _process(_delta: float) -> void:
	if $Timer.is_stopped():
		if Global.level_editor_is_playtesting():
			%Label.text = "0.0"
		else:
			%Label.text = str(float(duration)).substr(0, 3)
	else:
		%Label.text = str(float($Timer.time_left)).substr(0, 3)
		
func start_timer() -> void:
	$Timer.start(duration)
	%Label.modulate = Color.WHITE

func on_lost_power() -> void:
	if reset_when_lost_power:
		$Timer.stop()
		if Global.level_editor_is_playtesting():
			%Label.text = "0.0"
			%Label.modulate = Color.RED
