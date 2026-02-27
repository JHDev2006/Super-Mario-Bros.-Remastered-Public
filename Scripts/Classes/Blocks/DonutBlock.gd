extends StaticBody2D

var falling := false
var can_fall := false

const FALL_SPEED := 96

@onready var starting_position := global_position

func _physics_process(delta: float) -> void:
	if falling:
		global_position.y += FALL_SPEED * delta
	if $PlayerDetection.is_player_in_area():
		$Sprite.play("Fall")
	elif not falling:
		$Sprite.play("Idle")

func start_falling() -> void:
	falling = true
	$Collision.set_deferred("one_way_collision", true)
	$FallTimer.start()


func respawn() -> void:
	$Collision.set_deferred("one_way_collision", false)
	can_fall = true
	falling = false
	global_position = starting_position
	$Sprite.scale = Vector2.ZERO
	$AnimationPlayer.play("Grow")
	reset_physics_interpolation()


func on_player_entered() -> void:
	$AnimationPlayer.play("Shake")


func on_player_exited() -> void:
	$AnimationPlayer.play("RESET")
