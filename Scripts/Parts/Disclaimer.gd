extends Node

var can_skip := false

@export var default_font: Font = null

func _enter_tree() -> void:
	if Settings.file.game.lang != "jp":
		for i in [$Title, $"1", $"2", $Enjoy]:
			i.remove_theme_font_override("font")
			i.uppercase = true

func _ready() -> void:
	var animation: Animation = $AnimationPlayer.get_animation_library("").get_animation(&"Go")
	var track: int = animation.find_track("AudioStreamPlayer", Animation.TYPE_AUDIO)
	for key in animation.track_get_key_count(track):
		var resource_getter = ResourceGetter.new() #Why do I have to make a new one each time?
		animation.audio_track_set_key_stream(track, key, resource_getter.get_resource(animation.audio_track_get_key_stream(track, key)))
	Global.debugged_in = false
	Global.get_node("GameHUD").hide()
	await get_tree().create_timer(1, false).timeout
	can_skip = true

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and can_skip:
		go_to_menu()

func go_to_menu() -> void:
	ResourceGenerator.updating = true
	if Global.rom_path == "":
		Global.transition_to_scene("res://Scenes/Levels/RomVerifier.tscn")
	elif not Global.rom_assets_exist:
		Global.transition_to_scene("res://Scenes/Levels/RomResourceGenerator.tscn")
	else:
		Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
