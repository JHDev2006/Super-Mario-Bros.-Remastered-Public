extends Node2D

@export var particle: PackedScene = null

var velocity := Vector2(0, -300)

var can_spawn_particles := true

func _ready() -> void:
	Global.coins += 1
	Global.score += 200
	AudioManager.play_sfx("coin", global_position)

func _physics_process(delta: float) -> void:
	if get_node_or_null("Sprite") != null:
		global_position += velocity * delta
		velocity.y += 15 * delta * 60.0

func vanish() -> void:
	if can_spawn_particles and Settings.file.visuals.extra_particles == 1:
		summon_particle()
		$Sprite.queue_free()
	else:
		queue_free()

func summon_particle() -> void:
	var node = particle.instantiate()
	node.finished.connect(queue_free)
	add_child(node)
