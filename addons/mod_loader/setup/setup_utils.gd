class_name ModLoaderSetupUtils


# Slimed down version of ModLoaderUtils for the ModLoader Self Setup

const LOG_NAME := "ModLoader:SetupUtils"


static var ModLoaderSetupLog: Object = load("res://addons/mod_loader/setup/setup_log.gd")


# Get the path to a local folder. Primarily used to get the  (packed) mods
# folder, ie "res://mods" or the OS's equivalent, as well as the configs path
static func get_local_folder_dir(subfolder: String = "") -> String:
	var game_install_directory := OS.get_executable_path().get_base_dir()

	if OS.get_name() == "macOS":
		game_install_directory = game_install_directory.get_base_dir().get_base_dir()

	# Fix for running the game through the Godot editor (as the EXE path would be
	# the editor's own EXE, which won't have any mod ZIPs)
	# if OS.is_debug_build():
	if OS.has_feature("editor"):
		game_install_directory = "res://"

	return game_install_directory.path_join(subfolder)


# Provide a path, get the file name at the end of the path
static func get_file_name_from_path(path: String, make_lower_case := true, remove_extension := false) -> String:
	var file_name := path.get_file()

	if make_lower_case:
		file_name = file_name.to_lower()

	if remove_extension:
		file_name = file_name.trim_suffix("." + file_name.get_extension())

	return file_name


# Get an array of all autoloads -> ["autoload/AutoloadName", ...]
static func get_autoload_array() -> Array:
	var autoloads := []

	# Get all autoload settings
	for prop in ProjectSettings.get_property_list():
		var name: String = prop.name
		if name.begins_with("autoload/"):
			autoloads.append(name.trim_prefix("autoload/"))

	return autoloads


# Get the index of a specific autoload
static func get_autoload_index(autoload_name: String) -> int:
	var autoloads := get_autoload_array()
	var autoload_index := autoloads.find(autoload_name)

	return autoload_index


# Get the path where override.cfg will be stored.
# Not the same as the local folder dir (for mac)
static func get_override_path() -> String:
	var base_path := ""
	if OS.has_feature("editor"):
		base_path = ProjectSettings.globalize_path("res://")
	else:
		# this is technically different to res:// in macos, but we want the
		# executable dir anyway, so it is exactly what we need
		base_path = OS.get_executable_path().get_base_dir()

	return base_path.path_join("override.cfg")


# Register an array of classes to the global scope, since Godot only does that in the editor.
static func register_global_classes_from_array(new_global_classes: Array) -> void:
	var registered_classes: Array = ProjectSettings.get_setting("_global_script_classes")
	var registered_class_icons: Dictionary = ProjectSettings.get_setting("_global_script_class_icons")

	for new_class in new_global_classes:
		if not _is_valid_global_class_dict(new_class):
			continue
		for old_class in registered_classes:
			if old_class.class == new_class.class:
				if OS.has_feature("editor"):
					ModLoaderSetupLog.info('Class "%s" to be registered as global was already registered by the editor. Skipping.' % new_class.class, LOG_NAME)
				else:
					ModLoaderSetupLog.info('Class "%s" to be registered as global already exists. Skipping.' % new_class.class, LOG_NAME)
				continue

		registered_classes.append(new_class)
		registered_class_icons[new_class.class] = "" # empty icon, does not matter

	ProjectSettings.set_setting("_global_script_classes", registered_classes)
	ProjectSettings.set_setting("_global_script_class_icons", registered_class_icons)


# Checks if all required fields are in the given [Dictionary]
# Format: { "base": "ParentClass", "class": "ClassName", "language": "GDScript", "path": "res://path/class_name.gd" }
static func _is_valid_global_class_dict(global_class_dict: Dictionary) -> bool:
	var required_fields := ["base", "class", "language", "path"]
	if not global_class_dict.has_all(required_fields):
		ModLoaderSetupLog.fatal("Global class to be registered is missing one of %s" % required_fields, LOG_NAME)
		return false

	if not FileAccess.file_exists(global_class_dict.path):
		ModLoaderSetupLog.fatal('Class "%s" to be registered as global could not be found at given path "%s"' %
		[global_class_dict.class, global_class_dict.path], LOG_NAME)
		return false

	return true


# Check if the provided command line argument was present when launching the game
static func is_running_with_command_line_arg(argument: String) -> bool:
	for arg in OS.get_cmdline_args():
		if argument == arg.split("=")[0]:
			return true

	return false


# Get the command line argument value if present when launching the game
static func get_cmd_line_arg_value(argument: String) -> String:
	var args := _get_fixed_cmdline_args()

	for arg_index in args.size():
		var arg := args[arg_index] as String

		var key := arg.split("=")[0]
		if key == argument:
			# format: `--arg=value` or `--arg="value"`
			if "=" in arg:
				var value := arg.trim_prefix(argument + "=")
				value = value.trim_prefix('"').trim_suffix('"')
				value = value.trim_prefix("'").trim_suffix("'")
				return value

			# format: `--arg value` or `--arg "value"`
			elif arg_index +1 < args.size() and not args[arg_index +1].begins_with("--"):
				return args[arg_index + 1]

	return ""


static func _get_fixed_cmdline_args() -> PackedStringArray:
	return fix_godot_cmdline_args_string_space_splitting(OS.get_cmdline_args())


