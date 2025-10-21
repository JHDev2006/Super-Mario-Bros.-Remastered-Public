extends AnimatableBody2D

@export_enum("Up", "Down", "Left", "Right") var direction := 0

func _ready() -> void:
	$Timer.start()

func do_cycle() -> void:
	if BooRaceHandler.countdown_active == false:
		AudioManager.play_sfx("burner", global_position)
		do_animation()
		await get_tree().create_timer(0.25, false).timeout
		%Shape.set_deferred("disabled", false)
		await get_tree().create_timer(1.5, false).timeout
	%Shape.set_deferred("disabled", true)
	$Timer.start()

func do_animation() -> void:
	%Flame.show()
	%Flame.play("Rise")
	await %Flame.animation_finished
	%Flame.play("Loop")
	await get_tree().create_timer(1, false).timeout
	%Flame.play("Fall")
	await %Flame.animation_finished
	%Flame.hide()

func damage_player(player: Player) -> void:
	player.damage()
