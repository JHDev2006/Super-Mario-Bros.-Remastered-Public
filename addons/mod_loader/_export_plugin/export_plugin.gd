extends EditorExportPlugin

static var hook_pre_processor: _ModLoaderModHookPreProcessor

func _get_name() -> String:
	return "Godot Mod Loader Export Plugin"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	hook_pre_processor = _ModLoaderModHookPreProcessor.new()
	hook_pre_processor.process_begin()

func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.begins_with("res://addons") or path.begins_with("res://mods-unpacked"):
		return

	if type != "GDScript":
		return
	
	# skip() 
	# We can't skip any files anymore. 
	# Godot has now a weird bug where any file that's skipped cannot be added
	# During the project exporting process.
	var hookableFile = hook_pre_processor.process_script(path, true).to_utf8_buffer()
	add_file(path, hookableFile, false)
