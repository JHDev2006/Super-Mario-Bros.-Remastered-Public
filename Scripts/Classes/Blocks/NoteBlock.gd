class_name NoteBlock
extends Block

var bodies: Array[CharacterBody2D] = []

signal bounced
var animating := false
@export var play_sfx := true

var can_bounce := true

func bounce_up() -> void:
	if bouncing or animating:
		return
	bounced.emit()
	bouncing = true
	animating = true
	%Animations.play("BounceUp")
	dispense_item(-1)
	await %Animations.animation_finished
	bouncing = false
	animating = false

func _physics_process(_delta: float) -> void:
	if can_bounce:
		for i in %Area.get_overlapping_areas():
			if i.owner is CharacterBody2D:
				bounce_down(i.owner)

func bounce_down(body: PhysicsBody2D) -> void:
	if bouncing or animating:
		return
	can_bounce = false
	animating = true
	bounced.emit()
	if play_sfx:
		AudioManager.play_sfx("note_block", global_position)
	bodies.append(body)
	if body is Player:
		body.normal_state.jump_queued = false
		body.spring_bouncing = true
		body.has_jumped = false
	%Animations.play("BounceDown")
	dispense_item(1)
	await %Animations.animation_finished
	animating = false
	bouncing = false
	await get_tree().create_timer(0.1, false).timeout
	can_bounce = true

func bounce_bodies() -> void:
	for i in bodies:
		if is_instance_valid(i) == false:
			continue
		if i is Player:
			i.spring_bouncing = false
			if Global.player_action_pressed("jump", i.player_id):
				i.jump_cancelled = false
				i.has_jumped = true
				i.velocity.y = -350
				i.gravity = i.calculate_speed_param("JUMP_GRAVITY")
			else:
				i.velocity.y = -300
				i.gravity = i.calculate_speed_param("FALL_GRAVITY", i.velocity_x_jump_stored)
		else:
			i.velocity.y = -200
		if i is Thwomp:
			i.velocity = Vector2.ZERO
	bodies.clear()

func dispense_item(direction := -1) -> void:
	if item == null or item_amount <= 0:
		return
	item_amount -= 1
	var node = item.instantiate()
	node.global_position = global_position + Vector2(0, 8 * direction)
	node.set("velocity", Vector2(0, (100 if direction == 1 else -150)))
	add_sibling(node)
	AudioManager.play_sfx("item_appear", global_position)

const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

func summon_puff() -> void:
	$Particles.reparent(get_parent())
	var node = SMOKE_PARTICLE.instantiate()
	node.global_position = global_position + Vector2(0, 8)
	add_sibling(node)
	queue_free()
