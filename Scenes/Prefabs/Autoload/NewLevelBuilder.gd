extends Node

var entity_map := {}


const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

var sub_level_file = null

var level_file := {}

const BASE_LEVEL_SCENE: PackedScene = preload("res://Scenes/Levels/CustomLevelBase.tscn")

static var sub_levels: Array[PackedScene] = [null, null, null, null, null]

signal level_building_complete

var building = false

func _ready() -> void:
	load_entity_map()

func load_level(level_file := {}) -> void:
	sub_levels = [null, null, null, null, null]
	building = true
	for i in 5:
		sub_levels[i] = build_sublevel(i, level_file)
	level_building_complete.emit()
	building = false

func build_sublevel(level_idx := 0, level_file := {}) -> PackedScene:
	var level = BASE_LEVEL_SCENE.instantiate()
	level.sublevel_id = level_idx
	level.level_id = Global.level_num
	level.world_id = Global.world_num
	sub_level_file = level_file["Levels"][level_idx]
	return pack_level_into_scene(build_level(level))

func pack_level_into_scene(level: Node) -> PackedScene:
	var scene = PackedScene.new()
	scene.pack(level)
	return scene

func load_entity_map() -> void:
	entity_map = JSON.parse_string(FileAccess.open(EntityIDMapper.MAP_PATH, FileAccess.READ).get_as_text())

func build_level(level: Node = null) -> Node:
	if sub_level_file.is_empty():
		return null
	var layer_id := 0
	for layer in sub_level_file["Layers"]:
		for chunk_id in layer:
			var chunk = layer[chunk_id]
			add_tiles(level, LevelSaver.decompress_string(chunk["Tiles"]), int(chunk_id), int(layer_id))
			add_entities(level, LevelSaver.decompress_string(chunk["Entities"]), int(chunk_id), int(layer_id))
		layer_id += 1
	apply_level_data(level, sub_level_file["Data"])
	apply_bg_data(level, sub_level_file["BG"])
	return level

func add_tiles(level: Node, chunk := "", chunk_id := 0, layer := 0) -> void:
	for tile in chunk.split("=", false):
		var tile_position := Vector2i.ZERO
		var tile_atlas_position := Vector2i.ZERO
		var source_id := 0
		
		tile_position = decode_tile_position_from_chars(tile[0], tile[1], chunk_id)
		source_id = base64_charset.find(tile[4])
		tile_atlas_position = Vector2i(base64_charset.find(tile[2]), base64_charset.find(tile[3]))
		level.get_node("TileLayer" + str(layer + 1)).set_cell(tile_position, source_id, tile_atlas_position)

func add_entities(level: Node, chunk := "", chunk_id := 0, layer := 0) -> void:
	for entity in chunk.split("=", false):
		var entity_id = entity.get_slice(",", 1)
		var entity_chunk_position = entity.get_slice(",", 0)
		var entity_tile_position = decode_tile_position_from_chars(entity_chunk_position[0], entity_chunk_position[1], chunk_id)
		var entity_node: Node = null
		if entity_map.has(entity_id) == false:
			Global.log_error("MISSING ENTITY ID: " + entity_id)
			continue
		if entity_map[entity_id][0] != "res://Scenes/Prefabs/Entities/Player.tscn":
			entity_node = load(entity_map[entity_id][0]).instantiate()
		else:
			entity_node = level.get_node("EntityLayer1/Player")
		if entity_node == null:
			continue
		var offset = entity_map[entity_id][1].split(",")
		entity_node.global_position = entity_tile_position * 16 + (Vector2i(8, 8) + Vector2i(int(offset[0]), int(offset[1])))
		level.get_node("EntityLayer" + str(layer + 1)).add_child(entity_node)
		entity_node.reset_physics_interpolation()
		entity_node.owner = level
		entity_node.set_meta("tile_position", entity_tile_position)
		entity_node.set_meta("tile_offset", Vector2(int(offset[0]), int(offset[1])))
		if entity_node.has_node("EditorPropertyExposer"):
			entity_node.get_node("EditorPropertyExposer").apply_string(entity)
		if entity_node.has_node("SignalExposer"):
			entity_node.set_meta("save_string", entity)

func reset_player(player: Player) -> void: ## Function literally here to just reset the player back to default starting, if loading into a level file, that hasnt been written yet (pipes)
	player.show()
	player.state_machine.transition_to("Normal")
	player.global_position = Vector2(-232, 0)

func gzip_encode(text: String) -> String:
	var bytes = Marshalls.base64_to_raw(text)
	bytes.compress(FileAccess.COMPRESSION_GZIP)
	return Marshalls.raw_to_base64(bytes)

func gzip_decode(text: String) -> String:
	var bytes = Marshalls.base64_to_raw(text)
	bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return Marshalls.raw_to_base64(bytes)

func apply_level_data(level: Level, data := "") -> void:
	var split = data.split("=")
	var values := []
	for i in split:
		if i.length() == 2:
			values.append(decode_from_base64_2char(i))
		elif i.length() == 1:
			values.append(base64_charset.find(i))
		else:
			values.append(i)
	level.theme = Level.THEME_IDXS[values[0]]
	Global.level_theme = level.theme
	level.theme_time = ["Day", "Night"][values[1]]
	level.music = load(LevelEditor.music_track_list[values[2]])
	Global.theme_time = level.theme_time
	level.campaign = ["SMB1", "SMBLL", "SMBS", "SMBANN"][values[3]]
	Global.current_campaign = level.campaign
	level.can_backscroll = bool(values[4])
	level.vertical_height = -int(values[5])
	level.time_limit = int(values[6])
	if values.size() > 8:
		level.enforce_resolution = Vector2(int(values[7]), int(values[8]))
	ResourceSetterNew.clear_cache()
	Global.level_theme_changed.emit()

func apply_bg_data(level: Node, data := "") -> void:
	var split = data.split("=", false)
	var id := 0
	
	const BG_VALUES := ["primary_layer", "second_layer", "second_layer_offset", "time_of_day", "particles", "liquid_layer", "overlay_clouds", "second_layer_order"]
	for i in split:
		var value := 0
		if i.length() > 1:
			value = (decode_from_base64_2char(i))
		else:
			value = (base64_charset.find(i))
		level.get_node("LevelBG").set_value(value, BG_VALUES[id])
		id += 1
	

func decode_tile_position_from_chars(char_x: String, char_y: String, chunk_idx: int) -> Vector2i:
	
	var local_x = base64_charset.find(char_x)
	var local_y = base64_charset.find(char_y)

	return Vector2i(local_x + (chunk_idx * 32), local_y - 30)

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

func tile_to_chunk_idx(tile_position := Vector2i.ZERO) -> int:
	return floor(tile_position.x / 32.0)
