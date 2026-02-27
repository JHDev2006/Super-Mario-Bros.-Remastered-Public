extends CharacterBody2D

var is_pressed := false

@export var has_gravity := true
@export_enum("Up", "Down") var direction := 0

signal switch_pressed

func on_player_entered(player: Player) -> void:
	if (player.velocity.y >= 0 and direction == 0) or (player.velocity.y < 0 and direction == 1):
		pressed()

func _physics_process(delta: float) -> void:
	if has_gravity:
		$BasicStaticMovement.handle_movement(delta)

func pressed() -> void:
	if is_pressed:
		return
	switch_pressed.emit()
	for i in [$LCollision, $RCollision]:
		i.set_deferred("disabled", true)
	is_pressed = true
	$Sprite.play("Pressed")
	AudioManager.play_global_sfx("switch")
	$AnimationPlayer.play("Pressed")

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
