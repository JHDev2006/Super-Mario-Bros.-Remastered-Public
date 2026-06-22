class_name AssetRipper
extends Node

const SPRITES_PATH: String = "res://Resources/AssetRipper/Sprites/"
const SPRITE_LIST_PATH: String = "res://Resources/AssetRipper/SpriteList.json"

const DEFAULT_PALETTE_GROUP: String = "Default"
const PREVIEW_PALETTE: Array[Color] = [
	Color.TRANSPARENT,
	Color.DIM_GRAY,
	Color.WHITE,
	Color.DARK_GRAY
]
const PALETTES_FOLDER: String = "res://Resources/AssetRipper/Palettes/%s/%s.json"

var rom: PackedByteArray
var prg_rom_size: int
var chr_rom: PackedByteArray

## UTIL
func index_to_coords(index: int, max_x: int) -> Vector2i:
	var x: int = wrapi(index, 0, max_x)
	@warning_ignore("integer_division")
	var y: int = floor(index / max_x)
	return Vector2i(x, y)

func combine_bytes(byte0: int, byte1: int) -> PackedByteArray:
	var output_value: PackedByteArray
	for index in range(8):
		var bit_mask: int = 1 << index
		var shifted_byte0: int = (byte0 & bit_mask) >> index
		var shifted_byte1: int = (byte1 & bit_mask) >> index << 1
		output_value.insert(0, shifted_byte0 + shifted_byte1)
	return output_value

func reverse_bits(num: int):
	num = (num & 0xF0) >> 4 | (num & 0x0F) << 4
	num = (num & 0xCC) >> 2 | (num & 0x33) << 2
	num = (num & 0xAA) >> 1 | (num & 0x55) << 1
	return num

func png_path_to_json(png_path: String) -> String:
	return png_path.replace(
		"res://Assets/Sprites/", "res://Resources/AssetRipper/Sprites/"
	).replace(".png", ".json")

## TILE HANDLING
func draw_tile(
	chroma_key: bool,
	image: Image, 
	index: int, 
	pos: Vector2i,
	palette: PackedColorArray,
	flip_h: bool = false, 
	flip_v: bool = false
) -> void:
	var y = 0
	var img_size: Vector2i = image.get_size()
	var loaded_tile: Array[Array] = load_tile(index)
	if flip_h:
		for row in range(loaded_tile.size()):
			for byte in range(loaded_tile[row].size()):
				loaded_tile[row][byte] = reverse_bits(loaded_tile[row][byte])
	if flip_v:
		loaded_tile.reverse()
	for row: Array in loaded_tile:
		if y + pos.y < img_size.y:
			var x = 0
			for pixel: int in combine_bytes(row[0], row[1]):
				if x + pos.x < img_size.x:
					if not chroma_key or image.get_pixelv(Vector2i(x, y) + pos) == Color.GREEN:
						if palette[pixel].a != 1 and palette[pixel].a != 0:
							print(image.resource_path, palette[pixel])
						image.set_pixelv(Vector2i(x, y) + pos, palette[pixel])
				x += 1
		y += 1

func load_tile(index: int) -> Array:
	var address: int = 16*index
	var data: Array[Array] = []
	for i: int in range(8):
		var byte0: int = chr_rom[address + i]
		var byte1: int = chr_rom[address + i + 8]
		data.append([byte0, byte1])
	return data
