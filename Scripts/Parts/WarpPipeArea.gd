@tool
class_name WarpPipeArea
extends PipeArea

@export_range(1, 12) var world_num := 1:
	set(value):
		world_num = value
		update_visuals()
@export_range(1, 4) var level_num := 1:
	set(value):
		level_num = value
		update_visuals()

@export_range(0, 99) var level_id := 0

static var has_warped := false

func _ready() -> void:
	update_visuals()
	has_warped = false

func update_visuals() -> void:
	if Engine.is_editor_hint() or (Global.current_game_mode == Global.GameMode.LEVEL_EDITOR):
		$ArrowJoint.show()
		$ArrowJoint.rotation = get_vector(enter_direction).angle() - deg_to_rad(90)
		$ArrowJoint/Arrow.flip_v = exit_only
		$Node2D/CenterContainer/Label.text = "LVL " + str(level_id)
	else:
		hide()

func run_player_check(player: Player) -> void:
	if Global.player_action_pressed(get_input_direction(enter_direction), player.player_id) and can_enter:
		can_enter = false
		Checkpoint.passed_checkpoints.clear()
		SpeedrunHandler.is_warp_run = true
		Global.reset_values()
		Level.first_load = true
		has_warped = true
		player.enter_pipe(self, 
		Global.current_game_mode != Global.GameMode.MARATHON_PRACTICE and Global.current_campaign != "SMBANN",
		Global.in_custom_campaign() or (Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL) or (Global.current_game_mode == Global.GameMode.LEVEL_EDITOR))
		if (Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL):
			Global.can_time_tick = false
			AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.SILENCE, 99, false)
			await get_tree().create_timer(1, false).timeout
			if !Global.inf_time:
				Global.tally_time()
				if Global.tallying_score:
					await Global.score_tally_finished
			await get_tree().create_timer(1, false).timeout
			Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")
			return
		elif Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
			Global.can_time_tick = false
			AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.SILENCE, 99, false)
			await get_tree().create_timer(2, false).timeout
			Global.level_editor.stop_testing()
			return
		elif Global.in_custom_campaign():
			Global.can_time_tick = false
			await get_tree().create_timer(1, false).timeout
			Checkpoint.passed_checkpoints.clear()
			Global.reset_values()
			LevelEditor.sub_areas = [null, null, null, null, null]
			Global.custom_level_idx = level_id
			var arr = get_new_level_world_nums_from_idx(level_id)
			Global.world_num = arr[0]
			Global.level_num = arr[1]
			Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")
			return
		elif Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
			SpeedrunHandler.run_finished()
			await get_tree().create_timer(1, false).timeout
			Global.open_marathon_results()
			return
		elif Global.current_game_mode == Global.GameMode.DISCO:
			Global.current_level.get_node("DiscoLevel").level_finished()
			await get_tree().create_timer(1, false).timeout
			AudioManager.stop_all_music()
			Global.tally_time()
			await Global.score_tally_finished
			Global.open_disco_results()
			await Global.disco_level_continued
			Global.level_num = level_num
			Global.world_num = world_num
			LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
			return
		await owner.tree_exiting
		if Global.current_game_mode != Global.GameMode.MARATHON_PRACTICE:
			Global.level_num = level_num
			Global.world_num = world_num
		LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)

func get_new_level_world_nums_from_idx(idx := 0) -> Array:
	var arr := [1, 1]
	var campaign_json = Global.custom_campaign_jsons[Global.current_custom_campaign]
	var lvls_per_world = campaign_json.levels_per_world[0]
	for i in idx:
		arr[1] += 1
		if arr[1] > lvls_per_world:
			arr[1] = 1
			lvls_per_world = campaign_json.levels_per_world[arr[0] - 1]
			arr[0] += 1
	return arr
