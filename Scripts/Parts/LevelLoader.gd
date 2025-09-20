extends Node

var entity_map := {}

@onready var editor: LevelEditor = owner

const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
@onready var level: Level = $"../Level"
@onready var level_bg: LevelBG = $"../Level/LevelBG"

var sub_level_file = null

func _ready() -> void:
	load_entity_map()

func load_level(level_idx := 0) -> void:
	clear_level()
	editor.sub_level_id = level_idx
	sub_level_file = editor.level_file["Levels"][level_idx]
	build_level()

func clear_level() -> void:
	for layer in 5:
		for i in editor.entity_layer_nodes[layer].get_children():
			if i is Player:
				reset_player(i)
				continue
			i.queue_free()
		var connect_tiles = editor.tile_layer_nodes[layer].get_used_cells_by_id(0, Vector2i(13, 8))
		editor.tile_layer_nodes[layer].clear()
		for i in connect_tiles:
			editor.tile_layer_nodes[layer].set_cell(i, 0, Vector2i(13, 8))
		editor.entity_tiles = [{}, {}, {}, {}, {}]

func load_entity_map() -> void:
	entity_map = JSON.parse_string(FileAccess.open(EntityIDMapper.MAP_PATH, FileAccess.READ).get_as_text())

func build_level() -> void:
	if sub_level_file.is_empty():
		return
	var layer_id := 0
	for layer in sub_level_file["Layers"]:
		for chunk_id in layer:
			var chunk = layer[chunk_id]
			add_tiles(LevelSaver.decompress_string(chunk["Tiles"]), int(chunk_id), int(layer_id))
			add_entities(LevelSaver.decompress_string(chunk["Entities"]), int(chunk_id), int(layer_id))
		layer_id += 1
	apply_level_data(sub_level_file["Data"])
	apply_bg_data(sub_level_file["BG"])

func add_tiles(chunk := "", chunk_id := 0, layer := 0) -> void:
	for tile in chunk.split("=", false):
		var tile_position := Vector2i.ZERO
		var tile_atlas_position := Vector2i.ZERO
		var source_id := 0
		
		tile_position = decode_tile_position_from_chars(tile[0], tile[1], chunk_id)
		source_id = base64_charset.find(tile[4])
		tile_atlas_position = Vector2i(base64_charset.find(tile[2]), base64_charset.find(tile[3]))
		editor.tile_layer_nodes[layer].set_cell(tile_position, source_id, tile_atlas_position)

func add_entities(chunk := "", chunk_id := 0, layer := 0) -> void:
	for entity in chunk.split("=", false):
		var entity_id = entity.get_slice(",", 1)
		var entity_chunk_position = entity.get_slice(",", 0)
		var entity_tile_position = decode_tile_position_from_chars(entity_chunk_position[0], entity_chunk_position[1], chunk_id)
		var entity_node: Node = null
		if entity_map.has(entity_id) == false:
			Global.log_error("MISSING ENTITY ID!!!! JOE FORGOT TO UPDATE THE MAP AGAIN :(")
			continue
		if entity_map[entity_id][0] != "res://Scenes/Prefabs/Entities/Player.tscn":
			entity_node = load(entity_map[entity_id][0]).instantiate()
		else:
			entity_node = get_tree().get_first_node_in_group("Players")
		var offset = entity_map[entity_id][1].split(",")
		entity_node.global_position = entity_tile_position * 16 + (Vector2i(8, 8) + Vector2i(int(offset[0]), int(offset[1])))
		editor.entity_layer_nodes[layer].add_child(entity_node)
		entity_node.reset_physics_interpolation()
		entity_node.owner = editor
		editor.entity_tiles[layer][entity_tile_position] = entity_node
		entity_node.set_meta("tile_position", entity_tile_position)
		entity_node.set_meta("tile_offset", Vector2(int(offset[0]), int(offset[1])))
		if entity_node.has_node("EditorPropertyExposer"):
			entity_node.get_node("EditorPropertyExposer").apply_string(entity)

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

func apply_level_data(data := "") -> void:
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
	Global.theme_time = level.theme_time
	editor.bgm_id = values[2]
	level.campaign = ["SMB1", "SMBLL", "SMBS", "SMBANN"][values[3]]
	Global.current_campaign = level.campaign
	level.can_backscroll = bool(values[4])
	level.vertical_height = -int(values[5])
	level.time_limit = int(values[6])
	%ThemeTime.selected = values[1]
	%LevelMusic.selected = values[2]
	%Campaign.selected = values[3]
	%BackScroll.set_pressed_no_signal(bool(values[4]))
	%HeightLimit.value = values[5]
	%TimeLimit.value = values[6]
	%SubLevelID.selected = editor.sub_level_id
	ResourceSetterNew.cache.clear()
	Global.level_theme_changed.emit()

func apply_bg_data(data := "") -> void:
	var split = data.split("=", false)
	var id := 0
	
	const BG_VALUES := ["primary_layer", "second_layer", "second_layer_offset", "time_of_day", "particles", "liquid_layer", "overlay_clouds"]
	var SELECTORS = [%PrimaryLayer, %SecondLayer, %SecondLayerOffset, %TimeOfDay, %Particles, %LiquidLayer, %OverlayClouds]
	for i in split:
		var value := 0
		if i.length() > 1:
			value = (decode_from_base64_2char(i))
		else:
			value = (base64_charset.find(i))
		if SELECTORS[id] is SpinBox:
			SELECTORS[id].value = value
		elif SELECTORS[id] is Button:
			SELECTORS[id].set_pressed_no_signal(bool(value))
		else:
			SELECTORS[id].selected = value
		level_bg.set_value(value, BG_VALUES[id])
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
