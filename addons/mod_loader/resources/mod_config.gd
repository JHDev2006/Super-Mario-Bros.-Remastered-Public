class_name ModConfig
extends Resource
##
## This Class is used to represent a configuration for a mod.[br]
## The Class provides functionality to initialize, validate, save, and remove a mod's configuration.
##
## @tutorial(Creating a Mod Config Schema with JSON-Schemas): 	https://wiki.godotmodding.com/guides/modding/config_json/


const LOG_NAME := "ModLoader:ModConfig"

## Name of the config - must be unique
var name: String
## The mod_id this config belongs to
var mod_id: String
## The JSON-Schema this config uses for validation
var schema: Dictionary
## The data this config holds
var data: Dictionary
## The path where the JSON file for this config is stored
var save_path: String
## False if any data is invalid
var valid := false


func _init(_mod_id: String, _data: Dictionary, _save_path: String, _schema: Dictionary = {}) -> void:
	name = _ModLoaderPath.get_file_name_from_path(_save_path, true, true)
	mod_id = _mod_id
	schema = ModLoaderStore.mod_data[_mod_id].manifest.config_schema if _schema.is_empty() else _schema
	data = _data
	save_path = _save_path

	var error_message := validate()

	if not error_message == "":
		ModLoaderLog.error("Mod Config for mod \"%s\" failed JSON Schema Validation with error message: \"%s\"" % [mod_id, error_message], LOG_NAME)
		return

	valid = true


func get_data_as_string() -> String:
	return JSON.stringify(data)


func get_schema_as_string() -> String:
	return JSON.stringify(schema)


# Empty string if validation was successful
func validate() -> String:
	var json_schema := JSONSchema.new()
	var error := json_schema.validate(get_data_as_string(), get_schema_as_string())

	if error.is_empty():
		valid = true
	else:
		valid = false

	return error


# Runs the JSON-Schema validation and returns true if valid
func is_valid() -> bool:
	if validate() == "":
		valid = true
		return true

	valid = false
	return false


## Saves the config data to the config file
func save_to_file() -> bool:
	var is_success := _ModLoaderFile.save_dictionary_to_json_file(data, save_path)
	return is_success


## Removes the config file
func remove_file() -> bool:
	var is_success := _ModLoaderFile.remove_file(save_path)
	return is_success
