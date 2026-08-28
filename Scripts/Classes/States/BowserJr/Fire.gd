extends State

func enter(msg := {}) -> void:
	for i in 3:
		if %VisibleOnScreenEnabler2D.is_on_screen() == false: break
		if await breathe_fire() == false:
			return
	state_machine.transition_to("Idle")

func physics_update(delta: float) -> void:
	%Movement.handle_movement(delta)

func breathe_fire() -> bool:
	%Sprite.play("Breathe")
	if await wait(0.5) == false:
		return false
	owner.shoot_fire()
	%Sprite.play("Fire")
	if await wait(0.5) == false:
		return false
	return true
