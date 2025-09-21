extends PlayerState

var hang_time := 0.0
var is_hanging := false

var grounded_time := 0.0
var GROUNDED_LENIENCY := 0.03

var ground_collision: Area2D

func enter(msg := {}) -> void:
	player.velocity = Vector2.ZERO
	player.velocity.y = -player.GROUND_POUND_HANG_SPEED * player.gravity_vector.y
	player.is_pounding = true
	
	ground_collision = player.find_child("GroundBlockCollision")
	hang_time = player.GROUND_POUND_HANG_TIME
	grounded_time = 0.0
	is_hanging = true
	
	AudioManager.play_sfx("ground_pound_start", player.global_position)

func physics_update(_delta: float) -> void:
	player.play_animation("GroundPound")
	
	if is_hanging:
		player.velocity.y = move_toward(player.velocity.y, 0, player.GROUND_POUND_HANG_DECEL * 60 * _delta)
		hang_time -= _delta
		if hang_time <= 0:
			is_hanging = false
	else:
		player.velocity.y = player.GROUND_POUND_FALL_SPEED * player.gravity_vector.y
		
		if Global.player_action_pressed("move_up"):
			player.state_machine.transition_to("Normal")
			return
		
		if player.is_on_floor():
			var is_big := player.power_state.hitbox_size == "Big"
			var hit_block := false
			for i in ground_collision.get_overlapping_bodies():
				if i is Block:
					if is_big:
						if i is BrickBlock and not hit_block and not i.item:
							AudioManager.play_sfx("ground_pound_land", player.global_position)
							hit_block = true
					i.player_block_hit.emit(player)
			
			if not (hit_block and Global.player_action_pressed("move_down")):
				grounded_time += _delta
				if grounded_time >= GROUNDED_LENIENCY:
					player.state_machine.transition_to("Normal")
					AudioManager.play_sfx("ground_pound_land", player.global_position)
			else:
				grounded_time = 0.0
		else:
			grounded_time = 0.0
	
	player.move_and_slide()

func exit() -> void:
	player.is_pounding = false
