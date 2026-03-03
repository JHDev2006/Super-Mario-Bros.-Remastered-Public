class_name AssetEditor
extends AssetRipper

const CUR_SPRITE_TEXT: String = "Current Sprite:\n%s"

var list_index: int = 0
var sprite_list: Array
var cached_sprites: Dictionary[String, Dictionary]

var tile_atlas: Texture
var rom_provided: bool

var source_path: String
var tile_index: int = 0
var columns: int = 4
var sheet_size := Vector2i(16, 16)

var palette_base: String = "Tile"
var palettes: Dictionary
var tiles: Dictionary

@onready var rom_required: Label = %RomRequired
@onready var file_dialog: FileDialog = %FileDialog

@onready var image_preview: TextureRect = %ImagePreview
@onready var green_preview: TextureRect = %GreenPreview
@onready var tiles_preview: TextureRect = %TilesPreview
@onready var cur_sprite: Label = %CurSprite

@onready var preview: Sprite2D = %Preview
@onready var buttons: HBoxContainer = %Buttons
@onready var palette_override: LineEdit = %PaletteOverride

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var json_container: VBoxContainer = %JSONContainer
@onready var json_edit: TextEdit = %JSONEdit


func _ready() -> void:
	Global.get_node("GameHUD").hide()
	if Global.rom_path != "":
		on_file_selected(Global.rom_path)

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func _unhandled_input(event: InputEvent) -> void:
	if not rom_provided:
		return
	
	if event is InputEventMouseMotion:
		var is_snapped = not Input.is_action_pressed("editor_cam_fast")
		var mouse_pos: Vector2 = event.position + Vector2(
			scroll_container.scroll_horizontal,
			scroll_container.scroll_vertical
		) + Vector2(-4, -8)
		preview.position = Vector2i(mouse_pos).snappedi(8 if is_snapped else 1)
		
		preview.visible = true
		if preview.position.x + 8 > sheet_size.x:
			preview.visible = false
		if preview.position.y + 8 > sheet_size.y:
			preview.visible = false
	
	if not preview.is_visible_in_tree(): return
	
	var direction: int = 0
	if event.is_action_pressed("editor_cam_left"): direction = -1
	if event.is_action_pressed("editor_cam_right"): direction = 1
	if event.is_action_pressed("editor_cam_up"): direction = -16
	if event.is_action_pressed("editor_cam_down"): direction = 16
	if event.is_action_pressed("pick_tile"):
		if tiles.has(preview.position):
			tile_index = tiles[preview.position].index
			preview.flip_h = tiles[preview.position].flip_h
			preview.flip_v = tiles[preview.position].flip_v
			if Input.is_action_pressed("editor_select"):
				if tiles[preview.position].has("palette"):
					palette_override.text = tiles[preview.position]["palette"]
				else:
					palette_override.text = ""
			preview.region_rect = Rect2i(index_to_coords(tile_index, 32) * 8, Vector2i(8, 8))
	if direction != 0:
		var multiply = 1 if not Input.is_action_pressed("editor_cam_fast") else 8
		tile_index = wrapi(tile_index + direction * multiply, 0, 512)
		preview.region_rect = Rect2i(index_to_coords(tile_index, 32) * 8, Vector2i(8, 8))
	
	if event.is_action_pressed("jump_0"): preview.flip_h = not preview.flip_h
	if event.is_action_pressed("run_0"): preview.flip_v = not preview.flip_v
	
	var left_click: bool = event.is_action_pressed("mb_left")
	var right_click: bool = event.is_action_pressed("mb_right")
	if left_click or right_click:
		if left_click:
			tiles[preview.position] = {
				"index": tile_index,
				"flip_h": preview.flip_h,
				"flip_v": preview.flip_v
			}
			if not palette_override.text.is_empty():
				tiles[preview.position]["palette"] = palette_override.text
		else:
			tiles.erase(preview.position)
			
		update_edited_image()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("editor_select") == false:
		return
	var left_click: bool = Input.is_action_pressed("mb_left")
	var right_click: bool = Input.is_action_pressed("mb_right")
	if left_click or right_click:
		if left_click:
			tiles[preview.position] = {
				"index": tile_index,
				"flip_h": preview.flip_h,
				"flip_v": preview.flip_v
			}
			if not palette_override.text.is_empty():
				tiles[preview.position]["palette"] = palette_override.text
		else:
			tiles.erase(preview.position)
			
		update_edited_image()

func update_edited_image() -> void:
	var tiles_images: Array[Image] = get_tile_images(image_preview.texture.get_image().get_size(), tiles, palettes)
	tiles_preview.texture = ImageTexture.create_from_image(tiles_images[0])
	green_preview.texture = ImageTexture.create_from_image(tiles_images[1])

func get_tile_images(
	img_size: Vector2i, tile_list: Dictionary, palette_lists: Dictionary
) -> Array[Image]:
	var image := Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
	var green_image := Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
	
	for palette_name in palette_lists.keys():
		var cur_column: int = 0
		var offset := Vector2.ZERO
		
		var pal_json: String = FileAccess.get_file_as_string(
			PALETTES_FOLDER % [DEFAULT_PALETTE_GROUP, palette_name])
		var pal_dict: Dictionary = JSON.parse_string(pal_json).palettes
		
		for palette_id: String in palette_lists[palette_name]:
			var palette: Array = pal_dict.get(palette_id, PREVIEW_PALETTE)
			
			for tile_pos: Vector2 in tile_list:
				var tile_dict: Dictionary = tile_list[tile_pos]
				var tile_palette: String = tile_dict.get("palette", palette_base)
				if tile_palette == palette_name:
					var destination: Vector2 = tile_pos + offset
					if destination.x < img_size.x and destination.y < img_size.y:
						draw_green(green_image, destination)
						draw_tile(
							false,
							image,
							tile_dict.get("index", 0), 
							destination,
							palette,
							tile_dict.get("flip_h", false),
							tile_dict.get("flip_v", false)
						)
			cur_column += 1
			if cur_column >= columns:
				cur_column = 0
				offset.x = 0
				offset.y += sheet_size.y
			else:
				offset.x += sheet_size.x
	return [image, green_image]

