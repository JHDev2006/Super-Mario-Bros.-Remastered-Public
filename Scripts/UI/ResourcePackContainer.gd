class_name ResourcePackContainer
extends HBoxContainer
const RESOURCE_PACK_CONFIG_MENU = preload("uid://bom2rstlk8fws")
var pack_json := {"name": "Hello",
				"description": "Hi :"}
var icon: Texture = null

var pack_name := ""

var loaded := false
var selected := false
var load_order := 0
var config := {}

var config_path := ""

signal resource_pack_selected()

signal open_config(pack: ResourcePackContainer)

func _ready() -> void:
	setup_visuals()

func setup_visuals() -> void:
	%Title.text = pack_json.name.to_upper()
	%Description.text = pack_json.description.to_upper()
	%Icon.texture = icon
	%LoadedOrder.text = str(load_order)

func _process(_delta: float) -> void:
	loaded = Settings.file.visuals.resource_packs.has(pack_name)
	%Cursor.modulate.a = int(selected)
	%LoadedOrder.visible = loaded
	%LoadedOrder.text = str(load_order + 1)
	load_order = Settings.file.visuals.resource_packs.find(pack_name)
	$ResourcePackContainer.self_modulate = Color.GREEN if loaded else Color.WHITE
	$Edit/EditLabel.visible = selected and config != {}
	for i in [%TitleScroll, %DescScroll]:
		i.is_focused = selected
	if selected:
		focus_mode = Control.FOCUS_ALL
		grab_focus()
	else:
		focus_mode = Control.FOCUS_NONE
	if Input.is_action_just_pressed("ui_accept") and selected and visible:
		select()
	elif Input.is_action_just_pressed("ui_right") and selected and visible and config != {}:
		open_config_menu()

func open_config_menu() -> void:
	open_config.emit(self)

func select() -> void:
	# print(ResourceSetter.cache)
	ResourceSetter.cache.clear()
	# print(ResourceSetter.cache)
	ResourceSetterNew.cache.clear()
	ResourceGetter.cache.clear()
	AudioManager.current_level_theme = ""
	loaded = not loaded
	if loaded and Settings.file.visuals.resource_packs.has(pack_name) == false:
		Settings.file.visuals.resource_packs.push_front(pack_name)
		if config != {}:
			ResourceSetterNew.pack_configs[pack_name] = config
	else:
		ResourceSetterNew.pack_configs.erase(pack_name)
		Settings.file.visuals.resource_packs.erase(pack_name)
	Global.level_theme_changed.emit()
	if loaded:
		AudioManager.play_global_sfx("coin")
	else:
		AudioManager.play_global_sfx("bump")
