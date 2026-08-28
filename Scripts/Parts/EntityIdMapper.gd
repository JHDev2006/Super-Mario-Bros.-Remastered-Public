@tool
class_name EntityIDMapper
extends Node

@export_tool_button("Update ID's") var button = update_map
@export var auto_update := true
static var map := {}

const MAP_PATH := "res://EntityIDMap.json"

const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

var selectors_to_add := []

func _ready() -> void:
	load_entity_map()
	if Engine.is_editor_hint() == false and OS.is_debug_build() and auto_update:
		update_map()

static func load_entity_map() -> void:
	map = JSONParser.parse_to_dict(MAP_PATH)

func update_map() -> void:
	load_entity_map()
	get_ids()
	save_to_json()
	print("Update ID Map.")

func clear_map() -> void:
	map = {}
	save_to_json()

func get_ids() -> void:
	var id := 0
	for i: EditorTileSelector in get_tree().get_nodes_in_group("Selectors"):
		if i.type != 1 or i.entity_scene == null:
			continue
		var selector_id := encode_to_base64_2char(id)
		var value = get_selector_info_arr(i)
		id += 1
		if map.has(selector_id):
			if map.values().find(value) != -1:
				continue
			else:
				selector_id = encode_to_base64_2char(map.size())
		map.set(selector_id, get_selector_info_arr(i))


static func get_selector_info_arr(selector: EditorTileSelector) -> Array:
	return [selector.entity_scene.resource_path, str(selector.tile_offset.x) + "," + str(selector.tile_offset.y)]

func save_to_json() -> void:
	JSONParser.save_to_file(map, MAP_PATH)

static func get_map_id(entity_scene := "") -> String:
	var idx := 0
	for i in map.values():
		if i[0] == entity_scene:
			return map.keys()[idx]
		idx += 1
	return ""

func encode_to_base64_2char(value: int) -> String:
	if value < 0 or value >= 4096:
		push_error("Value out of range for 2-char base64 encoding.")
		return ""

	var char1 = base64_charset[(value >> 6) & 0b111111]  # Top 6 bits
	var char2 = base64_charset[value & 0b111111]         # Bottom 6 bits

	return char1 + char2

func decode_from_base64_2char(encoded: String) -> int:
	if encoded.length() != 2:
		push_error("Encoded string must be exactly 2 characters.")
		return -1

	var idx1 = base64_charset.find(encoded[0])
	var idx2 = base64_charset.find(encoded[1])

	if idx1 == -1 or idx2 == -1:
		push_error("Invalid character in base64 string.")
		return -1

	return (idx1 << 6) | idx2
