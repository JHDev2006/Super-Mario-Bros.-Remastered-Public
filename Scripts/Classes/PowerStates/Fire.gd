extends PowerUpState

var projectile_amount := 0
@export var projectile_scene: PackedScene = null
@export var shoot_sfx := ""
func update(delta: float) -> void:
	if Global.player_action_just_pressed("action", player.player_id) and projectile_amount < 2 and player.state_machine.state.name == "Normal" and delta > 0:
		throw_fireball()

func throw_fireball() -> void:
	var node = projectile_scene.instantiate()
	player.attacked.emit()
	node.character = player.character
	node.global_position = player.global_position - Vector2(-4 * player.direction, player.shoot_height * player.gravity_vector.y)
	node.direction = player.direction
	node.velocity.y = 100
	player.call_deferred("add_sibling", node)
	projectile_amount += 1
	node.tree_exited.connect(func(): projectile_amount -= 1)
	AudioManager.play_sfx(shoot_sfx, player.global_position)
	player.attacking = true
	for i in 2:
		await get_tree().physics_frame
	var time = player.calculate_await_time()
	await get_tree().create_timer(time, false).timeout
	player.attacking = false
