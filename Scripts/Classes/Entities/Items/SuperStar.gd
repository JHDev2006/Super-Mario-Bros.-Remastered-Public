extends PowerUpItem

@export var star_bgm: AudioStream = null

func _physics_process(delta: float) -> void:
	$BasicEnemyMovement.handle_movement(delta)

func collect_item(player: Player) -> void:
	collected.emit()
	player.super_star()
	AudioManager.play_sfx("power_up", global_position)
	queue_free()
