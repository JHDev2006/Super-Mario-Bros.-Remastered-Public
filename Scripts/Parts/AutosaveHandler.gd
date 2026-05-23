class_name AutosaveHandler
extends Node

@onready var level_editor: LevelEditor = get_parent()
@onready var timer := $AutoSaveTimer

static var last_section_time := -1.0
static var max_time := 60

signal finished

func _ready() -> void:
	%AutoSaveTimer.max_value = max_time
	await level_editor.ready
	level_editor.level_start.connect(before_test_autosave)
	
	print(str(last_section_time))
	if (last_section_time == -1.0):
		last_section_time = 60.0 * Settings.file.editor.autosave_min_timer
	if (Settings.file.editor.autosave_enabled):
		timer.start(last_section_time)
	
	await get_tree().create_timer(0.5).timeout
	if timer.time_left <= 5:
		level_editor.something_changed = true

var old_second := -1
func _physics_process(delta: float) -> void:
	if level_editor.something_changed == false and timer.paused == false:
		timer.paused = true
	elif level_editor.something_changed and timer.paused:
		timer.paused = false
	if timer.time_left > 0 and timer.time_left <= 5 and old_second != floori(timer.time_left):
		old_second = floori(timer.time_left)
		Global.log_comment("Autosave happens in: %s seconds!" % str(floori(timer.time_left) + 1), 1)

func before_test_autosave() -> void:
	handle_autosave(Settings.file.editor.autosave_before_test)

func handle_autosave(save: bool = true) -> void:
	timer.stop()
	if save:
		autosave_tick()
		level_editor.something_changed = false
	finished.emit()

func autosave_tick() -> void:
	start_autosave()
	
	if Settings.file.editor.autosave_enabled:
		timer.start(last_section_time)

func start_autosave() -> void:
	var level_name := level_editor.level_name
	var save_time := Time.get_datetime_string_from_system()
	var file_name = level_name.to_pascal_case() + "_" + save_time + ".lvl"
	
	var temp_level_file: Dictionary = $"../LevelSaver".save_level(level_name, level_editor.level_author, level_editor.level_desc, level_editor.difficulty)
	var message := ""
	
	var path = Global.config_path.path_join("custom_levels/").path_join(level_name.to_pascal_case() + ".lvl")
	if (!FileAccess.file_exists(path)):
		message = tr("EDITOR_AUTOSAVE_SAVE_LEVEL_FIRST")
	elif (is_level_empty(temp_level_file)):
		message = tr("EDITOR_AUTOSAVE_FAIL_EMPTY")
	elif (!level_editor.something_changed):
		message = tr("EDITOR_AUTOSAVE_FAIL_CHANGES")
	if (message != ""):
		Global.log_warning(message)
		return
	$"../LevelSaver".write_temp_file(level_name, temp_level_file, file_name, save_time)
	
	last_section_time = 60.0 * Settings.file.editor.autosave_min_timer
	Global.log_comment(tr("EDITOR_AUTOSAVE_COMPLETE").replace("{DATE}", save_time))

static func is_level_empty(file := {}) -> bool:
	var isEmpty := 0
	for i in 5:
		if (file["Levels"][i] == {}):
			isEmpty += 1
			continue
		var nothingFound := 0
		for j in 5:
			var layer: Dictionary = file["Levels"][i]["Layers"][j]
			var firstLayer = layer.keys().back()
			if (
				(layer == {} || !layer.has(firstLayer) || 
				(layer.has(firstLayer) && layer[firstLayer]["Tiles"] == "" && layer[firstLayer]["Entities"].length() == 24))
			):
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
	
	if Settings.file.editor.autosave_enabled:
		timer.start(60 * Settings.file.editor.autosave_min_timer)
	else:
		timer.stop()
		

func timer_changed(value: int) -> void:
	Settings.file.editor.autosave_min_timer = value
	Settings.save_settings()
	
	timer.wait_time = 60 * value
	
	if (Settings.file.editor.autosave_enabled):
		timer.start()
	else:
		timer.stop()

func before_test_toggled(toggled_on: bool) -> void:
	Settings.file.editor.autosave_before_test = toggled_on
	Settings.save_settings()
