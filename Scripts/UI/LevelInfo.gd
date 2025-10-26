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
	show()
	await get_tree().physics_frame
	active = true
	set_process(true)
	%Play.grab_focus()

func reopen() -> void:
	show()
	await get_tree().physics_frame
	active = true
	set_process(true)
	%Play.grab_focus()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_back") and active:
		closed.emit()
		close()

func level_selected() -> void:
	LevelEditor.level_file = JSON.parse_string(FileAccess.open(file_path, FileAccess.READ).get_as_text())
	level_play.emit()
	active = false

func level_edited() -> void:
	LevelEditor.level_file = JSON.parse_string(FileAccess.open(file_path, FileAccess.READ).get_as_text())
	level_edit.emit()

func close() -> void:
	hide()
	set_process(false)
