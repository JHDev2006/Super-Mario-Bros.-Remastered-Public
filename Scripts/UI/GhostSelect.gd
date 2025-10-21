extends Control

var selected_index := 0

var active := false

signal selected
signal cancelled

func _ready() -> void:
	pass

func open() -> void:
	show()
	await get_tree().physics_frame
	active = true

func _process(_delta: float) -> void:
	if active == false: return
	if Input.is_action_just_pressed("ui_down"):
		selected_index += 1
	elif Input.is_action_just_pressed("ui_up"):
		selected_index -= 1
	selected_index = wrapi(selected_index, 0, 2)
	if Input.is_action_just_pressed("ui_accept"):
		selected.emit()
		SpeedrunHandler.ghost_enabled = bool(selected_index)
		close()
	elif Input.is_action_just_pressed("ui_back"):
		close()
		cancelled.emit()
	var idx := 0
	for i in [%NoGhost, %Ghost]:
		i.get_node("Cursor").modulate.a = int(selected_index == idx)
		idx += 1

func load_ghost() -> void:
	SpeedrunHandler.load_best_marathon()

func close() -> void :
	hide()
	active = false
