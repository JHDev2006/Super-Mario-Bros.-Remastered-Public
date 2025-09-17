extends Node


# ModLoaderStore
## Singleton (autoload) for storing data. Should be added before ModLoader,
## as an autoload called `ModLoaderStore`


# Constants
# =============================================================================

# Most of these settings should never need to change, aside from the DEBUG_*
# options (which should be `false` when distributing compiled PCKs)

const MODLOADER_VERSION := "7.0.1"

# This is where mod ZIPs are unpacked to
const UNPACKED_DIR := "user://mods-unpacked/"

# Default name for the mod hook pack
const MOD_HOOK_PACK_NAME := "mod-hooks.zip"

# Set to true to require using "--enable-mods" to enable them
const REQUIRE_CMD_LINE := false

const LOG_NAME := "ModLoader:Store"

const URL_MOD_STRUCTURE_DOCS := "https://wiki.godotmodding.com/guides/modding/mod_structure"
const MOD_LOADER_DEV_TOOL_URL := "https://github.com/GodotModding/godot-mod-tool"

# Vars
# =============================================================================


# Stores arrays of hook callables that will be applied to a function,
# associated by a hash of the function name and script path
# Example:
# var modding_hooks := {
# 	1917482423: [Callable, Callable],
#	3108290668: [Callable],
# }
var modding_hooks := {}

# Stores script paths and method names to be processed for hooks
# Example:
# var hooked_script_paths := {
# 	"res://game/game.gd": ["_ready", "do_something"],
# }
var hooked_script_paths := {}

# Order for mods to be loaded in, set by `get_load_order`
var mod_load_order := []

# Stores data for every found/loaded mod
var mod_data := {}

# Any mods that are missing their dependancies are added to this
# Example property: "mod_id": ["dep_mod_id_0", "dep_mod_id_2"]
var mod_missing_dependencies := {}

# Set to false after ModLoader._init()
# Helps to decide whether a script extension should go through the _ModLoaderScriptExtension.handle_script_extensions() process
var is_initializing := true

# Store all extenders paths
var script_extensions := []

# Stores scene paths that need to be reloaded from file.
# Used to apply extension to scripts that are attached to preloaded scenes.
var scenes_to_refresh := []

# Dictionary of callables to modify a specific scene.
# Example property: "scene_path": [Callable, Callable]
var scenes_to_modify := {}

# Things to keep to ensure they are not garbage collected (used by `save_scene`)
var saved_objects := []

# Stores all the taken over scripts for restoration
var saved_scripts := {}

# Stores main scripts for mod disabling
var saved_mod_mains := {}

# Stores script extension paths with the key being the namespace of a mod
var saved_extension_paths := {}

var logged_messages: Dictionary:
	set(val):
		ModLoaderDeprecated.deprecated_changed("ModLoaderStore.logged_messages", "ModLoaderLog.logged_messages", "7.0.1")
		ModLoaderLog.logged_messages = val
	get:
		ModLoaderDeprecated.deprecated_changed("ModLoaderStore.logged_messages", "ModLoaderLog.logged_messages", "7.0.1")
		return ModLoaderLog.logged_messages

# Active user profile
var current_user_profile: ModUserProfile

# List of user profiles loaded from user://mod_user_profiles.json
var user_profiles :=  {}

# ModLoader cache is stored in user://mod_loader_cache.json
var cache := {}

# Various options, which can be changed either via
# Godot's GUI (with the options.tres resource file), or via CLI args.
# Usage: `ModLoaderStore.ml_options.KEY`
# See: res://addons/mod_loader/options/options.tres
# See: res://addons/mod_loader/resources/options_profile.gd
var ml_options: ModLoaderOptionsProfile

var has_feature := {
	"editor" = OS.has_feature("editor")
}

# Methods
# =============================================================================

func _init():
	_update_ml_options_from_options_resource()
	_update_ml_options_from_cli_args()
	_configure_logger()
	# ModLoaderStore is passed as argument so the cache data can be loaded on _init()
	_ModLoaderCache.init_cache(self)


func _exit_tree() -> void:
	# Save the cache to the cache file.
	_ModLoaderCache.save_to_file()


