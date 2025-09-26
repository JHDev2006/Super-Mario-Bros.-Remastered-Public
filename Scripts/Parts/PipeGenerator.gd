extends Node2D

@export var item: PackedScene = null

var item_amount := 0

@export_enum("Up", "Down", "Left", "Right") var direction := 0 

func _ready() -> void:
	$Timer.start()

func _physics_process(_delta: float) -> void:
	$Check.target_position = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][direction] * 16
	$Check.position = $Check.target_position.normalized()
func on_timeout() -> void:
	if item == null or item_amount >= 3 or $Check.is_colliding(): return
	$AnimationPlayer.stop()
	var node = item.instantiate()
	node.global_position = $Joint.global_position
	node.hide()
	add_sibling(node)
	$Joint.remote_path = node.get_path()
	item_amount += 1
	node.set_process(false)
	node.set_physics_process(false)
	node.reset_physics_interpolation()
	var z_old = node.z_index
	node.z_index = -10
	$AnimationPlayer.play(get_direction_string([Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT][direction]))
	await get_tree().process_frame
	node.show()
	node.reset_physics_interpolation()
	await $AnimationPlayer.animation_finished
	$Joint.remote_path = ""
	if is_instance_valid(node):
		node.velocity = Vector2.ZERO
		node.set_process(true)
		node.z_index = z_old
		node.set_physics_process(true)
		node.tree_exited.connect(func(): item_amount -= 1)

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
