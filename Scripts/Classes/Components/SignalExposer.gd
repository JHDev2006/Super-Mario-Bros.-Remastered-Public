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

const RECURSIVE_LIMIT := 500

var turned_on := false

@onready var line_drawer := LineDrawer.new()

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

@export_storage var all_connected := false

var wire_node: Node2D = null
var save_string := ""

var no_moving = null

@export_storage var line_drawer_added := false

var saved_offset := Vector2.ZERO

func _enter_tree() -> void:
	set_visibility_layer_bit(0, false)
	set_visibility_layer_bit(1, true)
	add_to_group("SignalExposers")
	save_string = owner.get_meta("save_string", "")
	if save_string != "":
		apply_string(save_string)
		owner.remove_meta("save_string")
		save_string = ""
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 10
	global_position = owner.global_position + position_offset
	if Global.level_editor != null:
		if Global.level_editor_is_editing() == false:
			get_tree().call_group("Gizmos", "set_visible", Global.level_editor.gizmos_visible)
	else:
		get_tree().call_group("Gizmos", "hide" if Global.debug_mode == false else "show")

func _ready() -> void:
	connect_pre_existing_signals()
	if line_drawer_added == false:
		add_child(line_drawer)
		line_drawer.top_level = true
		line_drawer.queue_redraw()
		line_drawer_added = true
	line_drawer = get_child(0)
	line_drawer.global_position = global_position
	if Global.level_editor != null:
		Global.level_editor.level_start.connect(line_drawer.queue_redraw)

func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	if editing:
		line_drawer.queue_redraw()
	elif Global.level_editor_is_editing() == false and no_moving != true:
		no_moving = true
		for x in connections:
			var target_node = get_node_from_tile(x[0], x[1])
			if target_node is TrackRider:
				line_drawer.queue_redraw()
				no_moving = false

func begin_connecting() -> void:
	update_animation(1.0, 1.2)
	editing = true
	await signal_connected
	editing = false
	update_animation(1.2, 1.0)
	line_drawer.queue_redraw()

func turn_on() -> void:
	if accepting_inputs == false: return
	if check_recursive() == false:
		return
	signals_recieved += 1
	update_animation(1.0, 1.2)
	powered_on.emit()
	signals_recieved = 0
	turned_on = true
	line_drawer.queue_redraw()

func turn_off() -> void:
	if accepting_inputs == false: return
	if check_recursive() == false:
		return
	signals_recieved += 1
	update_animation(1.2, 1.0)
	powered_off.emit()
	signals_recieved = 0
	turned_on = false
	line_drawer.queue_redraw()

func _exit_tree() -> void:
	signals_recieved = 0

func emit_pulse() -> void:
	if get_tree() == null: return
	if accepting_inputs == false: return
	update_animation(1.2, 1.0)
	if check_recursive() == false:
		return
	signals_recieved += 1
	pulse_emitted.emit()
	signals_recieved = 0
	turned_on = true
	if (line_drawer == null):
		line_drawer = LineDrawer.new()
		add_child(line_drawer)
	line_drawer.queue_redraw()
	await get_tree().create_timer(0.1, false).timeout
	turned_on = false
	line_drawer.queue_redraw()

func stop_connection() -> void:
	editing = false
	update_animation(1.2, 1.0)
	line_drawer.queue_redraw()

func connect_pre_existing_signals() -> void:
	for i in connections:
		connect_to_node(i, false)
	all_connected = true

func connect_to_node(node_to_recieve := [], animate := true, can_disconnect := false) -> void:
	has_output = true
	var node: Node = get_node_from_tile(node_to_recieve[0], node_to_recieve[1])
	if node == null:
		Global.log_error("Bad signal connection! Broken Gizmos got disconnected!")
		queue_free()
		return
	if (can_disconnect && connections.has(node_to_recieve)):
		disconnect_node(node_to_recieve)
		signal_connected.emit()
		return
	node.tree_exiting.connect(remove_node_connection.bind(node_to_recieve))
	if connections.has(node_to_recieve) == false:
		connections.append(node_to_recieve.duplicate())
	if connect_type == ConnectType.SIGNAL:
		pulse_emitted.connect(node.get_node("SignalExposer").on_recieve_pulse)
		powered_on.connect(node.get_node("SignalExposer").on_recieve_power)
		powered_off.connect(node.get_node("SignalExposer").on_lost_power)
		node.get_node("SignalExposer").has_input = true
		node.get_node("SignalExposer").total_inputs += 1
		if animate:
			node.get_node("SignalExposer").update_animation(1.2, 1.0, true)
		tree_exiting.connect(node.get_node("SignalExposer").input_removed)
	signal_connected.emit()

func remove_node_connection(node := []) -> void:
	if is_inside_tree():
		connections.erase(node)
		line_drawer.queue_redraw()
	if connections.is_empty():
		has_output = false

func disconnect_node(node_to_recieve := []) -> void:
	remove_node_connection(node_to_recieve)
	
	var node_signal: Node = get_node_from_tile(node_to_recieve[0], node_to_recieve[1]).get_node("SignalExposer")
	pulse_emitted.disconnect(node_signal.on_recieve_pulse)
	powered_on.disconnect(node_signal.on_recieve_power)
	powered_off.disconnect(node_signal.on_lost_power)
	node_signal.total_inputs -= 1
	node_signal.has_input = node_signal.total_inputs != 0
	node_signal.update_animation(0.8, 1.0, true)

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
	if owner.get_meta("save_string", "") != "":
		var string = owner.get_meta("save_string")
		string = string.substr(string.find(",$"))
		return string
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
		return false
	return true

const EXPLOSION = preload("uid://clbvyne1cr8gp")

func explode() -> void:
	await get_tree().process_frame
	var node = EXPLOSION.instantiate()
	node.global_position = owner.global_position
	owner.add_sibling(node)
	AudioManager.play_sfx("explode", global_position)
	owner.queue_free()
