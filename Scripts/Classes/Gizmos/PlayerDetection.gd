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

var can_detect := false

func _ready() -> void:
	can_detect = false
	for i in 9:
		await get_tree().physics_frame ## I dont know why. i dont WANT to know why, but for some reason we gotta wait like 10 frames before actually detecting shit, otherwise stuff thats instantly placed in side (players specifically), cause it to fire too quickly, or something, fuck my stupid chud life.
	can_detect = true

func _physics_process(_delta: float) -> void:
	$Hitbox.scale = Vector2(size_x, size_y)
	if can_detect:
		run_check()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-size_x / 2.0, -size_y / 2.0) * 16, Vector2(size_x, size_y) * 16), Color.WHITE, false, 1.0)

func run_check() -> void:
	if get_tree().paused or is_inside_tree() == false or Global.level_editor_is_editing():
		return
	var save = object_in_area
	object_in_area = false
	if type != 2:
		for i in $Hitbox.get_overlapping_areas():
			var node_layer = get_meta("layer", -1)
			var node_owner = i.owner
			if is_instance_valid(node_owner) == false:
				continue
			if node_owner is Player and type == 0:
				object_in_area = true
				break
			if node_layer != node_owner.get_meta("layer", -2):
				continue
			if node_owner is TrackRider:
				node_owner = node_owner.attached_entity
			if node_owner is Enemy and type == 1:
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
	if object_in_area and not save:
		object_entered.emit()
	elif not object_in_area and save:
		object_exited.emit()

func turn_on() -> void:
	object_entered.emit()

func turn_off() -> void:
	object_exited.emit()
