class_name PowerUpItem
extends CharacterBody2D

signal collected

@export var power_up_state := "Big"
var direction := 1

signal physics_tick(delta: float)

var rising := false

const player_angles := [Vector2(-1, -1), Vector2(1, -1), Vector2(-0.5, -2), Vector2(0.5, -2)]

func _physics_process(delta: float) -> void:
	physics_tick.emit(delta)

func collect_item(player: Player) -> void:
	collected.emit()
	player.get_power_up(power_up_state)
	queue_free()

func player_multiplayer_launch_spawn(player: Player) -> void:
	global_position.y -= 8
	velocity = 100 * player_angles[player.player_id]
	direction = sign(velocity.x)

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		collect_item(area.owner)

func block_bounce_up(block: Node2D) -> void:
	if rising: return
	direction = -sign(block.global_position.x - global_position.x + 0.1)
	velocity.y = -160

func block_dispense_tween() -> void:
	rising = true
	var old_z = z_index
	z_index = -2
	AudioManager.play_sfx("item_appear", global_position)
	set_physics_process(false)
	set_process(false)
	global_position.y += 8
	show()
	reset_physics_interpolation()
	var time := 1
	var tween = create_tween().tween_property(self, "position:y", position.y - 15, time)
	await tween.finished
	rising = false
	if get_parent().get_parent() is TrackRider:
		reparent(get_parent().get_parent().get_parent())
		reset_physics_interpolation()
	velocity.y = 0
	set_physics_process(true)
	set_process(true)
	z_index = old_z
