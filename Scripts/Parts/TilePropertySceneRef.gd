class_name TilePropertySceneRef
extends TilePropertyContainer

signal open_tile_menu(this)

var scene = null

const replace_scenes := {"res://Scenes/Prefabs/Entities/Items/Coin.tscn": "res://Scenes/Prefabs/Entities/Items/SpinningCoin.tscn"}

func set_starting_value(start_value = null) -> void:
	%SceneName.text = get_scene_path(start_value)

func open_tile_selection_menu() -> void:
	open_tile_menu.emit(self)

func set_scene(selector: EditorTileSelector) -> void:
	if selector.type == 0:
		scene = [selector.source_id, selector.tile_coords]
		%SceneName.text = selector.tile_name
	elif selector.type == 1:
		scene = load(EntityIDMapper.map[selector.entity_id][0])
		var split = EntityIDMapper.map[selector.entity_id][1].split(",")
		var offset = Vector2(int(split[0]), int(split[1]))
		if replace_scenes.has(scene.resource_path):
			scene = load(replace_scenes[scene.resource_path])
		scene.set_meta("offset", offset)
		%SceneName.text = get_scene_path(scene)
	elif selector.type == 2:
		scene = selector.terrain_id
		%SceneName.text = selector.tile_name
	value = scene
	value_changed.emit(self, scene)

func get_scene_path(var_scene = null) -> String:
	if var_scene == null:
		return "Empty"
	elif var_scene is PackedScene:
		return var_scene.resource_path.get_file().replace(".tscn", "").to_snake_case().replace("_", " ")
	else:
		return "Tile"
