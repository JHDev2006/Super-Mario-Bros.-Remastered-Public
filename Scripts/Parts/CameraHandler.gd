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

# how far between the center and the edge of the screen before scrolling to the center
const SCROLL_DIFFERENCE := 48.0

var can_diff := true

# guzlad: old Special scrolling variables kept for reference purposes
static var sp_screen_scroll := false
#static var sp_scroll_style := 1

var sp_scrolling := false

func _exit_tree() -> void:
	cam_locked = false

func _physics_process(delta: float) -> void:
	sp_screen_scroll = Settings.file.visuals.smbs_scroll > 0
	handle_camera(delta)
	last_position = global_position

func handle_camera(delta: float) -> void:
	
	can_scroll_left = camera_position.x + camera_offset.x > -255
	can_scroll_right = camera_position.x + camera_offset.x < camera_right_limit - 1
	
	if ["Pipe", "Climb", "FlagPole"].has(owner.state_machine.state.name):
		handle_vertical_scrolling(delta)
		do_limits()
		camera.global_position = camera_position + camera_offset
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
	if get_viewport() != null:
		camera_center_joint.global_position = get_viewport().get_camera_2d().get_screen_center_position()
		camera_center_joint.get_node("LeftWall").position.x = -(get_viewport_rect().size.x / 2)
		camera_center_joint.get_node("RightWall").position.x = (get_viewport_rect().size.x / 2)

func handle_horizontal_scrolling(delta: float) -> void:
	scrolling = false
	var true_velocity = (global_position - last_position) / delta
	var true_vel_dir = sign(true_velocity.x)
	if (owner.is_on_wall() and owner.direction == -owner.get_wall_normal().x):
		true_vel_dir = 0
		true_velocity.x = 0
	## RIGHT MOVEMENT
	if true_vel_dir == 1 and can_scroll_right:
		cam_direction = 1
		if global_position.x >= camera_position.x:
			var offset = 0
			if camera_position.x <= global_position.x - 4:
				offset = camera_position.x - global_position.x + abs(true_velocity.x * delta)
			scrolling = true
			camera_position.x = global_position.x + offset
	
	## LEFT MOVEMENT
	elif true_vel_dir == -1 and can_scroll_left and Global.current_level.can_backscroll:
		cam_direction = -1
		if global_position.x <= camera_position.x:
			scrolling = true
			var offset = 0
			if camera_position.x >= global_position.x + 4:
				offset = camera_position.x - global_position.x - abs(true_velocity.x * delta)
			camera_position.x = global_position.x + offset
	
	if can_diff == false: 
		position.x = 0
		return
	# horizontal adjusgments
	# if the position is matching the camera, start scrolling towards the center
	if global_position.x >= camera_position.x:
		position.x = move_toward(position.x,0.0,delta * max(30.0, abs(true_velocity.x / 2.3)))
	else:
		# if the camera if behind the middle of the screen, calculate the current difference
		position.x = max(min(camera_position.x-global_position.x,SCROLL_DIFFERENCE),position.x)


func handle_vertical_scrolling(_delta: float) -> void:
	## VERTICAL MOVEMENT
	if global_position.y < camera_position.y and owner.is_on_floor():
		camera_position.y = move_toward(camera_position.y, global_position.y, 3)
	elif global_position.y < camera_position.y - 64:
		camera_position.y = global_position.y + 64
	elif global_position.y > camera_position.y + 32:
		camera_position.y = global_position.y - 32

func handle_sp_scrolling() -> void:
	var distance = camera_position.x - owner.global_position.x
	var limit = get_viewport().get_visible_rect().size.x / 2 - 16
	if abs(distance) > limit:
		do_sp_scroll(sign(owner.global_position.x - camera_position.x))

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
	camera_position = global_position
	last_position = camera_position
	camera_position += camera_offset
	do_limits()
	camera.global_position = camera_position

func handle_offsets(delta: float) -> void:
	var true_velocity = (global_position - last_position) / delta
	var true_vel_dir = sign(true_velocity.x)
	if owner.velocity.x == 0 or (owner.is_on_wall() and owner.direction == -owner.get_wall_normal().x):
		true_vel_dir = 0
		true_velocity.x = 0
	if Global.current_level.can_backscroll:
		if true_vel_dir != 0 and abs(true_velocity.x) > 80:
			if abs(camera_position.x - global_position.x) <= 64:
				camera_offset.x = move_toward(camera_offset.x, 8 * true_vel_dir, abs(true_velocity.x) / 200)
	else:
		camera_offset.x = 8

func do_limits() -> void:
	camera_right_limit = clamp(Player.camera_right_limit, -256 + (get_viewport().get_visible_rect().size.x), INF)
	camera_position.x = clamp(camera_position.x, point_to_camera_limit(-256 - camera_offset.x, -1), point_to_camera_limit(camera_right_limit - camera_offset.x, 1))
	camera_position.y = clamp(camera_position.y, point_to_camera_limit_y(Global.current_level.vertical_height, -1), point_to_camera_limit_y(32, 1))
	var wall_enabled := true
	if is_instance_valid(Global.level_editor):
		if Global.level_editor.playing_level == false:
			wall_enabled = false
	$"../CameraCenterJoint/LeftWall".set_collision_layer_value(1, wall_enabled)
	var level_exit = false
	if owner.state_machine != null:
		level_exit = owner.state_machine.state.name == "LevelExit"
	$"../CameraCenterJoint/RightWall".set_collision_layer_value(1, wall_enabled and level_exit == false)
	
func point_to_camera_limit(point := 0, point_dir := -1) -> float:
	return point + ((get_viewport_rect().size.x / 2.0) * -point_dir)

func point_to_camera_limit_y(point := 0, point_dir := -1) -> float:
	return point + ((get_viewport_rect().size.y / 2.0) * -point_dir)
