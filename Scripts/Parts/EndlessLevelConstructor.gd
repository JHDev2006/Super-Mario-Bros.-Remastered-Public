extends Node

var style := "Overworld"

var level_seed := "8923589235890"

var level_length := 10

const PIECE_FOLDER := "res://Scenes/LevelPieces/"

const OVERWORLD_STYLES := ["Overworld", "Desert", "Snow", "Jungle", "Garden", "Beach", "Mountain", "Autumn"]

@onready var pieces: Node2D = $"../Pieces"

func _enter_tree() -> void:
	owner.theme = OVERWORLD_STYLES.pick_random()
	Global.level_theme = owner.theme
