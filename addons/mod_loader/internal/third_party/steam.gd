class_name _ModLoaderSteam
extends Node

const LOG_NAME := "ModLoader:ThirdParty:Steam"

# Methods related to Steam and the Steam Workshop


# Get mod zip paths from steam workshop folders.
# folder structure of a workshop item
# <workshop folder>/<steam app id>/<workshop item id>/<mod>.zip
static func find_steam_workshop_zips() -> Array[String]:
	# TODO: use new diraccess methods + filter
	var zip_paths: Array[String] = []
	var workshop_folder_path := _get_path_to_workshop()

	ModLoaderLog.info("Checking workshop items, with path: \"%s\"" % workshop_folder_path, LOG_NAME)

	var workshop_dir := DirAccess.open(workshop_folder_path)
	if workshop_dir == null:
		ModLoaderLog.error("Can't open workshop folder %s (Error: %s)" % [workshop_folder_path, error_string(DirAccess.get_open_error())], LOG_NAME)
		return []
	var workshop_dir_listdir_error := workshop_dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	if not workshop_dir_listdir_error == OK:
		ModLoaderLog.error("Can't read workshop folder %s (Error: %s)" % [workshop_folder_path, error_string(workshop_dir_listdir_error)], LOG_NAME)
		return []

	# Loop 1: Workshop folders
	while true:
		# Get the next workshop item folder
		var item_dir := workshop_dir.get_next()
		if item_dir == '':
			break

		var item_path := workshop_dir.get_current_dir() + "/" + item_dir
		ModLoaderLog.info("Checking workshop item path: \"%s\"" % item_path, LOG_NAME)

		# Only check directories
		if not workshop_dir.current_is_dir():
			continue

		# Loop 2: ZIPs inside the workshop folders
		zip_paths.append_array(_ModLoaderPath.get_zip_paths_in(ProjectSettings.globalize_path(item_path)))

	workshop_dir.list_dir_end()

	return zip_paths


# Get the path to the Steam workshop folder. Only works for Steam games, as it
# traverses directories relative to where a Steam game and its workshop content
# would be installed. Based on code by Blobfish (developer of Brotato).
# For reference, these are the paths of a Steam game and its workshop folder:
#   GAME     = Steam/steamapps/common/GameName
#   WORKSHOP = Steam/steamapps/workshop/content/AppID
# Eg. Brotato:
#   GAME     = Steam/steamapps/common/Brotato
#   WORKSHOP = Steam/steamapps/workshop/content/1942280
static func _get_path_to_workshop() -> String:
	if ModLoaderStore.ml_options.override_path_to_workshop:
		return ModLoaderStore.ml_options.override_path_to_workshop

	var game_install_directory := _ModLoaderPath.get_local_folder_dir()
	var path := ""

	# Traverse up to the steamapps directory (ie. `cd ..\..\` on Windows)
	var path_array := game_install_directory.split("/")
	path_array.resize(path_array.size() - 3)

	# Reconstruct the path, now that it has "common/GameName" removed
	path = "/".join(path_array)

	# Append the game's workshop path
	path = path.path_join("workshop/content/" + _get_steam_app_id())

	return path


# Gets the steam app ID from ml_options or the steam_data.json, which should be in the root
# directory (ie. res://steam_data.json). This file is used by Godot Workshop
# Utility (GWU), which was developed by Brotato developer Blobfish:
# https://github.com/thomasgvd/godot-workshop-utility
static func _get_steam_app_id() -> String:
	# Check if the steam id is stored in the options
	if ModLoaderStore.ml_options.steam_id:
		return str(ModLoaderStore.ml_options.steam_id)
		ModLoaderLog.debug("No Steam ID specified in the Mod Loader options. Attempting to read the steam_data.json file next.", LOG_NAME)

	# If the steam_id is not stored in the options try to get it from the steam_data.json file.
	var game_install_directory := _ModLoaderPath.get_local_folder_dir()
	var steam_app_id := ""
	var file := FileAccess.open(game_install_directory.path_join("steam_data.json"), FileAccess.READ)

	if not file == null:
		var test_json_conv = JSON.new()
		test_json_conv.parse(file.get_as_text())
		var file_content: Dictionary = test_json_conv.get_data()
		file.close()

		if not file_content.has("app_id"):
			ModLoaderLog.error("The steam_data file does not contain an app ID. Mod uploading will not work.", LOG_NAME)
			return ""

		steam_app_id = str(file_content.app_id)
	else :
		ModLoaderLog.error("Can't open steam_data file, \"%s\". Please make sure the file exists and is valid." % game_install_directory.path_join("steam_data.json"), LOG_NAME)

	return steam_app_id
