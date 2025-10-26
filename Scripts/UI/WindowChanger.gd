extends Node

func window_mode_changed(new_value := 0) -> void:
	match new_value:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Settings.file.video.mode = new_value

func null_function(_fuck_you := 0) -> void:
	pass

func window_size_changed(new_value := 0) -> void:
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if new_value == 1 else Window.CONTENT_SCALE_ASPECT_KEEP
	Settings.file.video.size = new_value

func vsync_changed(new_value := 0) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if new_value == 1 else DisplayServer.VSYNC_DISABLED)
	
	Settings.file.video.vsync = new_value

func drop_shadows_changed(new_value := 0) -> void:
	Settings.file.video.drop_shadows = new_value

func scaling_changed(new_value := 0) -> void:
	get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if new_value == 0 else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	Settings.file.video.scaling = new_value

func visuals_changed(new_value := 0) -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if new_value == 0 else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	RenderingServer.viewport_set_snap_2d_transforms_to_pixel(get_tree().root.get_viewport_rid(), not new_value)
	Settings.file.video.visuals = new_value

func hud_style_changed(new_value := 0) -> void:
	Settings.file.video.hud_size = new_value

func language_changed(new_value := 0) -> void:
	TranslationServer.set_locale(Global.lang_codes[new_value])
	Settings.file.game.lang = Global.lang_codes[new_value]
	%Flag.region_rect.position.x = new_value * 16

func frame_limit_changed(new_value := 0) -> void: 
	print_debug(str(new_value))
	
	var new_framerate := 0
	match new_value: 
		
		1: new_framerate = 60
		2: new_framerate = 120
		3: new_framerate = 144
		4: new_framerate = 240
	
	Engine.set_max_fps(new_framerate)
	Settings.file.video.frame_limit = new_value

func set_window_size(value := []) -> void:
	pass
	# nabbup: Recenter resized window on launch
	#var newpos = get_window().position - Vector2i((value[0]-get_window().size.x), (value[1]-get_window().size.y))/2
	#get_window().size = Vector2(value[0], value[1])
	#get_window().position = newpos

func set_value(value_name := "", value = null) -> void:
	{
		"mode": window_mode_changed,
		"size": window_size_changed,
		"vsync": vsync_changed,
		"drop_shadows": drop_shadows_changed,
		"scaling": scaling_changed,
		"visuals": visuals_changed,
		"palette": null_function,
		"hud_size": hud_style_changed,
		"hud_style": hud_style_changed,
		"frame_limit": frame_limit_changed,
		"window_size": set_window_size
	}[value_name].call(value)
