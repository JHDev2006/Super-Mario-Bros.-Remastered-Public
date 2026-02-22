@tool
class_name ModToolInterfaceHookGen
extends Window


signal hooks_exist_pressed

@onready var mod_tool_store: ModToolStore = get_node_or_null("/root/ModToolStore")
@onready var info_output: RichTextLabel = %InfoOutput
@onready var restart: Window = %Restart
@onready var button_gen_start: Button = %ButtonGenStart


func generate_hooks() -> void:
	# Get all script not in addons or mods-unpacked
	var all_script_file_paths := ModToolUtils.get_flat_view_dict("res://", "", [&"gd"], false, false, [&"addons", &"mods-unpacked"])

	for script_file_path in all_script_file_paths:
		if mod_tool_store.hooked_scripts.has(script_file_path):
			info_output.add_text("Skipping - Hooks already exists for \"%s\" \n" % script_file_path)
			continue

		var error := ModToolHookGen.transform_one(script_file_path, mod_tool_store)

		if not error == OK:
			info_output.add_text("ERROR: Accessing file at path \"%s\" failed with error: %s \n" % [script_file_path, error_string(error)])
		else:
			info_output.add_text("Added Hooks for \"%s\" \n" % script_file_path)

	mod_tool_store.is_hook_generation_done = true
	info_output.add_text("Mod Hook generation completed successfully!\n")

	mod_tool_store.save_store()
	restart.show()


func _on_button_pressed() -> void:
	button_gen_start.disabled = true
	generate_hooks()


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


func _on_button_hooks_exist_pressed() -> void:
	mod_tool_store.is_hook_generation_done = true
	hooks_exist_pressed.emit()
	hide()
