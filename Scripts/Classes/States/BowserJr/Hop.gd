extends State

var can_hop := false
var can_move := false

var times_hopped := 0

var direction = 0

func enter(_msg := {}) -> void:
	times_hopped += 1
	can_hop = false
	can_move = %FloorCheck.is_colliding()
	if direction == 0:
		direction = [-1, 1].pick_random()
	else:
		direction *= -1
	var chosen_cast = {-1: %LeftCheck, 1: %RightCheck}[direction]
	if chosen_cast.is_colliding():
		can_hop = true
		hop(direction)
	elif can_move:
		%FloorCheck.position.x = abs(%FloorCheck.position.x) * direction
		owner.velocity.x = 150 * direction
	if await wait(1) == false:
		return
	if randi_range(0, 2) != 0 and times_hopped < 3:
		exit()
		enter()
	else:
		state_machine.transition_to(["Fire", "GroundPound"].pick_random())

func exit() -> void:
	direction = 0

func physics_update(delta: float) -> void:
	if can_move:
		%Movement.handle_movement(delta)
		if can_hop == false:
			can_move = %FloorCheck.is_colliding()
		if owner.is_on_floor():
			%Sprite.play("Idle")

func hop(direction := 1) -> void:
	%Sprite.play("Hop")
	owner.velocity.x = 90 * direction
	owner.velocity.y = -150
