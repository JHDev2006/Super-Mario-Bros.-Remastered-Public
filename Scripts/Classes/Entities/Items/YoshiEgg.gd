extends CharacterBody2D

var gave_points := false

func _ready() -> void:
	AudioManager.play_sfx("item_appear", global_position)
	velocity.y = -150
	$Egg.play(["Green", "Yellow", "Red", "Blue"][Global.level_num - 1])
	$Yoshi.play(["Green", "Yellow", "Red", "Blue"][Global.level_num - 1])
	await get_tree().create_timer(1.5, false).timeout
	ChallengeModeHandler.set_value(ChallengeModeHandler.CoinValues.YOSHI_EGG, true)

func _physics_process(delta: float) -> void:
	velocity.y += (Global.entity_gravity) * delta * 60.0
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
	move_and_slide()

func show_smoke() -> void:
	gave_points = true
	var smoke = preload("res://Scenes/Prefabs/Particles/SmokeParticle.tscn").instantiate()
	smoke.scale = Vector2(2, 2)
	smoke.global_position =global_position
	add_sibling(smoke)
	$ScoreNoteSpawner.spawn_note(5000)
	queue_free()

func _exit_tree() -> void:
	if gave_points == false:
		ChallengeModeHandler.set_value(ChallengeModeHandler.CoinValues.YOSHI_EGG, true)
		Global.score += 5000
