class_name LevelEditor
extends Node

const CAM_MOVE_SPEED_SLOW := 128
const CAM_MOVE_SPEED_FAST := 256

var cursor_tile_position := Vector2i.ZERO

const CURSOR_OFFSET := Vector2(-8, -8)

var mode := 0
var current_entity_selector: EditorTileSelector = null
var current_entity_scene: PackedScene = null
var current_spawn_offset := Vector2i.ZERO
var current_tile_source := 0
var current_tile_coords := Vector2i.ZERO
var current_tile_flip := Vector2.ZERO ## 1 = true, 0 = false, x = hori, y = vert

var menu_open := false
var testing_level := false
var entity_tiles := [{}, {}, {}, {}, {}]

static var playing_level := false

var tile_list: Array[EditorTileSelector] = []

var tile_offsets := {}

signal level_start

var selected_tile_index := 0

var can_move_cam := true

var music_track_list: Array[String] = [ "res://Assets/Audio/BGM/Silence.json","res://Assets/Audio/BGM/Athletic.json", "res://Assets/Audio/BGM/Autumn.json", "res://Assets/Audio/BGM/Beach.json", "res://Assets/Audio/BGM/Bonus.json", "res://Assets/Audio/BGM/Bowser.json", "res://Assets/Audio/BGM/FinalBowser.json", "res://Assets/Audio/BGM/Castle.json", "res://Assets/Audio/BGM/CoinHeaven.json", "res://Assets/Audio/BGM/Desert.json", "res://Assets/Audio/BGM/Garden.json", "res://Assets/Audio/BGM/GhostHouse.json", "res://Assets/Audio/BGM/Jungle.json", "res://Assets/Audio/BGM/Mountain.json", "res://Assets/Audio/BGM/Overworld.json", "res://Assets/Audio/BGM/Pipeland.json", "res://Assets/Audio/BGM/BooRace.json", "res://Assets/Audio/BGM/Sky.json", "res://Assets/Audio/BGM/Snow.json", "res://Assets/Audio/BGM/Space.json", "res://Assets/Audio/BGM/Underground.json", "res://Assets/Audio/BGM/Underwater.json", "res://Assets/Audio/BGM/Volcano.json", "res://Assets/Audio/BGM/Airship.json"]
var music_track_names: Array[String] = ["BGM_NONE", "BGM_ATHLETIC", "BGM_AUTUMN", "BGM_BEACH", "BGM_BONUS", "BGM_BOWSER", "BGM_FINALBOWSER", "BGM_CASTLE", "BGM_COINHEAVEN", "BGM_DESERT", "BGM_GARDEN", "BGM_GHOSTHOUSE", "BGM_JUNGLE", "BGM_MOUNTAIN", "BGM_OVERWORLD", "BGM_PIPELAND", "BGM_RACE", "BGM_SKY", "BGM_SNOW", "BGM_SPACE", "BGM_UNDERGROUND", "BGM_UNDERWATER", "BGM_VOLCANO", "BGM_AIRSHIP"]


var bgm_id := 0

const MUSIC_TRACK_DIR := "res://Assets/Audio/BGM/"

var select_start := Vector2i.ZERO
var select_end := Vector2i.ZERO

signal close_confirm(save: bool)

var sub_level_id := 0

const BLANK_FILE := {"Info": {}, "Levels": [{}, {}, {}, {}, {}]}

static var level_file = {"Info": {}, "Levels": [{}, {}, {}, {}, {}]}

var current_layer := 0
@onready var tile_layer_nodes: Array[TileMapLayer] = [%TileLayer1, %TileLayer2, %TileLayer3, %TileLayer4, %TileLayer5]
@onready var entity_layer_nodes := [%EntityLayer1, %EntityLayer2, %EntityLayer3, %EntityLayer4, %EntityLayer5]
var saved_entity_layers := [null, null, null, null, null]

var copied_node: Node = null
var copied_tile_offset := Vector2.ZERO
var copied_tile_source_id := -1
var copied_tile_atlas_coors := Vector2i.ZERO
var copied_tile_terrain_id := -1


const CURSOR_ERASOR := preload("uid://d0j1my4kuapgb")
const CURSOR_PEN = preload("uid://bt0brcjv0efmw")
const CURSOR_PENCIL = preload("uid://c8oyhfvlv2gvh")
const CURSOR_RULER = preload("uid://cg2wkxnmjgplf")
const CURSOR_INSPECT = preload("uid://1l3foyjqeej")

