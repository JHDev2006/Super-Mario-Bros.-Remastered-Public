class_name LineDrawer
extends Node2D

@onready var signal_exposer: SignalExposer = get_parent()

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

func _ready() -> void:
	set_visibility_layer_bit(0, false)
	set_visibility_layer_bit(1, true)
	z_index = 1
	z_as_relative = false

func _draw() -> void:
	show()
	var gizmo_visible = false
	if Global.level_editor != null:
		gizmo_visible = Global.level_editor.gizmos_visible or Global.debug_mode
	if Global.level_editor_is_editing() == false and gizmo_visible == false and not Global.debug_mode:
		hide()
		return
	if signal_exposer.editing:
		draw_square_line(Vector2.ZERO, (get_local_mouse_position() + Vector2(0, 0)).snapped(Vector2(16, 16)) + Vector2(0, 0), WIRE_COLOURS[signal_exposer.connections.size() % WIRE_COLOURS.size()], false, false, true)
	var idx := 0
	for x in signal_exposer.connections:
		var target_position = to_local(x[1] * 16)
		var target_node = signal_exposer.get_node_from_tile(x[0], x[1])
		if is_instance_valid(target_node):
			draw_square_line(Vector2.ZERO, target_position + Vector2(8, 8), WIRE_COLOURS[idx % (WIRE_COLOURS.size())], not signal_exposer.turned_on, true)
		idx += 1

func draw_square_line(from := Vector2.ZERO, to := Vector2.ZERO, colour := Color.RED, dashed := false, offset := false, connecting := false) -> void:
	var dist_x = abs(from.x - to.x)
	var dist_y = abs(from.y - to.y)
	var line_function = draw_line
	if dashed:
		line_function = draw_dashed_line
	
	if (dist_x == 0 || dist_y == 0) || (dist_x == dist_y):
		if dist_x > 16 || dist_y > 16:
			from += (to - from).normalized() * 8
			if offset:
				to += (from - to).normalized() * 8
		var width = 1
		if dashed and dist_x == dist_y:
			width = 2
		line_function.call(from, to, colour, width)
		draw_arrow_head(from, to, colour, false, connecting)
	elif dist_x < dist_y:
		var first_point = Vector2(from.x, to.y)
		from += (first_point - from).normalized() * 8
		line_function.call(from, first_point, colour, 1)
		if offset:
			to += (first_point - to).normalized() * 9
		line_function.call(first_point, to, colour, 1)
		draw_arrow_head(first_point, to, colour, false, connecting)
	elif dist_x > dist_y:
		var first_point = Vector2(to.x, from.y)
		from += (first_point - from).normalized() * 8
		line_function.call(from, first_point, colour, 1)
		if offset:
			to += (first_point - to).normalized() * 8
		line_function.call(first_point, to, colour, 1)
		draw_arrow_head(first_point, to, colour, false, connecting)

func draw_arrow_head(from := Vector2.ZERO, point := Vector2.ZERO, color := Color.RED, offset := false, connecting := false) -> void:
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
