class_name ResourceGetter
extends Node

var original_resource: Resource = null

static var cache := {}

func get_resource(resource: Resource) -> Resource:
	if resource == null:
		return null

	if original_resource == null:
		original_resource = resource
	
	if cache.has(original_resource.resource_path) and resource is not AtlasTexture:
		return cache.get(original_resource.resource_path)
		
	var path := ""
	if original_resource is AtlasTexture:
		path = get_resource_path(original_resource.atlas.resource_path)
	else:
		path = get_resource_path(original_resource.resource_path)
	
	if path == original_resource.resource_path:
		return original_resource
	
	if original_resource is Texture:
		var new_resource = null
		if path.contains(Global.config_path):
			new_resource = ImageTexture.create_from_image(Image.load_from_file(path))
		else: 
			new_resource = load(path)
		send_to_cache(original_resource.resource_path, new_resource)
		if original_resource is AtlasTexture:
			var atlas = AtlasTexture.new()
			atlas.atlas = new_resource
			atlas.region = original_resource.region
			return atlas
		return new_resource
	
	elif original_resource is AudioStream:
		if path.get_file().contains(".wav"):
			var new_resource = AudioStreamWAV.load_from_file(path)
			send_to_cache(original_resource.resource_path, new_resource)
			return new_resource
		elif path.get_file().contains(".mp3"):
			var new_resource = AudioStreamMP3.load_from_file(path)
			send_to_cache(original_resource.resource_path, new_resource)
			return new_resource
	
	elif original_resource is Font:
		var new_font = FontFile.new()
		new_font.load_bitmap_font(path)
		send_to_cache(original_resource.resource_path, new_font)
		return new_font
	
	elif original_resource is JSON:
		var new_json = JSON.new()
		new_json.parse(FileAccess.get_file_as_string(path))
		send_to_cache(original_resource.resource_path, new_json)
		return new_json
	
	send_to_cache(original_resource.resource_path, original_resource)

	return original_resource

func send_to_cache(resource_path := "", resource_to_cache: Resource = null) -> void:
	if cache.has(resource_path) == false:
		cache.set(resource_path, resource_to_cache)

func get_resource_path(resource_path := "") -> String:
	for i in Settings.file.visuals.resource_packs:
		var test = resource_path.replace("res://Assets/", Global.config_path.path_join("resource_packs/" + i + "/"))
		if FileAccess.file_exists(test):
			return test
	return resource_path
