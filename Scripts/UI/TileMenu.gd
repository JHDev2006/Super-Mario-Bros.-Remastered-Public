extends CanvasLayer

var editor: LevelEditor = null

func _ready() -> void:
	Global.level_theme_changed.connect(update_theme_name)

func update_theme_name() -> void:
	%ThemeName.text = Global.level_theme

func update_menu_values(level: Level) -> void:
	%ThemeTime.selected = ["Day", "Night"].find(level.theme_time)
	if level.music != null:
		%LevelMusic.selected = editor.bgm_id
	else:
		%LevelMusic.selected = 0
	%Campaign.selected = Global.CAMPAIGNS.find(level.campaign)
	%BackScroll.set_pressed_no_signal(level.can_backscroll)
	%HeightLimit.value = abs(level.vertical_height)
	%TimeLimit.value = level.time_limit
	%SubLevelID.selected = editor.sub_level_id
	%ScreenSize.set_pressed_no_signal(level.enforce_resolution != Vector2.ZERO)
	
	var level_bg: LevelBG = level.get_node("LevelBG")
	%SecondLayerOrder.selected = level_bg.second_layer_order
	%PrimaryLayer.selected = level_bg.primary_layer
	%SecondLayer.selected = level_bg.second_layer
	%Particles.selected = level_bg.particles
	%LiquidLayer.selected = level_bg.liquid_layer
	%OverlayClouds.set_pressed_no_signal(level_bg.overlay_clouds)
