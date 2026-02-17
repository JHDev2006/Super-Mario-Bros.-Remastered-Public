class_name LevelEditor
extends Node

const CAM_MOVE_SPEED_SLOW := 128
const CAM_MOVE_SPEED_FAST := 256

var cursor_tile_position := Vector2i.ZERO

const CURSOR_OFFSET := Vector2(-8, -8)

var mode := 0
var current_entity_selector: EditorTileSelector = null
var current_entity_id := ""
var current_entity_scene: PackedScene = null
var current_tile_source := 0
var current_tile_coords := Vector2i.ZERO
var current_tile_flip := Vector2.ZERO ## 1 = true, 0 = false, x = hori, y = vert

var last_placed_position := Vector2i.ZERO

var multi_select_area := {}
var selected_area := false
var select_bounds := Rect2i()

var menu_open := false
var testing_level := false
var entity_tiles := [{}, {}, {}, {}, {}]

static var playing_level := false

var tile_list: Array[EditorTileSelector] = []

var tile_offsets := {}
var multi_select_layer := 0
var can_place := true

signal level_start

var level: Level = null

var selected_tile_index := 0

var copied_tile = null
var copied_tile_info = []

var can_move_cam := true

static var music_track_list: Array[String] = [ "res://Assets/Audio/BGM/Silence.json","res://Assets/Audio/BGM/Athletic.json", "res://Assets/Audio/BGM/Autumn.json", "res://Assets/Audio/BGM/Beach.json", "res://Assets/Audio/BGM/Bonus.json", "res://Assets/Audio/BGM/Bowser.json", "res://Assets/Audio/BGM/FinalBowser.json", "res://Assets/Audio/BGM/Castle.json", "res://Assets/Audio/BGM/CoinHeaven.json", "res://Assets/Audio/BGM/Desert.json", "res://Assets/Audio/BGM/Garden.json", "res://Assets/Audio/BGM/GhostHouse.json", "res://Assets/Audio/BGM/Jungle.json", "res://Assets/Audio/BGM/Mountain.json", "res://Assets/Audio/BGM/Overworld.json", "res://Assets/Audio/BGM/Pipeland.json", "res://Assets/Audio/BGM/BooRace.json", "res://Assets/Audio/BGM/Sky.json", "res://Assets/Audio/BGM/Snow.json", "res://Assets/Audio/BGM/Space.json", "res://Assets/Audio/BGM/Underground.json", "res://Assets/Audio/BGM/Underwater.json", "res://Assets/Audio/BGM/Volcano.json", "res://Assets/Audio/BGM/Airship.json"]
static var music_track_names: Array[String] = ["BGM_NONE", "BGM_ATHLETIC", "BGM_AUTUMN", "BGM_BEACH", "BGM_BONUS", "BGM_BOWSER", "BGM_FINALBOWSER", "BGM_CASTLE", "BGM_COINHEAVEN", "BGM_DESERT", "BGM_GARDEN", "BGM_GHOSTHOUSE", "BGM_JUNGLE", "BGM_MOUNTAIN", "BGM_OVERWORLD", "BGM_PIPELAND", "BGM_RACE", "BGM_SKY", "BGM_SNOW", "BGM_SPACE", "BGM_UNDERGROUND", "BGM_UNDERWATER", "BGM_VOLCANO", "BGM_AIRSHIP"]

enum TileType{TILE, ENTITY, TERRAIN}

var bgm_id := 0

var entity_id_map := {}

const MUSIC_TRACK_DIR := "res://Assets/Audio/BGM/"

var select_start := Vector2i.ZERO
var select_end := Vector2i.ZERO

var copied_area := {}

var area_to_save := {}

signal close_confirm(save: bool)

signal connection_node_found(new_node: Node)

var current_connection_type := SignalExposer.ConnectType.SIGNAL

var quick_connecting := false

var sub_level_id := 0

static var sub_areas: Array = [null, null, null, null, null]

const BLANK_FILE := {"Info": {}, "Levels": [{}, {}, {}, {}, {}]}

static var level_file = {"Info": {}, "Levels": [{}, {}, {}, {}, {}]}

var current_layer := 0
@onready var tile_layer_nodes: Array[TileMapLayer] = [%TileLayer1, %TileLayer2, %TileLayer3, %TileLayer4, %TileLayer5]
@onready var entity_layer_nodes := [%EntityLayer1, %EntityLayer2, %EntityLayer3, %EntityLayer4, %EntityLayer5]

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

var area_selecting := false
var multi_selecting := false

var inspect_mode := false
var inspect_menu_open := false
var current_inspect_tile: Node = null

var selection_filter := ""
var current_tile_type := TileType.TERRAIN

static var level_author := ""
static var level_desc := ""
static var level_name := ""
static var difficulty := 0

var current_terrain_id := 0

static var load_play := false

signal tile_selected(tile_selector: EditorTileSelector)

var tile_menu_open := false

signal editor_start

var pasting_area := false
var pasting_bounds := Rect2()

enum EditorState{IDLE, TILE_MENU, MODIFYING_TILE, SAVE_MENU, SELECTING_TILE_SCENE, QUITTING, PLAYTESTING, TRACK_EDITING, CONNECTING}

var current_state := EditorState.IDLE

static var play_pipe_transition := false
static var play_door_transition := false

const BOUNDARY_CONNECT_TILE := Vector2i.ZERO

var undo_redo = UndoRedo.new()

func _ready() -> void:
	$TileMenu.hide()
	entity_id_map = JSON.parse_string(FileAccess.open("res://EntityIDMap.json", FileAccess.READ).get_as_text())
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
	get_blueprints()
	load_level(0)
	await get_tree().process_frame
	Level.start_level_path = scene_file_path
	var layer_idx := 0
	for i in entity_layer_nodes:
		for x in i.get_children():
			entity_tiles[layer_idx][x.get_meta("tile_position")] = x
		layer_idx += 1
	Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.recenter_camera()
	%LevelName.text = level_name
	%LevelAuthor.text = level_author
	%Description.text = level_desc
	if Settings.file.game.editor_seen_guide == false:
		open_bindings_menu()
		Settings.file.game.editor_seen_guide = true
		Settings.save_settings()

var last_recorded_frame := Vector2.ZERO

