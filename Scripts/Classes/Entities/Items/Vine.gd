class_name Vine
extends Node2D

@export var top_point := -256

const SPEED := 32.0
@onready var collision: CollisionShape2D = $Hitbox/Collision
@onready var hitbox: Area2D = $Hitbox


@export var cutscene = false
@export var can_tele := true

var can_stop := true

signal stopped

var can_grow := false

@export_range(2, 16) var length := 3.0

func _ready() -> void:
	if cutscene and Global.level_editor_is_editing() == false:
		do_cutscene()
	else:
		if Global.current_level != null:
			top_point = Global.current_level.vertical_height - 48
	if has_meta("block_item"):
		$SFX.play()
		can_grow = true
		global_position.y += 8

func do_cutscene() -> void:
	Level.in_vine_level = true
	if owner is WarpVine:
		top_point = global_position.y
	global_position.y = 40
	$SFX.play()
	can_grow = true
	can_tele = false
	can_stop = true
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.global_position = Vector2(global_position.x, 64)
		i.hide()
		i.auto_death_pit = false
		i.state_machine.transition_to("Freeze")
	await stopped
	can_tele = false
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.show()
		for x in [1, 2]:
			i.set_collision_mask_value(x, false)
		i.state_machine.transition_to("Climb", {"Vine" = self, "Cutscene" = true})
		var climb_state = i.get_node("States/Climb")
		climb_state.climb_direction = -1
		var distance = abs(i.global_position.y - (top_point + 32))
		print([i.global_position.y, top_point])
		var climb_time = distance / (50)
		print([distance, climb_time])
		await get_tree().create_timer(climb_time, false).timeout
		i.direction = -1
		climb_state.climb_direction = 0
		await get_tree().create_timer(0.5, false).timeout
		i.state_machine.transition_to("Normal")
		i.auto_death_pit = true
		for x in [1, 2]:
			i.set_collision_mask_value(x, true)

func _physics_process(delta: float) -> void:
	if global_position.y >= top_point and can_grow:
		global_position.y -= SPEED * delta
		%Middle.position.y = %Top.position.y + 8
		%Bottom.position.y += SPEED * delta
		%Middle.size.y = abs(%Top.global_position.y - %Bottom.global_position.y) - 1
		collision.shape.size.y += SPEED * delta
		collision.position.y += (SPEED / 2) * delta
		if %CeilingCheck.is_colliding() and not cutscene:
			can_stop = false
			stopped.emit()
			can_grow = false
			can_tele = false
			return
	elif can_stop:
		can_stop = false
		stopped.emit()
		if (Level.vine_warp_level != "" or CoinHeavenWarpPoint.subarea_to_warp_to != -1) and not cutscene:
			can_tele = true
	
	handle_player_interaction(delta)
	$WarpHitbox/CollisionShape2D.set_deferred("disabled", global_position.y > top_point)

func handle_player_interaction(delta: float) -> void:
	for i in hitbox.get_overlapping_areas():
		if i.owner is Player:
			if Input.get_axis("move_up_0", "move_down_0") * i.owner.gravity_vector.y < 0 and i.owner.state_machine.state.name == "Normal":
				i.owner.state_machine.transition_to("Climb", {"Vine": self})
			elif i.owner.state_machine.state.name == "Climb" and global_position.y >= top_point and can_grow:
				i.owner.global_position.y -= SPEED * delta
			if i.global_position.y <= top_point + 16:
				on_player_entered(i.owner)


func on_player_entered(_player: Player) -> void:
	if can_tele == false:
		return
	Level.vine_return_level = Global.current_level.scene_file_path
	if Global.level_editor_is_playtesting():
		CoinHeavenWarpPoint.subarea_return = Global.level_editor.sub_level_id
		Global.level_editor.transition_to_sublevel(CoinHeavenWarpPoint.subarea_to_warp_to)
	elif Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
		Global.transition_to_scene(NewLevelBuilder.sub_levels[CoinHeavenWarpPoint.subarea_to_warp_to])
	else:
		Global.transition_to_scene(Level.vine_warp_level)


func on_area_exited(area: Area2D) -> void:
	if area.owner is Player and area.name != "HammerHitbox":
		if area.owner.state_machine.state.name == "Climb":
			area.owner.state_machine.transition_to("Normal")
