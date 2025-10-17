class_name KeyItem
extends Node2D

static var total_collected := 0
const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")
func _ready() -> void:
	$AnimationPlayer.play("Float")

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		total_collected += 1
		AudioManager.play_sfx("key_collect", global_position)
		summon_smoke_particle()
		queue_free()

func summon_smoke_particle() -> void:
	var node = SMOKE_PARTICLE.instantiate()
	node.global_position = global_position
	add_sibling(node)
