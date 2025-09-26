class_name CoinHeaven
extends Level

@export var all_coins_check: AllCoinsCollectedCheck = null

func _ready() -> void:
	Level.in_vine_level = true

func warp_back(player: Player) -> void:
	player.state_machine.transition_to("Freeze")
	if all_coins_check != null:
		await all_coins_check.check()
	await get_tree().create_timer(1, false).timeout
	PipeArea.exiting_pipe_id = -1
	Global.transition_to_scene(Level.vine_return_level)
