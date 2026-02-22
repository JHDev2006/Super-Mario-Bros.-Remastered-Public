@tool
class_name ModToolHookGen
extends RefCounted


static func transform_one(path: String, mod_tool_store: ModToolStore) -> Error:
	var source_code_processed := mod_tool_store.mod_hook_preprocessor.process_script(path, true)
	var backup_path := "%s/%s" % [mod_tool_store.path_script_backup_dir, path.trim_prefix("res://")]

	# Create a backup of the vanilla script files
	if not FileAccess.file_exists(backup_path):
		ModToolUtils.file_copy(path, backup_path)

	var file := FileAccess.open(path, FileAccess.WRITE)

	if not file:
		var error := file.get_error()
		return error

	# Write processed source_code to file
	file.store_string(source_code_processed)
	file.close()

	mod_tool_store.hooked_scripts[path] = true

	return OK


static func restore(path: String, mod_tool_store: ModToolStore) -> Error:
	var backup_path := "%s/%s" % [mod_tool_store.path_script_backup_dir, path.trim_prefix("res://")]
	var backup_file := FileAccess.open(backup_path, FileAccess.READ)

	if not backup_file:
		mod_tool_store.hooked_scripts.erase(path)
		clear_mod_hook_preprocessor_hashmap(path, mod_tool_store)
		return FileAccess.get_open_error()

	var restored_source := backup_file.get_as_text()

	var file := FileAccess.open(path, FileAccess.WRITE)

	if not file:
		return FileAccess.get_open_error()

	# Write processed source_code to file
	file.store_string(restored_source)
	file.close()

	mod_tool_store.hooked_scripts.erase(path)

	clear_mod_hook_preprocessor_hashmap(path, mod_tool_store)

	return OK


static func clear_mod_hook_preprocessor_hashmap(path: String, mod_tool_store: ModToolStore) -> void:
	var script: GDScript = load(path)

	for method in script.get_script_method_list():
		mod_tool_store.mod_hook_preprocessor.hashmap.erase(_ModLoaderHooks.get_hook_hash(path, method.name))
