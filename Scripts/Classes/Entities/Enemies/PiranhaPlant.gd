extends Enemy

@export var player_range := 24

@export_enum("Up", "Down", "Left", "Right") var plant_direction := 0

func _enter_tree() -> void:
	$Animation.play("Hide")

func _ready() -> void:
	if is_equal_approx(abs(global_rotation_degrees), 180) == false:
		$Sprite/Hitbox/UpsideDownExtension.queue_free()
	$Timer.start()

func on_timeout() -> void:
	var player = get_tree().get_first_node_in_group("Players")
	if plant_direction < 2:
		if abs(player.global_position.x - global_position.x) >= player_range:
			$Animation.play("Rise")
	elif (abs(player.global_position.y - global_position.y) >= player_range and abs(player.global_position.x - global_position.x) >= player_range * 2):
			$Animation.play("Rise")
