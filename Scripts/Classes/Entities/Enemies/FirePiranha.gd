extends Node

var direction := Vector2(-1, 1)

var target_player: Player = null

var shooting := false
var aiming := false
@export var shoot_amount := 1
@export var fireball_scene: PackedScene = null
@export var plant: Node2D = null

func _physics_process(_delta: float) -> void:
	if not shooting:
		handle_aiming()

func handle_aiming() -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	if target_player == null: return
	var sprite = %Sprite
	direction = get_direction_vector()
	sprite.scale.x = direction.x
	if shooting:
		sprite.play("ShootUp" if direction.y == -1 else "ShootDown")
	elif aiming:
		sprite.play("AimUp" if direction.y == -1 else "AimDown")
	else:
		sprite.play("IdleUp" if direction.y == -1 else "IdleDown")

func get_direction_vector() -> Vector2:
	var dir = Vector2.ZERO
	var sign_x = sign(target_player.global_position.x - plant.global_position.x)
	var sign_y = sign(target_player.global_position.y + 4 - plant.global_position.y)
	match plant.pipe_direction:
		0:
			dir.x = sign_x
			dir.y = sign_y
		1:
			dir.x = -sign_x
			dir.y = -sign_y
		2:
			dir.x = sign_y
			dir.y = -sign_x
		3:
			dir.x = -sign_y
			dir.y = sign_x
	return dir

func shoot() -> void:
	aiming = true
	if shoot_amount <= 1:
		await get_tree().create_timer(0.75, false).timeout
	else:
		await get_tree().create_timer(0.25, false).timeout
	shooting = true
	for i in shoot_amount:
		handle_aiming()
		spawn_fireball()
		if shoot_amount > 1:
			await get_tree().create_timer(0.25, false).timeout
		else:
			await get_tree().create_timer(0.75, false).timeout
	shooting = false
	aiming = false
	plant.get_node("Timer").start()

func spawn_fireball() -> void:
	var node = fireball_scene.instantiate()
	node.global_position = %Sprite.global_position
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_sfx("plant_fireball", node.global_position)
	var shoot_angle = node.global_position.direction_to(target_player.global_position).angle()
	match get_direction_vector().rotated(plant.get_node("%RotationJoint").global_rotation):
		Vector2(1, -1):
			shoot_angle = clamp(snapped(shoot_angle, deg_to_rad(22.5)), deg_to_rad(-45), deg_to_rad(-22.5))
		Vector2(1, 1):
			shoot_angle = clamp(snapped(shoot_angle, deg_to_rad(22.5)), deg_to_rad(22.5), deg_to_rad(45))
		Vector2(-1, 1):
			shoot_angle = clamp(snapped(shoot_angle, deg_to_rad(22.5)), deg_to_rad(135), deg_to_rad(157.5))
		Vector2(-1, -1):
			shoot_angle = clamp(snapped(shoot_angle, deg_to_rad(22.5)), deg_to_rad(-157.5), deg_to_rad(-135))
	node.MOVE_ANGLE = Vector2.from_angle(shoot_angle)
	Global.current_level.add_child(node)
