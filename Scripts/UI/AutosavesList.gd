extends VBoxContainer

signal level_selected(container: CustomLevelContainer)

const CUSTOM_LEVEL_CONTAINER = preload("uid://dt20tjug8m6oh")
const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

var containers := []
var current_container: CustomLevelContainer
var selected_lvl_idx := -1

var active := false

func set_current_container(container: CustomLevelContainer) -> void:
	current_container = container
	refresh()

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	active = (!$AutosavesDelete.confirming and !$"../../../../../AutosaveSettings".visible)
	if (Global.multibind_action_just_pressed("ui_back") || Input.is_action_just_pressed("mb_right")) && active:
		level_selected.emit(current_container)
		close(true)

func open() -> void:
	$"../Title".text = tr("AUTOSAVES")
	update_show(current_container.level_name)
	show()
	
	$OpenSettings/SelectableLabel.grab_focus()
	
	await get_tree().process_frame
	set_process(true)

func close(change_title := false) -> void:
	if change_title:
		$"../Title".text = tr("CUSTOM_LEVELS")
	active = false
	
	hide()
	set_process(false)

func refresh() -> void:
	%AutosaveContainers.get_node("Label").show()
	for i in %AutosaveContainers.get_children():
		if i is CustomLevelContainer:
			i.queue_free()
	containers.clear()
	get_levels()

func get_levels() -> void:
	if (current_container == null):
		return
	var path = Global.config_path.path_join("custom_levels/autosaves/%s" % current_container.level_name)
	var idx := 0
	for i in DirAccess.get_files_at(path):
		if i.contains(".lvl") == false:
			continue
		%AutosaveContainers.get_node("Label").hide()
		var container = CUSTOM_LEVEL_CONTAINER.instantiate()
		var file_path = path + "/" + i
		var json := JSONParser.parse_to_dict(file_path)
		
		if (AutosaveHandler.is_level_empty(json)):
			DirAccess.remove_absolute(file_path)
			return
		 
		var data = json["Levels"][0]["Data"].split("=")
		var info = json["Info"]
		container.is_autosave = true
		container.level_name = info["Name"]
		container.level_author = info["Author"]
		container.level_desc = info["Description"]
		container.autosave_time = info["SaveTime"]
		container.idx = idx
		container.file_path = file_path
		container.level_theme = Level.THEME_IDXS[base64_charset.find(data[0])]
		container.level_time = base64_charset.find(data[1])
		container.game_style = Global.CAMPAIGNS[base64_charset.find(data[3])]
		container.selected.connect(container_selected)
		containers.append(container)
		if info.has("Difficulty"):
			container.difficulty = info["Difficulty"]
		container.update_visuals()
		%AutosaveContainers.add_child(container)
		
		idx += 1

const LEVEL_PACK_CONTAINER = preload("uid://buj10cxh15fnd")

func update_show(level_name_check := "") -> void:
	for i in containers:
		if level_name_check != "":
			var level_name = i.level_name if (i.level_name != "") else "UNNAMED LEVEL"
			i.visible = level_name.to_lower() == level_name_check.to_lower()

func container_selected(container: CustomLevelContainer) -> void:
	if !container.is_autosave: return
	level_selected.emit(container)
	selected_lvl_idx = container.get_index()

func delete_levels() -> void:
	var path = Global.config_path.path_join("custom_levels/autosaves/%s" % current_container.level_name)
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)
	Global.log_warning("Autosaves have been deleted!")
	refresh()
