class_name Player
extends CharacterBody2D

#region Physics properies, these can be changed within a custom character's CharacterInfo.json
var JUMP_GRAVITY := 11.0               # The player's gravity while jumping, measured in px/frame
var JUMP_HEIGHT := 300.0               # The strength of the player's jump, measured in px/sec
var JUMP_INCR := 8.0                   # How much the player's X velocity affects their jump speed
var JUMP_CANCEL_DIVIDE := 1.5          # When the player cancels their jump, their Y velocity gets divided by this value
var JUMP_HOLD_SPEED_THRESHOLD := 0.0   # When the player's Y velocity goes past this value while jumping, their gravity switches to FALL_GRAVITY

var BOUNCE_HEIGHT := 200.0             # The strength at which the player bounces off enemies, measured in px/sec 
var BOUNCE_JUMP_HEIGHT := 300.0        # The strength at which the player bounces off enemies while holding jump, measured in px/sec 

var FALL_GRAVITY := 25.0               # The player's gravity while falling, measured in px/frame
var MAX_FALL_SPEED := 280.0            # The player's maximum fall speed, measured in px/sec
var CEILING_BUMP_SPEED := 45.0         # The speed at which the player falls after hitting a ceiling, measured in px/sec

var WALK_SPEED := 96.0                 # The player's speed while walking, measured in px/sec
var GROUND_WALK_ACCEL := 4.0           # The player's acceleration while walking, measured in px/frame
var WALK_SKID := 8.0                   # The player's turning deceleration while running, measured in px/frame

var RUN_SPEED := 160.0                 # The player's speed while running, measured in px/sec
var GROUND_RUN_ACCEL := 1.25           # The player's acceleration while running, measured in px/frame
var RUN_SKID := 8.0                    # The player's turning deceleration while running, measured in px/frame

var SKID_THRESHOLD := 100.0            # The horizontal speed required, to be able to start skidding.

var DECEL := 3.0                       # The player's deceleration while no buttons are pressed, measured in px/frame
var AIR_ACCEL := 3.0                   # The player's acceleration while in midair, measured in px/frame
var AIR_SKID := 1.5                    # The player's turning deceleration while in midair, measured in px/frame

var SWIM_SPEED := 95.0                 # The player's horizontal speed while swimming, measured in px/sec
var SWIM_GROUND_SPEED := 45.0          # The player's horizontal speed while grounded underwater, measured in px/sec
var SWIM_HEIGHT := 100.0               # The strength of the player's swim, measured in px/sec
var SWIM_GRAVITY := 2.5                # The player's gravity while swimming, measured in px/frame
var MAX_SWIM_FALL_SPEED := 200.0       # The player's maximum fall speed while swimming, measured in px/sec

var DEATH_JUMP_HEIGHT := 300.0         # The strength of the player's "jump" during the death animation, measured in px/sec
#endregion

@onready var camera_center_joint: Node2D = $CameraCenterJoint

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var camera: Camera2D = $Camera
@onready var score_note_spawner: ScoreNoteSpawner = $ScoreNoteSpawner

var has_jumped := false

var direction := 1
var input_direction := 0

var flight_meter := 0.0

var velocity_direction := 1

var total_keys := 0

@export var power_state: PowerUpState = null:
	set(value):
		power_state = value
		set_power_state_frame()
var character := "Mario"

var crouching := false:
	get(): # You can't crouch if the animation somehow doesn't exist.
		if not sprite.sprite_frames.has_animation("Crouch"): return false
		return crouching
var skidding := false

var bumping := false
var can_bump_sfx := true
var can_bump_jump = false
var can_bump_crouch = false
var can_bump_swim = false
var can_bump_fly = false

@export var player_id := 0
const ONE_UP_NOTE = preload("uid://dopxwjj37gu0l")
var gravity := FALL_GRAVITY

var attacking := false
var pipe_enter_direction := Vector2.ZERO#
var pipe_move_direction := 1
var stomp_combo := 0

var is_invincible := false
var can_pose := false
var is_posing := false

const COMBO_VALS := [100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000, null]

@export_enum("Small", "Big", "Fire") var starting_power_state := 0
@onready var state_machine: StateMachine = $States
@onready var normal_state: Node = $States/Normal
@export var auto_death_pit := true

var can_hurt := true

var in_water := false

var has_hammer := false

var spring_bouncing := false

var low_gravity := false

