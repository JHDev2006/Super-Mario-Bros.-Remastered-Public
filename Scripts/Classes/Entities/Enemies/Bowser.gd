extends Enemy

const BOWSER_FLAME = preload("res://Scenes/Prefabs/Entities/Enemies/BowserFlame.tscn")
const HAMMER = preload("res://Scenes/Prefabs/Entities/Items/Hammer.tscn")
@onready var sprite: BetterAnimatedSprite2D = $SpriteScaleJoint/Sprite

@export var can_hammer := false
@export var can_fire := true
@export var is_real := false
@export var music_enabled := true

var target_player: Player = null

var can_move := true
var can_fall := true
var is_falling_from_bridge := false
var charging_player := false
var charging_fire := false
var fire_shot := -1
var hammers_queued := 0
var hammers_spawned := 0

var health := 5

var move_dir := 1
var move_speed := 16

var modern = Settings.file.gameplay.bowser_style == 1

var starting_position := 0
var target_position := 0
var waiting_for_jump := false

var classic_starting_timers := [0.5333, 0.0667, 3.7333]
var modern_starting_timers := [1, 1, 0.5]
var classic_fire_table := [3.2, 1.0667, 3.2, 3.2, 3.2, 1.0667, 1.0667, 3.2]
var jump_height := 100 if modern else 128
var fall_speed := 2.5 if modern else 3.52
var max_fall_speed := Global.entity_max_fall_speed if modern else 150

var fire_charge_speed := 1.0 if modern else 0.5333

func _ready() -> void:
	if Global.world_num >= 5 or (Global.world_num >= 4 and (Global.current_campaign == "SMBLL" or Global.current_campaign == "SMBANN")):
		classic_fire_table.map(func(x): return x - 0.2667)
	starting_position = global_position.x
	get_new_target_position()
	move_speed = 16 if modern else 32
	waiting_for_jump = not modern
	var timer_type = modern_starting_timers if modern else classic_starting_timers
	var index = 0
	for i in [$JumpTimer, $HammerTime, $FlameTimer]:
		if timer_type[index] != null:
			i.wait_time = timer_type[index]
			i.start()
		index += 1

func _physics_process(delta: float) -> void:
	target_player = get_tree().get_nodes_in_group("Players")[0]
	print("Bowser position: ", global_position.x, "\nStart Position: ", starting_position, "\nTarget position: ", target_position)
	if charging_player:
		move_dir = 1
	elif (move_dir >= 0 and global_position.x >= target_position) or (move_dir < 0 and global_position.x <= target_position):
		if target_position == starting_position:
			get_new_target_position()
			if modern: move_dir *= -1
		else:
			target_position = starting_position
			move_dir *= -1
	if is_instance_valid(get_node_or_null("FireTimer")):
		if $FlameTimer.time_left == 0: 
			$FlameTimer.start(randf_range(1.5, 4.5) if modern else classic_fire_table[fire_shot % classic_fire_table.size()])
	if is_instance_valid(get_node_or_null("HammerTime")):
		if $HammerTime.time_left == 0: 
			$HammerTime.start()
	if is_on_floor():
		direction = sign(target_player.global_position.x - global_position.x)
		charging_player = direction > 0 and not modern
		if velocity.y == 0 and not modern:
			if is_instance_valid(get_node_or_null("JumpTimer")):
				if $JumpTimer.time_left == 0: 
					$JumpTimer.start([0.2667, 0.5333, 0.8, 1.0667].pick_random())
			if not waiting_for_jump: move_speed = 16
	sprite.scale.x = direction
	
	if (charging_fire and not modern) or is_falling_from_bridge or not can_fall:
		velocity.x = 0
	else:
		velocity.x = move_speed * move_dir if not charging_player else (move_speed * 2) * move_dir
	if can_fall:
		apply_enemy_gravity(delta)
	move_and_slide()
	if Input.is_action_just_pressed("editor_move_player") and Global.debug_mode:
		die()

func get_new_target_position():
	target_position = starting_position + 32 if modern else starting_position + ([16, 32, 48, 64].pick_random() * sign(move_dir))