func on_file_selected(path: String) -> void:
	rom = FileAccess.get_file_as_bytes(path)
	prg_rom_size = rom[4] * 16384
	chr_rom = rom.slice(16 + prg_rom_size)
	
	rom_provided = true
	rom_required.hide()
	buttons.show()
	
	# setup sprite atlas for placing tiles
	var atlas := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for index in range(512):
		var pos: Vector2i = index_to_coords(index, 32) * 8
		draw_tile(false, atlas, index, pos, PREVIEW_PALETTE)
	preview.texture = ImageTexture.create_from_image(atlas)
	#
	
	var list_json: String = FileAccess.get_file_as_string(SPRITE_LIST_PATH)
	var list_dict: Dictionary = JSON.parse_string(list_json)
	sprite_list = list_dict.get("sprites", [])
	
	cycle_list(0)

func load_sprite(sprite_dict: Dictionary) -> void:
	source_path = sprite_dict.source_path
	
	if source_path.begins_with("res://"):
		image_preview.texture = load(source_path)
	else:
		var image := Image.load_from_file(source_path)
		image_preview.texture = ImageTexture.create_from_image(image)
	cur_sprite.text = CUR_SPRITE_TEXT % source_path.get_file()
	
	columns = str_to_var(sprite_dict.get("columns", "4"))
	sheet_size = str_to_var(sprite_dict.get("sheet_size", "Vector2i(16, 16)"))
	palette_base = sprite_dict.get("palette_base", "Tile")
	
	var palettes_var: Variant = str_to_var(sprite_dict.get("palettes", var_to_str(get_default_palettes())))
	if typeof(palettes_var) == TYPE_ARRAY:
		palettes = {}
		palettes[palette_base] = palettes_var
	elif typeof(palettes_var) == TYPE_DICTIONARY:
		palettes = palettes_var
	
	tiles = str_to_var(sprite_dict.get("tiles", "{}"))
	
	update_palettes()
	update_edited_image()

func save_sprite() -> void:
	var sprite_dict: Dictionary = get_as_dict()
	var destination_path: String = png_path_to_json(sprite_dict.source_path)
	
	var json_string: String = JSON.stringify(sprite_dict)
	DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
	var file: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
	file.store_line(json_string)
	file.close()
	
	# save green over original image
	var base_image: Image = image_preview.texture.get_image()
	var green_image: Image = green_preview.texture.get_image()
	for y in range(green_image.get_size().y):
		for x in range(green_image.get_size().x):
			var found_color: Color = green_image.get_pixel(x, y)
			if found_color.a > 0:
				base_image.set_pixel(x, y, found_color)
	base_image.save_png(sprite_dict.source_path)

func cycle_list(add_index: int) -> void:
	if add_index != 0:
		cached_sprites[sprite_list[list_index]] = get_as_dict()
		list_index = wrapi(list_index + add_index, 0, sprite_list.size())
	
	if sprite_list[list_index] in cached_sprites:
		load_sprite(cached_sprites[sprite_list[list_index]])
	else:
		var json_path: String = sprite_list[list_index].replace(
			"res://Assets/Sprites/", "res://Resources/AssetRipper/Sprites/"
			).replace(".png", ".json")
		if FileAccess.file_exists(json_path):
			var json_string: String = FileAccess.get_file_as_string(json_path)
			load_sprite(JSON.parse_string(json_string))
		else:
			load_sprite({"source_path": sprite_list[list_index]})

func get_as_dict() -> Dictionary:
	return {
		"source_path": source_path,
		"columns": var_to_str(columns),
		"sheet_size": var_to_str(sheet_size),
		"palette_base": palette_base,
		"palettes": var_to_str(palettes),
		"tiles": var_to_str(tiles)
	}

func get_default_palettes() -> Dictionary:
	var pal_json: String = FileAccess.get_file_as_string(
		PALETTES_FOLDER % [DEFAULT_PALETTE_GROUP, palette_base])
	var pal_dict: Dictionary = JSON.parse_string(pal_json)
	var default_palettes: Array = pal_dict.get("palettes", []).keys()
	return {palette_base: default_palettes}

func update_palettes(load_textedit: bool = false) -> void:
	if load_textedit:
		var dict: Dictionary = JSON.parse_string(json_edit.text)
		columns = dict.get("columns", 1)
		var size_array: Array = dict.get("sheet_size", [16, 16])
		sheet_size = Vector2i(size_array[0], size_array[1])
		palette_base = dict.get("palette_base", "Tile")
		var pal_var: Variant = dict.get("palettes", get_default_palettes())
		if typeof(pal_var) == TYPE_ARRAY:
			palettes = {}
			palettes[palette_base] = pal_var
		elif typeof(pal_var) == TYPE_DICTIONARY:
			palettes = pal_var
		update_edited_image()
		
	json_edit.text = JSON.stringify(
		{
			"columns": columns,
			"sheet_size": [sheet_size.x, sheet_size.y],
			"palette_base": palette_base,
			"palettes": palettes
		}, "\t", false)

func toggle_palettes_view(toggled_on: bool) -> void:
	json_container.visible = toggled_on
	scroll_container.visible = not toggled_on

func draw_green(
	image: Image,
	pos: Vector2i
) -> void:
	for y in range(8):
		for x in range(8):
			image.set_pixelv(Vector2i(x, y) + pos, Color.GREEN)
