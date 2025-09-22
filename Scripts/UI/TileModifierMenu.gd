extends PanelContainer

var editing_node: Node = null

var properties := []

var override_scenes := {}

const VALUES := {
	TYPE_BOOL: preload("uid://diqn7e5hqpbsk"),
	"PackedScene": preload("uid://clfxxcxk3fobh"),
	TYPE_INT: preload("uid://4pi0tdru3c4v")
}

var active := false

signal closed
signal open_scene_ref_tile_menu(scene_ref: TilePropertySceneRef)
signal edit_track_path(track_path: TilePropertyTrackPath)

var can_exit := true:
	set(value):
		can_exit = value
		pass


func _process(_delta: float) -> void:
	if active and (Input.is_action_just_pressed("ui_back") or Input.is_action_just_pressed("editor_open_menu")):
		print(can_exit)
		if can_exit:
			close()
		else:
			pass

func open() -> void:
	active = true
	size = Vector2.ZERO
	add_properties()
	show()
	editing_node.tree_exiting.connect(close)


func add_properties() -> void:
	for i in properties:
		var property: TilePropertyContainer = null
		if override_scenes.has(i.name):
			property = override_scenes[i.name].instantiate()
		if i.type == TYPE_STRING:
			property = preload("uid://l0lulnbn7v6b").instantiate()
			property.editing_start.connect(set_can_exit.bind(false))
			property.editing_finished.connect(set_can_exit.bind(true))
		if i.hint_string == "PackedScene":
			property = preload("uid://clfxxcxk3fobh").instantiate()
		if i.hint == PROPERTY_HINT_ENUM:
			property = preload("uid://87lcnsa0epi1").instantiate()
			var values := {}
			var idx := 0
			for x in i.hint_string.split(","):
				property.values.set(idx, x)
				idx += 1
		elif (i.type == TYPE_INT or i.type == TYPE_FLOAT) and i.hint_string.contains(","):
			if override_scenes.has(i.name):
				property = override_scenes[i.name].instantiate()
			else: property = preload("uid://4pi0tdru3c4v").instantiate()
			var values = i.hint_string.split(",")
			property.min_value = float(values[0])
			property.max_value = float(values[1])
			if values.size() >= 3:
				property.property_step = float(values[2])
		elif i.type == TYPE_BOOL:
			property = preload("uid://diqn7e5hqpbsk").instantiate()
		
		
		if property != null:
			property.exit_changed.connect(set_can_exit)
			property.tile_property_name = i["name"]
			%Container.add_child(property)
			property.owner = self
			property.set_starting_value(editing_node.get(property.tile_property_name))
			property.value_changed.connect(value_changed)
			property.editing_node = editing_node
			if property is TilePropertySceneRef:
				property.open_tile_menu.connect(open_scene_ref)
	await get_tree().physics_frame
	$Container.update_minimum_size()
	update_minimum_size()

func set_can_exit(new_value := false) -> void:
	print(new_value)
	if new_value:
		pass
	can_exit = new_value

func open_scene_ref(scene_ref: TilePropertySceneRef) -> void:
	open_scene_ref_tile_menu.emit(scene_ref)
	can_exit = false

func value_changed(property, new_value) -> void:
	can_exit = true
	editing_node.set(property.tile_property_name, new_value)

func close() -> void:
	hide()
	active = false
	await get_tree().create_timer(0.1).timeout
	closed.emit()
	for i in %Container.get_children():
		i.queue_free()
	
