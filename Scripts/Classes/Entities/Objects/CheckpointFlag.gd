extends Node2D
@onready var sprite: AnimatedSprite2D = $"../Sprite"
@onready var activated: AnimatedSprite2D = $"../Activated"

static var character_save := "Mario"

func _ready() -> void:
	activated.get_node("ResourceSetterNew").resource_json = load(get_character_sprite_path(0))
	if Settings.file.difficulty.checkpoint_style == 0 and (Global.current_game_mode != Global.GameMode.LEVEL_EDITOR and Global.current_game_mode != Global.GameMode.CUSTOM_LEVEL) or Global.current_campaign == "SMBANN":
		owner.queue_free()
		return
	owner.show()
	if owner.passed:
		sprite.hide()
		activated.show()

func get_character_sprite_path(player_id := 0) -> String:
	var character = Player.CHARACTERS[int(Global.player_characters[player_id])]
	var path = "res://Assets/Sprites/Players/" + character + "/CheckpointFlag.json"
	if int(Global.player_characters[player_id]) > 3:
		path = path.replace("res://Assets/Sprites/Players", "user://custom_characters")
	return path

func activate(player: Player) -> void:
	character_save = player.character
	sprite.play("Hit")
	await get_tree().physics_frame
	await sprite.animation_finished
	sprite.hide()
	activated.show()