func _physics_process(delta: float) -> void:
	%TileCursor.hide()
	if [EditorState.IDLE, EditorState.CONNECTING].has(current_state) and not cursor_in_toolbar:
		handle_tile_cursor()
	if [EditorState.IDLE, EditorState.TRACK_EDITING, EditorState.CONNECTING].has(current_state):
		handle_camera(delta)
	if is_instance_valid(%ThemeName):
		%ThemeName.text = Global.level_theme
	handle_hud()
	if Input.is_action_just_pressed("editor_open_menu"):
		if current_state == EditorState.IDLE:
			open_tile_menu()
		elif current_state == EditorState.TILE_MENU:
			close_tile_menu()
		elif current_state == EditorState.SELECTING_TILE_SCENE:
			close_tile_menu()
			current_state = EditorState.MODIFYING_TILE
			Input.flush_buffered_events()
			%TileModifierMenu.can_exit = true
	if Input.is_action_just_pressed("editor_play") and (current_state == EditorState.IDLE or current_state == EditorState.PLAYTESTING) and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		Checkpoint.passed_checkpoints.clear()
		if current_state == EditorState.PLAYTESTING:
			stop_testing()
		else:
			play_level()
	handle_player_trail()
	handle_layers()

func handle_player_trail() -> void:
	$PlayerTrail.modulate.a = int(current_state != EditorState.PLAYTESTING)
	if current_state == EditorState.PLAYTESTING:
		var target_player = get_tree().get_first_node_in_group("Players")
		if target_player == null:
			return
		var distance = last_placed_position.distance_to(target_player.global_position)
		if distance >= 32:
			record_player_frame()

func handle_hud() -> void:
	$Info.visible = not playing_level
	%Grid.modulate.a = int(not playing_level)
	%Tools.visible = not playing_level

func quit_editor() -> void:
	%QuitDialog.show()

signal level_saved

func open_tile_menu() -> void:
	$TileMenu/MarginContainer/VBoxContainer/TabButtons.show()
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

func go_back_to_menu() -> void:
	Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")

func open_bindings_menu() -> void:
	%EditorGuide.show()
	$TileMenu.hide()
	current_state = EditorState.SAVE_MENU
	await %EditorGuide.visibility_changed
	current_state = EditorState.IDLE

func open_save_dialog() -> void:
	current_state = EditorState.SAVE_MENU
	can_move_cam = false
	%SaveLevelDialog.show()
	menu_open = true

func stop_testing() -> void:
	if current_state == EditorState.IDLE:
		return
	cleanup()
	return_to_editor.call_deferred()


func cleanup() -> void:
	Global.reset_values()
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
		Global.time = level.time_limit
	elif Level.can_set_time and playing_level:
		Global.time = level.time_limit
	Global.can_time_tick = playing_level

func update_music() -> void:
	if music_track_list[bgm_id] != "":
		level.music = load(music_track_list[bgm_id].replace(".remap", ""))
		print(level.music)
	else:
		level.music = null

func play_level() -> void:
	clear_trail()
	current_state = EditorState.PLAYTESTING
	$TileMenu.hide()
	menu_open = false
	update_music()
	reset_values_for_play()
	%Camera.enabled = false
	level.apply_resolution_enforcement()
	level.inf_time_check()
	level_start.emit()
	if gizmos_visible == false:
		get_tree().call_group("Gizmos", "hide")
	get_tree().call_group("Players", "editor_level_start")
	save_current_level()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	handle_hud()
	$TrailTimer.start()

func return_to_editor() -> void:
	current_state = EditorState.IDLE
	AudioManager.stop_all_music()
	level.music = null
	%Camera.global_position = get_viewport().get_camera_2d().get_screen_center_position()
	%Camera.reset_physics_interpolation()
	load_level(sub_level_id)
	get_tree().call_group("Gizmos", "show")
	%Camera.enabled = true
	%Camera.make_current()
	editor_start.emit()
	level.process_mode = Node.PROCESS_MODE_DISABLED
	handle_hud()

var zoom := 1.0

func handle_camera(delta: float) -> void:
	var input_vector = Input.get_vector("editor_cam_left", "editor_cam_right", "editor_cam_up", "editor_cam_down")
	%Camera.global_position += input_vector * (CAM_MOVE_SPEED_FAST if Input.is_action_pressed("editor_cam_fast") else CAM_MOVE_SPEED_SLOW) * delta
	%Camera.global_position.y = clamp(%Camera.global_position.y, level.vertical_height + ((get_viewport().get_visible_rect().size.y / 2) * %Camera.zoom.y) / %Camera.zoom.y, 32 - (get_viewport().get_visible_rect().size.y / 2))
	%Camera.global_position.x = clamp(%Camera.global_position.x, -256 + (get_viewport().get_visible_rect().size.x / 2), INF)

func handle_layers() -> void:
	if Input.is_action_just_pressed("layer_up"):
		current_layer += 1
	if Input.is_action_just_pressed("layer_down"):
		current_layer -= 1
	current_layer = clamp(current_layer, 0, entity_layer_nodes.size() - 1)
	var idx := 0
	for i in entity_layer_nodes:
		i.z_index = 0 if current_layer == idx or playing_level else -1
		i.modulate = Color(1, 1, 1, 1) if current_layer == idx or playing_level else Color(1, 1, 1, 0.5)
		tile_layer_nodes[idx].modulate = i.modulate
		tile_layer_nodes[idx].z_index = i.z_index - 1
		%LayerDisplay.get_child(idx).modulate = Color.WHITE if current_layer == idx else Color(0.1, 0.1, 0.1, 0.5)
		idx += 1
	if current_state != EditorState.PLAYTESTING:
		for i in entity_tiles:
			for x in i.keys():
				if is_instance_valid(i[x]) == false: continue
				i[x].modulate = Color.WHITE if i[x].has_node("SignalExposer") and i[x].get_node("SignalExposer").can_input or %TileModifierMenu.editing_node == i[x] or current_state != EditorState.CONNECTING or current_connection_type == SignalExposer.ConnectType.REFERENCE else Color.DIM_GRAY
		for i in tile_layer_nodes:
			i.self_modulate = Color.WHITE if current_state != EditorState.CONNECTING else Color.DIM_GRAY
		level.get_node("LevelBG").modulate = Color.WHITE if current_state != EditorState.CONNECTING else Color.DIM_GRAY
	%LayerLabel.text = tr("EDITOR_HUD_LAYER").replace("{LAYER}", str(current_layer + 1))