var gravity_vector := Vector2.DOWN

var jump_cancelled := false

var camera_pan_amount := 24

var animating_camera := false

var can_uncrouch := false

var can_air_turn := false

static var CHARACTERS := ["Mario", "Luigi", "Toad", "Toadette"]
const POWER_STATES := ["Small", "Big", "Fire"]

signal moved
signal dead

var is_dead := false

static var CHARACTER_NAMES := ["CHAR_MARIO", "CHAR_LUIGI", "CHAR_TOAD", "CHAR_TOADETTE"]

static var CHARACTER_COLOURS := [preload("res://Assets/Sprites/Players/Mario/CharacterColour.json"), preload("res://Assets/Sprites/Players/Luigi/CharacterColour.json"), preload("res://Assets/Sprites/Players/Toad/CharacterColour.json"), preload("res://Assets/Sprites/Players/Toadette/CharacterColour.json")]

var can_timer_warn := true

var colour_palette_texture: Texture = null

static var CHARACTER_PALETTES := [
	preload("res://Assets/Sprites/Players/Mario/ColourPalette.json"),
	preload("res://Assets/Sprites/Players/Luigi/ColourPalette.json"),
	preload("res://Assets/Sprites/Players/Toad/ColourPalette.json"),
	preload("res://Assets/Sprites/Players/Toadette/ColourPalette.json")
]

const ANIMATION_FALLBACKS := {
	"JumpFall": "Jump", 
	"JumpBump": "Bump",
	"Fall": "Move", 
	"Pipe": "Idle", 
	"Walk": "Move", 
	"Run": "Move", 
	"PipeWalk": "Walk", 
	"LookUp": "Idle", 
	"Crouch": "Idle",
	"CrouchFall": "Crouch", 
	"CrouchJump": "Crouch", 
	"CrouchBump": "Bump",
	"CrouchMove": "Crouch", 
	"IdleAttack": "MoveAttack", 
	"CrouchAttack": "IdleAttack", 
	"MoveAttack": "Attack", 
	"WalkAttack": "MoveAttack", 
	"RunAttack": "MoveAttack", 
	"SkidAttack": "MoveAttack",
	"FlyIdle": "SwimIdle",
	"FlyUp": "SwimUp",
	"FlyMove": "SwimMove",
	"FlyAttack": "SwimAttack",
	"FlyBump": "SwimBump",
	"FlagSlide": "Climb",
	"WaterMove": "Move",
	"WaterIdle": "Idle",
	"SwimBump": "Bump",
	"DieFreeze": "Die",
	"StarJump": "Jump",
	"StarFall": "JumpFall"
}

var palette_transform := true
var transforming := false

static var camera_right_limit := 999999

static var times_hit := 0

var can_run := true

var air_frames := 0

static var classic_physics := false

var swim_stroke := false

var skid_frames := 0

var simulated_velocity := Vector2.ZERO

func _ready() -> void:
	if classic_physics:
		apply_classic_physics()
	get_viewport().size_changed.connect(recenter_camera)
	show()
	$Checkpoint/Label.text = str(player_id + 1)
	$Checkpoint/Label.modulate = [Color("5050FF"), Color("F73910"), Color("1A912E"), Color("FFB762")][player_id]
	$Checkpoint/Label.visible = Global.connected_players > 1
	Global.can_pause = true
	character = CHARACTERS[int(Global.player_characters[player_id])]
	Global.can_time_tick = true
	if [Global.GameMode.BOO_RACE, Global.GameMode.MARATHON, Global.GameMode.MARATHON_PRACTICE].has(Global.current_game_mode) == false:
		apply_character_physics()
	apply_character_sfx_map()
	Global.level_theme_changed.connect(apply_character_sfx_map)
	Global.level_theme_changed.connect(apply_character_physics)
	Global.level_theme_changed.connect(set_power_state_frame)
	if Global.current_level.first_load and Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		Global.player_power_states[player_id] = "0"
	power_state = $PowerStates.get_node(POWER_STATES[int(Global.player_power_states[player_id])])
	if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		camera.enabled = false
	handle_power_up_states(0)
	set_power_state_frame()
	handle_invincible_palette()
	if Global.level_editor == null:
		recenter_camera()

