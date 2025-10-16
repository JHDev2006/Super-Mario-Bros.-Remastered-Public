extends Node2D

@export_range(25, 180) var length := 80
@export_enum("Clockwise", "C-Clockwise") var direction := 0
@export_range(4, 12) var boo_amount := 10
@export var spread_boos := false

func _physics_process(delta: float) -> void:
	%RotationJoint.global_rotation_degrees = wrap(%RotationJoint.global_rotation_degrees + (45 * [1, -1][direction]) * delta, 0, 360)
	for i in $Boos.get_children():
		i.get_node("Sprite").scale.x = sign(get_tree().get_first_node_in_group("Players").global_position.x + 1 - i.global_position.x)
	
func on_area_entered(area: Area2D) -> void:
	if area.owner is Player and area.name != "HammerHitbox":
		area.owner.damage()

func flag_die() -> void:
	queue_free()
