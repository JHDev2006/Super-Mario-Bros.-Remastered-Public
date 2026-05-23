class_name BowserJr
extends Enemy

var health := 3

var fireball_hits := 0

const BOWSER_JR_FIREBALL = preload("uid://b3c6eemy8dmsf")

var target_player: Player = null

func start() -> void:
	$States.transition_to("Idle")

func _physics_process(_delta: float) -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	if target_player != null:
		var target_direction = sign(target_player.global_position.x - global_position.x)
		if target_direction != 0: direction = target_direction
	%Sprite.scale.x = direction

func player_stomped_on(player: Player) -> void:
	if $States.state.name != "Shell":
		damage()
		player.enemy_bounce_off(false, false)
	else:
		damage_player(player)

func damage() -> void:
	health -= 1
	if health > 0:
		AudioManager.play_sfx("enemy_stomp", global_position)
		%DamageAnimation.play("DamageFlash")
		$States.transition_to("Damage")
	else:
		die()

func fireball_hit() -> void:
	if $States.state.name == "Shell":
		return
	fireball_hits += 1
	AudioManager.play_sfx("kick", global_position)
	%DamageAnimation.play("DamageFlash")
	if fireball_hits >= 5:
		fireball_hits = 0
		damage()

func shoot_fire() -> void:
	var fireball = BOWSER_JR_FIREBALL.instantiate()
	AudioManager.play_sfx("bowser_jr_fireball", global_position)
	fireball.global_position = global_position + Vector2(8 * direction, -12)
	fireball.MOVE_ANGLE = global_position.direction_to(target_player.global_position)
	add_sibling(fireball)
