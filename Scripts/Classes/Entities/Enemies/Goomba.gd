extends Enemy

var can_move := true

## Determines how many hits this enemy can take.
@export var hit_count := 1
## Determines how much the enemy's speed will be multiplied by when hit.
@export var move_speed_mult_on_hit := 2
## Determines the animation method this enemy will use when dying.
@export_enum("Stomped", "Gib") var stomp_death_style := 0

var can_turn := false

func _ready() -> void:
	$Sprite.play("Walk")

func _physics_process(_delta: float) -> void:
	if can_turn:
		$Sprite.scale.x = direction

func stomped_on(player: Player) -> void:
	AudioManager.play_sfx("enemy_stomp", global_position)
	DiscoLevel.combo_amount += 1
	player.enemy_bounce_off()
	hit_count -= 1
	if hit_count <= 0:
		enemy_death(player)
	else:
		hit(player)

func damage(object: Node2D) -> void:
	if hit_count <= 0:
		die_from_object(object)
		$ScoreNoteSpawner.spawn_note(200)
		return
	AudioManager.play_sfx("kick", global_position)
	velocity.y = -150
	hit(object)

func hit(object: Node2D) -> void:
	direction = sign(global_position.x - object.global_position.x)
	hit_count -= 1
	$Sprite.play("Angry")
	$BasicEnemyMovement.move_speed *= move_speed_mult_on_hit

func enemy_death(player: Player):
	if stomp_death_style == 0:
		can_move = false
		$BasicEnemyMovement.can_move = false
		$Sprite.play("Stomped")
		$Hitbox.queue_free()
		await get_tree().create_timer(0.5, false).timeout
		queue_free()
	else:
		$GibSpawner.stomp_die(player)
