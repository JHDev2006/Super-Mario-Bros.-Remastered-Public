extends Node

@export_file_path("*.tscn") var destination_scene := ""

func _ready() -> void:
	Level.vine_return_level = destination_scene
