extends CharacterBody2D

var is_pressed := false

signal switch_pressed

@export var one_time := true

func on_player_entered(player: Player) -> void:
	if player.velocity.y >= 0:
		pressed(one_time)

func pressed(destroy := true) -> void:
	if is_pressed:
		return
	switch_pressed.emit()
	for i in [$LCollision, $RCollision]:
		i.set_deferred("disabled", true)
	is_pressed = true
	$Sprite.play("Pressed")
	AudioManager.play_global_sfx("switch")
	AudioManager.play_global_sfx("pswitch_pressed")
	$AnimationPlayer.play("Pressed")
	Global.activate_p_switch()
	await get_tree().create_timer(0.5, false).timeout
	if destroy:
		delete()
	else:
		Global.p_switch_toggle.connect(restore, CONNECT_ONE_SHOT)

func restore() -> void:
	$Sprite.play("Idle")
	for i in [$LCollision, $RCollision]:
		i.set_deferred("disabled", false)
	is_pressed = false

func delete() -> void:
	queue_free()
	$GibSpawner.summon_poof()

func bump_up() -> void:
	velocity.y = -150
