class_name TitleScreenOptions
extends VBoxContainer

@export var active := false

@export var can_exit := true

var selected_index := 0

@export var options: Array[Label] = []
@onready var title_screen_parent := owner

signal option_1_selected
signal option_2_selected
signal option_3_selected

signal closed

func _process(_delta: float) -> void:
	if active:
		handle_inputs()

func open() -> void:
	Global.world_num = clamp(Global.world_num, 1, Level.get_world_count())
	title_screen_parent.active_options = self
	show()
	await get_tree().physics_frame
	active = true

func close() -> void:
	active = false
	hide()

func handle_inputs() -> void:
	if Input.is_action_just_pressed("ui_down"):
		selected_index += 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if Input.is_action_just_pressed("ui_up"):
		selected_index -= 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	var amount := []
	for i in options:
		if i.visible:
			amount.append(i)
	selected_index = wrapi(selected_index, 0, amount.size())
	if Input.is_action_just_pressed("ui_accept"):
		option_selected()
	elif can_exit and Input.is_action_just_pressed("ui_back"):
		close()
		closed.emit()

func option_selected() -> void:
	active = false
	emit_signal("option_" + str(selected_index + 1) + "_selected")
