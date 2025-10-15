extends Node2D

var target_player: Player = null

var velocity := Vector2.ZERO

const MOVE_SPEED := 30
const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")
var direction := -1

signal killed

func _physics_process(delta: float) -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	if $TrackJoint.is_attached == false:
		handle_movement(delta)
	$Sprite.scale.x = direction

func handle_movement(delta: float) -> void:
	var target_direction = sign(target_player.global_position.x - global_position.x)
	if target_direction != 0:
		direction = target_direction
	if target_player.direction == direction:
		if $Sprite.animation != "Move":
			$Sprite.play("Move")
		velocity = lerp(velocity, 30 * global_position.direction_to(target_player.global_position), delta * 5)
	else:
		if $Sprite.animation != "Idle":
			$Sprite.play("Idle")
		velocity = lerp(velocity, Vector2.ZERO, delta * 5)
	global_position += velocity * delta


func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		if area.owner.is_invincible or area.name == "HammerHitbox": # todo: can we make killing boos better?
			die()
		else:
			area.owner.damage()

func die() -> void:
	summon_smoke_particle()
	queue_free()
	killed.emit()

func flag_die() -> void:
	die()

func summon_smoke_particle() -> void:
	var particle = SMOKE_PARTICLE.instantiate()
	particle.global_position = global_position
	add_sibling(particle)
