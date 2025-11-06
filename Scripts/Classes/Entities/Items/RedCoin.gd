extends Node2D

@export var id := 0
var already_collected := false
const COLLECTION_SFXS := [preload("uid://drr1qqeuhmv6m"), preload("uid://de1tktivtggdv"), preload("uid://cdtlca36qsba5"), preload("uid://dd47k4c5sypwp"), preload("uid://chi2nogc2op4i")]
const SPINNING_RED_COIN = preload("res://Scenes/Prefabs/Entities/Items/SpinningRedCoin.tscn")
var can_spawn_particles := false

@onready var COIN_SPARKLE = load("res://Scenes/Prefabs/Particles/RedCoinSparkle.tscn")

signal collected

func _ready() -> void:
	if ChallengeModeHandler.is_coin_collected(id) or ChallengeModeHandler.is_coin_permanently_collected(id):
		already_collected = true
		$Sprite.play("Collected")
		set_visibility_layer_bit(0, false)

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		collect()

func collect() -> void:
	collected.emit()
	if already_collected:
		AudioManager.play_sfx("coin", global_position, 2)
	else:
		AudioManager.play_sfx(COLLECTION_SFXS[ChallengeModeHandler.red_coins], global_position)
		ChallengeModeHandler.red_coins += 1
	Global.score += 200
	ChallengeModeHandler.set_value(id, true)
	if can_spawn_particles and Settings.file.visuals.extra_particles == 1:
		summon_particle()
	queue_free()

func summon_particle() -> void:
	var node = COIN_SPARKLE.instantiate()
	node.global_position = global_position
	add_sibling(node)

func summon_bounced_coin() -> void:
	var node = SPINNING_RED_COIN.instantiate()
	node.id = id
	node.global_position = global_position + Vector2(0, 8)
	add_sibling(node)
	queue_free()
