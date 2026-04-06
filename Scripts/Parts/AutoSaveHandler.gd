class_name AutoSaveHandler
extends Node

@onready var level_editor: LevelEditor = get_parent()
@onready var timer := $AutoSaveTimer

signal finished

func _ready() -> void:
	await level_editor.ready
	level_editor.level_start.connect(before_test_autosave)
	
	if (LevelEditor.autosave_enabled):
		timer.start(60 * LevelEditor.autosave_min_timer)

var old_second := -1
func _physics_process(delta: float) -> void:
	if timer.time_left > 0 and timer.time_left <= 5 and old_second != floori(timer.time_left):
		old_second = floori(timer.time_left)
		Global.log_comment("AutoSave happens in: %s seconds!" % str(floori(timer.time_left) + 1), 1)

func before_test_autosave() -> void:
	handle_autosave(LevelEditor.autosave_before_test)

func handle_autosave(save: bool = true) -> void:
	timer.stop()
	if save:
		autosave_tick()
	finished.emit()

func autosave_tick() -> void:
	start_autosave()
	
	if LevelEditor.autosave_enabled:
		timer.start(60 * LevelEditor.autosave_min_timer)

func start_autosave() -> void:
	var level_name := level_editor.level_name if (level_editor.level_name != "") else "Unnamed Level"
	var file_name = level_name.to_pascal_case() + "_" + Time.get_datetime_string_from_system() + ".lvl"

	var temp_level_file = $"../LevelSaver".save_level(level_name, level_editor.level_author, level_editor.level_desc, level_editor.difficulty)
	$"../LevelSaver".write_temp_file(temp_level_file, file_name)
	
	Global.log_comment("Level auto saved as '%s'." % file_name)

func enable_toggled(toggled_on: bool) -> void:
	LevelEditor.autosave_enabled = toggled_on
	
	if LevelEditor.autosave_enabled:
		timer.start(60 * LevelEditor.autosave_min_timer)
	else:
		timer.stop()

func timer_changed(value: int) -> void:
	LevelEditor.autosave_min_timer = value
	
	timer.wait_time = 60 * value
	
	if (LevelEditor.autosave_enabled):
		timer.start()
	else:
		timer.stop()

func before_test_toggled(toggled_on: bool) -> void:
	LevelEditor.autosave_before_test = toggled_on
	
func editor_return_toggled(toggled_on: bool) -> void:
	LevelEditor.autosave_on_editor_return = toggled_on

func delete_all_cache() -> void:
	var path := Global.config_path.path_join("custom_levels/autosaves")
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)
	Global.log_warning("Autosaves folder has been deleted!")
	
func delete_level_cache() -> void:
	var level_name := level_editor.level_name if (level_editor.level_name != "") else "Unnamed Level"
	var lvl_file_name = level_name.to_pascal_case()
	for i in "<>:?!/":
		lvl_file_name = lvl_file_name.replace(i, "")
	
	var path := Global.config_path.path_join("custom_levels/autosaves")
	for file_name in DirAccess.get_files_at(path):
		if file_name.contains(lvl_file_name):
			DirAccess.remove_absolute(path.path_join(file_name))
	
	Global.log_warning("Autosaves files for current level name has been deleted!")
