extends VBoxContainer

signal closed

var file_path := ""

var active := false

func _ready() -> void:
	set_process(false)

signal level_play
signal level_edit

func open(container: CustomLevelContainer = null) -> void:
	if container != null:
		for i in ["level_name", "level_author", "level_theme", "game_style", "level_time", "difficulty", "is_downloaded", "level_id", "thumbnail"]:
			%SelectedLevel.set(i, container.get(i))
	%SelectedLevel.update_visuals()
	LevelEditor.level_name = container.level_name
	CustomLevelMenu.current_level_file = container.file_path
	LevelEditor.level_author = container.level_author
	file_path = container.file_path
	LevelEditor.level_desc = container.level_desc
	%Description.text = container.level_desc
	%AutosaveTime.visible = container.autosave_time != ""
	%OpenAutosaves.visible = container.autosave_time == ""
	%AutosaveTime.text = "Autosave: " + container.autosave_time.replace("T", " ")
	show()
	await get_tree().physics_frame
	active = true
	set_process(true)
	if (%AutosaveTime.visible):
		%Play.hide()
		%Edit.grab_focus()
	else:
		%Play.show()
		%Play.grab_focus()

func reopen() -> void:
	show()
	await get_tree().physics_frame
	active = true
	set_process(true)
	%Play.grab_focus()

func _process(_delta: float) -> void:
	if (!active):
		return
	if (Global.multibind_action_just_pressed("ui_back") || Input.is_action_just_pressed("mb_right")):
		closed.emit()
		close()

func level_selected() -> void:
	active = false
	
	LevelEditor.level_file = JSONParser.parse_to_dict(file_path)
	level_play.emit()

func level_edited() -> void:
	LevelEditor.level_file = JSONParser.parse_to_dict(file_path)
	level_edit.emit()

func close(back := true) -> void:
	hide()
	set_process(false)
	active = false
	
	if back:
		if (%AutosaveTime.visible):
			%AutosavesList.open()
		else:
			%LevelList.open(false)
