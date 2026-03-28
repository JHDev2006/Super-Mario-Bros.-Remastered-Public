class_name DiscoLevel
extends Node

@export var combo_meter_rate := 1.0
@export var max_combo := 30.0
@export var disco_lighting: Parallax2D = null

static var combo_amount := 0:
	set(value):
		if value > combo_amount:
			combo_meter = 100
		combo_amount = value
static var score_mult := 0
static var combo_meter := 0.0

static var in_disco_level := false
static var combo_breaks := 0
static var giving_score := false

static var max_combo_amount := 0.0
static var first_load := true

static var can_meter_tick := true

const RANK_AMOUNTS := {0: "F", 0.25: "D", 0.45: "C", 0.6: "B", 0.8: "A", 1: "S"}

const RANKS := "FDCBASP"

static var current_rank := ""

static var active := false

const S_RANK_SCORES := [
	[45000, 40000, 25000, 12000],
	[52500, 25000, 25000, 12000],
	[45000, 45000, 25000, 12000],
	[45000, 45000, 25000, 12000],
	
	[45000, 40000, 30000, 12000],
	[30000, 45000, 20000, 12000],
	[45000, 25000, 30000, 12000],
	[45000, 45000, 45000, 12000]
]

static var level_ranks := "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"

const RANK_IDs := ["F", "D", "C", "B", "A", "S", "P"]

func _ready() -> void:
	if Global.current_game_mode != Global.GameMode.DISCO:
		queue_free()
		return
	active = true
	Global.current_campaign = "SMBANN"
	if get_parent().get_node_or_null("EndFlagpole") != null:
		get_parent().get_node("EndFlagpole").player_reached.connect(level_finished)
	if get_parent().get_node_or_null("CastleBridge") != null:
		get_parent().get_node("CastleBridge").victory_begin.connect(level_finished)
	can_meter_tick = true
	if DiscoLevel.first_load == true:
		max_combo_amount = max_combo
		reset_values()
		DiscoLevel.first_load = false

	in_disco_level = true

static func reset_values() -> void:
	combo_amount = 0
	combo_meter = 0
	first_load = false
	if Global.current_game_mode == Global.GameMode.DISCO:
		Global.score = 0
	combo_breaks = 0
	current_rank = "F"
	Player.times_hit = 0
	Global.player_power_states = "0000"

func _physics_process(delta: float) -> void:
	if not active:
		return
	if can_meter_tick:
		combo_meter = clamp(combo_meter - 24 * combo_meter_rate * delta, 0, 100)
	if combo_meter <= 0 and combo_amount > 0 and not giving_score:
		if combo_amount > 2 or current_rank == "P" or current_rank == "S":
			AudioManager.play_global_sfx("combo_lost")
		give_points(combo_amount)
		combo_amount = 0
		combo_breaks += 1
	var old_rank = current_rank
	current_rank = "F"
	for i in RANK_AMOUNTS.keys():
		if (Global.score + (combo_amount * 500) + (Global.time * 50)) >= (S_RANK_SCORES[Global.world_num - 1][Global.level_num - 1] * i):
			current_rank = RANK_AMOUNTS[i]
	if current_rank == "S" and combo_breaks <= 0 and combo_amount >= 1:
		current_rank = "P"
	if RANKS.find(current_rank) > RANKS.find(old_rank):
		if current_rank == "S" or current_rank == "P":
			AudioManager.play_global_sfx("rank_up_2")
		elif combo_amount > 0:
			AudioManager.play_global_sfx("rank_up_1")
	elif RANKS.find(current_rank) < RANKS.find(old_rank):
		AudioManager.play_global_sfx("rank_down")

func give_points(amount := 0) -> void:
	await get_tree().create_timer(0.5, false).timeout
	for i in amount * 4:
		Global.score += 125
		AudioManager.play_global_sfx("score")
		await get_tree().physics_frame
	AudioManager.play_global_sfx("score_end")
	AudioManager.kill_sfx("score")
		
func _exit_tree() -> void:
	Global.tallying_score = false
	AudioManager.kill_sfx("score")

func level_finished() -> void:
	if !(Global.world_num == 8 && Global.level_num == 4):
		SaveManager.visited_levels[SaveManager.get_level_idx(Global.world_num, Global.level_num) + 1] = "1"
	Global.score += (combo_amount * 500)
	combo_meter = 100
	_physics_process(0)
	can_meter_tick = false
	await Global.score_tally_finished
	active = false
	write_final_rank()

func write_final_rank() -> void:
	if ChallengeModeHandler.top_challenge_scores[Global.world_num - 1][Global.level_num - 1] < Global.score:
		ChallengeModeHandler.top_challenge_scores[Global.world_num - 1][Global.level_num - 1] = Global.score
	if RANK_IDs.find(level_ranks[SaveManager.get_level_idx(Global.world_num, Global.level_num)]) < RANK_IDs.find(current_rank):
		level_ranks[SaveManager.get_level_idx(Global.world_num, Global.level_num)] = current_rank
	check_for_p_rank_achievement()
	SaveManager.write_save("SMBANN")

func check_for_p_rank_achievement() -> void:
	if level_ranks == "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP":
		Global.unlock_achievement(Global.AchievementID.ANN_PRANK)
