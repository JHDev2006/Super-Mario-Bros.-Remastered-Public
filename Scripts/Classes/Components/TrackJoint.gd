class_name TrackJoint
extends Node

signal attached

@export var offset := Vector2(0, 8)
@export var movement_node: Node = null
@export var disable_physics := true
@export var exclude_areas: Array[Area2D]

var rider: TrackRider = null
var is_attached := false

func detach() -> void:
	if rider == null: return
	owner.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT
	rider.attached_entity = null
	rider.queue_free()
	get_parent().reparent(rider.get_parent()) 
	owner.reset_physics_interpolation()
	
