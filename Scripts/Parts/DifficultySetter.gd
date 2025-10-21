extends Node

func damage_style_changed(new_value := 0) -> void:
	Settings.file.difficulty.damage_style = new_value

func checkpoint_changed(new_value := 0) -> void:
	Settings.file.difficulty.checkpoint_style = new_value

func inf_lives_changed(new_value := 0) -> void:
	Settings.file.difficulty.inf_lives = new_value

func flag_lives_changed(new_value := 0) -> void:
	Settings.file.difficulty.flagpole_lives = new_value

func time_limit_changed(new_value := 0) -> void:
	Settings.file.difficulty.time_limit = new_value

func game_over_changed(new_value := 0) -> void:
	Settings.file.difficulty.game_over_behaviour = new_value

func backscroll_changed(new_value := 0) -> void:
	Settings.file.difficulty.back_scroll = new_value

func level_design_changed(new_value := 0) -> void:
	Settings.file.difficulty.level_design = new_value

func extra_checkpoints_changed(new_value := 0) -> void:
	Settings.file.difficulty.extra_checkpoints = new_value

func lakitu_style_changed(new_value := 0) -> void:
	Settings.file.difficulty.lakitu_style = new_value
	
func physics_style_changed(new_value := 0) -> void:
	Settings.file.difficulty.physics_style = new_value
	for player in get_tree().get_nodes_in_group("Players"):
		player.apply_physics_style()

func set_value(value_name := "", value := 0) -> void:
	{
		"damage_style": damage_style_changed,
		"checkpoint_style": checkpoint_changed,
		"inf_lives": inf_lives_changed,
		"flagpole_lives": flag_lives_changed,
		"game_over": game_over_changed,
		"level_design": level_design_changed,
		"extra_checkpoints": extra_checkpoints_changed,
		"back_scroll": backscroll_changed,
		"physics_style": physics_style_changed
	}[value_name].call(value)
