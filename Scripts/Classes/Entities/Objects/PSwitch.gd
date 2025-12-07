extends CharacterBody2D

var is_pressed := false

func on_player_entered(player: Player) -> void:
	if player.velocity.y >= 0:
		pressed()

func pressed() -> void:
	if is_pressed:
		return
	is_pressed = true
	$Sprite.play("Pressed")
	AudioManager.play_global_sfx("switch")
	AudioManager.play_global_sfx("pswitch_pressed")
	$AnimationPlayer.play("Pressed")
	Global.activate_p_switch()
