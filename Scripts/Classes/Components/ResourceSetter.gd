class_name ResourceSetter
extends Node

@export var node_to_affect: Node = null
@export var property_name := ""
@export var themed_resource: ThemedResource = null
@export var use_classic_theming := false
@export var use_cache := true

signal sprites_updated

static var cache := {}

func _ready() -> void:
	Global.level_theme_changed.connect(update_sprites)
	update_sprites()

func update_sprites() -> void:
	cache.clear()
	if themed_resource == null:
		node_to_affect.set(property_name, null)
		return
	var resource = get_resource(themed_resource, node_to_affect, true, use_cache)
	node_to_affect.set(property_name, resource)
	if node_to_affect is AnimatedSprite2D:
		node_to_affect.play()
	sprites_updated.emit()

static func get_resource(resource: Resource, node: Node = null, assign := false, cache_enabled := true) -> RefCounted:
	if resource == null:
		return resource
	var og_path = resource.resource_path
	if resource is AtlasTexture:
		og_path = resource.atlas.resource_path
	if resource is ThemedResource:
		if resource.get(Global.level_theme) != null:
			resource = get_resource(resource.get(Global.level_theme))
		else:
			resource = get_resource(resource.Overworld)
	if resource is CampaignResource:
		if resource.get(Global.current_campaign) != null:
			resource = get_resource(resource.get(Global.current_campaign))
		else:
			resource = get_resource(resource.SMB1)

	if assign:
		if resource is AtlasTexture:
			resource.filter_clip = true
		if resource is SpriteFrames:
			if node is not AnimatedSprite2D:
				resource = resource.get_frame_texture(resource.get_animation_names()[0], 0)
	if Settings.file.visuals.resource_packs.is_empty() == false:
		for i in Settings.file.visuals.resource_packs:
			resource = get_override_resource(resource, i)
	if cache.has(og_path) == false:
		cache[og_path] = resource.duplicate()
	if resource == null:
		pass
	return resource

static func get_override_resource(resource: Resource = null, resource_pack := "") -> Object:
	if resource == null:
		return
	if resource_pack == "":
		return
	var original_resource_path = resource.resource_path
	var resource_path = get_override_resource_path(resource.resource_path, resource_pack)
	if FileAccess.file_exists(resource_path):
		if resource is Texture:
			resource = create_image_from_path(resource_path)
		elif resource is SpriteFrames:
			resource = create_new_sprite_frames(resource, resource_pack)
		if resource is AudioStream:
			if resource_path.contains(".mp3"):
				var resource_loops = resource.has_loop()
				resource = AudioStreamMP3.load_from_file(resource_path)
				resource.set_loop(resource_loops)
			elif resource_path.contains(".wav"):
				resource = AudioStreamWAV.load_from_file(resource_path)
		if resource is FontVariation:
			resource_path = get_override_resource_path(resource.base_font.resource_path, resource_pack)
			if FileAccess.file_exists(resource_path):
				var new_font = FontFile.new()
				var variation = resource.duplicate()
				new_font.load_bitmap_font(resource_path.replace(".png", ".fnt"))
				variation.base_font = new_font
				resource = variation
	else:
		if resource is SpriteFrames:
			resource = create_new_sprite_frames(resource, resource_pack)
		if resource is AtlasTexture:
			resource_path = get_override_resource_path(resource.atlas.resource_path, resource_pack)
			if FileAccess.file_exists(resource_path):
				var new_resource = AtlasTexture.new()
				new_resource.atlas = create_image_from_path(get_override_resource_path(resource.atlas.resource_path, resource_pack))
				new_resource.region = resource.region
				return new_resource
		if resource is AudioStreamInteractive:
			resource = get_override_resource(resource.get_clip_stream(0), resource_pack)
		if resource is FontVariation:
			resource_path = get_override_resource_path(resource.base_font.resource_path, resource_pack)
			if FileAccess.file_exists(resource_path):
				var new_font = FontFile.new()
				var variation = resource.duplicate()
				new_font.load_bitmap_font(resource_path.replace(".png", ".fnt"))
				variation.base_font = new_font
				resource = variation
	return resource

static func create_image_from_path(file_path := "") -> ImageTexture:
	var image = Image.new()
	image.load(file_path)
	return ImageTexture.create_from_image(image)

static func create_new_sprite_frames(old_sprite_frames: SpriteFrames, resource_pack := "") -> SpriteFrames:
	var new_frames = SpriteFrames.new()
	new_frames.remove_animation("default")
	for i in old_sprite_frames.get_animation_names():
		new_frames.add_animation(i)
		for x in old_sprite_frames.get_frame_count(i):
			var frame = AtlasTexture.new()
			var old_frame = old_sprite_frames.get_frame_texture(i, x)
			frame.atlas = get_override_resource(old_frame.atlas, resource_pack)
			frame.region = old_frame.region
			new_frames.add_frame(i, frame, old_sprite_frames.get_frame_duration(i, x))
			new_frames.set_animation_loop(i, old_sprite_frames.get_animation_loop(i))
			new_frames.set_animation_speed(i, old_sprite_frames.get_animation_speed(i))
	return new_frames

static func get_pure_resource_path(resource_path := "") -> String:
	if Settings.file.visuals.resource_packs.is_empty() == false:
		for i in Settings.file.visuals.resource_packs:
			var new_path = get_override_resource_path(resource_path, i)
			new_path = new_path.replace(Global.config_path.path_join("custom_characters"), Global.config_path.path_join("resource_packs/" + new_path + "/Sprites/Players/CustomCharacters/"))
			if FileAccess.file_exists(new_path):
				return new_path
	return resource_path

static func get_override_resource_path(resource_path := "", resource_pack := "") -> String:
	if resource_pack != "":
		return resource_path.replace("res://Assets", Global.config_path.path_join("resource_packs/" + resource_pack))
	else:
		return resource_path
