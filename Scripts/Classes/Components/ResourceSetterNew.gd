class_name ResourceSetterNew
extends Node

@export var node_to_affect: Node = null
@export var property_node: Node = null
@export var property_name := ""
@export var mode: ResourceMode = ResourceMode.SPRITE_FRAMES
@export var resource_json: JSON = null:
	set(value):
		resource_json = value
		update_resource()

enum ResourceMode {SPRITE_FRAMES, TEXTURE, AUDIO, RAW, FONT}
@export var use_cache := true

static var cache := {}
static var property_cache := {}

var current_json_path := ""

static var state := [0, 0, 0]

static var pack_configs := {}

var config_to_use := {}

var is_random := false

signal updated

var current_resource_pack := ""

@export var force_properties := {}
var update_on_spawn := true

func _init() -> void:
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func _ready() -> void:
	Global.level_time_changed.connect(update_resource)
	Global.level_theme_changed.connect(update_resource)

func _enter_tree() -> void:
	safety_check()
	if update_on_spawn:
		update_resource()

func safety_check() -> void:
	if Settings.file.visuals.resource_packs.has(Global.ROM_PACK_NAME) == false:
		Settings.file.visuals.resource_packs.insert(Global.ROM_PACK_NAME, 0)

func update_resource() -> void:
	randomize()
	if is_inside_tree() == false or is_queued_for_deletion() or resource_json == null or node_to_affect == null:
		return
	if state != [Global.level_theme, Global.theme_time, Global.current_room]:
		cache.clear()
		property_cache.clear()
	if node_to_affect != null:
		var resource = get_resource(resource_json)
		node_to_affect.set(property_name, resource)
		if node_to_affect is AnimatedSprite2D:
			node_to_affect.play()
	state = [Global.level_theme, Global.theme_time, Global.current_room]
	updated.emit()

func get_resource(json_file: JSON) -> Resource:
	if cache.has(json_file.resource_path) and use_cache and force_properties.is_empty():
		if property_cache.has(json_file.resource_path):
			apply_properties(property_cache[json_file.resource_path])
		return cache[json_file.resource_path]
	
	var resource: Resource = null
	var resource_path = json_file.resource_path
	config_to_use = {}
	current_resource_pack = ""
	for i in Settings.file.visuals.resource_packs:
		var new_path = get_resource_pack_path(resource_path, i)
		if resource_path != new_path or current_resource_pack == "":
			current_resource_pack = i
		resource_path = new_path
	
	var source_json = JSON.parse_string(FileAccess.open(resource_path, FileAccess.READ).get_as_text())
	if source_json == null:
		Global.log_error("Error parsing " + resource_path + "!")
		return
	var json = source_json.duplicate()
	var source_resource_path = ""
	if json.has("variations"):
		json = get_variation_json(json.variations)
		if json.has("source"):
			if json.get("source") is String:
				source_resource_path = json_file.resource_path.replace(json_file.resource_path.get_file(), json.source)
		else:
			Global.log_error("Error getting variations! " + resource_path)
			return
	for i in Settings.file.visuals.resource_packs:
		source_resource_path = get_resource_pack_path(source_resource_path, i)
	if json.has("rect"):
		resource = load_image_from_path(source_resource_path)
		var atlas = AtlasTexture.new()
		atlas.atlas = resource
		atlas.region = Rect2(json.rect[0], json.rect[1], json.rect[2], json.rect[3])
		resource = atlas
	if json.has("properties"):
		apply_properties(json.get("properties"))
		if use_cache:
			property_cache[json_file.resource_path] = json.properties.duplicate()
	elif source_json.has("properties"):
		apply_properties(source_json.get("properties"))
		if use_cache:
			property_cache[json_file.resource_path] = source_json.properties.duplicate()
	match mode:
		ResourceMode.SPRITE_FRAMES:
			var animation_json = {}
			
			if source_json.has("animations"):
				animation_json = source_json.get("animations")
			elif json.has("animations"):
				animation_json = json.get("animations")
			
			if json.has("animation_overrides"):
				for i in json.get("animation_overrides").keys():
					animation_json[i] = json.get("animation_overrides")[i]
					
			if animation_json != {}:
				resource = load_image_from_path(source_resource_path)
				if json.has("rect"):
					var atlas = AtlasTexture.new()
					atlas.atlas = resource
					atlas.region = Rect2(json.rect[0], json.rect[1], json.rect[2], json.rect[3])
					resource = atlas
				resource = create_sprite_frames_from_image(resource, animation_json)
			else:
				resource = load_image_from_path(source_resource_path)
				if json.has("rect"):
					var atlas = AtlasTexture.new()
					atlas.atlas = resource
					atlas.region = Rect2(json.rect[0], json.rect[1], json.rect[2], json.rect[3])
					resource = atlas
				var sprite_frames = SpriteFrames.new()
				sprite_frames.add_frame("default", resource)
				resource = sprite_frames
		ResourceMode.TEXTURE:
			if json.get("source") is Array:
				resource = AnimatedTexture.new()
				resource.frames = json.get("source").size()
				var idx := 0
				for i in json.get("source"):
					var frame_path = ResourceSetter.get_pure_resource_path(json_file.resource_path.replace(json_file.resource_path.get_file(), i))
					resource.set_frame_texture(idx, load_image_from_path(frame_path))
					idx += 1
			else:
				resource = load_image_from_path(source_resource_path)
			if json.has("rect"):
				var rect = json.rect
				var atlas = AtlasTexture.new()
				atlas.atlas = resource
				atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
				resource = atlas
		ResourceMode.AUDIO:
			resource = load_audio_from_path(source_resource_path)
		ResourceMode.RAW:
			pass
		ResourceMode.FONT:
			if source_resource_path.contains(Global.get_config_path()):
				resource = FontFile.new()
				resource.load_bitmap_font(source_resource_path)
			else:
				resource = load(source_resource_path)
			resource.set_meta("base_path", source_resource_path)
	if cache.has(json_file.resource_path) == false and use_cache and not is_random:
		cache[json_file.resource_path] = resource
	return resource