var multi_selecting := false

var inspect_mode := false
var inspect_menu_open := false
var current_inspect_tile: Node = null

var selection_filter := ""

static var level_author := ""
static var level_desc := ""
static var level_name := ""
static var difficulty := 0

var current_terrain_id := 0

static var load_play := false

signal tile_selected(tile_selector: EditorTileSelector)

var tile_menu_open := false

signal editor_start

enum EditorState{IDLE, TILE_MENU, MODIFYING_TILE, SAVE_MENU, SELECTING_TILE_SCENE, QUITTING, PLAYTESTING, TRACK_EDITING}

var current_state := EditorState.IDLE

static var play_pipe_transition := false
static var play_door_transition := false

const BOUNDARY_CONNECT_TILE := Vector2i.ZERO

var undo_redo = UndoRedo.new()

func _ready() -> void:
	$TileMenu.hide()
	DiscordManager.set_discord_status("In The Level Editor...")
	Global.level_editor = self
	playing_level = false
	menu_open = $TileMenu.visible
	Global.get_node("GameHUD").hide()
	Global.can_time_tick = false
	for i in get_tree().get_nodes_in_group("Selectors"):
		tile_list.append(i)
	var idx := 0
	for i in music_track_list:
		if i == "": continue
		$%LevelMusic.add_item(tr(music_track_names[idx]).to_upper())
		idx += 1
	await get_tree().process_frame
	Level.start_level_path = scene_file_path
	var layer_idx := 0
	for i in entity_layer_nodes:
		for x in i.get_children():
			entity_tiles[layer_idx][x.get_meta("tile_position")] = x
	if level_file != {}:
		Level.can_set_time = true
		$LevelLoader.load_level(Checkpoint.sublevel_id)
		if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
			$Info.hide()
			%Grid.hide()
			play_level()
			_physics_process(0)
			set_physics_process(false)
			for i in [$TileMenu]:
				i.queue_free()
		else:
			Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	else:
		Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.recenter_camera()
	%LevelName.text = level_name
	%LevelAuthor.text = level_author
	%Description.text = level_desc


func _physics_process(delta: float) -> void:
	if current_state == EditorState.IDLE:
		handle_tile_cursor()
	if [EditorState.IDLE, EditorState.TRACK_EDITING].has(current_state):
		handle_camera(delta)
	if is_instance_valid(%ThemeName):
		%ThemeName.text = Global.level_theme
	handle_hud()
	if Input.is_action_just_pressed("editor_open_menu"):
		if current_state == EditorState.IDLE:
			open_tile_menu()
		elif current_state == EditorState.TILE_MENU:
			close_tile_menu()
	if Input.is_action_just_pressed("editor_play") and (current_state == EditorState.IDLE or current_state == EditorState.PLAYTESTING) and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		Checkpoint.passed_checkpoints.clear()
		if current_state == EditorState.PLAYTESTING:
			stop_testing()
		else:
			play_level()
	handle_layers()

func handle_hud() -> void:
	$TileCursor.visible = current_state == EditorState.IDLE
	$Info.visible = not playing_level
	%Grid.visible = not playing_level

func quit_editor() -> void:
	%QuitDialog.show()

signal level_saved

func open_tile_menu() -> void:
	$TileMenu.visible = true
	current_state = EditorState.TILE_MENU
	for i in get_tree().get_nodes_in_group("Selectors"):
		i.disabled = false
		i.update_visuals()

func close_tile_menu() -> void:
	$TileMenu.visible = false
	current_state = EditorState.IDLE
	for i in get_tree().get_nodes_in_group("Selectors"):
		i.disabled = false

func save_level_before_exit() -> void:
	tile_menu_open = true
	open_save_dialog()
	await level_saved
	go_back_to_menu()

func copy_node(tile_position := Vector2i.ZERO) -> void:
	if tile_layer_nodes[current_layer].get_used_cells().has(tile_position):
		var terrain_id = BetterTerrain.get_cell(tile_layer_nodes[current_layer], tile_position)
		if terrain_id != -2:
			copied_tile_terrain_id = terrain_id
			return
		mode = 0
		copied_tile_source_id = tile_layer_nodes[current_layer].get_cell_source_id(tile_position)
		copied_tile_atlas_coors = tile_layer_nodes[current_layer].get_cell_atlas_coords(tile_position)
	elif entity_tiles[current_layer].has(tile_position):
		copied_node = entity_tiles[current_layer][tile_position].duplicate()
		copied_tile_offset = entity_tiles[current_layer][tile_position].get_meta("tile_offset")

