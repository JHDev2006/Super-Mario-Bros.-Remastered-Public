class_name PackNinePatch
extends NinePatchRect

@onready var resource_getter = ResourceGetter.new()

func _ready() -> void:
	update()
	Global.level_theme_changed.connect(update)

func update() -> void:
	texture = resource_getter.get_resource(texture)

func _exit_tree() -> void:
	resource_getter.free()
