class_name ResourceSetterNew
extends Node

@export var node_to_affect: Node = null
@export var property_node: Node = null
@export var property_name := ""
@export var mode: ResourceMode = ResourceMode.SPRITE_FRAMES

static var surpress_warnings = null
static var surpress_errors := false

## Backup of the last json path.
var backup_json_path := ""
@export_file_path("*.json") var json_path := "":
	set(value):
		backup_json_path = json_path
		
		json_path = value
		update_resource()

@export var metadata_node: Node = owner

enum ResourceMode {SPRITE_FRAMES, TEXTURE, AUDIO, RAW, FONT, THEME}
@export var use_cache := true

@export var sync: Array[ResourceSetterNew] = []

static var cache := {}
static var material_cache := {}
static var property_cache := {}
static var active_flags := []
static var sequences := {}

static var state := [0, 0, 0]

static var pack_configs := {}

var config_to_use := {}

var is_variable := false

signal updated

var current_resource_pack := ""

@export var force_properties := {}
var update_on_spawn := true

var source_json := {}

func _init() -> void:
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func _ready() -> void:
	if mode != ResourceMode.THEME:
		Global.level_theme_changed.connect(update_resource)

func _enter_tree() -> void:
	safety_check()
	if update_on_spawn:
		update_resource()

func safety_check() -> void:
	if Settings.file.visuals.resource_packs.has(Global.ROM_PACK_NAME) == false:
		Settings.file.visuals.resource_packs.append(Global.ROM_PACK_NAME)

func update_resource() -> void:
	randomize()
	if is_inside_tree() == false or is_queued_for_deletion() or json_path == "" or node_to_affect == null:
		return
	if state != [Global.level_theme, Global.theme_time, Global.current_room_type]:
		cache.clear()
		active_flags.clear()
		property_cache.clear()
	if node_to_affect != null:
		var json: JSON = load(json_path)
		# DawnLR: Load backup if the json path doesn't return a file.
		if (json == null):
			json = load(backup_json_path)
		var resource = get_resource(json)
		if mode != ResourceMode.THEME:
			node_to_affect.set(property_name, resource)
			if node_to_affect is AnimatedSprite2D:
				node_to_affect.play()
	state = [Global.level_theme, Global.theme_time, Global.current_room_type]
	updated.emit()

