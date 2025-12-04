extends CharacterBody2D

func _ready() -> void:
	AudioManager.play_sfx("item_appear", global_position)
	Global.score += 5000
	ChallengeModeHandler.set_value(ChallengeModeHandler.CoinValues.YOSHI_EGG, true)
	velocity.y = -150
	$Egg.play(["Green", "Yellow", "Red", "Blue"][Global.level_num - 1])
	$Yoshi.play(["Green", "Yellow", "Red", "Blue"][Global.level_num - 1])
	await get_tree().create_timer(1.5, false).timeout

func _physics_process(delta: float) -> void:
	velocity.y += (Global.entity_gravity / delta) * delta
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)
	move_and_slide()

func show_smoke() -> void:
	var smoke = preload("res://Scenes/Prefabs/Particles/SmokeParticle.tscn").instantiate()
	smoke.scale = Vector2(2, 2)
	smoke.global_position =global_position
	add_sibling(smoke)
	$ScoreNoteSpawner.spawn_note(5000)
	queue_free()
