extends Node2D

@export var play_end_music := false
var can_menu := false
const ENDING = preload("res://Assets/Audio/BGM/Ending.mp3")

var talking := false

func _ready() -> void:
	Global.level_complete_begin.connect(begin)
	for i in [$SpeedrunMSG/ThankYou, $StandardMSG/ThankYou]:
		i.text = tr(i.text).replace("{PLAYER}", tr(Player.CHARACTER_NAMES[int(Global.player_characters[0])]))
	if play_end_music and (Global.level_editor != null or Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL):
		$EndingSpeech/AnotherCastle5.modulate.a = 0
		$EndingSpeech/AnotherCastle6.modulate.a = 0

func begin() -> void:
	$Sprite.play("Await")
	%PBMessage.modulate.a = int(SpeedrunHandler.timer < SpeedrunHandler.best_time)
	if play_end_music:
		Global.game_beaten = true
		SaveManager.write_save()
		play_music()
	%Time.text = tr(%Time.text).replace("{TIME}", SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(SpeedrunHandler.timer)))
	$CameraRightLimit._enter_tree()
	await get_tree().create_timer(3, false).timeout
	$Sprite.play("Talk")
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE or (Global.current_game_mode == Global.GameMode.MARATHON and play_end_music):
		show_message($SpeedrunMSG)
	else:
		show_message($StandardMSG)
	if not play_end_music:
		await get_tree().create_timer(7, false).timeout
		exit_level()

func exit_level() -> void:
	match Global.current_game_mode:
		Global.GameMode.MARATHON_PRACTICE:
			Global.open_marathon_results()
		Global.GameMode.CUSTOM_LEVEL:
			Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")
		Global.GameMode.LEVEL_EDITOR:
			Global.level_editor.stop_testing()
		_:
			if Global.current_campaign == "SMBANN":
				Global.open_disco_results()
				return
			if Global.world_num < 1:
				Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
			else:
				Global.current_level.transition_to_next_level()

func do_tally() -> void:
	pass

func play_music() -> void:
	await AudioManager.music_override_player.finished
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.ENDING, 999999, false)
	if [Global.GameMode.MARATHON, Global.GameMode.MARATHON_PRACTICE].has(Global.current_game_mode) == false:
		show_message($EndingSpeech)
		await get_tree().create_timer(5, false).timeout
		can_menu = true
	else:
		can_menu = true

func _process(_delta: float) -> void:
	if can_menu and Input.is_action_just_pressed("jump_0"):
		can_menu = false
		peach_level_exit()

func show_message(message_node: Node) -> void:
	for i in message_node.get_children():
		i.show()
		await get_tree().create_timer(1).timeout

func peach_level_exit() -> void:
	match Global.current_game_mode:
		Global.GameMode.MARATHON:
			Global.open_marathon_results()
		Global.GameMode.MARATHON_PRACTICE:
			Global.open_marathon_results()
		Global.GameMode.CUSTOM_LEVEL:
			Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")
		Global.GameMode.LEVEL_EDITOR:
			Global.level_editor.play_toggle()
		_:
			if Global.current_campaign == "SMBLL" and Global.world_num == 8:
				Global.current_level.transition_to_next_level()
			elif Global.current_game_mode == Global.GameMode.CAMPAIGN:
				CreditsLevel.go_to_title_screen = true
				Global.transition_to_scene("res://Scenes/Levels/Credits.tscn")
			else: Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func toggle_talking() -> void:
	talking = !talking
	if talking:
		$Sprite.play("Talk")
	else:
		$Sprite.play("Idle")
