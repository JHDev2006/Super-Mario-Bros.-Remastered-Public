extends PlayerState

var wave := 0.0

var old_x = 0

func enter(_msg := {}) -> void:
	old_x = player.sprite.position.x
	player.velocity.x = 0
	%ShakeLines.show()
	player.play_animation("Stunned")
	if await wait(1.5) == false:
		return
	state_machine.transition_to("Normal")

func physics_update(delta: float) -> void:
	wave = fmod(wave + delta, PI * 2)
	player.sprite.position.x = sin(wave * 64)
	player.apply_gravity(delta)
	player.move()

func exit() -> void:
	player.sprite.position.x = old_x
	%ShakeLines.hide()
