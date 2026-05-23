class_name TrackRider
extends Node2D

@export var attached_entity: Node2D = null

@export_range(1, 8, 1) var speed := 2
@export_enum("Forward", "Backward") var direction := 0

@export var auto_move := true

var velocity := Vector2.ZERO
var last_position := Vector2.ZERO
var direction_vector := Vector2i.ZERO

var current_track: Track = null
var can_attach := true
var travelling_on_rail := false

signal started

var can_move := true

var moving := false

var point_idx := 0.0

@onready var path := Curve2D.new()

func _ready() -> void:
	start()

func start() -> void:
	await get_tree().physics_frame
	if $SignalExposer.total_inputs > 0:
		can_move = false
	current_track = null
	point_idx = 0
	if auto_move == false:
		can_move = false
	if Global.level_editor_is_editing() == false:
		global_position += Vector2.ZERO
	if attached_entity != null:
		attach_to_joint(attached_entity)

func check_for_entities() -> void:
	for i in $Hitbox.get_overlapping_bodies():
		if i.has_node("TrackJoint"):
			attach_to_joint(i)
			return
	for i in $Hitbox.get_overlapping_areas():
		if i.owner.has_node("TrackJoint"):
			attach_to_joint(i.owner)
			return

func _physics_process(delta: float) -> void:
	if attached_entity == null:
		check_for_entities()
		return
	elif travelling_on_rail == false:
		velocity.y += 10
		global_position += velocity * delta
		check_for_rail()
	elif path != null and is_instance_valid(current_track) and can_move:
		handle_moving(delta)

func attach_to_joint(node: Node2D) -> void:
	var joint = node.get_node("TrackJoint")
	joint.is_attached = true
	if joint.movement_node != null:
		joint.movement_node.set("active", false)
		joint.movement_node.set("auto_call", false)
		joint.attached.emit()
	elif joint.disable_physics:
		node.set_physics_process(false)
	if joint.get_parent().has_node("GibSpawner"):
		joint.get_parent().get_node("GibSpawner").global_parent = true
	joint.rider = self
	node.reparent($Joint, false)
	node.position = joint.offset
	attached_entity = node

func handle_moving(delta: float) -> void:
	var point = global_position
	if point_idx >= path.get_baked_length() - (2) and direction == 0:
		if current_track.looping:
			point_idx = 0
		elif current_track.end_point == 0:
			direction = !direction
			bounce()
		else:
			detach_from_rail()
			return
	elif point_idx <= 4 and direction == 1:
		if current_track.looping:
			point_idx = path.get_baked_length()
		elif current_track.start_point == 0:
			direction = !direction
			bounce()
		else:
			detach_from_rail()
			return
	if can_move:
		point_idx += speed * 32 * delta * [1, -1][direction]
	var new_point = path.sample_baked(point_idx)
	velocity = (new_point - point) / delta
	global_position += velocity * delta

func check_for_rail() -> void:
	if travelling_on_rail == false and can_attach:
		for i in $Hitbox.get_overlapping_areas():
			if i.get_parent() is TrackPiece and i.get_parent().owner != current_track:
				var piece: TrackPiece = i.get_parent()
				if piece.owner.length <= 0:
					continue
				global_position = piece.global_position
				travelling_on_rail = true
				attached_entity.get_node("TrackJoint").started_moving.emit()
				current_track = piece.owner
				path = current_track.baked_path
				point_idx = path.get_closest_offset(global_position)
				if velocity.length() > 10:
					var track_direction = (current_track.baked_path.sample_baked(point_idx + (0.01 * [1, -1][direction])) - current_track.baked_path.sample_baked(point_idx)).normalized()
					if velocity.normalized().dot(track_direction) > 0:
						direction = !direction


func bounce() -> void:
	if is_instance_valid(attached_entity) == false:
		return
	var joint = attached_entity.get_node("TrackJoint")
	if joint != null:
		joint.bounced.emit()

func detach_from_rail() -> void:
	can_attach = false
	travelling_on_rail = false
	point_idx = 0
	path = null
	can_attach = true

func start_moving() -> void:
	started.emit()
	can_move = true

func stop_moving() -> void:
	can_move = false

func toggle() -> void:
	can_move = not can_move
	if can_move:
		started.emit()
