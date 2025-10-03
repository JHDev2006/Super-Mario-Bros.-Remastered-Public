class_name BrickBlock
extends Block

var ticking_down := false

func _ready() -> void:
	if item_amount == 10 and item.resource_path == "res://Scenes/Prefabs/Entities/Items/SpinningCoin.tscn" and is_instance_valid(Global.level_editor) == false:
		Global.log_warning("Coin Brick Block is wrong! please report!: " + name)

func check_brick_empty() -> void:
	$PSwitcher.enabled = item == null

func on_block_hit(player: Player) -> void:
	if player.power_state.hitbox_size == "Big":
		if item == null:
			await get_tree().physics_frame
			destroy()
			Global.score += 50
	if item != null:
		if mushroom_if_small:
			item = player_mushroom_check(player)
		dispense_item()

func on_shell_block_hit(_shell: Shell) -> void:
	if item == null:
		await get_tree().physics_frame
		destroy()
		Global.score += 50
	else:
		dispense_item()

func set_coin_count() -> void:
	if has_meta("r_coin_id") and Global.current_game_mode == Global.GameMode.CHALLENGE:
		item = load("res://Scenes/Prefabs/Entities/Items/SpinningRedCoin.tscn")
	item_amount = 1
