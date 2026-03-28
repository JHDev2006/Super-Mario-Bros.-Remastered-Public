extends Node2D

@export_range(-8.0, 8.0, 0.1) var horizontal_speed := 0.0:
	set(value):
		horizontal_speed = value

@export_range(-8.0, 8.0, 0.1) var upwards_speed := 0.0:
	set(value):
		upwards_speed = value

@export var relative_to_direction := false
@export var additive := true
@export var update_player_direction := true

var active := false
var launched_this_frame := false

func _physics_process(_delta: float) -> void:
	if active:
		launch()
	launched_this_frame = false

func turn_on() -> void:
	active = true
	launch() # necessary for zero frame pulses in certain scenarios

func turn_off() -> void:
	active = false

func launch() -> void:
	if launched_this_frame:
		return
	if get_tree():
		for i: Player in get_tree().get_nodes_in_group("Players"):
			i.has_flung = true
			launched_this_frame = true
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
			if update_player_direction:
				if i.velocity.x != 0:
					i.direction = sign(i.velocity.x)
				if i.velocity.y < 0:
					i.gravity = i.calculate_speed_param("JUMP_GRAVITY")
					i.jump_cancelled = false