func save_level() -> void:
	level_author = %LevelAuthor.text
	level_desc = %Description.text
	level_name = %LevelName.text
	difficulty = %DifficultySlider.value
	var file_name = level_name.to_pascal_case() + ".lvl"
	%SaveLevelDialog.hide()
	menu_open = false
	save_current_level()
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
	%TileCursor.show()
	var target_mouse_icon = null
	var snapped_position = ((%TileCursor.get_global_mouse_position() - CURSOR_OFFSET).snapped(Vector2(16, 16))) + CURSOR_OFFSET
	%TileCursor.global_position = (snapped_position)
	var old_index := selected_tile_index
	var tile_position = global_position_to_tile_position(snapped_position + Vector2(-8, -8))
	tile_position.y = clamp(tile_position.y, -30, 1)
	tile_position.x = clamp(tile_position.x, -16, INF)
	cursor_tile_position = tile_position
	%AreaPlacePreview.visible = pasting_area
	%AreaPlacePreview.size = (pasting_bounds.size + Vector2(1, 1)) * 16
	var offset = Vector2.ZERO
	if pasting_area:
		if int(pasting_bounds.size.x) % 2 == 1:
			offset.x = 8
		if int(pasting_bounds.size.y) % 2 == 1:
			offset.y = 8
	if Input.is_action_just_released("mb_left"):
		can_place = true
	%AreaPlacePreview.global_position = ((snapped_position) - (%AreaPlacePreview.size / 2)) + offset
	inspect_mode = Input.is_action_pressed("editor_inspect") and not area_selecting and not multi_selecting
	if inspect_mode and current_state == EditorState.IDLE:
		handle_inspection(tile_position)
		if current_inspect_tile == null:
			Input.set_custom_mouse_cursor(CURSOR_INSPECT)
		else:
			Input.set_custom_mouse_cursor(null)
		return
	if current_state == EditorState.IDLE:
		if Input.is_action_pressed("mb_left"):
			if (Input.is_action_pressed("editor_select")) and not area_selecting:
				area_select_start(tile_position)
			elif Input.is_action_pressed("multi_select") and (not multi_selecting or selected_area):
				multi_select_start(tile_position)
			elif Input.is_action_pressed("editor_select") == false and Input.is_action_pressed("multi_select") == false:
				area_selecting = false
				multi_select_start()
				multi_selecting = false
				if pasting_area:
					paste_area(tile_position, copied_area.duplicate_deep(), current_layer, pasting_bounds, true)
				elif can_place:
					match current_tile_type:
						TileType.TILE:
							place_tile(tile_position, current_layer, current_tile_coords, [current_tile_source])
						TileType.ENTITY:
							place_tile(tile_position, current_layer, current_entity_id)
						TileType.TERRAIN:
							place_tile(tile_position, current_layer, current_terrain_id)
					target_mouse_icon = (CURSOR_PENCIL)
			
		if Input.is_action_pressed("mb_right"):
			if Input.is_action_pressed("editor_select") and not area_selecting:
				area_select_start(tile_position)
				target_mouse_icon = (CURSOR_RULER)
			elif Input.is_action_pressed("editor_select") == false:
				area_selecting = false
				multi_select_start()
				multi_selecting = false
				remove_tile(tile_position)
				target_mouse_icon = (CURSOR_ERASOR)
			elif not area_selecting and not multi_selecting:
				multi_select_start()
				multi_selecting = false
		
		if Input.is_action_just_pressed("scroll_up"):
			selected_tile_index -= 1
		if Input.is_action_just_pressed("scroll_down"):
			selected_tile_index += 1

		if Input.is_action_just_pressed("ui_copy") and pasting_area == false:
			copy_tile(tile_position, current_layer)
		elif Input.is_action_just_pressed("ui_cut") and pasting_area == false:
			copy_tile(tile_position, current_layer)
			remove_tile(tile_position, current_layer)
		elif Input.is_action_pressed("ui_paste"):
			if copied_tile != null:
				pasting_area = false
				place_tile(tile_position, current_layer, copied_tile, copied_tile_info)
			elif copied_area != {}:
				copied_tile = null
				pasting_area = true
	
		if Input.is_action_just_pressed("pick_tile"):
			pick_tile(tile_position)
	
		if Input.is_action_just_pressed("ui_undo"):
			undo()
		
		if Input.is_action_just_pressed("ui_redo"):
			redo()
	
	if current_state == EditorState.CONNECTING:
		if Input.is_action_just_pressed("mb_left"):
			if entity_tiles[current_layer].has(tile_position):
				if entity_tiles[current_layer][tile_position].get_node_or_null("SignalExposer") != null:
					if entity_tiles[current_layer][tile_position].get_node("SignalExposer").can_input:
						connection_node_found.emit(entity_tiles[current_layer][tile_position])
						current_state = EditorState.MODIFYING_TILE
		if Input.is_action_just_pressed("mb_right") or Input.is_action_just_pressed("editor_open_menu"):
			%TileModifierMenu.cancel_connection()
	
	if not multi_selecting:
		handle_area_selecting(tile_position)
		if area_selecting:
			target_mouse_icon = CURSOR_RULER
	if not area_selecting:
		handle_multi_selecting(tile_position)
		if multi_selecting:
			target_mouse_icon = CURSOR_RULER
	if old_index != selected_tile_index:
		selected_tile_index = wrap(selected_tile_index, 0, tile_list.size())
		on_tile_selected(tile_list[selected_tile_index])
		show_scroll_preview()
	
	if current_state == EditorState.IDLE:
		if Input.is_action_just_pressed("quick_connect"):
			if entity_tiles[current_layer].get(tile_position) != null:
				if entity_tiles[current_layer][tile_position].has_node("SignalExposer"):
					if entity_tiles[current_layer][tile_position].get_node("SignalExposer").can_output:
						quick_connecting = true
						%TileModifierMenu.editing_node = entity_tiles[current_layer][tile_position]
						%TileModifierMenu.begin_signal_connection()
	Input.set_custom_mouse_cursor(target_mouse_icon)


func paste_area(tile_position := Vector2i.ZERO, area := copied_area, layer_num := current_layer, bounds := pasting_bounds, save_action := true) -> void:
	var corner = tile_position - Vector2i(bounds.size / 2)
	var old_area = save_area(corner, corner, corner + Vector2i(bounds.size), layer_num)
	replace_area(corner, current_layer, area, false)
	pasting_area = false
	can_place = false
	if save_action:
		undo_redo.create_action("Paste Area")
		undo_redo.add_do_method(paste_area.bind(tile_position, area.duplicate_deep(), layer_num, bounds, false))
		undo_redo.add_undo_method(replace_area.bind(corner, layer_num, old_area.duplicate_deep()))
		undo_redo.commit_action(false)

