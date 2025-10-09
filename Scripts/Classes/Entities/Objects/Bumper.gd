extends Node2D

const LOW_STRENGTH := -300
const HIGH_STRENGTH := -450

func bounce_player(player: Player) -> void:
	$Sprite.play("Bounce")
	$AnimationPlayer.stop()
	if player.global_position.y + 8 < global_position.y:
		player.velocity.x *= 0.8
		if Global.player_action_pressed("jump", player.player_id):
			player.gravity = player.JUMP_GRAVITY
			player.jump_cancelled = false
			player.velocity.y = HIGH_STRENGTH
			player.jump_type = player.JumpType.STANDARD
			player.has_jumped = true
			AudioManager.play_sfx("bumper_high", global_position)
		else:
			AudioManager.play_sfx("bumper", global_position)
			player.velocity.y = LOW_STRENGTH
	else:
		player.velocity = global_position.direction_to(player.global_position) * 200
		if Global.player_action_pressed("jump", player.player_id):
			player.gravity = player.JUMP_GRAVITY
			player.velocity.y = LOW_STRENGTH
			player.has_jumped = true
			AudioManager.play_sfx("bumper_high", global_position)
		else:
			AudioManager.play_sfx("bumper", global_position)
	refresh_hitbox()
	$AnimationPlayer.play("Bounce")
	await $AnimationPlayer.animation_finished
	$Sprite.play("Idle")

func refresh_hitbox() -> void:
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	await get_tree().physics_frame
	$Hitbox/CollisionShape2D.set_deferred("disabled", false)
	
