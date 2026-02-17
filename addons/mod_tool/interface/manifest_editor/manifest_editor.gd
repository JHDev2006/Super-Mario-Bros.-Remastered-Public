@tool
extends PanelContainer


var input_fields := []

@onready var mod_tool_store: ModToolStore = get_node_or_null("/root/ModToolStore")
@onready var manifest_input_vbox := $"%InputVBox"
@onready var input_incompatibilities: ModToolInterfaceInputString = $"%Incompatibilities"
@onready var input_dependencies: ModToolInterfaceInputString = $"%Dependencies"
@onready var input_optional_dependencies: ModToolInterfaceInputString = $"%OptionalDependencies"
@onready var input_load_before: ModToolInterfaceInputString = $"%LoadBefore"



func _ready() -> void:
	$VBox/Panel.add_theme_stylebox_override("panel", ThemeDB.get_default_theme().get_stylebox("bg", "ItemList"))
	# Setup input fields
	for node in manifest_input_vbox.get_children():
		if node is ModToolInterfaceInputString:
			input_fields.append(node)


func load_manifest() -> void:
	var manifest_dict_json := _ModLoaderFile.get_json_as_dict(mod_tool_store.path_manifest)
	mod_tool_store.manifest_data = ModManifest.new(manifest_dict_json, mod_tool_store.path_mod_dir)
	ModToolUtils.output_info("Loaded manifest from " + mod_tool_store.path_manifest)


func save_manifest() -> void:
	var invalid_inputs := get_invalid()

	if invalid_inputs.size() == 0:
		var _is_success := ModToolUtils.save_to_manifest_json(mod_tool_store.manifest_data, mod_tool_store.path_manifest)
	else:
		ModToolUtils.output_error('Invalid Manifest - Manifest not saved! Please check your inputs in the following fields -> ' + ", ".join(invalid_inputs))


func update_ui() -> void:
	# For each input field
	for input in input_fields:
		# Check if the key used in the ModToolInterfaceInputString instance is in the data_dict.
		if mod_tool_store.manifest_data.get(input.key):
			var value = mod_tool_store.manifest_data.get(input.key)

			# If the value is an Array create a comma separated list
			if value is PackedStringArray:
				input.input_text = ", ".join(value)
			# Else convert the value to a string
			else:
				input.input_text = str(value)
		# If the key is not in the data clear the input
		else:
			input.input_text = ""


# Returns an array of invalid fields
func get_invalid() -> Array:
	var invalid_fields := []

	for input in input_fields:
		if not input.is_valid:
			invalid_fields.append(input.label_text)

	return invalid_fields


func _update_manifest_value(input: ModToolInterfaceInputString, new_value) -> void:
	if mod_tool_store.manifest_data:
		mod_tool_store.manifest_data.set(input.key, new_value)


func _on_SaveManifest_pressed() -> void:
	save_manifest()


# Validated StringInputs
# =============================================================================


func _on_ModName_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)
	input_node.validate(mod_tool_store.manifest_data.is_name_or_namespace_valid(new_text, true))


func _on_Namespace_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)
	input_node.validate(mod_tool_store.manifest_data.is_name_or_namespace_valid(new_text, true))


func _on_Version_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)
	input_node.validate(mod_tool_store.manifest_data.is_semver_valid("", new_text, "version", true))


# When dealing with Inputs that depend on other Inputs, the `input_node` is not utilized.
# This is because the `value_changed` signal is connected to this method for all relevant inputs.
# As a result, the input_node would retrieve multiple different nodes, which should not be updated but rather revalidated.
# In such cases, the input node is directly referenced to prevent overwriting the values in other input fields.
func _on_Dependencies_value_changed(new_text: String, input_node: ModToolInterfaceInputString, validate_only: bool) -> void:
	var dependencies: PackedStringArray

	if validate_only:
		dependencies = mod_tool_store.manifest_data.dependencies
	else:
		dependencies = input_dependencies.get_input_as_array_from_comma_separated_string()
		_update_manifest_value(input_dependencies, dependencies)

	var is_id_array_valid := mod_tool_store.manifest_data.is_mod_id_array_valid(mod_tool_store.name_mod_dir, dependencies, "dependencies", true)
	var is_distinct_mod_id_incompatibilities := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			dependencies,
			mod_tool_store.manifest_data.incompatibilities,
			["dependencies", "incompatibilities"],
			"",
			true
		)
	var is_distinct_mod_id_optional_dependencies := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			dependencies,
			mod_tool_store.manifest_data.optional_dependencies,
			["dependencies", "optional_dependencies"],
			"",
			true
		)

	input_dependencies.validate(
		is_id_array_valid and
		is_distinct_mod_id_incompatibilities and
		is_distinct_mod_id_optional_dependencies
	)


