class_name Burner
extends AnimatableBody2D

@export_enum("Up", "Down", "Left", "Right") var direction := 0

var can_burn := true

var turned_on = true


func start() -> void:
	if $SignalExposer.total_inputs <= 0:
		$Timer.start()

func do_cycle() -> void:
	if can_burn == false:
		return
	can_burn = false
	if BooRaceHandler.countdown_active == false:
		if $OnScreen.is_on_screen():
			AudioManager.play_sfx("burner", global_position)
		do_animation()
		await get_tree().create_timer(0.25, false).timeout
		%Shape.set_deferred("disabled", false)
		await get_tree().create_timer(1.5, false).timeout
	%Shape.set_deferred("disabled", true)
	if $SignalExposer.total_inputs <= 0:
		$Timer.start()
		can_burn = true

func do_animation() -> void:
	%Flame.show()
	%Flame.play("Rise")
	await %Flame.animation_finished
	%Flame.play("Loop")
	await get_tree().create_timer(1, false).timeout
	%Flame.play("Fall")
	await %Flame.animation_finished
	%Flame.hide()
	can_burn = true

func turn_on() -> void:
	can_burn = false
	if $OnScreen.is_on_screen():
		AudioManager.play_sfx("burner", global_position)
	turned_on = true
	%Flame.show()
	%Flame.play("Rise")
	turn_on_collision()
	await %Flame.animation_finished
	if turned_on:
		%Flame.play("Loop")

func turn_off() -> void:
	turned_on = false
	%Flame.show()
	%Flame.play("Fall")
	turn_off_collision()
	await %Flame.animation_finished
	if not turned_on:
		%Flame.hide()
		can_burn = true

func turn_on_collision() -> void:
	await get_tree().create_timer(0.25, false).timeout
	%Shape.set_deferred("disabled", false)

func turn_off_collision() -> void:
	await get_tree().create_timer(0.25, false).timeout
	%Shape.set_deferred("disabled", true)

func damage_player(player: Player, type: String = "Normal") -> void:
	player.damage(type if type != "Normal" else "")