func apply_character_physics() -> void:
	var path = "res://Assets/Sprites/Players/" + character + "/CharacterInfo.json"
	if int(Global.player_characters[player_id]) > 3:
		path = path.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
	path = ResourceSetter.get_pure_resource_path(path)
	var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	for i in json.physics:
		set(i, json.physics[i])
	
	for i in get_tree().get_nodes_in_group("SmallCollisions"):
		var hitbox_scale = json.get("small_hitbox_scale", [1, 1])
		i.hitbox = Vector3(hitbox_scale[0], hitbox_scale[1] if i.get_meta("scalable", true) else 1, json.get("small_crouch_scale", 0.75))
		i._physics_process(0)
	for i in get_tree().get_nodes_in_group("BigCollisions"):
		var hitbox_scale = json.get("big_hitbox_scale", [1, 1])
		i.hitbox = Vector3(hitbox_scale[0], hitbox_scale[1] if i.get_meta("scalable", true) else 1, json.get("big_crouch_scale", 0.5))
		i._physics_process(0)

func apply_classic_physics() -> void:
	var json = JSON.parse_string(FileAccess.open("res://Resources/ClassicPhysics.json", FileAccess.READ).get_as_text())
	for i in json:
		set(i, json[i])

func recenter_camera() -> void:
	%CameraHandler.recenter_camera()
	%CameraHandler.update_camera_barriers()

func reparent_camera() -> void:
	return

func editor_level_start() -> void:
	if PipeArea.exiting_pipe_id == -1:
		power_state = get_node("PowerStates").get_child(starting_power_state)
	handle_power_up_states(0)
	set_power_state_frame()
	camera_make_current()
	recenter_camera()
	state_machine.transition_to("Normal")
	if camera_right_limit <= global_position.x:
		camera_right_limit = 99999999
	await get_tree().create_timer(0.1, false).timeout
	if camera_right_limit <= global_position.x:
		camera_right_limit = 99999999


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_reload"):
		set_power_state_frame()
	if Input.is_action_just_pressed("debug_noclip") and Global.debug_mode:
		state_machine.transition_to("NoClip")
		Global.log_comment("NOCLIP Enabled")
	up_direction = -gravity_vector
	handle_directions()
	handle_block_collision_detection()
	handle_wing_flight(delta)
	air_frames = (air_frames + 1 if is_on_floor() == false else 0)
	for i in get_tree().get_nodes_in_group("StepCollision"):
		var on_wall := false
		for x in [$StepWallChecks/LWall, $StepWallChecks/RWall]:
			if x.is_colliding():
				on_wall = true
		var step_enabled = (not on_wall and air_frames < 4 and velocity.y >= 0)
		i.set_deferred("disabled", not step_enabled)
	if is_actually_on_ceiling() and can_bump_sfx:
		bump_ceiling()
	elif is_actually_on_floor() and not is_invincible:
		stomp_combo = 0
	elif velocity.y > 15:
		can_bump_sfx = true
	handle_water_detection()
	%SkidParticles.visible = Settings.file.visuals.extra_particles == 1
	%SkidParticles.emitting = ((skidding and skid_frames > 2) or crouching) and is_on_floor() and abs(velocity.x) > 25 and Settings.file.visuals.extra_particles == 1
	if $SkidSFX.playing:
		if (is_actually_on_floor() and skidding) == false:
			$SkidSFX.stop()
	elif is_actually_on_floor() and skidding and Settings.file.audio.skid_sfx == 1:
		$SkidSFX.play()

const BUBBLE_PARTICLE = preload("uid://bwjae1h1airtr")

func handle_water_detection() -> void:
	var old_water = in_water
	if $Hitbox.monitoring:
		in_water = $Hitbox.get_overlapping_areas().any(func(area: Area2D): return area is WaterArea) or $WaterDetect.get_overlapping_bodies().is_empty() == false
	if old_water != in_water and in_water == false and flight_meter <= 0:
		water_exited()

func summon_bubble() -> void:
	var bubble = BUBBLE_PARTICLE.instantiate()
	bubble.global_position = global_position + Vector2(0, -16 if power_state.hitbox_size == "Small" else -32)
	add_sibling(bubble)

func _process(delta: float) -> void:
	handle_power_up_states(delta)
	handle_invincible_palette()
	if is_invincible:
		DiscoLevel.combo_meter = 100
	%Hammer.visible = has_hammer

