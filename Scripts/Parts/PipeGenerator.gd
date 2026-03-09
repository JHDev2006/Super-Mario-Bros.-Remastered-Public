extends Node2D

@export var item: PackedScene = null

var item_amount := 0

@export_enum("Up", "Down", "Left", "Right") var direction := 0 

func start() -> void:
	if $SignalExposer.total_inputs <= 0:
		$Timer.start()
	if Global.level_editor != null:
		if Global.level_editor.gizmos_visible:
			return
	hide()

func _physics_process(_delta: float) -> void:
	$Check.target_position = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][direction] * 16
	$Check.position = $Check.target_position.normalized()

func on_timeout() -> void:
	if (item == null or item_amount >= 3 or $Check.is_colliding()) and $SignalExposer.total_inputs <= 0: 
		return
	var direction_vector = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT][direction]
	var node = item.instantiate()
	node.set_meta("block_item", true)
	node.global_position = global_position + (direction_vector * 16)
	if direction_vector.x != 0:
		node.global_position.y += 12
	node.hide()
	add_sibling(node)
	item_amount += 1
	node.set_process(false)
	node.set_physics_process(false)
	node.reset_physics_interpolation()
	node.set_meta("no_persist", true)
	var z_old = node.z_index
	node.z_index = -10
	node.tree_exiting.connect(item_deleted)
	await get_tree().process_frame
	if is_instance_valid(node) == false:
		return
	node.show()
	node.reset_physics_interpolation()
	await tween_animation(node, -direction_vector)
	if is_instance_valid(node):
		node.velocity = Vector2.ZERO
		node.set_process(true)
		node.z_index = z_old
		node.set_physics_process(true)
		if direction >= 2:
			node.set("direction", [0, 0, -1, 1][direction])

func item_deleted() -> void:
	item_amount -= 1

func get_direction_string(direction_vector := Vector2.UP) -> String:
	match direction_vector:
		Vector2.UP:
			return "Up"
		Vector2.DOWN:
			return "Down"
		Vector2.LEFT:
			return "Left"
		Vector2.RIGHT:
			return "Right"
		_:
			return ""

func tween_animation(node: Node = null, anim_direction := Vector2.UP) -> void:
	var final_position = global_position
	if anim_direction.x != 0:
		final_position.x += 8 * (anim_direction.x)
		final_position.y += 12
	if anim_direction.y > 0:
		final_position.y += 16
	await create_tween().tween_property(node, "global_position", final_position, 0.5).finished
	return
