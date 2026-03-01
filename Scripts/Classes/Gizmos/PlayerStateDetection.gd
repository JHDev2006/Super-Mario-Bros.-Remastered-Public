extends Node2D

@export_enum("On Floor", "On Wall", "On Ceiling", "Is Falling", "Is Small", "Is Big", "Is Fire", "Is Superball", "Is Facing Left", "Is Facing Right", "Is Going Left", "Is Going Right") var state_to_detect := 0

signal turned_on
signal turned_off

var active := false

func _physics_process(_delta: float) -> void:
	for i in get_tree().get_nodes_in_group("Players"):
		var player: Player = i
		match state_to_detect:
			0:
				run_check(player.is_actually_on_floor())
			1:
				run_check(player.is_actually_on_wall())
			2:
				run_check(player.is_actually_on_ceiling())
			3:
				run_check(player.velocity.y * player.gravity_vector.y > 0)
			4:
				run_check(player.power_state.state_name == "Small")
			5:
				run_check(player.power_state.state_name == "Big")
			6:
				run_check(player.power_state.state_name == "Fire")
			7:
				run_check(player.power_state.state_name == "Superball")
			8:
				run_check(player.direction == -1)
			9:
				run_check(player.direction == 1)
			10:
				run_check(player.velocity_direction == -1)
			11:
				run_check(player.velocity_direction == 1)

func run_check(check := false) -> void:
	if check:
		if not active:
			turned_on.emit()
		active = true
	else:
		if active:
			turned_off.emit()
		active = false
