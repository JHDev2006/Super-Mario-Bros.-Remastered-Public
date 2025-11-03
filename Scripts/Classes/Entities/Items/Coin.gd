extends Node2D

@export var COIN_SPARKLE: PackedScene = null

@export var spinning_coin_scene: PackedScene = null

var can_spawn_particles := true

signal collected

func area_entered(area: Area2D) -> void:
	if area.owner is Player:
		collect()

func collect() -> void:
	remove_from_group("Coins")
	collected.emit()
	$Hitbox.area_entered.disconnect(area_entered)
	Global.coins += 1
	DiscoLevel.combo_meter += 10
	Global.score += 200
	AudioManager.play_sfx("coin", global_position)
	if can_spawn_particles and Settings.file.visuals.extra_particles == 1:
		summon_particle()
		$Sprite.queue_free()
	else:
		queue_free()
		if get_parent() is TileMapLayer:
			get_parent().erase_cell(get_parent().local_to_map(position))

func summon_block_coin() -> void:
	var node = spinning_coin_scene.instantiate()
	node.global_position = global_position
	add_sibling(node)
	queue_free()
	if get_parent() is TileMapLayer:
		get_parent().erase_cell(get_parent().local_to_map(position))

func summon_particle() -> void:
	var node = COIN_SPARKLE.instantiate()
	node.finished.connect(queue_free)
	add_child(node)
