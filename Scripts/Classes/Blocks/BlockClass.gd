@icon("res://Assets/Sprites/Editor/Block.svg")
class_name Block
extends AnimatableBody2D
signal player_block_hit(player: Player)
signal shell_block_hit(shell: Shell)

@export var visuals: Node = null
const EMPTY_BLOCK = ("res://Scenes/Prefabs/Blocks/EmptyBlock.tscn")
@export var item: PackedScene = null:
	set(value):
		item = value
		item_changed.emit()
@export var destructable := true
@export var destruction_particle_scene: PackedScene = null
@export_range(1, 99) var item_amount := 1
@export var combo_meter_amount := 25
@export var mushroom_if_small := false
const SUPER_MUSHROOM = ("res://Scenes/Prefabs/Entities/Items/SuperMushroom.tscn")
var can_hit := true
var bouncing := false

const NO_SFX_ITEMS := ["res://Scenes/Prefabs/Entities/Items/SpinningRedCoin.tscn","res://Scenes/Prefabs/Entities/Items/SpinningCoin.tscn", "res://Scenes/Prefabs/Entities/Items/Vine.tscn" ]

@export var start_z := -1
signal item_changed
signal block_emptied
signal block_destroyed

func _enter_tree() -> void:
	z_index = start_z
	sync_to_physics = false
	if item != null:
		if item.resource_path.contains(Global.current_level.scene_file_path):
			Global.log_error("ITEM SCENE IS NULL! BLOCK NAME: " + str(name) + " PLEASE REPORT!")

func dispense_item() -> void:
	if can_hit == false:
		return
	can_hit = false
	await get_tree().create_timer(0.1, false).timeout
	DiscoLevel.combo_meter += combo_meter_amount
	var item_to_dispense = player_mushroom_check(get_tree().get_first_node_in_group("Players"))
	var node = item_to_dispense.instantiate()
	if node is PowerUpItem or node.has_meta("is_item"):
		for i in get_tree().get_nodes_in_group("Players"):
			node.position = position + Vector2(0, -1)
			node.hide()
			add_sibling(node)
			if node is PowerUpItem:
				if Global.connected_players > 1:
					AudioManager.play_sfx("item_appear", global_position)
					node.player_multiplayer_launch_spawn(i)
				else:
					node.block_dispense_tween()
	else:
		if item.resource_path == "res://Scenes/Prefabs/Entities/Items/SpinningRedCoin.tscn":
			if has_meta("r_coin_id"):
				node.id = get_meta("r_coin_id", 0)
		var parent = get_parent()
		node.global_position = global_position + Vector2(0, -8) + node.get_meta("block_spawn_offset", Vector2.ZERO)
		if get_parent().get_parent() is TrackRider:
			parent = get_parent().get_parent().get_parent()
		parent.add_child(node)
		parent.move_child(node, get_index() - 1)
		print("FUCK: " + str(item.resource_path))
		if NO_SFX_ITEMS.has(item.resource_path) == false:
			AudioManager.play_sfx("item_appear", global_position)
			node.set("velocity", Vector2(0, node.get_meta("block_launch_velocity", -150)))
	can_hit = true
	item_amount -= 1
	if item_amount == 1:
		if has_meta("red_coin") == true:
			item = load("res://Scenes/Prefabs/Entities/Items/SpinningRedCoin.tscn")
	if item_amount <= 0:
		spawn_empty_block()

func player_mushroom_check(player: Player = null) -> PackedScene:
	if player.power_state.hitbox_size == "Small" and mushroom_if_small:
		return load(SUPER_MUSHROOM)
	return item

func spawn_empty_block() -> void:
	var block = load(EMPTY_BLOCK).instantiate()
	block.position = position
	add_sibling(block)
	if get_parent().get_parent() is TrackRider:
		get_parent().get_parent().attached_entity = block
	block_emptied.emit()
	queue_free()

func destroy() -> void:
	block_destroyed.emit()
	DiscoLevel.combo_meter += combo_meter_amount
	AudioManager.play_sfx("block_break", global_position)
	var particles = destruction_particle_scene.instantiate()
	particles.global_position = global_position
	add_sibling(particles)
	queue_free()
