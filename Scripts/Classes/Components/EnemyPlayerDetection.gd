class_name EnemyPlayerDetection
extends Node

@export var hitbox: Area2D = null

@export var height := 4

signal player_hit(player: Player)
signal player_stomped_on(player: Player)
signal player_stomped_below(player: Player)
signal invincible_player_hit(player: Player)
signal hammer_player_hit(player: Player)

func _ready() -> void:
	hitbox.area_entered.connect(area_entered)

func area_entered(area: Area2D) -> void:
	if area.owner is Player:
		if area.name == "HammerHitbox":
			hammer_entered(area.owner)
		else:
			player_entered(area.owner)

func player_entered(player: Player) -> void:
	var is_below_player = player.global_position.y + height < owner.global_position.y if player.gravity_vector.y >= 0 else player.global_position.y - height > owner.global_position.y
	if player.is_invincible:
		invincible_player_hit.emit(player)
	elif (player.actual_velocity_y() >= 15 or is_below_player) and player.in_water == false:
		if player.gravity_vector.y >= 0:
			player_stomped_on.emit(player)
		else:
			player_stomped_below.emit(player)
	else:
		player_hit.emit(player)

func hammer_entered(player: Player) -> void:
	if player.has_hammer:
		hammer_player_hit.emit(player)
