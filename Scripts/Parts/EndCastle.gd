extends Node2D

var time_save := 0

signal finished_sequence
const FIREWORK = preload("res://Scenes/Prefabs/Particles/Firework.tscn")

var tally_finished := false
var music_finished := false
var tree = null
var show_walls := false
var doing_sequence := false

var can_transition := false

static var is_transitioning := false

func _ready() -> void:
	await Global.level_complete_begin
	$Overlay.show()
	$OverlaySprite.show()
	$Overlay/PlayerDetection.set_collision_layer_value(1, true)
	Global.score_tally_finished.connect(on_tally_finished)
	if Global.current_game_mode == Global.GameMode.BOO_RACE:
		get_tree().create_timer(3.5, false).timeout.connect(on_music_finished)
	else:
		get_tree().create_timer(5.5, false).timeout.connect(on_music_finished)
	time_save = Global.time

func update_cam_limit() -> void:
	$CameraRightLimit._enter_tree()

func _process(_delta: float) -> void:
	$Overlay.modulate.a = int($SmallCastleVisual.use_sprite == false)
	if Global.level_editor != null && scene_file_path == "res://Scenes/Prefabs/LevelObjects/EndFinalCastle.tscn":
		var is_smbs: bool = Global.current_campaign == "SMBS"
		$SmallCastleVisual.visible = !is_smbs
		$SmallCastleVisual2.visible = is_smbs
	if get_node_or_null("Wall") != null:
		%Wall.visible = show_walls

func _physics_process(_delta: float) -> void:
	for i: Player in get_tree().get_nodes_in_group("Players"):
		if i.can_pose and i.global_position >= global_position and i.sprite.sprite_frames.has_animation("PoseDoor"):
			i.is_posing = true; i.can_pose = false
			i.global_position = global_position
			i.play_animation("PoseDoor")
			i.sprite.animation_finished.connect(on_pose_finished.bind(i))
			i.sprite.animation_looped.connect(on_pose_finished.bind(i))

func on_pose_finished(player: Player) -> void:
	player.is_posing = false
	player.z_index = -2

func on_music_finished() -> void:
	do_sequence()

func on_tally_finished() -> void:
	$FlagJoint/Flag/AnimationPlayer.play("Raise")

func do_sequence() -> void:
	if Global.current_game_mode != Global.GameMode.BOO_RACE:
		await get_tree().create_timer(1, false).timeout
		if Global.current_campaign == "SMBLL":
			await do_lost_levels_firework_check()
		else:
			await do_firework_check()
	await get_tree().create_timer(1, false).timeout
	if is_transitioning == false:
		is_transitioning = true
		exit_level()

func do_firework_check() -> void:
	var digit = time_save % 10
	if [1, 3, 6].has(digit):
		await show_fireworks(digit)
	return

func do_lost_levels_firework_check() -> void:
	var coin_digit = Global.coins % 10
	var time_digit = time_save % 10
	if coin_digit == time_digit:
		if coin_digit % 2 == 0:
			await show_fireworks(6)
			if coin_digit % 11 == 0:
				spawn_one_up_note()
				AudioManager.play_sfx("1_up", global_position)
				Global.lives += 1
		else:
			await show_fireworks(3)

const ONE_UP_NOTE = preload("uid://dopxwjj37gu0l")

func spawn_one_up_note() -> void:
	var note = ONE_UP_NOTE.instantiate()
	note.global_position = global_position + Vector2(0, -16)
	owner.add_sibling(note)

func _exit_tree() -> void:
	is_transitioning = false

func show_fireworks(amount := 0) -> void:
	for i in amount:
		spawn_firework()
		await get_tree().create_timer(0.5, false).timeout

func spawn_firework() -> void:
	var node = FIREWORK.instantiate()
	Global.score += 500
	node.position.x = randf_range(-48, 48)
	node.position.y = randf_range(-112, -150)
	add_child(node)
	AudioManager.play_sfx("firework", node.global_position)


func exit_level() -> void:
	await Global.frame_rule
	match Global.current_game_mode:
		Global.GameMode.MARATHON_PRACTICE:
			Global.reset_values()
			Global.open_marathon_results()
		Global.GameMode.CUSTOM_LEVEL:
			Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")
		Global.GameMode.LEVEL_EDITOR:
			Global.level_editor.stop_testing()
		_:
			if Global.current_campaign == "SMBANN":
				Global.open_disco_results()
			else:
				Global.current_level.transition_to_next_level()
