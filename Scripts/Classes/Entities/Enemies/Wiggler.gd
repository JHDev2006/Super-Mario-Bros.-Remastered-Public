extends Enemy

@onready var parts := [$Parts/Head, $Parts/Body1, $Parts/Body2, $Parts/Body3, $Parts/Body4]

var wave := 0.0

var positions := []

var PART_SEPERATION := 12.0
var WAVE_POWER := 1.1
var WAVE_LENGTH := 3.141
var WAVE_SPEED := 12.0

var angry := false

var can_move := true

var dead := false

func _ready() -> void:
	for i in parts:
		i.global_position = global_position

func _physics_process(delta: float) -> void:
	handle_part_wave(delta)
	if can_move:
		handle_part_movement(delta)
		$BasicEnemyMovement.handle_movement(delta)
	elif dead:
		handle_part_movement(delta)
		handle_dying_state(delta)

func handle_part_wave(delta: float) -> void:
	wave += WAVE_SPEED * delta
	for i in parts:
		i.get_node("Sprite").offset.y = (sin(wave + (i.get_index() * WAVE_LENGTH)) * WAVE_POWER) - (WAVE_POWER / 2)

func handle_part_movement(_delta: float) -> void:
	positions.push_front(global_position)
	var idx := 0
	for i in parts:
		var target_position = i.global_position
		if positions.size() > idx * PART_SEPERATION:
			target_position = positions[idx * PART_SEPERATION]
		var part_direction = sign(target_position.x - i.global_position.x)
		if part_direction != 0:
			i.scale.x = part_direction
		i.global_position = target_position
		idx += 1
	if positions.size() > parts.size() * PART_SEPERATION:
		positions.pop_back()


func die_from_object(obj: Node2D) -> void:
	var dir = sign(global_position.x - obj.global_position.x)
	if dir == 0:
		dir = [-1, 1].pick_random()
	DiscoLevel.combo_amount += 1
	killed.emit(dir)

func player_stomped_on(player: Player) -> void:
	player.enemy_bounce_off(not angry, not angry)
	AudioManager.play_sfx("enemy_stomp", global_position)
	if not angry:
		make_angry()

func make_angry() -> void:
	angry = true
	can_move = false
	WAVE_SPEED *= 2
	$FlowerPoof.play("default")
	for i in parts:
		i.get_node("Sprite").play("Angry")
		part_scale_tween(i)
		await get_tree().create_timer(0.05, false).timeout
	await get_tree().create_timer(0.5, false).timeout
	can_move = true
	$Timer.start()
	$BasicEnemyMovement.move_speed *= 2
	PART_SEPERATION /= 2

func do_death_animation() -> void:
	AudioManager.play_sfx("kick", global_position)
	dead = true
	can_move = false
	$Collision.queue_free()
	$VisibleOnScreenEnabler2D.queue_free()
	for i in parts:
		i.get_node("PlayerDetection").queue_free()
	velocity.x = 0
	velocity.y = -250
	await get_tree().create_timer(5, false).timeout
	queue_free()

func part_scale_tween(part: Node2D) -> void:
	part.get_node("Sprite").scale = Vector2(1.5, 1.5)
	create_tween().tween_property(part.get_node("Sprite"), "scale", Vector2.ONE, 0.1)

func handle_dying_state(delta) -> void:
	apply_enemy_gravity(delta)
	move_and_slide()
	
