class_name PlayerDetection
extends Area2D

signal player_entered(player: Player)
signal player_exited(player: Player)

func _ready() -> void:
	area_entered.connect(on_area_entered)
	area_exited.connect(on_area_exited)

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player and area.name != "HammerHitbox":
		player_entered.emit(area.owner)

func on_area_exited(area: Area2D) -> void:
	if area.owner is Player and area.name != "HammerHitbox":
		player_exited.emit(area.owner)

func is_player_in_area() -> bool:
	return get_overlapping_areas().any(func(area: Area2D) -> bool: return area.owner is Player)
