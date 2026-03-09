extends Enemy


var target_player: Player = null
var direction_vector := Vector2.LEFT

var direction_angle := 0.0

const SPEED := 75.0

@export var explosion_scene: PackedScene = null

var can_turn := true

var can_explode := true

func _ready() -> void:
	if has_meta("block_item"):
		can_explode = false
		direction_vector = Vector2.UP
		await get_tree().create_timer(1, false).timeout
		can_explode = true
	$Timer.start()

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_visuals()

func handle_movement(delta: float) -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	if can_turn:
		direction_vector = lerp(direction_vector, ((target_player.global_position + Vector2(0, -8)) - global_position), delta).normalized()
	if abs(direction_vector.x) > 0:
		direction = sign(direction_vector.x)
	velocity = SPEED * direction_vector
	global_position += velocity * delta

func handle_visuals() -> void:
	var angle = snapped(rad_to_deg(direction_vector.angle()), 45)
	var diagonal = angle % 90 != 0
	$Sprite.global_rotation_degrees = angle + (180 if direction == -1 else 0)
	if diagonal:
		$Sprite.global_rotation_degrees += (45 if direction == 1 else 135)
	$ParticlesRotation.global_rotation_degrees = angle
	$ParticlesRotation.show()
	$Sprite.play("Diagonal" if diagonal else "Normal")
	$Sprite.scale.x = direction

func hit_solid() -> void:
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	AudioManager.play_sfx("explode", global_position)
	add_sibling(explosion)
	queue_free()


func on_timeout() -> void:
	can_turn = false
