extends Control

var config_json := {}

signal closed


var selected_index := 0
var active := false

var json_path := ""

func open() -> void:
	if active: return
	clear_options()
	spawn_options()
	show()
	%Options.active = true
	option_highlighted(%Options.get_child(1))
	await get_tree().process_frame
	%Options.active = true
	active = true

func clear_options() -> void:
	for i in %Options.options:
		i.free()
	%Options.options.clear()

func _process(_delta: float) -> void:
	if Global.multibind_action_just_pressed("ui_back") and active:
		close()

func spawn_options() -> void:
	for i in config_json.options:
		var node: PackConfigOption = load("res://Scenes/Parts/ResourcePackConfigOptionNode.tscn").instantiate()
		node.config_name = i
		if config_json.options[i] is bool:
			node.values = ["SETTING_OFF", "SETTING_ON"]
			node.selected_index = int(config_json.options[i])
			node.is_bool = true
		else:
			node.values = config_json.value_keys[i]
			var val = config_json.value_keys[i].find(config_json.options[i])
			node.selected_index = val
		%Options.add_child(node)
		node.value_changed.connect(value_changed)
		node.focus_entered.connect(option_highlighted.bind(node))
		%Options.options.append(node)

func value_changed(option: PackConfigOption) -> void:
	if option.is_bool:
		config_json.options[option.config_name] = bool(option.selected_index)
	else:
		config_json.options[option.config_name] = option.values[option.selected_index]
	option_highlighted(option)
	update_json()

func update_json() -> void:
	JSONParser.save_to_file(config_json, json_path)

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

func option_highlighted(option: PackConfigOption) -> void:
	%Description.hide()
	if config_json.has("option_descs"):
		if config_json.option_descs.has(option.config_name):
			if config_json.option_descs[option.config_name] is Array:
				%DescText.text = str(config_json.option_descs[option.config_name][option.selected_index])
			elif config_json.option_descs[option.config_name] is String:
				%DescText.text = str(config_json.option_descs[option.config_name])
			%Description.show()
	print("Set")