func apply_gravity(delta: float) -> void:
	if in_water or flight_meter > 0:
		gravity = SWIM_GRAVITY
	else:
		if sign(gravity_vector.y) * velocity.y + JUMP_HOLD_SPEED_THRESHOLD > 0.0:
			gravity = FALL_GRAVITY
	velocity += (gravity_vector * ((gravity / (1.5 if low_gravity else 1.0)) / delta)) * delta
	var target_fall: float = MAX_FALL_SPEED
	if in_water:
		target_fall = MAX_SWIM_FALL_SPEED
	if gravity_vector.y > 0:
		velocity.y = clamp(velocity.y, -INF, (target_fall / (1.2 if low_gravity else 1.0)))
	else:
		velocity.y = clamp(velocity.y, -(target_fall / (1.2 if low_gravity else 1.0)), INF)

func camera_make_current() -> void:
	camera.enabled = true
	camera.make_current()

func play_animation(animation_name := "") -> void:
	if sprite.sprite_frames == null: return
	animation_name = get_fallback_animation(animation_name)
	if sprite.animation != animation_name:
		sprite.play(animation_name)

func get_fallback_animation(animation_name := "") -> String:
	if sprite.sprite_frames.has_animation(animation_name) == false and ANIMATION_FALLBACKS.has(animation_name):
		return get_fallback_animation(ANIMATION_FALLBACKS.get(animation_name))
	else:
		return animation_name

func apply_character_sfx_map() -> void:
	var path = "res://Assets/Sprites/Players/" + character + "/SFX.json"
	var custom_character := false
	if int(Global.player_characters[player_id]) > 3:
		custom_character = true
		path = path.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
	path = ResourceSetter.get_pure_resource_path(path)
	var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	
	for i in json:
		var res_path = "res://Assets/Audio/SFX/" + json[i]
		res_path = ResourceSetter.get_pure_resource_path(res_path)
		if FileAccess.file_exists(res_path) == false or custom_character:
			var directory = "res://Assets/Sprites/Players/" + character + "/" + json[i]
			if int(Global.player_characters[player_id]) > 3:
				directory = directory.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
			directory = ResourceSetter.get_pure_resource_path(directory)
			if FileAccess.file_exists(directory):
				json[i] = directory
			else:
				json[i] = res_path
		else:
			json[i] = res_path
	
	AudioManager.load_sfx_map(json)

func refresh_hitbox() -> void:
	$Hitbox.set_deferred("monitoring", false)
	$Hitbox.set_deferred("monitorable", false)
	await get_tree().physics_frame
	$Hitbox.set_deferred("monitoring", true)
	$Hitbox.set_deferred("monitorable", true)

func is_actually_on_floor() -> bool:
	if is_on_floor():
		return true
	else:
		for i in get_tree().get_nodes_in_group("CollisionRays"):
			if i.is_on_floor():
				return true
	return false

func is_actually_on_wall() -> bool:
	if is_on_wall():
		return true
	else:
		for i in get_tree().get_nodes_in_group("CollisionRays"):
			if i.is_on_wall():
				return true
	return false

func is_actually_on_ceiling() -> bool:
	if is_on_ceiling():
		return true
	else:
		for i in get_tree().get_nodes_in_group("CollisionRays"):
			if i.is_on_ceiling():
				return true
	return false

func enemy_bounce_off(add_combo := true, award_score := true) -> void:
	if add_combo:
		add_stomp_combo(award_score)
	jump_cancelled = not Global.player_action_pressed("jump", player_id)
	await get_tree().physics_frame
	if Global.player_action_pressed("jump", player_id):
		velocity.y = sign(gravity_vector.y) * -BOUNCE_JUMP_HEIGHT
		gravity = JUMP_GRAVITY
		has_jumped = true
	else:
		velocity.y = sign(gravity_vector.y) * -BOUNCE_HEIGHT

func add_stomp_combo(award_score := true) -> void:
	if stomp_combo >= 10:
		if award_score:
			if Global.current_game_mode == Global.GameMode.CHALLENGE or Settings.file.difficulty.inf_lives:
				Global.score += 10000
				score_note_spawner.spawn_note(10000)
			else:
				Global.lives += 1
				AudioManager.play_global_sfx("1_up")
				score_note_spawner.spawn_one_up_note()
	else:
		if award_score:
			Global.score += COMBO_VALS[stomp_combo]
			score_note_spawner.spawn_note(COMBO_VALS[stomp_combo])
		stomp_combo += 1

