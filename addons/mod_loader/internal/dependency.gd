class_name _ModLoaderDependency
extends RefCounted


# This Class provides methods for working with dependencies.
# Currently all of the included methods are internal and should only be used by the mod loader itself.

const LOG_NAME := "ModLoader:Dependency"


# Run dependency checks on a mod, checking any dependencies it lists in its
# mod_manifest (ie. its manifest.json file). If a mod depends on another mod that
# hasn't been loaded, the dependent mod won't be loaded, if it is a required dependency.
#
# Parameters:
# - mod: A ModData object representing the mod being checked.
# - dependency_chain: An array that stores the IDs of the mods that have already
#   been checked to avoid circular dependencies.
# - is_required: A boolean indicating whether the mod is a required or optional
#   dependency. Optional dependencies will not prevent the dependent mod from
#   loading if they are missing.
#
# Returns: A boolean indicating whether a circular dependency was detected.
static func check_dependencies(mod: ModData, is_required := true, dependency_chain := []) -> bool:
	var dependency_type := "required" if is_required else "optional"
	# Get the dependency array based on the is_required flag
	var dependencies := mod.manifest.dependencies if is_required else mod.manifest.optional_dependencies
	# Get the ID of the mod being checked
	var mod_id := mod.dir_name

	ModLoaderLog.debug("Checking dependencies - mod_id: %s %s dependencies: %s" % [mod_id, dependency_type, dependencies], LOG_NAME)

	# Check for circular dependency
	if mod_id in dependency_chain:
		ModLoaderLog.debug("%s dependency check - circular dependency detected for mod with ID %s." % [dependency_type.capitalize(), mod_id], LOG_NAME)
		return true

	# Add mod_id to dependency_chain to avoid circular dependencies
	dependency_chain.append(mod_id)

	# Loop through each dependency listed in the mod's manifest
	for dependency_id in dependencies:
		# Check if dependency is missing
		if not ModLoaderStore.mod_data.has(dependency_id) or not ModLoaderStore.mod_data[dependency_id].is_loadable or not ModLoaderStore.mod_data[dependency_id].is_active:
			# Skip to the next dependency if it's optional
			if not is_required:
				ModLoaderLog.info("Missing optional dependency - mod: -> %s dependency -> %s" % [mod_id, dependency_id], LOG_NAME)
				continue
			_handle_missing_dependency(mod_id, dependency_id)
			# Flag the mod so it's not loaded later
			mod.is_loadable = false
		else:
			var dependency: ModData = ModLoaderStore.mod_data[dependency_id]

			# Increase the importance score of the dependency by 1
			dependency.importance += 1
			ModLoaderLog.debug("%s dependency -> %s importance -> %s" % [dependency_type.capitalize(), dependency_id, dependency.importance], LOG_NAME)

			# Check if the dependency has any dependencies of its own
			if dependency.manifest.dependencies.size() > 0:
				if check_dependencies(dependency, is_required, dependency_chain):
					return true

	# Return false if all dependencies have been resolved
	return false


# Run load before check on a mod, checking any load_before entries it lists in its
# mod_manifest (ie. its manifest.json file). Add the mod to the dependency of the
# mods inside the load_before array.
static func check_load_before(mod: ModData) -> void:
	# Skip if no entries in load_before
	if mod.manifest.load_before.size() == 0:
		return

	ModLoaderLog.debug("Load before - In mod %s detected." % mod.dir_name, LOG_NAME)

	# For each mod id in load_before
	for load_before_id in mod.manifest.load_before:
		# Check if the load_before mod exists
		if not ModLoaderStore.mod_data.has(load_before_id):
			ModLoaderLog.debug("Load before - Skipping %s because it's missing" % load_before_id, LOG_NAME)
			continue

		var load_before_mod_dependencies := ModLoaderStore.mod_data[load_before_id].manifest.dependencies as PackedStringArray

		# Check if it's already a dependency
		if mod.dir_name in load_before_mod_dependencies:
			ModLoaderLog.debug("Load before - Skipping because it's already a dependency for %s" % load_before_id, LOG_NAME)
			continue

		# Add the mod to the dependency array
		load_before_mod_dependencies.append(mod.dir_name)
		ModLoaderStore.mod_data[load_before_id].manifest.dependencies = load_before_mod_dependencies

		ModLoaderLog.debug("Load before - Added %s as dependency for %s" % [mod.dir_name, load_before_id], LOG_NAME)


# Get the load order of mods, using a custom sorter
static func get_load_order(mod_data_array: Array) -> Array:
	# Add loadable mods to the mod load order array
	for mod in mod_data_array:
		mod = mod as ModData
		if mod.is_loadable:
			ModLoaderStore.mod_load_order.append(mod)

	# Sort mods by the importance value
	ModLoaderStore.mod_load_order.sort_custom(Callable(CompareImportance, "_compare_importance"))
	return  ModLoaderStore.mod_load_order


# Handles a missing dependency for a given mod ID. Logs an error message indicating the missing dependency and adds
# the dependency ID to the mod_missing_dependencies dictionary for the specified mod.
static func _handle_missing_dependency(mod_id: String, dependency_id: String) -> void:
	ModLoaderLog.error("Missing dependency - mod: -> %s dependency -> %s" % [mod_id, dependency_id], LOG_NAME)
	# if mod is not present in the missing dependencies array
	if not ModLoaderStore.mod_missing_dependencies.has(mod_id):
		# add it
		ModLoaderStore.mod_missing_dependencies[mod_id] = []

	ModLoaderStore.mod_missing_dependencies[mod_id].append(dependency_id)


# Inner class so the sort function can be called by get_load_order()
class CompareImportance:
	# Custom sorter that orders mods by important
	static func _compare_importance(a: ModData, b: ModData) -> bool:
		if a.importance > b.importance:
			return true # a -> b
		else:
			return false # b -> a
