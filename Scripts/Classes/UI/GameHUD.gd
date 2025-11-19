class_name GameHUD
extends CanvasLayer

var current_chara := 0

static var character_icons := [preload("res://Assets/Sprites/Players/Mario/LifeIcon.json"),preload("res://Assets/Sprites/Players/Luigi/LifeIcon.json"), preload("res://Assets/Sprites/Players/Toad/LifeIcon.json"), preload("res://Assets/Sprites/Players/Toadette/LifeIcon.json")]

const RANK_COLOURS := {"F": Color.DIM_GRAY, "D": Color.WEB_MAROON, "C": Color.PALE_GREEN, "B": Color.DODGER_BLUE, "A": Color.RED, "S": Color.GOLD, "P": Color.PURPLE}

var delta_time := 0.0

func _ready() -> void:
	Global.level_theme_changed.connect(update_character_info)

func _process(delta: float) -> void:
	if not get_tree().paused and $Timer.paused:
		delta_time += delta
	if delta_time >= 1:
		delta_time -= 1
		on_timeout()
	handle_main_hud()
	handle_pausing()

func handle_main_hud() -> void:
	$Main.visible = not Settings.file.visuals.modern_hud
	$ModernHUD.visible = Settings.file.visuals.modern_hud
	$Main/RedCoins.hide()
	$Main/CoinCount.show()
	%IGT.hide()
	%Combo.hide()
	$Timer.paused = Settings.file.difficulty.time_limit == 2
	$%Time.show()
	%Stopwatch.hide()
	%PB.hide()
	$Main/CoinCount/KeyCount.visible = KeyItem.total_collected > 0
	%KeyAmount.text = "*" + str(KeyItem.total_collected).pad_zeros(2)
	$Main.set_anchors_preset(Control.PRESET_CENTER_TOP if Settings.file.video.hud_size == 1 else Control.PRESET_TOP_WIDE, true)
	$ModernHUD.set_anchors_preset(Control.PRESET_CENTER_TOP if Settings.file.video.hud_size == 1 else Control.PRESET_TOP_WIDE, true)
	%Score.text = str(Global.score).pad_zeros(6)
	%CoinLabel.text = "*" + str(Global.coins).pad_zeros(2)
	if current_chara != Global.player_characters[0]:
		update_character_info()
	%CharacterIcon.get_node("Shadow").texture = %CharacterIcon.texture
	%ModernLifeCount.text = "*" + (str(Global.lives).pad_zeros(2) if Settings.file.difficulty.inf_lives == 0 else "∞")
	%CharacterIcon.visible = Global.current_game_mode != Global.GameMode.BOO_RACE
	%ModernLifeCount.visible = Global.current_game_mode != Global.GameMode.BOO_RACE
	var world_num := str(Global.world_num)
	if int(world_num) >= 10:
		world_num = ["A", "B", "C", "D"][int(world_num) % 10]
	elif int(world_num) < 1:
		world_num = " "
#	else:
#		print(Global.world_num)
	%LevelNum.text = world_num + "-" + str(Global.level_num)
	%Crown.visible = Global.second_quest
	%Time.text = " " + str(Global.time).pad_zeros(3)
	if Settings.file.difficulty.time_limit == 0:
		%Time.text = " ---"
	%Time.visible = get_tree().get_first_node_in_group("Players") != null
	handle_modern_hud()
	if Global.current_game_mode == Global.GameMode.CHALLENGE:
		handle_challenge_mode_hud()
	
	if DiscoLevel.in_disco_level:
		handle_disco_combo()
	
	if SpeedrunHandler.show_timer:
		handle_speedrun_timer()

func update_character_info() -> void:
	%CharacterName.text = tr(Player.CHARACTER_NAMES[int(Global.player_characters[0])])
	%CharacterIcon.get_node("ResourceSetterNew").resource_json = (character_icons[int(Global.player_characters[0])])
	current_chara = Global.player_characters[0]

func handle_modern_hud() -> void:
	$ModernHUD/TopLeft/RedCoins.hide()
	$ModernHUD/TopLeft/CoinCount.show()
	%ModernPB.hide()
	%ModernIGT.hide()
	%ModernCoinCount.text = "*" + str(Global.coins).pad_zeros(2)
	%ModernScore.text = str(Global.score).pad_zeros(9)
	%ModernTime.text = "⏲" + str(Global.time).pad_zeros(3)
	%ModernKeyCount.visible = KeyItem.total_collected > 0
	%ModernKeyAmount.text = "*" + str(KeyItem.total_collected).pad_zeros(2)
	if get_tree().get_first_node_in_group("Players") == null or Settings.file.difficulty.time_limit == 0:
		%ModernTime.text = "⏲---"

func handle_disco_combo() -> void:
	%Combo.show()
	%ComboAmount.text = "Combo*" + str(DiscoLevel.combo_amount)
	%ComboMeter.value = DiscoLevel.combo_meter
	%ComboMeter.modulate = Color.PURPLE if DiscoLevel.combo_breaks <= 0 else Color.WHITE
	%MedalIcon.region_rect.position.x = ("FDCBASP".find(DiscoLevel.current_rank) + 1) * 16