func bump_ceiling() -> void:
	AudioManager.play_sfx("bump", global_position)
	velocity.y = CEILING_BUMP_SPEED
	can_bump_sfx = false
	bumping = true
	await get_tree().create_timer(0.1).timeout
	AudioManager.kill_sfx("small_jump")
	AudioManager.kill_sfx("big_jump")
	await get_tree().create_timer(0.1).timeout
	bumping = false

func super_star() -> void:
	DiscoLevel.combo_meter += 1
	is_invincible = true
	$StarTimer.start()

var colour_palette: Texture = null

func stop_all_timers() -> void:
	flight_meter = -1
	for i in [$StarTimer, $HammerTimer]:
		i.stop()

func handle_invincible_palette() -> void:
	sprite.material.set_shader_parameter("mode", !Settings.file.visuals.rainbow_style)
	sprite.material.set_shader_parameter("player_palette", $PlayerPalette.texture)
	sprite.material.set_shader_parameter("palette_size", colour_palette.get_width())
	sprite.material.set_shader_parameter("invincible_palette", $InvinciblePalette.texture)
	sprite.material.set_shader_parameter("palette_idx", POWER_STATES.find(power_state.state_name))
	sprite.material.set_shader_parameter("enabled", (is_invincible or (palette_transform and transforming)))

func handle_block_collision_detection() -> void:
	if ["Pipe"].has(state_machine.state.name): return
	match power_state.hitbox_size:
		"Small":
			var points: Array = $SmallCollision.polygon
			points.sort_custom(func(a, b): return a.y < b.y)
			$BlockCollision.position.y = points.front().y * $SmallCollision.scale.y
		"Big":
			var points: Array = $BigCollision.polygon
			points.sort_custom(func(a, b): return a.y < b.y)
			$BlockCollision.position.y = points.front().y * $BigCollision.scale.y
	if velocity.y <= FALL_GRAVITY:
		for i in $BlockCollision.get_overlapping_bodies():
			if i is Block:
				if is_on_ceiling():
					i.player_block_hit.emit(self)
func handle_directions() -> void:
	input_direction = 0
	if Global.player_action_pressed("move_right", player_id):
		input_direction = 1
	elif Global.player_action_pressed("move_left", player_id):
		input_direction = -1
	velocity_direction = sign(velocity.x)

var use_big_collision := false

func handle_power_up_states(delta) -> void:
	for i in get_tree().get_nodes_in_group("SmallCollisions"):
		i.disabled = power_state.hitbox_size != "Small"
		i.visible = not i.disabled
		i.crouching = crouching
	for i in get_tree().get_nodes_in_group("BigCollisions"):
		i.disabled = power_state.hitbox_size != "Big"
		i.visible = not i.disabled
		i.crouching = crouching
	$Checkpoint.position.y = -24 if power_state.hitbox_size == "Small" else -40
	power_state.update(delta)

func handle_wing_flight(delta: float) -> void:
	flight_meter -= delta
	if flight_meter <= 0 && %Wings.visible:
		AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.WING)
		gravity = FALL_GRAVITY
	%Wings.visible = flight_meter >= 0
	if flight_meter < 0:
		return
	%BigWing.visible = power_state.hitbox_size == "Big"
	%SmallWing.visible = power_state.hitbox_size == "Small"
	for i in [%SmallWing, %BigWing]:
		if velocity.y < 0:
			i.play("Flap")
		else:
			i.play("Idle")
	if flight_meter <= 3:
		%Wings.get_node("AnimationPlayer").play("Flash")
	else:
		%Wings.get_node("AnimationPlayer").play("RESET")

func damage() -> void:
	if can_hurt == false or is_invincible:
		return
	times_hit += 1
	var damage_state = power_state.damage_state
	if damage_state != null:
		if Settings.file.difficulty.damage_style == 0:
			damage_state = get_node("PowerStates/Small")
		DiscoLevel.combo_meter -= 50
		AudioManager.play_sfx("damage", global_position)
		await power_up_animation(damage_state.state_name)
		power_state = get_node("PowerStates/" + damage_state.state_name)
		Global.player_power_states[player_id] = str(power_state.get_index())
		do_i_frames()
	else:
		die()

var cam_direction := 1
@onready var last_position := global_position

@onready var camera_position = camera.global_position
var camera_offset = Vector2.ZERO

func point_to_camera_limit(point := 0, point_dir := -1) -> float:
	return point + ((get_viewport_rect().size.x / 2.0) * -point_dir)

