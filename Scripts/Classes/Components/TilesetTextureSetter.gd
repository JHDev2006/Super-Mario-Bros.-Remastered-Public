class_name TilesetTextureSetter
extends Node

@export var tile_map: TileMapLayer
@export var texture: Texture = null:
	set(value):
		texture = value
		texture_changed.emit()

signal texture_changed

@export var atlas_id := 0

func _ready() -> void:
	update()
	texture_changed.connect(update)

func update() -> void:
	var source = tile_map.tile_set.get_source(atlas_id)
	if source != null:
		source.texture = texture
