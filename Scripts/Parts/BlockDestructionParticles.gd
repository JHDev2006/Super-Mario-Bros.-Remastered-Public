extends Node2D

@onready var particles := [$TL, $TR, $BL, $BR]

var particle_directions := [Vector2(-1, -3), Vector2(1, -3), Vector2(-1, -1), Vector2(1, -1)]
var particle_velocities := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]

var particle_rotations := [0.0, 0.0, 0.0, 0.0]

func _ready() -> void:
	for i in 4:
		particle_velocities[i] = 70 * particle_directions[i]

func _physics_process(delta: float) -> void:
	for i in 4:
		particles[i].global_position += particle_velocities[i] * delta
		particle_velocities[i] += Vector2(0, 15) * delta * 60.0
		particle_rotations[i] += (1080 * particle_directions[i].x) * delta
		particles[i].global_rotation_degrees = snapped(particle_rotations[i], 90)
