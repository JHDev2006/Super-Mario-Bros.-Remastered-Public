class_name TilePlacer
extends Node2D

@export var tile_to_place = null
@export var show_smoke := true
const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

var spawned := false

func place_tile() -> void:
	if spawned:
		return
	spawned = true
	var tileset: TileMapLayer = null
	var tile_position = Vector2i(((global_position - Vector2(8, 8)).snapped(Vector2(16, 16))) / 16)
	if Global.level_editor != null:
		tileset = Global.level_editor.tile_layer_nodes[get_meta("layer", 0)]
	else:
		tileset = Global.current_level.get_node("TileLayer" + str(get_meta("layer", 0) + 1))
	if tile_to_place is int:
		BetterTerrain.set_cell(tileset, tile_position, tile_to_place)
		BetterTerrain.update_terrain_cell(tileset, tile_position, true)
	elif tile_to_place is Array:
		tileset.set_cell(tile_position, tile_to_place[0], tile_to_place[1])
	elif tile_to_place is PackedScene:
		var node = tile_to_place.instantiate()
		node.set_meta("no_persist", true)
		node.set_meta("layer", get_meta("layer", -1))
		node.global_position = (Vector2(tile_position) * 16) + Vector2(8, 8) + tile_to_place.get_meta("offset", Vector2.ZERO)
		if $TrackJoint.is_attached:
			get_parent().owner.add_sibling(node)
		else:
			add_sibling(node)
	if show_smoke:
		summon_smoke()

func _physics_process(delta: float) -> void:
	spawned = false

func summon_smoke() -> void:
	var node = SMOKE_PARTICLE.instantiate()
	node.global_position = global_position + Vector2(0, 8)
	if $TrackJoint.is_attached:
		get_parent().owner.add_sibling(node)
	else:
		add_sibling(node)