func point_to_camera_limit_y(point := 0, point_dir := -1) -> float:
	return point + ((get_viewport_rect().size.y / 2.0) * -point_dir)

func passed_checkpoint() -> void:
	if Settings.file.difficulty.checkpoint_style == 0:
		$Checkpoint/Animation.play("Show")
	AudioManager.play_sfx("checkpoint", global_position)

func do_i_frames() -> void:
	can_hurt = false
	for i in 25:
		sprite.hide()
		if get_tree() == null:
			return
		await get_tree().create_timer(0.04, false).timeout
		sprite.show()
		if get_tree() == null:
			return
		await get_tree().create_timer(0.04, false).timeout
	can_hurt = true
	refresh_hitbox()

func die(pit := false) -> void:
	if ["Dead", "Pipe", "LevelExit"].has(state_machine.state.name):
		return
	is_dead = true
	visible = not pit
	flight_meter = 0
	dead.emit()
	Global.p_switch_active = false
	Global.p_switch_timer = 0
	stop_all_timers()
	Global.total_deaths += 1
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	state_machine.transition_to("Dead", {"Pit": pit})
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Level.can_set_time = true
	Level.first_load = true
	if Global.current_game_mode != Global.GameMode.BOO_RACE:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.DEATH, 999, false)
		await get_tree().create_timer(3).timeout
	else:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.RACE_LOSE, 999, false)
		await get_tree().create_timer(5).timeout

	death_load()

func death_load() -> void:
	power_state = get_node("PowerStates/Small")
	Global.player_power_states = "0000"

	if Global.death_load:
		return
	Global.death_load = true

	# Handle lives decrement for CAMPAIGN and MARATHON
	if [Global.GameMode.CAMPAIGN, Global.GameMode.MARATHON].has(Global.current_game_mode):
		if Settings.file.difficulty.inf_lives == 0:
			Global.lives -= 1

	# Full dispatch table for death handling
	var death_actions = {
		Global.GameMode.CUSTOM_LEVEL: func():
			LevelTransition.level_to_transition_to = "res://Scenes/Levels/LevelEditor.tscn"
			Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn"),

		Global.GameMode.LEVEL_EDITOR: func():
			owner.stop_testing(),
			

		Global.GameMode.CHALLENGE: func():
			Global.transition_to_scene("res://Scenes/Levels/ChallengeMiss.tscn"),

		Global.GameMode.BOO_RACE: func():
			Global.reset_values()
			Global.clear_saved_values()
			Global.death_load = false
			Level.start_level_path = Global.current_level.scene_file_path
			Global.current_level.reload_level(),

		"time_up": func():
			Global.transition_to_scene("res://Scenes/Levels/TimeUp.tscn"),

		"game_over": func():
			Global.death_load = false
			Global.transition_to_scene("res://Scenes/Levels/GameOver.tscn"),

		"default_reload": func():
			LevelPersistance.reset_states()
			Global.current_level.reload_level()
	}

	# Determine which action to take
	if death_actions.has(Global.current_game_mode):
		death_actions[Global.current_game_mode].call()
	elif Global.lives <= 0 and Settings.file.difficulty.inf_lives == 0:
		death_actions["game_over"].call()
	elif Global.time <= 0:
		death_actions["time_up"].call()
	else:
		death_actions["default_reload"].call()

func time_up() -> void:
	die()

func set_power_state_frame() -> void:
	colour_palette = ResourceSetter.get_resource(preload("uid://b0quveyqh25dn"))
	$PlayerPalette/ResourceSetterNew.resource_json = (CHARACTER_PALETTES[int(Global.player_characters[player_id])])
	if power_state != null:
		$ResourceSetterNew.resource_json = load(get_character_sprite_path())
		$ResourceSetterNew.update_resource()
	if %Sprite.sprite_frames != null:
		can_pose = %Sprite.sprite_frames.has_animation("PoseDoor")
		can_bump_jump = %Sprite.sprite_frames.has_animation("JumpBump")
		can_bump_crouch = %Sprite.sprite_frames.has_animation("CrouchBump")
		can_bump_swim = %Sprite.sprite_frames.has_animation("SwimBump")
		can_bump_fly = %Sprite.sprite_frames.has_animation("FlyBump")

