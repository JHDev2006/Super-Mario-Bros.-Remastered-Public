@tool
class_name ThemedToJSONConverter
extends Node

@export var resource: ThemedResource = null
@export_file("*.json") var json_file_path := ""

@export_tool_button("Convert!") var button = convert_to_json

var json := {}

const THEMES := ["Overworld", "Underground", "Desert", "Snow", "Jungle", "Underwater", "Castle", "Sky", "Volcano", "Garden", "Beach"]
const CAMPAIGNS := ["SMB1", "SMBLL", "SMBS", "SMBANN"]
var animation_json := {}
var variation_json := {}

var donor_sprite_frames: SpriteFrames = null

func convert_to_json() -> void:
	donor_sprite_frames = null
	variation_json.clear()
	animation_json.clear()
	json.clear()
	variation_json = get_variation_values(resource)
	if donor_sprite_frames != null:
		animation_json = get_animations()
	if animation_json.is_empty() == false:
		json["animations"] = animation_json
	json["variations"] = variation_json
	var json_file = JSON.stringify(json, "\t", false)
	var file = FileAccess.open(json_file_path, FileAccess.WRITE)
	file.store_string(json_file)
	file.close()
	print("Done!")

func get_variation_values(variation_resource: Resource) -> Dictionary:
	var val_dict := {}
	for i in get_value_list(variation_resource):
		if variation_resource.get(i) != null:
			if variation_resource.get(i) is not ThemedResource and variation_resource.get(i) is not TimedResource and variation_resource.get(i) is not CampaignResource:
				var value = {}
				if variation_resource.get(i) is SpriteFrames and donor_sprite_frames == null:
					donor_sprite_frames = variation_resource.get(i)
				value["source"] = get_source(variation_resource.get(i))
				if variation_resource.get(i) is SpriteFrames:
					value["rect"] = get_sprite_frames_rect(variation_resource.get(i))
				if variation_resource.get(i) is AtlasTexture:
					var rect: Rect2 = variation_resource.get(i).region
					value["rect"] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
				val_dict[i] = value
			else:
				val_dict[i] = get_variation_values(variation_resource.get(i))
			if i == "Overworld":
				val_dict["default"] = val_dict[i]
	if val_dict.size() == 2:
		val_dict.erase("Overworld")
	return val_dict

func get_value_list(value_resource: Resource) -> Array:
	if value_resource is ThemedResource:
		return THEMES
	if value_resource is CampaignResource:
		return CAMPAIGNS
	if value_resource is TimedResource:
		return ["Day", "Night"]
	else:
		return []

func get_sprite_frames_rect(sprite_frames: SpriteFrames) -> Array:
	var rects := []
	for i in sprite_frames.get_animation_names():
		for x in sprite_frames.get_frame_count(i):
			var region = sprite_frames.get_frame_texture(i, x).region
			rects.append(region)
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for rect in rects:
		var pos = rect.position
		var end = rect.position + rect.size
		
		min_x = min(min_x, pos.x)
		min_y = min(min_y, pos.y)
		max_x = max(max_x, end.x)
		max_y = max(max_y, end.y)
	
	var max_rect = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	
	return [max_rect.position.x, max_rect.position.y, max_rect.size.x, max_rect.size.y]

func get_animations() -> Dictionary:
	var dict := {}
	var bound_rect = get_sprite_frames_rect(donor_sprite_frames)
	for i in donor_sprite_frames.get_animation_names():
		var anim_dict = {}
		var frame_arr := []
		for x in donor_sprite_frames.get_frame_count(i):
			var rect: Rect2 = donor_sprite_frames.get_frame_texture(i, x).region
			for y in donor_sprite_frames.get_frame_duration(i, x):
				frame_arr.append([rect.position.x - bound_rect[0], rect.position.y - bound_rect[1], rect.size.x, rect.size.y])
		anim_dict["frames"] = frame_arr
		anim_dict["speed"] = donor_sprite_frames.get_animation_speed(i)
		anim_dict["loop"] = donor_sprite_frames.get_animation_loop(i)
		dict[i] = anim_dict
	return dict

func get_source(source_resource: Resource) -> String:
	if source_resource is AtlasTexture:
		return source_resource.atlas.resource_path.get_file()
	if source_resource is Texture2D:
		return source_resource.resource_path.get_file()
	if source_resource is SpriteFrames:
		var texture = source_resource.get_frame_texture(source_resource.get_animation_names()[0], 0)
		if texture is AtlasTexture:
			return texture.atlas.resource_path.get_file()
		else:
			return texture.resource_path.get_file()
	if source_resource.resource_path.get_file():
		return 	source_resource.resource_path.get_file()
	else:
		return ""
