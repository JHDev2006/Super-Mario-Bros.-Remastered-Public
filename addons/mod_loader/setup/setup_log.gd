class_name ModLoaderSetupLog


# Slimed down version of ModLoaderLog for the ModLoader Self Setup

const MOD_LOG_PATH := "user://logs/modloader.log"

enum VERBOSITY_LEVEL {
	ERROR,
	WARNING,
	INFO,
	DEBUG,
}


class ModLoaderLogEntry:
	extends Resource

	var mod_name: String
	var message: String
	var type: String
	var time: String


	func _init(_mod_name: String, _message: String, _type: String, _time: String) -> void:
		mod_name = _mod_name
		message = _message
		type = _type
		time = _time


	func get_entry() -> String:
		return time + get_prefix() + message


	func get_prefix() -> String:
		return "%s %s: " % [type.to_upper(), mod_name]


	func get_md5() -> String:
		return str(get_prefix(), message).md5_text()


# API log functions
# =============================================================================

# Logs the error in red and a stack trace. Prefixed FATAL-ERROR
# Stops the execution in editor
# Always logged
static func fatal(message: String, mod_name: String) -> void:
	_log(message, mod_name, "fatal-error")


# Logs the message and pushed an error. Prefixed ERROR
# Always logged
static func error(message: String, mod_name: String) -> void:
	_log(message, mod_name, "error")


# Logs the message and pushes a warning. Prefixed WARNING
# Logged with verbosity level at or above warning (-v)
static func warning(message: String, mod_name: String) -> void:
	_log(message, mod_name, "warning")


# Logs the message. Prefixed INFO
# Logged with verbosity level at or above info (-vv)
static func info(message: String, mod_name: String) -> void:
	_log(message, mod_name, "info")


# Logs the message. Prefixed SUCCESS
# Logged with verbosity level at or above info (-vv)
static func success(message: String, mod_name: String) -> void:
	_log(message, mod_name, "success")


# Logs the message. Prefixed DEBUG
# Logged with verbosity level at or above debug (-vvv)
static func debug(message: String, mod_name: String) -> void:
	_log(message, mod_name, "debug")


# Logs the message formatted with [method JSON.print]. Prefixed DEBUG
# Logged with verbosity level at or above debug (-vvv)
static func debug_json_print(message: String, json_printable, mod_name: String) -> void:
	message = "%s\n%s" % [message, JSON.stringify(json_printable, "  ")]
	_log(message, mod_name, "debug")


# Internal log functions
# =============================================================================

static func _log(message: String, mod_name: String, log_type: String = "info") -> void:
	var time := "%s   " % _get_time_string()
	var log_entry := ModLoaderLogEntry.new(mod_name, message, log_type, time)

	match log_type.to_lower():
		"fatal-error":
			push_error(message)
			_write_to_log_file(log_entry.get_entry())
			_write_to_log_file(JSON.stringify(get_stack(), "  "))
			assert(false, message)
		"error":
			printerr(message)
			push_error(message)
			_write_to_log_file(log_entry.get_entry())
		"warning":
				print(log_entry.get_prefix() + message)
				push_warning(message)
				_write_to_log_file(log_entry.get_entry())
		"info", "success":
				print(log_entry.get_prefix() + message)
				_write_to_log_file(log_entry.get_entry())
		"debug":
				print(log_entry.get_prefix() + message)
				_write_to_log_file(log_entry.get_entry())


# Internal Date Time
# =============================================================================

# Returns the current time as a string in the format hh:mm:ss
static func _get_time_string() -> String:
	var date_time := Time.get_datetime_dict_from_system()
	return "%02d:%02d:%02d" % [ date_time.hour, date_time.minute, date_time.second ]


# Returns the current date as a string in the format yyyy-mm-dd
static func _get_date_string() -> String:
	var date_time := Time.get_datetime_dict_from_system()
	return "%s-%02d-%02d" % [ date_time.year, date_time.month, date_time.day ]


# Returns the current date and time as a string in the format yyyy-mm-dd_hh:mm:ss
static func _get_date_time_string() -> String:
	return "%s_%s" % [ _get_date_string(), _get_time_string() ]


# Internal File
# =============================================================================

static func _write_to_log_file(string_to_write: String) -> void:
	if not FileAccess.file_exists(MOD_LOG_PATH):
		_rotate_log_file()

	var log_file := FileAccess.open(MOD_LOG_PATH, FileAccess.READ_WRITE)

	if log_file == null:
		assert(false, "Could not open log file, error code: %s" % error)
		return

	log_file.seek_end()
	log_file.store_string("\n" + string_to_write)
	log_file.close()


# Keeps log backups for every run, just like the Godot; gdscript implementation of
# https://github.com/godotengine/godot/blob/1d14c054a12dacdc193b589e4afb0ef319ee2aae/core/io/logger.cpp#L151
static func _rotate_log_file() -> void:
	var MAX_LOGS: int = ProjectSettings.get_setting("debug/file_logging/max_log_files")

	if FileAccess.file_exists(MOD_LOG_PATH):
		if MAX_LOGS > 1:
			var datetime := _get_date_time_string().replace(":", ".")
			var backup_name: String = MOD_LOG_PATH.get_basename() + "_" + datetime
			if MOD_LOG_PATH.get_extension().length() > 0:
				backup_name += "." + MOD_LOG_PATH.get_extension()

			var dir := DirAccess.open(MOD_LOG_PATH.get_base_dir())
			if not dir == null:
				dir.copy(MOD_LOG_PATH, backup_name)
			_clear_old_log_backups()

	# only File.WRITE creates a new file, File.READ_WRITE throws an error
	var log_file := FileAccess.open(MOD_LOG_PATH, FileAccess.WRITE)
	if log_file == null:
		assert(false, "Could not open log file, error code: %s" % error)
	log_file.store_string('%s Created log' % _get_date_string())
	log_file.close()


static func _clear_old_log_backups() -> void:
	var MAX_LOGS := int(ProjectSettings.get_setting("debug/file_logging/max_log_files"))
	var MAX_BACKUPS := MAX_LOGS - 1 # -1 for the current new log (not a backup)
	var basename := MOD_LOG_PATH.get_file().get_basename() as String
	var extension := MOD_LOG_PATH.get_extension() as String

	var dir := DirAccess.open(MOD_LOG_PATH.get_base_dir())
	if dir == null:
		return

	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var file := dir.get_next()
	var backups := []
	while file.length() > 0:
		if (not dir.current_is_dir() and
				file.begins_with(basename) and
				file.get_extension() == extension and
				not file == MOD_LOG_PATH.get_file()):
			backups.append(file)
		file = dir.get_next()
	dir.list_dir_end()

	if backups.size() > MAX_BACKUPS:
		backups.sort()
		backups.resize(backups.size() - MAX_BACKUPS)
		for file_to_delete in backups:
			dir.remove(file_to_delete)