func get_power_up(power_name := "") -> void:
	if is_dead:
		return
	Global.score += 1000
	DiscoLevel.combo_amount += 1
	score_note_spawner.spawn_note(1000)
	AudioManager.play_sfx("power_up", global_position)
	if Settings.file.difficulty.damage_style == 0 and power_state.state_name != power_name:
		if power_name != "Big" and power_state.state_name != "Big":
			power_name = "Big"
	var new_power_state = get_node("PowerStates/" + power_name)
	if new_power_state.power_tier >= power_state.power_tier and new_power_state != power_state:
		can_hurt = false
		await power_up_animation(power_name)
	else:
		return
	power_state = new_power_state
	Global.player_power_states[player_id] = str(power_state.get_index())
	handle_power_up_states(0)
	can_hurt = true
	refresh_hitbox()
	await get_tree().physics_frame
	check_for_block()

func check_for_block() -> void:
	if test_move(global_transform, (Vector2.UP * gravity_vector) * 4):
		crouching = true

func power_up_animation(new_power_state := "") -> void:
	if normal_state.jump_buffer > 0:
		normal_state.jump_buffer += 10
	var old_frames = sprite.sprite_frames
	var new_frames = $ResourceSetterNew.get_resource(load(get_character_sprite_path(new_power_state)))
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.show()
	get_tree().paused = true
	if get_node("PowerStates/" + new_power_state).hitbox_size != power_state.hitbox_size:
		if Settings.file.visuals.transform_style == 0:
			sprite.speed_scale = 3
			sprite.play("Grow")
			var rainbow = new_power_state != "Big" and (power_state.state_name != "Big" and new_power_state != "Small")
			if rainbow:
				transforming = true
				sprite.material.set_shader_parameter("enabled", true)
			await get_tree().create_timer(0.4, true).timeout
			power_state = get_node("PowerStates/" + new_power_state)
			sprite.sprite_frames = new_frames
			handle_invincible_palette()
			sprite.play("Grow")
			await get_tree().create_timer(0.4, true).timeout
			if rainbow:
				sprite.material.set_shader_parameter("enabled", false)
			transforming = false
		else:
			sprite.speed_scale = 0
			if new_power_state == "Small":
				%GrowAnimation.play("Shrink")
			else:
				sprite.sprite_frames = new_frames
				%GrowAnimation.play("Grow")
			await get_tree().create_timer(0.8, true).timeout
			sprite.sprite_frames = new_frames
			transforming = false
	else:
		if Settings.file.visuals.transform_style == 1:
			for i in 6:
				sprite.sprite_frames = new_frames
				await get_tree().create_timer(0.05).timeout
				sprite.sprite_frames = old_frames
				await get_tree().create_timer(0.05).timeout
		else:
			handle_invincible_palette()
			sprite.stop()
			sprite.material.set_shader_parameter("enabled", true)
			transforming = true
			await get_tree().create_timer(0.6).timeout
			transforming = false
	get_tree().paused = false
	sprite.process_mode = Node.PROCESS_MODE_INHERIT
	if Global.player_action_just_pressed("jump", player_id):
		jump()
	return

const RESERVE_ITEM = preload("res://Scenes/Prefabs/Entities/Items/ReserveItem.tscn")

func dispense_stored_item() -> void:
	add_sibling(RESERVE_ITEM.instantiate())

func get_character_sprite_path(power_stateto_use := power_state.state_name) -> String:
	var path = "res://Assets/Sprites/Players/" + character + "/" + power_stateto_use + ".json"
	if int(Global.player_characters[player_id]) > 3:
		path = path.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
	return path

func enter_pipe(pipe: PipeArea, warp_to_level := true) -> void:
	z_index = -10
	can_bump_sfx = false
	Global.can_pause = false
	Global.can_time_tick = false
	pipe_enter_direction = pipe.get_vector(pipe.enter_direction)
	if pipe_enter_direction.x != 0:
		global_position.y = pipe.global_position.y + 14
	AudioManager.play_sfx("pipe", global_position)
	state_machine.transition_to("Pipe")
	PipeArea.exiting_pipe_id = pipe.pipe_id
	hide_pipe_animation()
	if warp_to_level:
		await get_tree().create_timer(1, false).timeout
		if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR or Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
			LevelEditor.play_pipe_transition = true
			owner.transition_to_sublevel(pipe.target_sub_level)
		else:
			Global.transition_to_scene(pipe.target_level)

