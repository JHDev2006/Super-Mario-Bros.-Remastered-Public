extends Node2D


var can_move := true
var aiming := false

const MAX_DISTANCE := 32

@onready var enemy: Enemy = $Enemy

const MOVE_SPEED := 50

var target_player: Player = null

const LUNGE_AMOUNT := 64

var floor := 0.0

func _ready() -> void:
	$Enemy.add_collision_exception_with($Post)
	$Enemy/Timer.start()
	Global.level_theme_changed.connect(queue_redraw)

func _physics_process(delta: float) -> void:
	if can_move:
		handle_movement(delta)
	elif aiming:
		enemy.velocity.x = 0
		enemy.direction = sign(target_player.global_position.x - enemy.global_position.x)
		enemy.apply_enemy_gravity(delta)
		enemy.move_and_slide()
	%Sprite.scale.x = enemy.direction

func handle_movement(delta: float) -> void:
	if enemy.is_on_floor():
		enemy.velocity.y = -100
		if enemy.global_position.distance_to(global_position) >= MAX_DISTANCE:
			enemy.direction = sign(global_position.x - enemy.global_position.x)
	if enemy.is_on_floor() or enemy.position.y > floor:
		floor = enemy.position.y
		$Rope.floor = floor
	if enemy.is_on_wall():
		enemy.direction *= -1
	enemy.velocity.x = MOVE_SPEED * enemy.direction
	enemy.apply_enemy_gravity(delta)
	enemy.move_and_slide()

func lunge() -> void:
	can_move = false
	target_player = get_tree().get_first_node_in_group("Players")
	aiming = true
	await get_tree().create_timer(1, false).timeout
	aiming = false
	var target_pos = (target_player.global_position - global_position - Vector2(0, 16)).normalized() * LUNGE_AMOUNT
	$Rope.has_floor = false
	var tween = create_tween().tween_property($Enemy, "position", target_pos, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(1.5, false).timeout
	if is_instance_valid(enemy) == false:
		return
	enemy.move_and_slide()
	tween = create_tween().tween_property($Enemy, "position", Vector2(0, -8), 0.35).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(0.25, false).timeout
	can_move = true
	$Rope.has_floor = true
	enemy.velocity.y = -100
	$Enemy/Timer.start()

func enemy_killed(_dir := 0) -> void:
	set_physics_process(false)
	$Rope.queue_free()
