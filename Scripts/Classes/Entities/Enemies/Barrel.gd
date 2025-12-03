extends Enemy

var MOVE_SPEED := 32
var MAX_MOVE_SPEED := 108

const BARREL_DESTRUCTION_PARTICLE = preload("res://Scenes/Prefabs/Particles/BarrelDestructionParticle.tscn")
func _physics_process(delta: float) -> void:
	handle_movement(delta)

func handle_movement(delta: float) -> void:
	if is_on_wall() and is_on_floor() and get_wall_normal().x == -direction:
		die()
	if is_on_floor() and get_floor_angle() != 0:
		var floor_normal = get_floor_normal()
		floor_normal = sign(floor_normal[0]) if abs(floor_normal[0]) < 0.5 else 1.5 * sign(floor_normal[0])
		if MOVE_SPEED <= 0:
			direction = sign(floor_normal)
		MOVE_SPEED = clamp(MOVE_SPEED + (2 * (direction * floor_normal)) * delta * 60.0, 0, MAX_MOVE_SPEED)
		$BasicEnemyMovement.move_speed = MOVE_SPEED
	
func die() -> void:
	destroy()

func die_from_object(_node: Node2D) -> void:
	destroy()
	
func die_from_hammer(_node: Node2D) -> void:
	AudioManager.play_sfx("hammer_hit", global_position)
	destroy()

func summon_particle() -> void:
	var node = BARREL_DESTRUCTION_PARTICLE.instantiate()
	node.global_position = global_position - Vector2(0, 8)
	add_sibling(node)

func destroy() -> void:
	summon_particle()
	AudioManager.play_sfx("block_break", global_position)
	queue_free()

func bounce_up() -> void:
	velocity.y = -200
