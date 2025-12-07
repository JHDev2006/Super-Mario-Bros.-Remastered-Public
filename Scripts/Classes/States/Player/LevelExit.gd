extends PlayerState

var npc_count = [0, 0]
var pose_type = "PoseDoor"
var pose_offset = 0

func enter(_msg := {}) -> void:
	player.can_hurt = false
	player.has_jumped = false
	player.crouching = false
	player.in_cutscene = true
	player.get_node("CameraCenterJoint/RightWall").set_collision_layer_value(1, false)
	for i: Node2D in get_tree().get_nodes_in_group("CastleNPCs"):
		if i.global_position < player.global_position:
			return
		if i.play_end_music:
			npc_count[1] += 1
		else:
			npc_count[0] += 1
	player.speed_mult = player.physics_params(get_npc_count("_SPEED_MULT", "FLAG"), player.ENDING_PARAMETERS)
	player.accel_mult = player.physics_params(get_npc_count("_ACCEL_MULT", "FLAG"), player.ENDING_PARAMETERS)
	pose_offset = player.physics_params(get_npc_count("_POSE_OFFSET", "DOOR"), player.ENDING_PARAMETERS)
	if npc_count == [0, 0]:
		pose_type = "PoseDoor"
	elif npc_count[0] > npc_count[1]:
		pose_type = "PoseToad"
	else:
		pose_type = "PosePeach"
	
func physics_update(delta: float) -> void:
	handle_posing()
	if player.is_posing:
		player.velocity.x = 0
		return
	player.input_direction = 1
	player.can_run = false
	player.normal_state.handle_movement(delta)
	player.normal_state.handle_animations()

func get_npc_count(param: String, default: String):
	if npc_count == [0, 0]:
		return default + param
	elif npc_count[0] > npc_count[1]:
		return "TOAD" + param
	else:
		return "PEACH" + param

func handle_posing() -> void:
	# SkyanUltra: Moved PoseDoor behavior to LevelExit for easier access and easier sorting
	# of player behavior. Additionally added similar behavior for Toad and Peach NPCs in
	# castle levels.
	if not player.in_cutscene:
		return
	if npc_count == [0, 0]:
		for i: Node2D in get_tree().get_nodes_in_group("EndCastles"):
			var pose_position = i.global_position.x + pose_offset
			if (player.global_position[0] >= pose_position and player.global_position[0] <= pose_position + 24) and player.can_pose_anim and player.sprite.sprite_frames.has_animation("PoseDoor"):
				player.is_posing = true; player.can_pose_anim = false
				player.global_position = Vector2(pose_position, i.global_position.y)
				player.play_animation(pose_type)
				player.sprite.animation_finished.connect(on_pose_finished.bind())
				player.sprite.animation_looped.connect(on_pose_finished.bind())
	else:
		for i: Node2D in get_tree().get_nodes_in_group("CastleNPCs"):
			var pose_position = i.global_position.x + pose_offset
			if (player.global_position[0] >= pose_position and player.global_position[0] <= pose_position + 24):
				player.is_posing = true; player.can_pose_castle_anim = false
				player.global_position = Vector2(pose_position, i.global_position.y)
				player.velocity.x = 0
				if player.sprite.sprite_frames.has_animation(pose_type):
					player.play_animation(pose_type)
				else:
					player.normal_state.handle_animations()

func on_pose_finished() -> void:
	player.is_posing = false
	player.z_index = -2
