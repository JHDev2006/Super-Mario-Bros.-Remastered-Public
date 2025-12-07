class_name TrackRider
extends Node2D

@export var attached_entity: Node2D = null

@export_range(1, 8, 1) var speed := 2
@export_enum("Forward", "Backward") var direction := 0

var velocity := Vector2.ZERO
var last_position := Vector2.ZERO
var direction_vector := Vector2i.ZERO

var current_track: Track = null
var track_idx := -1
var can_attach := true
var travelling_on_rail := false

func _ready() -> void:
	start()
	await get_tree().physics_frame
	if attached_entity != null:
		attach_to_joint(attached_entity)

func start() -> void:
	current_track = null
	track_idx = -1

func check_for_entities() -> void:
	for i in $Hitbox.get_overlapping_bodies():
		#print(i)
		if i.has_node("TrackJoint"):
			attach_to_joint(i)
			return
	for i in $Hitbox.get_overlapping_areas():
		#print(i)
		if i.owner.has_node("TrackJoint") and !i.owner.get_node("TrackJoint").exclude_areas.has(i):
			attach_to_joint(i.owner)
			return

func _physics_process(delta: float) -> void:
	if attached_entity == null:
		check_for_entities()
		return
	if travelling_on_rail == false:
		velocity.y += 10
		global_position += velocity * delta
		check_for_rail()
	last_position = global_position

func attach_to_joint(node: Node2D) -> void:
	var joint = node.get_node("TrackJoint")
	joint.is_attached = true
	if joint.movement_node != null:
		joint.movement_node.active = false
		joint.attached.emit()
	elif joint.disable_physics:
		node.set_physics_process(false)
	joint.rider = self
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	node.reparent($Joint, false)
	node.position = joint.offset
	attached_entity = node

func check_for_rail() -> void:
	if travelling_on_rail == false and can_attach:
		for i in $Hitbox.get_overlapping_areas():
			if i.get_parent() is TrackPiece and i.get_parent().owner != current_track:
				var piece: TrackPiece = i.get_parent()
				if piece.owner.length <= 0:
					continue
				global_position = piece.global_position
				travelling_on_rail = true
				current_track = piece.owner
				track_idx = piece.idx
				if track_idx >= current_track.path.size():
					direction = 1
				if direction == 1:
					track_idx -= 1
				track_idx = clamp(track_idx, 0, current_track.path.size() - 1)
	if travelling_on_rail:
		direction_vector = current_track.path[track_idx] * [1, -1][direction]
		if current_track != null:
			move_tween(Vector2(direction_vector))

func move_tween(new_direction := Vector2.ZERO) -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_position + (new_direction * 16), float(1.0 if new_direction.is_normalized() else 1.414) / (speed * 2))
	await tween.finished
	track_idx += [1, -1][direction]


	if track_idx >= current_track.length and direction == 0:
		track_idx = current_track.length - 1
		if current_track.end_point == 0:
			direction = 1
		else:
			detach_from_rail()
			return
	if track_idx < 0 and direction == 1:
		track_idx = 0
		if current_track.start_point == 0:
			direction = 0
		else:
			detach_from_rail()
			return
	check_for_rail()

func detach_from_rail() -> void:
	can_attach = false
	travelling_on_rail = false
	track_idx = -1
	velocity = direction_vector * speed * 48
	await get_tree().create_timer(0.1, false).timeout
	can_attach = true
