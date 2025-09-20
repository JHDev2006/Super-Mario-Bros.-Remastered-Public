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
	if Checkpoint.passed:
		sprite.hide()
		activated.show()

func get_character_sprite_path(player_id := 0) -> String:
	var char_idx = int(Global.player_characters[player_id])
	var character = Player.CHARACTERS[char_idx]
	if char_idx > 3:
		var path = Global.config_path.path_join("custom_characters").path_join(character).path_join("CheckpointFlag.json")
		return path
	else:
		return "res://Assets/Sprites/Players".path_join(character).path_join("CheckpointFlag.json")

func activate(player: Player) -> void:
	character_save = player.character
	sprite.play("Hit")
	await get_tree().physics_frame
	await sprite.animation_finished
	sprite.hide()
	activated.show()
