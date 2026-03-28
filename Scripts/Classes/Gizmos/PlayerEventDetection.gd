extends Node2D

@export_enum("Jump", "Crouch", "Attack", "Damaged", "Powerup_Get", "Land") var event := 0

signal event_triggered

func connect_signals() -> void:
	for i: Player in get_tree().get_nodes_in_group("Players"):
		match event:
			0:
				i.jumped.connect(event_triggered.emit)
			1:
				i.crouch_started.connect(event_triggered.emit)
			2:
				i.attacked.connect(event_triggered.emit)
			3:
				i.damaged.connect(event_triggered.emit)
			4:
				i.powered_up.connect(event_triggered.emit)
			5:
				i.landed.connect(event_triggered.emit)
