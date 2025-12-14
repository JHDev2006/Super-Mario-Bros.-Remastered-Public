extends Control

signal full_run_selected
signal level_run_selected
signal cancelled

var selected := 0

var active := false

func open() -> void:
	setup_visuals()
	[$PanelContainer/VBoxContainer/HBoxContainer/Full, $PanelContainer/VBoxContainer/HBoxContainer/Level][selected].grab_focus()
	show()
	await get_tree().process_frame
	active = true

func close() -> void:
	hide()
	active = false

func _process(_delta: float) -> void:
	if active:
		if Input.is_action_just_pressed("ui_accept"):
			[full_run_selected, level_run_selected][selected].emit()
			Global.current_game_mode = [Global.GameMode.MARATHON, Global.GameMode.MARATHON_PRACTICE][selected]
			close()
		elif Input.is_action_just_pressed("ui_back"):
			close()
			cancelled.emit()
		if Input.is_action_just_pressed("ui_left"):
			selected -= 1
		if Input.is_action_just_pressed("ui_right"):
			selected += 1
		selected = wrapi(selected, 0, 2)
		%MarathonName.text = ["MARATHON_FULL", "MARATHON_LEVEL"][selected]
		for i in [$PanelContainer/VBoxContainer/HBoxContainer/Full, $PanelContainer/VBoxContainer/HBoxContainer/Level]:
			i.get_node("Label").visible = selected == i.get_index()

func setup_visuals() -> void:
	if SpeedrunHandler.marathon_best_warpless_time <= 0:
		%FullRunPB.text = "--:--:--"
	else:
		%FullRunPB.text = SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(SpeedrunHandler.marathon_best_warpless_time))
		
	if SpeedrunHandler.marathon_best_any_time <= 0:
		%WarpedRunPB.text = "--:--:--"
	else:
		%WarpedRunPB.text = SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(SpeedrunHandler.marathon_best_any_time))

	for i in %FullMedals.get_children():
		i.get_node("Full").visible = SpeedrunHandler.met_target_time(
			SpeedrunHandler.marathon_best_warpless_time, SpeedrunHandler.GOLD_WARPLESS_TIMES[Global.current_campaign] * SpeedrunHandler.MEDAL_CONVERSIONS[i.get_index()])
	for i in %WarpedMedals.get_children():
		i.get_node("Full").visible = SpeedrunHandler.met_target_time(
			SpeedrunHandler.marathon_best_any_time, SpeedrunHandler.GOLD_ANY_TIMES[Global.current_campaign] * SpeedrunHandler.MEDAL_CONVERSIONS[i.get_index()])
