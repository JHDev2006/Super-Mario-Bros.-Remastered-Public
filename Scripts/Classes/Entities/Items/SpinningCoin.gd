extends Node2D
const COIN_SPARKLE = preload("res://Scenes/Prefabs/Particles/CoinSparkle.tscn")
var velocity := Vector2(0, -300)

var can_spawn_particles := true

func _ready() -> void:
	Global.coins += 1
	Global.score += 200
	AudioManager.play_sfx("coin", global_position)

func _physics_process(delta: float) -> void:
	if get_node_or_null("Sprite") != null:
		global_position += velocity * delta
		velocity.y += (15 / delta) * delta

func vanish() -> void:
	if can_spawn_particles:
		summon_particle()
		$Sprite.queue_free()
	else:
		queue_free()

func summon_particle() -> void:
	var node = COIN_SPARKLE.instantiate()
	node.finished.connect(queue_free)
	add_child(node)
