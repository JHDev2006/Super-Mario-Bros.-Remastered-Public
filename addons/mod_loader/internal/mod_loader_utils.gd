class_name ModLoaderUtils
extends Node


const LOG_NAME := "ModLoader:ModLoaderUtils"


## This is a dummy func. It is exclusively used to show notes in the code that
## stay visible after decompiling a PCK, as is primarily intended to assist new
## modders in understanding and troubleshooting issues
static func _code_note(_msg:String):
	pass


## Returns an empty [String] if the key does not exist or is not type of [String]
static func get_string_from_dict(dict: Dictionary, key: String) -> String:
	if not dict.has(key):
		return ""

	if not dict[key] is String:
		return ""

	return dict[key]


## Returns an empty [Array] if the key does not exist or is not type of [Array]
static func get_array_from_dict(dict: Dictionary, key: String) -> Array:
	if not dict.has(key):
		return []

	if not dict[key] is Array:
		return []

	return dict[key]


## Returns an empty [Dictionary] if the key does not exist or is not type of [Dictionary]
static func get_dict_from_dict(dict: Dictionary, key: String) -> Dictionary:
	if not dict.has(key):
		return {}

	if not dict[key] is Dictionary:
		return {}

	return dict[key]


## Works like [method Dictionary.has_all],
## but allows for more specific errors if a field is missing
static func dict_has_fields(dict: Dictionary, required_fields: Array[String]) -> bool:
	var missing_fields := get_missing_dict_fields(dict, required_fields)

	if missing_fields.size() > 0:
		ModLoaderLog.fatal("Dictionary is missing required fields: %s" % str(missing_fields), LOG_NAME)
		return false

	return true


static func get_missing_dict_fields(dict: Dictionary, required_fields: Array[String]) -> Array[String]:
	var missing_fields := required_fields.duplicate()

	for key in dict.keys():
		if(required_fields.has(key)):
			missing_fields.erase(key)

	return missing_fields


## Register an array of classes to the global scope, since Godot only does that in the editor.
static func register_global_classes_from_array(new_global_classes: Array) -> void:
	var registered_classes: Array = ProjectSettings.get_setting("_global_script_classes")
	var registered_class_icons: Dictionary = ProjectSettings.get_setting("_global_script_class_icons")

	for new_class in new_global_classes:
		if not _is_valid_global_class_dict(new_class):
			continue
		for old_class in registered_classes:
			if old_class.get_class() == new_class.get_class():
				if OS.has_feature("editor"):
					ModLoaderLog.info('Class "%s" to be registered as global was already registered by the editor. Skipping.' % new_class.get_class(), LOG_NAME)
				else:
					ModLoaderLog.info('Class "%s" to be registered as global already exists. Skipping.' % new_class.get_class(), LOG_NAME)
				continue

		registered_classes.append(new_class)
		registered_class_icons[new_class.get_class()] = "" # empty icon, does not matter

	ProjectSettings.set_setting("_global_script_classes", registered_classes)
	ProjectSettings.set_setting("_global_script_class_icons", registered_class_icons)


## Checks if all required fields are in the given [Dictionary]
## Format: [code]{ "base": "ParentClass", "class": "ClassName", "language": "GDScript", "path": "res://path/class_name.gd" }[/code]
static func _is_valid_global_class_dict(global_class_dict: Dictionary) -> bool:
	var required_fields := ["base", "class", "language", "path"]
	if not global_class_dict.has_all(required_fields):
		ModLoaderLog.fatal("Global class to be registered is missing one of %s" % required_fields, LOG_NAME)
		return false

	if not _ModLoaderFile.file_exists(global_class_dict.path):
		ModLoaderLog.fatal('Class "%s" to be registered as global could not be found at given path "%s"' %
		[global_class_dict.get_class, global_class_dict.path], LOG_NAME)
		return false

	return true
