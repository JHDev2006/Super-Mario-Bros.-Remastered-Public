extends Node

func _ready() -> void:
	get_tree().paused = false

func _process(_delta: float) -> void:
	if Global.multibind_action_just_pressed("jump_0"):
		go_back_to_title()

func go_back_to_title() -> void:
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func reset_values() -> void:
	pass
