extends Node2D

@export_range(1, 16) var size_x := 1
@export_range(1, 16) var size_y := 1

signal object_entered
signal object_exited

@export_enum("Player", "Enemy", "Object") var type := 0

@export var detect_items := true
@export var detect_shells := true
@export var detect_blocks := true
@export var detect_projectiles := true
@export var detect_physics_objs := true

var object_in_area := false

func _physics_process(_delta: float) -> void:
	$Hitbox.scale = Vector2(size_x, size_y)
	run_check()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-size_x / 2.0, -size_y / 2.0) * 16, Vector2(size_x, size_y) * 16), Color.WHITE, false, 1.0)

func run_check() -> void:
	var save = object_in_area
	object_in_area = false
	if type != 2:
		for i in $Hitbox.get_overlapping_areas():
			if i.owner == null:
				continue
			var node_layer = get_meta("layer", -1)
			if node_layer != i.owner.get_meta("layer", -2):
				continue
			var node_owner = i.owner
			if node_owner is TrackRider:
				node_owner = node_owner.attached_entity
			if node_owner is Enemy and type == 1:
				object_in_area = true
				break
			if node_owner is Player and type == 0:
				object_in_area = true
				break
	else:
		for i in $Hitbox.get_overlapping_areas():
			var node_owner = i.owner
			if node_owner is Shell and detect_shells:
				object_in_area = true
				break
			if (node_owner.has_signal("collected") or node_owner is PowerUpItem) and detect_items:
				object_in_area = true
				break
			if node_owner is Projectile and detect_projectiles:
				object_in_area = true
				break
		for i in $Hitbox.get_overlapping_bodies():
			if i is Block and detect_blocks:
				object_in_area = true
				break
			if (i.has_node("BasicStaticMovement") or i is Crate) and detect_physics_objs:
				object_in_area = true
				break
	print(object_in_area)
	if object_in_area and not save:
		object_entered.emit()
	elif not object_in_area and save:
		object_exited.emit()
