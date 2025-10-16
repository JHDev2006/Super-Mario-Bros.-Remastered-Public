@tool
extends EditorPlugin

var export_plugin: EditorExportPlugin = null

func _enter_tree():
	export_plugin = load("res://addons/git_bake_export/git_bake_export_plugin.gd").new()
	add_export_plugin(export_plugin)

func _exit_tree():
	if export_plugin:
		remove_export_plugin(export_plugin)
