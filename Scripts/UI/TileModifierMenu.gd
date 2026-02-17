extends PanelContainer

var editing_node: Node = null

var properties := []
var has_connection := false

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
signal begin_connect(node: Node, signal_name: String)

var property_nodes := []
var signal_nodes := []

var signal_to_connect := ""

signal left_click_release

var can_exit := true:
	set(value):
		can_exit = value
		pass


func _process(_delta: float) -> void:
	if Input.is_action_just_released("mb_left"): left_click_release.emit()
	if active and (Input.is_action_just_pressed("ui_back") or Input.is_action_just_pressed("editor_open_menu")):
		if can_exit:
			close()
		else:
			pass

func open() -> void:
	active = true
	clear_nodes()
	%Properties.visible = properties.size() > 0
	%SignalDisplay.visible = has_connection
	%SignalDisplay.node = editing_node
	add_properties()
	size = Vector2.ZERO
	update_minimum_size()
	show()
	editing_node.tree_exiting.connect(close)
	

func clear_nodes() -> void:
	for i in property_nodes:
		i.queue_free()
	property_nodes.clear()
	update_minimum_size()

func add_properties() -> void:
	for i in properties:
		var property: TilePropertyContainer = null
		if override_scenes.has(i.name):
			property = override_scenes[i.name].instantiate()
		if i.type == TYPE_STRING:
			property = preload("uid://l0lulnbn7v6b").instantiate()
			property.editing_start.connect(set_can_exit.bind(false))
			property.editing_finished.connect(set_can_exit.bind(true))
		elif i.hint_string == "PackedScene":
			property = preload("uid://clfxxcxk3fobh").instantiate()
		elif i.hint == PROPERTY_HINT_ENUM:
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
		elif i.type == TYPE_COLOR:
			property = preload("uid://o3ya33lcbn7y").instantiate()
		
		if property != null:
			property.exit_changed.connect(set_can_exit)
			property.tile_property_name = i["name"]
			%Properties.add_child(property)
			property_nodes.append(property)
			property.owner = self
			property.set_starting_value(editing_node.get(property.tile_property_name))
			property.value_changed.connect(value_changed)
			property.editing_node = editing_node
			if property is TilePropertySceneRef:
				property.open_tile_menu.connect(open_scene_ref)
	await get_tree().physics_frame
	%Properties.update_minimum_size()
	update_minimum_size()

func set_can_exit(new_value := false) -> void:
	print(new_value)
	if new_value:
		pass
	can_exit = new_value

func open_scene_ref(scene_ref: TilePropertySceneRef) -> void:
	open_scene_ref_tile_menu.emit(scene_ref)
	can_exit = false

func begin_signal_connection() -> void:
	begin_connect.emit(editing_node)
	can_exit = false
	editing_node.get_node("SignalExposer").begin_connecting()
	hide()
	Global.level_editor.start_signal_connection(editing_node, editing_node.get_node("SignalExposer").connect_type)

func cancel_connection() -> void:
	Global.level_editor.current_state = LevelEditor.EditorState.MODIFYING_TILE
	editing_node.get_node("SignalExposer").stop_connection()
	can_exit = true
	show()
	if Global.level_editor.quick_connecting:
		Global.level_editor.quick_connecting = false
		close()
	Global.level_editor.quick_connecting = false

func value_changed(property, new_value) -> void:
	can_exit = true
	var old_value = editing_node.get(property.tile_property_name)
	var undo_redo = Global.level_editor.undo_redo
	undo_redo.create_action("Edited Node")
	undo_redo.add_do_method(set_value.bind(editing_node, property.tile_property_name, new_value))
	undo_redo.add_undo_method(set_value.bind(editing_node, property.tile_property_name, old_value))
	undo_redo.commit_action(true)

func set_value(node: Node, value_name := "", value = null) -> void:
	if is_instance_valid(node) == false:
		return
	node.set(value_name, value)
	do_animation(node)
	node.get_node("EditorPropertyExposer").modifier_applied.emit()

func close() -> void:
	active = false
	clear_nodes()
	editing_node.tree_exiting.disconnect(close)
	properties.clear()
	closed.emit()
	if get_tree() == null: return
	if Global.level_editor.quick_connecting:
		await left_click_release
	else:
		await get_tree().create_timer(0.03).timeout
	Global.level_editor.current_inspect_tile = null
	Global.level_editor.current_state = LevelEditor.EditorState.IDLE
	hide()

var old_scale = Vector2.ONE

func connect_signal(new_node: Node) -> void:
	editing_node.get_node("SignalExposer").connect_to_node([Global.level_editor.current_layer, new_node.get_meta("tile_position")])
	can_exit = true
	print("Connected!")
	if Global.level_editor.quick_connecting:
		close()
	else:
		show()
	Global.level_editor.quick_connecting = false

func do_animation(node: Node) -> void:
	if node.get_node("EditorPropertyExposer").animate_change == false:
		return
	if node is Node2D:
		if node.scale != old_scale:
			node.scale = old_scale
		old_scale = node.scale
		node.scale += Vector2(0.5, 0.5)
		create_tween().set_trans(Tween.TRANS_CUBIC).tween_property(node, "scale", old_scale, 0.1)
		var sparkle = preload("uid://btuv0dcfc8u7x").instantiate()
		sparkle.global_position = node.get_meta("tile_position") * 16
		print([sparkle.global_position, node.global_position])
		add_sibling(sparkle)
		sparkle.animation_finished.connect(sparkle.queue_free)
