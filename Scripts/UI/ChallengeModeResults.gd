extends Node


@export var can_exit := false

func _enter_tree() -> void:
	Global.get_node("GameHUD").hide()

var coin_medal := true
var score_medal := false
var yoshi_medal := false

var exiting := false

func _ready() -> void:
	var your_results = tr("CHALLENGE_DIALOGUE_RESULTS").split(" ")
	$SpeechBubble/Your.text = your_results[0]
	$SpeechBubble/Your/Results.text = your_results[1]
	coin_medal = int(ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1]) & 0b011111 == 0b011111
	score_medal = ChallengeModeHandler.top_challenge_scores[Global.world_num -1][Global.level_num - 1] >= ChallengeModeHandler.CHALLENGE_TARGETS[Global.current_campaign][Global.world_num -1][Global.level_num -1]
	yoshi_medal = ChallengeModeHandler.is_coin_collected(ChallengeModeHandler.CoinValues.YOSHI_EGG, ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1])
	$ChallengeResults.play()
	setup_results()

func _process(_delta: float) -> void:
	if can_exit and Input.is_action_just_pressed("jump_0"):
		can_exit = false
		exiting = true
		save_results()
		$ChallengeResults.stop()
		$ChallengeEnd.play()
		await $ChallengeEnd.finished
		open_menu()
	Engine.time_scale = 5 if Input.is_action_pressed("jump_0") and can_exit == false and exiting == false else 1

func open_menu() -> void:
	$CanvasLayer/PauseMenu.open()

func save_results() -> void:
	var index := 0
	ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1] =  int(ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1]) | ChallengeModeHandler.current_run_red_coins_collected
	if Global.score >= ChallengeModeHandler.top_challenge_scores[Global.world_num - 1][Global.level_num - 1]:
		ChallengeModeHandler.top_challenge_scores[Global.world_num - 1][Global.level_num - 1] = Global.score
	ChallengeModeHandler.new().check_for_achievement()
	SaveManager.write_save()

func retry_level() -> void:
	Global.player_power_states = "0000"
	ChallengeModeHandler.current_run_red_coins_collected = ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1]
	Global.score = 0
	LevelTransition.level_to_transition_to = Level.get_scene_string(Global.world_num, Global.level_num)
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func go_to_title_screen() -> void:
	Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()
	Engine.time_scale = 1

func setup_results() -> void:
	$Sprite2D3/RedCoins.visible = coin_medal
	$Sprite2D3/Score.visible = score_medal
	$Sprite2D3/YoshiEgg.visible = yoshi_medal
	$SpeechBubble/Score/ScoreLabel.text = str(Global.score)
	var idx = 0
	for i in $Sprite2D/Sprite2D3/Coins.get_children():
		if ChallengeModeHandler.is_coin_collected(idx, ChallengeModeHandler.red_coins_collected[Global.world_num - 1][Global.level_num - 1]):
			i.frame = 1
		else:
			i.frame = 0
		idx += 1
	idx = 0
	for i in $SpeechBubble/Coins/Node2D.get_children():
		i.frame = int(ChallengeModeHandler.is_coin_collected(idx))
		idx += 1
	$Sprite2D/Sprite2D3/ScoreText/Target.text = "/ " + str(ChallengeModeHandler.CHALLENGE_TARGETS[Global.current_campaign][Global.world_num - 1][Global.level_num - 1])
	$WorldLevel.text = str(Global.world_num) + "-" + str(Global.level_num)
	$Yoshi.play(["Green", "Yellow", "Red", "Blue"][Global.level_num - 1])

func update_coins_display() -> void:
	var idx := 0
	for i in $Sprite2D/Sprite2D3/Coins.get_children():
		if ChallengeModeHandler.is_coin_collected(idx):
			i.frame = 1
		idx += 1

func update_score() -> void:
	$Sprite2D/Sprite2D3/ScoreText.text = str(Global.score)

func give_red_coin_medal() -> void:
	const mask = (1 << ChallengeModeHandler.CoinValues.R_COIN_1) | (1 << ChallengeModeHandler.CoinValues.R_COIN_2) | (1 << ChallengeModeHandler.CoinValues.R_COIN_3) | (1 << ChallengeModeHandler.CoinValues.R_COIN_4) | (1 << ChallengeModeHandler.CoinValues.R_COIN_5)
	var valid := (ChallengeModeHandler.current_run_red_coins_collected & mask) == mask
	if valid and not coin_medal:
		do_medal_give_animation($Sprite2D3/RedCoins)

func give_score_medal() -> void:
	if Global.score >= ChallengeModeHandler.CHALLENGE_TARGETS[Global.current_campaign][Global.world_num - 1][Global.level_num - 1] and not score_medal:
		do_medal_give_animation($Sprite2D3/Score)

func give_yoshi_medal() -> void:
	if ChallengeModeHandler.is_coin_collected(ChallengeModeHandler.CoinValues.YOSHI_EGG):
		$SmokeParticle.play()
		$Yoshi/AudioStreamPlayer2D.play()
		$Yoshi.show()
		if yoshi_medal == false:
			await get_tree().create_timer(0.5, false).timeout
			do_medal_give_animation($Sprite2D3/YoshiEgg)

func do_medal_give_animation(medal: Node) -> void:
	$AudioStreamPlayer2.play()
	get_tree().paused = true
	for i in 4:
		medal.hide()
		await get_tree().create_timer(0.1, true).timeout
		medal.show()
		await get_tree().create_timer(0.1, true).timeout
	get_tree().paused = false
