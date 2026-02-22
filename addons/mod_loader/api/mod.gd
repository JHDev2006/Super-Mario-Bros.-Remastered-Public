class_name ModLoaderMod
extends Object
##
## This Class provides helper functions to build mods.
##
## @tutorial(Script Extensions):	https://wiki.godotmodding.com/#/guides/modding/script_extensions
## @tutorial(Script Hooks):			https://wiki.godotmodding.com/#/guides/modding/script_hooks
## @tutorial(Mod Structure):		https://wiki.godotmodding.com/#/guides/modding/mod_structure
## @tutorial(Mod Files):			https://wiki.godotmodding.com/#/guides/modding/mod_files


const LOG_NAME := "ModLoader:Mod"


## Installs a script extension that extends a vanilla script.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param child_script_path] ([String]): The path to the mod's extender script.[br]
## [br]
## [b]Returns:[/b][br]
## - No return value[br]
## [br]
## This is the preferred way of modifying a vanilla [Script][br]
## Since Godot 4, extensions can cause issues with scripts that use [code]class_name[/code]
## and should be avoided if present.[br]
## See [method add_hook] for those cases.[br]
## [br]
## The [param child_script_path] should point to your mod's extender script.[br]
## Example: [code]"MOD/extensions/singletons/utils.gd"[/code][br]
## Inside the extender script, include [code]extends {target}[/code] where [code]{target}[/code] is the vanilla path.[br]
## Example: [code]extends "res://singletons/utils.gd"[/code].[br]
## ===[br]
## [b]Note:[/b][br]
## Your extender script doesn't have to follow the same directory path as the vanilla file,
## but it's good practice to do so.[br]
## ===[br]
## [br]
static func install_script_extension(child_script_path: String) -> void:
	var mod_id: String = _ModLoaderPath.get_mod_dir(child_script_path)
	var mod_data: ModData = get_mod_data(mod_id)
	if not ModLoaderStore.saved_extension_paths.has(mod_data.manifest.get_mod_id()):
		ModLoaderStore.saved_extension_paths[mod_data.manifest.get_mod_id()] = []
	ModLoaderStore.saved_extension_paths[mod_data.manifest.get_mod_id()].append(child_script_path)

	# If this is called during initialization, add it with the other
	# extensions to be installed taking inheritance chain into account
	if ModLoaderStore.is_initializing:
		ModLoaderStore.script_extensions.push_back(child_script_path)

	# If not, apply the extension directly
	else:
		_ModLoaderScriptExtension.apply_extension(child_script_path)


## Adds all methods from a file as hooks. [br]
## [br]
## [b]Parameters:[/b][br]
## - [param vanilla_script_path] ([String]): The path to the script which will be hooked.[br]
## - [param hook_script_path] ([String]): The path to the script containing hooks.[br]
## [br]
## [b]Returns:[/b][br]
## - No return value[br]
## [br]
## The file needs to extend [Object].[br]
## The methods in the file need to have the exact same name as the vanilla method
## they intend to hook, all mismatches will be ignored. [br]
## See: [method add_hook]
## [br]
## [b]Examples:[/b][br]
## [codeblock]
## ModLoaderMod.install_script_hooks(
##     "res://tools/utilities.gd",
##     extensions_dir_path.path_join("tools/utilities-hook.gd")
## )
## [/codeblock]
static func install_script_hooks(vanilla_script_path: String, hook_script_path: String) -> void:
	var hook_script := load(hook_script_path) as GDScript
	var hook_script_instance := hook_script.new()

	# Every script that inherits RefCounted will be cleaned up by the engine as
	# soon as there are no more references to it. If the reference is gone
	# the method can't be called and everything returns null.
	# Only Object won't be removed, so we can use it here.
	if hook_script_instance is RefCounted:
		ModLoaderLog.fatal(
			"Scripts holding mod hooks should always extend Object (%s)"
			% hook_script_path, LOG_NAME
		)

	var vanilla_script := load(vanilla_script_path) as GDScript
	var vanilla_methods := vanilla_script.get_script_method_list().map(
		func(method: Dictionary) -> String:
			return method.name
	)

	var methods := hook_script.get_script_method_list()
	for hook in methods:
		if hook.name in vanilla_methods:
			ModLoaderMod.add_hook(Callable(hook_script_instance, hook.name), vanilla_script_path, hook.name)
			continue

		ModLoaderLog.debug(
			'Skipped adding hook "%s" (not found in vanilla script %s)'
			% [hook.name, vanilla_script_path], LOG_NAME
		)

		if not OS.has_feature("editor"):
			continue

		vanilla_methods.sort_custom((
			func(a_name: String, b_name: String, target_name: String) -> bool:
				return a_name.similarity(target_name) > b_name.similarity(target_name)
		).bind(hook.name))

		var closest_vanilla: String = vanilla_methods.front()
		if closest_vanilla.similarity(hook.name) > 0.8:
			ModLoaderLog.hint(
				'Did you mean "%s" instead of "%s"?'
				% [closest_vanilla, hook.name], LOG_NAME
			)


