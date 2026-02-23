class_name SignalExposer
extends Node2D

signal signal_connected

signal pulse_emitted
signal powered_on
signal powered_off

signal recieved_pulse
signal recieved_power
signal lost_power

static var signals_recieved := 0

const RECURSIVE_LIMIT := 256

var turned_on := false

@export var can_input := true
@export var can_output := true
@export var connect_type := ConnectType.SIGNAL
const ARROW = preload("res://Assets/Sprites/Editor/Gizmos/ConnectionArrow.png")

enum ConnectType{SIGNAL, REFERENCE}

var editing := false

var has_input := false
var has_output := false
var total_inputs := 0

var accepting_inputs := true

@export_storage var connections := []
@export var do_animation := true
@export_storage var position_offset := position

var wire_node: Node2D = null
var save_string := ""

const WIRE_COLOURS := [
  "#FF0000",
  "#00FF00",
  "#0000FF",
  "#FFFF00",
  "#FF00FF",
  "#00FFFF",
  "#FFA500",
  "#800080"
]

@onready var recursive_check := Timer.new()

var no_moving = null

var saved_offset := Vector2.ZERO

func _ready() -> void:
	add_child(recursive_check)
	if get_process_delta_time() > 0:
		recursive_check.wait_time = get_process_delta_time()
	recursive_check.timeout.connect(on_recursive_timeout)
	recursive_check.start()
	set_visibility_layer_bit(0, false)
	set_visibility_layer_bit(1, true)
	add_to_group("SignalExposers")
	save_string = owner.get_meta("save_string", "")
	if save_string != "":
		apply_string(save_string)
		owner.remove_meta("save_string")
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 10
	global_position = owner.global_position + position_offset
	call_deferred("connect_pre_existing_signals")
	queue_redraw()
	if Global.level_editor != null:
		Global.level_editor.level_start.connect(queue_redraw)
	if Global.level_editor_is_editing() == false:
		get_tree().call_group("Gizmos", "hide")

func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	if editing:
		queue_redraw()
	elif Global.level_editor_is_editing() == false and no_moving != true:
		no_moving = true
		for x in connections:
			var target_node = get_node_from_tile(x[0], x[1])
			if target_node is TrackRider:
				queue_redraw()
				no_moving = false

func _draw() -> void:
	show()
	var gizmo_visible = false
	if Global.level_editor != null:
		gizmo_visible = Global.level_editor.gizmos_visible
	if Global.level_editor_is_editing() == false and gizmo_visible == false:
		hide()
		return
	if editing:
		draw_square_line(Vector2.ZERO, (get_local_mouse_position() + Vector2(0, 0)).snapped(Vector2(16, 16)) + Vector2(0, 0), WIRE_COLOURS[connections.size() % WIRE_COLOURS.size()])
	var idx := 0
	for x in connections:
		var target_node = get_node_from_tile(x[0], x[1])
		if target_node == null:
			continue
		draw_square_line(Vector2.ZERO, to_local(target_node.get_node("SignalExposer").global_position), WIRE_COLOURS[idx % (WIRE_COLOURS.size())], true)
		idx += 1

func draw_square_line(from := Vector2.ZERO, to := Vector2.ZERO, colour := Color.RED, offset := false) -> void:
	var dist_x = abs(from.x - to.x)
	var dist_y = abs(from.y - to.y)
	if turned_on:
		if (dist_y == 0 or dist_x == 0):
			draw_line(from, to, colour, 1, false)
			draw_arrow_head(from, to, colour, offset)
		elif dist_x == dist_y and dist_x > 16:
			draw_line(from, to, colour, 2, false)
			draw_arrow_head(from, to, colour, offset)
		elif dist_x > dist_y:
			draw_line(from, Vector2(to.x, from.y), colour, 2) 
			var direction = (to - Vector2(to.x, from.y)).normalized()
			if offset:
				to -= direction * 8
			draw_line(Vector2(to.x, from.y), to, colour, 2)
			draw_arrow_head(Vector2(to.x, from.y), to, colour, offset)
		else:
			draw_line(from, Vector2(from.x, to.y), colour, 2)
			draw_line(Vector2(from.x, to.y), to, colour, 2)
			var direction = (to - Vector2(from.x, to.y)).normalized()
			if offset:
				to -= direction * 8
			draw_arrow_head(Vector2(from.x, to.y), to, colour, offset)
	else:
		if (dist_y == 0 or dist_x == 0):
			draw_dashed_line(from, to, colour, 1)
			draw_arrow_head(from, to, colour, offset)
		elif (dist_x == dist_y and dist_x > 16):
			draw_dashed_line(from, to, colour, 1.5, 2.0, false)
			draw_arrow_head(from, to, colour, offset)
		elif dist_x > dist_y:
			draw_dashed_line(from, Vector2(to.x, from.y), colour, 1)
			var direction = (to - Vector2(to.x, from.y)).normalized()
			if offset:
				to -= direction * 8
			draw_dashed_line(Vector2(to.x, from.y), to, colour, 1)
			draw_arrow_head(Vector2(to.x, from.y), to, colour, offset)
		else:
			draw_dashed_line(from, Vector2(from.x, to.y), colour, 1)
			var direction = (to - Vector2(from.x, to.y)).normalized()
			if offset:
				to -= direction * 8
			draw_dashed_line(Vector2(from.x, to.y), to, colour, 1)
			draw_arrow_head(Vector2(from.x, to.y), to, colour, offset)