func cut_node(tile_position := Vector2i.ZERO) -> void:
	var old_copy = copied_node
	copy_node(tile_position)
	if copied_node != old_copy:
		remove_tile(tile_position)

func paste_node(tile_position := Vector2i.ZERO) -> void:
	place_tile(tile_position, true)

func go_back_to_menu() -> void:
	Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")

func open_bindings_menu() -> void:
	$TileMenu/EditorKeybindsView.open()
	current_state = EditorState.SAVE_MENU
	await $TileMenu/EditorKeybindsView.closed
	current_state = EditorState.TILE_MENU

func open_save_dialog() -> void:
	current_state = EditorState.SAVE_MENU
	can_move_cam = false
	%SaveLevelDialog.show()
	menu_open = true

func stop_testing() -> void:
	cleanup()
	return_to_editor()
	

func cleanup() -> void:
	get_tree().paused = false
	Global.p_switch_timer = 0
	Global.cancel_score_tally()
	playing_level = !playing_level
	play_pipe_transition = false
	play_door_transition = false
	LevelPersistance.reset_states()
	KeyItem.total_collected = 0
	Global.get_node("GameHUD").visible = playing_level
	Global.p_switch_active = false
	if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		Global.time = $Level.time_limit
	elif Level.can_set_time and playing_level:
		Global.time = $Level.time_limit
	Global.can_time_tick = playing_level
	print(Global.can_time_tick)

func update_music() -> void:
	if music_track_list[bgm_id] != "":
		$Level.music = load(music_track_list[bgm_id].replace(".remap", ""))
	else:
		$Level.music = null

func play_level() -> void:
	$TileMenu.hide()
	menu_open = false
	update_music()
	reset_values_for_play()
	%Camera.enabled = false
	level_start.emit()
	get_tree().call_group("Players", "editor_level_start")
	parse_tiles()
	if Global.current_game_mode != Global.GameMode.CUSTOM_LEVEL:
		level_file = await $LevelSaver.save_level(level_name, level_author, level_desc, difficulty)
	current_state = EditorState.PLAYTESTING
	handle_hud()

func parse_tiles() -> void:
	saved_entity_layers = [null, null, null, null, null]
	var idx := 0
	for i in entity_layer_nodes:
		if is_instance_valid(i) == false:
			continue
		if load_play == false:
			saved_entity_layers[idx] = i.duplicate(DUPLICATE_USE_INSTANTIATION)
		if i is Player:
			i.direction = 1
			i.velocity = Vector2.ZERO
			i.global_position = i.global_position.snapped(Vector2(8, 8))
		i.ready.emit()
		i.set_process_mode(Node.PROCESS_MODE_INHERIT)
		idx += 1

func return_to_editor() -> void:
	AudioManager.stop_all_music()
	$Level.music = null
	%Camera.global_position = get_viewport().get_camera_2d().get_screen_center_position()
	%Camera.reset_physics_interpolation()
	return_editor_tiles()
	%Camera.enabled = true
	%Camera.make_current()
	KeyItem.total_collected = 0
	Door.unlocked_doors.clear()
	editor_start.emit()
	current_state = EditorState.IDLE
	handle_hud()

func return_editor_tiles() -> void:
	for i in entity_layer_nodes:
		i.queue_free()
	var idx := 0
	for i in entity_tiles:
		i.clear()
		$Level.add_child(saved_entity_layers[idx])
		entity_layer_nodes[idx] = saved_entity_layers[idx]
		idx += 1
	var layer_idx = 0
	for x in entity_layer_nodes:
		x.process_mode = PROCESS_MODE_DISABLED
		for i in x.get_children():
			i.owner = self
			var _tile_position = (Vector2i(i.global_position) - Vector2i(8, 8)) / 16
			entity_tiles[layer_idx].set(i.get_meta("tile_position", Vector2i.ZERO), i)
		layer_idx += 1

