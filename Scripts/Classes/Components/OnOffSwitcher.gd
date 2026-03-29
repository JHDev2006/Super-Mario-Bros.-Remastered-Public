class_name OnOffSwitcher
extends Node

static var active := false

@export var sprite: AnimatedSprite2D = null
@export var collision_to_change: CollisionShape2D = null
@export var invert := false

signal switched_on
signal switched_off
signal switched

static var has_switched := false

var spawned := false

func _ready() -> void:
	add_to_group("OnOffSwitches")
	await owner.ready
	on_switch()
	spawned = true

func on_switch(emit := true) -> void:
	if emit:
		switched.emit()
	var on = active
	if invert:
		on = !active
	if emit:
		if on:
			switched_on.emit()
		else:
			switched_off.emit()
	update_stuff()

func switch() -> void:
	if has_switched:
		return
	has_switched = true
	active = not active
	AudioManager.play_sfx("switch", owner.global_position)
	get_tree().call_group("OnOffSwitches", "on_switch")
	await get_tree().physics_frame
	has_switched = false

func update_stuff() -> void:
	var is_on = active
	if invert: is_on = !is_on
	if sprite != null:
		sprite.play("On" if is_on else "Off")
		if not spawned:
			sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 1
	if collision_to_change != null:
		collision_to_change.set_deferred("disabled", !is_on)
