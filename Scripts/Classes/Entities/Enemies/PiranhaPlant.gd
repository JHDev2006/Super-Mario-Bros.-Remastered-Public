extends Enemy

@export var player_range := 24

@export_enum("Up", "Down", "Left", "Right") var pipe_direction := 0

@export var rise_animation := "Rise"

@export var upside_down_hitbox: Node2D = null

func _ready() -> void:
	$Animation.play("RESET")
	$Animation.play("Hide")
	if abs(global_rotation_degrees) >= 178:
		pipe_direction = 1
		global_rotation_degrees = 0
		global_position.y += 16
		$RotationJoint.global_rotation_degrees = 180
	$Timer.start()

func on_timeout() -> void:
	upside_down_hitbox.set_deferred("disabled", abs($RotationJoint.global_rotation_degrees) > 90 == false)
	var player = get_tree().get_first_node_in_group("Players")
	$RotationJoint/PositionJoint/Visuals/Hitbox.set_deferred("monitoring", true)
	if pipe_direction < 2:
		if abs(player.global_position.x - global_position.x) >= player_range:
			$Animation.play(rise_animation)
	elif (abs(player.global_position.y - global_position.y) >= player_range and abs(player.global_position.x - global_position.x) >= player_range * 2):
			$Animation.play(rise_animation)
	if $Animation.is_playing():
		await $Animation.animation_finished
	$RotationJoint/PositionJoint/Visuals/Hitbox.set_deferred("monitoring", false)
	$Timer.start()

func on_killed(gib_direction: int) -> void:
	var gib_spawner = get_node("GibSpawner")
	if Settings.file.visuals.extra_particles == 1:
		gib_spawner.gib_type = 2
	gib_spawner.summon_gib(gib_direction)
