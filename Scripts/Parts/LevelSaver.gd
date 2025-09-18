class_name LevelSaver
extends Node

var sub_level_file := {"Layers": [{}, {}, {}, {}, {}], "Data": "", "BG": ""}

static var level_file := {"Info": {}, "Levels": [{}, {}, {}, {}, {}]}

@onready var editor: LevelEditor = owner

const chunk_template := {"Tiles": "", "Entities": ""}

const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
@onready var level: Level = $"../Level"
@onready var level_bg: LevelBG = $"../Level/LevelBG"

var entity_map := {}

const tile_blacklist := []

func _ready() -> void:
	load_entity_map()

func save_level(level_name := "Unnamed Level", level_author := "You", level_desc := "No Desc", difficulty := 0) -> Dictionary:
	level_file = editor.level_file
	sub_level_file = {"Layers": [{}, {}, {}, {}, {}], "Data": "", "BG": ""}
	get_tiles()
	get_entities()
	
	save_bg_data()
	save_level_data()
	level_file["Levels"][editor.sub_level_id] = sub_level_file.duplicate()
	level_file["Info"] = {"Name": level_name, "Author": level_author, "Description": level_desc, "Difficulty": difficulty}
	level_file["Version"] = Global.version_number
	return level_file

func write_file(json := {}, lvl_file_name := "") -> void:
	for i in "<>:?!/":
		lvl_file_name = lvl_file_name.replace(i, "")
	var file = FileAccess.open(Global.config_path.path_join("custom_levels/" + lvl_file_name), FileAccess.WRITE)
	file.store_string(JSON.stringify(json, "", false))
	file.close()
	print("saved")

func load_entity_map() -> void:
	entity_map = JSON.parse_string(FileAccess.open(EntityIDMapper.MAP_PATH, FileAccess.READ).get_as_text())

func get_tiles() -> void:
	for layer in 5:
		for tile in editor.tile_layer_nodes[layer].get_used_cells():
			if tile_blacklist.has(editor.tile_layer_nodes[layer].get_cell_atlas_coords(tile)) or editor.tile_layer_nodes[layer].get_cell_source_id(tile) == 6:
				continue
			var tile_string := ""
			var chunk_tile = Vector2i(wrap(tile.x, 0, 32), wrap(tile.y + 30, -1, 32))
			tile_string += base64_charset[chunk_tile.x]
			tile_string += base64_charset[chunk_tile.y]
			tile_string += ""
			tile_string += base64_charset[editor.tile_layer_nodes[layer].get_cell_atlas_coords(tile).x]
			tile_string += base64_charset[editor.tile_layer_nodes[layer].get_cell_atlas_coords(tile).y]
			tile_string += base64_charset[editor.tile_layer_nodes[layer].get_cell_source_id(tile)]
			var tile_chunk_idx = tile_to_chunk_idx(tile)
			var tile_chunk := {}
			if sub_level_file["Layers"][layer].has(tile_chunk_idx):
				tile_chunk = sub_level_file["Layers"][layer][tile_chunk_idx]
			else:
				tile_chunk = chunk_template.duplicate(true)
			tile_chunk["Tiles"] += tile_string + "="
			sub_level_file["Layers"][layer][tile_chunk_idx] = tile_chunk
		for i in sub_level_file["Layers"][layer]:
			sub_level_file["Layers"][layer][i]["Tiles"] = compress_string(sub_level_file["Layers"][layer][i]["Tiles"])


static func compress_string(buffer := "") -> String:
	var bytes = buffer.to_ascii_buffer()
	var compressed_bytes = bytes.compress(FileAccess.CompressionMode.COMPRESSION_DEFLATE)
	var b64_buffer = Marshalls.raw_to_base64(compressed_bytes)
	# workaround since for some reason .replace() decided not to work today
	b64_buffer = b64_buffer.replace("=", "%")
	return b64_buffer

static func decompress_string(buffer := "") -> String:
	if buffer.is_empty():
		return buffer
	buffer = buffer.replace("%", "=")
	var compressed = Marshalls.base64_to_raw(buffer)
	var decompressed = compressed.decompress_dynamic(-1, FileAccess.CompressionMode.COMPRESSION_DEFLATE)
	var ret = decompressed.get_string_from_ascii()
	return ret

func get_entities() -> void:
	for layer in 5:
		for entity in editor.entity_layer_nodes[layer].get_children():
			if entity.has_meta("tile_position") == false:
				continue
			var entity_string := ""
			var chunk_position = Vector2i(wrap(entity.get_meta("tile_position").x, 0, 32), wrap(entity.get_meta("tile_position").y + 30, 0, 32))
			entity_string += base64_charset[chunk_position.x]
			entity_string += base64_charset[chunk_position.y]
			entity_string += ","

			entity_string += EntityIDMapper.get_map_id(entity.scene_file_path)
			if entity.has_node("EditorPropertyExposer"):
				entity_string += entity.get_node("EditorPropertyExposer").get_string()
			var entity_chunk_idx = tile_to_chunk_idx(entity.get_meta("tile_position"))
			var tile_chunk := {}
			if sub_level_file["Layers"][layer].has(entity_chunk_idx):
				tile_chunk = sub_level_file["Layers"][layer][entity_chunk_idx]
			else:
				tile_chunk = chunk_template.duplicate(true)
			tile_chunk["Entities"] += entity_string + "="
			sub_level_file["Layers"][layer][entity_chunk_idx] = tile_chunk
		for i in sub_level_file["Layers"][layer]:
			sub_level_file["Layers"][layer][i]["Entities"] = compress_string(sub_level_file["Layers"][layer][i]["Entities"])

func encode_to_base64_2char(value: int) -> String:
	if value < 0 or value >= 4096:
		push_error("Value out of range for 2-char base64 encoding.")
		return ""

	var char1 = base64_charset[(value >> 6) & 0b111111]  # Top 6 bits
	var char2 = base64_charset[value & 0b111111]         # Bottom 6 bits

	return char1 + char2

func save_level_data() -> void:
	var string := ""
	for i in [Level.THEME_IDXS.find(level.theme), ["Day", "Night"].find(level.theme_time), editor.bgm_id, ["SMB1", "SMBLL", "SMBS", "SMBANN"].find(level.campaign), level.can_backscroll, abs(level.vertical_height), level.time_limit]:
		var key := ""
		if int(i) >= 64:
			key = encode_to_base64_2char(int(i))
		else:
			key = base64_charset[int(i)]
		string += key + "="
	sub_level_file["Data"] = string

func save_bg_data() -> void:
	var string := ""
	for i in [level_bg.primary_layer, level_bg.second_layer, level_bg.second_layer_offset.y, level_bg.time_of_day, level_bg.particles, level_bg.liquid_layer, level_bg.overlay_clouds]:
		var key := ""
		i = int(i)
		if abs(i) >= 64:
			key = encode_to_base64_2char(abs(i))
		else:
			key = base64_charset[abs(i)]
		string += key + "="
	sub_level_file["BG"] = string

func tile_to_chunk_idx(tile_position := Vector2i.ZERO) -> int:
	return floor(tile_position.x / 32.0)