func handle_camera(delta: float) -> void:
	var input_vector = Input.get_vector("editor_cam_left", "editor_cam_right", "editor_cam_up", "editor_cam_down")
	%Camera.global_position += input_vector * (CAM_MOVE_SPEED_FAST if Input.is_action_pressed("editor_cam_fast") else CAM_MOVE_SPEED_SLOW) * delta
	%Camera.global_position.y = clamp(%Camera.global_position.y, $Level.vertical_height + (get_viewport().get_visible_rect().size.y / 2), 32 - (get_viewport().get_visible_rect().size.y / 2))
	%Camera.global_position.x = clamp(%Camera.global_position.x, -256 + (get_viewport().get_visible_rect().size.x / 2), INF)

func handle_layers() -> void:
	if Input.is_action_just_pressed("layer_up"):
		current_layer += 1
	if Input.is_action_just_pressed("layer_down"):
		current_layer -= 1
	current_layer = clamp(current_layer, 0, entity_layer_nodes.size() - 1)
	var idx := 0
	for i in entity_layer_nodes:
		if is_instance_valid(i) == false:
			continue
		i.z_index = 0 if current_layer == idx or playing_level else -1
		i.modulate = Color(1, 1, 1, 1) if current_layer == idx or playing_level else Color(1, 1, 1, 0.5)
		tile_layer_nodes[idx].modulate = i.modulate
		tile_layer_nodes[idx].z_index = i.z_index - 1
		%LayerDisplay.get_child(idx).modulate = Color.WHITE if current_layer == idx else Color(0.1, 0.1, 0.1, 0.5)
		idx += 1
	%LayerLabel.text = "Layer " + str(current_layer + 1)

func save_level() -> void:
	level_author = %LevelAuthor.text
	level_desc = %Description.text
	level_name = %LevelName.text
	difficulty = %DifficultySlider.value
	var file_name = level_name.to_pascal_case() + ".lvl"
	%SaveLevelDialog.hide()
	menu_open = false
	level_file = $LevelSaver.save_level(level_name, level_author, level_desc, difficulty)
	$LevelSaver.write_file(level_file, file_name)
	%SaveDialog.text = str("'") +  file_name + "'" + " Saved." 
	%SaveAnimation.play("Show")
	current_state = EditorState.TILE_MENU
	level_saved.emit()

func close_save_menu() -> void:
	can_move_cam = true
	%SaveLevelDialog.hide()
	menu_open = false
	current_state = EditorState.TILE_MENU

func handle_tile_cursor() -> void:
	var target_mouse_icon = null
	var snapped_position = ((%TileCursor.get_global_mouse_position() - CURSOR_OFFSET).snapped(Vector2(16, 16))) + CURSOR_OFFSET
	%TileCursor.global_position = (snapped_position)
	var old_index := selected_tile_index
	var tile_position = global_position_to_tile_position(snapped_position + Vector2(-8, -8))
	tile_position.y = clamp(tile_position.y, -30, 1)
	tile_position.x = clamp(tile_position.x, -16, INF)
	cursor_tile_position = tile_position

	inspect_mode = Input.is_action_pressed("editor_inspect") and not multi_selecting
	if inspect_mode and current_state == EditorState.IDLE:
		handle_inspection(tile_position)
		return
	
	if Input.is_action_pressed("mb_left"):
		if Input.is_action_pressed("editor_select") and not multi_selecting:
			multi_select_start(tile_position)
		elif Input.is_action_pressed("editor_select") == false:
			multi_selecting = false
			place_tile(tile_position)
			target_mouse_icon = (CURSOR_PENCIL)
		
	if Input.is_action_pressed("mb_right"):
		if Input.is_action_pressed("editor_select") and not multi_selecting:
			multi_select_start(tile_position)
			target_mouse_icon = (CURSOR_RULER)
		elif Input.is_action_pressed("editor_select") == false:
			multi_selecting = false
			remove_tile(tile_position)
			target_mouse_icon = (CURSOR_ERASOR)
	
	if current_state == EditorState.IDLE:
		if Input.is_action_just_pressed("scroll_up"):
			selected_tile_index -= 1
		if Input.is_action_just_pressed("scroll_down"):
			selected_tile_index += 1
	
		if Input.is_action_just_pressed("editor_copy"):
			copy_node(tile_position)
		elif Input.is_action_just_pressed("editor_cut"):
			cut_node(tile_position)
		elif Input.is_action_pressed("ui_paste"):
			paste_node(tile_position)
	
		if Input.is_action_just_pressed("pick_tile"):
			pick_tile(tile_position)
	
	handle_multi_selecting(tile_position)
	if old_index != selected_tile_index:
		selected_tile_index = wrap(selected_tile_index, 0, tile_list.size())
		on_tile_selected(tile_list[selected_tile_index])
		show_scroll_preview()
	
	Input.set_custom_mouse_cursor(target_mouse_icon)

