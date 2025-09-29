extends Node2D

var velocity := Vector2(0, -300)

var id := 0

const collection_sounds := [preload("uid://drr1qqeuhmv6m"), preload("uid://de1tktivtggdv"), preload("uid://cdtlca36qsba5"), preload("uid://dd47k4c5sypwp"), preload("uid://chi2nogc2op4i")]

var already_collected := false

var can_spawn_particles := false
@onready var COIN_SPARKLE = load("res://Scenes/Prefabs/Particles/RedCoinSparkle.tscn")

func _ready() -> void:
	already_collected = ChallengeModeHandler.is_coin_collected(id) or ChallengeModeHandler.is_coin_permanently_collected(id)
	if already_collected == false:
		ChallengeModeHandler.red_coins += 1
		AudioManager.play_sfx(collection_sounds[ChallengeModeHandler.red_coins - 1], global_position)
	else:
		set_visibility_layer_bit(0, false)
		AudioManager.play_sfx("coin", global_position, 2)
		$Sprite.play("Collected")
	Global.score += 200
	ChallengeModeHandler.set_value(id, true)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	velocity.y += (15 / delta) * delta

func vanish() -> void:
	if can_spawn_particles:
		$Sprite.queue_free()
		summon_particle()
	else:
		queue_free()

func summon_particle() -> void:
	var node = COIN_SPARKLE.instantiate()
	node.finished.connect(queue_free)
	node.global_position = global_position
	add_sibling(node)
