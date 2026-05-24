class_name ExtraBGM
extends Node

@export var extra_track: JSON = null

func _ready() -> void:
	Level.extra_music = extra_track

func _exit_tree() -> void:
	Level.extra_music = null