func draw_arrow_head(from := Vector2.ZERO, point := Vector2.ZERO, color := Color.RED, offset := false) -> void:
	var direction = (point - from).normalized()
	if offset:
		point -= direction * 1
	else:
		point -= direction * 3
	var head = (direction * 2)
	var left_point = (-direction * 4).rotated(deg_to_rad(-45)) + direction
	var right_point = (-direction * 4).rotated(deg_to_rad(45)) + direction
	head += point + direction
	left_point += point + direction
	right_point += point + direction
	draw_polygon([head, left_point, right_point], [color, color, color])

func begin_connecting() -> void:
	update_animation(1.0, 1.2)
	editing = true
	await signal_connected
	editing = false
	update_animation(1.2, 1.0)
	queue_redraw()

func turn_on() -> void:
	if accepting_inputs == false: return
	signals_recieved += 1
	if check_recursive() == false:
		return
	update_animation(1.0, 1.2)
	powered_on.emit()
	turned_on = true
	queue_redraw()

func turn_off() -> void:
	if accepting_inputs == false: return
	signals_recieved += 1
	if check_recursive() == false:
		return
	update_animation(1.2, 1.0)
	powered_off.emit()
	turned_on = false
	queue_redraw()

func _exit_tree() -> void:
	signals_recieved = 0

func emit_pulse() -> void:
	if get_tree() == null: return
	if accepting_inputs == false: return
	signals_recieved += 1
	if check_recursive() == false:
		return
	update_animation(1.2, 1.0)
	pulse_emitted.emit()
	turned_on = true
	queue_redraw()
	await get_tree().create_timer(0.1, false).timeout
	turned_on = false
	queue_redraw()

func stop_connection() -> void:
	editing = false
	update_animation(1.2, 1.0)
	queue_redraw()

func connect_pre_existing_signals() -> void:
	for i in connections:
		connect_to_node(i)

func connect_to_node(node_to_recieve := []) -> void:
	has_output = true
	var node: Node = get_node_from_tile(node_to_recieve[0], node_to_recieve[1])
	node.tree_exiting.connect(remove_node_connection.bind(node_to_recieve))
	if connections.has(node_to_recieve) == false:
		connections.append(node_to_recieve.duplicate())
	if connect_type == ConnectType.SIGNAL:
		pulse_emitted.connect(node.get_node("SignalExposer").on_recieve_pulse)
		powered_on.connect(node.get_node("SignalExposer").on_recieve_power)
		powered_off.connect(node.get_node("SignalExposer").on_lost_power)
		node.get_node("SignalExposer").has_input = true
		node.get_node("SignalExposer").total_inputs += 1
		node.get_node("SignalExposer").update_animation(1.2, 1.0, true)
		tree_exiting.connect(node.get_node("SignalExposer").input_removed)
	signal_connected.emit()

func remove_node_connection(node := []) -> void:
	if is_inside_tree():
		connections.erase(node)
		queue_redraw()
	if connections.is_empty():
		has_output = false

func on_recieve_pulse() -> void:
	if accepting_inputs == false: return
	if check_recursive():
		recieved_pulse.emit()

func on_lost_power() -> void:
	if accepting_inputs == false: return
	if check_recursive():
		lost_power.emit()

func on_recieve_power() -> void:
	if accepting_inputs == false: return
	if check_recursive():
		recieved_power.emit()

func increment_pulse() -> void:
	pass

func input_removed() -> void:
	total_inputs -= 1
	if total_inputs <= 0:
		has_input = false

func get_string() -> String:
	var entity_string := ""
	for i in connections:
		entity_string += ",$"
		entity_string += str(i[0]) + "," + str(i[1].x) + "," + str(i[1].y)
	return entity_string

func apply_string(string := "") -> void:
	var arr := []
	if string.contains("$"):
		string = string.substr(string.find("$"))
		arr = string.split("$", false)
	for i in arr:
		var signal_arr = i.split(",")
		connections.append([int(signal_arr[0]), Vector2i(int(signal_arr[1]), int(signal_arr[2]))])

func get_node_from_tile(layer_num := 0, tile_position := Vector2i.ZERO) -> Node:
	for i in get_tree().get_nodes_in_group("SignalExposers"):

		if i.owner.get_meta("tile_position", Vector2i.ZERO) == tile_position and i.owner.get_parent() == Global.current_level.get_node("EntityLayer" + str(layer_num + 1)):
			return i.owner
	return null

func update_animation(from := 1.2, to := 1.0, force := false) -> void:
	if (do_animation == false or is_visible_in_tree() == false) and not force:
		return
	owner.scale = Vector2(from, from)
	create_tween().set_trans(Tween.TRANS_CIRC).tween_property(owner, "scale", Vector2(to, to), 0.15)

func on_recursive_timeout() -> void:
	signals_recieved = 0

func check_recursive() -> bool:
	if accepting_inputs == false:
		return false
	if signals_recieved >= RECURSIVE_LIMIT:
		accepting_inputs = false
		explode()
	return signals_recieved < RECURSIVE_LIMIT

const EXPLOSION = preload("uid://clbvyne1cr8gp")

func explode() -> void:
	await get_tree().process_frame
	var node = EXPLOSION.instantiate()
	node.global_position = owner.global_position
	owner.add_sibling(node)
	AudioManager.play_sfx("explode", global_position)
	owner.queue_free()