# When dealing with Inputs that depend on other Inputs, the `input_node` is not utilized.
# This is because the `value_changed` signal is connected to this method for all relevant inputs.
# As a result, the input_node would retrieve multiple different nodes, which should not be updated but rather revalidated.
# In such cases, the input node is directly referenced to prevent overwriting the values in other input fields.
func _on_OptionalDependencies_value_changed(new_text: String, input_node: ModToolInterfaceInputString, validate_only: bool) -> void:
	var optional_dependencies: PackedStringArray

	if validate_only:
		optional_dependencies = mod_tool_store.manifest_data.optional_dependencies
	else:
		optional_dependencies = input_optional_dependencies.get_input_as_array_from_comma_separated_string()
		_update_manifest_value(input_optional_dependencies, optional_dependencies)

	var is_id_array_valid := mod_tool_store.manifest_data.is_mod_id_array_valid(mod_tool_store.name_mod_dir, optional_dependencies, "optional_dependencies", true)
	var is_distinct_mod_id_incompatibilities := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			optional_dependencies,
			mod_tool_store.manifest_data.incompatibilities,
			["optional_dependencies", "incompatibilities"],
			"",
			true
		)
	var is_distinct_mod_id_dependencies := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			optional_dependencies,
			mod_tool_store.manifest_data.dependencies,
			["optional_dependencies", "dependencies"],
			"",
			true
		)

	input_optional_dependencies.validate(
		is_id_array_valid and
		is_distinct_mod_id_incompatibilities and
		is_distinct_mod_id_dependencies
	)


func _on_CompatibleModLoaderVersions_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var compatible_modloader_versions := input_node.get_input_as_array_from_comma_separated_string()
	_update_manifest_value(input_node, compatible_modloader_versions)
	input_node.validate(mod_tool_store.manifest_data.is_semver_version_array_valid(mod_tool_store.name_mod_dir, compatible_modloader_versions, "Compatible ModLoader Versions", true))


# When dealing with Inputs that depend on other Inputs, the `input_node` is not utilized.
# This is because the `value_changed` signal is connected to this method for all relevant inputs.
# As a result, the input_node would retrieve multiple different nodes, which should not be updated but rather revalidated.
# In such cases, the input node is directly referenced to prevent overwriting the values in other input fields.
func _on_Incompatibilities_value_changed(new_text: String, input_node: ModToolInterfaceInputString, validate_only: bool) -> void:
	var incompatibilities: PackedStringArray

	if validate_only:
		incompatibilities = mod_tool_store.manifest_data.incompatibilities
	else:
		incompatibilities = input_incompatibilities.get_input_as_array_from_comma_separated_string()
		_update_manifest_value(input_incompatibilities, incompatibilities)

	var is_mod_id_array_valid := mod_tool_store.manifest_data.is_mod_id_array_valid(mod_tool_store.name_mod_dir, incompatibilities, "incompatibilities", true)
	var is_distinct_mod_id_dependencies := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			mod_tool_store.manifest_data.dependencies,
			incompatibilities,
			["dependencies", "incompatibilities"],
			"",
			true
		)
	var is_distinct_mod_id_optional_dependencies := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			mod_tool_store.manifest_data.optional_dependencies,
			incompatibilities,
			["optional_dependencies", "incompatibilities"],
			"",
			true
		)

	input_incompatibilities.validate(
		is_mod_id_array_valid and
		is_distinct_mod_id_dependencies and
		is_distinct_mod_id_optional_dependencies
	)


# When dealing with Inputs that depend on other Inputs, the `input_node` is not utilized.
# This is because the `value_changed` signal is connected to this method for all relevant inputs.
# As a result, the input_node would retrieve multiple different nodes, which should not be updated but rather revalidated.
# In such cases, the input node is directly referenced to prevent overwriting the values in other input fields.
func _on_LoadBefore_value_changed(new_text: String, input_node: ModToolInterfaceInputString, validate_only: bool) -> void:
	var load_before: PackedStringArray

	if validate_only:
		load_before = mod_tool_store.manifest_data.load_before
	else:
		load_before = input_load_before.get_input_as_array_from_comma_separated_string()
		_update_manifest_value(input_load_before, load_before)

	var is_mod_id_array_valid := mod_tool_store.manifest_data.is_mod_id_array_valid(mod_tool_store.name_mod_dir, load_before, "load_before", true)
	var is_distinct_mod_id_dependencies := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			load_before,
			mod_tool_store.manifest_data.dependencies,
			["load_before", "dependencies"],
			"\"load_before\" should be handled as optional dependency adding it to \"dependencies\" will cancel out the desired effect.",
			true
		)
	var is_distinct_mod_id_optional_dependencies := mod_tool_store.manifest_data.validate_distinct_mod_ids_in_arrays(
			mod_tool_store.name_mod_dir,
			load_before,
			mod_tool_store.manifest_data.optional_dependencies,
			["load_before", "optional_dependencies"],
			"\"load_before\" can be viewed as optional dependency, please remove the duplicate mod-id.",
			true
		)

	input_load_before.validate(
		is_mod_id_array_valid and
		is_distinct_mod_id_dependencies and
		is_distinct_mod_id_optional_dependencies
	)


# Non Validated StringInputs
# =============================================================================


func _on_WebsiteUrl_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)


func _on_Description_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)


func _on_Authors_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var authors := input_node.get_input_as_array_from_comma_separated_string()
	_update_manifest_value(input_node, authors)


func _on_CompatibleGameVersions_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var compatible_game_versions := input_node.get_input_as_array_from_comma_separated_string()
	_update_manifest_value(input_node, compatible_game_versions)


func _on_Tags_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var tags := input_node.get_input_as_array_from_comma_separated_string()
	_update_manifest_value(input_node, tags)
