extends Enemy

const BOWSER_FLAME = preload("res://Scenes/Prefabs/Entities/Enemies/BowserFlame.tscn")
const HAMMER = preload("res://Scenes/Prefabs/Entities/Items/Hammer.tscn")
@onready var sprite: BetterAnimatedSprite2D = $SpriteScaleJoint/Sprite

@export var can_hammer := false
@export var can_fire := true
@export var is_real := true
@export var music_enabled := true

var target_player: Player = null

var can_move := true
var can_fall := true

var health := 5

var move_dir := -1

func _ready() -> void:
	for i in [$JumpTimer, $HammerTime, $FlameTimer]:
		i.start()

func _physics_process(delta: float) -> void:
	target_player = get_tree().get_nodes_in_group("Players")[0]
	if is_on_floor():
		direction = sign(target_player.global_position.x - global_position.x)
		velocity.x = 0
	sprite.scale.x = direction
	if can_fall:
		apply_enemy_gravity(delta)
	move_and_slide()
	if Input.is_action_just_pressed("editor_move_player") and Global.debug_mode:
		die()

func jump() -> void:
	if is_on_floor():
		velocity.y = -100
	$JumpTimer.start(randf_range(1, 2.5))

func apply_enemy_gravity(delta: float) -> void:
	velocity.y += (2.5 / delta) * delta
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)

func get_target_y(player: Player) -> float:
	if player.global_position.y + 16 < global_position.y:
		return player.global_position.y - 32
	else:
		return player.global_position.y - 8

func show_smoke() -> void:
	if is_real: return
	var smoke = preload("res://Scenes/Prefabs/Particles/SmokeParticle.tscn").instantiate()
	smoke.scale = Vector2(2, 2)
	smoke.global_position =global_position
	AudioManager.play_sfx("magic", global_position)
	add_sibling(smoke)

func breathe_fire() -> void:
	if can_fire == false:
		return
	sprite.play("FireCharge")
	await get_tree().create_timer(1, false).timeout
	var flame = BOWSER_FLAME.instantiate()
	flame.global_position = global_position + Vector2(18 * direction, -20)
	flame.mode = 1
	flame.direction = direction
	flame.target_y = get_target_y(target_player)
	if $TrackJoint.is_attached:
		get_parent().owner.add_sibling(flame)
	else:
		add_sibling(flame)
	sprite.play("FireBreathe")
	if is_instance_valid(get_node_or_null("FlameTimer")):
		$FlameTimer.start(randf_range(1.5, 4.5))
	await get_tree().create_timer(0.5, false).timeout
	sprite.play("Idle")

func bridge_fall() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	direction = 1
	$FlameTimer.queue_free()
	$HammerTime.queue_free()
	$JumpTimer.queue_free()
	sprite.play("Fall")
	sprite.reset_physics_interpolation()
	$MoveAnimation.queue_free()
	can_fall = false
	velocity.y = 0
	await get_tree().create_timer(2).timeout
	$FallSFX.play()
	can_fall = true
	$Collision.queue_free()
	await get_tree().create_timer(2).timeout
	queue_free()

func throw_hammers() -> void:
	if can_hammer == false:
		return
	$Hammer.show()
	await get_tree().create_timer(0.5, false).timeout
	for i in randi_range(3, 6):
		$Hammer.show()
		await get_tree().create_timer(0.1, false).timeout
		var node = HAMMER.instantiate()
		node.velocity.y = -200
		node.global_position = $Hammer.global_position
		node.direction = direction
		if $TrackJoint.is_attached:
			get_parent().owner.add_sibling(node)
		else:
			add_sibling(node)
		sprite.play("Idle")
		$Hammer.hide()
		await get_tree().create_timer(0.1, false).timeout
	if get_node_or_null("HammerTime") != null:
		$HammerTime.start()

func fireball_hit() -> void:
	health -= 1
	AudioManager.play_sfx("bump", global_position)
	if health <= 0:
		die()
	else:
		$SpriteScaleJoint/HurtAnimation.stop()
		$SpriteScaleJoint/HurtAnimation.play("Hurt")
		AudioManager.play_sfx("kick", global_position)

func play_music() -> void:
	for i: EntityGenerator in get_tree().get_nodes_in_group("EntityGenerators"):
		if i.entity_scene != null:
			if i.entity_scene.resource_path == "res://Scenes/Prefabs/Entities/Enemies/BowserFlame.tscn":
				i.queue_free()
	if Settings.file.audio.extra_bgm == 0: return
	if Global.level_editor != null:
		return
	if music_enabled:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.BOWSER, 5, false)

func on_timeout() -> void:
	move_dir = [-1, 1].pick_random()

func on_gib_about_to_spawn() -> void:
	if is_real:
		$FallSFX.play()
		$FallSFX.finished.connect($FallSFX.queue_free)
		$FallSFX.reparent(get_parent())
	# guzlad: ugly but it'll have to do until we move the metadata stuff to actual variables
	if ((Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL) or (Global.current_game_mode == Global.GameMode.LEVEL_EDITOR)) and !is_real:
		$SpriteScaleJoint/DeathSprite/ResourceSetterNew.resource_json = load("res://Assets/Sprites/Enemies/Goomba.json")
