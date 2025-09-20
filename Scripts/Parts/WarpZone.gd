class_name WarpZone
extends Node

@export var enable_sides := true

@export var pipe_destinations := [-1, -1, -1]

func _ready() -> void:
	if enable_sides == false:
		$Pipes/Right.queue_free()
		$Pipes/Left.queue_free()
	var idx := 0
	for i in [$Pipes/Left/TextLabel, $Pipes/Middle/TextLabel, $Pipes/Right/TextLabel]:
		if pipe_destinations[idx] > 9:
			i.text = ["A", "B", "C", "D"][int(pipe_destinations[idx]) % 10]
		else:
			i.text = str(pipe_destinations[idx])
		idx += 1

func activate() -> void:
	for i in get_tree().get_nodes_in_group("Labels"):
		i.show()
	for i in get_tree().get_nodes_in_group("Plants"):
		i.queue_free()
	if enable_sides:
		$Pipes/Left/Pipe.world_num = pipe_destinations[0]
		$Pipes/Right/Pipe.world_num = pipe_destinations[2]
	$Pipes/Middle/Pipe.world_num = pipe_destinations[1]
