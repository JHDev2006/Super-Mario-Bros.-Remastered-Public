class_name TilesetTextureSetter
extends Node

@export var tile_map: TileMapLayer
@export var texture: Texture = null:
	set(value):
		texture = AtlasTexture.new()
		texture.atlas = value
		texture_changed.emit()

signal texture_changed

@export var atlas_id := 0
@export var resource_setter: ResourceSetterNew

@onready var resource_getter = ResourceGetter.new()
@onready var animation_timer = Timer.new()

var animation_atlas: AtlasTexture
var animation_json: Dictionary
var animation_frame: int = -1
var animation_loop: bool

func _ready() -> void:
	animation_timer.one_shot = true
	animation_timer.timeout.connect(run_frame)
	add_child(animation_timer)
	# Reset Tilemaps and Tilesets
	if Global.level_editor == null and Global.current_game_mode != Global.GameMode.CUSTOM_LEVEL and atlas_id > 0:
		tile_map.tile_set = tile_map.tile_set.duplicate(true)
		tile_map = tile_map.duplicate()
	# Update Textures
	update()
	texture_changed.connect(update)

func update() -> void:
	print(name)
	var source = tile_map.tile_set.get_source(atlas_id)
	if source != null:
		source.texture = texture
		if resource_setter != null: # Handles custom animations
			animation_json = resource_setter.get_variation_json(resource_getter.get_resource(resource_setter.resource_json).data.get("animations", {}))
			if animation_json.is_empty():
				animation_loop = false
				animation_timer.stop()
				return
			elif animation_json.has("loop"): # CREATE animations and frames based on the usual SMB1R format
				animation_loop = animation_json.loop
				animation_timer.start(1.0 / animation_json.speed)
			else: # CREATE animations and frames based on GODOT's system
				for id in animation_json:
					if not id.begins_with("Tile:"): continue
					var tile_id = int(id)
					var coords = source.get_tile_id(tile_id)
					var data = animation_json[id]
					source.set_tile_animation_mode(coords, data.get("mode", TileSetAtlasSource.TILE_ANIMATION_MODE_DEFAULT))
					source.set_tile_animation_speed(coords, data.get("speed", 1.0))
					if not data.get("frames", []).is_empty():
						source.set_tile_animation_frames_count(coords, data.frames.size())
						for i in data.frames.size():
							source.set_tile_animation_frame_duration(coords, i, data.frames[i].duration)

func run_frame() -> void:
	var frames = animation_json.get("frames", [])
	if frames.is_empty(): return
	animation_frame = wrapi(animation_frame + 1, 0, frames.size())
	var rect = Rect2(frames[animation_frame][0], frames[animation_frame][1], frames[animation_frame][2], frames[animation_frame][3])
	texture.region = rect
	if animation_loop: animation_timer.start(1.0 / animation_json.speed)
