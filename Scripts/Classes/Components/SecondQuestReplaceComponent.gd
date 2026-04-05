class_name SecondQuestReplacer
extends Node

@export_file("*.tscn") var new_scene := ""
@export var properties: Array[String] = []

func _ready() -> void:
	if (Global.second_quest or HardModeForce.enabled) and new_scene != "" and new_scene != owner.scene_file_path:
		if owner.owner != null:
			await owner.owner.ready
		var node = load(new_scene).instantiate()
		node.position = owner.position
		node.global_rotation = owner.global_rotation
		for i in properties:
			node.set(i, owner.get(i))
		owner.add_sibling(node)
		if owner is RopeElevatorPlatform:
			owner.linked_platform.linked_platform = node
		owner.queue_free()
	else:
		queue_free()
