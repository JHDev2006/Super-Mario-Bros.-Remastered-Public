class_name PickAPathPoint
extends Node2D

var crossed := false

func on_player_entered(_player: Player) -> void:
	if not crossed: 
		AudioManager.play_global_sfx("correct")
	crossed = true
