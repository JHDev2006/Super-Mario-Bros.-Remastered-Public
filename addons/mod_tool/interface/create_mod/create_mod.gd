@tool
extends Window


signal mod_dir_created

const DIR_NAME_DEFAULT_TEMPLATE = "default"
const DIR_NAME_MINIMAL_TEMPLATE = "minimal"

@onready var mod_tool_store: ModToolStore = get_node_or_null("/root/ModToolStore")
@onready var mod_namespace: ModToolInterfaceInputString = $"%Namespace"
@onready var mod_name: ModToolInterfaceInputString = $"%ModName"
@onready var mod_id: ModToolInterfaceInputString = $"%ModId"
@onready var mod_template: ModToolInterfaceInputOptions = $"%ModTemplate"


func _ready() -> void:
	mod_namespace.show_error_if_not(false)
	mod_name.show_error_if_not(false)
	mod_id.show_error_if_not(false)


func add_mod() -> void:
	# Validate mod-id
	if not mod_tool_store.manifest_data.is_mod_id_valid(mod_tool_store.name_mod_dir, mod_tool_store.name_mod_dir, "", true):
		ModToolUtils.output_error('Invalid name or namespace: "%s". You may only use letters, numbers, underscores and at least 3 characters for each.' % mod_tool_store.name_mod_dir)
		return

	# Check if mod dir exists
	if not _ModLoaderFile.dir_exists(mod_tool_store.path_mod_dir):
		# If not - create it
		var success := ModToolUtils.make_dir_recursive(mod_tool_store.path_mod_dir)
		if not success:
			return

		# Get Template files
		var template_paths := ModToolUtils.get_flat_view_dict(mod_tool_store.path_current_template_dir, "", [], false, true)

		# Copy current selected template dir files and folders to res://mods-unpacked
		for path in template_paths:
			var template_local_path := path.trim_prefix(mod_tool_store.path_current_template_dir) as String
			if _ModLoaderFile.file_exists(path):
				ModToolUtils.file_copy(path, mod_tool_store.path_mod_dir.path_join(template_local_path))
			else:
				ModToolUtils.make_dir_recursive(mod_tool_store.path_mod_dir.path_join(template_local_path))

		# Update FileSystem
		mod_tool_store.editor_file_system.scan()
		# Wait for the scan to finish
		await mod_tool_store.editor_file_system.filesystem_changed

		# Navigate to the new mod dir in the FileSystem pannel
		EditorInterface.get_file_system_dock().navigate_to_path(mod_tool_store.path_mod_dir.path_join("mod_main.gd"))

		# Output info
		ModToolUtils.output_info("Added base mod files to " + mod_tool_store.path_mod_dir)

		# Open mod_main.gd in the code editor
		var mod_main_script := load(mod_tool_store.path_mod_dir.path_join("mod_main.gd"))
		EditorInterface.edit_script(mod_main_script)
		EditorInterface.set_main_screen_editor("Script")

		# Split the new mod id
		var name_mod_dir_split: Array = mod_tool_store.name_mod_dir.split("-")

		# Update the namespace in the manifest
		mod_tool_store.manifest_data.mod_namespace = name_mod_dir_split[0]

		# Update the mod name in the manifest
		mod_tool_store.manifest_data.name = name_mod_dir_split[1]

		# Update manifest editor ui
		mod_tool_store.editor_plugin.tools_panel.manifest_editor.update_ui()

		# Open manifest editor
		mod_tool_store.editor_plugin.tools_panel.show_manifest_editor()

		# Save the manifest
		mod_tool_store.editor_plugin.tools_panel.manifest_editor.save_manifest()

	else:
		# If so - show error and ask if user wants to connect with the mod instead
		ModToolUtils.output_error("Mod directory at %s already exists." % mod_tool_store.path_mod_dir)
		# TODO: Ask user to connect with the mod instead
		return


func clear_mod_id_input() -> void:
	mod_id.input_text = ""


func get_template_options() -> Array[String]:
	var mod_template_options: Array[String] = []

	var template_dirs := _ModLoaderPath.get_dir_paths_in_dir(mod_tool_store.PATH_TEMPLATES_DIR)

	# Add the default templates
	mod_template_options.push_back(DIR_NAME_DEFAULT_TEMPLATE)
	mod_template_options.push_back(DIR_NAME_MINIMAL_TEMPLATE)

	for template_dir in template_dirs:
		var template_dir_name: String = template_dir.split("/")[-1]

		# Skip if its one of the default templates
		if (
			template_dir_name == DIR_NAME_DEFAULT_TEMPLATE or
			template_dir_name == DIR_NAME_MINIMAL_TEMPLATE
		):
			continue

		# Add all the custom templates
		mod_template_options.push_back(template_dir_name)

	return mod_template_options


func _on_Namespace_value_changed(new_value: String, input_node: ModToolInterfaceInputString) -> void:
	input_node.validate(mod_tool_store.manifest_data.is_name_or_namespace_valid(new_value, true))
	mod_id.input_text = "%s-%s" % [mod_namespace.get_input_value(), mod_name.get_input_value()]


func _on_ModName_value_changed(new_value: String, input_node: ModToolInterfaceInputString) -> void:
	input_node.validate(mod_tool_store.manifest_data.is_name_or_namespace_valid(new_value, true))
	mod_id.input_text = "%s-%s" % [mod_namespace.get_input_value(), mod_name.get_input_value()]


func _on_ModId_value_changed(new_value: String, input_node: ModToolInterfaceInputString) -> void:
	input_node.validate(mod_tool_store.manifest_data.is_mod_id_valid(new_value, new_value, "", true))
	mod_tool_store.name_mod_dir = new_value


func _on_btn_create_mod_pressed() -> void:
	add_mod()
	emit_signal("mod_dir_created")


func _on_CreateMod_about_to_show() -> void:
	# Reset Inputs
	mod_namespace.input_text = ""
	mod_name.input_text = ""
	# Reset Template
	mod_tool_store.path_current_template_dir = mod_tool_store.PATH_TEMPLATES_DIR + "default"

	# Get all Template options
	mod_template.input_options = get_template_options()


func _on_ModTemplate_value_changed(new_value: String, input_node: ModToolInterfaceInputOptions) -> void:
	mod_tool_store.path_current_template_dir = mod_tool_store.PATH_TEMPLATES_DIR + new_value


func _on_close_requested() -> void:
	hide()
