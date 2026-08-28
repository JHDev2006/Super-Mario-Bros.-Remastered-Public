extends Control
@onready var cursor: TextureRect = $Cursor

var selected_index := 0

signal selected
signal cancelled

var active := false

@onready var choices := [$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Yes, $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/No]

func _process(_delta: float) -> void:
	if active:
		handle_input()
	cursor.global_position.x = choices[selected_index].global_position.x - 6

func open() -> void:
	show()
	AudioManager.play_global_sfx("pause")
	selected_index = 1
	await get_tree().process_frame
	active = true
	await selected
	hide()

func handle_input() -> void:
	if Global.multibind_action_just_pressed("ui_left"):
		selected_index -= 1
	if Global.multibind_action_just_pressed("ui_right"):
		selected_index += 1
	if Global.multibind_action_just_pressed("ui_back"):
		close()
		cancelled.emit()
	selected_index = clamp(selected_index, 0, 1)
	if Global.multibind_action_just_pressed("ui_accept"):
		select()

func select() -> void:
	selected.emit()
	close()

func close() -> void:
	active = false
	hide()
