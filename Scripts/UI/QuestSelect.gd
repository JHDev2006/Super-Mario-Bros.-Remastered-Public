extends Control

signal selected
signal cancelled
var active := false

var selected_index := 0

var old_quest := false

func _process(_delta: float) -> void:
	if active:
		handle_input()

func open() -> void:
	old_quest = Global.second_quest
	show()
	await get_tree().process_frame
	[%FirstQuest, %SecondQuest][int(Global.second_quest)].grab_focus()
	active = true

func handle_input() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		select()
		close()
	elif Input.is_action_just_pressed("ui_back"):
		Global.second_quest = old_quest
		close()
		cancelled.emit()
		return

func set_index(idx := false) -> void:
	selected_index = wrapi(int(idx), 0, 2)
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_global_sfx("menu_move")

func select() -> void:
	Global.second_quest = bool(selected_index)
	selected.emit()
	close()

func close() -> void:
	active = false
	hide()
