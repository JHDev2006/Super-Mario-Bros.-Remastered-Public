@icon("res://Assets/Sprites/Editor/Enemy.svg")
class_name Enemy
extends CharacterBody2D

signal killed(direction: int)

@export var on_screen_enabler: VisibleOnScreenNotifier2D = null
@export var score_note_adder: ScoreNoteSpawner = null

var direction := -1

func damage_player(player: Player) -> void:
	player.damage()

func apply_enemy_gravity(delta: float) -> void:
	velocity.y += (Global.entity_gravity / delta) * delta
	velocity.y = clamp(velocity.y, -INF, Global.entity_max_fall_speed)

func die() -> void:
	killed.emit([-1, 1].pick_random())
	DiscoLevel.combo_amount += 1
	DiscoLevel.combo_meter = 100
	queue_free()

func die_from_object(obj: Node2D) -> void:
	var dir = sign(global_position.x - obj.global_position.x)
	if dir == 0:
		dir = [-1, 1].pick_random()
	DiscoLevel.combo_amount += 1
	killed.emit(dir)
	queue_free()

func flag_die() -> void:
	if on_screen_enabler != null:
		if on_screen_enabler.is_on_screen():
			queue_free()
			if score_note_adder != null:
				if score_note_adder.add_score == false:
					Global.score += 500
				score_note_adder.spawn_note(500)

func die_from_hammer(obj: Node2D) -> void:
	var dir = sign(global_position.x - obj.global_position.x)
	if dir == 0:
		dir = [-1, 1].pick_random()
	DiscoLevel.combo_amount += 1
	AudioManager.play_sfx("hammer_hit", global_position)
	killed.emit(dir)
	queue_free()
