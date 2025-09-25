class_name FireBall
extends CharacterBody2D

const CHARACTERS := ["Mario", "Luigi", "Toad", "Toadette"]

var character := "Mario"

var direction := 1
const FIREBALL_EXPLOSION = preload("res://Scenes/Prefabs/Particles/FireballExplosion.tscn")

const MOVE_SPEED := 220

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	$Sprite/Animation.speed_scale = direction * 2
	velocity.x = MOVE_SPEED * direction
	velocity.y += (15 / delta) * delta
	velocity.y = clamp(velocity.y, -INF, 150)
	if is_on_floor():
		velocity.y = -125
	if is_on_wall() or (abs(get_floor_normal().x) > 0 and is_on_ceiling()):
		hit()
	move_and_slide()

func hit(play_sfx := true) -> void:
	if play_sfx:
		AudioManager.play_sfx("bump", global_position)
	summon_explosion()
	queue_free()

func summon_explosion() -> void:
	var node = FIREBALL_EXPLOSION.instantiate()
	node.global_position = global_position
	add_sibling(node)
