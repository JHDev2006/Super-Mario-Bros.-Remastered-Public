
extends HBoxContainer

@export var title := ""
@export var selected := false
@export var campaigns: Array[String]
@export var extra_confirm := false
signal deleted(campaign: String)
var confirming := false

var confirm_2 := false


var selected_index := 0:
	set(value):
		selected_index = value

func _process(_delta: float) -> void:
	if selected:
		handle_inputs()
	else:
		confirm_2 = false
		confirming = false
	$Cursor.modulate.a = int(selected)
	for i in [$AutoScrollContainer, %AutoScrollContainer2]:
		i.is_focused = selected
	%Title.text = tr(title) + ":"
	if not confirming:
		%Value.modulate = Color.WHITE
		%Value.text = tr(str(campaigns[selected_index]))
	else:
		if confirm_2:
			%Value.text = tr("DELETION_CONFIRM_2")
		else:
			%Value.text = tr("DELETION_CONFIRM")
		%Value.modulate = Color.RED
	%LeftArrow.modulate.a = int(selected and selected_index > 0)
	%RightArrow.modulate.a = int(selected and selected_index < campaigns.size() - 1)

func set_selected(active := false) -> void:
	selected = active

func handle_inputs() -> void:
	if Global.multibind_action_just_pressed("ui_left"):
		confirming = false
		confirm_2 = false
		selected_index -= 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if Global.multibind_action_just_pressed("ui_right"):
		confirming = false
		confirm_2 = false
		selected_index += 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if Global.multibind_action_just_pressed("ui_accept"):
		if confirming or confirm_2:
			if extra_confirm and confirm_2 == false:
				confirm_2 = true
			else:
				AudioManager.play_global_sfx("cannon")
				confirm_2 = false
				confirming = false
				deleted.emit(campaigns[selected_index])
		else:
			confirm_2 = false
			confirming = true
	selected_index = clamp(selected_index, 0, campaigns.size() - 1)
