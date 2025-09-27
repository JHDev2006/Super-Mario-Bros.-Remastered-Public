extends Enemy

@export_range(1, 10, 1) var length := 3

var wave := 0.0

func _physics_process(delta: float) -> void:
	handle_collision()
	handle_part_animation(delta)

func handle_collision() -> void:
	$HeadHitbox.position.y = (-length * 16) + 8
	$Collision.shape.size.y = (length * 16) - 2
	$Collision.position.y = -$Collision.shape.size.y / 2
	$BodyHitbox.position.y = $Collision.position.y

func handle_part_animation(delta: float) -> void:
	wave += delta
	for i in $Parts.get_children():
		if i.get_index() > 0:
			i.offset.x = sin(wave * 8) * 1 * [-1, 1][i.get_index() % 2]

func summon_part_gibs() -> void:
	for i in $Parts.get_children():
		if i.visible:
			i.get_node("GibSpawner").summon_gib([-1, 1][i.get_index() % 2])
