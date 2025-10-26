class_name Icicle
extends Enemy

var falling := false
const ICICLE_DESTRUCTION = preload("res://Scenes/Parts/Particles/IcicleDestruction.tscn")
func _physics_process(delta: float) -> void:
	if falling:
		handle_movement(delta)
	else:
		detect_player()

func detect_player() -> void:
	var shaking := false
	for i in get_tree().get_nodes_in_group("Players"):
		var distance = abs(i.global_position.x - global_position.x)
		if i.global_position.y > global_position.y:
			if distance <= 32:
				fall()
			elif distance <= 64:
				shaking = true
	if shaking:
		$AnimationPlayer.play("Shake")
	else:
		$AnimationPlayer.play("RESET")
			

func handle_movement(delta: float) -> void:
	apply_enemy_gravity(delta)
	apply_enemy_gravity(delta / 2)
	if is_on_floor():
		destroy()
	move_and_slide()

func destroy() -> void:
	await get_tree().physics_frame
	AudioManager.play_sfx("icicle_break", global_position)
	summon_particles()
	queue_free()

func summon_particles() -> void:
	var node = ICICLE_DESTRUCTION.instantiate()
	node.global_position = global_position - Vector2(0, 8)
	add_sibling(node)

func fall() -> void:
	AudioManager.play_sfx("icicle_fall", global_position)
	falling = true
