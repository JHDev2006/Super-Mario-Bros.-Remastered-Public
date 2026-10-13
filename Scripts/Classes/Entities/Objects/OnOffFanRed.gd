extends AnimatableBody2D

@export_enum("Right", "Left", "Up", "Down") var direction := 0
@export_range(1, 4, 1) var strength := 1

@export var active := false

func turn_on() -> void:
	active = true

func turn_off() -> void:
	active = false

func _physics_process(_delta: float) -> void:
	$Particles.amount = strength * 2
	$Particles.speed_scale = strength / 2.0
	$Sprite.speed_scale = strength / 2.0
	if active:
		for i in $Hitbox.get_overlapping_areas():
			if i.owner is CharacterBody2D:
				var wind_velocity = Vector2.RIGHT.rotated(global_rotation) * (strength * 2)
				var modifier = Vector2.ONE
				if i.owner is Player:
					if Global.player_action_pressed("jump", i.owner.player_id):
						modifier.y = 2
					if Global.player_action_pressed("move_down", i.owner.player_id):
						modifier.y = 0.5
				var distance = 0
				if direction > 1:
					distance = ((abs(i.owner.global_position.y - global_position.y) / modifier.y) / 250)
				else:
					distance = ((abs(i.owner.global_position.x - global_position.x) / modifier.x) / 250)
				i.owner.velocity += (wind_velocity / distance / Vector2(2, 1))
	$Particles.emitting = active
	$Sprite.play("On" if active else "Off")
