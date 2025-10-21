class_name CameraRightLimit
extends Node2D

@export var reset_on_delete := true
@export var lock_camera := false

func _enter_tree() -> void:
	add_to_group("CameraLimits")
	Player.camera_right_limit = int(global_position.x)

func _exit_tree() -> void:
	if reset_on_delete:
		Player.camera_right_limit = int(99999999)

func return_camera_to_normal() -> void:
	for i in get_tree().get_nodes_in_group("Players"):
		Player.camera_right_limit = int(9999999)
		CameraHandler.cam_locked = false
		i.reset_camera_to_center()


func on_screen_entered() -> void:
	if lock_camera:
		CameraHandler.cam_locked = true
