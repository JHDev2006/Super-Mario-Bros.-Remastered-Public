class_name ExtraBGM
extends Node

@export var extra_track: JSON = null

func _enter_tree() -> void:
	Level.extra_music = extra_track
