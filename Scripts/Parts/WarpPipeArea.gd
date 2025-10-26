@tool
class_name WarpPipeArea
extends PipeArea

@export var world_num := 1:
	set(value):
		world_num = value
		update_visuals()
@export var level_num := 1:
	set(value):
		level_num = value
		update_visuals()

static var has_warped := false

func _ready() -> void:
	update_visuals()
	has_warped = false

func update_visuals() -> void:
	if Engine.is_editor_hint():
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
		player.enter_pipe(self, Global.current_game_mode != Global.GameMode.MARATHON_PRACTICE and Global.current_campaign != "SMBANN")
		if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
			SpeedrunHandler.run_finished()
			await get_tree().create_timer(1, false).timeout
			Global.open_marathon_results()
			return
		elif Global.current_campaign == "SMBANN":
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
	
