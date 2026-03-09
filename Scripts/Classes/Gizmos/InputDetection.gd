extends Node2D

@export_enum("Jump", "Run", "Action", "Left", "Right", "Up", "Down") var action := 0

var is_pressed := false

signal held
signal release

const MAP := [
	"jump",
	"run",
	"action",
	"move_left",
	"move_right",
	"move_up",
	"move_down"
]

func _physics_process(_delta: float) -> void:
	if is_pressed == false and Global.player_action_pressed(MAP[action], 0):
		held.emit()
	elif is_pressed and Global.player_action_pressed(MAP[action], 0) == false:
		release.emit()
	is_pressed = Global.player_action_pressed(MAP[action], 0)
		
