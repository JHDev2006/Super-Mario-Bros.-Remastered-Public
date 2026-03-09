class_name BubbleProjectile
extends Projectile

func _physics_process(delta: float) -> void:
	# $Sprite.flip_h = direction == 1
	handle_movement(delta)


func on_player_stomped(player: Player) -> void:
	AudioManager.play_sfx("bubble_bounce", global_position)
	DiscoLevel.combo_amount += 1
	player.enemy_bounce_off(false,false)
	hit(false,true)
