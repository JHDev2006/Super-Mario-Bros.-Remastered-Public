class_name PlantFireball
extends CharacterBody2D

var direction := Vector2.ZERO
var can_rotate := true

const MOVE_SPEED := 75.0
const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

@export var can_pass_walls := false

func _ready() -> void:
	if can_rotate:
		$Sprite/AnimationPlayer.play("Spin")

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = signf(direction.x)
	$Sprite/AnimationPlayer.speed_scale = signf(direction.x)
	global_position += MOVE_SPEED * direction * delta
	move_and_slide()
	if is_on_wall() and not can_pass_walls:
		hit()

func hit() -> void:
	queue_free()
	summon_smoke()

func damage_player(player: Player) -> void:
	player.damage()
	hit()

func summon_smoke() -> void:
	var node = SMOKE_PARTICLE.instantiate()
	node.global_position = global_position + Vector2(0, 8)
	add_sibling(node)
