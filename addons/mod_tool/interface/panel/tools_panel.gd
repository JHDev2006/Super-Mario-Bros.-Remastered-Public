@tool
class_name ModToolsPanel
extends Control


# passed from the EditorPlugin
var mod_tool_store: ModToolStore
var editor_plugin: EditorPlugin: set = set_editor_plugin
var context_actions: FileSystemContextActions

var tab_parent_bottom_panel: PanelContainer
var log_richtext_label: RichTextLabel
var log_dock_button: Button

@onready var mod_tool_store_node: ModToolStore = get_node_or_null("/root/ModToolStore")
@onready var tab_container := $"%TabContainer"
@onready var create_mod := $"%CreateMod"
@onready var select_mod := $"%SelectMod"
@onready var label_output := $"%Output"
@onready var mod_id := $"%ModId"
@onready var manifest_editor := $"%Manifest Editor"
@onready var export_path := $"%ExportPath"
@onready var file_dialog := $"%FileDialog"
@onready var hook_gen: ModToolInterfaceHookGen = %HookGen
@onready var hook_restore: ModToolInterfaceHookRestore = %HookRestore
@onready var button_add_hooks: Button = %AddHooks
@onready var button_restore: Button = %Restore


func _ready() -> void:
	tab_parent_bottom_panel = get_parent().get_parent() as PanelContainer

	get_log_nodes()

	if mod_tool_store:
		if mod_tool_store.is_hook_generation_done:
			button_add_hooks.hide()
		else:
			button_restore.hide()
		# Load manifest.json file
		if _ModLoaderFile.file_exists(mod_tool_store.path_manifest):
			manifest_editor.load_manifest()
			manifest_editor.update_ui()
		else:
			# Load template Manifest
			var template_manifest_data := _ModLoaderFile.get_json_as_dict("res://addons/mod_tool/templates/minimal/manifest.json")
			mod_tool_store.manifest_data = ModManifest.new(template_manifest_data, "")

	_update_ui()


func set_editor_plugin(plugin: EditorPlugin) -> void:
	editor_plugin = plugin

	mod_tool_store.editor_plugin = editor_plugin
	mod_tool_store.editor_file_system = EditorInterface.get_resource_filesystem()
	mod_tool_store.editor_base_control = EditorInterface.get_base_control()

	context_actions = FileSystemContextActions.new(
		mod_tool_store,
		EditorInterface.get_file_system_dock()
	)


func get_log_nodes() -> void:
	var editor_log := get_parent().get_child(0)
	log_richtext_label = editor_log.get_child(1) as RichTextLabel
	if not log_richtext_label:
		# on project load it can happen that these nodes don't exist yet, wait for parent
		await get_parent().ready
		log_richtext_label = editor_log.get_child(1) as RichTextLabel

	# The button hbox should be last, but here it is second from last for some reason
	var dock_tool_button_bar: HBoxContainer = get_parent().get_child(get_parent().get_child_count() -2)
	log_dock_button = dock_tool_button_bar.get_child(0).get_child(0)


# Removes the last error line from the output console as if nothing happened
# used in the json validation since the error is displayed right there and
# it causes a lot of clutter otherwise
func discard_last_console_error() -> void:
	# If the console is flooded anyway, ignore
	var line_count := log_richtext_label.get_line_count()
	if line_count > 1000:
		return

	# The last line is an empty line, remove the one before that
	log_richtext_label.remove_line(line_count -2)
	log_richtext_label.add_text("\n")

	# If there is an error in the console already, leave the circle on the tool button
	# All error lines have a space in the beginnig to separate from the circle image
	# Not the safest way to check, but it's the only one it seems
	for line in log_richtext_label.text.split("\n"):
		if (line as String).begins_with(" "):
			return

	# If there were no other error lines, remove the icon
	# Setting to null will crash the editor occasionally, this does not
	if log_dock_button:
		log_dock_button.icon = CompressedTexture2D.new()


func show_manifest_editor() -> void:
	tab_container.current_tab = 0


func show_config_editor() -> void:
	tab_container.current_tab = 1


func _update_ui() -> void:
	if not mod_tool_store:
		return
	mod_id.input_text = mod_tool_store.name_mod_dir
	export_path.input_text = mod_tool_store.path_export_dir


func _is_mod_dir_valid() -> bool:
	# Check if Mod ID is given
	if mod_tool_store.name_mod_dir == '':
		ModToolUtils.output_error("Please provide a Mod ID")
		return false

	# Check if mod dir exists
	if not _ModLoaderFile.dir_exists(mod_tool_store.path_mod_dir):
		ModToolUtils.output_error("Mod folder %s does not exist" % mod_tool_store.path_mod_dir)
		return false

	return true


func load_mod(name_mod_dir: String) -> void:
	# Set the dir name
	mod_tool_store.name_mod_dir = name_mod_dir

	# Load Manifest
	manifest_editor.load_manifest()
	manifest_editor.update_ui()

	# TODO: Load Mod Config if existing

	ModToolUtils.output_info("Mod \"%s\" loaded." % name_mod_dir)


func _on_export_pressed() -> void:
	if _is_mod_dir_valid():
		var zipper := ModToolZipBuilder.new()
		zipper.build_zip(mod_tool_store)


func _on_clear_output_pressed() -> void:
	label_output.clear()


func _on_copy_output_pressed() -> void:
	DisplayServer.clipboard_set(label_output.text)


func _on_save_manifest_pressed() -> void:
	manifest_editor.save_manifest()


func _on_export_settings_create_new_mod_pressed() -> void:
	create_mod.popup_centered()
	create_mod.clear_mod_id_input()


func _on_CreateMod_mod_dir_created() -> void:
	create_mod.hide()
	_update_ui()
	manifest_editor.load_manifest()
	manifest_editor.update_ui()


func _on_ConnectMod_pressed() -> void:
	# Opens a popup that displays the mod directory names in the mods-unpacked directory
	select_mod.generate_dir_buttons(ModLoaderMod.get_unpacked_dir())
	select_mod.popup_centered()


func _on_SelectMod_dir_selected(dir_path: String) -> void:
	var mod_dir_name := dir_path.split("/")[-1]
	load_mod(mod_dir_name)
	select_mod.hide()
	_update_ui()


func _on_ButtonExportPath_pressed() -> void:
	file_dialog.current_path = mod_tool_store.path_export_dir
	file_dialog.popup_centered()


func _on_FileDialog_dir_selected(dir: String) -> void:
	mod_tool_store.path_export_dir = dir
	export_path.input_text = dir
	file_dialog.hide()


func _on_add_hooks_pressed() -> void:
	hook_gen.show()


func _on_restore_pressed() -> void:
	hook_restore.show()


func _on_hook_gen_hooks_exist_pressed() -> void:
	button_add_hooks.hide()
	button_restore.show()
