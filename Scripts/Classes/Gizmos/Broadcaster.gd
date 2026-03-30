class_name Broadcaster
extends Node2D

static var active_channels := []

@export_range(0, 99) var channel := 0
@export_enum("Send and Recieve", "Send Only", "Recieve Only") var mode := 0

signal recieved_signal

func _ready() -> void:
	for i in active_channels:
		check_channels(i)

func check_channels(signal_id := 0) -> void:
	if mode == 1 or Global.level_editor_is_editing():
		return
	$SignalExposer.signals_recieved += 1
	if $SignalExposer.check_recursive() == false:
		return
	if channel == signal_id:
		$Status.show()
		$Status.flip_v = true
		recieved_signal.emit()
		await get_tree().create_timer(0.5, false).timeout
		$Status.hide()

func emit_broadcast() -> void:
	if mode == 2:
		return
	if $SignalExposer.check_recursive() == false:
		return
	$Status.show()
	$Status.flip_v = false
	$SignalExposer.update_animation()
	active_channels.append(channel)
	var matching_channel := false
	for i in get_tree().get_nodes_in_group("Broadcasters"):
		if i != self:
			if i.channel == channel:
				matching_channel = true
			i.check_channels.call_deferred(channel)
	if matching_channel:
		active_channels.erase(channel)
	await get_tree().create_timer(0.5, false).timeout
	$Status.hide()

const EXPLOSION = preload("uid://clbvyne1cr8gp")

func summon_explosion() -> void:
	queue_free()
	AudioManager.play_global_sfx("explode")
	var node = EXPLOSION.instantiate()
	node.global_position = global_position
	add_sibling(node)
