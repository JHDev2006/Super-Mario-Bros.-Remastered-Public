@tool
class_name LevelBG
extends Node2D

@export_enum("Day", "Night", "Auto") var time_of_day := 0:
	set(value):
		time_of_day = value
		update_visuals()

@export_enum("Hills", "Bush", "None", "Auto") var primary_layer = 0:
	set(value):
		primary_layer = value
		update_visuals()

@export_enum("None", "Mushrooms", "Trees") var second_layer = 0:
	set(value):
		second_layer = value
		update_visuals()

@export_enum("Behind", "In Front") var second_layer_order = 0:
	set(value):
		second_layer_order = value
		update_visuals()

@export var second_layer_offset := Vector2.ZERO:
	set(value):
		second_layer_offset = value
		update_visuals()

@export_enum("None", "Snow", "Leaves", "Ember", "Auto") var particles := 0:
	set(value):
		particles = value
		update_visuals()

@export_enum("None", "Water", "Lava", "Poison") var liquid_layer := 0:
	set(value):
		liquid_layer = value
		update_visuals()

@export var liquid_offset := 8:
	set(value):
		liquid_offset = value
		update_visuals()

@export var overlay_clouds := false:
	set(value):
		overlay_clouds = value
		update_visuals()

func set_value(value := 0, value_name := "") -> void:
	set(value_name, value)

var is_auto := false

var combo_progress := 0.0

var visual_progress := 0.0

var can_tree_tint := true

var top_edge_enabled := true

var can_mushroom_tint := true

var sky_scroll_speed := -4.0

const disco_sfx_threshold := [0.05, 0.5, 0.8]

func set_second_y_offset(value := 0.0) -> void:
	second_layer_offset.y = -value

func _ready() -> void:
	if particles == 4:
		if ["", "Snow", "Jungle", "Castle"].has(Global.level_theme):
			particles = ["", "Snow", "Jungle", "Castle"].find(Global.level_theme)
	await get_parent().ready
	if Engine.is_editor_hint() == false:
		if time_of_day == 2:
			is_auto = true
			time_of_day = ["Day", "Night"].find(Global.theme_time)
		if primary_layer == 3:
			if ["Jungle", "Autumn"].has(Global.level_theme):
				if Global.world_num > 4 and Global.world_num <= 8 or time_of_day == 1:
					primary_layer = 1
				else:
					primary_layer = 0
			else:
				primary_layer = 0
		get_parent().move_child(self, 0)
		Global.level_theme_changed.connect(update_visuals)
		update_visuals()
	handle_disco_visuals(1)

func _physics_process(delta: float) -> void:
	handle_disco_visuals(delta)
	if Engine.is_editor_hint() == false:
		if Global.current_level != null:
			var frame = $TopEdge/Sprite.sprite_frames.get_frame_texture($TopEdge/Sprite.animation, 0)
			$TopEdge/Sprite.position.y = Global.current_level.vertical_height - 32
			$TopEdge.repeat_size.x = frame.get_width()
			$TopEdge.repeat_times = (ceil(get_viewport_rect().size.x / $TopEdge.repeat_size.x) + 1) * 2
		var repeat_times = (ceil(get_viewport_rect().size.x / 512) + 1) * 2
		for i in [$SkyLayer, $PrimaryLayer, $DiscoBits/Rainbow, $DiscoBits/SpotLights, $SecondaryLayer, $OverlayLayer/CloudLayer, $OverlayLayer/Particles, $LiquidLayer, $Parallax2D, $FGLayer]:
			i.repeat_times = repeat_times

func handle_disco_visuals(delta: float) -> void:
	if Engine.is_editor_hint() or Global.current_level == null:
		return
	$DiscoBits.visible = DiscoLevel.in_disco_level
	$Parallax2D.visible = DiscoLevel.in_disco_level
	if DiscoLevel.in_disco_level == false:
		return
	if is_nan(combo_progress) or is_nan(visual_progress):
		combo_progress = 0
		visual_progress = 0
	combo_progress = inverse_lerp(0.0, DiscoLevel.max_combo_amount, DiscoLevel.combo_amount)
	combo_progress = clamp(combo_progress, 0, 1)
	if get_tree().get_first_node_in_group("Players") != null:
		if get_tree().get_first_node_in_group("Players").is_invincible:
			combo_progress = 1
	visual_progress = (lerp(visual_progress, combo_progress, delta))
	$DiscoBits.modulate.a = lerpf(0, 0.9, visual_progress)
	$DiscoBits/Rainbow/Joint.position.y = lerpf(256, 0, visual_progress)
	handle_toads(delta, visual_progress)

