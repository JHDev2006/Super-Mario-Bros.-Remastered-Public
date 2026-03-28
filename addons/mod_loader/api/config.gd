class_name ModLoaderConfig
extends Object
##
## Class for managing per-mod configurations.
##
## @tutorial(Creating a Mod Config Schema with JSON-Schemas): 	https://wiki.godotmodding.com/guides/modding/config_json/

const LOG_NAME := "ModLoader:Config"
const DEFAULT_CONFIG_NAME  := "default"


## Creates a new configuration for a mod.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## - [param config_name] ([String]): The name of the configuration.[br]
## - [param config_data] ([Dictionary]): The configuration data to be stored.[br]
## [br]
## [b]Returns:[/b][br]
## - [ModConfig]: The created [ModConfig] object if successful, or null otherwise.
static func create_config(mod_id: String, config_name: String, config_data: Dictionary) -> ModConfig:
	var default_config: ModConfig = get_default_config(mod_id)
	if not default_config:
		ModLoaderLog.error(
			"Failed to create config \"%s\". No config schema found for \"%s\"."
			% [config_name, mod_id], LOG_NAME
		)
		return null

	# Make sure the config name is not empty
	if config_name == "":
		ModLoaderLog.error(
			"Failed to create config \"%s\". The config name cannot be empty."
			% config_name, LOG_NAME
		)
		return null

	# Make sure the config name is unique
	if ModLoaderStore.mod_data[mod_id].configs.has(config_name):
		ModLoaderLog.error(
			"Failed to create config \"%s\". A config with the name \"%s\" already exists."
			% [config_name, config_name], LOG_NAME
		)
		return null

	# Create the config save path based on the config_name
	var config_file_path := _ModLoaderPath.get_path_to_mod_configs_dir(mod_id).path_join("%s.json" % config_name)
	# Initialize a new ModConfig object with the provided parameters
	var mod_config := ModConfig.new(
		mod_id,
		config_data,
		config_file_path
	)

	# Check if the mod_config is valid
	if not mod_config.is_valid:
		return null

	# Store the mod_config in the mod's ModData
	ModLoaderStore.mod_data[mod_id].configs[config_name] = mod_config
	# Save the mod_config to a new config JSON file in the mod's config directory
	var is_save_success := mod_config.save_to_file()

	if not is_save_success:
		return null

	ModLoaderLog.debug("Created new config \"%s\" for mod \"%s\"" % [config_name, mod_id], LOG_NAME)

	return mod_config


## Updates an existing [ModConfig] object with new data and saves the config file.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param config] ([ModConfig]): The [ModConfig] object to be updated.[br]
## [br]
## [b]Returns:[/b][br]
## - [ModConfig]: The updated [ModConfig] object if successful, or null otherwise.
static func update_config(config: ModConfig) -> ModConfig:
	# Validate the config and check for any validation errors
	var error_message := config.validate()

	# Check if the config is the "default" config, which cannot be modified
	if config.name == DEFAULT_CONFIG_NAME:
		ModLoaderLog.error("The \"default\" config cannot be modified. Please create a new config instead.", LOG_NAME)
		return null

	# Check if the config passed validation
	if not config.is_valid:
		ModLoaderLog.error("Update for config \"%s\" failed validation with error message \"%s\"" % [config.name, error_message], LOG_NAME)
		return null

	# Save the updated config to the config file
	var is_save_success := config.save_to_file()

	if not is_save_success:
		ModLoaderLog.error("Failed to save config \"%s\" to \"%s\"." % [config.name, config.save_path], LOG_NAME)
		return null

	# Return the updated config
	return config


## Deletes a [ModConfig] object and performs cleanup operations.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param config] ([ModConfig]): The [ModConfig] object to be deleted.[br]
## [br]
## [b]Returns:[/b][br]
## - [bool]: True if the deletion was successful, False otherwise.
static func delete_config(config: ModConfig) -> bool:
	# Check if the config is the "default" config, which cannot be deleted
	if config.name == DEFAULT_CONFIG_NAME:
		ModLoaderLog.error("Deletion of the default configuration is not allowed.", LOG_NAME)
		return false

	# Change the current config to the "default" config
	set_current_config(get_default_config(config.mod_id))
	# Remove the config file from the Mod Config directory
	var is_remove_success := config.remove_file()

	if not is_remove_success:
		return false

	# Remove the config from ModData
	ModLoaderStore.mod_data[config.mod_id].configs.erase(config.name)

	return true


## Sets the current configuration of a mod to the specified configuration.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param config] ([ModConfig]): The [ModConfig] object to be set as current config.
static func set_current_config(config: ModConfig) -> void:
	ModLoaderStore.mod_data[config.mod_id].current_config = config


