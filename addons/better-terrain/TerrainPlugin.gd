@tool
extends EditorPlugin

const AUTOLOAD_NAME = "BetterTerrain"
var dock : Control
var button : Button

func _enter_tree() -> void:
	# Wait for autoloads to register
	await get_tree().process_frame
	
	if !get_tree().root.get_node_or_null(^"BetterTerrain"):
		# Autoload wasn't present on plugin init, which means plugin won't have loaded correctly
		add_autoload_singleton(AUTOLOAD_NAME, "res://addons/better-terrain/BetterTerrain.gd")
		ProjectSettings.save()
		
		var confirm = ConfirmationDialog.new()
		confirm.dialog_text = "The editor needs to be restarted for Better Terrain to load correctly. Restart now? Note: Unsaved changes will be lost."
		confirm.confirmed.connect(func():
			OS.set_restart_on_exit(true, ["-e"])
			get_tree().quit()
		)
		get_editor_interface().popup_dialog_centered(confirm)
	
	dock = load("res://addons/better-terrain/editor/Dock.tscn").instantiate()
	dock.update_overlay.connect(self.update_overlays)
	get_editor_interface().get_editor_main_screen().mouse_exited.connect(dock.canvas_mouse_exit)
	dock.undo_manager = get_undo_redo()
	button = add_control_to_bottom_panel(dock, "Terrain")
	button.toggled.connect(dock.about_to_be_visible)
	dock.force_show_terrains.connect(button.toggled.emit.bind(true))
	button.visible = false


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.queue_free()


func _handles(object) -> bool:
	return object is TileMapLayer or object is TileSet


func _make_visible(visible) -> void:
	button.visible = visible


func _edit(object) -> void:
	var new_tileset : TileSet = null
	
	if object is TileMapLayer:
		dock.tilemap = object
		new_tileset = object.tile_set
	if object is TileSet:
		dock.tilemap = null
		new_tileset = object
	
	if dock.tileset != new_tileset:
		dock.tiles_about_to_change()
		dock.tileset = new_tileset
		dock.tiles_changed()


func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if dock.is_visible_in_tree():
		dock.canvas_draw(overlay)


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if !dock.is_visible_in_tree():
		return false
	
	return dock.canvas_input(event)
