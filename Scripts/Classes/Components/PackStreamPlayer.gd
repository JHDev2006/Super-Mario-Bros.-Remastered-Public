class_name PackStreamPlayer
extends AudioStreamPlayer

@onready var resource_getter = ResourceGetter.new()

func _ready() -> void:
	add_child(resource_getter)
	update()
	Global.level_theme_changed.connect(update)

func update() -> void:
	stream = resource_getter.get_resource(stream)