## Array that lists Resource Packs that should be skipped for that Resource.
var ignore_resource_from := []
func get_resource(json_file: JSON) -> Resource:
	if (json_file == null):
		var scene_name = owner.scene_file_path.get_file().get_basename()
		
		# DawnLR: Is this even possible? Like, I know I managed to do it once, but it's really hard to pull off.
		log_error("JSON file not found. Missing for Node: %s" % str(scene_name) + " Check the log.")
		return
	if cache.has(json_file.resource_path) and use_cache and force_properties.is_empty():
		var cached_resource = cache[json_file.resource_path]
		
		if cached_resource.has_meta("loop_offsets") and node_to_affect is AnimatedSprite2D:
			var loop_offsets = cached_resource.get_meta("loop_offsets")
			for i in loop_offsets.keys():
				node_to_affect.animation_looped.connect(on_animation_looped.bind(i, loop_offsets[i]))
		
		if material_cache.has(json_file.resource_path):
			set_material(material_cache[json_file.resource_path])
		
		if property_cache.has(json_file.resource_path):
			apply_properties(property_cache[json_file.resource_path])
		
		return cached_resource
	
	var resource: Resource = null
	var resource_path = json_file.resource_path
	config_to_use = {}
	current_resource_pack = ""
	for i in Settings.file.visuals.resource_packs:
		if (ignore_resource_from.has(i) && i != "BaseAssets"):
			continue
		var new_path = get_resource_pack_path(resource_path, i)
		if resource_path != new_path or current_resource_pack == "":
			current_resource_pack = i
		resource_path = new_path
	
	source_json = JSONParser.parse_to_dict(resource_path)
	if (FileAccess.file_exists(resource_path) && source_json.is_empty() && current_resource_pack != "BaseAssets"):
		# DawnLR: Given file cannot be worked with, skipping resource pack!
		ignore_resource_from.append(current_resource_pack)
		return get_resource(json_file)
	
	var json = source_json.duplicate()
	var source_resource_path = ""
	var finished = false
	while finished == false:
		if json.has("variations"):
			json = get_variation_json(json.variations)
			sync_metadata()
			if json.has("source"):
				if json.get("source") is String:
					source_resource_path = json_file.resource_path.replace(json_file.resource_path.get_file(), json.source)
			elif mode != ResourceMode.THEME && current_resource_pack != "BaseAssets":
				# DawnLR: If "source" is not set, then there's no way to reach the resource, skipping resource pack!
				log_error("Variation source needed wasn't found inside: \"%s\". Stopped at %s." % [resource_path, get_variation_path()], false)
				ignore_resource_from.append(current_resource_pack)
				return get_resource(json_file)
			if json.has("flags"):
				for i in json["flags"]:
					active_flags.append(i)
					json = get_variation_json(source_json)
				finished = false
		finished = true
	for i in Settings.file.visuals.resource_packs:
		if (ignore_resource_from.has(i) && i != "BaseAssets"):
			continue
		source_resource_path = get_resource_pack_path(source_resource_path, i)
		if (!FileAccess.file_exists(source_resource_path) && i != "BaseAssets" && i.contains("user://") && mode != ResourceMode.THEME):
			log_error("Variation source needed is not an existing file: \"%s\". Stopped at %s." % [resource_path, get_variation_path()], false)
			ignore_resource_from.append(i)
			return get_resource(json_file)
		
	var rect_error_message := func(): log_error("Variation source for: \"%s\" has incorrect rect size, should be 4 but is: %s. Stopped at: %s" % [resource_path, str(json["rect"].size()), get_variation_path()])
	
	if json.has("rect"):
		resource = load_image_from_path(source_resource_path)
		if (json["rect"].size() == 4):
			var atlas = AtlasTexture.new()
			atlas.atlas = resource
			atlas.region = Rect2(json.rect[0], json.rect[1], json.rect[2], json.rect[3])
			resource = atlas
		else:
			rect_error_message.call()
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
			
			if json.has("animations"):
				animation_json = json.get("animations")
			elif source_json.has("animations"):
				animation_json = source_json.get("animations")
			
			if json.has("animation_overrides"):
				for i in json.get("animation_overrides").keys():
					animation_json[i] = json.get("animation_overrides")[i]
			resource = load_image_from_path(source_resource_path)
			if json.has("rect"):
				if (json["rect"].size() == 4):
					var atlas = AtlasTexture.new()
					atlas.atlas = resource
					atlas.region = Rect2(json.rect[0], json.rect[1], json.rect[2], json.rect[3])
					resource = atlas
				else:
					rect_error_message.call()
			
			if animation_json != {}:
				resource = create_sprite_frames_from_image(resource, animation_json, resource_path)
			else:
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
				if (json["rect"].size() == 4):
					var atlas = AtlasTexture.new()
					atlas.atlas = resource
					atlas.region = Rect2(json.rect[0], json.rect[1], json.rect[2], json.rect[3])
					resource = atlas
				else:
					rect_error_message.call()
		ResourceMode.AUDIO:
			var loop_point = json.get("loop", -1.0)
			print(source_resource_path)
			resource = AudioManager.import_stream(source_resource_path, loop_point)
			print(resource)
		ResourceMode.RAW:
			pass
		ResourceMode.FONT:
			if source_resource_path.contains(Global.get_config_path()):
				resource = FontFile.new()
				resource.load_bitmap_font(source_resource_path)
			else:
				resource = load(source_resource_path)
			resource.set_meta("base_path", source_resource_path)
		ResourceMode.THEME:
			print([json, get_variation_path()])
			Global.theme_override = json.get("theme", "")
			Global.time_override = json.get("time", "")
			Global.music_override = json.get("music", "")
			Global.primary_bg_override = json.get("primary_bg", -1)
			Global.level_metadata = json.get("metadata", {})
			Global.secondary_bg_override = json.get("secondary_bg", -1)
			Global.particle_override = json.get("particles", -1)
			Global.extra_music_override = json.get("extra_bgm", "")
			Global.liquid_override = json.get("liquid", -1)
			Global.overlay_clouds_override = json.get("overlay_clouds", -1)
			Global.second_order_override = json.get("second_layer_order", -1)
	
	if mode in [ResourceMode.TEXTURE, ResourceMode.SPRITE_FRAMES]:
		var blend_mode := "mix"
		if json.has("blend"):
			blend_mode = json["blend"]
		elif source_json.has("blend"):
			blend_mode = source_json["blend"]
		if use_cache and not is_variable:
			material_cache[json_file.resource_path] = blend_mode
		set_material(blend_mode)
	
	if cache.has(json_file.resource_path) == false and use_cache and not is_variable:
		cache[json_file.resource_path] = resource
	
	ignore_resource_from.clear()
	variation_needed.clear()
	
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

