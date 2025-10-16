extends Node2D

signal victory_begin
const CASTLE_COMPLETE = preload("res://Assets/Audio/BGM/CastleComplete.mp3")

var cam_move := false

@export_range(8, 20, 1) var length := 13
@export var end_timer := false
@export var do_tally := true

signal axe_touched

var bowser_present := true

func _ready() -> void:
	await get_tree().physics_frame
	$Axe/CameraRightLimit._enter_tree()

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		destroy_bridge(area.owner)

func destroy_bridge(player: Player) -> void:
	Global.can_pause = false
	for i in get_tree().get_nodes_in_group("Enemies"):
		if i is BowserFlame:
			i.queue_free()
		elif i is Hammer:
			i.queue_free()
	if (end_timer and Global.current_game_mode == Global.GameMode.MARATHON) or Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		SpeedrunHandler.run_finished()
	
	if end_timer:
		if Global.world_num > 8:
			Global.unlock_achievement(Global.AchievementID.SMBLL_WORLD9)
		match Global.current_campaign:
			"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_CLEAR)
			"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_CLEAR)
			"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_CLEAR)
			"SMBANN": Global.unlock_achievement(Global.AchievementID.SMBANN_CLEAR)
	
	bowser_present = get_tree().get_first_node_in_group("Bowser") != null
	player.velocity = Vector2.ZERO
	Global.can_time_tick = false
	axe_touched.emit()
	$Axe.queue_free()
	if bowser_present:
		for i in get_tree().get_nodes_in_group("Bowser"):
			i.bridge_fall()
		get_tree().paused = true
		await get_tree().create_timer(0.5).timeout
		for i in $Bridge.get_children():
			if i.visible:
				AudioManager.play_sfx("block_break", i.global_position)
			if Settings.file.visuals.bridge_animation == 0:
				bridge_piece_break(i)
			else:
				bridge_piece_fall(i)
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(1.5).timeout
		get_tree().paused = false
	victory_sequence(player)

func bridge_piece_fall(node: Node2D) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "global_position:y", node.global_position.y + 128, 0.5)

const BRIDGE_DESTRUCTION_PARTICLE = preload("uid://cwfjdgsyh35h6")

func bridge_piece_break(node: Node2D) -> void:
	if Settings.file.visuals.extra_particles == 1:
		var particle = BRIDGE_DESTRUCTION_PARTICLE.instantiate()
		particle.global_position = node.global_position
		particle.process_mode = Node.PROCESS_MODE_ALWAYS
		add_sibling(particle)
	node.modulate.a = 0

func _physics_process(delta: float) -> void:
	if cam_move and $Camera.global_position.x < Player.camera_right_limit:
		$Camera.global_position.x += 96 * delta
	$Camera.global_position.x = clamp($Camera.global_position.x, -INF, Player.camera_right_limit)

func victory_sequence(player: Player) -> void:
	get_tree().call_group("Enemies", "flag_die")
	Global.level_complete_begin.emit()
	victory_begin.emit()
	cam_move = true
	$Camera.limit_right = Player.camera_right_limit
	$Camera.global_position = get_viewport().get_camera_2d().get_screen_center_position()
	$Camera.reset_physics_interpolation()

	player.state_machine.transition_to("LevelExit")
	$Camera.make_current()
	if Global.current_game_mode == Global.GameMode.BOO_RACE:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.RACE_WIN, 99, false)
		await AudioManager.music_override_player.finished
		Global.current_level.transition_to_next_level()
	else:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.CASTLE_COMPLETE, 99, false)
	await get_tree().create_timer(1, false).timeout
	if do_tally:
		Global.tally_time()


func on_victory_begin() -> void:
	pass # Replace with function body.
