@tool
class_name TeleportPipeArea
extends PipeArea

@export var connecting_pipe: PipeArea = null

func _ready() -> void:
	update_visuals()

func update_visuals() -> void:
	if Engine.is_editor_hint():
		$ArrowJoint.show()
		$ArrowJoint.rotation = get_vector(enter_direction).angle() - deg_to_rad(90)
		$ArrowJoint/Arrow.flip_v = exit_only
		if connecting_pipe != null:
			$Node2D/CenterContainer/Label.text = str(connecting_pipe.pipe_id)
	else:
		hide()

func run_player_check(player: Player) -> void:
	if Global.player_action_pressed(get_input_direction(enter_direction), player.player_id) and can_enter:
		can_enter = false
		Checkpoint.passed_checkpoints.clear()
		player.enter_pipe(self, false)
		await get_tree().create_timer(1, false).timeout
		$CanvasLayer.show()
		await get_tree().create_timer(0.25, false).timeout
		connecting_pipe.exit_pipe()
		can_enter = true
		for i in 2:
			await get_tree().physics_frame
		$CanvasLayer.hide()
