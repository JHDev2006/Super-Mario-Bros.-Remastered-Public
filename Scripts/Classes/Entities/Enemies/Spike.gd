extends Enemy
const SPIKE_BALL = preload("uid://c7il83r4ab05d")

@export var can_move := false

var can_turn := true

func _ready() -> void:
	$ThrowTimer.start()
	if can_move:
		$TurnTimer.start()

func _physics_process(delta: float) -> void:
	if $TrackJoint.is_attached:
		return
	if can_move:
		$Movement.handle_movement(delta)
	else:
		$StaticMovement.handle_movement(delta)
		var target_player = get_tree().get_first_node_in_group("Players")
		var target_direction = sign(target_player.global_position.x - global_position.x)
		if target_direction != 0 and can_turn:
			direction = target_direction

func throw_ball() -> void:
	can_turn = false
	$Movement.can_move = false
	%Animations.play("BallSpawn")
	await %Animations.animation_finished
	summon_ball()
	%Animations.play("Idle")
	$Movement.can_move = true
	can_turn = true

func summon_ball() -> void:
	var ball = SPIKE_BALL.instantiate()
	ball.global_position = %Ball.global_position
	var parent = get_parent()
	if $TrackJoint.is_attached:
		parent = get_parent().owner.get_parent()
	parent.add_child(ball)
	ball.velocity.x = 100 * direction


func on_timeout() -> void:
	if not $Movement.can_move: return
	var target_player = get_tree().get_first_node_in_group("Players")
	direction = sign(target_player.global_position.x - global_position.x)
