@tool
extends EditorPlugin


var _export_plugin: EditorExportPlugin


func _enter_tree():
	_export_plugin = preload("res://addons/mod_loader/_export_plugin/export_plugin.gd").new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
