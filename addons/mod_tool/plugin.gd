@tool
extends EditorPlugin

var mod_tool_store
var tools_panel

func _enter_tree() -> void:
	mod_tool_store = preload("res://addons/mod_tool/global/store.gd").new() as ModToolStore
	mod_tool_store.name = "ModToolStore"
	get_tree().root.call_deferred("add_child", mod_tool_store, true)


	tools_panel = preload("res://addons/mod_tool/interface/panel/tools_panel.tscn").instantiate() as ModToolsPanel
	tools_panel.mod_tool_store = mod_tool_store
	tools_panel.editor_plugin = self
	EditorInterface.get_editor_main_screen().call_deferred("add_child", tools_panel, true)
	_make_visible(false)
	connect_to_script_editor()


func _exit_tree() -> void:
	if mod_tool_store:
		mod_tool_store.queue_free()

	if tools_panel:
		tools_panel.free()


func _make_visible(visible):
	if tools_panel:
		tools_panel.visible = visible


func _has_main_screen():
	return true


func _get_plugin_name():
	return "Mod Tool"


func _get_plugin_icon():
	return EditorInterface.get_base_control().get_theme_icon(&"Tools", &"EditorIcons")


func connect_to_script_editor() -> void:
	EditorInterface.get_script_editor().editor_script_changed.connect(ModToolUtils.reload_script.bind(mod_tool_store))
