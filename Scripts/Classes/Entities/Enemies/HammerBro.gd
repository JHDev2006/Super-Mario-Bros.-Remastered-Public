extends Enemy

var jumping := false
var jump_direction := 0

@export var auto_charge := false

var charging := false
var charge_timer := 10 if Settings.file.difficulty.hammer_bro_style == 1 else 50
var charge_speed := 50 if Settings.file.difficulty.hammer_bro_style == 1 else 32
var hammer_timer := 1.0 if Settings.file.difficulty.hammer_bro_style == 1 else 0.133
var hammer_held_timer = 0.5 if Settings.file.difficulty.hammer_bro_style == 1 else 0.233

var wall_jump := false
var target_player: Player = null
const HAMMER = preload("res://Scenes/Prefabs/Entities/Items/Hammer.tscn")

func _ready() -> void:
	$MovementAnimations.play("Movement")
	$Timer.start(charge_timer)
	$JumpTimer.start()
	$HammerTimer.start(hammer_timer)

func _process(delta: float) -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	direction = sign(target_player.global_position.x - global_position.x)

	$MovementJoint/Sprite.scale.x = direction
	if $TrackJoint.is_attached: $MovementAnimations.play("RESET")

func _physics_process(delta: float) -> void:
	apply_enemy_gravity(delta)
	if charging and target_player != null:
		if is_on_wall() and is_on_floor():
			jump(true)
		velocity.x = charge_speed * direction
		if ((direction > 0 and global_position.x >= target_player.global_position.x) or (direction < 0 and global_position.x <= target_player.global_position.x)) and Settings.file.difficulty.hammer_bro_style == 0:
			charging = false
			$MovementAnimations.play("Movement")
			$Timer.start(charge_timer)
	else:
		velocity.x = 0
	move_and_slide()
	handle_collision()

func handle_collision() -> void:
	var can_pass_block := false
	if jump_direction == -1:
		can_pass_block = velocity.y < -50
	elif jump_direction == 1:
		can_pass_block = velocity.y <= 250
	$Collision.set_deferred("disabled", can_pass_block and jumping and not wall_jump)
	if is_on_floor() and jumping:
		jumping = false

func jump(wall := false) -> void:
	if is_on_floor() == false:
		return
	wall_jump = wall
	jumping = true
	jump_direction = [-1, 1].pick_random()
	if jump_direction == -1 and $UpBlock.is_colliding() == false:
		jump_direction = 1
	if jump_direction == 1 and ($BlockDetect.is_colliding() or global_position.y >= -1):
		jump_direction = -1
	if jump_direction == -1:
		velocity.y = -300
	else:
		velocity.y = -140
	$JumpTimer.start(randf_range(1, 5))

func do_hammer_throw() -> void:
	if Settings.file.difficulty.hammer_bro_style == 1:
		for i in randi_range(1, 6):
			await throw_hammer()
			await get_tree().create_timer(0.25, false).timeout
		$HammerTimer.start(randf_range(2, 5))
	else:
		if randi_range(1, 4) == 1:
			await throw_hammer()
		$HammerTimer.start(hammer_timer)

func throw_hammer() -> void:
	$MovementJoint/Sprite/Hammer.show()
	if Settings.file.difficulty.hammer_bro_style == 0: $HammerHitbox/Shape.disabled = false
	$MovementJoint/Sprite.play("Hammer")
	await get_tree().create_timer(hammer_held_timer, false).timeout
	spawn_hammer()
	$MovementJoint/Sprite.play("Idle")
	if Settings.file.difficulty.hammer_bro_style == 0: $HammerHitbox/Shape.disabled = true
	$MovementJoint/Sprite/Hammer.hide()

func spawn_hammer() -> void:
	var node = HAMMER.instantiate()
	if Settings.file.difficulty.hammer_bro_style == 0:
		node.MOVE_SPEED = 64
		node.GRAVITY = 4
	node.global_position = $MovementJoint/Sprite/Hammer.global_position
	node.velocity.y = -200 if Settings.file.difficulty.hammer_bro_style == 1 else -100
	node.direction = direction
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_sfx("hammer_throw", global_position)
	if $TrackJoint.is_attached:
		get_parent().owner.add_sibling(node)
	else:
		add_sibling(node)

func charge() -> void:
	charging = true
	$MovementAnimations.play("RESET")

func on_screen_entered() -> void:
	if auto_charge:
		charge()
