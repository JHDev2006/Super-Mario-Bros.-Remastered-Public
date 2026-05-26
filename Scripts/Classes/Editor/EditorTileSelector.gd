class_name EditorTileSelector
extends Control

@export var tile_name := ""
@export_multiline var tile_desc := ""
@export_enum("Tile", "Entity", "Terrain") var type := 0
@export var icon_texture: Resource = null
@export var icon_region_override := Rect2(0, 0, 0, 0)

@export var secondary_icon_texture: Resource = null
@export var secondary_icon_region_override := Rect2(0, 0, 0, 0)

@export_category("Entity")
@export var entity_id := ""

@export_group("ID Generation")
@export var entity_scene: PackedScene = null
@export var tile_offset := Vector2i.ZERO

@export_category("Tile")
@export var source_id := 0
@export var terrain_id := 0
@export var tile_coords := Vector2i.ZERO
@export var flip_h := false
@export var flip_v := false

var texture_rect_region := Rect2(0, 0, 0, 0)

signal tile_selected(selector: EditorTileSelector)
signal right_clicked

var mouse_hovered := false

var disabled := false

const BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

func _ready() -> void:
	set_icon_texture()
	set_second_icon_texture()
	update_visuals()
	set_process(false)
	if tile_selected.is_connected(Global.level_editor.on_tile_selected) == false:
		tile_selected.connect(Global.level_editor.on_tile_selected)
	%NameLabel.text = tile_name

func _process(_delta: float) -> void:
	var target_position = get_viewport().get_mouse_position()
	target_position.x = clamp(target_position.x, %Panel.size.x / 2, (get_viewport().get_visible_rect().size.x) - %Panel.size.x / 2)
	%NamePanel.position = target_position
	%Description.text = tile_desc
	%Line.visible = tile_desc != ""
	%Description.custom_minimum_size.x = get_viewport().get_visible_rect().size.x / 2
	if tile_desc != "":
		%DescPreview.visible = not Input.is_action_pressed("editor_inspect")
		%Description.visible = not %DescPreview.visible
		%DescriptionSizer.visible = %Description.visible

func set_icon_texture():
	if icon_texture == null:
		return
	if icon_texture is JSON:
		$ResourceSetterNew.resource_json = icon_texture
		$ResourceSetterNew.update_resource()
	else:
		%Icon.texture = ResourceSetter.get_resource(icon_texture, %Icon)

func set_second_icon_texture():
	if secondary_icon_texture == null:
		return
	if secondary_icon_texture is JSON:
		$ResourceSetterNew2.resource_json = secondary_icon_texture
		$ResourceSetterNew2.update_resource()
	elif secondary_icon_texture is ThemedResource:
		%SecondaryIcon.texture = ResourceSetter.get_resource(secondary_icon_texture, %SecondaryIcon)
	else:
		%SecondaryIcon.texture = secondary_icon_texture


func on_pressed() -> void:
	tile_selected.emit(self)


func update_visuals() -> void:
	if icon_region_override != Rect2(0, 0, 0, 0):
		%Icon.region_rect = icon_region_override
	if secondary_icon_region_override != Rect2(0, 0, 0, 0):
		%SecondaryIcon.region_rect = secondary_icon_region_override
	modulate = Color.WHITE if not disabled else Color.DIM_GRAY

func set_mouse_hovered(hovered := false) -> void:
	%NamePanel.visible = hovered and tile_name.is_empty() == false
	mouse_hovered = hovered
	$Button.disabled = disabled
	set_process(hovered)

func on_mouse_entered() -> void:
	set_mouse_hovered(true)

func get_id() -> void:
	for i in EntityIDMapper.map.keys():
		if EntityIDMapper.map[i][0] == entity_scene.resource_path:
			entity_id = i
			return
	
	var new_id = encode_to_base64_2char(EntityIDMapper.map.size())
	EntityIDMapper.map[new_id] = [entity_scene.resource_path, str(tile_offset.x) + "," + str(tile_offset.y)]
	FileAccess.open("res://EntityIDMap.json", FileAccess.WRITE).store_string(JSON.stringify(EntityIDMapper.map, "\t"))
	entity_id = new_id

func encode_to_base64_2char(value: int) -> String:
	if value < 0 or value >= 4096:
		push_error("Value out of range for 2-char base64 encoding.")
		return ""

	var char1 = BASE64[(value >> 6) & 0b111111]  # Top 6 bits
	var char2 = BASE64[value & 0b111111]         # Bottom 6 bits

	return char1 + char2

func on_mouse_exited() -> void:
	set_mouse_hovered(false)
	%NamePanel.hide()
