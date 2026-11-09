class_name ResourceGenerator
extends AssetRipper

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var error: Label = %Error

static var updating := false

func _ready() -> void:
	Global.get_node("GameHUD").hide()
	if updating: $MarginContainer/ProgressBar/Label.text = "UPDATING ASSETS..."
	rom = FileAccess.get_file_as_bytes(Global.rom_path)
	prg_rom_size = rom[4] * 16384
	chr_rom = rom.slice(16 + prg_rom_size)
	await get_tree().create_timer(1, false).timeout
	generate_resource_pack()

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()



func done() -> void:
	if not Settings.file.visuals.resource_packs.has(Global.ROM_PACK_NAME):
		Settings.file.visuals.resource_packs.insert(0, Global.ROM_PACK_NAME)
		
	await get_tree().create_timer(0.5).timeout
	Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func generate_resource_pack() -> void:
	DirAccess.make_dir_recursive_absolute(Global.ROM_ASSETS_PATH)
	
	var pack_json: String = FileAccess.get_file_as_string("res://Resources/AssetRipper/ResourcePack/pack_info.json")
	var pack_dict: Dictionary = JSON.parse_string(pack_json)
	pack_dict.set("version", Global.ROM_ASSETS_VERSION)
	
	var pack_file := FileAccess.open(Global.ROM_ASSETS_PATH + "/pack_info.json", FileAccess.WRITE)
	pack_file.store_line(JSON.stringify(pack_dict))
	pack_file.close()
	
	var list_json: String = FileAccess.get_file_as_string(SPRITE_LIST_PATH)
	var list_dict: Dictionary = JSON.parse_string(list_json)
	
	var sprite_list: Array = list_dict.get("sprites", [])
	progress_bar.max_value = sprite_list.size()
	
	var sprites_handled: int = 0
	for sprite_path in sprite_list:
		var json_path: String = png_path_to_json(sprite_path)
		var sprite_image: Image
		print("Running:" + sprite_path)
		if sprite_path.begins_with("res://"):
			sprite_image = load(sprite_path).get_image()
		else:
			sprite_image = Image.load_from_file(sprite_path)
		sprite_image.convert(Image.FORMAT_RGBA8)
		if FileAccess.file_exists(json_path):
			var json_string: String = FileAccess.get_file_as_string(json_path)
			var json_dict: Dictionary = JSON.parse_string(json_string)
			
			paste_sprite(sprite_image, json_dict)
			
			var destination_path: String = get_destination_path(sprite_path)
			if not DirAccess.dir_exists_absolute(destination_path.get_base_dir()):
				DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
			sprite_image.save_png(destination_path)
		
			sprites_handled += 1 
			progress_bar.value = sprites_handled
			await get_tree().process_frame
	
	if sprites_handled < sprite_list.size():
		error.show()
		## uncomment this once the initial jsons are fully setup so that the game won't
		## boot if the resource pack loading is borked
		OS.move_to_trash(Global.ROM_ASSETS_PATH)
	else:
		done()

func paste_sprite(sprite_image: Image, json_dict: Dictionary):
	var columns: int = str_to_var(json_dict.get("columns", "4"))
	var sheet_size: Vector2i = str_to_var(json_dict.get("sheet_size", "Vector2i(16, 16)"))
	var palette_base: String = json_dict.get("palette_base", "Tile")
	
	var palette_var: Variant = str_to_var(json_dict.get("palettes", "{}"))
	var palette_lists: Dictionary
	if typeof(palette_var) == TYPE_ARRAY:
		palette_lists[palette_base] = palette_var
	elif typeof(palette_var) == TYPE_DICTIONARY:
		palette_lists = palette_var
	
	var tile_list: Dictionary = str_to_var(json_dict.get("tiles", "{}"))
	var img_size: Vector2i = sprite_image.get_size()
	
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
						draw_tile(
							true,
							sprite_image,
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

func get_destination_path(sprite_path: String) -> String:
	return sprite_path.replace("res://Assets/", Global.ROM_ASSETS_PATH + "/")