func handle_challenge_mode_hud() -> void:
	$Main/RedCoins.show()
	$ModernHUD/TopLeft/RedCoins.show()
	$ModernHUD/TopLeft/CoinCount.hide()
	$Main/CoinCount.hide()
	%ModernLifeCount.hide()
	%CharacterIcon.hide()
	var red_coins_collected = ChallengeModeHandler.current_run_red_coins_collected
	var idx := 0
	if Global.world_num > 8:
		return
	if Global.in_title_screen:
		red_coins_collected = int(ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1])
	for i in [$Main/RedCoins/Coin1, $Main/RedCoins/Coin2, $Main/RedCoins/Coin3, $Main/RedCoins/Coin4, $Main/RedCoins/Coin5]:
		i.frame = int(ChallengeModeHandler.is_coin_collected(idx, red_coins_collected))
		idx += 1
	if ChallengeModeHandler.is_coin_collected(ChallengeModeHandler.CoinValues.YOSHI_EGG, red_coins_collected):
		$Main/RedCoins/YoshiEgg.frame = Global.level_num
	else:
		$Main/RedCoins/YoshiEgg.frame = 0
	
	$Main/RedCoins/ScoreMedal.frame = (Global.score > ChallengeModeHandler.CHALLENGE_TARGETS[Global.current_campaign][Global.world_num - 1][Global.level_num - 1] or ChallengeModeHandler.top_challenge_scores[Global.world_num - 1][Global.level_num - 1] >= ChallengeModeHandler.CHALLENGE_TARGETS[Global.current_campaign][Global.world_num - 1][Global.level_num - 1])
	
	if is_instance_valid(Global.current_level):
		handle_yoshi_radar()
	
	for i in $Main/RedCoins.get_children():
		i.get_node("Shadow").frame = i.frame
	for i in $ModernHUD/TopLeft/RedCoins.get_child_count():
		$ModernHUD/TopLeft/RedCoins.get_child(i).frame = $Main/RedCoins.get_child(i).frame
		$ModernHUD/TopLeft/RedCoins.get_child(i).get_node("Shadow").frame = $Main/RedCoins.get_child(i).frame

func handle_yoshi_radar() -> void:
	var has_egg = false
	var egg_position = Vector2.ZERO
	for i in get_tree().get_nodes_in_group("Blocks"):
		if i.item != null:
			if i.item.resource_path == "res://Scenes/Prefabs/Entities/Items/YoshiEgg.tscn":
				has_egg = true
				egg_position = i.global_position
				break
	%Radar.frame = Global.level_num
	%ModernRadar.frame = Global.level_num
	if has_egg == false or ChallengeModeHandler.is_coin_collected(ChallengeModeHandler.CoinValues.YOSHI_EGG): 
		%Radar.get_node("AnimationPlayer").play("RESET")
		%ModernRadar.get_node("AnimationPlayer").play("RESET")
		return

	var player_position = get_tree().get_first_node_in_group("Players").global_position
	var distance = (egg_position - player_position).length()
	
	%Radar.get_node("AnimationPlayer").speed_scale = (250 / distance)
	%ModernRadar.get_node("AnimationPlayer").speed_scale = $Main/RedCoins/YoshiEgg/Radar/AnimationPlayer.speed_scale
	if distance < 512:
		%Radar.get_node("AnimationPlayer").play("Flash")
		%ModernRadar.get_node("AnimationPlayer").play("Flash")
	else:
		%Radar.get_node("AnimationPlayer").play("RESET")
		%ModernRadar.get_node("AnimationPlayer").play("RESET")

func handle_speedrun_timer() -> void:
	%Time.hide()
	%Stopwatch.show()
	%IGT.show()
	%IGT.modulate.a = int([Global.GameMode.MARATHON, Global.GameMode.MARATHON_PRACTICE].has(Global.current_game_mode) and get_tree().get_first_node_in_group("Players") != null)
	%IGT.text = "⏲" + (str(Global.time).pad_zeros(3))
	%ModernIGT.visible = %IGT.modulate.a == 1
	%ModernIGT.text = %IGT.text
	var late = SpeedrunHandler.timer > SpeedrunHandler.best_time
	var diff = SpeedrunHandler.best_time - SpeedrunHandler.timer
	%PB.visible = SpeedrunHandler.best_time > 0 and (SpeedrunHandler.timer > 0 or Global.current_level != null)
	%ModernPB.visible = %PB.visible
	var time_string = SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(SpeedrunHandler.timer))
	%Stopwatch.text = time_string
	%ModernTime.text = "⏲" + time_string
	%PB.text = ("+" if late else "-") + SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(diff))
	%PB.modulate = Color.RED if late else Color.GREEN
	%ModernPB.text = %PB.text
	%ModernPB.modulate = %PB.modulate

func handle_pausing() -> void:
	if get_tree().get_first_node_in_group("Players") != null and Global.can_pause and ((Global.current_game_mode != Global.GameMode.LEVEL_EDITOR) or Global.level_editor_is_playtesting()):
		if get_tree().paused == false and Global.game_paused == false:
			if Input.is_action_just_pressed("pause"):
				activate_pause_menu()

func activate_pause_menu() -> void:
	match Global.current_game_mode:
		Global.GameMode.BOO_RACE:
			$BooRacePause.open()
		Global.GameMode.MARATHON:
			$MarathonPause.open()
		Global.GameMode.MARATHON_PRACTICE:
			$MarathonPause.open()
		Global.GameMode.LEVEL_EDITOR:
			if (Global.level_editor_is_playtesting()):
				$LevelTestingPause.open()
		_:
			$StoryPause.open()




const HURRY_UP = preload("res://Assets/Audio/BGM/HurryUp.mp3")

func on_timeout() -> void:
	if Global.can_time_tick and is_instance_valid(Global.current_level) and Settings.file.difficulty.time_limit > 0:
		if Global.level_editor != null:
			if Global.level_editor.current_state != LevelEditor.EditorState.PLAYTESTING:
				return
		if Global.time == 0:
			get_tree().call_group("Players", "time_up")
			return
		Global.time -= 1
		if Global.time == 100:
			AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.TIME_WARNING, 5, true)
