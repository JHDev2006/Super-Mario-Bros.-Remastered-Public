extends Enemy

var direction_vector := Vector2.UP

const MOVE_SPEED := 70.0

func _physics_process(delta: float) -> void:
	global_position += direction_vector * MOVE_SPEED * delta

func stomped(player: Player) -> void:
	player.enemy_bounce_off(true)
	AudioManager.play_sfx("enemy_stomp", global_position)
	$GibSpawner.summon_gib(1, false, 1)
	queue_free()