func handle_toads(delta: float, toad_combo_progress := 0.0) -> void:
	if is_equal_approx(toad_combo_progress, 0) or DiscoLevel.combo_amount == 0:
		toad_combo_progress = 0
	var idx := 0.0
	for i in $Parallax2D/Toads.get_children():
		i.visible = DiscoLevel.in_disco_level
		var target_y = 64
		if (idx / $Parallax2D/Toads.get_child_count()) < toad_combo_progress:
			target_y = -8
		i.position.y = lerpf(i.position.y, target_y, delta * 5)
		idx += 1
		if is_inside_tree() == false:
			return
		await get_tree().physics_frame
	
	idx = 0
	for i in [$DiscoBits/Cheer1, $DiscoBits/Cheer2, $DiscoBits/Cheer3]:
		if toad_combo_progress >= disco_sfx_threshold[idx]:
			if i.is_playing() == false:
				i.play()
			i.stream_paused = (Global.game_paused)
		else:
			i.stop()
		idx += 1

var auto_layers := false

func update_visuals() -> void:
	if is_inside_tree() == false:
		return
	$PrimaryLayer.visible = primary_layer != 3
	$SecondaryLayer.scroll_scale.x = 0.4 if second_layer_order == 0 else 0.6
	var parallax_amount = $SecondaryLayer.scroll_scale.x
	if Engine.is_editor_hint() == false:
		for i in [$SkyLayer, $PrimaryLayer, $SecondaryLayer]:
			var scroll_scale := -1.0
			if Settings.file.visuals.parallax_style == 0:
				scroll_scale = 1
			elif Settings.file.visuals.parallax_style == 1:
				scroll_scale = 0.5
			if scroll_scale != -1:
				i.scroll_scale.x = scroll_scale
		if Settings.file.visuals.parallax_style == 0:
			$FGLayer.scroll_scale.x = 1
	$LiquidLayer.visible = liquid_layer > 0
	$LiquidLayer/Lava.visible = liquid_layer == 2
	$LiquidLayer/Water.visible = liquid_layer == 1
	$LiquidLayer/Poison.visible = liquid_layer == 3
	$LiquidLayer.scroll_offset.y = liquid_offset
	$OverlayLayer/Particles/Snow.visible = particles == 1
	$OverlayLayer/Particles/Leaves.visible = particles == 2
	$OverlayLayer/Particles.visible = Settings.file.visuals.bg_particles == 1
	$OverlayLayer/Particles/LavaEmber.visible = particles == 3
	$SkyLayer.autoscroll.x = sky_scroll_speed
	$PrimaryLayer/Hills.visible = primary_layer == 0
	$PrimaryLayer/Bush.visible = primary_layer == 1
	
	$SecondaryLayer.visible = second_layer > 0
	$SecondaryLayer.scroll_offset = Vector2(80, 64) + second_layer_offset
	if Engine.is_editor_hint() == false and get_viewport().get_camera_2d() != null:
		for i in [$PrimaryLayer, $SecondaryLayer, $SkyLayer]:
			i.screen_offset.x = get_viewport().get_camera_2d().get_screen_center_position().x / i.scroll_scale.x
	$SecondaryLayer/Mushrooms.visible = second_layer == 1
	$SecondaryLayer/Trees.visible = second_layer == 2
	for i in $Parallax2D/Toads.get_children():
		i.offset.y = randf_range(-5, 5)
	$SecondaryLayer/Mushrooms.get_node("Tint").visible = can_mushroom_tint
	$SecondaryLayer/Trees.get_node("Tint").visible = can_tree_tint
	
	if primary_layer != 3:
		var current_primary_layer: AnimatedSprite2D = [$PrimaryLayer/Hills, $PrimaryLayer/Bush, null][primary_layer]
		if current_primary_layer != null:
			$PrimaryLayer.repeat_size = current_primary_layer.sprite_frames.get_frame_texture(current_primary_layer.animation, current_primary_layer.frame).get_size()
			$PrimaryLayer.repeat_size.y = 0

	var current_secondary_layer: AnimatedSprite2D = [null, $SecondaryLayer/Trees, $SecondaryLayer/Mushrooms][second_layer]
	if current_secondary_layer != null:
		$SecondaryLayer.repeat_size = current_secondary_layer.sprite_frames.get_frame_texture(current_secondary_layer.animation, current_secondary_layer.frame).get_size()
		$SecondaryLayer.repeat_size.y = 0
	
	$SkyLayer.repeat_size = $SkyLayer/Sky.sprite_frames.get_frame_texture($SkyLayer/Sky.animation, $SkyLayer/Sky.frame).get_size()
	
	var tree_tint_amount = inverse_lerp(1, 0, parallax_amount)
	var mushroom_tint_amount = tree_tint_amount
	if can_mushroom_tint == false:
		mushroom_tint_amount = 0
	if can_tree_tint == false:
		tree_tint_amount = 0
	
	$SecondaryLayer/Mushrooms.get_node("Tint").modulate.a = mushroom_tint_amount
	$SecondaryLayer/Trees.get_node("Tint").modulate.a = tree_tint_amount
	
	$PrimaryLayer.z_index = int(not bool(second_layer_order))
	$OverlayLayer/CloudLayer.visible = overlay_clouds and Settings.file.visuals.bg_particles == 1
	$TopEdge.visible = ["Underground", "Castle", "GhostHouse", "Bonus"].has(Global.level_theme) and primary_layer == 0 and top_edge_enabled