func pick_tile(tile_position := Vector2i.ZERO) -> void:
	var tile = null
	if entity_tiles[current_layer].has(tile_position):
		tile = entity_tiles[current_layer][tile_position]
		if tile is Player:
			return
		current_tile_type = TileType.ENTITY
		current_entity_id = tile.get_meta("ID")
	elif tile_layer_nodes[current_layer].get_used_cells().has(tile_position):
		var terrain_id := BetterTerrain.get_cell(tile_layer_nodes[current_layer], tile_position)
		if terrain_id >= 0:
			current_tile_type = TileType.TERRAIN
			current_terrain_id = terrain_id
		else:
			current_tile_type = TileType.TILE
			current_tile_coords = tile_layer_nodes[current_layer].get_cell_atlas_coords(tile_position)
			current_tile_source = tile_layer_nodes[current_layer].get_cell_source_id(tile_position)

func handle_inspection(tile_position := Vector2i.ZERO) -> void:
	if Input.is_action_just_pressed("mb_left"):
		if entity_tiles[current_layer].get(tile_position) != null:
			open_tile_properties(entity_tiles[current_layer][tile_position])

func open_tile_properties(tile: Node2D) -> void:
	var properties = get_tile_properties(tile)
	var has_connection = tile_has_signal(tile)
	if has_connection == false and properties.is_empty():
		return
	
	current_inspect_tile = tile
	if properties.is_empty() == false:
		%TileModifierMenu.override_scenes = tile.get_node("EditorPropertyExposer").properties_force_selector
		%TileModifierMenu.properties = properties
	%TileModifierMenu.has_connection = has_connection
	%TileModifierMenu.editing_node = current_inspect_tile
	%TileModifierMenu.open()
	current_state = EditorState.MODIFYING_TILE
	await get_tree().process_frame
	%TileModifierMenu.update_minimum_size()
	%TileModifierMenu.position = tile.get_global_transform_with_canvas().origin - Vector2(tile.get_meta("tile_offset", Vector2i.ZERO))
	%TileModifierMenu.position.x = clamp(%TileModifierMenu.position.x, 0, get_viewport().get_visible_rect().size.x - %TileModifierMenu.size.x - 2)
	%TileModifierMenu.position.y = clamp(%TileModifierMenu.position.y, 0, get_viewport().get_visible_rect().size.y - %TileModifierMenu.size.y - 2)

func area_select_start(tile_position := Vector2i.ZERO) -> void:
	select_start = tile_position
	area_selecting = true
	multi_select_start(tile_position)
	multi_selecting = false

func handle_area_selecting(tile_position := Vector2i.ZERO) -> void:
	select_end = tile_position
	%AreaSelectRect.visible = area_selecting
	var top_corner := select_start
	if select_start.x > select_end.x:
		top_corner.x = select_end.x
	if select_start.y > select_end.y:
		top_corner.y = select_end.y
	%AreaSelectRect.global_position = top_corner * 16
	%AreaSelectRect.size = abs(select_end - select_start) * 16 + Vector2i(16, 16)
	if area_selecting:
		if Input.is_action_just_released("mb_left"): 
			match current_tile_type:
				TileType.TILE:
					mass_place(top_corner, select_start, select_end, current_layer, current_tile_coords, [current_tile_source])
				TileType.ENTITY:
					mass_place(top_corner, select_start, select_end, current_layer, current_entity_id)
				TileType.TERRAIN:
					mass_place(top_corner, select_start, select_end, current_layer, current_terrain_id)
			area_selecting = false
		if Input.is_action_just_released("mb_right"): 
			mass_remove(top_corner, select_start, select_end)
			area_selecting = false

func multi_select_start(tile_position := Vector2i.ZERO) -> void:
	select_start = tile_position
	multi_selecting = true
	selected_area = false
	select_bounds = Rect2i()
	multi_select_area = {}

func handle_multi_selecting(tile_position := Vector2i.ZERO) -> void:
	if selected_area == false:
		select_end = tile_position
	%MultiSelectRect.visible = multi_selecting and selected_area == false
	%SelectedAreaRect.visible = selected_area
	var top_corner := select_start
	if select_start.x > select_end.x:
		top_corner.x = select_end.x
	if select_start.y > select_end.y:
		top_corner.y = select_end.y
	if selected_area == false:
		%MultiSelectRect.global_position = top_corner * 16
		%MultiSelectRect.size = abs(select_end - select_start) * 16 + Vector2i(16, 16)
	else:
		%SelectedAreaRect.global_position = select_bounds.position * 16
		%SelectedAreaRect.size = select_bounds.size * 16 + Vector2i(16, 16)
		if Input.is_action_just_pressed("editor_copy") or Input.is_action_just_pressed("editor_cut"):
			copied_tile = null
			top_corner = select_bounds.position
			select_start = top_corner
			select_end = select_start + select_bounds.size
			pasting_bounds = get_area_bounds(top_corner, select_start, select_end, multi_select_layer)
			copied_area = save_area(top_corner, select_start, select_end, multi_select_layer)
			multi_selecting = false
			selected_area = false
			if Input.is_action_just_pressed("editor_cut"):
				mass_remove(top_corner, select_start, select_end, multi_select_layer)
				Global.log_comment("Area Cut!")
			else:
				Global.log_comment("Area Copied!")
		if Input.is_action_just_pressed("editor_save"):
			top_corner = select_bounds.position
			select_start = top_corner
			select_end = select_start + select_bounds.size
			area_to_save = save_area(top_corner, select_start, select_end, multi_select_layer)
			%SaveBlueprint.show()
			current_state = EditorState.SAVE_MENU
	if multi_selecting:
		if Input.is_action_just_released("mb_left"): 
			selected_area = false
			if is_tile_in_area(top_corner, select_start, select_end, current_layer):
				select_bounds = get_area_bounds(top_corner, select_start, select_end, multi_select_layer)
				multi_select_area = save_area(top_corner, select_start, select_end, current_layer)
				selected_area = true
				multi_select_layer = current_layer
				print(multi_select_layer)
				select_bounds = get_area_bounds(top_corner, select_start, select_end, multi_select_layer)
			else:
				multi_select_start()
				multi_selecting = false

