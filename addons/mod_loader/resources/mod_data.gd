class_name ModData
extends Resource
##
## Stores and validates all Data required to load a mod successfully
## If some of the data is invalid, [member is_loadable] will be false


const LOG_NAME := "ModLoader:ModData"

const MOD_MAIN := "mod_main.gd"
const MANIFEST := "manifest.json"
const OVERWRITES := "overwrites.gd"

# These 2 files are always required by mods.
# [i]mod_main.gd[/i] = The main init file for the mod
# [i]manifest.json[/i] = Meta data for the mod, including its dependencies
enum RequiredModFiles {
	MOD_MAIN,
	MANIFEST,
}

enum OptionalModFiles {
	OVERWRITES
}

# Specifies the source from which the mod has been loaded:
# UNPACKED = From the mods-unpacked directory ( only when in the editor ).
# LOCAL = From the local mod zip directory, which by default is ../game_dir/mods.
# STEAM_WORKSHOP = Loaded from ../Steam/steamapps/workshop/content/1234567/[..].
enum Sources {
	UNPACKED,
	LOCAL,
	STEAM_WORKSHOP,
}

## Name of the Mod's zip file
var zip_name := ""
## Path to the Mod's zip file
var zip_path := ""

## Directory of the mod. Has to be identical to [method ModManifest.get_mod_id]
var dir_name := ""
## Path to the mod's unpacked directory
var dir_path := ""
## False if any data is invalid
var is_loadable := true
## True if overwrites.gd exists
var is_overwrite := false
## True if mod can't be disabled or enabled in a user profile
var is_locked := false
## Flag indicating whether the mod should be loaded
var is_active := true
## Is increased for every mod depending on this mod. Highest importance is loaded first
var importance := 0
## Contents of the manifest
var manifest: ModManifest
# Updated in load_configs
## All mod configs
var configs := {}
## The currently applied mod config
var current_config: ModConfig: set = _set_current_config
## Specifies the source from which the mod has been loaded
var source: int

var load_errors: Array[String] = []
var load_warnings: Array[String] = []



func _init(_manifest: ModManifest, path: String) -> void:
	manifest = _manifest

	if _ModLoaderPath.is_zip(path):
		zip_name = _ModLoaderPath.get_file_name_from_path(path)
		zip_path = path
		# Use the dir name of the passed path instead of the manifest data so we can validate
		# the mod dir has the same name as the mod id in the manifest
		dir_name = _ModLoaderFile.get_mod_dir_name_in_zip(zip_path)
	else:
		dir_name = path.split("/")[-1]

	dir_path = _ModLoaderPath.get_unpacked_mods_dir_path().path_join(dir_name)
	source = get_mod_source()

	_has_required_files()
	# We want to avoid checking if mod_dir_name == mod_id when manifest parsing has failed
	# to prevent confusing error messages.
	if not manifest.has_parsing_failed:
		_is_mod_dir_name_same_as_id(manifest)

	is_overwrite = _is_overwrite()
	is_locked = manifest.get_mod_id() in ModLoaderStore.ml_options.locked_mods

	if not load_errors.is_empty() or not manifest.validation_messages_error.is_empty():
		is_loadable = false


# Load each mod config json from the mods config directory.
func load_configs() -> void:
	# If the default values in the config schema are invalid don't load configs
	if not manifest.load_mod_config_defaults():
		return

	var config_dir_path := _ModLoaderPath.get_path_to_mod_configs_dir(dir_name)
	var config_file_paths := _ModLoaderPath.get_file_paths_in_dir(config_dir_path)
	for config_file_path in config_file_paths:
		_load_config(config_file_path)

	# Set the current_config based on the user profile
	if ModLoaderUserProfile.is_initialized() and ModLoaderConfig.has_current_config(dir_name):
		current_config = ModLoaderConfig.get_current_config(dir_name)
	else:
		current_config = ModLoaderConfig.get_config(dir_name, ModLoaderConfig.DEFAULT_CONFIG_NAME)


