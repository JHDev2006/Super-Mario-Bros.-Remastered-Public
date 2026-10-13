extends StaticBody2D

@export var melted_scene: PackedScene = null
const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

var melting := false

var melted_node: Node2D = null

func _ready() -> void:
	melted_node = melted_scene.instantiate()
	melted_node.global_position = Vector2(-512, 512)
	add_sibling.call_deferred(melted_node)

func fireball_entered(ball: Node2D) -> void:
	ball.hit()
	call_deferred("melt")

func melt() -> void:
	if melting: return
	melting = true
	melted_node.global_position = global_position
	if melted_node.has_node("VisibleOnScreenEnabler2D"):
		## For some reason, we have to delete any of these that exist, 
		## otherwise block collision gets completely fucked up, idk why, 
		## probably a godot bug :thumbsup:
		melted_node.get_node("VisibleOnScreenEnabler2D").queue_free()
	summon_smoke()
	queue_free()

func summon_smoke() -> void:
	var smoke = SMOKE_PARTICLE.instantiate()
	smoke.global_position = global_position + Vector2(0, 8)
	add_sibling(smoke)
