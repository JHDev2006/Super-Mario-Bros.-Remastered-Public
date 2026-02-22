class_name _ModLoaderModHookPacker
extends RefCounted


# This class is used to generate mod hooks on demand and pack them into a zip file.
# Currently all of the included functions are internal and should only be used by the mod loader itself.

const LOG_NAME := "ModLoader:ModHookPacker"


static func start() -> void:
	ModLoaderLog.info("Generating mod hooks .zip", LOG_NAME)
	var hook_pre_processor = _ModLoaderModHookPreProcessor.new()
	hook_pre_processor.process_begin()

	var mod_hook_pack_path := _ModLoaderPath.get_path_to_hook_pack()

	# Create mod hook pack path if necessary
	if not DirAccess.dir_exists_absolute(mod_hook_pack_path.get_base_dir()):
		var error := DirAccess.make_dir_recursive_absolute(mod_hook_pack_path.get_base_dir())
		if not error == OK:
			ModLoaderLog.error("Error creating the mod hook directory at %s" % mod_hook_pack_path, LOG_NAME)
			return
		ModLoaderLog.debug("Created dir at: %s" % mod_hook_pack_path, LOG_NAME)

	# Create mod hook zip
	var zip_writer := ZIPPacker.new()
	var error: Error

	if not FileAccess.file_exists(mod_hook_pack_path):
		# Clear cache if the hook pack does not exist
		_ModLoaderCache.remove_data("hooks")
		error = zip_writer.open(mod_hook_pack_path)
	else:
		# If there is a pack already, append to it
		error = zip_writer.open(mod_hook_pack_path, ZIPPacker.APPEND_ADDINZIP)
	if not error == OK:
		ModLoaderLog.error("Error (%s) writing to hooks zip, consider deleting this file: %s" % [error, mod_hook_pack_path], LOG_NAME)
		return

	ModLoaderLog.debug("Scripts requiring hooks: %s" % [ModLoaderStore.hooked_script_paths], LOG_NAME)

	var cache := _ModLoaderCache.get_data("hooks")
	var cached_script_paths: Dictionary = {} if cache.is_empty() or not cache.has("hooked_script_paths") else cache.hooked_script_paths
	if cached_script_paths == ModLoaderStore.hooked_script_paths:
		ModLoaderLog.info("Scripts are already processed according to cache, skipping process.", LOG_NAME)
		zip_writer.close()
		return

	var new_hooks_created := false
	# Get all scripts that need processing
	for path in ModLoaderStore.hooked_script_paths.keys():
		var method_mask: Array[String] = []
		method_mask.assign(ModLoaderStore.hooked_script_paths[path])
		var processed_source_code := hook_pre_processor.process_script_verbose(path, false, method_mask)

		# Skip writing to the zip if no new hooks were created for this script
		if not hook_pre_processor.script_paths_hooked.has(path):
			ModLoaderLog.debug("No new hooks were created in \"%s\", skipping writing to hook pack." % path, LOG_NAME)
			continue

		zip_writer.start_file(path.trim_prefix("res://"))
		zip_writer.write_file(processed_source_code.to_utf8_buffer())
		zip_writer.close_file()

		ModLoaderLog.debug("Hooks created for script: %s" % path, LOG_NAME)
		new_hooks_created = true

	if new_hooks_created:
		_ModLoaderCache.update_data("hooks", {"hooked_script_paths": ModLoaderStore.hooked_script_paths})
		_ModLoaderCache.save_to_file()
		ModLoader.new_hooks_created.emit()

	zip_writer.close()
