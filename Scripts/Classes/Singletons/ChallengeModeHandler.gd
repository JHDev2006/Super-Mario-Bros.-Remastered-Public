class_name ChallengeModeHandler
extends Node

static var challenge_mode := false
static var red_coins := 0
static var yoshi_egg_found := false
static var yoshi_egg_id := 1

static var current_run_red_coins_collected := 0

enum CoinValues{R_COIN_1 = 0, R_COIN_2 = 1, R_COIN_3 = 2, R_COIN_4 = 3, R_COIN_5 = 4, YOSHI_EGG = 5}

const BIT_VALUES := [1, 2, 4, 8, 16, 32, 64, 128]

static var top_challenge_scores := [
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
]

const CHALLENGE_TARGETS := {
	"SMB1": SMB1_CHALLENGE_SCORE_TARGETS,
	"SMBLL": SMBLL_CHALLENGE_SCORE_TARGETS,
	"SMBS": SMBS_CHALLENGE_SCORE_TARGETS,
	"SMBANN": []
}

const SMB1_CHALLENGE_SCORE_TARGETS := [
	[32000, 38000, 23000, 17000],
	[40000, 24000, 23000, 17000],
	[40000, 65000, 23000, 17000],
	[32000, 35000, 23000, 19000],
	[80000, 36000, 23000, 17000],
	[30000, 30000, 21000, 17000],
	[32000, 23000, 28000, 19000],
	[60000, 32000, 28000, 20000],
]

const SMBLL_CHALLENGE_SCORE_TARGETS := [
	[40000, 28000, 26000, 17000],
	[32000, 45000, 30000, 20000],
	[32000, 25000, 30000, 19000],
	[29000, 35000, 24000, 18000],
	[60000, 33000, 23000, 17000],
	[40000, 24000, 29000, 18000],
	[38000, 24000, 18000, 27000],
	[40000, 34000, 26000, 17000],
]

const SMBS_CHALLENGE_SCORE_TARGETS := [
	[32000, 35000, 30000, 25000],
	[36000, 27000, 26000, 24000],
	[26000, 30000, 32000, 21000],
	[33000, 25000, 24000, 17000],
	[40000, 32000, 25000, 21000],
	[30000, 28000, 30000, 22000],
	[36000, 23000, 32000, 19000],
	[30000, 25000, 24000, 18000],
]

static var red_coins_collected := [
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0]
]

static func set_value(coin_id := CoinValues.R_COIN_1, value := false) -> void:
	if value:
		current_run_red_coins_collected |= (1 << coin_id)
	else:
		current_run_red_coins_collected &= ~(1 << coin_id)

static func is_coin_collected(coin_id: CoinValues = CoinValues.R_COIN_1, num := current_run_red_coins_collected) -> bool:
	return num & (1 << coin_id) != 0

func check_for_achievement() -> void:
	for x in red_coins_collected:
		for i in x:
			if i != 63:
				return
	var target
	match Global.current_campaign:
		"SMBLL": target = SMBLL_CHALLENGE_SCORE_TARGETS
		"SMBS": target = SMBS_CHALLENGE_SCORE_TARGETS
		_: target = SMB1_CHALLENGE_SCORE_TARGETS
	var world := 0
	for x in top_challenge_scores:
		var level := 0
		for i in x:
			if top_challenge_scores[world][level] < target[world][level]:
				return
			level += 1
		world += 1
	
	match Global.current_campaign:
		"SMB1": Global.unlock_achievement(Global.AchievementID.SMB1_CHALLENGE)
		"SMBLL": Global.unlock_achievement(Global.AchievementID.SMBLL_CHALLENGE)
		"SMBS": Global.unlock_achievement(Global.AchievementID.SMBS_CHALLENGE)
