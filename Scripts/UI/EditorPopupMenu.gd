extends Control

var active := false

signal closed

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	if Global.multibind_action_just_pressed("ui_cancel") or Global.multibind_action_just_pressed("editor_open_menu"):
		close()

func open() -> void:
	set_process(true)
	show()
	active = true

func close() -> void:
	set_process(false)
	hide()
	active = false
	await get_tree().create_timer(0.1).timeout
	closed.emit()
