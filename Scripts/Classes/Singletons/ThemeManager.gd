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

var current_json: JSON
var sync_music := true

func _ready() -> void:
	pass

func on_updated() -> void:
	if current_json != null and current_json.data.has("variations"):
		var json := get_variation_json(current_json.data.variations)
		if json.has("theme") and Level.THEME_IDXS.has(json.theme):
			print("SYNC:", sync_music)
			if sync_music:
				Global.force_music = load(MUSIC_TRACKS[json.theme])
				Global.music_to_replace = MUSIC_TRACKS[Global.level_theme]
			Global.force_theme = json.theme
		if json.has("time") and ["Day", "Night"].has(json.time):
			Global.force_time = json.time

func get_resource(json_file: JSON) -> Resource:
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
	if json.has("variations"):
		json = get_variation_json(json.variations)
	if json.has("properties"):
		apply_properties(json.get("properties"))
	elif source_json.has("properties"):
		apply_properties(source_json.get("properties"))
	return load(resource_path)
