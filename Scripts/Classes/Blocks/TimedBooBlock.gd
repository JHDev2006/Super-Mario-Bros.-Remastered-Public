class_name TimedBooBlock
extends Block

var time := 3
var active := false

signal switched

var can_change_animation := false

static var main_block = null

static var can_tick := true:
	set(value):
		can_tick = value

func _ready() -> void:
	main_block = self
	can_change_animation = true

func level_start() -> void:
	$Timer.start()

func on_timeout() -> void:
	if can_tick == false or BooRaceHandler.countdown_active or Global.level_editor_is_editing(): return
	time = clamp(time - 1, 0, 3)
	if main_block == self:
		if time <= 0:
			switched.emit()
			return
		elif time < 3:
			AudioManager.play_global_sfx("timer_beep")
	update_sprite()

func update_sprite() -> void:
	if active:
		$Sprite.play("On" + str(time))
	else:
		$Sprite.play("Off" + str(time))

func on_block_hit() -> void:
	if not can_hit:
		return
	can_hit = false
	switched.emit()
	await get_tree().create_timer(0.25, false).timeout
	can_hit = true

func _exit_tree() -> void:
	can_tick = true

func set_active(is_active := false) -> void:
	if Global.level_editor_is_editing():
		return
	$Timer.stop()
	time = 4
	active = is_active
	if can_change_animation:
		if active:
			$Sprite.play("BlueToRed")
		else:
			$Sprite.play("RedToBlue")
		await $Sprite.animation_finished
	time = 3
	update_sprite()
	$Timer.start()
	time = 4
	on_timeout()
