class_name EntityGenerator
extends Node2D

var spawn_meter := 0.0
@export var threshold := 2.0
var active := false
@export_enum("Target Player", "Random Height") var y_pos := 0
@export_enum("Right", "Bottom") var direction := 0
@export var entity_scene: PackedScene = null

signal activated

func _physics_process(delta: float) -> void:
	if active:
		spawn_meter += delta
		if spawn_meter >= threshold:
			spawn_entity()
			spawn_meter = randf_range(-2, 0)

func activate() -> void:
	if not active:
		active = true
		spawn_meter = 0
		spawn_entity()
		activated.emit()

func deactivate_all_generators() -> void:
	for i in get_tree().get_nodes_in_group("EntityGenerators"):
		i.active = false
		i.deactivate()

func deactivate() -> void:
	pass

func spawn_entity() -> void:
	if entity_scene == null: return
	var node = entity_scene.instantiate()
	if direction == 1:
		node.global_position.x = get_viewport().get_camera_2d().get_screen_center_position().x + [ -32 ,-64, -96, -128].pick_random()
		node.global_position.y = 48
	else:
		if y_pos == 0:
			node.global_position.y = get_tree().get_first_node_in_group("Players").global_position.y + randi_range(-4, 4)
		else:
			node.global_position.y = randf_range(0, -152)
		node.global_position.x = get_viewport().get_camera_2d().get_screen_center_position().x + ((get_viewport().get_visible_rect().size.x / 2) + 8)
	if get_parent() is EntityGenerator:
		get_parent().add_sibling(node)
	else:
		add_sibling(node)
