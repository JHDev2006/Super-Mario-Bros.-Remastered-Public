extends AnimatableBody2D

@export var is_active := false

func _ready() -> void:
	update()

func toggle() -> void:
	is_active = !is_active
	update()

func turn_on() -> void:
	is_active = true
	update()

func turn_off() -> void:
	is_active = false
	update()

func update() -> void:
	$Sprite.play(["Off", "On"][int(is_active)])
	$PlayerDetection/CollisionShape2D.set_deferred("disabled", !is_active)
