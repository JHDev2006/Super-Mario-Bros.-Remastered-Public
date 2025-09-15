extends Enemy

func _ready() -> void:
	direction = sign(get_viewport().get_camera_2d().get_screen_center_position().x - global_position.x)
	velocity.x = randf_range(50, 200) * direction
	velocity.y = randf_range(-250, -350)
	$Sprite.scale.x = direction
	setup_line()
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_sfx("cheep_cheep", global_position)


func setup_line() -> void:
	$Line2D.clear_points()
	var line_velocity = velocity
	var line_position = $Sprite.global_position
	for i in 200:
		line_position += line_velocity * 0.016
		line_velocity.y += (5 / 0.016) * 0.016
		$Line2D.add_point(line_position)

func _physics_process(delta: float) -> void:
	velocity.y += (5) * delta * 60.0
	$Line2D.remove_point(0)
	if global_position.y > 64 and velocity.y > 0:
		queue_free()
	move_and_slide()
