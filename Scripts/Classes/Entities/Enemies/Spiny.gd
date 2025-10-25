extends Enemy

var in_egg := false

const MOVE_SPEED := 40

func _physics_process(delta: float) -> void:
	handle_movement(delta)

func handle_movement(_delta: float) -> void:
	if in_egg:
		$BasicEnemyMovement.move_speed = 0
		$BasicEnemyMovement.second_quest_speed = 0
		if is_on_floor():
			var player = get_tree().get_first_node_in_group("Players")
			direction = sign(player.global_position.x - global_position.x)
			$BasicEnemyMovement.move_speed = 32
			$BasicEnemyMovement.second_quest_speed = 36
			in_egg = false
		$Sprite.play("Egg")
	else:
		$Sprite.play("Walk")
		$Sprite.scale.x = direction
	