func pick_tile(tile_position := Vector2i.ZERO) -> void:
	if tile_layer_nodes[current_layer].get_used_cells().has(tile_position):
		var terrain_id = BetterTerrain.get_cell(tile_layer_nodes[current_layer], tile_position)
		if terrain_id != -2:
			mode = 2
			current_terrain_id = terrain_id
			return
		mode = 0
		current_tile_source = tile_layer_nodes[current_layer].get_cell_source_id(tile_position)
		current_tile_coords = tile_layer_nodes[current_layer].get_cell_atlas_coords(tile_position)
	elif entity_tiles[current_layer].has(tile_position) and entity_tiles[current_layer][tile_position] is not Player:
		mode = 1
		current_entity_scene = load(entity_tiles[current_layer][tile_position].scene_file_path)
		current_spawn_offset = entity_tiles[current_layer][tile_position].get_meta("tile_offset")

func handle_inspection(tile_position := Vector2i.ZERO) -> void:
	Input.set_custom_mouse_cursor(CURSOR_INSPECT)
	if Input.is_action_just_pressed("mb_left"):
		if entity_tiles[current_layer].get(tile_position) != null:
			open_tile_properties(entity_tiles[current_layer][tile_position])

func open_tile_properties(tile: Node2D) -> void:
	var properties = get_tile_properties(tile)
	if properties.is_empty():
		return
	
	current_inspect_tile = tile
	%TileModifierMenu.override_scenes = tile.get_node("EditorPropertyExposer").properties_force_selector
	%TileModifierMenu.properties = properties
	%TileModifierMenu.editing_node = current_inspect_tile
	%TileModifierMenu.open()
	current_state = EditorState.MODIFYING_TILE
	%TileModifierMenu.position = tile.get_global_transform_with_canvas().origin
	%TileModifierMenu.position.x = clamp(%TileModifierMenu.position.x, 0, get_viewport().get_visible_rect().size.x - %TileModifierMenu.size.x - 2)
	%TileModifierMenu.position.y = clamp(%TileModifierMenu.position.y, 0, get_viewport().get_visible_rect().size.y - %TileModifierMenu.size.y - 2)

	await %TileModifierMenu.closed
	current_state = EditorState.IDLE

func multi_select_start(tile_position := Vector2i.ZERO) -> void:
	select_start = tile_position
	multi_selecting = true

func handle_multi_selecting(tile_position := Vector2i.ZERO) -> void:
	select_end = tile_position
	%MultiSelectRect.visible = multi_selecting
	var top_corner := select_start
	if select_start.x > select_end.x:
		top_corner.x = select_end.x
	if select_start.y > select_end.y:
		top_corner.y = select_end.y
	%MultiSelectRect.global_position = top_corner * 16
	%MultiSelectRect.size = abs(select_end - select_start) * 16 + Vector2i(16, 16)
	if multi_selecting:
		Input.set_custom_mouse_cursor(CURSOR_RULER)
		if Input.is_action_just_released("mb_left"): 
			for x in abs(select_end.x - select_start.x) + 1:
				for y in abs(select_end.y - select_start.y) + 1:
					var position = top_corner + Vector2i(x, y)
					place_tile(position)
			multi_selecting = false
		if Input.is_action_just_released("mb_right"): 
			for x in abs(select_end.x - select_start.x) + 1:
				for y in abs(select_end.y - select_start.y) + 1:
					var position = top_corner + Vector2i(x, y)
					remove_tile(position)
			multi_selecting = false

