extends Node2D

var velocity := 5.0

var play_sfx := false

@onready var starting_y := global_position.y
@export_range(0, 3) var jump_delay := 1
var can_jump := true

signal killed

const BASE_LINE := 48

func _ready() -> void:
	if Global.current_game_mode != Global.GameMode.LEVEL_EDITOR and global_position.y > -32:
		Global.log_warning("Podoboo is too low! Forgot to update!")

func _physics_process(delta: float) -> void:
	velocity += (5) * delta * 60.0
	velocity = clamp(velocity, -INF, 280)
	global_position.y += velocity * delta
	global_position.y = clamp(global_position.y, -INF, BASE_LINE)
	if global_position.y >= BASE_LINE and can_jump:
		can_jump = false
		do_jump()
		
	$Sprite.flip_v = velocity > 0

func do_jump() -> void:
	if jump_delay > 0:
		$Timer.start(jump_delay)
		await $Timer.timeout
	if play_sfx:
		AudioManager.play_sfx("podoboo", global_position)
	velocity = calculate_jump_height()
	print(velocity)
	await get_tree().physics_frame
	can_jump = true

func damage_player(player: Player) -> void:
	player.damage()

func calculate_jump_height() -> float:
	global_position.y = BASE_LINE
	return -sqrt(2 * 5 * abs(starting_y - (global_position.y))) * 8
	
const SMOKE_PARTICLE = preload("uid://d08nv4qtfouv1")

func flag_die() -> void:
	die()

func die() -> void:
	killed.emit()
	queue_free()
