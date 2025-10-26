class_name Explosion
extends Enemy

const destructable_tiles := {Vector2i(4, 0): Rect2(32, 160, 16, 16), Vector2i(4, 2): Rect2(48, 160, 16, 16)}
const BLOCK_DESTRUCTION_PARTICLES = preload("uid://cyw7kk1em8h16")

func on_body_entered(body: Node2D) -> void:
	if body is Block:
		if body.destructable: body.destroy()