var variation_needed := []
func get_variation_path() -> String:
	var variation_path := ""
	for i in variation_needed:
		if (variation_needed.find(i) != 0):
			variation_path += "/"
		variation_path += "\"%s\"" % i
	return variation_path

func get_variation_json(json := {}) -> Dictionary:
	var used_default := true
	
	for i in json.keys().filter(func(key): return key.contains("config:")):
		get_config_file(current_resource_pack)
		if config_to_use != {}:
			var option_name = i.get_slice(":", 1)
			if config_to_use.options.has(option_name):
				variation_needed.append(option_name)
				used_default = false
				
				var config_json = json[i][config_to_use.options[option_name]]
				if config_json.has("link"):
					json = get_variation_json(json[config_json.get("link")])
				else:
					json = get_variation_json(config_json)
				break
	
	for i in json.keys().filter(func(key): return key.contains("flag:")):
		if active_flags.has(i):
			json = get_variation_json(json[i])
			break
	var level_theme = Global.level_theme
	
	if force_properties.has("Theme"):
		level_theme = force_properties.Theme
	if Global.theme_override != "":
		level_theme = Global.theme_override
	if json.has(level_theme) == false:
		level_theme = "default"
	if json.has(level_theme):
		variation_needed.append(level_theme)
		used_default = false
		
		if json.get(level_theme).has("link"):
			json = get_variation_json(json[json.get(level_theme).get("link")])
		else:
			json = get_variation_json(json[level_theme])
	
	var level_time = Global.theme_time
	if force_properties.has("Time"):
		level_time = force_properties.Time
	if Global.time_override != "":
		level_time = Global.time_override
	if json.has(level_time):
		variation_needed.append(level_time)
		used_default = false
		
		json = get_variation_json(json[level_time])
	
	var campaign: String = Global.current_campaign
	if force_properties.has("Campaign"):
		campaign = force_properties.Campaign
	if json.has(campaign) == false:
		campaign = "SMB1"
	if json.has(campaign):
		variation_needed.append(campaign)
		used_default = false
		
		if json.get(campaign).has("link"):
			json = get_variation_json(json[json.get(campaign).get("link")])
		else:
			json = get_variation_json(json[campaign])
	
	if json.has("choices"):
		is_variable = true
		var idx := randi_range(0, json.choices.size() - 1)
		if has_meta("RNGChoice"):
			idx = get_meta("RNGChoice", -1)
		else:
			set_meta("RNGChoice", idx)
		var random_json = json.choices[idx]
		
		variation_needed.append("choices:" + str(idx))
		used_default = false
		
		if random_json.has("link"):
			json = get_variation_json(json[random_json.get("link")])
		else:
			json = get_variation_json(random_json)
			
	if json.has("sequence"):
		is_variable = true
		var idx := 0
		if has_meta("SequencePos"):
			idx = get_meta("SequencePos", -1)
		else:
			idx = sequences.get(json_path, -1) + 1
			set_meta("SequencePos", idx)
			sequences[json_path] = idx
		var sequence_json = json.sequence[posmod(idx, json.sequence.size())]
		if sequence_json.has("link"):
			json = get_variation_json(json[sequence_json.get("link")])
		else:
			json = get_variation_json(sequence_json)
	
	var world = "World" + str(Global.world_num)
	if force_properties.has("World"):
		world = "World" + str(force_properties.World)
	if json.has(world) == false:
		world = "World1"
	if json.has(world):
		variation_needed.append(world)
		used_default = false
		
		if json.get(world).has("link"):
			json = get_variation_json(json[json.get(world).get("link")])
		else:
			json = get_variation_json(json[world])
	
	var level_string = "Level" + str(Global.level_num)
	if json.has(level_string) == false:
		level_string = "Level1"
	if json.has(level_string):
		variation_needed.append(level_string)
		used_default = false
		
		if json.get(level_string).has("link"):
			json = get_variation_json(json[json.get(level_string).get("link")])
		else:
			json = get_variation_json(json[level_string])
	
	var quest = "Quest:1"
	if Global.second_quest:
		quest = "Quest:2"
	if json.has(quest):
		json = get_variation_json(json[quest])
	
	var room = "RoomType:" + Level.ROOM_STRINGS[Global.current_room_type]
	if json.has(room) == false:
		room = "RoomType:Default"
	if json.has(room):
		variation_needed.append(room)
		used_default = false
		
		if json.get(room).has("link"):
			json = get_variation_json(json[json.get(room).get("link")])
		else:
			json = get_variation_json(json[room])
	
	var game_mode = "GameMode:" + Global.game_mode_strings[Global.current_game_mode]
	if json.has(game_mode) == false:
		game_mode = "GameMode:" + Global.game_mode_strings[0]
	if json.has(game_mode):
		variation_needed.append(game_mode)
		used_default = false
		
		if json.get(game_mode).has("link"):
			json = get_variation_json(json[json.get(game_mode).get("link")])
		else:
			json = get_variation_json(json[game_mode])
	
	var chara = "Character:" + Player.CHARACTERS[int(Global.player_characters[0])]
	if json.has(chara) == false:
		chara = "Character:default"
	if json.has(chara):
		variation_needed.append(chara)
		used_default = false
		
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
		variation_needed.append(boo)
		used_default = false
		
		if json.get(boo).has("link"):
			json = get_variation_json(json[json.get(boo).get("link")])
		else:
			json = get_variation_json(json[boo])
			
	var meta_data_keys := json.keys().filter(func(key): return key.contains("Metadata") && key.contains("LevelMetadata") == false)
	if meta_data_keys.is_empty() == false:
		is_variable = true
		for i in meta_data_keys:
			var meta_name = i.get_slice(":", 1)
			var node_to_use = metadata_node
			if node_to_use == null:
				node_to_use = owner
			var meta_value = str(node_to_use.get_meta(meta_name, "Default")) if node_to_use != null else "Default"
			var meta_json = null
			
			if json[i].has(meta_value):
				meta_json = json[i].get(meta_value)
			elif json[i].has("Default"):
				meta_json = json[i].get("Default")
			if meta_json != null:
				variation_needed.append(meta_value)
				used_default = false
				if meta_json.has("link"):
					json = get_variation_json(json[i][meta_json.get("link")])
				else:
					json = get_variation_json(meta_json)
				break
	
	meta_data_keys = json.keys().filter(func(key): return key.contains("LevelMetadata"))
	if meta_data_keys.is_empty() == false:
		is_variable = true
		for i in meta_data_keys:
			var meta_name = i.get_slice(":", 1)
			var meta_value = str(Global.level_metadata.get(meta_name, "Default"))
			var meta_json = null
			if json[i].has(meta_value):
				meta_json = json[i].get(meta_value)
			elif json[i].has("Default"):
				meta_json = json[i].get("Default")
			if meta_json != null:
				variation_needed.append(meta_value)
				used_default = false
				if meta_json.has("link"):
					json = get_variation_json(json[i][meta_json.get("link")])
				else:
					json = get_variation_json(meta_json)
				break
	
	if (json.has("default") && used_default):
		variation_needed.append("default")
		
	return json