func show_scroll_preview() -> void:
	$TileCursor/Previews.show()
	for i in [$"TileCursor/Previews/-2", $"TileCursor/Previews/-1", $"TileCursor/Previews/0", $"TileCursor/Previews/1", $"TileCursor/Previews/2"]:
		var position = selected_tile_index + int(i.name)
		var selector = tile_list[wrap(position, 0, tile_list.size())]
		i.texture = selector.get_node("%Icon").texture
		i.get_node("Overlay").texture = selector.get_node("%SecondaryIcon").texture
		i.get_node("Overlay").region_rect = selector.get_node("%SecondaryIcon").region_rect
		i.region_rect = selector.get_node("%Icon").region_rect
	$TileCursor/Timer.start()
	await $TileCursor/Timer.timeout
	$TileCursor/Previews.hide()
	
func open_tile_selection_menu_scene_ref(selector: TilePropertySceneRef) -> void:
	open_tile_menu()
	current_state = EditorState.SELECTING_TILE_SCENE
	selection_filter = selector.editing_node.get_node("EditorPropertyExposer").filters[selector.tile_property_name]
	for i in get_tree().get_nodes_in_group("Selectors"):
		i.disabled = !i.has_meta(selection_filter)
		i.update_visuals()
	await tile_selected
	if is_instance_valid(selector) == false:
		return
	selector.set_scene(current_entity_selector)
	close_tile_menu()
	current_state = EditorState.MODIFYING_TILE
func on_tile_selected(selector: EditorTileSelector) -> void:
	mode = selector.type
	current_entity_selector = selector
	selected_tile_index = tile_list.find(selector)
	print(selected_tile_index)
	if selector.type == 1:
		current_entity_scene = selector.entity_scene
		current_spawn_offset = selector.tile_offset
	elif selector.type == 2:
		current_terrain_id = selector.terrain_id
	else:
		current_tile_source = selector.source_id
		current_tile_coords = selector.tile_coords
		current_tile_flip = Vector2(selector.flip_h, selector.flip_v)
	tile_selected.emit(selector)

func reset_values_for_play() -> void:
	Global.score = 0
	Global.lives = 0
	Global.coins = 0
	cleanup()

func place_tile(tile_position := Vector2i.ZERO, use_copy := false) -> void:
	$TileCursor/Previews.hide()
	var mode_to_use = mode
	if use_copy:
		if copied_node != null:
			mode_to_use = 1
		elif copied_tile_terrain_id != -1:
			mode_to_use = 2
		else:
			mode_to_use = 0
	if mode_to_use == 0:
		var alt_tile := 0
		if current_tile_flip.x != 0:
			alt_tile += TileSetAtlasSource.TRANSFORM_FLIP_H
		if current_tile_flip.y != 0:
			alt_tile += TileSetAtlasSource.TRANSFORM_FLIP_V
		remove_tile(tile_position)
		check_connect_boundary_tiles(tile_position, current_layer)
		var source = current_tile_source
		var atlas = current_tile_coords
		if use_copy:
			source = copied_tile_source_id
			atlas = copied_tile_atlas_coors
		tile_layer_nodes[current_layer].set_cell(tile_position, source, atlas, alt_tile)
	elif mode_to_use == 2:
		var terrain_id = current_terrain_id
		if use_copy:
			terrain_id = copied_tile_terrain_id
		remove_tile(tile_position)
		check_connect_boundary_tiles(tile_position, current_layer)
		BetterTerrain.set_cell(tile_layer_nodes[current_layer], tile_position, terrain_id)
	else:
		var overlapping_tile = null
		if entity_tiles[current_layer].get(tile_position) != null and current_entity_scene != null:
			overlapping_tile = entity_tiles[current_layer][tile_position]
			if overlapping_tile.scene_file_path == current_entity_scene.resource_path:
				return
		remove_tile(tile_position)
		var node: Node = null
		if use_copy and copied_node != null:
			node = copied_node.duplicate()
			var offset := Vector2i.ZERO
			var off_string = EntityIDMapper.map[EntityIDMapper.get_map_id(copied_node.scene_file_path)][1].split(",")
			offset = Vector2i(int(off_string[0]), int(off_string[1]))

			node.global_position = (tile_position * 16) + (Vector2i(8, 8) + offset)
		else:
			node = current_entity_scene.instantiate()
			node.global_position = (tile_position * 16) + (Vector2i(8, 8) + current_spawn_offset)
		node.set_meta("tile_position", tile_position)
		node.set_meta("tile_offset", current_spawn_offset)
		entity_layer_nodes[current_layer].add_child(node)
		node.reset_physics_interpolation()
		entity_tiles[current_layer].set(tile_position, node)
	BetterTerrain.update_terrain_cell(tile_layer_nodes[current_layer], tile_position, true)

