extends VBoxContainer

signal level_selected(container: CustomLevelContainer)

const CUSTOM_LEVEL_CONTAINER = preload("uid://dt20tjug8m6oh")

const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

signal closed

var containers := []

var selected_lvl_idx := -1

var search_check := ""

func open(refresh_list := true) -> void:
	show()
	if refresh_list:
		refresh()
	if selected_lvl_idx >= 0:
		%LevelContainers.get_child(selected_lvl_idx).grab_focus()
	else:
		$TopBit/Button.grab_focus()
	await get_tree().process_frame
	set_process(true)

func open_folder() -> void:
	var custom_level_path = Global.config_path.path_join("custom_levels")
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(custom_level_path))

func _process(_delta: float) -> void:
	if Global.multibind_action_just_pressed("ui_back") and CustomLineEdit.editing == false:
		closed.emit()

func close() -> void:
	hide()
	set_process(false)

func refresh() -> void:
	%LevelContainers.get_node("Label").show()
	for i in %LevelContainers.get_children():
		if i is CustomLevelContainer:
			i.queue_free()
	containers.clear()
	get_levels(Global.config_path.path_join("custom_levels"), CustomLevelContainer.Type.SAVED)
	get_levels(Global.config_path.path_join("custom_levels/downloaded"), CustomLevelContainer.Type.DOWNLOADED)

func get_levels(path : String = "", type := CustomLevelContainer.Type.ALL) -> void:
	if path == "":
		path = Global.config_path.path_join("custom_levels")
	var idx := 0
	for i in DirAccess.get_files_at(path):
		if i.contains(".lvl") == false:
			continue
		%LevelContainers.get_node("Label").hide()
		var container = CUSTOM_LEVEL_CONTAINER.instantiate()
		var file_path = path + "/" + i
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		var data = json["Levels"][0]["Data"].split("=")
		var info = json["Info"]
		container.is_downloaded = path.contains("downloaded")
		if container.is_downloaded:
			container.level_id = file_path.get_file().replace(".lvl", "")
		container.level_name = info["Name"]
		container.level_author = info["Author"]
		container.level_desc = info["Description"]
		container.idx = idx
		container.current_type = type
		container.file_path = file_path
		container.level_theme = Level.THEME_IDXS[base64_charset.find(data[0])]
		container.level_time = base64_charset.find(data[1])
		container.game_style = Global.CAMPAIGNS[base64_charset.find(data[3])]
		container.selected.connect(container_selected)
		containers.append(container)
		[%SavedLevels, %DownloadedLevels][type - 1].show()
		if info.has("Difficulty"):
			container.difficulty = info["Difficulty"]
		%LevelContainers.add_child(container)
		%LevelContainers.move_child(container, [%SavedLevels, %DownloadedLevels][type - 1].get_index() + 1)
		idx += 1
		
const LEVEL_PACK_CONTAINER = preload("uid://buj10cxh15fnd")

func update_show(new_type := 0) -> void:
	for i in containers:
		i.visible = i.current_type == new_type or new_type == 0
		if search_check != "" and i.visible:
			i.visible = i.level_name.contains(search_check)
	%SavedLevels.visible = (new_type == CustomLevelContainer.Type.SAVED or new_type == 0) and get_visible_containers(CustomLevelContainer.Type.SAVED) > 0
	%DownloadedLevels.visible = (new_type == CustomLevelContainer.Type.DOWNLOADED or new_type == 0) and get_visible_containers(CustomLevelContainer.Type.DOWNLOADED) > 0
	

func get_visible_containers(type := 0) -> int:
	var vis_child := 0
	for i in containers:
		if i.visible and i.current_type == type:
			vis_child += 1
	return vis_child

func search_submitted(search_query := "") -> void:
	search_check = search_query
	update_show()

func container_selected(container: CustomLevelContainer) -> void:
	level_selected.emit(container)
	selected_lvl_idx = container.get_index()