## Adds a hook, a custom mod function, to a vanilla method.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_callable] ([Callable]): The function that will executed when
##   the vanilla method is executed. When writing a mod callable, make sure
##   that it [i]always[/i] receives a [ModLoaderHookChain] object as first argument,
##   which is used to continue down the hook chain (see: [method ModLoaderHookChain.execute_next])
##   and allows manipulating parameters before and return values after the
##   vanilla method is called. [br]
## - [param script_path] ([String]): Path to the vanilla script that holds the method.[br]
## - [param method_name] ([String]): The method the hook will be applied to.[br]
## [br]
## [b]Returns:[/b][br][br]
## - No return value[br]
## [br]
## Opposed to script extensions, hooks can be applied to scripts that use
## [code]class_name[/code] without issues.[br]
## If possible, prefer [method install_script_extension].[br]
## [br]
## [b]Examples:[/b][br]
## [br]
## Given the following vanilla script [code]main.gd[/code]
## [codeblock]
## class_name MainGame
## extends Node2D
##
## var version := "vanilla 1.0.0"
##
##
## func _ready():
##     $CanvasLayer/Control/Label.text = "Version: %s" % version
##     print(Utilities.format_date(15, 11, 2024))
## [/codeblock]
##
## It can be hooked in [code]mod_main.gd[/code] like this
## [codeblock]
## func _init() -> void:
##     ModLoaderMod.add_hook(change_version, "res://main.gd", "_ready")
##     ModLoaderMod.add_hook(time_travel, "res://tools/utilities.gd", "format_date")
##     # Multiple hooks can be added to a single method.
##     ModLoaderMod.add_hook(add_season, "res://tools/utilities.gd", "format_date")
##
##
## # The script we are hooking is attached to a node, which we can get from reference_object
## # then we can change any variables it has
## func change_version(chain: ModLoaderHookChain) -> void:
##     # Using a typecast here (with "as") can help with autocomplete and avoiding errors
##     var main_node := chain.reference_object as MainGame
##     main_node.version = "Modloader Hooked!"
##     # _ready, which we are hooking, does not have any arguments
##     chain.execute_next()
##
##
## # Parameters can be manipulated easily by changing what is passed into .execute_next()
## # The vanilla method (Utilities.format_date) takes 3 arguments, our hook method takes
## # the ModLoaderHookChain followed by the same 3
## func time_travel(chain: ModLoaderHookChain, day: int, month: int, year: int) -> String:
##     print("time travel!")
##     year -= 100
##     # Just the vanilla arguments are passed along in the same order, wrapped into an Array
##     var val = chain.execute_next([day, month, year])
##     return val
##
##
## # The return value can be manipulated by calling the next hook (or vanilla) first
## # then changing it and returning the new value.
## func add_season(chain: ModLoaderHookChain, day: int, month: int, year: int) -> String:
##     var output = chain.execute_next([day, month, year])
##     match month:
##         12, 1, 2:
##             output += ", Winter"
##         3, 4, 5:
##             output += ", Spring"
##         6, 7, 8:
##             output += ", Summer"
##         9, 10, 11:
##             output += ", Autumn"
##     return output
## [/codeblock]
##
static func add_hook(mod_callable: Callable, script_path: String, method_name: String) -> void:
	_ModLoaderHooks.add_hook(mod_callable, script_path, method_name)


## Registers an array of classes to the global scope since Godot only does that in the editor.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param new_global_classes] ([Array]): An array of class definitions to be registered.[br]
## [br]
## [b]Returns:[/b][br]
## - No return value[br]
## [br]
## Format: [code]{ "base": "ParentClass", "class": "ClassName", "language": "GDScript", "path": "res://path/class_name.gd" }[/code][br]
## [br]
## ===[br]
## [b]Tip:[/b][color=tip][/color][br]
## You can find these easily in the project.godot file under `_global_script_classes`[br]
## (but you should only include classes belonging to your mod)[br]
## ===[br]
static func register_global_classes_from_array(new_global_classes: Array) -> void:
	ModLoaderUtils.register_global_classes_from_array(new_global_classes)
	var _savecustom_error: int = ProjectSettings.save_custom(_ModLoaderPath.get_override_path())


