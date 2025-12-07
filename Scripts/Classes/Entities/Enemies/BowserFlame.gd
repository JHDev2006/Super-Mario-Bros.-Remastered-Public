class_name BowserFlame
extends Projectile

@export_enum("Straight", "Aimed") var mode := 0

var target_y := 0

func _physics_process(delta: float) -> void:
	if mode == 1:
		global_position.y = move_toward(global_position.y, target_y, delta * 50)
	$Sprite.flip_h = direction != 1
	handle_movement(delta)

func play_sfx() -> void:
	AudioManager.play_sfx("bowser_flame", global_position)
