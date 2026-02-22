@tool
class_name ModToolInterfaceHookRestore
extends Window


@onready var mod_tool_store: ModToolStore = get_node_or_null("/root/ModToolStore")
@onready var info_output: RichTextLabel = %InfoOutput
@onready var restart: Window = %Restart
@onready var button_restore_start: Button = %ButtonRestoreStart


func start_restore() -> void:
	# Get all script not in addons or mods-unpacked
	var all_script_file_paths := ModToolUtils.get_flat_view_dict("res://", "", [&"gd"], false, false, [&"addons", &"mods-unpacked"])

	var encountered_error := false

	for script_path in mod_tool_store.hooked_scripts.keys():
		var error := ModToolHookGen.restore(script_path, mod_tool_store)

		if not error == OK:
			encountered_error = true
			info_output.add_text("ERROR: Accessing file at path \"%s\" failed with error: %s \n" % [script_path, error_string(error)])
			break

		info_output.add_text("Restored \"%s\" \n" % script_path)

	if encountered_error:
		info_output.add_text("ERROR: Restore aborted.\n")
	else:
		mod_tool_store.is_hook_generation_done = false
		info_output.add_text("Restore completed successfully!\n")

		mod_tool_store.save_store()

		restart.show()


func _on_close_requested() -> void:
	hide()


func _on_button_restart_now_pressed() -> void:
	await get_tree().create_timer(1.0).timeout
	EditorInterface.restart_editor()


func _on_button_restart_later_pressed() -> void:
	restart.hide()
	hide()


func _on_restart_close_requested() -> void:
	restart.hide()


func _on_button_restore_start_pressed() -> void:
	button_restore_start.disabled = true
	start_restore()
