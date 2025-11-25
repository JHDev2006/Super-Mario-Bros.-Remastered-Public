class_name RopeElevatorPlatform
extends Node2D


@export var linked_platform: Node2D = null

@onready var platform: AnimatableBody2D = $Platform
@onready var player_detection: Area2D = $Platform/PlayerDetection

@export var rope_top := -160
var velocity := 0.0

var dropped := false

var player_stood_on := false

var sample_colour: Texture = null

func _ready() -> void:
	$Platform/ScoreNoteSpawner.owner = $Platform

func _process(_delta: float) -> void:
	if not dropped:
		$Rope.size.y = platform.global_position.y - rope_top
		$Rope.global_position.y = rope_top

func _physics_process(delta: float) -> void:
	player_stood_on = player_detection.get_overlapping_areas().any(is_player)
	if dropped:
		velocity += (5) * delta * 60.0
		platform.position.y += velocity * delta
		return
	else:
		if platform.global_position.y <= rope_top or linked_platform.dropped:
			dropped = true
			if linked_platform.dropped:
				if Settings.file.audio.extra_sfx == 1:
					AudioManager.play_sfx("lift_fall", global_position)
				$Platform/ScoreNoteSpawner.spawn_note(1000)
	if player_stood_on:
		velocity += (2) * delta * 60.0
	else:
		velocity = lerpf(velocity, 0, delta * 2)
	linked_platform.velocity = -velocity
	platform.position.y += velocity * delta
	
func is_player(area: Area2D) -> bool:
	if area.owner is Player:
		return area.owner.is_on_floor()
	return false