# Create a new ModConfig instance for each Config JSON and add it to the configs dictionary.
func _load_config(config_file_path: String) -> void:
	var config_data := _ModLoaderFile.get_json_as_dict(config_file_path)
	var mod_config = ModConfig.new(
		dir_name,
		config_data,
		config_file_path,
		manifest.config_schema
	)

	# Add the config to the configs dictionary
	configs[mod_config.name] = mod_config


# Update the mod_list of the current user profile
func _set_current_config(new_current_config: ModConfig) -> void:
	ModLoaderUserProfile.set_mod_current_config(dir_name, new_current_config)
	current_config = new_current_config
	# We can't emit the signal if the ModLoader is not initialized yet
	if ModLoader:
		ModLoader.current_config_changed.emit(new_current_config)


func set_mod_state(should_activate: bool, force := false) -> bool:
	if is_locked and should_activate != is_active:
		ModLoaderLog.error(
			"Unable to toggle mod \"%s\" since it is marked as locked. Locked mods: %s"
			% [manifest.get_mod_id(), ModLoaderStore.ml_options.locked_mods], LOG_NAME)
		return false

	if should_activate and not is_loadable:
		ModLoaderLog.error(
			"Unable to activate mod \"%s\" since it has the following load errors: %s"
			% [manifest.get_mod_id(), ", ".join(load_errors)], LOG_NAME)
		return false

	if should_activate and manifest.validation_messages_warning.size() > 0:
		if not force:
			ModLoaderLog.warning(
				"Rejecting to activate mod \"%s\" since it has the following load warnings: %s"
				% [manifest.get_mod_id(), ", ".join(load_warnings)], LOG_NAME)
			return false
		ModLoaderLog.info(
			"Forced to activate mod \"%s\" despite the following load warnings: %s"
			% [manifest.get_mod_id(), ", ".join(load_warnings)], LOG_NAME)

	is_active = should_activate
	return true


# Validates if [member dir_name] matches [method ModManifest.get_mod_id]
func _is_mod_dir_name_same_as_id(mod_manifest: ModManifest) -> bool:
	var manifest_id := mod_manifest.get_mod_id()
	if not dir_name == manifest_id:
		load_errors.push_back('Mod directory name "%s" does not match the data in manifest.json. Expected "%s" (Format: {namespace}-{name})' % [ dir_name, manifest_id ])
		return false
	return true


func _is_overwrite() -> bool:
	return _ModLoaderFile.file_exists(get_optional_mod_file_path(OptionalModFiles.OVERWRITES), zip_path)


# Confirms that all files from [member required_mod_files] exist
func _has_required_files() -> bool:
	var has_required_files := true

	for required_file in RequiredModFiles:
		var required_file_path := get_required_mod_file_path(RequiredModFiles[required_file])

		if not _ModLoaderFile.file_exists(required_file_path, zip_path):
			load_errors.push_back(
				"ERROR - %s is missing a required file: %s. For more information, please visit \"%s\"." %
				[dir_name, required_file_path, ModLoaderStore.URL_MOD_STRUCTURE_DOCS]
			)
			has_required_files = false

	return has_required_files


# Converts enum indices [member RequiredModFiles] into their respective file paths
# All required mod files should be in the root of the mod directory
func get_required_mod_file_path(required_file: RequiredModFiles) -> String:
	match required_file:
		RequiredModFiles.MOD_MAIN:
			return dir_path.path_join(MOD_MAIN)
		RequiredModFiles.MANIFEST:
			return dir_path.path_join(MANIFEST)
	return ""


func get_optional_mod_file_path(optional_file: OptionalModFiles) -> String:
	match optional_file:
		OptionalModFiles.OVERWRITES:
			return dir_path.path_join(OVERWRITES)
	return ""


func get_mod_source() -> Sources:
	if zip_path.contains("workshop"):
		return Sources.STEAM_WORKSHOP
	if zip_path == "":
		return Sources.UNPACKED

	return Sources.LOCAL
