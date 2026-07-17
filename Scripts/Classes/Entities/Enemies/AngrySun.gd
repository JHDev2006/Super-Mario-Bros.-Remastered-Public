class_name AngrySun
extends Enemy

enum States{IDLE, CHARGING, DIVING}

var current_state := States.IDLE

var screen_size := Vector2(256, 240)

var screen_direction := -1

var screen_center_pos := Vector2.ZERO

var margin := Vector2(32, 48)

var target_position := Vector2.ZERO

var wave := 0.0

var in_position := false

var old_dive_position := Vector2.ZERO
var new_dive_position := Vector2.ZERO

func _ready() -> void:
	if $SignalExposer.total_inputs <= 0:
		$IdleMeter.start()

func _physics_process(delta: float) -> void:
	screen_center_pos = get_viewport().get_camera_2d().get_screen_center_position()
	screen_size = get_viewport().get_visible_rect().size
	target_position = (screen_center_pos + Vector2((screen_size.x / 2) * screen_direction, -screen_size.y / 2)) + (margin * Vector2(-screen_direction, 1))
	handle_states.call_deferred(delta)

func handle_states(delta: float) -> void:
	match current_state:
		States.IDLE:
			handle_idle(delta)
		States.CHARGING:
			handle_charging(delta)
		States.DIVING:
			handle_wave(delta)

func start_charging() -> void:
	%Sprite.play("Charge")
	current_state = States.CHARGING
	$ChargeMeter.start()

func handle_idle(delta: float) -> void:
	if in_position:
		global_position = lerp(global_position, target_position, 1)
	else:
		global_position = lerp(global_position, target_position, delta * 20)
		if global_position.distance_to(target_position) <= 16:
			in_position = true

func start_diving() -> void:
	%Sprite.play("Dive")
	old_dive_position = (Vector2((screen_size.x / 2) * screen_direction, -screen_size.y / 2)) + (margin * Vector2(-screen_direction, 1))
	new_dive_position = (Vector2((screen_size.x / 2) * -screen_direction, -screen_size.y / 2)) + (margin * Vector2(screen_direction, 1))
	wave = 0
	current_state = States.DIVING

func handle_charging(delta: float) -> void:
	wave += delta
	target_position += Vector2(sin(wave * 16) * 8, cos(wave * 16) * 8)
	global_position = lerp(global_position, target_position, delta * 20)

func start_idle() -> void:
	%Sprite.play("Idle")
	screen_direction *= -1
	wave = 0
	current_state = States.IDLE
	$IdleMeter.start()

func handle_wave(delta: float) -> void:
	wave += 0.6 * delta
	target_position = screen_center_pos + Vector2(lerpf(old_dive_position.x, new_dive_position.x, wave), old_dive_position.y + (sin(wave * PI) * ((screen_size.y / 2) + 48)))
	global_position = target_position
	if wave >= 1:
		screen_direction *= -1
		start_charging()
		
const MOON_SPARKLE = preload("uid://biq4hwvm6q8qr")

func moon_wipe() -> void:
	AudioManager.play_global_sfx("moon_wipe")
	for i in get_tree().get_nodes_in_group("Enemies"):
		var sparkle = MOON_SPARKLE.instantiate()
		sparkle.global_position = i.global_position + Vector2(0, -8)
		add_sibling(sparkle)
		i.flag_die()
