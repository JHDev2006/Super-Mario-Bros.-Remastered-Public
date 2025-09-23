class_name BasicEnemyMovement
extends Node

@export var ledge_detection_cast: RayCast2D = null

var can_move := true

@export var auto_call := true

@export var move_speed := 32
@export var second_quest_speed := 36

@onready var current_speed := move_speed
@export var bounce_on_land := false
@export var bounce_height := -200
@export var visuals: Node2D

@export var follow_player := false

var can_hit := true

var can_bounce := true

var active := true

func _ready() -> void:
	if owner is CharacterBody2D:
		owner.floor_constant_speed = true
		owner.floor_max_angle = 0.80

func _physics_process(delta: float) -> void:
	if auto_call:
		handle_movement(delta)
	if visuals != null:
		visuals.scale.x = owner.direction

func handle_movement(delta: float) -> void:
	if active == false: return
	if Global.second_quest and owner is Enemy:
		move_speed = second_quest_speed
	apply_gravity(delta)
	if owner.is_on_wall():
		wall_hit()
	elif ledge_detection_cast != null and owner.is_on_floor():
		ledge_detection_cast.floor_normal = owner.get_floor_normal()
		ledge_detection_cast.position.x = abs(ledge_detection_cast.position.x) * owner.direction
		if ledge_detection_cast.is_colliding() == false:
			wall_hit()
	if follow_player and owner.is_on_floor():
		player_direction_check()
	current_speed = abs(owner.velocity.x)
	if current_speed < move_speed:
		current_speed = move_speed
	if owner.is_on_floor():
		current_speed = move_speed
		if bounce_on_land:
			owner.velocity.y = bounce_height
	owner.velocity.x = (current_speed if can_move else 0) * owner.direction
	owner.move_and_slide()

func apply_gravity(delta: float) -> void:
	owner.velocity.y += (Global.entity_gravity ) * delta * 60.0
	owner.velocity.y = clamp(owner.velocity.y, -INF, Global.entity_max_fall_speed)

func player_direction_check() -> void:
	var target_player = get_tree().get_first_node_in_group("Players")
	owner.direction = sign(target_player.global_position.x - owner.global_position.x)

func wall_hit() -> void:
	if can_hit == false:
		return
	can_hit = false
	owner.direction *= -1
	await get_tree().create_timer(0.1, false).timeout
	can_hit = true
