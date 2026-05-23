extends Control


signal selected
signal cancelled

var selected_index := 0
var active := false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if active:
		if Global.multibind_action_just_pressed("ui_down"):
			selected_index += 1
		elif Global.multibind_action_just_pressed("ui_up"):
			selected_index -= 1
		selected_index = clamp(selected_index, 0, 1)
		if Global.multibind_action_just_pressed("ui_accept"):
			SpeedrunHandler.is_warp_run = bool(selected_index)
			selected.emit()
			close()
		elif Global.multibind_action_just_pressed("ui_back"):
			cancelled.emit()
			close()
	var idx := 0
	for i in [$Panel/VBoxContainer/Warpless/Cursor, $Panel/VBoxContainer/Any/Cursor]:
		i.modulate.a = int(selected_index == idx)
		idx += 1

func open() -> void:
	show()
	$Panel/VBoxContainer/Warpless.grab_focus()
	await get_tree().create_timer(0.1, false).timeout
	active = true
	grab_focus()

func close() -> void:
	active = false
	hide()