func mass_place(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer, thing_to_place = null, info := [], save_action := true) -> void:
	var area = save_area(top_corner, select_start, select_end, layer_num)
	var position := Vector2i.ZERO
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			position = top_corner + Vector2i(x, y)
			place_tile(position, layer_num, thing_to_place, info, false)
	if save_action:
		undo_redo.create_action("Mass Place")
		undo_redo.add_do_method(mass_place.bind(top_corner, select_start, select_end, layer_num, thing_to_place, info, false))
		undo_redo.add_undo_method(replace_area.bind(top_corner, layer_num, area))
		undo_redo.commit_action(false)

func mass_remove(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer, save_action := true) -> void:
	var area := {}
	if save_action:
		area = save_area(top_corner, select_start, select_end, layer_num)
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			var position = top_corner + Vector2i(x, y)
			remove_tile(position, layer_num, false)
	if save_action:
		undo_redo.create_action("Mass Remove")
		undo_redo.add_do_method(mass_remove.bind(top_corner, select_start, select_end, layer_num, false))
		undo_redo.add_undo_method(replace_area.bind(top_corner, layer_num, area))
		undo_redo.commit_action(false)

func get_area_bounds(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer) -> Rect2i:
	
	var smallest_x := 99999
	var smallest_y := 99999
	var largest_x := -1
	var largest_y := -1
	
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			var position = top_corner + Vector2i(x, y)
			var tile = null
			if entity_tiles[layer_num].get(position, null) != null:
				if tile is not Player:
					tile = Vector2i(x, y)
			elif tile_layer_nodes[layer_num].get_used_cells().has(position):
				tile = Vector2i(x, y)
			if tile != null:
				if tile.x > largest_x:
					largest_x = tile.x
				if tile.y > largest_y:
					largest_y = tile.y
				if tile.x < smallest_x:
					smallest_x = tile.x
				if tile.y < smallest_y:
					smallest_y = tile.y
	return Rect2i(top_corner.x + smallest_x, top_corner.y + smallest_y, abs(smallest_x - largest_x), abs(smallest_y - largest_y))

func copy_tile(tile_position := Vector2i.ZERO, layer_num := current_layer) -> void:
	copied_node = null
	copied_tile_info = []
	if entity_tiles[layer_num].has(tile_position):
		copied_tile = entity_tiles[layer_num][tile_position].duplicate()
		if copied_tile.has_node("SignalExposer"):
			copied_tile.get_node("SignalExposer").connections.clear()
		copied_tile_info = [copied_tile.get_meta("tile_offset")]
	elif tile_layer_nodes[layer_num].get_used_cells().has(tile_position):
		if BetterTerrain.get_cell(tile_layer_nodes[layer_num], tile_position) >= 0:
			copied_tile = BetterTerrain.get_cell(tile_layer_nodes[layer_num], tile_position)
		else:
			copied_tile = tile_layer_nodes[layer_num].get_cell_atlas_coords(tile_position)
			copied_tile_info = [tile_layer_nodes[layer_num].get_cell_source_id(tile_position)]
	if copied_node != null:
		copied_area = {}
func replace_area(top_corner := Vector2i.ZERO, layer_num := current_layer, area := {}, delete_empty := true) -> void:
	if delete_empty:
		for i in area["Empty"].split("="):
			var decode = i.split(",", false)
			if decode.is_empty() == false:
				var position = top_corner + Vector2i(int(decode[0]), int(decode[1]))
				remove_tile(position, layer_num, false)
	for i in area["Tiles"].split("="):
		var decode = i.split(",", false)
		if decode.is_empty() == false:
			var position = top_corner + Vector2i(int(decode[0]), int(decode[1]))
			var source_id = int(decode[2])
			var atlas_coords = Vector2i(int(decode[3]), int(decode[4]))
			place_tile(position, layer_num, atlas_coords, [source_id], false)
			BetterTerrain.update_terrain_cell(tile_layer_nodes[layer_num], position, true)
	for i in area["Entities"].split("="):
		var decode = i.split(",", false)
		if decode.is_empty() == false:
			var position = top_corner + Vector2i(int(decode[0]), int(decode[1]))
			var entity_id = decode[2]
			if decode.size() > 3:
				var idx := 3
				var entity_string := "0,0,"
				for x in decode.size() - 3:
					entity_string += decode[idx] + ","
					idx += 1
				place_tile(position, layer_num, entity_id, [entity_string], false)
			else:
				place_tile(position, layer_num, entity_id, [], false)
	for i in area["Connections"].split("="):
		var decode = i.split(",", false)
		if decode.is_empty():
			continue
		var true_source_position = top_corner + Vector2i(int(decode[0]), int(decode[1]))
		var true_target_position = top_corner + Vector2i(int(decode[2]), int(decode[3]))
		var source = entity_tiles[layer_num][true_source_position]
		source.get_node("SignalExposer").connections.append([layer_num, true_target_position])

func save_area(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer) -> Dictionary:
	var dict := {"Tiles": "", "Entities": "", "Connections": "", "Empty": "", "Size": "0,0"}
	var entities := []
	var bounds := get_area_bounds(top_corner, select_start, select_end, layer_num)
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			var position = top_corner + Vector2i(x, y)
			if entity_tiles[layer_num].get(position, null) != null:
				entities.append(entity_tiles[layer_num].get(position))
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			var position = top_corner + Vector2i(x, y)
			if entity_tiles[layer_num].get(position, null) != null:
				var entity_tile = entity_tiles[layer_num].get(position)
				if entity_tile is Player:
					continue
				var entity_string = str(x) + "," + str(y) + "," + EntityIDMapper.get_map_id(entity_tile.scene_file_path)
				if entity_tile.has_node("EditorPropertyExposer"):
					entity_string += entity_tile.get_node("EditorPropertyExposer").get_string()
				if entity_tile.has_node("SignalExposer"):
					var connection_string := ""
					for i in entity_tile.get_node("SignalExposer").connections:
						var target_entity = entity_tiles[i[0]].get(Vector2i(i[1].x, i[1].y))
						var local_position = position - top_corner
						var local_target_position = abs(Vector2i(i[1].x, i[1].y) - top_corner)
						if entities.has(target_entity):
							connection_string += (str(local_position.x) + "," + str(local_position.y) + "," + str(local_target_position.x) + "," + str(local_target_position.y) + "=")
					if connection_string != "":
						dict["Connections"] += connection_string
				dict["Entities"] += entity_string + "="
			elif tile_layer_nodes[layer_num].get_used_cells().has(position):
				var local_position = abs(position - top_corner)
				var atlas_position = tile_layer_nodes[layer_num].get_cell_atlas_coords(position)
				var tile_string = str(local_position.x) + "," + str(local_position.y) + "," + str(tile_layer_nodes[layer_num].get_cell_source_id(position)) + "," + str(atlas_position.x) + "," + str(atlas_position.y) + "="
				dict["Tiles"] += tile_string
			else:
				var local_position = abs(position - top_corner)
				dict["Empty"] += str(local_position.x) + "," + str(local_position.y) + "="
	dict["Size"] = str(bounds.size.x) + "," + str(bounds.size.y)
	print(dict)
	return dict