func apply_properties(properties := {}) -> void:
	if property_node == null:
		return
	for i in properties.keys():
		if property_node.get(i) is Vector2:
			var value = properties[i]
			if value is Array:
				property_node.set(i, Vector2(value[0], value[1]))
		else:
			var obj = property_node
			for p in i.split("."):
				if not is_instance_valid(obj): continue
				if obj.get(p) is Object:
					if obj.has_method("duplicate"):
						obj.set(p, obj[p].duplicate(true))
					obj = obj[p]
				else:
					obj.set(p, properties[i])
					continue



func get_variation_json(json := {}) -> Dictionary:
	var level_theme = Global.level_theme
	if force_properties.has("Theme"):
		level_theme = force_properties.Theme
	for i in json.keys().filter(func(key): return key.contains("config:")):
		get_config_file(current_resource_pack)
		if config_to_use != {}:
			var option_name = i.get_slice(":", 1)
			if config_to_use.options.has(option_name):
				json = get_variation_json(json[i][config_to_use.options[option_name]])
				break
	
	if json.has(level_theme) == false:
		level_theme = "default"
	if json.has(level_theme):
		if json.get(level_theme).has("link"):
			json = get_variation_json(json[json.get(level_theme).get("link")])
		else:
			json = get_variation_json(json[level_theme])
	
	var level_time = Global.theme_time
	if force_properties.has("Time"):
		level_time = force_properties.Time
	if json.has(level_time):
		json = get_variation_json(json[level_time])
	
	var campaign = Global.current_campaign
	if force_properties.has("Campaign"):
		campaign = force_properties.Campaign
	if json.has(campaign) == false:
		campaign = "SMB1"
	if json.has(campaign):
		if json.get(campaign).has("link"):
			json = get_variation_json(json[json.get(campaign).get("link")])
		else:
			json = get_variation_json(json[campaign])
	
	if json.has("choices"):
		is_random = true
		json = get_variation_json(json.choices.pick_random())
	
	var world = "World" + str(Global.world_num)
	if force_properties.has("World"):
		world = "World" + str(force_properties.World)
	if json.has(world) == false:
		world = "World1"
	if json.has(world):
		if json.get(world).has("link"):
			json = get_variation_json(json[json.get(world).get("link")])
		else:
			json = get_variation_json(json[world])
	
	var level_string = "Level" + str(Global.level_num)
	if json.has(level_string) == false:
		level_string = "Level1"
	if json.has(level_string):
		if json.get(level_string).has("link"):
			json = get_variation_json(json[json.get(level_string).get("link")])
		else:
			json = get_variation_json(json[level_string])
	
	var room = Global.room_strings[Global.current_room]
	if json.has(room) == false:
		room = Global.room_strings[0]
	if json.has(room):
		if json.get(room).has("link"):
			json = get_variation_json(json[json.get(room).get("link")])
		else:
			json = get_variation_json(json[room])
	
	var game_mode = "GameMode:" + Global.game_mode_strings[Global.current_game_mode]
	if json.has(game_mode) == false:
		game_mode = "GameMode:" + Global.game_mode_strings[0]
	if json.has(game_mode):
		if json.get(game_mode).has("link"):
			json = get_variation_json(json[json.get(game_mode).get("link")])
		else:
			json = get_variation_json(json[game_mode])
	
	var chara = "Character:" + Player.CHARACTERS[int(Global.player_characters[0])]
	if json.has(chara) == false:
		chara = "Character:default"
	if json.has(chara):
		if json.get(chara).has("link"):
			json = get_variation_json(json[json.get(chara).get("link")])
		else:
			json = get_variation_json(json[chara])
	
	var boo = "RaceBoo:" + str(BooRaceHandler.boo_colour)
	if json.has(boo) == false:
		boo = "RaceBoo:0"
	if force_properties.has("RaceBoo"):
		boo = "RaceBoo:" + str(force_properties["RaceBoo"])
	if json.has(boo):
		if json.get(boo).has("link"):
			json = get_variation_json(json[json.get(boo).get("link")])
		else:
			json = get_variation_json(json[boo])
	
	return json

