extends Node2D
const COIN_SPARKLE = preload("res://Scenes/Prefabs/Particles/CoinSparkle.tscn")
var velocity := Vector2(0, -300)

func _ready() -> void:
	Global.coins += 1
	Global.score += 200
	AudioManager.play_sfx("coin", global_position)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	velocity.y += (15) * delta * 60.0

func vanish() -> void:
	queue_free()

func summon_particle() -> void:
	var node = COIN_SPARKLE.instantiate()
	node.global_position = global_position
	add_sibling(node)