# Reverses a bug in Godot, which splits input strings at spaces even if they are quoted
# e.g. `--arg="some value" --arg-two 'more value'` becomes `[ --arg="some, value", --arg-two, 'more, value' ]`
static func fix_godot_cmdline_args_string_space_splitting(args: PackedStringArray) -> PackedStringArray:
	if not OS.has_feature("editor"): # only happens in editor builds
		return args
	if OS.has_feature("windows"): # windows is unaffected
		return args

	var fixed_args := PackedStringArray([])
	var fixed_arg := ""
	# if we encounter an argument that contains `=` followed by a quote,
	# or an argument that starts with a quote, take all following args and
	# concatenate them into one, until we find the closing quote
	for arg in args:
		var arg_string := arg as String
		if '="' in arg_string or '="' in fixed_arg or \
				arg_string.begins_with('"') or fixed_arg.begins_with('"'):
			if not fixed_arg == "":
				fixed_arg += " "
			fixed_arg += arg_string
			if arg_string.ends_with('"'):
				fixed_args.append(fixed_arg.trim_prefix(" "))
				fixed_arg = ""
				continue
		# same thing for single quotes
		elif "='" in arg_string or "='" in fixed_arg \
				or arg_string.begins_with("'") or fixed_arg.begins_with("'"):
			if not fixed_arg == "":
				fixed_arg += " "
			fixed_arg += arg_string
			if arg_string.ends_with("'"):
				fixed_args.append(fixed_arg.trim_prefix(" "))
				fixed_arg = ""
				continue

		else:
			fixed_args.append(arg_string)

	return fixed_args


# Slightly modified version of:
# https://gist.github.com/willnationsdev/00d97aa8339138fd7ef0d6bd42748f6e
# Removed .import from the extension filter.
# p_match is a string that filters the list of files.
# If p_match_is_regex is false, p_match is directly string-searched against the FILENAME.
# If it is true, a regex object compiles p_match and runs it against the FILEPATH.
static func get_flat_view_dict(
	p_dir := "res://",
 	p_match := "",
	p_match_file_extensions: Array[StringName] = [],
	p_match_is_regex := false,
	include_empty_dirs := false,
	ignored_dirs: Array[StringName] = []
) -> PackedStringArray:
	var data: PackedStringArray = []
	var regex: RegEx

	if p_match_is_regex:
		regex = RegEx.new()
		var _compile_error: int = regex.compile(p_match)
		if not regex.is_valid():
			return data

	var dirs := [p_dir]
	var first := true
	while not dirs.is_empty():
		var dir_name : String = dirs.back()
		var dir := DirAccess.open(dir_name)
		dirs.pop_back()

		if dir_name.lstrip("res://").get_slice("/", 0) in ignored_dirs:
			continue

		if dir:
			var _dirlist_error: int = dir.list_dir_begin()
			var file_name := dir.get_next()
			if include_empty_dirs and not dir_name == p_dir:
				data.append(dir_name)
			while file_name != "":
				if not dir_name == "res://":
					first = false
				# ignore hidden, temporary, or system content
				if not file_name.begins_with(".") and not file_name.get_extension() == "tmp":
					# If a directory, then add to list of directories to visit
					if dir.current_is_dir():
						dirs.push_back(dir.get_current_dir() + "/" + file_name)
					# If a file, check if we already have a record for the same name
					else:
						var path := dir.get_current_dir() + ("/" if not first else "") + file_name
						# grab all
						if not p_match and not p_match_file_extensions:
							data.append(path)
						# grab matching strings
						elif not p_match_is_regex and p_match and file_name.contains(p_match):
							data.append(path)
						# garb matching file extension
						elif p_match_file_extensions and file_name.get_extension() in p_match_file_extensions:
							data.append(path)
						# grab matching regex
						elif p_match_is_regex:
							var regex_match := regex.search(path)
							if regex_match != null:
								data.append(path)
				# Move on to the next file in this directory
				file_name = dir.get_next()
			# We've exhausted all files in this directory. Close the iterator.
			dir.list_dir_end()
	return data


static func copy_file(from: String, to: String) -> void:
	ModLoaderSetupLog.debug("Copy file from: \"%s\" to: \"%s\"" % [from, to], LOG_NAME)
	var global_to_path := ProjectSettings.globalize_path(to.get_base_dir())

	if not DirAccess.dir_exists_absolute(global_to_path):
		ModLoaderSetupLog.debug("Creating dir \"%s\"" % global_to_path, LOG_NAME)
		DirAccess.make_dir_recursive_absolute(global_to_path)

	var file_from := FileAccess.open(from, FileAccess.READ)
	var file_from_error := file_from.get_error()

	if not file_from_error == OK:
		ModLoaderSetupLog.error("Error accessing file \"%s\": %s" % [from, error_string(file_from_error)], LOG_NAME)
		return

	var file_from_content := file_from.get_buffer(file_from.get_length())
	var file_to := FileAccess.open(to, FileAccess.WRITE)
	var file_to_error := file_to.get_error()

	if not file_to_error == OK:
		ModLoaderSetupLog.error("Error writing file \"%s\": %s" % [to, error_string(file_to_error)], LOG_NAME)
		return

	file_to.store_buffer(file_from_content)