## Returns the schema for the specified mod id.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - A dictionary representing the schema for the mod's configuration file.
static func get_config_schema(mod_id: String) -> Dictionary:
	# Get all config files for the specified mod
	var mod_configs := get_configs(mod_id)

	# If no config files were found, return an empty dictionary
	if mod_configs.is_empty():
		return {}

	# The schema is the same for all config files, so we just return the schema of the default config file
	return mod_configs.default.schema


## Retrieves the schema for a specific property key.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param config] ([ModConfig]): The [ModConfig] object from which to retrieve the schema.[br]
## - [param prop] ([String]): The property key for which to retrieve the schema.[br]
## [br]
## [b]Returns:[/b][br]
## - [Dictionary]: The schema dictionary for the specified property.
static func get_schema_for_prop(config: ModConfig, prop: String) -> Dictionary:
	# Split the property string into an array of property keys
	var prop_array := prop.split(".")

	# If the property array is empty, return the schema for the root property
	if prop_array.is_empty():
		return config.schema.properties[prop]

	# Traverse the schema dictionary to find the schema for the specified property
	var schema_for_prop := _traverse_schema(config.schema.properties, prop_array)

	# If the schema for the property is empty, log an error and return an empty dictionary
	if schema_for_prop.is_empty():
		ModLoaderLog.error("No Schema found for property \"%s\" in config \"%s\" for mod \"%s\"" % [prop, config.name, config.mod_id], LOG_NAME)
		return {}

	return schema_for_prop


# Recursively traverses the schema dictionary based on the provided [code]prop_key_array[/code]
# and returns the corresponding schema for the target property.[br]
# [br]
# [b]Parameters:[/b][br]
# - [param schema_prop]: The current schema dictionary to traverse.[br]
# - [param prop_key_array]: An array containing the property keys representing the path to the target property.[br]
# [br]
# [b]Returns:[/b][br]
# - [Dictionary]: The schema dictionary corresponding to the target property specified by the [code]prop_key_array[/code].
# If the target property is not found, an empty dictionary is returned.
static func _traverse_schema(schema_prop: Dictionary, prop_key_array: Array) -> Dictionary:
	# Return the current schema_prop if the prop_key_array is empty (reached the destination property)
	if prop_key_array.is_empty():
		return schema_prop

	# Get and remove the first prop_key in the array
	var prop_key: String = prop_key_array.pop_front()

	# Check if the searched property exists
	if not schema_prop.has(prop_key):
		return {}

	schema_prop = schema_prop[prop_key]

	# If the schema_prop has a 'type' key, is of type 'object', and there are more property keys remaining
	if schema_prop.has("type") and schema_prop.type == "object" and not prop_key_array.is_empty():
		# Set the properties of the object as the current 'schema_prop'
		schema_prop = schema_prop.properties

	schema_prop = _traverse_schema(schema_prop, prop_key_array)

	return schema_prop


## Retrieves an Array of mods that have configuration files.[br]
## [br]
## [b]Returns:[/b][br]
## - [Array]: An Array containing the mod data of mods that have configuration files.
static func get_mods_with_config() -> Array:
	# Create an empty array to store mods with configuration files
	var mods_with_config := []

	# Iterate over each mod in ModLoaderStore.mod_data
	for mod_id in ModLoaderStore.mod_data:
		# Retrieve the mod data for the current mod ID
		# *The ModData type cannot be used because ModData is not fully loaded when this code is executed.*
		var mod_data = ModLoaderStore.mod_data[mod_id]

		# Check if the mod has any configuration files
		if not mod_data.configs.is_empty():
			mods_with_config.push_back(mod_data)

	# Return the array of mods with configuration files
	return mods_with_config


## Retrieves the configurations dictionary for a given mod ID.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id]: The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - [Dictionary]: A dictionary containing the configurations for the specified mod.
## If the mod ID is invalid or no configurations are found, an empty dictionary is returned.
static func get_configs(mod_id: String) -> Dictionary:
	# Check if the mod ID is invalid
	if not ModLoaderStore.mod_data.has(mod_id):
		ModLoaderLog.fatal("Mod ID \"%s\" not found" % [mod_id], LOG_NAME)
		return {}

	var config_dictionary: Dictionary = ModLoaderStore.mod_data[mod_id].configs

	# Check if there is no config file for the mod
	if config_dictionary.is_empty():
		ModLoaderLog.debug("No config for mod id \"%s\"" % mod_id, LOG_NAME, true)
		return {}

	return config_dictionary


## Retrieves the configuration for a specific mod and configuration name.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## - [param config_name] ([String]): The name of the configuration.[br]
## [br]
## [b]Returns:[/b][br]
## - [ModConfig]: The configuration as a [ModConfig] object or null if not found.
static func get_config(mod_id: String, config_name: String) -> ModConfig:
	var configs := get_configs(mod_id)

	if not configs.has(config_name):
		ModLoaderLog.error("No config with name \"%s\" found for mod_id \"%s\" " % [config_name, mod_id], LOG_NAME)
		return null

	return configs[config_name]


