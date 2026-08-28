class_name CameraHandler
extends Node2D

@onready var last_position = global_position
@export var camera: Camera2D = null

@export var camera_center_joint: Node2D = null

var camera_position := Vector2.ZERO
var camera_offset := Vector2(8, 0)

var camera_right_limit := 9999999

var player_offset := 0.0

var can_scroll_left := true
var can_scroll_right := true

static var cam_locked := false

var scrolling := false
var cam_direction := 1

static var solid_cam_bounds := false

# how far between the center and the edge of the screen before scrolling to the center
const SCROLL_DIFFERENCE := 48.0

var can_diff := true

# guzlad: old Special scrolling variables kept for reference purposes
static var sp_screen_scroll := false
#static var sp_scroll_style := 1

var player: Player = null

var sp_scrolling := false


func _exit_tree() -> void:
	cam_locked = false
	solid_cam_bounds = false

func _ready() -> void:
	player = owner


func _physics_process(delta: float) -> void:
	sp_screen_scroll = Settings.file.visuals.smbs_scroll > 0
	handle_camera.call_deferred(delta)
	if is_instance_valid(player):
		set_deferred("last_position", player.global_position)

func handle_camera(delta: float) -> void:
	if get_tree().get_first_node_in_group("Players") == null:
		return
	for i in get_tree().get_nodes_in_group("Players"):
		if is_instance_valid(player) == false:
			player = i
		if i != player:
			if i.velocity.x > player.velocity.x:
				if i.global_position.x + (i.velocity.x * delta * 60) > player.global_position.x:
					player = i
			elif i.global_position.x > player.global_position.x:
				player = i
	can_scroll_left = camera_position.x + camera_offset.x > -255
	can_scroll_right = camera_position.x + camera_offset.x < camera_right_limit - 1
	
	if ["Pipe", "Climb", "FlagPole"].has(player.state_machine.state.name):
		handle_vertical_scrolling(delta)
		do_limits()
		camera.global_position = camera_position + camera_offset
		if not player.exiting_pipe:
			return
	
	if not cam_locked:
		if not sp_screen_scroll:
			handle_horizontal_scrolling(delta)
			handle_vertical_scrolling(delta)
			handle_offsets(delta)
		else:
			handle_sp_scrolling()
	
	do_limits()
	camera.global_position = camera_position + camera_offset
	update_camera_barriers()

func update_camera_barriers() -> void:
	if get_viewport() != null and get_viewport().get_camera_2d() != null:
		camera_center_joint.global_position = get_viewport().get_camera_2d().get_screen_center_position()
		camera_center_joint.get_node("LeftWall").position.x = -(get_viewport_rect().size.x / 2)
		camera_center_joint.get_node("RightWall").position.x = (get_viewport_rect().size.x / 2)
		for i in [camera_center_joint.get_node("RightWall"), camera_center_joint.get_node("LeftWall")]:
			i.get_node("CollisionShape2D").set_deferred("one_way_collision", not solid_cam_bounds)

func handle_horizontal_scrolling(delta: float) -> void:
	scrolling = false
	var true_velocity = (player.global_position - last_position) / delta
	var true_vel_dir = sign(true_velocity.x)
	if (player.is_on_wall() and player.direction == -player.get_wall_normal().x):
		true_vel_dir = 0
		true_velocity.x = 0
	## RIGHT MOVEMENT
	if true_vel_dir == 1 and can_scroll_right:
		cam_direction = 1
		if player.global_position.x >= camera_position.x:
			var offset = 0
			if camera_position.x <= player.global_position.x - 4:
				offset = camera_position.x - player.global_position.x + abs(true_velocity.x * delta)
				offset += abs(true_velocity.x) * delta / 2
			scrolling = true
			
			camera_position.x = player.global_position.x + offset
		elif player.global_position.x >= camera.get_screen_center_position().x - get_viewport().get_visible_rect().size.x / 5 and (player.velocity.x) > 20:
			camera_position.x += min(abs(player.velocity.x), 40) * delta
	
	## LEFT MOVEMENT
	elif true_vel_dir == -1 and can_scroll_left and Global.current_level.can_backscroll:
		cam_direction = -1
		if player.global_position.x <= camera_position.x:
			scrolling = true
			var offset = 0
			if camera_position.x >= player.global_position.x + 4:
				offset = camera_position.x - player.global_position.x - abs(true_velocity.x * delta)
			camera_position.x = player.global_position.x + offset
		elif player.global_position.x <= camera.get_screen_center_position().x + get_viewport().get_visible_rect().size.x / 5 and (player.velocity.x) < -20:
			camera_position.x += max(player.velocity.x, -40) * delta
	
	if can_diff == false: 
		position.x = 0
		return


