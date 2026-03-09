extends Node2D

@export var sfx := 0
@export_range(0.1, 3.0, 0.1) var pitch := 1.0
@export var global := false

func play_sfx() -> void:
	if global:
		AudioManager.play_global_sfx(AudioManager.sfx_library.keys()[sfx], pitch)
	else:
		AudioManager.play_sfx(AudioManager.sfx_library.keys()[sfx], global_position, pitch)
	$SignalExposer.update_animation()
