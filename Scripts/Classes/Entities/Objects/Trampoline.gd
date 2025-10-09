extends AnimatableBody2D

@export var bounce_height := -500

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
	var high_bounce := false
	for player in players:
		player.jump_type = player.JumpType.TRAMPOLINE
		if Global.player_action_pressed("jump", player.player_id):
			high_bounce = true
			player.velocity.y = bounce_height
			player.gravity = player.JUMP_GRAVITY
			player.has_jumped = true
		else:
			player.velocity.y = -300
	if high_bounce:
		AudioManager.play_sfx("spring", global_position)
	else:
		AudioManager.play_sfx("bump", global_position)
	players.clear()

func on_area_exited(area: Area2D) -> void:
	if area.owner is Player:
		area.owner.spring_bouncing = false
