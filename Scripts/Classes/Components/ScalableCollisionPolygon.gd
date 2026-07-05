@tool
extends CollisionPolygon2D

@export var offset := Vector2.ZERO
@export var hitbox := Vector2.ONE

var crouching := false

var sloped_floor_corner := false

func _physics_process(_delta: float) -> void:
	update()

func update() -> void:
	update_polygon()
	position = offset

func update_polygon() -> void:
	# Ok so something happened on Godot 4.7 where polygons can't be updated without setting their whole array now.
	var updated_polygons: Array = polygon.duplicate()
	
	## Bottom Half
	updated_polygons[5].x = -(hitbox.x / 2)
	updated_polygons[6].x = -(hitbox.x / 2) + 2
	updated_polygons[0].x = (hitbox.x / 2)
	updated_polygons[7].x = (hitbox.x / 2) - 2
	
	## Top Half
	updated_polygons[1].x = (hitbox.x / 2)
	updated_polygons[4].x = -(hitbox.x / 2)
	
	updated_polygons[2].x = (hitbox.x / 2) - 3
	updated_polygons[3].x = -(hitbox.x / 2) + 3
	
	var corner_height := 0
	if sloped_floor_corner:
		corner_height = -3
	updated_polygons[5].y = corner_height
	updated_polygons[0].y = corner_height
	
	updated_polygons[2].y = -hitbox.y
	updated_polygons[3].y = -hitbox.y
	updated_polygons[1].y = -hitbox.y + 6
	updated_polygons[4].y = -hitbox.y + 6
	
	polygon = updated_polygons
