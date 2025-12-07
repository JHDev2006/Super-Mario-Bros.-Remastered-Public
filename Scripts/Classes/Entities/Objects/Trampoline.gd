extends AnimatableBody2D

@export var trampoline_type := "TRAMPOLINE"

var players := []

func on_area_entered(area: Area2D) -> void:
	pass

func _physics_process(_delta: float) -> void:
	for i in $Hitbox.get_overlapping_areas():
		if i.owner is Player and i.owner.is_on_floor():
			if i.owner.spring_bouncing or i.owner.velocity.y < 0:
				continue
			i.owner.velocity.x = 0
			if players.has(i.owner) == false:
				players.append(i.owner)
				$Animation.play("Bounce")
				i.owner.spring_bouncing = true
	for i in players:
		i.global_position.y = $PlayerCollision/PlayerJoint.global_position.y

func bounce_players() -> void:
	for player in players:
		player.has_spring_jumped = true
		if Global.player_action_pressed("jump", player.player_id):
			player.velocity.y = -player.physics_params(trampoline_type + "_SPEED")
			player.gravity = player.calculate_speed_param("JUMP_GRAVITY")
			player.has_jumped = true
			AudioManager.play_sfx(player.physics_params("TRAMPOLINE_USED_SFX", player.COSMETIC_PARAMETERS), global_position)
		else:
			player.velocity.y = -player.calculate_speed_param("JUMP_SPEED")
			AudioManager.play_sfx(player.physics_params("TRAMPOLINE_SFX", player.COSMETIC_PARAMETERS), global_position)
	players.clear()

func on_area_exited(area: Area2D) -> void:
	if area.owner is Player:
		area.owner.spring_bouncing = false
