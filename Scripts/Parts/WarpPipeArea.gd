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

static var has_warped := false

func _ready() -> void:
	update_visuals()
	has_warped = false

func update_visuals() -> void:
	if (Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL):
		$Node2D/CenterContainer/Label.text = "EXIT"
		$ArrowJoint.hide()
		$Node2D/ColorRect.hide()
	elif Global.in_custom_campaign():
		$ArrowJoint.hide()
		$Node2D/ColorRect.hide()
		$Node2D/CenterContainer/Label.text = str(world_num) + "-" + str(level_num)
	elif Engine.is_editor_hint() or (Global.current_game_mode == Global.GameMode.LEVEL_EDITOR):
		$ArrowJoint.show()
		$ArrowJoint.rotation = get_vector(enter_direction).angle() - deg_to_rad(90)
		$ArrowJoint/Arrow.flip_v = exit_only
		$Node2D/CenterContainer/Label.text = str(world_num) + "-" + str(level_num)
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
			AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.SILENCE, 99, false)
			await get_tree().create_timer(1, false).timeout
			if !Global.inf_time:
				Global.tally_time()
				if Global.tallying_score:
					await Global.score_tally_finished
			await get_tree().create_timer(1, false).timeout
			
			Checkpoint.passed_checkpoints.clear()
			Global.reset_values()
			
			NewLevelBuilder.sub_levels = [null, null, null, null, null]
			Global.level_num = level_num
			Global.world_num = world_num
			var level_file_name = Global.custom_campaign_jsons[Global.current_custom_campaign].levels[SaveManager.get_level_idx(Global.world_num, Global.level_num)]
			var path = Global.config_path.path_join("level_packs").path_join(Global.current_custom_campaign).path_join(level_file_name)
			Global.custom_level_idx = SaveManager.get_level_idx(world_num,level_num)
			Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")
			# Global.transition_to_scene(Level.get_scene_string(Global.world_num, Global.level_num))
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
	