func get_config_file(resource_pack := "") -> void:
	var config_file_path: String = Global.config_path.path_join("resource_packs/" + resource_pack + "/config.json")
	if FileAccess.file_exists(config_file_path):
		config_to_use = JSONParser.parse_to_dict(config_file_path)

func get_resource_pack_path(res_path := "", resource_pack := "") -> String:
	var user_path := res_path.replace("res://Assets", Global.config_path.path_join("resource_packs/" + resource_pack))
	user_path = user_path.replace(Global.config_path.path_join("custom_characters"), Global.config_path.path_join("resource_packs/" + resource_pack + "/Sprites/Players/CustomCharacters/"))
	if FileAccess.file_exists(user_path):
		return user_path
	else:
		return res_path

func create_sprite_frames_from_image(image: Resource, animation_json := {}, resource_path := "") -> SpriteFrames:
	var image_region_end = image.get_size()
	
	var sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	var loop_offsets := {}
	for anim_name in animation_json.keys():
		if animation_json[anim_name].has("link"):
			animation_json[anim_name] = animation_json[animation_json[anim_name].link]
		sprite_frames.add_animation(anim_name)
		if (animation_json[anim_name].has("frames")):
			for frame in animation_json[anim_name].frames:
				var frame_texture = AtlasTexture.new()
				frame_texture.atlas = image
				
				if (frame.size() != 4):
					log_error("Animation frame for resource: \"%s\" has incorrect rect size, should be 4 but is: %s. \"%s\":Frame%s" % [resource_path, str(frame.size()), anim_name, str(animation_json[anim_name].frames.find(frame))])
					continue
				if (animation_json[anim_name].has("loop")):
					sprite_frames.set_animation_loop(anim_name, animation_json[anim_name].loop)
					if animation_json[anim_name].has("loop_offset") and node_to_affect is AnimatedSprite2D:
						loop_offsets[anim_name] = animation_json[anim_name].get("loop_offset", 0)
						node_to_affect.animation_looped.connect(on_animation_looped.bind(anim_name, animation_json[anim_name].get("loop_offset", 0)))
				else:
					log_warning("Animation frame for resource: \"%s\" has no loop set: \"%s\":Frame%s" % [resource_path, anim_name, str(animation_json[anim_name].frames.find(frame))])
				if (animation_json[anim_name].has("speed")):
					sprite_frames.set_animation_speed(anim_name, animation_json[anim_name].speed)
				else:
					log_warning("Animation frame for resource: \"%s\" has no speed set: \"%s\":Frame%s" % [resource_path, anim_name, str(animation_json[anim_name].frames.find(frame))])
				
				frame_texture.region = Rect2(int(frame[0]), int(frame[1]), int(frame[2]), int(frame[3]))
				frame_texture.filter_clip = true
				sprite_frames.add_frame(anim_name, frame_texture)
				
				if (frame_texture.region.end > image_region_end):
					log_warning("Animation frame for resource: \"%s\" exceeds the base rect region: \"%s\":Frame%s" % [resource_path, anim_name, str(animation_json[anim_name].frames.find(frame))])
				
	sprite_frames.set_meta("loop_offsets", loop_offsets)
	return sprite_frames

