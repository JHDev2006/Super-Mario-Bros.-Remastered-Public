extends VBoxContainer

signal closed

const LEVEL_INFO_URL := "https://levelsharesquare.com/api/levels/"

var level_id := ""

var has_downloaded := false

signal level_play

var level_thumbnail = null

func _ready() -> void:
	set_process(false)

func open(container: OnlineLevelContainer) -> void:
	has_downloaded = FileAccess.file_exists("user://custom_levels/downloaded/" + container.level_id + ".lvl")
	show()
	level_thumbnail = container.level_thumbnail
	%Download.text = "DOWNLOAD"
	if has_downloaded:
		%OnlinePlay.grab_focus()
	else:
		%Download.grab_focus()
	setup_visuals(container)
	level_id = container.level_id
	await get_tree().physics_frame
	set_process(true)

func setup_visuals(container: OnlineLevelContainer) -> void:
	$Panel/AutoScrollContainer.scroll_pos = 0
	$Panel/AutoScrollContainer.move_direction = -1
	%LSSDescription.text = "Fetching Description..."
	%SelectedOnlineLevel.level_name = container.level_name
	%SelectedOnlineLevel.level_author = container.level_author
	%SelectedOnlineLevel.level_id = container.level_id
	%SelectedOnlineLevel.thumbnail_url = container.thumbnail_url
	%SelectedOnlineLevel.level_thumbnail = level_thumbnail
	%SelectedOnlineLevel.difficulty = container.difficulty
	%SelectedOnlineLevel.setup_visuals()
	$Description.request(LEVEL_INFO_URL + container.level_id)
	%Download.visible = not has_downloaded
	%OnlinePlay.visible = has_downloaded

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_back"):
		close()

func close() -> void:
	hide()
	closed.emit()
	set_process(false)

func download_level() -> void:
	DirAccess.make_dir_recursive_absolute("user://custom_levels/downloaded")
	var url = "https://levelsharesquare.com/api/levels/" + level_id + "/code"
	print(url)
	$DownloadLevel.request(url, [], HTTPClient.METHOD_GET)
	%Download.text = "DOWNLOADING..."

func open_lss() -> void:
	OS.shell_open("https://levelsharesquare.com/levels/" + str(level_id))

func on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var string = body.get_string_from_utf8()
	var json = JSON.parse_string(string)
	%LSSDescription.text = Global.sanitize_string(json["level"]["description"])

func level_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var string = body.get_string_from_utf8()
	var json = JSON.parse_string(string)
	var file = FileAccess.open("user://custom_levels/downloaded/" + level_id + ".lvl", FileAccess.WRITE)
	var data = null
	if json.levelData.data is Array:
		data = get_json_from_bytes(json.levelData.data)
	else:
		data = json.levelData
	file.store_string(JSON.stringify(str_to_var(data)))
	file.close()
	save_thumbnail()
	%Download.hide()
	%OnlinePlay.show()
	%OnlinePlay.grab_focus()

func save_thumbnail() -> void:
	if OnlineLevelContainer.cached_thumbnails.has(level_id):
		var thumbnail = OnlineLevelContainer.cached_thumbnails.get(level_id)
		DirAccess.make_dir_recursive_absolute("user://custom_levels/downloaded/thumbnails")
		thumbnail.get_image().save_png("user://custom_levels/downloaded/thumbnails/"+ level_id + ".png")

func play_level() -> void:
	var file_path := "user://custom_levels/downloaded/" + level_id + ".lvl"
	var file = JSON.parse_string(FileAccess.open(file_path, FileAccess.READ).get_as_text())
	LevelEditor.level_file = file
	var info = file["Info"]
	LevelEditor.level_author = info["Author"]
	LevelEditor.level_name = info["Name"]
	level_play.emit()

func get_json_from_bytes(json := []) -> String:
	return PackedByteArray(json).get_string_from_ascii()