func handle_vertical_scrolling(_delta: float) -> void:
	## VERTICAL MOVEMENT
	if player.global_position.y < camera_position.y and player.is_on_floor():
		camera_position.y = move_toward(camera_position.y, player.global_position.y, 3)
	elif player.global_position.y < camera_position.y - 64:
		camera_position.y = player.global_position.y + 64
	elif player.global_position.y > camera_position.y + 32:
		camera_position.y = player.global_position.y - 32

func handle_sp_scrolling() -> void:
	var distance = camera_position.x - player.global_position.x
	var limit = get_viewport().get_visible_rect().size.x / 2 - 16
	if abs(distance) > limit:
		do_sp_scroll(sign(player.global_position.x - camera_position.x))

func do_sp_scroll(direction := 1) -> void:
	if sp_scrolling: return
	sp_scrolling = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var distance = get_viewport().get_visible_rect().size.x - 32
	if Settings.file.visuals.smbs_scroll == 1: #Sharp X1 (smooth)
		var tween = create_tween()
		tween.tween_property(self, "camera_position:x", camera_position.x + (distance * direction), 1)
		await tween.finished
	else: #PC-8801 (black screen)
		if Settings.file.visuals.transition_animation:
			Global.get_node("Transition").get_node("TransitionBlock").modulate.a = 1
		Global.get_node("Transition").show()
		await get_tree().create_timer(0.5).timeout
		camera_position.x += distance * direction
		await get_tree().create_timer(0.5).timeout
		Global.get_node("Transition").hide()
	sp_scrolling = false
	get_tree().paused = false

func tween_ahead() -> void:
	if scrolling == false: return
	await get_tree().create_timer(0.25).timeout
	var tween = create_tween()
	tween.tween_property(self, "camera_position:x", camera_position.x + (32 * cam_direction), 0.25)

func recenter_camera() -> void:
	if is_instance_valid(player) == false:
		player = owner
	camera_position = player.global_position
	last_position = camera_position
	camera_position += camera_offset
	do_limits()
	camera.global_position = camera_position
	camera.reset_physics_interpolation()
	camera.reset_smoothing()

func handle_offsets(delta: float) -> void:
	var true_velocity = (player.global_position - last_position) / delta
	var true_vel_dir = sign(true_velocity.x)
	if player.velocity.x == 0 or (player.is_on_wall() and player.direction == -player.get_wall_normal().x):
		true_vel_dir = 0
		true_velocity.x = 0
	if Global.current_level.can_backscroll:
		const CENTER_OFFSET := 8
		if true_vel_dir != 0 and abs(true_velocity.x) > 80:
			var left_bound := camera_position.x - CENTER_OFFSET >= point_to_camera_limit(-256, -1)
			var right_bound = camera_position.x + CENTER_OFFSET <= point_to_camera_limit(camera_right_limit, 1)
			if abs(camera_position.x - player.global_position.x) <= 16 and left_bound and right_bound:
				camera_offset.x = move_toward(camera_offset.x, CENTER_OFFSET * true_vel_dir, abs(true_velocity.x) / 200)
	else:
		camera_offset.x = 8

func do_limits() -> void:
	if get_viewport() == null: return
	var viewport_size = get_viewport().get_visible_rect().size
	if Global.current_level.enforce_resolution != Vector2.ZERO:
		viewport_size = Global.current_level.enforce_resolution
	camera_right_limit = clamp(Player.camera_right_limit, -256 + (viewport_size.x), INF)
	camera_position.x = clamp(camera_position.x, point_to_camera_limit(-256 - camera_offset.x, -1), point_to_camera_limit(camera_right_limit - camera_offset.x, 1))
	camera_position.y = clamp(camera_position.y, point_to_camera_limit_y(Global.current_level.vertical_height, -1), point_to_camera_limit_y(32, 1))
	var wall_enabled := true
	if is_instance_valid(Global.level_editor):
		if Global.level_editor.playing_level == false:
			wall_enabled = false
	$"../CameraCenterJoint/LeftWall".set_collision_layer_value(1, wall_enabled)
	var level_exit = false
	if player.state_machine != null:
		level_exit = player.state_machine.state.name == "LevelExit"
	$"../CameraCenterJoint/RightWall".set_collision_layer_value(1, wall_enabled and level_exit == false)
	
func point_to_camera_limit(point := 0, point_dir := -1) -> int:
	return point + ((get_viewport_rect().size.x / 2.0) * -point_dir)

func point_to_camera_limit_y(point := 0, point_dir := -1) -> int:
	return point + ((get_viewport_rect().size.y / 2.0) * -point_dir)
