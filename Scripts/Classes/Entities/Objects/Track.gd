class_name Track
extends Node2D
const TRACK_PIECE = preload("uid://4gxhnql5bjk6")

@export var path := []
var pieces := []
var length := 0

@export_enum("Closed", "Open") var start_point := 0
@export_enum("Closed", "Open") var end_point := 0
@export var invisible := false:
	set(value):
		invisible = value
		update_pieces()

var looping := false

var editing := false

var track_texture: Texture = null
var invis_track_texture: Texture = null

var baked_path: Curve2D = null

var last_direction := Vector2i.ZERO

@export_storage var placed_pieces := false

const DIRECTIONS := [
	Vector2i(-1, -1), # 0
	Vector2i.UP, # 1
	Vector2i(1, -1), # 2
	Vector2i.RIGHT, # 3
	Vector2i(1, 1), # 4
	Vector2i.DOWN, # 5
	Vector2i(-1, 1), # 6
	Vector2i.LEFT # 7
]

var mouse_in_areas := 0

@export var track_pieces_save := []

func _process(_delta: float) -> void:
	$Point.frame = int(start_point == 0)
	$End.frame = int(end_point == 0)
	visible = not (invisible and (Global.level_editor_is_playtesting() or Global.level_editor == null))
	$PlacePreview.visible = editing
	if editing and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		if Global.multibind_action_just_pressed("editor_open_menu") or Global.multibind_action_just_pressed("ui_cancel"):
			editing = false
			Global.level_editor.current_state = LevelEditor.EditorState.IDLE
			update_pieces()

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("mb_left") and editing and mouse_in_areas > 0:
		for i in 8:
			if is_mouse_in_area(i):
				if Track.DIRECTIONS[i] == -last_direction:
					remove_last_piece()
				else:
					add_piece(Track.DIRECTIONS[i])
				break

func _ready() -> void:
	for i in path:
		add_piece(i, false)
	update_pieces()

func update_pieces() -> void:
	var idx := 0
	$PlacePreview.position = Vector2.ZERO
	for i in $Pieces.get_children():
		i.idx = idx
		i.editing = idx >= path.size() and editing
		if idx > 0:
			i.starting_direction = -path[idx - 1]
		else:
			i.starting_direction = Vector2i.ZERO
		if idx <= path.size() - 1:
			i.connecting_direction = path[idx]
		else:
			i.connecting_direction = Vector2i.ZERO
		idx += 1
	if path.is_empty() == false:
		last_direction = path[path.size() - 1]
	else:
		last_direction = Vector2i.ZERO
	idx = 0
	for i in path:
		$PlacePreview.position += Vector2(i * 16)
	for i in $PlacePreview.get_children():
		i.frame = int(last_direction == -DIRECTIONS[idx])
		idx += 1
	track_pieces_save.clear()
	$End.position = $PlacePreview.position
	for i in $Pieces.get_children():
		track_pieces_save.append(i)
	queue_redraw()
	looping = $PlacePreview.position == Vector2.ZERO and length > 0
	$Point.visible = not looping
	$End.visible = not looping
	baked_path = construct_path()

func add_piece(new_direction := Vector2i.ZERO, add_to_arr := true) -> void:
	placed_pieces = true
	var piece = TRACK_PIECE.instantiate()
	var next_position := new_direction * 16
	for i in length:
		next_position += path[i] * 16
	piece.position = next_position
	$Pieces.add_child(piece)
	piece.owner = self
	pieces.append(piece)
	piece.idx = length
	piece.reset_physics_interpolation()
	if add_to_arr:
		path.append(new_direction)
	length += 1
	update_pieces()

func remove_last_piece() -> void:
	looping = false
	$Pieces.get_child($Pieces.get_child_count() - 1).queue_free()
	await get_tree().process_frame
	path.pop_back()
	pieces.pop_back()
	length -= 1
	update_pieces()

func on_mouse_entered(area_idx := 0) -> void:
	mouse_in_areas |= (1 << area_idx)

func on_mouse_exited(area_idx := 0) -> void:
	mouse_in_areas &= ~(1 << area_idx)

func is_mouse_in_area(area_idx := 0) -> bool:
	return mouse_in_areas & (1 << area_idx) != 0

func _draw() -> void:
	var current_position = Vector2(-8, -8)
	var idx := 0
	var texture = track_texture
	if invisible:
		if Global.level_editor_is_playtesting() == false:
			texture = invis_track_texture
		else:
			return
	for i in path:
		i = Vector2(i)
		draw_texture_rect_region(texture, Rect2(current_position, Vector2(16, 16)), Rect2(TrackPiece.SPRITE_COORDS[Vector2i(i)], Vector2(16, 16)))
		if idx > 0:
			var last_pos = -path[idx - 1]
			draw_texture_rect_region(texture, Rect2(current_position, Vector2(16, 16)), Rect2(TrackPiece.SPRITE_COORDS[Vector2i(last_pos)], Vector2(16, 16)))
		idx += 1
		current_position += i * 16
	if path.size() > 0:
		draw_texture_rect_region(texture, Rect2(current_position, Vector2(16, 16)), Rect2(TrackPiece.SPRITE_COORDS[Vector2i(-path[path.size() - 1])], Vector2(16, 16)))

func construct_path() -> Curve2D:
	var curve = Curve2D.new()
	curve.bake_interval = 16
	var point_pos := global_position
	var current_direction = Vector2i.ZERO
	for i in path:
		if i != current_direction:
			current_direction = i
			curve.add_point((point_pos))
		point_pos += Vector2(i) * 16
	curve.add_point(point_pos)
	return curve
