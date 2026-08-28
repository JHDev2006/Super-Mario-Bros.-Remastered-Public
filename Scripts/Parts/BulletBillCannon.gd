extends Node2D

@export var item: PackedScene = preload("res://Scenes/Prefabs/Entities/Enemies/BulletBill.tscn")

var timer := 15

const MAX_TIME := 15
const HARD_TIME := 7

func _physics_process(_delta: float) -> void:
	if $SignalExposer.total_inputs > 0:
		return
	if randi_range(0, 8) == 8:
		timer -= 1
	print(timer)
	if timer <= 0:
		if Global.second_quest:
			timer = HARD_TIME
		else:
			timer = MAX_TIME
		fire()

func fire() -> void:
	if BulletBill.amount >= 3 or $PlayerDetect.get_overlapping_areas().any(func(area: Area2D): return area.owner is Player) or is_inside_tree() == false:
		if $SignalExposer.total_inputs <= 0:
			return
	var player: Player = get_tree().get_first_node_in_group("Players")
	var direction = sign(player.global_position.x - global_position.x)
	$BlockCheck.scale.x = direction
	$BlockCheck/RayCast2D.force_raycast_update()
	if $BlockCheck/RayCast2D.is_colliding():
		return
	var node = item.instantiate()
	node.global_position = global_position + Vector2(0, 8)
	node.set("direction", direction)
	node.set_meta("no_persist", true)
	if node is CharacterBody2D:
		node.position.x += 8 * direction
	node.set("velocity", Vector2(100 * direction, 0))
	if node is not BulletBill:
		AudioManager.play_sfx("cannon", global_position)
	else:
		BulletBill.amount += 1
		node.tree_exiting.connect(func(): BulletBill.amount -= 1)
		node.cannon = true
	add_sibling(node)

func flag_die() -> void:
	queue_free()
