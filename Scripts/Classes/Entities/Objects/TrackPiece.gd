class_name TrackPiece
extends Node2D

var editing := false

var mouse_in_areas := 0

var pieces := []

var idx := 0

var starting_direction := Vector2i.ZERO
var connecting_direction := Vector2i.UP

const SPRITE_COORDS := {
	Vector2i.ZERO: Vector2(112, 16),
	Vector2i.RIGHT: Vector2(0, 0),
	Vector2i.LEFT: Vector2(16, 0),
	Vector2i.DOWN: Vector2(32, 0),
	Vector2i.UP: Vector2(48, 0),
	Vector2i(1, 1): Vector2(64, 0),
	Vector2i(-1, 1): Vector2(80, 0),
	Vector2i(-1, -1): Vector2(96, 0),
	Vector2i(1, -1): Vector2(112, 0),
}

const TRACKS = preload("uid://50hm4xgnw8ks")
const INVISIBLE_TRACKS = preload("uid://barofu3g8jf00")

func _process(_delta: float) -> void:
	$PlacePreview.visible = editing
	$Start.region_rect.position = SPRITE_COORDS[starting_direction]
	$Connect.region_rect.position = SPRITE_COORDS[connecting_direction]
	$End.visible = idx == owner.length
	$End.frame = int(owner.end_point == 0)
	if Input.is_action_pressed("mb_left") and editing and mouse_in_areas > 0:
		for i in 8:
			if is_mouse_in_area(i):
				if Track.DIRECTIONS[i] == starting_direction:
					owner.remove_last_piece()
				else:
					owner.add_piece(Track.DIRECTIONS[i])

func update_direction_textures() -> void:
	var texture = TRACKS
	if owner.invisible:
		texture = INVISIBLE_TRACKS
	for i in $PlacePreview.get_children():
		i.frame = int(Track.DIRECTIONS[i.get_index()] == starting_direction)
	for i in [$Start, $Connect, $End]:
		i.texture = texture
	$DirectionArrow.global_rotation = Vector2(connecting_direction).angle()

func on_mouse_entered(area_idx := 0) -> void:
	mouse_in_areas |= (1 << area_idx)

func on_mouse_exited(area_idx := 0) -> void:
	mouse_in_areas &= ~(1 << area_idx)

func is_mouse_in_area(area_idx := 0) -> bool:
	return mouse_in_areas & (1 << area_idx) != 0
