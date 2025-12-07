extends StaticBody2D

@export var is_super := false

func on_player_entered(player: Player) -> void:
	player.enemy_bounce_off(false)
	player.has_spring_jumped = true
	play_animation()
	AudioManager.play_sfx("spring", global_position)
	if is_super:
		await get_tree().physics_frame
		player.velocity.y *= 1.5

func play_animation() -> void:
	$Sprite.play("Bounce")
	await $Sprite.animation_finished
	$Sprite.play("Idle")
