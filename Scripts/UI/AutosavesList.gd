extends VBoxContainer

signal closed
signal level_selected(container: CustomLevelContainer)

const CUSTOM_LEVEL_CONTAINER = preload("uid://dt20tjug8m6oh")
const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

var containers := []
var selected_lvl_idx := -1
var search_check := ""

var active := false

func _ready() -> void:
	$Time.maximum = AutosaveHandler.max_time
	set_process(false)

func _process(_delta: float) -> void:
	if ($AutosavesDelete.confirming and active):
		update_show(0, true)
	active = (CustomLineEdit.editing == false and !$AutosavesDelete.confirming)
	if (Global.multibind_action_just_pressed("ui_back") || Input.is_action_just_pressed("mb_right")) && active:
		closed.emit()
		close()

func open() -> void:
	$"../Title".text = tr("AUTOSAVES")
	show()
	
	if selected_lvl_idx >= 0:
		%AutosaveContainers.get_child(selected_lvl_idx).grab_focus()
	else:
		$Enable.grab_focus()
	await get_tree().process_frame
	set_process(true)

func close(change_title: bool = true) -> void:
	if (change_title):
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
	get_levels(Global.config_path.path_join("custom_levels/autosaves"))

func get_levels(path : String = "", type := CustomLevelContainer.Type.ALL) -> void:
	if path == "":
		path = Global.config_path.path_join("custom_levels/autosaves")
	var idx := 0
	for i in DirAccess.get_files_at(path):
		if i.contains(".lvl") == false:
			continue
		%AutosaveContainers.get_node("Label").hide()
		var container = CUSTOM_LEVEL_CONTAINER.instantiate()
		var file_path = path + "/" + i
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		
		if (is_level_empty(json)):
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
		container.current_type = type
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

func update_show(new_type := 0, exact := false) -> void:
	for i in containers:
		i.visible = i.current_type == new_type or new_type == 0
		if search_check != "" and i.visible:
			var level_name = i.level_name if (i.level_name != "") else "UNNAMED LEVEL"
			if (exact):
				i.visible = level_name.to_lower() == search_check.to_lower()
			else:
				i.visible = level_name.to_lower().contains(search_check.to_lower())

func search_submitted(search_query := "") -> void:
	search_check = search_query
	update_show()

func container_selected(container: CustomLevelContainer) -> void:
	if !container.is_autosave: return
	level_selected.emit(container)
	selected_lvl_idx = container.get_index()

func delete_levels(filter: String) -> void:
	if (filter.contains("ALL")):
		var path = Global.config_path.path_join("custom_levels/autosaves")
		for file_name in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(path.path_join(file_name))
		DirAccess.remove_absolute(path)
		Global.log_warning("Autosaves folder has been deleted!")
	elif (filter.contains("SEARCH")):
		var level_name := search_check
		var lvl_file_name = level_name.to_pascal_case()
		for i in "<>:?!/":
			lvl_file_name = lvl_file_name.replace(i, "")
		
		var path = Global.config_path.path_join("custom_levels/autosaves")
		for file_name in DirAccess.get_files_at(path):
			var actual_name = file_name.split("_")[0]
			if actual_name.to_lower() == lvl_file_name.to_lower():
				DirAccess.remove_absolute(path.path_join(file_name))
		
		Global.log_warning("Autosaves files for current level name has been deleted!")
	refresh()

func is_level_empty(file := {}) -> bool:
	var isEmpty := 0
	for i in 5:
		if (file["Levels"][i] == {}):
			isEmpty += 1
			continue
		var nothingFound := 0
		for j in 5:
			var layer: Dictionary = file["Levels"][i]["Layers"][j]
			var firstLayer = layer.keys()
			if (firstLayer != []):
				firstLayer = str(layer.keys()[0])
			if ((layer == {} || !layer.has(firstLayer) || (layer.has(firstLayer) && layer[firstLayer]["Tiles"] == "" && layer[firstLayer]["Entities"].length() == 24))):
				nothingFound += 1
				continue
		if (nothingFound == 5):
			isEmpty += 1
	
	if (isEmpty >= 5):
		return true
	return false

func enable_toggled(toggled_on: bool) -> void:
	Settings.file.editor.autosave_enabled = toggled_on
	Settings.save_settings()

func timer_changed(value: int) -> void:
	Settings.file.editor.autosave_min_timer = value
	Settings.save_settings()

func before_test_toggled(toggled_on: bool) -> void:
	Settings.file.editor.autosave_before_test = toggled_on
	Settings.save_settings()
	
func editor_return_toggled(toggled_on: bool) -> void:
	Settings.file.editor.autosave_on_return_to_editor = toggled_on
	Settings.save_settings()
