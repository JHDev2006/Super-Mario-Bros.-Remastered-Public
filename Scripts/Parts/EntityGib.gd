extends Node2D

@export_enum("Spin", "Drop", "Poof") var gib_type := 0

var visuals: Node = null

var velocity := Vector2(0, 0)

var direction := 1

var entity_rotation := 0.0

func _ready() -> void:
	if visuals == null:
		queue_free()
		return
	visuals.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(visuals)
	visuals.process_mode = Node.PROCESS_MODE_DISABLED
	visuals.position = Vector2.ZERO
	match gib_type:
		0:
			velocity = Vector2(100 * direction, -200) 

func _physics_process(delta: float) -> void:
	match gib_type:
		0:
			spin_move(delta)
		1:
			velocity.y += (15) * delta * 60.0
			velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
			scale.y = -1
			
	global_position += velocity * delta

func spin_move(delta: float) -> void:
	velocity.y += (15) * delta * 60.0
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
	entity_rotation = (180 * direction)
	visuals.global_rotation_degrees = snapped(entity_rotation, 45)
	velocity.x = lerpf(velocity.x, 0, delta / 2)
	