func is_tile_in_area(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer) -> bool:
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			var position = top_corner + Vector2i(x, y)
			if entity_tiles[layer_num].get(position, null) != null:
				return true
			elif tile_layer_nodes[layer_num].get_used_cells().has(position):
				return true
	return false

func show_scroll_preview() -> void:
	$TileCursor/Previews.show()
	for i in [$"TileCursor/Previews/-3", $"TileCursor/Previews/-2", $"TileCursor/Previews/-1", $"TileCursor/Previews/0", $"TileCursor/Previews/1", $"TileCursor/Previews/2", $"TileCursor/Previews/3"]:
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
	for i in [$TileMenu/MarginContainer/VBoxContainer/PanelContainer/TILES, $TileMenu/MarginContainer/VBoxContainer/PanelContainer/LEVEL, $TileMenu/MarginContainer/VBoxContainer/PanelContainer/BG, $TileMenu/MarginContainer/VBoxContainer/PanelContainer/Blueprints]:
		i.hide()
	$TileMenu/MarginContainer/VBoxContainer/PanelContainer/TILES.show()
	$TileMenu/MarginContainer/VBoxContainer/TabButtons.hide()
	current_state = EditorState.SELECTING_TILE_SCENE
	selection_filter = selector.editing_node.get_node("EditorPropertyExposer").filters[selector.tile_property_name]
	for i in get_tree().get_nodes_in_group("Selectors"):
		i.disabled = !i.has_meta(selection_filter) and selection_filter != ""
		i.update_visuals()
	var old_scene = current_entity_scene
	await tile_selected
	if is_instance_valid(selector) == false:
		return
	selector.set_scene(current_entity_selector)
	current_entity_scene = old_scene
	close_tile_menu()
	current_state = EditorState.MODIFYING_TILE

func start_signal_connection(node: Node, connection_type := SignalExposer.ConnectType.SIGNAL) -> void:
	current_state = LevelEditor.EditorState.CONNECTING
	current_connection_type = connection_type

func on_tile_selected(selector: EditorTileSelector) -> void:
	current_tile_type = selector.type
	current_entity_selector = selector
	selected_tile_index = tile_list.find(selector)
	if selector.type == 1:
		current_entity_id = selector.entity_id
		current_entity_scene = load(entity_id_map[current_entity_id][0])
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

func place_tile(tile_position := Vector2i.ZERO, layer_num := current_layer, tile_to_place = null, info := [], save_action := true) -> void:
	$TileCursor/Previews.hide()
	var old_tile = null
	var old_tile_info = []
	if entity_tiles[layer_num].get(tile_position) != null:
		var overlapping_tile = entity_tiles[layer_num][tile_position]
		if overlapping_tile is Player:
			return
		old_tile = overlapping_tile.duplicate()
		old_tile_info = [overlapping_tile.get_meta("tile_offset"), overlapping_tile.get_meta("ID", "")]
	elif BetterTerrain.get_cell(tile_layer_nodes[layer_num], tile_position) >= 0:
		old_tile = BetterTerrain.get_cell(tile_layer_nodes[layer_num], tile_position)
		print(old_tile)
	elif tile_layer_nodes[layer_num].get_used_cells().has(tile_position):
		old_tile = tile_layer_nodes[layer_num].get_cell_atlas_coords(tile_position)
		old_tile_info = [tile_layer_nodes[layer_num].get_cell_source_id(tile_position)]
	
	if tile_to_place is Vector2i:
		var alt_tile := 0
		if current_tile_flip.x != 0:
			alt_tile += TileSetAtlasSource.TRANSFORM_FLIP_H
		if current_tile_flip.y != 0:
			alt_tile += TileSetAtlasSource.TRANSFORM_FLIP_V
		var source = info[0]
		var atlas = tile_to_place
		if old_tile is Vector2i:
			if old_tile == atlas and old_tile_info == info:
				return
		remove_tile(tile_position, layer_num, false)
		check_connect_boundary_tiles(tile_position, layer_num)
		tile_layer_nodes[layer_num].set_cell(tile_position, source, atlas, alt_tile)
	elif tile_to_place is int:
		var terrain_id = tile_to_place
		print(old_tile)
		if old_tile is int:
			if old_tile == terrain_id:
				return
		remove_tile(tile_position, layer_num, false)
		check_connect_boundary_tiles(tile_position, layer_num)
		BetterTerrain.set_cell(tile_layer_nodes[layer_num], tile_position, terrain_id)
	elif tile_to_place is String:
		var node: Node = null
		if old_tile != null and old_tile is Node:
			if old_tile.get_meta("ID", "") == tile_to_place:
				return 
		remove_tile(tile_position, layer_num, false)
		current_entity_scene = load(entity_id_map[tile_to_place][0])
		node = current_entity_scene.instantiate()
		if node.has_node("AmountLimiter"):
			if node.get_node("AmountLimiter").run_check(get_tree()):
				node.queue_free()
				Global.log_error("Only one of these is allowed in a room at a time!", false)
				return
		var spawn_offset := Vector2i.ZERO
		var split = entity_id_map[tile_to_place][1].split(",")
		spawn_offset = Vector2i(int(split[0]), int(split[1]))
		node.global_position = (tile_position * 16) + (Vector2i(8, 8) + spawn_offset)
		node.set_meta("tile_position", tile_position)
		node.set_meta("ID", tile_to_place)
		node.set_meta("layer", layer_num)
		node.set_meta("tile_offset", spawn_offset)
		entity_layer_nodes[layer_num].add_child(node)
		node.reset_physics_interpolation()
		entity_tiles[layer_num].set(tile_position, node)
		if info.is_empty() == false and node.has_node("EditorPropertyExposer"):
			node.get_node("EditorPropertyExposer").apply_string(info[0])
	elif tile_to_place is Node:
		tile_to_place = tile_to_place.duplicate()
		var spawn_offset := Vector2i.ZERO
		tile_to_place.set_meta("tile_position", tile_position)
		tile_to_place.set_meta("layer", layer_num)
		if info.size() > 0:
			spawn_offset = info[0]
		tile_to_place.global_position = (tile_position * 16) + (Vector2i(8, 8) + spawn_offset)
		if entity_tiles[layer_num].get(tile_position) != null:
			var overlapping_tile = entity_tiles[layer_num][tile_position]
			if overlapping_tile.get_meta("ID", "") == tile_to_place.get_meta("ID", ""):
				return
		remove_tile(tile_position, layer_num, save_action)
		entity_layer_nodes[layer_num].add_child(tile_to_place)
		entity_tiles[layer_num].set(tile_position, tile_to_place)
	
	if save_action:
		undo_redo.create_action("Place Tile")
		undo_redo.add_do_method(place_tile.bind(tile_position, layer_num, tile_to_place, info, false))
		if old_tile == null:
			undo_redo.add_undo_method(remove_tile.bind(tile_position, layer_num, false))
		else:
			undo_redo.add_undo_method(place_tile.bind(tile_position, layer_num, old_tile, old_tile_info, false))
		undo_redo.commit_action(false)

	BetterTerrain.update_terrain_cell(tile_layer_nodes[layer_num], tile_position, true)

