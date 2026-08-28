extends Label

signal pressed

@export var accept_mouse_clicks := false

func _ready() -> void:
	if accept_mouse_clicks == false:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if Global.multibind_action_just_pressed("ui_accept") || (Input.is_action_just_pressed("mb_left") and accept_mouse_clicks):
		pressed.emit()

func toggle_process(enabled := false) -> void:
	set_process(enabled)
