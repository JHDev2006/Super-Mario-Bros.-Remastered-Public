class_name PropertyExposer
extends Node

@export var properties: Array[String] = []
@export var filters: Dictionary[String, String] = {}

@export var properties_force_selector: Dictionary[String, PackedScene] = {}

@export var animate_change := true

@export var editing_scale := Vector2(1, 1)

const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

static var entity_map := {}

signal modifier_applied

func _init() -> void:
	name = "EditorPropertyExposer"

func _ready() -> void:
	assert(name == "EditorPropertyExposer", "MISSED ONE")
	name = "EditorPropertyExposer"
	get_entity_map()

func get_entity_map() -> void:
	if entity_map.is_empty():
		entity_map = JSON.parse_string(FileAccess.open(EntityIDMapper.MAP_PATH, FileAccess.READ).get_as_text())

func get_string() -> String:
	var string = ""
	for i in properties:
		string += ","
		if owner is Track:
			if owner.get(i) is Array:
				for x in owner.get(i):
					string += base64_charset[(Track.DIRECTIONS.find(x))]
		if owner is TilePlacer:
			if i == "tile_to_place":
				string += var_to_str(owner.get(i)).replace(",", "&")
		if owner is SnakeBlock:
			if owner.get(i) is Array:
				for x in owner.get(i):
					string += base64_charset[(SnakeBlock.DIRECTIONS.find(x))]
		if owner.get(i) is String:
			string += owner.get(i).replace(",", "&")
		if owner.get(i) is Color:
			var colour: Color = owner.get(i)
			string += colour.to_html(false)
		elif owner.get(i) is PackedScene:
			var key = EntityIDMapper.get_map_id(owner.get(i).resource_path)
			if key == null or key == "":
				key = "!!"
			string += key
		elif owner.get(i) is float:
			string += str(owner.get(i))
		elif owner.get(i) is int:
			if owner.get(i) >= 64:
				string += encode_to_base64_2char(owner.get(i))
			else:
				string += base64_charset[owner.get(i)]
		elif owner.get(i) is bool:
			string += base64_charset[int(owner.get(i))]
		elif owner.get(i) == null:
			string += "!!"
		
	return string

func apply_string(entity_string := "") -> void:
	get_entity_map()
	var idx := 2
	var slice = entity_string.split(",", false)
	for i in properties:
		if slice.size() <= idx:
			return
		var value = slice[idx]
		if value.contains("$"):
			return ## its a signal connection, we dont want the rest. we're done
		idx += 1
		if owner is Track:
			if owner.get(i) is Array:
				for x in value:
					owner.get(i).append(Track.DIRECTIONS[base64_charset.find(x)])
				owner._ready()
				continue
		if owner is SnakeBlock:
			if owner.get(i) is Array:
				for x in value:
					owner.get(i).append(SnakeBlock.DIRECTIONS[base64_charset.find(x)])
				continue
		if owner is TilePlacer:
			if i == "tile_to_place":
				owner.set(i, str_to_var(value.replace("&", ",")))
				continue
		elif owner.get(i) is String:
			owner.set(i, value.replace("&", ","))
		elif owner.get(i) is Color:
			owner.set(i, Color(value))
		elif owner.get(i) is PackedScene or (owner.get(i) == null and i == "item"):
			var scene = entity_map.get(value)
			if scene != null:
				owner.set(i, load(entity_map.get(value)[0]))
			elif value != "!!":
				Global.log_error("error getting item! : " + i + str(value))
		elif owner.get(i) is int:
			var num = value
			if value.length() > 1:
				num = decode_from_base64_2char(value)
			else:
				num = base64_charset.find(value)
			owner.set(i, num)
		elif owner.get(i) is bool:
			owner.set(i, bool(base64_charset.find(value)))
		elif owner.get(i) is float:
			owner.set(i, float(value))
	modifier_applied.emit()

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

	var char1_val = base64_charset.find(encoded[0])
	var char2_val = base64_charset.find(encoded[1])

	if char1_val == -1 or char2_val == -1:
		push_error("Invalid character in base64 string.")
		return -1

	return (char1_val << 6) | char2_val

func do_animation() -> void:
	if animate_change == false:
		return
	if owner is Node2D:
		var old_scale = owner.scale
		owner.scale += Vector2(0.2, 0.2)
		create_tween().set_trans(Tween.TRANS_CUBIC).tween_property(owner, "scale", old_scale, 0.1)
