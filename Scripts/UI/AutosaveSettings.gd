extends Control

func _ready() -> void:
	$Panel/ScrollContainer/Options/Time.maximum = AutosaveHandler.max_time
	set_process(false)

func _process(delta: float) -> void:
	if (Global.multibind_action_just_pressed("ui_back") || Input.is_action_just_pressed("mb_right")):
		close()

func open() -> void:
	$Panel/ScrollContainer/Options/Enable.grab_focus()
	show()
	set_process(true)

func close() -> void:
	hide()
	set_process(false)

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