func hide_pipe_animation() -> void:
	if pipe_enter_direction.x != 0:
		await get_tree().create_timer(0.3, false).timeout
		hide()
	else:
		await get_tree().create_timer(0.6, false).timeout
		hide()

func go_to_exit_pipe(pipe: PipeArea) -> void:
	Global.can_time_tick = false
	pipe_enter_direction = Vector2.ZERO
	state_machine.transition_to("Freeze")
	global_position = pipe.global_position + (pipe.get_vector(pipe.enter_direction) * 32)
	if pipe.enter_direction == 1:
		global_position = pipe.global_position + Vector2(0, -8)
	recenter_camera()
	if pipe.get_vector(pipe.enter_direction).y == 0:
		global_position.y += 16
		global_position.x -= 8 * pipe.get_vector(pipe.enter_direction).x
	reset_physics_interpolation()
	hide()

func exit_pipe(pipe: PipeArea) -> void:
	show()
	pipe_enter_direction = -pipe.get_vector(pipe.enter_direction)
	AudioManager.play_sfx("pipe", global_position)
	state_machine.transition_to("Pipe")
	await get_tree().create_timer(0.65, false).timeout
	Global.can_pause = true
	state_machine.transition_to("Normal")
	Global.can_time_tick = true

func jump() -> void:
	if spring_bouncing:
		return
	velocity.y = calculate_jump_height() * gravity_vector.y
	gravity = JUMP_GRAVITY
	AudioManager.play_sfx("small_jump" if power_state.hitbox_size == "Small" else "big_jump", global_position)
	has_jumped = true
	await get_tree().physics_frame
	has_jumped = true

func calculate_jump_height() -> float: # Thanks wye love you xxx
	return -(JUMP_HEIGHT + JUMP_INCR * int(abs(velocity.x) / 25))

const SMOKE_PARTICLE = preload("res://Scenes/Prefabs/Particles/SmokeParticle.tscn")

func teleport_player(new_position := Vector2.ZERO) -> void:
	hide()
	do_smoke_effect()
	var old_state = state_machine.state.name
	state_machine.transition_to("Freeze")
	await get_tree().create_timer(0.5, false).timeout
	global_position = new_position
	recenter_camera()
	await get_tree().create_timer(0.5, false).timeout
	state_machine.transition_to(old_state)
	show()
	velocity.y = 0
	do_smoke_effect()

func do_smoke_effect() -> void:
	for i in 2:
		var node = SMOKE_PARTICLE.instantiate()
		node.global_position = global_position - Vector2(0, 16 * i)
		add_sibling(node)
		if power_state.hitbox_size == "Small":
			break
	AudioManager.play_sfx("magic", global_position)

func on_timeout() -> void:
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.STAR)
	await get_tree().create_timer(1, false).timeout
	is_invincible = false


func on_area_entered(area: Area2D) -> void:
	if area.owner is Player and area.owner != self:
		if area.owner.velocity.y > 0 and area.owner.is_actually_on_floor() == false:
			area.owner.enemy_bounce_off(false)
			velocity.y = 50
			AudioManager.play_sfx("bump", global_position)

func hammer_get() -> void:
	has_hammer = true
	$HammerTimer.start()
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.HAMMER, 0, false)

func on_hammer_area_entered(area: Area2D) -> void:
	pass

func wing_get() -> void:
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.WING, 0, false, false)
	flight_meter = 10

func on_hammer_timeout() -> void:
	has_hammer = false
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.HAMMER)

func water_exited() -> void:
	await get_tree().physics_frame
	if in_water: return
	normal_state.swim_up_meter = 0
	if velocity.y < 0:
		velocity.y = -250.0 if velocity.y < -50.0 or Global.player_action_pressed("move_up", player_id) else velocity.y
	has_jumped = true
	if Global.player_action_pressed("move_up", player_id):
		gravity = JUMP_GRAVITY
	else:
		gravity = FALL_GRAVITY

func reset_camera_to_center() -> void:
	animating_camera = true
	var old_position = camera.position
	camera.global_position = get_viewport().get_camera_2d().get_screen_center_position()
	camera.reset_physics_interpolation()
	var tween = create_tween()
	tween.tween_property(camera, "position", old_position, 0.5)
	await tween.finished
	camera.position = old_position
	animating_camera = false

func on_area_exited(area: Area2D) -> void:
	if area is WaterArea:
		water_exited()