## Adds a translation file.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param resource_path] ([String]): The path to the translation resource file.[br]
## [b]Returns:[/b][br]
## - No return value[br]
## [br]
## ===[br]
## [b]Note:[/b][br]
## The [code].translation[/code] file should have been created by the Godot editor already, usually when importing a CSV file.
## The translation file should named [code]name.langcode.translation[/code] -> [code]mytranslation.en.translation[/code].[br]
## ===[br]
static func add_translation(resource_path: String) -> void:
	if not _ModLoaderFile.file_exists(resource_path):
		ModLoaderLog.fatal("Tried to load a position resource from a file that doesn't exist. The invalid path was: %s" % [resource_path], LOG_NAME)
		return

	var translation_object: Translation = load(resource_path)
	if translation_object:
		TranslationServer.add_translation(translation_object)
		ModLoaderLog.info("Added Translation from Resource -> %s" % resource_path, LOG_NAME)
	else:
		ModLoaderLog.fatal("Failed to load translation at path: %s" % [resource_path], LOG_NAME)



## Marks the given scene for to be refreshed. It will be refreshed at the correct point in time later.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param scene_path] ([String]): The path to the scene file to be refreshed.
## [br]
## [b]Returns:[/b][br]
## - No return value[br]
## [br]
## ===[br]
## [b]Note:[/b][color=abstract "Version"][/color][br]
## This function requires Godot 4.3 or higher.[br]
## ===[br]
## [br]
## This function is useful if a script extension is not automatically applied.
## This situation can occur when a script is attached to a preloaded scene.
## If you encounter issues where your script extension is not working as expected,
## try to identify the scene to which it is attached and use this method to refresh it.
## This will reload already loaded scenes and apply the script extension.
## [br]
static func refresh_scene(scene_path: String) -> void:
	if scene_path in ModLoaderStore.scenes_to_refresh:
		return

	ModLoaderStore.scenes_to_refresh.push_back(scene_path)
	ModLoaderLog.debug("Added \"%s\" to be refreshed." % scene_path, LOG_NAME)


## Extends a specific scene by providing a callable function to modify it.
## [br]
## [b]Parameters:[/b][br]
## - [param scene_vanilla_path] ([String]): The path to the vanilla scene file.[br]
## - [param edit_callable] ([Callable]): The callable function to modify the scene.[br]
## [br]
## [b]Returns:[/b][br]
## - No return value[br]
## [br]
## The callable receives an instance of the "vanilla_scene" as the first parameter.[br]
static func extend_scene(scene_vanilla_path: String, edit_callable: Callable) -> void:
	if not ModLoaderStore.scenes_to_modify.has(scene_vanilla_path):
		ModLoaderStore.scenes_to_modify[scene_vanilla_path] = []

	ModLoaderStore.scenes_to_modify[scene_vanilla_path].push_back(edit_callable)


## Gets the [ModData] from the provided namespace.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - [ModData]: The [ModData] associated with the provided [code]mod_id[/code], or null if the [code]mod_id[/code] is invalid.[br]
static func get_mod_data(mod_id: String) -> ModData:
	if not ModLoaderStore.mod_data.has(mod_id):
		ModLoaderLog.error("%s is an invalid mod_id" % mod_id, LOG_NAME)
		return null

	return ModLoaderStore.mod_data[mod_id]


## Gets the [ModData] of all loaded Mods as [Dictionary].[br]
## [br]
## [b]Returns:[/b][br]
## - [Dictionary]: A dictionary containing the [ModData] of all loaded mods.[br]
static func get_mod_data_all() -> Dictionary:
	return ModLoaderStore.mod_data


## Returns the path to the directory where unpacked mods are stored.[br]
## [br]
## [b]Returns:[/b][br]
## - [String]: The path to the unpacked mods directory.[br]
static func get_unpacked_dir() -> String:
	return _ModLoaderPath.get_unpacked_mods_dir_path()


## Returns true if the mod with the given [code]mod_id[/code] was successfully loaded.[br]
## [br]
## [b]Parameters:[/b][br]
## - [param mod_id] ([String]): The ID of the mod.[br]
## [br]
## [b]Returns:[/b][br]
## - [bool]: true if the mod is loaded, false otherwise.[br]
static func is_mod_loaded(mod_id: String) -> bool:
	if ModLoaderStore.is_initializing:
		ModLoaderLog.warning(
			"The ModLoader is not fully initialized. " +
			"Calling \"is_mod_loaded()\" in \"_init()\" may result in an unexpected return value as mods are still loading.",
			LOG_NAME
		)

	# If the mod is not present in the mod_data dictionary or the mod is flagged as not loadable.
	if not ModLoaderStore.mod_data.has(mod_id) or not ModLoaderStore.mod_data[mod_id].is_loadable:
		return false

	return true


## Returns true if the mod with the given mod_id was successfully loaded and is currently active.
## [br]
## Parameters:
## - [param mod_id] ([String]): The ID of the mod.
## [br]
## Returns:
## - [bool]: true if the mod is loaded and active, false otherwise.
static func is_mod_active(mod_id: String) -> bool:
	return is_mod_loaded(mod_id) and ModLoaderStore.mod_data[mod_id].is_active
