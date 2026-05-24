class_name RopeElevatorPlatform
extends Node2D


@export var linked_platform: Node2D = null

@onready var platform: AnimatableBody2D = $Platform
@onready var player_detection: Area2D = $Platform/PlayerDetection

@export var rope_top := -160

@export var can_fall := true

var velocity := 0.0

var dropped := false

var player_stood_on := false

var sample_colour: Texture = null

var locked := false

func _ready() -> void:
	$Platform/ScoreNoteSpawner.owner = $Platform

func _process(_delta: float) -> void:
	if not dropped and is_instance_valid($Rope):
		$Rope.size.y = $Platform.global_position.y - rope_top + 1
		$Rope.global_position.y = rope_top

func _physics_process(delta: float) -> void:
	player_stood_on = player_detection.get_overlapping_areas().any(is_player)
	if platform.global_position.y <= rope_top + 8 and player_stood_on:
		locked = false
		linked_platform.locked = false
	if can_fall == false:
		if linked_platform.global_position.y <= rope_top + 8 or (platform.global_position.y <= rope_top + 8 and not player_stood_on) or locked:
			velocity = 0
			locked = true
			linked_platform.locked = true
			linked_platform.velocity = 0
			return
	if dropped:
		velocity += (5 / delta) * delta
		platform.position.y += velocity * delta
		return
	else:
		if (platform.global_position.y <= rope_top or linked_platform.dropped) and can_fall:
			dropped = true
			if linked_platform.dropped:
				if Settings.file.audio.extra_sfx == 1:
					AudioManager.play_sfx("lift_fall", global_position)
				$Platform/ScoreNoteSpawner.spawn_note(1000)
	if player_stood_on:
		velocity += (2 / delta) * delta
	else:
		velocity = lerpf(velocity, 0, delta * 2)
	linked_platform.velocity = -velocity
	platform.position.y += velocity * delta
	
func is_player(area: Area2D) -> bool:
	if area.owner is Player:
		return area.owner.is_on_floor()
	return false
