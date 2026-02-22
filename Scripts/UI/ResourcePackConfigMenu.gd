extends Control

var config_json := {}
const RESOURCE_PACK_CONFIG_OPTION_NODE = preload("uid://c5ea03ob6ncq7")

signal closed


var selected_index := 0
var active := false

var json_path := ""

func open() -> void:
	if active: return
	clear_options()
	spawn_options()
	show()
	await get_tree().process_frame
	%Options.active = true
	active = true

func clear_options() -> void:
	for i in %Options.options:
		i.queue_free()
	%Options.options.clear()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_back") and active:
		close()

func spawn_options() -> void:
	for i in config_json.options:
		var node = RESOURCE_PACK_CONFIG_OPTION_NODE.instantiate()
		node.config_name = i
		if config_json.options[i] is bool:
			node.values = ["SETTING_OFF", "SETTING_ON"]
			node.selected_index = int(config_json.options[i])
			node.is_bool = true
		else:
			node.values = config_json.value_keys[i]
			node.selected_index = config_json.value_keys[i].find(config_json.options[i])
		%Options.add_child(node)
		node.value_changed.connect(value_changed)
		%Options.options.append(node)

func value_changed(option: PackConfigOption) -> void:
	if option.is_bool:
		config_json.options[option.config_name] = bool(option.selected_index)
	else:
		config_json.options[option.config_name] = option.values[option.selected_index]
	update_json()

func update_json() -> void:
	var file = FileAccess.open(json_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config_json, "\t", false))
	file.close()

func close() -> void:
	ResourceSetter.cache.clear()
	ResourceSetterNew.clear_cache()
	AudioManager.current_level_theme = ""
	Global.update_theme()
	closed.emit()
	clear_options()
	hide()
	%Options.active = false
	active = false
