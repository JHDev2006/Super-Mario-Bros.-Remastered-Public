extends Node

@export var reset_level := false

@export var has_menu := false

var can_continue := false

func _enter_tree() -> void:
	Global.level_theme = "Underground"
	Global.level_theme_changed.emit()
	AudioManager.stop_all_music()

func _ready() -> void:
	get_tree().paused = false
	Global.lives = clamp(Global.lives, 0, 99)
	SpeedrunHandler.timer_active = false
	await get_tree().create_timer(0.1).timeout
	can_continue = true

func _process(_delta: float) -> void:
	print(can_continue)
	if Input.is_action_just_pressed("jump_0") and can_continue:
		can_continue = false
		if Global.transitioning_scene:
			await Global.transition_finished
			await get_tree().create_timer(0.15, false).timeout
		go_back_to_title()


func go_back_to_title() -> void:
	if has_menu:
		$Timer.queue_free()
		has_menu = false
		$CanvasLayer/VBoxContainer.show()
		$CanvasLayer/VBoxContainer/SelectableLabel.grab_focus()
	elif not reset_level:
		quit_to_menu()
	else:
		continue_on()

func continue_on() -> void:
	reset_values()
	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func quit_to_menu() -> void:
	reset_values()
	Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func reset_values() -> void:
	if Global.world_num <= 8:
		ChallengeModeHandler.current_run_red_coins_collected = 0
	Global.lives = 3
	Global.score = 0
	Global.player_power_states = "0000"
	Global.coins = 0
	if Global.current_game_mode == Global.GameMode.CHALLENGE:
		return
	match Settings.file.difficulty.game_over_behaviour:
		0:
			Global.level_num = 1
		1:
			pass
		2:
			Global.level_num = 1
			Global.world_num = 1
	Global.reset_values()
	SaveManager.write_save()
