extends StaticBody2D

@export var melted_scene: PackedScene = null
const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

var melting := false

func fireball_entered(ball: Node2D) -> void:
	ball.hit()
	call_deferred("melt")

func melt() -> void:
	if melting: return
	melting = true
	var melted_node = melted_scene.instantiate()
	melted_node.global_position = global_position
	add_sibling(melted_node)
	summon_smoke()
	queue_free()

func summon_smoke() -> void:
	var smoke = SMOKE_PARTICLE.instantiate()
	smoke.global_position = global_position + Vector2(0, 8)
	add_sibling(smoke)
