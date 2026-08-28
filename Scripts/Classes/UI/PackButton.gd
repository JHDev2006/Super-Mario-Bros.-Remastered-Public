class_name PackButton
extends Button

@onready var resource_getter = ResourceGetter.new()

func _ready() -> void:
	add_child(resource_getter)
	update()
	Global.level_theme_changed.connect(update)

func update() -> void:
	icon = resource_getter.get_resource(icon)