## Checks whether a mod has a current configuration set.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - [bool]: True if the mod has a current configuration, false otherwise.
static func has_current_config(mod_id: String) -> bool:
	var mod_data := ModLoaderMod.get_mod_data(mod_id)
	return not mod_data.current_config == null


## Checks whether a mod has a configuration with the specified name.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## - [param config_name] ([String]): The name of the configuration.[br]
## [br]
## [b]Returns:[/b][br]
## - [bool]: True if the mod has a configuration with the specified name, False otherwise.
static func has_config(mod_id: String, config_name: String) -> bool:
	var mod_data := ModLoaderMod.get_mod_data(mod_id)
	return mod_data.configs.has(config_name)


## Retrieves the default configuration for a specified mod ID.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - [ModConfig]: The [ModConfig] object representing the default configuration for the specified mod.
## If the mod ID is invalid or no configuration is found, returns null.
static func get_default_config(mod_id: String) -> ModConfig:
	return get_config(mod_id, DEFAULT_CONFIG_NAME)


## Retrieves the currently active configuration for a specific mod.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - [ModConfig]: The configuration as a [ModConfig] object or [code]null[/code] if not found.
static func get_current_config(mod_id: String) -> ModConfig:
	var current_config_name := get_current_config_name(mod_id)
	var current_config: ModConfig

	# Load the default configuration if there is no configuration set as current yet
	# Otherwise load the corresponding configuration
	if current_config_name.is_empty():
		current_config = get_default_config(mod_id)
	else:
		current_config = get_config(mod_id, current_config_name)

	return current_config


## Retrieves the name of the current configuration for a specific mod.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - [String] The currently active configuration name for the given mod id or an empty string if not found.
static func get_current_config_name(mod_id: String) -> String:
	# Check if user profile has been loaded
	if not ModLoaderStore.current_user_profile or not ModLoaderStore.user_profiles.has(ModLoaderStore.current_user_profile.name):
		# Warn and return an empty string if the user profile has not been loaded
		ModLoaderLog.warning("Can't get current mod config name for \"%s\", because no current user profile is present." % mod_id, LOG_NAME)
		return ""

	# Retrieve the current user profile from ModLoaderStore
	# *Can't use ModLoaderUserProfile because it causes a cyclic dependency*
	var current_user_profile = ModLoaderStore.current_user_profile

	# Check if the mod exists in the user profile's mod list and if it has a current config
	if not current_user_profile.mod_list.has(mod_id) or not current_user_profile.mod_list[mod_id].has("current_config"):
		# Log an error and return an empty string if the mod has no config file
		ModLoaderLog.error("Can't get current mod config name for \"%s\" because no config file exists." % mod_id, LOG_NAME)
		return ""

	# Return the name of the current configuration for the mod
	return current_user_profile.mod_list[mod_id].current_config


## Refreshes the data of the provided configuration by reloading it from the config file.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param config] ([ModConfig]): The [ModConfig] object whose data needs to be refreshed.[br]
## [br]
## [b]Returns:[/b][br]
## - [ModConfig]: The [ModConfig] object with refreshed data if successful, or the original object otherwise.
static func refresh_config_data(config: ModConfig) -> ModConfig:
	# Retrieve updated configuration data from the config file
	var new_config_data := _ModLoaderFile.get_json_as_dict(config.save_path)
	# Update the data property of the ModConfig object with the refreshed data
	config.data = new_config_data

	return config


## Iterates over all mods to refresh the data of their current configurations, if available.[br]
## [br]
## [b]Returns:[/b][br]
## - No return value[br]
## [br]
## Compares the previous configuration data with the refreshed data and emits the [signal ModLoader.current_config_changed]
## signal if changes are detected.[br]
## This function ensures that any changes made to the configuration files outside the application
## are reflected within the application's runtime, allowing for dynamic updates without the need for a restart.
static func refresh_current_configs() -> void:
	for mod_id in ModLoaderMod.get_mod_data_all().keys():
		# Skip if the mod has no config
		if not has_current_config(mod_id):
			return

		# Retrieve the current configuration for the mod
		var config := get_current_config(mod_id)
		# Create a deep copy of the current configuration data for comparison
		var config_data_previous := config.data.duplicate(true)
		# Refresh the configuration data
		var config_new := refresh_config_data(config)

		# Compare previous data with refreshed data
		if not config_data_previous == config_new.data:
			# Emit signal indicating that the current configuration has changed
			ModLoader.current_config_changed.emit(config)
