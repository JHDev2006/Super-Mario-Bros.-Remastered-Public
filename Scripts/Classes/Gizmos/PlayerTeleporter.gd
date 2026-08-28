extends Node2D

func teleport_player() -> void:
	for i: Player in get_tree().get_nodes_in_group("Players"):
		var target_position = global_position + Vector2(0, 8)
		if i.gravity_vector == Vector2.UP:
			target_position.y -= 16
		i.teleport_player(target_position)
