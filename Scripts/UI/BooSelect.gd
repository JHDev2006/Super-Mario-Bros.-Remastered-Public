extends Control
@onready var cursor: Label = %Cursor

var selected_boo := 0

var active := false

var lvl_idx := 0

signal boo_selected
signal cancelled

signal boo_changed

@onready var boos := [%Boo1, %Boo2, %Boo3, %Boo4, %Boo5]

func _process(_delta: float) -> void:
	if active:
		handle_input()
		BooRaceHandler.boo_colour = selected_boo
	for i in boos:
		i.get_node("Cursor").visible = selected_boo == i.get_index()

func open() -> void:
	grab_focus()
	selected_boo = int(BooRaceHandler.cleared_boo_levels[lvl_idx])
	update_visuals()
	show()
	await get_tree().process_frame
	active = true

func update_visuals() -> void:
	var idx := 0
	for i in boos:
		i.modulate = Color.WHITE if (int(BooRaceHandler.cleared_boo_levels[lvl_idx]) >= idx or Global.debug_mode) else Color.DIM_GRAY
		idx += 1

func handle_input() -> void:
	var old_colour = selected_boo
	if Global.multibind_action_just_pressed("ui_left"):
		selected_boo -= 1
	if Global.multibind_action_just_pressed("ui_right"):
		selected_boo += 1
	selected_boo = clamp(selected_boo, 0, 4)
	BooRaceHandler.boo_colour = selected_boo
	if old_colour != selected_boo:
		boo_changed.emit()
	if Global.multibind_action_just_pressed("ui_back"):
		cancelled.emit()
		close()
	if Global.multibind_action_just_pressed("ui_accept"):
		if int(BooRaceHandler.cleared_boo_levels[lvl_idx]) < selected_boo and not Global.debug_mode:
			AudioManager.play_sfx("bump")
		else:
			select_world()

func select_world() -> void:
	boo_selected.emit()
	close()

func close() -> void:
	active = false
	hide()
