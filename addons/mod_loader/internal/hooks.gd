@tool
class_name _ModLoaderHooks
extends Object

# This Class provides utility functions for working with Mod Hooks.
# Currently all of the included functions are internal and should only be used by the mod loader itself.
# Functions with external use are exposed through the ModLoaderMod class.

const LOG_NAME := "ModLoader:Hooks"

static var any_mod_hooked := false


## Internal ModLoader method. [br]
## To add hooks from a mod use [method ModLoaderMod.add_hook].
static func add_hook(mod_callable: Callable, script_path: String, method_name: String) -> void:
	any_mod_hooked = true
	var hash := get_hook_hash(script_path, method_name)
	if not ModLoaderStore.modding_hooks.has(hash):
		ModLoaderStore.modding_hooks[hash] = []
	ModLoaderStore.modding_hooks[hash].push_back(mod_callable)
	ModLoaderLog.debug('Added hook "%s" to method: "%s" in script: "%s"'
		% [mod_callable.get_method(), method_name, script_path], LOG_NAME
	)

	if not ModLoaderStore.hooked_script_paths.has(script_path):
		ModLoaderStore.hooked_script_paths[script_path] = [method_name]
	elif not ModLoaderStore.hooked_script_paths[script_path].has(method_name):
		ModLoaderStore.hooked_script_paths[script_path].append(method_name)


static func call_hooks(vanilla_method: Callable, args: Array, hook_hash: int) -> Variant:
	var hooks: Array = ModLoaderStore.modding_hooks.get(hook_hash, [])
	if hooks.is_empty():
		return vanilla_method.callv(args)

	var chain := ModLoaderHookChain.new(vanilla_method.get_object(), [vanilla_method] + hooks)
	return chain.execute_next(args)


static func call_hooks_async(vanilla_method: Callable, args: Array, hook_hash: int) -> Variant:
	var hooks: Array = ModLoaderStore.modding_hooks.get(hook_hash, [])
	if hooks.is_empty():
		return await vanilla_method.callv(args)

	var chain := ModLoaderHookChain.new(vanilla_method.get_object(), [vanilla_method] + hooks)
	return await chain.execute_next_async(args)


static func get_hook_hash(path: String, method: String) -> int:
	return hash(path + method)


static func on_new_hooks_created() -> void:
	if ModLoaderStore.ml_options.disable_restart:
		ModLoaderLog.debug("Mod Loader handled restart is disabled.", LOG_NAME)
		return
	ModLoaderLog.debug("Instancing restart notification scene from path: %s" % [ModLoaderStore.ml_options.restart_notification_scene_path], LOG_NAME)
	var restart_notification_scene = load(ModLoaderStore.ml_options.restart_notification_scene_path).instantiate()
	ModLoader.add_child(restart_notification_scene)
