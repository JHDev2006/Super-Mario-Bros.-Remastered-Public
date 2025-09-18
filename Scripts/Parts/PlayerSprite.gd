class_name PlayerSprite
extends AnimatedSprite2D

@export var player_id := 0
@export var force_power_state := ""
@export var force_character := ""
var character := ""

@export var resource_setter: ResourceSetterNew

func _ready() -> void:
	Global.player_characters_changed.connect(update)
	Global.level_theme_changed.connect(update)
	animation_changed.connect(on_animation_changed)
	update()

func update() -> void:
	character = Player.CHARACTERS[int(Global.player_characters[player_id])]
	var power_state = Global.player_power_states[player_id]
	if force_power_state != "":
		power_state = force_power_state
	if force_character != "":
		character = force_character
	if resource_setter != null:
		var path = "res://Assets/Sprites/Players/" + character + "/" + Player.POWER_STATES[int(power_state)] + ".json"
		if Player.CHARACTERS.find(character) > 3:
			path = path.replace("res://Assets/Sprites/Players/", Global.config_path.path_join("custom_characters/"))
		var json = resource_setter.get_resource(load(path))
		sprite_frames = json
		if sprite_frames == null: 
			return
		if sprite_frames.get_frame_texture(animation, frame):
			offset.y = -(sprite_frames.get_frame_texture(animation, frame).get_height() / 2.0)

func on_animation_changed() -> void:
	if sprite_frames.has_animation(animation) == false and Player.ANIMATION_FALLBACKS.has(animation):
		play(Player.ANIMATION_FALLBACKS[animation])
