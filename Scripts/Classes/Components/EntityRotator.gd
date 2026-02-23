class_name EntityRotator
extends Node

@export var rotation_joint: Node2D = owner
@export var direction_value_name := "direction"
@export var directions := {
	0: 0,
	1: 90,
	2: 180,
	3: 270
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(_delta: float) -> void:
	owner.global_rotation_degrees = directions[owner.get(direction_value_name)]
