class_name Broadcaster
extends Node2D

static var active_channels := []

@export_range(0, 99) var channel := 0
@export_enum("Send and Recieve", "Send Only", "Recieve Only") var mode := 0

signal recieved_signal

func _ready() -> void:
	await get_tree().create_timer(0.2, false).timeout
	check_channels()

func check_channels() -> void:
	if mode == 1:
		return
	$SignalExposer.signals_recieved += 1
	if $SignalExposer.check_recursive() == false:
		return
	if active_channels.has(channel):#
		$Status.show()
		$Status.flip_v = true
		recieved_signal.emit()
		if active_channels.has(channel):
			active_channels.erase.call_deferred(channel)
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
	for i in get_tree().get_nodes_in_group("Broadcasters"):
		if i != self:
			i.check_channels.call_deferred()
	await get_tree().create_timer(0.5, false).timeout
	$Status.hide()

const EXPLOSION = preload("uid://clbvyne1cr8gp")

func summon_explosion() -> void:
	queue_free()
	AudioManager.play_global_sfx("explode")
	var node = EXPLOSION.instantiate()
	node.global_position = global_position
	add_sibling(node)
