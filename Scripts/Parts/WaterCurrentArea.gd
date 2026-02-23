extends Node2D

@export var strength := 3

func _ready() -> void:
	$Particles.amount = 32 * scale.x

func _physics_process(delta: float) -> void:
	for i in $Hitbox.get_overlapping_areas():
		if i.owner is Player:
			pull_player.call_deferred(i.owner, delta)

func pull_player(player: Player, delta: float) -> void:
	for x in strength:
		player.apply_gravity(delta * 1.5)
	if Settings.file.gameplay.physics_style == 0:
		player.global_position.x += 48 * sign(global_position.x - player.global_position.x) * delta
