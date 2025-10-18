extends Node

func parallax_style_changed(new_value := 0) -> void:
	Settings.file.visuals.parallax_style = new_value

func liquid_style_changed(_unused := -1) -> void:
	return

func hud_style_changed(new_value := 0) -> void:
	Settings.file.visuals.modern_hud = new_value

func extra_bgs_changed(new_value := 0) -> void:
	Settings.file.visuals.extra_bgs = new_value

func bg_particles_changed(new_value := 0) -> void:
	Settings.file.visuals.bg_particles = new_value

func colour_palette_changed(new_value := 0) -> void:
	Settings.file.visuals.palette = new_value

func rainbow_style_changed(new_value := 0) -> void:
	Settings.file.visuals.rainbow_style = new_value

func transform_style_changed(new_value := 0) -> void:
	Settings.file.visuals.transform_style = new_value

func text_shadows_changed(new_value := 0) -> void:
	Settings.file.visuals.text_shadows = new_value
	Global.text_shadow_changed.emit()

func transition_bg_changed(new_value := 0) -> void:
	Settings.file.visuals.transition_bg = new_value

func bridge_changed(new_value := 0) -> void:
	Settings.file.visuals.bridge_animation = new_value

func resource_pack_loaded(new_value := []) -> void:
	Global.loaded_resource_packs = new_value
	Global.level_theme_changed.emit()

func colourful_pipes_changed(new_value := 0) -> void:
	Settings.file.visuals.colour_pipes = new_value

func smbs_scroll_changed(new_value := 0) -> void:
	Settings.file.visuals.smbs_scroll = new_value

func visible_timers_changed(new_value := 0) -> void:
	Settings.file.visuals.visible_timers = new_value

func transition_style_changed(new_value := 0) -> void:
	Global.fade_transition = bool(new_value)
	Settings.file.visuals.transition_animation = new_value

func firebar_style_changed(new_value := 0) -> void:
	Settings.file.visuals.firebar_style = new_value

func extra_particles(new_value := 0) -> void:
	Settings.file.visuals.extra_particles = new_value

func set_value(value_name := "", value = null) -> void:
	{
		"parallax_style": parallax_style_changed,
		"extra_bgs": extra_bgs_changed,
		"liquid_style": liquid_style_changed,
		"modern_hud": hud_style_changed,
		"bg_particles": bg_particles_changed,
		"palette": colour_palette_changed,
		"rainbow_style": rainbow_style_changed,
		"transform_style": transform_style_changed,
		"text_shadows": text_shadows_changed,
		"transition_bg": transition_bg_changed,
		"resource_packs": resource_pack_loaded,
		"bridge_animation": bridge_changed,
		"transition_animation": transform_style_changed,
		"smbs_scroll": smbs_scroll_changed,
		"colour_pipes": colourful_pipes_changed,
		"firebar_style": firebar_style_changed,
		"extra_particles": extra_particles
	}[value_name].call(value)
