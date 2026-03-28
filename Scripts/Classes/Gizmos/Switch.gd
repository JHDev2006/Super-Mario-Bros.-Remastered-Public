extends Node2D

signal turned_on
signal turned_off

@export var powered := false

func toggle() -> void:
	powered = not powered
	update()

func start() -> void:
	if powered:
		update.call_deferred()

func update() -> void:
	[turned_off, turned_on][int(powered)].emit()

func _process(_delta: float) -> void:
	$Sprite2D.frame = int(powered)
