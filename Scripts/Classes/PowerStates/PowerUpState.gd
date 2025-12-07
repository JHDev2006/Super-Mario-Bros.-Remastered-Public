class_name PowerUpState
extends Node

@export var state_name := ""
@export var power_tier := 0
@export_enum("Small", "Big", "Fire") var hitbox_size := "Small"
@export var damage_state: PowerUpState = null

@onready var player: Player = owner

func update(_delta: float) -> void:
	pass
