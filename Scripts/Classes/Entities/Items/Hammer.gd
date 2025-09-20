class_name Hammer
extends Node2D

var velocity := Vector2(0, -200)

var direction := -1

func _ready() -> void:
	$Sprite.flip_h = direction == 1
	$Animations.speed_scale = -direction
	velocity.x = 120 * direction
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_sfx("hammer_throw", global_position)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	velocity.y += (Global.entity_gravity) * delta * 60.0
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
	
func flag_die() -> void:
	queue_free()

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		area.owner.damage()
