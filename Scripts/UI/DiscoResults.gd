extends Control

const RANK_MESSAGES = ["F_RANK_MESSAGE", "D_RANK_MESSAGE", "C_RANK_MESSAGE", "B_RANK_MESSAGE", "A_RANK_MESSAGE", "S_RANK_MESSAGE", "P_RANK_MESSAGE"]

var selected_index := 0

func _ready() -> void:
	pass

func open() -> void:
	setup_visuals()
	show()
	set_focus(true)
	await get_tree().physics_frame
	[%Continue, %Retry, %LevelSelect, %ReturnMenu][selected_index].grab_focus()

func setup_visuals() -> void:
	%Score.text = str(Global.score)
	var rank_idx = DiscoLevel.RANK_IDs.find(DiscoLevel.current_rank)
	%Medal.region_rect.position.x = 16 * (rank_idx + 1)
	%RankMessage.text = RANK_MESSAGES[rank_idx]
	%RankMessage.modulate = GameHUD.RANK_COLOURS[DiscoLevel.current_rank]

func close() -> void:
	hide()

func set_focus(enabled := false) -> void:
	for i in [%Continue, %Retry, %LevelSelect, %ReturnMenu]:
		i.focus_mode = 0 if enabled == false else 2

func continue_to_next_level() -> void:
	if Global.world_num == 8 and Global.level_num == 4:
		go_to_menu()
		return
	Global.current_level.transition_to_next_level()
	Global.disco_level_continued.emit()
	close()

func set_index(idx := 0) -> void:
	selected_index = idx

func restart_level() -> void:
	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
	Global.reset_values()
	DiscoLevel.reset_values()
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")
	close()

func go_to_menu() -> void:
	Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
	close()
