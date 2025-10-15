class_name TimerSprite
extends Sprite2D

@export var max_value := 1.0
@export var value_name := ""

@export_enum("Global", "Player", "Timer") var object := 0
@export var timer: Timer = null

@export var warn_sfx: AudioStreamPlayer = null

@export var warn_threshold := 0.7

var can_warn := false

func _ready() -> void:
	texture = ResourceSetter.get_resource(texture, self)

func _process(_delta: float) -> void:
	var node = owner if object == 1 else Global
	if object == 2:
		node = timer
	var value = node.get(value_name)
	var percent = inverse_lerp(max_value, 0, value)
	percent = clamp(percent, 0, 1)
	get_parent().visible = percent < 1 and Settings.file.visuals.visible_timers
	frame = lerp(0, 6, percent)
	if percent >= warn_threshold and Settings.file.audio.extra_sfx == 1:
		if node is Timer:
			if node.is_stopped(): return
		if can_warn:
			can_warn = false
			AudioManager.play_global_sfx("timer_warning")
	else:
		can_warn = true
