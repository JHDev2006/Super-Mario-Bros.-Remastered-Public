class_name CoinHeavenWarpPoint
extends Node2D

@export_file("*.tscn") var heaven_scene := ""

func _ready() -> void:
	Level.vine_warp_level = heaven_scene
	if Level.in_vine_level:
		Level.in_vine_level = false
		if PipeArea.exiting_pipe_id == -1:
			for i in get_tree().get_nodes_in_group("Players"):
				i.global_position = global_position
				i.reset_physics_interpolation()
				i.recenter_camera()
