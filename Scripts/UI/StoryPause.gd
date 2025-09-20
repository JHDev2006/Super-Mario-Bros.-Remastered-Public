extends Control

var selected_index := 0

@export var options: Array[Label]
@onready var cursor: TextureRect = $Control/Cursor

var active := false

@export var is_pause := true

signal option_1_selected
signal option_2_selected
signal option_3_selected
signal option_4_selected

func _process(_delta: float) -> void:
	if active:
		handle_inputs()
	cursor.global_position.y = options[selected_index].global_position.y + 4
	cursor.global_position.x = options[selected_index].global_position.x - 10

func handle_inputs() -> void:
	if Input.is_action_just_pressed("ui_down"):
		selected_index += 1
	if Input.is_action_just_pressed("ui_up"):
		selected_index -= 1
	selected_index = clamp(selected_index, 0, options.size() - 1)
	if Input.is_action_just_pressed("ui_accept"):
		option_selected()

func option_selected() -> void:
	emit_signal("option_" + str(selected_index + 1) + "_selected")

func open_settings() -> void:
	active = false
	$SettingsMenu.open()
	await $SettingsMenu.closed
	active = true

func open() -> void:
	if is_pause:
		Global.game_paused = true
		AudioManager.play_global_sfx("pause")
		get_tree().paused = true
	show()
	await get_tree().physics_frame
	active = true

func close() -> void:
	active = false
	selected_index = 0
	hide()
	for i in 2:
		await get_tree().physics_frame
	Global.game_paused = false
	get_tree().paused = false