static func clear_cache() -> void:
	for i in cache.keys():
		if cache[i] == null:
			cache.erase(i)
	surpress_warnings = null
	cache.clear()
	material_cache.clear()
	active_flags.clear()
	property_cache.clear()
	sequences.clear()

func load_image_from_path(path := "") -> Texture2D:
	if path.contains("res://"):
		if path.contains("NULL"):
			return null
		return load(path)
	var image = Image.new()
	image.load(path)
	return ImageTexture.create_from_image(image)

func sync_metadata() -> void:
	for i in sync:
		copy_meta(i)

func clear_metadata() -> void:
	for meta in get_meta_list():
		remove_meta(meta)

func copy_meta(new_node: Node) -> void:
	for meta in get_meta_list():
		new_node.set_meta(meta, get_meta(meta))

func log_error(msg := "", can_spam := true, timer := 10) -> void:
	if surpress_errors == false:
		Global.log_error(msg, can_spam, timer)

func log_warning(msg := "", timer := 10) -> void:
	if surpress_warnings == null:
		surpress_warnings = !is_warnings_enabled()
	if surpress_warnings == false:
		Global.log_warning(msg, timer)

func is_warnings_enabled() -> bool:
	var pack_json = JSONParser.parse_to_dict(Global.get_config_path().path_join("/resource_packs/" + current_resource_pack + "/pack_info.json"))
	if pack_json.get("show_warnings", false):
		return true
	return false

func set_material(blend_mode := "mix") -> void:
	if node_to_affect is not CanvasItem or node_to_affect.material is ShaderMaterial:
		return
	var particle_animation := false
	if node_to_affect.material is CanvasItemMaterial:
		node_to_affect.material.blend_mode = {
			"mix": 0,
			"add": 1,
			"sub": 2,
			"mult": 3
		}[blend_mode]
	elif blend_mode != "mix":
		const MATERIALS := {
			"add": "res://Resources/Materials/Add.tres",
			"mult": "res://Resources/Materials/Mult.tres",
			"sub": "res://Resources/Materials/Sub.tres",
		}
		node_to_affect.material = load(MATERIALS[blend_mode])
		node_to_affect.material.set_particles_animation(particle_animation)
	elif node_to_affect.material != null:
		if node_to_affect.material.resource_path.has("res://"):
			node_to_affect.material = null

func on_animation_looped(anim_name := "", loop_offset := 0) -> void:
	var sprite: AnimatedSprite2D = node_to_affect
	if sprite.animation == anim_name:
		sprite.set_frame_and_progress(loop_offset, 0)
