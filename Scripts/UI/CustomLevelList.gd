extends VBoxContainer

signal level_selected(container: CustomLevelContainer)

const CUSTOM_LEVEL_CONTAINER = preload("uid://dt20tjug8m6oh")

const CUSTOM_LEVEL_PATH := "user://custom_levels/"
const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

signal closed

var containers := []

var selected_lvl_idx := -1

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
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(CUSTOM_LEVEL_PATH))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_back"):
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
	get_levels("user://custom_levels")
	get_levels("user://custom_levels/downloaded")

func get_levels(path := "user://custom_levels") -> void:
	DirAccess.make_dir_recursive_absolute(path)
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
		container.file_path = file_path
		container.level_theme = Level.THEME_IDXS[base64_charset.find(data[0])]
		container.level_time = base64_charset.find(data[1])
		container.game_style = Global.CAMPAIGNS[base64_charset.find(data[3])]
		container.selected.connect(container_selected)
		containers.append(container)
		print(data)
		if info.has("Difficulty"):
			container.difficulty = info["Difficulty"]
		%LevelContainers.add_child(container)
		idx += 1

func container_selected(container: CustomLevelContainer) -> void:
	level_selected.emit(container)
	selected_lvl_idx = container.get_index()
