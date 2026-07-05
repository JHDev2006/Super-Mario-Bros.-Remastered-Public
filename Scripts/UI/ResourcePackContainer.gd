class_name ResourcePackContainer
extends HBoxContainer
const RESOURCE_PACK_CONFIG_MENU = preload("uid://bom2rstlk8fws")
var pack_json := {"name": "Hello",
				"description": "Hi :"}
var icon: Texture = null

var pack_id := ""

var loaded := false
var selected := false
var load_order := 0
var config := {}

var config_path := ""

var old_idx := -1

signal resource_pack_selected()

signal open_config(pack: ResourcePackContainer)

func _ready() -> void:
	setup_visuals()
	old_idx = get_index()

func setup_visuals() -> void:
	if (pack_json.has("name")):
		%Title.text = pack_json.name.to_upper()
	else:
		%Title.text = pack_id
	
	if (pack_json.has("description")):
		%Description.text = pack_json.description.to_upper()
	else:
		%Description.text = ""
	%Icon.texture = icon
	%LoadedOrder.text = str(load_order)

func _process(_delta: float) -> void:
	loaded = Settings.file.visuals.resource_packs.has(pack_id)
	%Cursor.modulate.a = int(selected)
	%LoadedOrder.visible = loaded
	%LoadedOrder.text = str(load_order + 1)
	load_order = Settings.file.visuals.resource_packs.find(pack_id)
	var colour = Color.WHITE
	if Global.custom_pack == pack_id:
		colour = Color.YELLOW
	elif loaded:
		colour = Color.GREEN
	$ResourcePackContainer.self_modulate = colour
	$Edit/EditLabel.visible = selected and config != {}
	for i in [%TitleScroll, %DescScroll]:
		i.is_focused = selected
	if selected:
		focus_mode = Control.FOCUS_ALL
		grab_focus()
	else:
		focus_mode = Control.FOCUS_NONE
	if Global.multibind_action_just_pressed("ui_accept") and selected and visible:
		select()
	elif Global.multibind_action_just_pressed("ui_right") and selected and visible and config != {}:
		open_config_menu()

func open_config_menu() -> void:
	open_config.emit(self)

func select() -> void:
	if Global.custom_pack == pack_id:
		AudioManager.play_global_sfx("bump")
		return
	ResourceSetter.cache.clear()
	ResourceSetterNew.clear_cache()
	ResourceGetter.cache.clear()
	AudioManager.current_level_theme = ""
	loaded = not loaded
	if loaded and Settings.file.visuals.resource_packs.has(pack_id) == false:
		Settings.file.visuals.resource_packs.push_front(pack_id)
		if config != {}:
			ResourceSetterNew.pack_configs[pack_id] = config
	else:
		ResourceSetterNew.pack_configs.erase(pack_id)
		Settings.file.visuals.resource_packs.erase(pack_id)
	Global.load_default_translations()
	TranslationServer.reload_pseudolocalization()
	Global.update_theme()
	if loaded:
		AudioManager.play_global_sfx("coin")
	else:
		AudioManager.play_global_sfx("bump")
	grab_focus()
