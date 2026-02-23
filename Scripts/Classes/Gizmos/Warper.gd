class_name Warper
extends Node2D

@export_enum("Room 0", "Room 1", "Room 2", "Room 3", "Room 4") var destination := 0
@export_range(0, 99) var channel := 0

static var target_channel := -1
static var warping := false
signal warped

static var saved_velocity := Vector2.ZERO

func _ready() -> void:
	run_check.call_deferred()

func run_check() -> void:
	if target_channel == channel:
		target_channel = -1
		for i: Player in get_tree().get_nodes_in_group("Players"):
			i.global_position = global_position + Vector2(0, 8)
			i.recenter_camera()
		await get_tree().create_timer(0.1, false).timeout
		for i: Player in get_tree().get_nodes_in_group("Players"):
			i.velocity = saved_velocity
			if saved_velocity.y < 0:
				i.has_jumped = true
				i.gravity = i.calculate_speed_param("JUMP_GRAVITY")
		warped.emit()
		saved_velocity = Vector2.ZERO

func _exit_tree() -> void:
	warping = false

func warp() -> void:
	if warping:
		return
	warping = true
	target_channel = channel
	var player = get_tree().get_first_node_in_group("Players")
	saved_velocity = player.velocity
	if Global.level_editor != null:
		Global.level_editor.transition_to_sublevel(destination)
	else:
		Global.transition_to_scene(NewLevelBuilder.sub_levels[destination])
