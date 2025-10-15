extends Area2D

func area_entered(area: Area2D) -> void:
	if area.owner is Player and area.name != "HammerHitbox" and area.owner.state_machine.state.name != "Dead":
		area.owner.die(true)
