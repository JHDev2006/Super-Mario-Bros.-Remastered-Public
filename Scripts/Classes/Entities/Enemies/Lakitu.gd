class_name Lakitu
extends Enemy

static var present := false:
	set(value):
		if value == true:
			pass
		present = value

var screen_center := Vector2.ZERO
var lakitu_point := Vector2.ZERO

const BLOCK_DISTANCE := 64

var player: Player = null

var retreat := false

var can_enter := false

static var spiny_amount := 0
@export var item: PackedScene = null
@export var retreat_x := 3072

func _ready() -> void:
	can_enter = false
	$ThrowTimer.start()
	lakitu_point = to_local(global_position)
	get_parent().move_child(self, 0)

func _process(_delta: float) -> void:
	screen_center = get_viewport().get_camera_2d().get_screen_center_position()

func _physics_process(delta: float) -> void:
	player = get_tree().get_first_node_in_group("Players")
	handle_movement(delta)

func handle_movement(_delta: float) -> void:
	retreat = get_viewport().get_camera_2d().get_screen_center_position().x >= retreat_x
	var player_x = player.global_position.x + ((player.velocity.x))
	var distance = abs(global_position.x - player_x)
	get_direction(player_x)
	if direction == 1:
		velocity.x = int(clamp((distance - 16) * 2, 48, INF))
	else:
		velocity.x = -48
	$Cloud.scale.x = direction
	move_and_slide()

func get_direction(player_x := 0.0) -> void:
	if retreat:
		present = false
		direction = -1
		return
	if direction == -1 and global_position.x < player_x - BLOCK_DISTANCE:
		direction = 1
	elif direction == 1 and global_position.x > player_x + BLOCK_DISTANCE:
		direction = -1

func summon_cloud_particle() -> void:
	var node = preload("res://Scenes/Prefabs/Particles/LakituCloudBurst.tscn").instantiate()
	node.global_position = $Cloud.global_position
	add_sibling(node)

func on_timeout() -> void:
	if spiny_amount >= 3 or retreat or $WallCheck.is_colliding():
		return
	$Cloud/Sprite.play("Throw")
	await get_tree().create_timer(0.5, false).timeout
	if $WallCheck.is_colliding() == false:
		throw_spiny()
	$Cloud/Sprite.play("Idle")

func throw_spiny() -> void:
	var node = item.instantiate()
	spiny_amount += 1
	node.set("in_egg", true)
	node.global_position = $Cloud/Sprite.global_position
	node.velocity = Vector2(0, -150)
	if Settings.file.difficulty.lakitu_style == 1:
		node.velocity.x = 50 * (sign(player.global_position.x - global_position.x))
		node.set("direction", sign(node.velocity.x))
	add_sibling(node)
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_sfx("lakitu_throw", global_position)
	node.tree_exited.connect(func(): spiny_amount -= 1)

func on_screen_entered() -> void:
	if Global.level_editor != null:
		if Global.level_editor.playing_level == false:
			return
	add_to_group("Lakitus")
	if get_tree().get_node_count_in_group("Lakitus") >= 2:
		queue_free()