# Update ModLoader's options, via the custom options resource
#
# Parameters:
# - ml_options_path: Path to the options resource. See: res://addons/mod_loader/resources/options_current.gd
func _update_ml_options_from_options_resource(ml_options_path := "res://addons/mod_loader/options/options.tres") -> void:
	# Get user options for ModLoader
	if not _ModLoaderFile.file_exists(ml_options_path) and not ResourceLoader.exists(ml_options_path):
		ModLoaderLog.fatal(str("A critical file is missing: ", ml_options_path), LOG_NAME)

	var options_resource: ModLoaderCurrentOptions = load(ml_options_path)
	if options_resource.current_options == null:
		ModLoaderLog.warning(str(
			"No current options are set. Falling back to defaults. ",
			"Edit your options at %s. " % ml_options_path
		), LOG_NAME)
	else:
		var current_options = options_resource.current_options
		if not current_options is ModLoaderOptionsProfile:
			ModLoaderLog.error(str(
				"Current options is not a valid Resource of type ModLoaderOptionsProfile. ",
				"Please edit your options at %s. " % ml_options_path
			), LOG_NAME)
		# Update from the options in the resource
		ml_options = current_options

	# Get options overrides by feature tags
	# An override is saved as Dictionary[String: ModLoaderOptionsProfile]
	for feature_tag in options_resource.feature_override_options.keys():
		if not feature_tag is String:
			ModLoaderLog.error(str(
				"Options override keys are required to be of type String. Failing key: \"%s.\" " % feature_tag,
				"Please edit your options at %s. " % ml_options_path,
				"Consult the documentation for all available feature tags: ",
				"https://docs.godotengine.org/en/3.5/tutorials/export/feature_tags.html"
			), LOG_NAME)
			continue

		if not OS.has_feature(feature_tag):
			ModLoaderLog.info("Options override feature tag \"%s\". does not apply, skipping." % feature_tag, LOG_NAME)
			continue

		ModLoaderLog.info("Applying options override with feature tag \"%s\"." % feature_tag, LOG_NAME)
		var override_options = options_resource.feature_override_options[feature_tag]
		if not override_options is ModLoaderOptionsProfile:
			ModLoaderLog.error(str(
				"Options override is not a valid Resource of type ModLoaderOptionsProfile. ",
				"Options override key with invalid resource: \"%s\". " % feature_tag,
				"Please edit your options at %s. " % ml_options_path
			), LOG_NAME)
			continue

		# Update from the options in the resource
		ml_options = override_options

	if not ml_options.customize_script_path.is_empty():
		ml_options.customize_script_instance = load(ml_options.customize_script_path).new(ml_options)


# Update ModLoader's options, via CLI args
func _update_ml_options_from_cli_args() -> void:
	# Disable mods
	if _ModLoaderCLI.is_running_with_command_line_arg("--disable-mods"):
		ml_options.enable_mods = false

	# Override paths to mods
	# Set via: --mods-path
	# Example: --mods-path="C://path/mods"
	var cmd_line_mod_path := _ModLoaderCLI.get_cmd_line_arg_value("--mods-path")
	if cmd_line_mod_path:
		ml_options.override_path_to_mods = cmd_line_mod_path
		ModLoaderLog.info("The path mods are loaded from has been changed via the CLI arg `--mods-path`, to: " + cmd_line_mod_path, LOG_NAME)

	# Override paths to configs
	# Set via: --configs-path
	# Example: --configs-path="C://path/configs"
	var cmd_line_configs_path := _ModLoaderCLI.get_cmd_line_arg_value("--configs-path")
	if cmd_line_configs_path:
		ml_options.override_path_to_configs = cmd_line_configs_path
		ModLoaderLog.info("The path configs are loaded from has been changed via the CLI arg `--configs-path`, to: " + cmd_line_configs_path, LOG_NAME)

	# Log level verbosity
	if _ModLoaderCLI.is_running_with_command_line_arg("-vvv") or _ModLoaderCLI.is_running_with_command_line_arg("--log-debug"):
		ml_options.log_level = ModLoaderLog.VERBOSITY_LEVEL.DEBUG
	elif _ModLoaderCLI.is_running_with_command_line_arg("-vv") or _ModLoaderCLI.is_running_with_command_line_arg("--log-info"):
		ml_options.log_level = ModLoaderLog.VERBOSITY_LEVEL.INFO
	elif _ModLoaderCLI.is_running_with_command_line_arg("-v") or _ModLoaderCLI.is_running_with_command_line_arg("--log-warning"):
		ml_options.log_level = ModLoaderLog.VERBOSITY_LEVEL.WARNING

	# Ignored mod_names in log
	var ignore_mod_names := _ModLoaderCLI.get_cmd_line_arg_value("--log-ignore")
	if not ignore_mod_names == "":
		ml_options.ignored_mod_names_in_log = ignore_mod_names.split(",")


# Update static variables from the options
func _configure_logger() -> void:
	ModLoaderLog.verbosity = ml_options.log_level
	ModLoaderLog.ignored_mods = ml_options.ignored_mod_names_in_log
	ModLoaderLog.warning_color = ml_options.warning_color
	ModLoaderLog.success_color = ml_options.success_color
	ModLoaderLog.info_color = ml_options.info_color
	ModLoaderLog.hint_color = ml_options.hint_color
	ModLoaderLog.debug_color = ml_options.debug_color
	ModLoaderLog.debug_bold = ml_options.debug_bold
