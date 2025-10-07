class_name Door
extends Node2D

@export_range(0, 99) var door_id := 0

@export_enum("0", "1", "2", "3", "4") var sublevel_id := 0

@export var locked := false:
	set(value):
		locked = value
		pass
@export var start_locked := false

signal updated

static var exiting_door_id := -1

var can_enter := true

static var door_found := false

static var unlocked_doors := []

static var same_scene_exiting_door: Door = null

func _ready() -> void:
	if start_locked:
		locked = true
	await get_tree().physics_frame
	if locked:
		check_if_unlocked(false)

func _physics_process(_delta: float) -> void:
	for i in $PlayerDetection.get_overlapping_areas():
		if i.owner is Player and can_enter:
			if Global.player_action_just_pressed("move_up", i.owner.player_id) and i.owner.is_on_floor():
				if locked:
					if KeyItem.total_collected > 0:
						unlock_door(i.owner)
					else:
						AudioManager.play_sfx("door_locked", global_position)
						$Sprite.play("Locked")
						$AnimationPlayer.play("Locked")
				else:
					player_enter(i.owner)

func check_if_unlocked(do_animation := true) -> void:
	if locked:
		print(unlocked_doors)
		if unlocked_doors.has(door_id):
			locked = false
			$Sprite.play("Idle")
			if do_animation:
				$AnimationPlayer.play("Unlock")

func run_door_check() -> void:
	if same_scene_exiting_door != null:
		if same_scene_exiting_door != self and exiting_door_id == door_id:
			door_found = true
			get_tree().call_group("CameraLimits", "return_camera_to_normal")
			for i in get_tree().get_nodes_in_group("Players"):
				player_exit(i)
			return
	else:
		if exiting_door_id == door_id:
			door_found = true
			for i in get_tree().get_nodes_in_group("Players"):
				player_exit(i)
			return
	await get_tree().physics_frame
	if door_found == false:
		for i in get_tree().get_nodes_in_group("Players"):
			player_exit(i)

func unlock_door(player: Player) -> void:
	AudioManager.play_sfx("door_unlock", global_position)
	Global.p_switch_timer_paused = true
	KeyItem.total_collected -= 1
	freeze_player(player)
	$Sprite.play("Idle")
	unlocked_doors.append(door_id)
	get_tree().call_group("Doors", "check_if_unlocked", true)
	$AnimationPlayer.play("Unlock")
	await get_tree().create_timer(0.5, false).timeout
	player_enter(player)

func player_exit(player: Player) -> void:
	exiting_door_id = -1
	can_enter = false
	LevelEditor.play_door_transition = false
	if same_scene_exiting_door != null: same_scene_exiting_door.get_node("Sprite").play("Idle")
	same_scene_exiting_door = null
	player.global_position = global_position
	player.recenter_camera()
	$Sprite.play("Close")
	await get_tree().create_timer(0.2, false).timeout
	$Sprite.play("Close")
	player.state_machine.transition_to("Normal")
	AudioManager.play_sfx("door_close", global_position)
	can_enter = true
	Global.p_switch_timer_paused = false

func player_enter(player: Player) -> void:
	Global.p_switch_timer_paused = true
	can_enter = false
	door_found = false
	exiting_door_id = door_id
	freeze_player(player)
	$Sprite.play("Open")
	LevelEditor.play_door_transition = true
	AudioManager.play_sfx("door_open", global_position)
	await get_tree().create_timer(0.5, false).timeout
	if Global.level_editor.sub_level_id == sublevel_id:
		Global.do_fake_transition()
		if Global.fade_transition:
			await get_tree().create_timer(0.25, false).timeout
		same_scene_exiting_door = self
		for i in get_tree().get_nodes_in_group("Doors"):
			i.run_door_check()
	else:
		same_scene_exiting_door = null
		Global.level_editor.transition_to_sublevel(sublevel_id)
	can_enter = true

func freeze_player(player: Player) -> void:
	player.state_machine.transition_to("Freeze")
	player.sprite.play("Idle")
	player.velocity = Vector2.ZERO
