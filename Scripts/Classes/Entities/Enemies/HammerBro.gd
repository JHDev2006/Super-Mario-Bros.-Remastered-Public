extends Enemy

var jumping := false
var jump_direction := 0

@export var auto_charge := false

var charging := false

var wall_jump := false
var target_player: Player = null
const HAMMER = preload("res://Scenes/Prefabs/Entities/Items/Hammer.tscn")

func _ready() -> void:
	$MovementAnimations.play("Movement")
	$Timer.start()
	$JumpTimer.start()
	$HammerTimer.start()

func _process(delta: float) -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	direction = sign(target_player.global_position.x - global_position.x)
	$MovementJoint/Sprite.scale.x = -direction
	if $TrackJoint.is_attached: $MovementAnimations.play("RESET")

func _physics_process(delta: float) -> void:
	apply_enemy_gravity(delta)
	if charging and target_player != null:
		if is_on_wall() and is_on_floor():
			jump(true)
		velocity.x = 50 * direction
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
	for i in randi_range(1, 6):
		await throw_hammer()
		await get_tree().create_timer(0.25, false).timeout
	$HammerTimer.start(randf_range(2, 5))

func throw_hammer() -> void:
	$MovementJoint/Sprite/Hammer.show()
	$MovementJoint/Sprite.play("Hammer")
	await get_tree().create_timer(0.5, false).timeout
	spawn_hammer()
	$MovementJoint/Sprite.play("Idle")
	$MovementJoint/Sprite/Hammer.hide()

func spawn_hammer() -> void:
	var node = HAMMER.instantiate()
	node.global_position = $MovementJoint/Sprite/Hammer.global_position
	node.direction = direction
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
