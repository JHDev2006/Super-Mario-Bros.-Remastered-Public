extends Control

@onready var current_container: Control = $PanelContainer/MarginContainer/VBoxContainer/Video

@export var containers: Array[Control]
@export var disabled_containers: Array[Control]

var category_select_active := false
var category_index := 0

signal closed

var can_move := true

var active = false

static var physics_warning_shown := false

signal opened

func _process(_delta: float) -> void:
	category_select_active = current_container.selected_index == -1 and active
	%Category.text = tr(current_container.category_name)
	%Icon.region_rect.position.x = category_index * 24
	
	for i in [%LeftArrow, %RightArrow]:
		i.modulate.a = int(current_container.selected_index == -1)
	if Global.multibind_action_just_pressed("ui_accept"):
		$CanvasLayer.hide()
	for i in containers.size():
		containers[i].active = category_index == i and active
		if SelectableInputOption.rebinding_input == false:
			containers[i].can_input = can_move
			for x in containers[i].options:
				x.focus_mode = 2 if can_move else 0
	for i in disabled_containers:
		i.active = false
	if category_select_active and active and can_move:
		handle_inputs()
	if Global.multibind_action_just_pressed("ui_back") and active and current_container.can_input and can_move:
		close()

func show_physics_warning(value := 0) -> void:
	if physics_warning_shown:
		return
	$CanvasLayer.visible = not value
	if value == 0:
		physics_warning_shown = true
		AudioManager.play_global_sfx("bump")
		can_move = false
		await $CanvasLayer.visibility_changed
		can_move = true

func handle_inputs() -> void:
	var direction := 0
	if Global.multibind_action_just_pressed("ui_left"):
		category_index -= 1
		direction = -1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if Global.multibind_action_just_pressed("ui_right"):
		category_index += 1
		direction += 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	category_index = wrap(category_index, 0, containers.size())
	if disabled_containers.has(containers[category_index]):
		category_index = wrap(category_index + direction, 0, containers.size())
	current_container = containers[category_index]

func open_pack_config_menu(pack: ResourcePackContainer) -> void:
	$ResourcePackConfigMenu.config_json = pack.config
	$ResourcePackConfigMenu.json_path = pack.config_path
	$ResourcePackConfigMenu.open()
	can_move = false
	await $ResourcePackConfigMenu.closed
	can_move = true

func open() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	opened.emit()
	update_all_starting()
	$PanelContainer/MarginContainer/VBoxContainer/KeyboardControls.selected_index = -1
	$PanelContainer/MarginContainer/VBoxContainer/Controller.selected_index = -1
	show()
	update_minimum_size()
	current_container.show()
	current_container.active = true
	await get_tree().process_frame
	active = true

func update_all_starting() -> void:
	get_tree().call_group("Options", "update_starting_values")
	%Flag.region_rect.position.x = Global.lang_codes.find(TranslationServer.get_locale()) * 16
	$PanelContainer/MarginContainer/VBoxContainer/Video/Language.selected_index = Global.lang_codes.find(Settings.file.game.lang)

func close() -> void:
	$CanvasLayer.hide()
	hide()
	active = false
	closed.emit()
	await get_tree().process_frame
	Settings.save_settings()
	process_mode = Node.PROCESS_MODE_DISABLED
