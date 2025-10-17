class_name Hammer
extends Enemy

func _ready() -> void:
	velocity = Vector2(0, -200)
	$Sprite.flip_h = direction == 1
	$Animations.speed_scale = -direction
	velocity.x = 120 * direction
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_sfx("hammer_throw", global_position)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	velocity.y += (Global.entity_gravity / delta) * delta
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
