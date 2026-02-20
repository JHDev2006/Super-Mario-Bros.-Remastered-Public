class_name Projectile
extends Enemy

## Determines if this projectile deals damage to the player or not.
@export var is_friendly := false
## Which particle scene to load.
@export var PARTICLE: Resource = null
## Determines the offset of the particle when it is created.
@export var PARTICLE_OFFSET: Vector2 = Vector2(0, 0)
## Determines if the projectile will display a particle upon making contact with something, but hasn't been destroyed.
@export var PARTICLE_ON_CONTACT := false
## Determines what sound will play when the projectile makes contact with something.
@export var SFX_COLLIDE := ""
## Determines how many entities a projectile can hit before being destroyed. Negative values are considered infinite.
@export var PIERCE_COUNT: int = -1
## Determines how much time must pass in seconds before the projectile can hit the same enemy it is currently intersecting with again. Negative values are considered infinite.
@export var PIERCE_HITRATE := -1
## Determines how many times a projectile can bounce on tiles before being destroyed. Negative values are considered infinite.
@export var BOUNCE_COUNT: int = -1
## Controls if the projectile will make contact with the environment.
@export var HAS_COLLISION := false
## Controls if the projectile will bounce on the ground rather than being destroyed.
@export var GROUND_BOUNCE := false
## Controls if the projectile will bounce off of walls rather than being destroyed.
@export var WALL_BOUNCE := false
## Controls if the projectile will bounce off the ceiling rather than being destroyed.
@export var CEIL_BOUNCE := false
## Controls if the projectile will collect coins when it comes in contact with them.
@export var COLLECT_COINS := false
## Controls how long the projectile will exist for in seconds.
@export var LIFETIME := -1
## Controls the speed of the projectile.
@export var MOVE_SPEED := 0
## Controls the maximum speed of the projectile.
@export var MOVE_SPEED_CAP := [-INF, INF]
## Controls the initial angle the projectile travels at.
@export var MOVE_ANGLE: Vector2 = Vector2.ZERO
## Controls the amount of deceleration the projectile will experience on the ground.
@export var GROUND_DECEL := 0
## Controls the amount of deceleration the projectile will experience in the air.
@export var AIR_DECEL := 0
## Controls the value of gravity the projectile will experience.
@export var GRAVITY := 0
## Controls the velocity the projectile will gain when bouncing off of the floor or ceiling.
@export var BOUNCE_HEIGHT := 0
## Controls the maximum speed the projectile can fall at.
@export var MAX_FALL_SPEED := 280.0

func _ready() -> void:
	var collision = get_node_or_null("Collision")
	if not HAS_COLLISION and collision != null: collision.disabled = true
	if LIFETIME >= 0:
		await get_tree().create_timer(LIFETIME).timeout
		hit(true, true)
	await get_tree().physics_frame
	if get_node_or_null("VisibleOnScreenNotifier2D") != null:
		if get_node_or_null("VisibleOnScreenNotifier2D").is_on_screen() == false:
			queue_free()

func _physics_process(delta: float) -> void:
	$Sprite.flip_h = direction == 1
	handle_movement(delta)

func handle_movement(delta: float) -> void:
	var CUR_GRAVITY = GRAVITY * (Global.entity_gravity * 0.1)
	var DECEL_TYPE = GROUND_DECEL if is_on_floor() else AIR_DECEL
	if MOVE_ANGLE == Vector2.ZERO:
		velocity.y += (CUR_GRAVITY / delta) * delta
		velocity.y = clamp(velocity.y, -INF, MAX_FALL_SPEED)
	if HAS_COLLISION:
		projectile_bounce()
	MOVE_SPEED = clamp(move_toward(MOVE_SPEED, 0, (DECEL_TYPE / delta) * delta), MOVE_SPEED_CAP[0], MOVE_SPEED_CAP[1])
	velocity.x = MOVE_SPEED * direction
	if MOVE_ANGLE != Vector2.ZERO:
		velocity = MOVE_ANGLE * velocity.length()
	move_and_slide()

func projectile_bounce() -> void:
	if get_slide_collision_count() <= 0:
		return
	if BOUNCE_COUNT != 0:
		BOUNCE_COUNT -= 1
	else:
		hit(true, true)
		return
	if is_on_floor() and GROUND_BOUNCE:
		if not GROUND_BOUNCE: hit(true, true)
		velocity.y = -BOUNCE_HEIGHT
	if is_on_ceiling() and CEIL_BOUNCE:
		if not CEIL_BOUNCE: hit(true, true)
		velocity.y = BOUNCE_HEIGHT
	if is_on_wall():
		if not WALL_BOUNCE: hit(true, true)
		direction *= -1

func damage_player(player: Player, type: String = "Normal") -> void:
	if !is_friendly:
		player.damage(type if type != "Normal" else "")
		hit()

func hit(play_sfx := true, force_destroy := false) -> void:
	if play_sfx and SFX_COLLIDE != "":
		AudioManager.play_sfx(SFX_COLLIDE, global_position)
	if PIERCE_COUNT == 0 or BOUNCE_COUNT == 0 or force_destroy:
		summon_explosion()
		queue_free()
	else:
		var hitbox = get_node_or_null("Hitbox")
		PIERCE_COUNT -= 1
		if PARTICLE_ON_CONTACT: summon_explosion()
		if PIERCE_HITRATE >= 0 and hitbox != null:
			hitbox.monitoring = false
			await get_tree().create_timer(PIERCE_HITRATE, false).timeout
			hitbox.monitoring = true

func summon_explosion() -> void:
	if PARTICLE is PackedScene and PARTICLE.can_instantiate():
		var node = PARTICLE.instantiate()
		node.global_position = global_position + PARTICLE_OFFSET
		add_sibling(node)