func check_connect_boundary_tiles(tile_position := Vector2i.ZERO, layer := 0) -> void:
	if tile_position.y > 0:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.DOWN, 6, BOUNDARY_CONNECT_TILE)
	if tile_position.x <= -16:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.LEFT, 6, BOUNDARY_CONNECT_TILE)
	if tile_position.y > 0 and tile_position.x <= -16:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.LEFT + Vector2i.DOWN, 6, BOUNDARY_CONNECT_TILE)

func remove_tile(tile_position := Vector2i.ZERO) -> void:
	$TileCursor/Previews.hide()
	tile_layer_nodes[current_layer].set_cell(tile_position, -1)
	if entity_tiles[current_layer].get(tile_position) != null:
		if entity_tiles[current_layer].get(tile_position) is Player:
			return
		entity_tiles[current_layer].get(tile_position).queue_free()
	entity_tiles[current_layer].erase(tile_position)
	BetterTerrain.update_terrain_cell(tile_layer_nodes[current_layer], tile_position, true)

func global_position_to_tile_position(position := Vector2.ZERO) -> Vector2i:
	return Vector2i(position / 16)

func theme_selected(theme_idx := 0) -> void:
	ResourceSetterNew.cache.clear()
	AudioManager.current_level_theme = ""
	$Level.theme = Level.THEME_IDXS[theme_idx]
	Global.level_theme = $Level.theme
	Global.level_theme_changed.emit()

func time_selected(time_idx := 0) -> void:
	ResourceSetterNew.cache.clear()
	AudioManager.current_level_theme = ""
	$Level.theme_time = ["Day", "Night"][time_idx]
	Global.theme_time = ["Day", "Night"][time_idx]
	$Level/LevelBG.time_of_day = time_idx
	Global.level_theme_changed.emit()

func music_selected(music_idx := 0) -> void:
	bgm_id = music_idx

func campaign_selected(campaign_idx := 0) -> void:
	ResourceSetterNew.cache.clear()
	Global.current_campaign = ["SMB1", "SMBLL", "SMBS", "SMBANN"][campaign_idx]
	$Level.campaign = Global.current_campaign
	Global.level_theme_changed.emit()

func backscroll_toggled(new_value := false) -> void:
	$Level.can_backscroll = new_value

func height_limit_changed(new_value := 0) -> void:
	$Level.vertical_height = -new_value

func time_limit_changed(new_value := 0) -> void:
	$Level.time_limit = new_value

func low_gravity_toggled(new_value := false) -> void:
	Global.entity_gravity = 10 if new_value == false else 5
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.low_gravity = new_value

func transition_to_sublevel(sub_lvl_idx := 0) -> void:
	Global.can_pause = false
	var play_transition = playing_level
	if play_transition:
		await Global.do_fake_transition()
	else:
		level_file = $LevelSaver.save_level(level_name, level_author, level_desc, difficulty)
		LevelPersistance.reset_states()
	sub_level_id = sub_lvl_idx
	await $LevelLoader.load_level(sub_lvl_idx)
	if Settings.file.visuals.transition_animation == 0:
		Global.do_fake_transition(0.1)
	await get_tree().physics_frame
	if (play_pipe_transition or play_door_transition) and play_transition:
		parse_tiles()
		if play_pipe_transition:
			get_tree().call_group("Pipes", "run_pipe_check")
		if play_door_transition:
			get_tree().call_group("Doors", "run_door_check")
		update_music()
	PipeArea.exiting_pipe_id = -1
	Global.can_pause = true

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		%ControllerInputWarning.show()
	else:
		%ControllerInputWarning.hide()

func get_tile_properties(tile: Node) -> Array:
	var properties := []
	var old_properties := []
	if tile.get_node_or_null("EditorPropertyExposer") == null:
		return []
	
	var property_exposer: PropertyExposer = tile.get_node_or_null("EditorPropertyExposer")
	old_properties = tile.get_property_list()
	for i in old_properties:
		if property_exposer.properties.has(i.name):
			properties.append(i)
	return properties


func on_tree_exited() -> void:
	pass # Replace with function body.
