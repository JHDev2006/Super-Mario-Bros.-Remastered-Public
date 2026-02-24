extends Node2D

@export_range(-8.0, 8.0, 0.1) var horizontal_speed := 0.0:
	set(value):
		horizontal_speed = value

@export_range(-8.0, 8.0, 0.1) var upwards_speed := 0.0:
	set(value):
		upwards_speed = value

@export var relative_to_direction := false
@export var additive := true

func launch() -> void:
	if get_tree():
		for i: Player in get_tree().get_nodes_in_group("Players"):
			i.has_flung = true
			if additive:
				i.velocity.y = i.velocity.y + upwards_speed*-100
				if relative_to_direction:
					i.velocity.x = i.velocity.x + horizontal_speed*50*i.direction
				else:
					i.velocity.x = i.velocity.x + horizontal_speed*50
			else:
				if upwards_speed != 0:
					i.velocity.y = upwards_speed*-100
				if horizontal_speed != 0:
					if relative_to_direction:
						i.velocity.x = horizontal_speed*50*i.direction
					else:
						i.velocity.x = horizontal_speed*50
