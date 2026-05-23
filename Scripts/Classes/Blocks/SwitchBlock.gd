extends AnimatableBody2D

@export_enum("Orange", "Green", "Pink", "Blue") var colour := 0
@export var active := false

const COLOUR_STRINGS := [
	"Orange",
	"Green",
	"Pink",
	"Blue"
]

func _ready() -> void:
	update_sprite()
	update_collision()

func update_sprite() -> void:
	if active:
		$Sprite.play(COLOUR_STRINGS[colour] + "Active")
	else:
		$Sprite.play(COLOUR_STRINGS[colour] + "Inactive")

func update_collision() -> void:
	$Collision.set_deferred("disabled", not active)

func turn_on() -> void:
	active = true
	update_collision()
	update_sprite()

func turn_off() -> void:
	active = false
	update_collision()
	update_sprite()

func toggle() -> void:
	active = not active
	update_collision()
	update_sprite()
