extends EntityGenerator


const new_vector = Vector2.UP

func activate() -> void:
	for i in get_tree().get_nodes_in_group("Players"):
		on_player_entered(i)

func deactivate() -> void:
	for i in get_tree().get_nodes_in_group("Players"):
		on_player_exited(i)

func on_player_entered(player: Player) -> void:
	if player.gravity_vector == new_vector:
		return
	player.gravity_vector = new_vector
	player.global_position.y -= 16
	player.global_rotation = -player.gravity_vector.angle() + deg_to_rad(90)
	player.get_node("CameraHandler").global_rotation = 0
	player.get_node("CameraHandler").position.x = 0
	player.get_node("CameraHandler").can_diff = false
	player.reset_physics_interpolation()

func on_player_exited(player: Player) -> void:
	if player.gravity_vector == Vector2.DOWN:
		return
	player.gravity_vector = Vector2.DOWN
	player.global_position.y += 16
	player.velocity.y *= 1.1
	player.global_rotation = -player.gravity_vector.angle() + deg_to_rad(90)
	player.get_node("CameraHandler").position.x = 0
	player.reset_physics_interpolation()
