class_name EditorTileSelector
extends Control

@export var tile_name := ""
@export_multiline var tile_desc := ""
@export_enum("Tile", "Entity", "Terrain") var type := 0

@export_file_path("*.json") var icon_texture_path := ""
@export var icon_region_override := Rect2(0, 0, 0, 0)

@export_file_path("*.json") var secondary_icon_texture_path := ""
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
	if tile_selected.is_connected(owner.on_tile_selected) == false:
		tile_selected.connect(owner.on_tile_selected)

func set_icon_texture():
	if icon_texture_path == "":
		return
	if icon_texture_path.get_extension() == "json":
		$ResourceSetterNew.json_path = icon_texture_path
		$ResourceSetterNew.update_resource()
	else:
		%Icon.texture = ResourceSetter.get_resource(load(icon_texture_path), %Icon)

func set_second_icon_texture():
	if secondary_icon_texture_path == "":
		return
	if secondary_icon_texture_path.get_extension() == "json":
		$ResourceSetterNew2.json_path = secondary_icon_texture_path
	else:
		%SecondaryIcon.texture = load(secondary_icon_texture_path)


func on_pressed() -> void:
	tile_selected.emit(self)


func update_visuals() -> void:
	if icon_region_override != Rect2(0, 0, 0, 0):
		%Icon.region_rect = icon_region_override
	if secondary_icon_region_override != Rect2(0, 0, 0, 0):
		%SecondaryIcon.region_rect = secondary_icon_region_override
	modulate = Color.WHITE if not disabled else Color.DIM_GRAY


func get_id() -> void:
	for i in EntityIDMapper.map.keys():
		if EntityIDMapper.map[i][0] == entity_scene.resource_path:
			entity_id = i
			return
	
	var new_id = encode_to_base64_2char(EntityIDMapper.map.size())
	EntityIDMapper.map[new_id] = [entity_scene.resource_path, str(tile_offset.x) + "," + str(tile_offset.y)]
	JSONParser.save_to_file(EntityIDMapper.map, "res://EntityIDMap.json")
	entity_id = new_id

func encode_to_base64_2char(value: int) -> String:
	if value < 0 or value >= 4096:
		push_error("Value out of range for 2-char base64 encoding.")
		return ""

	var char1 = BASE64[(value >> 6) & 0b111111]  # Top 6 bits
	var char2 = BASE64[value & 0b111111]         # Bottom 6 bits

	return char1 + char2