func get_config_file(resource_pack := "") -> void:
	if FileAccess.file_exists("user://resource_packs/" + resource_pack + "/config.json"):
		config_to_use = JSON.parse_string(FileAccess.open("user://resource_packs/" + resource_pack + "/config.json", FileAccess.READ).get_as_text())
		if config_to_use == null:
			Global.log_error("Error parsing Config File! (" + resource_pack + ")")
			config_to_use = {}
	else:
		print("resource pack to use: " + resource_pack)

func get_resource_pack_path(res_path := "", resource_pack := "") -> String:
	var user_path := res_path.replace("res://Assets", Global.config_path.path_join("resource_packs/" + resource_pack))
	user_path = user_path.replace(Global.config_path.path_join("custom_characters"), Global.config_path.path_join("resource_packs/" + resource_pack + "/Sprites/Players/CustomCharacters/"))
	if FileAccess.file_exists(user_path):
		return user_path
	else:
		return res_path

func create_sprite_frames_from_image(image: Resource, animation_json := {}) -> SpriteFrames:
	var sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	for anim_name in animation_json.keys():
		sprite_frames.add_animation(anim_name)
		for frame in animation_json[anim_name].frames:
			var frame_texture = AtlasTexture.new()
			frame_texture.atlas = image
			frame_texture.region = Rect2(frame[0], frame[1], frame[2], frame[3])
			frame_texture.filter_clip = true
			sprite_frames.add_frame(anim_name, frame_texture)
		sprite_frames.set_animation_loop(anim_name, animation_json[anim_name].loop)
		sprite_frames.set_animation_speed(anim_name, animation_json[anim_name].speed)
	
	return sprite_frames

func clear_cache() -> void:
	for i in cache.keys():
		if cache[i] == null:
			cache.erase(i)
	cache.clear()
	property_cache.clear()

func load_image_from_path(path := "") -> Texture2D:
	if path.contains("res://"):
		if path.contains("NULL"):
			return null
		return load(path)
	var image = Image.new()
	image.load(path)
	return ImageTexture.create_from_image(image)

func load_audio_from_path(path := "") -> AudioStream:
	var stream = null
	if path.contains(".bgm"):
		stream = AudioManager.generate_interactive_stream(JSON.parse_string(FileAccess.get_file_as_string(path)))
	elif path.contains("res://"):
		return load(path)
	if path.contains(".wav"):
		stream = AudioStreamWAV.load_from_file(path)
	elif path.contains(".mp3"):
		stream = AudioStreamMP3.load_from_file(path)
	elif path.contains(".ogg"):
		stream = AudioStreamOggVorbis.load_from_file(path)
	return stream
