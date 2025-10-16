class_name BowserFlame
extends Enemy

@export_enum("Straight", "Aimed") var mode := 0

var target_y := 0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	movement(delta)

func movement(delta: float) -> void:
	if mode == 1:
		global_position.y = move_toward(global_position.y, target_y, delta * 50)
	global_position.x += (100 * direction) * delta
	$Sprite.scale.x = -direction

func play_sfx() -> void:
	AudioManager.play_sfx("bowser_flame", global_position)
