extends PowerUpState

var fireball_amount := 0
const FIREBALL = preload("res://Scenes/Prefabs/Entities/Items/Fireball.tscn")
func update(delta: float) -> void:
	if Global.player_action_just_pressed("action", player.player_id) and fireball_amount < 2 and player.state_machine.state.name == "Normal" and delta > 0:
		throw_fireball()

func throw_fireball() -> void:
	var node = FIREBALL.instantiate()
	node.character = player.character
	node.global_position = player.global_position - Vector2(-4 * player.direction, 16 * player.gravity_vector.y)
	node.direction = player.direction
	node.velocity.y = 100
	player.call_deferred("add_sibling", node)
	fireball_amount += 1
	node.tree_exited.connect(func(): fireball_amount -= 1)
	AudioManager.play_sfx("fireball", player.global_position)
	player.attacking = true
	await get_tree().create_timer(0.1, false).timeout
	player.attacking = false
