@tool
extends CollisionShape2D

@export var offset := Vector2.ZERO
@export var link: CollisionPolygon2D
@export var hitbox := Vector3.ONE

var crouching := false

func _physics_process(_delta: float) -> void:
	scale = Vector2(hitbox.x, hitbox.y)
	if crouching and get_meta("scalable", true): scale.y *= hitbox.z
	update()

func update() -> void:
	var height_to_use = shape.size.y
	if link != null:
		height_to_use *= link.scale.y * link.scale.y
	if get_meta("scalable", true):
		position.y = -height_to_use / 2 * scale.y - offset.y
