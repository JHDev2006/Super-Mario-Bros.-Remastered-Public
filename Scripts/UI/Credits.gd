class_name CreditsLevel
extends Level

func _enter_tree() -> void:
	pass

static var go_to_title_screen := true
static var view_from_menu := false

func _ready() -> void:
	for i in $Labels.get_children():
		i.hide()
	AudioManager.stop_all_music()
	Global.get_node("GameHUD").hide()
	await get_tree().create_timer(1, false).timeout
	do_sequence()

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if $Skip.visible:
			exit()
		else:
			$Skip.show()
			await get_tree().create_timer(2, false).timeout
			$Skip.hide()

func exit() -> void:
	if go_to_title_screen:
		if view_from_menu:
			TitleScreen.return_to = TitleScreen.TITLE_RETURN.EXTRAS
			TitleScreen.return_selected_index = 1
		Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
	else:
		LevelTransition.level_to_transition_to = Level.get_scene_string(9, 1)
		Global.world_num = 8
		Global.world_num = 4
		update_next_level_info()
		transition_to_next_level()

func do_sequence() -> void:
	$Music.play()
	for i in $Labels.get_children():
		i.show()
		if i.has_meta("time"):
			await get_tree().create_timer(i.get_meta("time"), false).timeout
		else:
			await get_tree().create_timer(4, false).timeout
		i.hide()
		await get_tree().create_timer(0.5, false).timeout
	await get_tree().create_timer(5, false).timeout
	exit()
