class_name MoonGravity
extends Node

@export var new_gravity := 5
const OLD_GRAVITY := 10

func _ready() -> void:
	Global.entity_gravity = new_gravity
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.low_gravity = true

func _exit_tree() -> void:
	Global.entity_gravity = OLD_GRAVITY
