class_name ModLoaderOptionsProfile
extends Resource
##
## Class to define and store Mod Loader Options.
##
## @tutorial(Example Customization Script): https://wiki.godotmodding.com/guides/integration/mod_loader_options/#game-version-validation


## Settings for game version validation.
enum VERSION_VALIDATION {
	## Uses the default semantic versioning (semver) validation.
	DEFAULT,

	## Disables validation of the game version specified in [member semantic_version]
	## and the mod's [member ModManifest.compatible_game_version].
	DISABLED,

	## Enables custom game version validation.
	## Use [member customize_script_path] to specify a script that customizes the Mod Loader options.
	## In this script, you must set [member custom_game_version_validation_callable]
	## to a custom validation [Callable].
	## [br]
	## ===[br]
	## [b]Note:[color=note "Easier Mod Loader Updates"][/color][/b][br]
	## Using a custom script allows you to keep your code outside the addons directory,
	## making it easier to update the mod loader without affecting your modifications. [br]
	## ===[br]
	CUSTOM,
}

## Can be used to disable mods for specific plaforms by using feature overrides
@export var enable_mods: bool = true
## List of mod ids that can't be turned on or off
@export var locked_mods: Array[String] = []
## List of mods that will not be loaded
@export var disabled_mods: Array[String] = []
## Disables the requirement for the mod loader autoloads to be first
@export var allow_modloader_autoloads_anywhere: bool = false
## This script is loaded after [member ModLoaderStore.ml_options] has been initialized.
## It is instantiated with [member ModLoaderStore.ml_options] as an argument.
## Use this script to apply settings that cannot be configured through the editor UI.
##
## For an example, see [enum VERSION_VALIDATION] [code]CUSTOM[/code] or
## [code]res://addons/mod_loader/options/example_customize_script.gd[/code].
@export_file var customize_script_path: String

@export_group("Logging")
## Sets the logging verbosity level.
## Refer to [enum ModLoaderLog.VERBOSITY_LEVEL] for more details.
@export var log_level := ModLoaderLog.VERBOSITY_LEVEL.DEBUG
## Stops the mod loader from logging any deprecation related errors.
@export var ignore_deprecated_errors: bool = false
## Ignore messages from these namespaces.[br]
## Accepts * as wildcard. [br]
## [code]ModLoader:Dependency[/code] - ignore the exact name [br]
## [code]ModLoader:*[/code] - ignore all beginning with this name [br]
@export var ignored_mod_names_in_log: Array[String] = []
## Highlighting color for warning type log messages
@export var warning_color := Color("#ffde66")
## Highlighting color for success type log messages
@export var success_color := Color("#5d8c3f")
## Highlighting color for info type log messages
@export var info_color := Color("#70bafa")
## Highlighting color for hint type log messages
@export var hint_color := Color("#b293fa")
## Highlighting color for debug type log messages
@export var debug_color := Color("#d4d4d4")
## Highlight debug log prefixes with bold formatting
@export var debug_bold := true

@export_group("Game Data")
## Steam app id, can be found in the steam page url
@export var steam_id: int = 0:
	get:
		return steam_id

## Semantic game version. [br]
## Replace the getter in options_profile.gd if your game stores the version somewhere else
@export var semantic_version := "0.0.0":
	get:
		return semantic_version

@export_group("Mod Sources")
## Indicates whether to load mods from the Steam Workshop directory, or the overridden workshop path.
@export var load_from_steam_workshop: bool = false
## Indicates whether to load mods from the "mods" folder located at the game's install directory, or the overridden mods path.
@export var load_from_local: bool = true
## Indicates whether to load mods from  [code]"res://mods-unpacked"[/code] in the exported game.[br]
## ===[br]
## [b]Note:[color=note "Load from unpacked in the editor"][/color][/b][br]
## In the editor, mods inside [code]"res://mods-unpacked"[/code] are always loaded. Use [member enable_mods] to disable mod loading completely.[br]
## ===[br]
@export var load_from_unpacked: bool = true
## Path to a folder containing mods [br]
## Mod zips should be directly in this folder
@export_dir var override_path_to_mods = ""
## Use this option to override the default path where configs are stored.
@export_dir var override_path_to_configs = ""
## Path to a folder containing workshop items.[br]
## Mods zips are placed in another folder, usually[br]
## [code]/<workshop id>/mod.zip[/code][br]
## The real workshop path ends with [br]
## [code]/workshop/content[/code] [br]
@export_dir var override_path_to_workshop = ""

@export_group("Mod Hooks")
## Can be used to override the default hook pack path, the hook pack is located inside the game's install directory by default.
## To override the path specify a new absolute path.
@export_global_dir var override_path_to_hook_pack := ""
## Can be used to override the default hook pack name, by default it is [constant ModLoaderStore.MOD_HOOK_PACK_NAME]
@export var override_hook_pack_name := ""
## Can be used to specify your own scene that is displayed if a game restart is required.
## For example if new mod hooks were generated.
@export_dir var restart_notification_scene_path := "res://addons/mod_loader/restart_notification.tscn"
## Can be used to disable the mod loader's restart logic. Use the [signal ModLoader.new_hooks_created] to implement your own restart logic.
@export var disable_restart := false

@export_group("Mod Validation")
## Defines how the game version should be validated.
## This setting controls validation for the game version specified in [member semantic_version]
## and the mod's [member ModManifest.compatible_game_version].
@export var game_version_validation := VERSION_VALIDATION.DEFAULT

## Callable that is executed during [ModManifest] validation
## if [member game_version_validation] is set to [enum VERSION_VALIDATION] [code]CUSTOM[/code].
## See the example under [enum VERSION_VALIDATION] [code]CUSTOM[/code] to learn how to set this up.
var custom_game_version_validation_callable: Callable

## Stores the instance of the script specified in [member customize_script_path].
var customize_script_instance: RefCounted
