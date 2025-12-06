extends Control

var current_theme := "Overworld"

const THEME_ICONS_DAY = preload("uid://cw5c58yiaeh4j")
const THEME_ICONS_NIGHT = preload("uid://bds7ota87jglw")

signal level_theme_changed

func _ready() -> void:
	update()
	grab_themes()

func grab_themes() -> void:
	for i in %ThemeContainer.get_children():
		i.get_node("Button").pressed.connect(theme_selected.bind(i.name))

func open() -> void:
	update()
	show()

func close() -> void:
	hide()

func update() -> void:
	for i in %ThemeContainer.get_children():
		i.get_node("Checkbox").visible = current_theme == i.name
		i.texture = [THEME_ICONS_DAY, THEME_ICONS_NIGHT][["Day", "Night"].find(Global.theme_time)]

func theme_selected(theme_name := "") -> void:
	current_theme = theme_name
	Global.level_theme = current_theme
	Global.current_level.theme = current_theme
	level_theme_changed.emit()
	ResourceSetterNew.cache.clear()
	ResourceSetter.cache.clear()
	Global.update_theme()
	update()
	close()
