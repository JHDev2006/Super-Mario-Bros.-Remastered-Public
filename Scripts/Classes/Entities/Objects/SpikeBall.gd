class_name SpikeBall
extends CharacterBody2D

var can_gravity := false
const SPIKE_BALL_DESTRUCTION_PARTICLES = preload("uid://bk0arhpyyila6")
func _physics_process(delta: float) -> void:
	handle_movement(delta)
	$Sprite.rotation_degrees += velocity.x * delta * 8
	handle_block_collision()

func handle_movement(delta: float) -> void:
	if can_gravity:
		velocity.y += (Global.entity_gravity) * delta * 60.0
	if is_on_floor():
		can_gravity = true
		velocity.x += get_floor_normal().x * 4
	if is_on_wall():
		destroy()
	if sign(get_floor_normal().x) != sign(velocity.x) and abs(get_floor_normal().x) > 0.2 and is_on_floor():
		velocity.y = (velocity.length() * get_floor_normal().y) + Global.entity_gravity
	move_and_slide()

func destroy() -> void:
	summon_particles()
	AudioManager.play_sfx("block_break", global_position)
	queue_free()

func handle_block_collision() -> void:
	for i in $Hitbox.get_overlapping_bodies():
		if i is Block:
			if global_position.y - 8 < i.global_position.y:
				i.shell_block_hit.emit(null)

func summon_particles() -> void:
	var particles = SPIKE_BALL_DESTRUCTION_PARTICLES.instantiate()
	particles.global_position = global_position
	add_sibling(particles)

func on_area_entered(area: Area2D) -> void:
	if area.owner is SpikeBall and area.owner != self:
		destroy()
	if area.owner is Enemy:
		if area.owner.has_node("ShellDetection"):
			area.owner.die_from_object(self)
	elif area.owner is Player:
		if area.owner.is_invincible or area.name == "HammerHitbox":
			destroy()
		else:
			area.owner.damage()