func check_connect_boundary_tiles(tile_position := Vector2i.ZERO, layer := 0) -> void:
	if tile_position.y > 0:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.DOWN, 6, BOUNDARY_CONNECT_TILE)
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.DOWN + Vector2i.LEFT, 6, BOUNDARY_CONNECT_TILE)
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.DOWN + Vector2i.RIGHT, 6, BOUNDARY_CONNECT_TILE)
	if tile_position.x <= -16:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.LEFT, 6, BOUNDARY_CONNECT_TILE)
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.LEFT + Vector2i.UP, 6, BOUNDARY_CONNECT_TILE)
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.LEFT + Vector2i.DOWN, 6, BOUNDARY_CONNECT_TILE)

func remove_tile(tile_position := Vector2i.ZERO, layer_num := current_layer, save_action := true) -> bool:
	$TileCursor/Previews.hide()
	var old_tile = null
	var info := []
	if entity_tiles[layer_num].get(tile_position) != null:
		if entity_tiles[layer_num].get(tile_position) is Player:
			return false
		if save_action:
			old_tile = entity_tiles[layer_num].get(tile_position).duplicate()
			info = [old_tile.get_meta("tile_offset")]
		entity_tiles[layer_num].get(tile_position).queue_free()
	elif tile_layer_nodes[layer_num].get_used_cells().has(tile_position) and save_action:
		if BetterTerrain.get_cell(tile_layer_nodes[layer_num], tile_position) >= 0:
			old_tile = BetterTerrain.get_cell(tile_layer_nodes[layer_num], tile_position)
		else:
			old_tile = tile_layer_nodes[layer_num].get_cell_atlas_coords(tile_position)
			info = [tile_layer_nodes[layer_num].get_cell_source_id(tile_position)]
	entity_tiles[layer_num].erase(tile_position)
	tile_layer_nodes[layer_num].set_cell(tile_position, -1)
	BetterTerrain.update_terrain_cell(tile_layer_nodes[layer_num], tile_position, true)
	if save_action and old_tile != null:
		undo_redo.create_action("Remove Tile")
		undo_redo.add_do_method(remove_tile.bind(tile_position, layer_num, false))
		undo_redo.add_undo_method(place_tile.bind(tile_position, layer_num, old_tile, info, false))
		undo_redo.commit_action(false)
	return old_tile != null

func global_position_to_tile_position(position := Vector2.ZERO) -> Vector2i:
	return Vector2i(position / 16)

func theme_selected(theme_idx := 0) -> void:
	ResourceSetterNew.clear_cache()
	AudioManager.current_level_theme = ""
	$Level.theme = Level.THEME_IDXS[theme_idx]
	Global.level_theme = $Level.theme
	Global.update_theme()

func time_selected(time_idx := 0) -> void:
	ResourceSetterNew.clear_cache()
	AudioManager.current_level_theme = ""
	level.theme_time = ["Day", "Night"][time_idx]
	Global.theme_time = ["Day", "Night"][time_idx]
	level.get_node("LevelBG").time_of_day = time_idx
	Global.update_theme()

func music_selected(music_idx := 0) -> void:
	bgm_id = music_idx

func campaign_selected(campaign_idx := 0) -> void:
	ResourceSetterNew.clear_cache()
	Global.current_campaign = ["SMB1", "SMBLL", "SMBS", "SMBANN"][campaign_idx]
	level.campaign = Global.current_campaign
	Global.update_theme()

func backscroll_toggled(new_value := false) -> void:
	level.can_backscroll = new_value

func height_limit_changed(new_value := 0) -> void:
	level.vertical_height = -new_value

func time_limit_changed(new_value := 0) -> void:
	level.time_limit = new_value

func res_enforce_changed(new_value := false) -> void:
	if new_value:
		level.enforce_resolution = get_viewport().get_visible_rect().size
	else:
		level.enforce_resolution = Vector2.ZERO

func low_gravity_toggled(new_value := false) -> void:
	Global.entity_gravity = 10 if new_value == false else 5
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.low_gravity = new_value

func transition_to_sublevel(sub_lvl_idx := 0) -> void:
	clear_trail()
	undo_redo.clear_history()
	Global.can_pause = false
	if Global.level_editor_is_playtesting():
		Global.do_fake_transition()
		for i in 2:
			await get_tree().physics_frame
	else:
		save_current_level()
		Global.reset_values()
		PipeArea.exiting_pipe_id = -1
	load_level(sub_lvl_idx)
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

func tile_has_signal(tile: Node) -> bool:
	if tile.has_node("SignalExposer"):
		return tile.get_node("SignalExposer").can_output
	return false

const CUSTOM_LEVEL_BASE = ("res://Scenes/Levels/CustomLevelBase.tscn")

