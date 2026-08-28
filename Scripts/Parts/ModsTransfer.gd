class_name ModsTransfer
extends Node

static func find_mods_in_old_path() -> Array:
	var arr := []
	
	var exe_path := OS.get_executable_path()
	var exe_dir  := exe_path.get_base_dir()
	var old_path := exe_dir.path_join("mods")
	
	for mod in DirAccess.get_files_at(old_path):
		if mod.contains(".zip") == false:
			continue
		var mod_path = old_path.path_join(mod)
		
		print("Mod \"%s\" found, will be cutted to: %s" % [mod, _ModLoaderPath.get_local_folder_dir("mods/"+mod)])
		arr.push_back(mod_path)
	return arr

static func move_mods_to_new_path(arr := []) -> void:
	var new_path := _ModLoaderPath.get_local_folder_dir("mods")
	
	var success = false
	for i: String in arr:
		success = true
		move_file(i, new_path.path_join(i.get_file()))
		
	if success:
		var stored_at := "Config folder" if Global.config_path != "user://" else "Appdata folder"
		Global.log_warning("All GML mods are now at your %s." % stored_at)
		
		var exe_path := OS.get_executable_path()
		var exe_dir  := exe_path.get_base_dir()
		var old_path := exe_dir.path_join("mods")
		
		DirAccess.remove_absolute(old_path)

static func move_file(path := "", move_to := "") -> void:
	var source := FileAccess.open(path, FileAccess.READ)

	if (source == null):
		var file_error := FileAccess.get_open_error()
		Global.log_error("GML Mod: \"%s\" has not been moved due to an error! CODE: %s" % [path.get_file(), error_string(file_error)])
		return
	
	var pasted := FileAccess.open(move_to, FileAccess.WRITE)
	var success := pasted.store_buffer(source.get_buffer(source.get_length()))
	
	if not success:
		Global.log_error("Couldn't move file \"%s\" to: %s" % [path.get_file(), move_to])
		return

	pasted.close()
	source.close()
	
	if success:
		print("Succesfully moved \"%s\"" % path.get_file())
		DirAccess.remove_absolute(path)
