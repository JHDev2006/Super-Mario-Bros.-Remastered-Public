extends StaticBody2D

var valid := false

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Players")
	if player.is_on_floor() == false and not $Area2D.get_overlapping_areas().any(func(area: Area2D): return area.owner is Player):
		valid = (player.direction == -1 and player.crouching and player.call("physics_params", "CAN_BE_WALL_EJECTED"))
	$CollisionShape2D.set_deferred("one_way_collision", valid)