func save_current_level() -> void:
	var saved_level = level.duplicate()
	if music_track_list[bgm_id] != "":
		saved_level.music = load(music_track_list[bgm_id].replace(".remap", ""))
	else:
		saved_level.music = null
	sub_areas[sub_level_id] = saved_level.duplicate()

func load_level(level_id := 0) -> void:
	var node = sub_areas[level_id]
	if node == null:
		node = load(CUSTOM_LEVEL_BASE).instantiate()
		node.sublevel_id = level_id
	elif node is PackedScene:
		node = node.instantiate()
	if level != null:
		level.queue_free()
	add_child(node)
	level = node
	sub_level_id = level_id
	update_references()
	reload_entity_tiles()
	if Global.level_editor_is_playtesting() == false:
		node.music = null
		node.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	else:
		save_current_level()
		node.process_mode = ProcessMode.PROCESS_MODE_PAUSABLE
		get_tree().call_group("Players", "editor_level_start")

func convert_scenes_to_nodes() -> void:
	pass

func reload_entity_tiles() -> void:
	entity_tiles = [{}, {}, {}, {}, {}]
	var layer_idx := 0
	for layer in entity_layer_nodes:
		for child in layer.get_children():
			entity_tiles[layer_idx][child.get_meta("tile_position")] = child
		layer_idx += 1

func update_references() -> void:
	entity_layer_nodes = [level.get_node("EntityLayer1"), level.get_node("EntityLayer2"), level.get_node("EntityLayer3"), level.get_node("EntityLayer4"), level.get_node("EntityLayer5")]
	tile_layer_nodes = [level.get_node("TileLayer1"), level.get_node("TileLayer2"), level.get_node("TileLayer3"), level.get_node("TileLayer4"), level.get_node("TileLayer5")]
	if level.music != null:
		bgm_id = music_track_list.find(level.music.resource_path)
	update_menu_values()

func update_menu_values() -> void:
	%ThemeTime.selected = ["Day", "Night"].find(level.theme_time)
	if level.music != null:
		%LevelMusic.selected = bgm_id
	else:
		%LevelMusic.selected = 0
	%Campaign.selected = Global.CAMPAIGNS.find(level.campaign)
	%BackScroll.set_pressed_no_signal(level.can_backscroll)
	%HeightLimit.value = abs(level.vertical_height)
	%TimeLimit.value = level.time_limit
	%SubLevelID.selected = sub_level_id
	
	var level_bg: LevelBG = level.get_node("LevelBG")
	%SecondLayerOrder.selected = level_bg.second_layer_order
	%PrimaryLayer.selected = level_bg.primary_layer
	%SecondLayer.selected = level_bg.second_layer
	%Particles.selected = level_bg.particles
	%LiquidLayer.selected = level_bg.liquid_layer
	%OverlayClouds.set_pressed_no_signal(level_bg.overlay_clouds)

func set_bg_value(value := 0, value_name := "") -> void:
	level.get_node("LevelBG").set(value_name, value)
	level.get_node("LevelBG").update_visuals()

func on_tree_exited() -> void:
	Input.set_custom_mouse_cursor(null)


var cursor_in_toolbar := false

func on_mouse_entered() -> void:
	cursor_in_toolbar = true

func undo() -> void:
	undo_redo.undo()

func redo() -> void:
	undo_redo.redo()

func on_mouse_exited() -> void:
	cursor_in_toolbar = false

func set_toolbar_tooltip(text := "") -> void:
	%ToolsName.show()
	%ToolsName.text = text

func clear_toolbar_tooltip(text := "") -> void:
	if %ToolsName.text == text:
		%ToolsName.hide()

var gizmos_visible := true

func toggle_gizmos(toggled := false) -> void:
	gizmos_visible = toggled

func clear_trail() -> void:
	for i in $PlayerTrail.get_children():
		i.queue_free()

func record_player_frame () -> void:
	var target_player = get_tree().get_first_node_in_group("Players")
	if target_player == null:
		return
	last_placed_position = target_player.global_position
	var frame = target_player.sprite.sprite_frames.get_frame_texture(target_player.sprite.animation, target_player.sprite.frame)
	var sprite = Sprite2D.new()
	sprite.texture = frame
	sprite.global_transform = target_player.sprite.global_transform
	sprite.modulate.a = 0.5
	$PlayerTrail.add_child(sprite)

func clear_level() -> void:
	sub_areas = [null, null, null, null, null]
	level_file = BLANK_FILE.duplicate_deep()
	load_level(0)
	clear_trail()

func set_state(state := EditorState.IDLE) -> void:
	current_state = state

func save_blueprint() -> void:
	var file_name = %BlueprintName.text.to_pascal_case() + ".mbp"
	var file = FileAccess.open(Global.config_path.path_join("blueprints").path_join(file_name), FileAccess.WRITE)
	file.store_string($LevelSaver.compress_string(JSON.stringify(area_to_save)))
	file.close()
	Global.log_comment(file_name + " saved.")
	area_to_save = {}

func load_blueprint(blueprint_path := "") -> void:
	var file = FileAccess.open(blueprint_path, FileAccess.READ).get_as_text()
	var json = JSON.parse_string($LevelSaver.decompress_string(file))
	copied_area = json
	pasting_area = true
	var size_str = json["Size"].split(",", false)
	var size = Vector2(int(size_str[0]), int(size_str[1]))
	pasting_bounds = Rect2i(-ceil((size.x + 1) / 2), -ceil((size.y + 1) / 2), size.x, size.y)
	pasting_bounds.position += Vector2(16, 16)
	print(pasting_bounds)
	$TileMenu.hide()
	current_state = EditorState.IDLE

const BLUEPRINT_CONTAINER = preload("uid://cgij8pg22drfx")

func get_blueprints() -> void:
	for i in %Blueprints.get_children():
		i.queue_free()
	var blueprint_path = Global.config_path.path_join("blueprints")
	for i in DirAccess.get_files_at(blueprint_path):
		var container = BLUEPRINT_CONTAINER.instantiate()
		container.path = blueprint_path.path_join(i)
		%Blueprints.add_child(container)
		container.blueprint_selected.connect(load_blueprint)

func open_blueprint_folder() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Global.config_path.path_join("blueprints")), true)

func save_reminder() -> void:
	Global.log_comment("Remember to save!")
	AudioManager.play_global_sfx("pause")
