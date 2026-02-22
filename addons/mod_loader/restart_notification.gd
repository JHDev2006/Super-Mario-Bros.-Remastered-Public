extends Control


@export var wait_time := 20.0

@onready var timer_label: Label = %TimerLabel
@onready var timer: Timer = %Timer

@onready var restart_button: Button = %RestartButton
@onready var cancel_button: Button = %CancelButton


func _ready() -> void:
	cancel_button.pressed.connect(cancel)
	restart_button.pressed.connect(restart)
	restart_button.grab_focus()

	timer.timeout.connect(restart)
	timer.start(wait_time)


func  _process(delta: float) -> void:
	timer_label.text = "%d" % (timer.time_left -1)


func cancel() -> void:
	timer.stop()
	hide()
	queue_free()


func restart() -> void:
	OS.set_restart_on_exit(true)
	get_tree().quit()