func jump() -> void:
	if charging_player:
		return
	if is_on_floor():
		velocity.y = -jump_height
	if not modern:
		position.y -= 1 # SkyanUltra: I don't know why classic bowser does this, but he does. Cool???
	else:
		$JumpTimer.start(randf_range(1, 2.5))
	await get_tree().physics_frame
	waiting_for_jump = false

func apply_enemy_gravity(delta: float) -> void:
	velocity.y += (fall_speed / delta) * delta
	velocity.y = clamp(velocity.y, -INF, max_fall_speed)

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
	if not can_fire:
		return
	sprite.play("FireCharge")
	charging_fire = true
	await get_tree().create_timer(fire_charge_speed, false).timeout
	if ignore_flag_die:
		return
	charging_fire = false
	fire_shot += 1
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
		$FlameTimer.start(randf_range(1.5, 4.5) if modern else classic_fire_table[fire_shot % classic_fire_table.size()])
	await get_tree().create_timer(0.5, false).timeout
	sprite.play("Idle")

func bridge_fall() -> void:
	AudioManager.play_global_sfx("bowser_fall")
	ignore_flag_die = true
	can_fall = true
	is_falling_from_bridge = true
	$Collision.queue_free()
	await get_tree().create_timer(5).timeout
	queue_free()

func do_start_fall() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	direction = 1
	sprite.play("Fall")
	sprite.reset_physics_interpolation()
	$FlameTimer.queue_free()
	$HammerTime.queue_free()
	$JumpTimer.queue_free()
	can_fall = false
	velocity.y = 0

func throw_hammers() -> void:
	if can_hammer == false:
		return
	if modern:
		modern_hammers()
	else:
		classic_hammers()

func classic_hammers() -> void:
	if is_on_floor() or randi_range(1, 9) < hammers_spawned:
		return
	hammers_queued += 1
	hammers_spawned += 1
	sprite.play("Hammer")
	$Hammer.show()
	await get_tree().create_timer(0.233, false).timeout
	if ignore_flag_die:
		sprite.play("Idle")
		$Hammer.hide()
		return
	spawn_hammer()
	hammers_queued -= 1
	if hammers_queued <= 0:
		sprite.play("Idle")
		$Hammer.hide()

func despawn_hammer() -> void:
	hammers_spawned -= 1

func spawn_hammer() -> void:
	var node = HAMMER.instantiate()
	var notifier = node.get_node("VisibleOnScreenNotifier2D")
	notifier.screen_exited.connect(self.despawn_hammer)
	if not modern:
		node.MOVE_SPEED = 64
		node.GRAVITY = 4
	node.global_position = $Hammer.global_position
	node.velocity.y = -200 if modern else -100
	node.direction = direction
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_sfx("hammer_throw", global_position)
	if $TrackJoint.is_attached:
		get_parent().owner.add_sibling(node)
	else:
		add_sibling(node)

func modern_hammers() -> void:
	sprite.play("Hammer")
	$Hammer.show()
	await get_tree().create_timer(0.5, false).timeout
	for i in randi_range(3, 6):
		sprite.play("Hammer")
		$Hammer.show()
		if ignore_flag_die:
			sprite.play("Idle")
			$Hammer.hide()
			return
		await get_tree().create_timer(0.1, false).timeout
		if ignore_flag_die:
			sprite.play("Idle")
			$Hammer.hide()
			return
		spawn_hammer()
		sprite.play("Idle")
		$Hammer.hide()
		await get_tree().create_timer(0.1, false).timeout

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
		AudioManager.play_global_sfx("bowser_fall")
	else:
		$GibSpawner.gib_type = 0
	# guzlad: ugly but it'll have to do until we move the metadata stuff to actual variables
	if ((Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL) or (Global.current_game_mode == Global.GameMode.LEVEL_EDITOR)) and !is_real:
		$SpriteScaleJoint/DeathSprite/ResourceSetterNew.resource_json = load("res://Assets/Sprites/Enemies/Goomba.json")
