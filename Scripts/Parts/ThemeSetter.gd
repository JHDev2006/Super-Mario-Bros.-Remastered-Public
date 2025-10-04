class_name ThemeSetter
extends ResourceSetterNew

const MUSIC_TRACKS := {
	"Overworld": "res://Assets/Audio/BGM/Overworld.json",
	"Underground": "res://Assets/Audio/BGM/Underground.json",
	"Desert": "res://Assets/Audio/BGM/Desert.json",
	"Snow": "res://Assets/Audio/BGM/Snow.json",
	"Jungle": "res://Assets/Audio/BGM/Jungle.json",
	"Beach": "res://Assets/Audio/BGM/Beach.json",
	"Garden": "res://Assets/Audio/BGM/Garden.json",
	"Mountain": "res://Assets/Audio/BGM/Mountain.json",
	"Skyland": "res://Assets/Audio/BGM/Sky.json",
	"Autumn": "res://Assets/Audio/BGM/Autumn.json",
	"Pipeland": "res://Assets/Audio/BGM/Pipeland.json",
	"Space": "res://Assets/Audio/BGM/Space.json",
	"Underwater": "res://Assets/Audio/BGM/Underwater.json",
	"Volcano": "res://Assets/Audio/BGM/Volcano.json",
	"GhostHouse": "res://Assets/Audio/BGM/GhostHouse.json",
	"Castle": "res://Assets/Audio/BGM/Castle.json",
	"CastleWater": "res://Assets/Audio/BGM/Underwater.json",
	"Airship": "res://Assets/Audio/BGM/Airship.json",
	"Bonus": "res://Assets/Audio/BGM/Bonus.json"
}

@export var theme_data: JSON
@export var change_theme := false
@export var sync_music := true

var updating := false

static var music: JSON
static var music_to_replace := ""

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
	resource = load(resource_path)
	var json = source_json.duplicate()
	if json.has("variations"):
		json = get_variation_json(json.variations)
	if json.has("properties"):
		apply_properties(json.get("properties"))
		if use_cache:
			property_cache[json_file.resource_path] = json.properties.duplicate()
	elif source_json.has("properties"):
		apply_properties(source_json.get("properties"))
		if use_cache:
			property_cache[json_file.resource_path] = source_json.properties.duplicate()
	if cache.has(json_file.resource_path) == false and use_cache and not is_random:
		cache[json_file.resource_path] = resource
	return resource

func update_resource() -> void:
	if is_inside_tree() == false or is_queued_for_deletion() or resource_json == null or node_to_affect == null or updating:
		return
	super()
	force_properties = {
		"Theme": get_default_theme(),
		"Time": get_default_time()
	}
	if theme_data != null and theme_data.data.has("variations"):
		set_theme(get_variation_json(theme_data.data.variations))
	else:
		set_theme()

func set_theme(json := {}) -> void:
	updating = true
	if change_theme:
		if json.has("theme") and json.theme is String and Level.THEME_IDXS.has(json.theme):
			Global.level_theme = json.theme
			if sync_music:
				music = load(MUSIC_TRACKS[json.theme])
				music_to_replace = MUSIC_TRACKS[get_default_theme()]
			else:
				music = null
				music_to_replace = ""
		else:
			Global.level_theme = get_default_theme()
			music = null
			music_to_replace = ""
		if json.has("time") and json.time is String and ["Day", "Night"].has(json.time):
			Global.theme_time = json.time
		else:
			Global.theme_time = get_default_time()
	else:
		Global.level_theme = get_default_theme()
		Global.theme_time = get_default_time()
		music = null
		music_to_replace = ""
	updating = false

func get_level() -> Level:
	if Global.current_level != null:
		return Global.current_level
	var scene := get_tree().current_scene
	if scene is Level:
		return scene
	return null

func get_default_theme() -> String:
	var level := get_level()
	if level != null:
		if level.auto_set_theme:
			return Level.WORLD_THEMES[Global.current_campaign][Global.world_num]
		else:
			return level.theme
	return "Overworld"

func get_default_time() -> String:
	var level := get_level()
	if level != null:
		if level.auto_set_theme:
			if range(4, 9).has(Global.world_num) or Global.current_campaign == "SMBANN":
				return "Night"
			else:
				return "Day"
		else:
			return level.theme_time
	return "Day"
