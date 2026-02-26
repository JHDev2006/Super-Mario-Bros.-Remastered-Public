class_name _ModLoaderScriptExtension
extends RefCounted

# This Class provides methods for working with script extensions.
# Currently all of the included methods are internal and should only be used by the mod loader itself.

const LOG_NAME := "ModLoader:ScriptExtension"


# Sort script extensions by inheritance and apply them in order
static func handle_script_extensions() -> void:
	var extension_paths := []
	for extension_path in ModLoaderStore.script_extensions:
		if FileAccess.file_exists(extension_path):
			extension_paths.push_back(extension_path)
		else:
			ModLoaderLog.error(
				"The child script path '%s' does not exist" % [extension_path], LOG_NAME
			)

	# Sort by inheritance
	InheritanceSorting.new(extension_paths)

	# Load and install all extensions
	for extension in extension_paths:
		var script: Script = apply_extension(extension)
		_reload_vanilla_child_classes_for(script)


# Sorts script paths by their ancestors.  Scripts are organized by their common
# ancestors then sorted such that scripts extending script A will be before
# a script extending script B if A is an ancestor of B.
class InheritanceSorting:
	var stack_cache := {}
	# This dictionary's keys are mod_ids and it stores the corresponding position in the load_order
	var load_order := {}

	func _init(inheritance_array_to_sort: Array) -> void:
		_populate_load_order_table()
		inheritance_array_to_sort.sort_custom(check_inheritances)

	# Comparator function.  return true if a should go before b.  This may
	# enforce conditions beyond the stated inheritance relationship.
	func check_inheritances(extension_a: String, extension_b: String) -> bool:
		var a_stack := cached_inheritances_stack(extension_a)
		var b_stack := cached_inheritances_stack(extension_b)

		var last_index: int
		for index in a_stack.size():
			if index >= b_stack.size():
				return false
			if a_stack[index] != b_stack[index]:
				return a_stack[index] < b_stack[index]
			last_index = index

		if last_index < b_stack.size() - 1:
			return true

		return compare_mods_order(extension_a, extension_b)

	# Returns a list of scripts representing all the ancestors of the extension
	# script with the most recent ancestor last.
	#
	# Results are stored in a cache keyed by extension path
	func cached_inheritances_stack(extension_path: String) -> Array:
		if stack_cache.has(extension_path):
			return stack_cache[extension_path]

		var stack := []

		var parent_script: Script = load(extension_path)
		while parent_script:
			stack.push_front(parent_script.resource_path)
			parent_script = parent_script.get_base_script()
		stack.pop_back()

		stack_cache[extension_path] = stack
		return stack

	# Secondary comparator function for resolving scripts extending the same vanilla script
	# Will return whether a comes before b in the load order
	func compare_mods_order(extension_a: String, extension_b: String) -> bool:
		var mod_a_id: String = _ModLoaderPath.get_mod_dir(extension_a)
		var mod_b_id: String = _ModLoaderPath.get_mod_dir(extension_b)

		return load_order[mod_a_id] < load_order[mod_b_id]

	# Populate a load order dictionary for faster access and comparison between mod ids
	func _populate_load_order_table() -> void:
		var mod_index := 0
		for mod in ModLoaderStore.mod_load_order:
			load_order[mod.dir_name] = mod_index
			mod_index += 1


static func apply_extension(extension_path: String) -> Script:
	# Check path to file exists
	if not FileAccess.file_exists(extension_path):
		ModLoaderLog.error("The child script path '%s' does not exist" % [extension_path], LOG_NAME)
		return null

	var child_script: Script = load(extension_path)
	# Adding metadata that contains the extension script path
	# We cannot get that path in any other way
	# Passing the child_script as is would return the base script path
	# Passing the .duplicate() would return a '' path
	child_script.set_meta("extension_script_path", extension_path)

	# Force Godot to compile the script now.
	# We need to do this here to ensure that the inheritance chain is
	# properly set up, and multiple mods can chain-extend the same
	# class multiple times.
	# This is also needed to make Godot instantiate the extended class
	# when creating singletons.
	child_script.reload()

	var parent_script: Script = child_script.get_base_script()
	var parent_script_path: String = parent_script.resource_path

	# We want to save scripts for resetting later
	# All the scripts are saved in order already
	if not ModLoaderStore.saved_scripts.has(parent_script_path):
		ModLoaderStore.saved_scripts[parent_script_path] = []
		# The first entry in the saved script array that has the path
		# used as a key will be the duplicate of the not modified script
		ModLoaderStore.saved_scripts[parent_script_path].append(parent_script.duplicate())

	ModLoaderStore.saved_scripts[parent_script_path].append(child_script)

	ModLoaderLog.info(
		"Installing script extension: %s <- %s" % [parent_script_path, extension_path], LOG_NAME
	)
	child_script.take_over_path(parent_script_path)

	return child_script


# Reload all children classes of the vanilla class we just extended
# Calling reload() the children of an extended class seems to allow them to be extended
# e.g if B is a child class of A, reloading B after apply an extender of A allows extenders of B to properly extend B, taking A's extender(s) into account
static func _reload_vanilla_child_classes_for(script: Script) -> void:
	if script == null:
		return
	var current_child_classes := []
	var actual_path: String = script.get_base_script().resource_path
	var classes: Array = ProjectSettings.get_global_class_list()

	for _class in classes:
		if _class.path == actual_path:
			current_child_classes.push_back(_class)
			break

	for _class in current_child_classes:
		for child_class in classes:
			if child_class.base == _class.get_class():
				load(child_class.path).reload()
