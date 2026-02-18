extends Enemy

var in_egg := false

const MOVE_SPEED := 40

func _ready():
	if Settings.file.difficulty.spiny_style == 1:
		$BlockBouncingDetection.block_bounced.connect(die_from_object.bind())
		$BlockBouncingDetection.block_bounced.connect($ScoreNoteSpawner.spawn_note.bind(200))
	else:
		# SkyanUltra: Original block bump behavior. Will get sent upwards instead of being defeated.
		$BlockBouncingDetection.block_bounced.connect(bounce_from_object.bind())

func _physics_process(delta: float) -> void:
	handle_movement(delta)

func handle_movement(_delta: float) -> void:
	if in_egg:
		$BasicEnemyMovement.move_speed = 0
		$BasicEnemyMovement.second_quest_speed = 0
		if is_on_floor():
			var player = get_tree().get_first_node_in_group("Players")
			direction = sign(player.global_position.x - global_position.x)
			$BasicEnemyMovement.move_speed = 32
			$BasicEnemyMovement.second_quest_speed = 36
			in_egg = false
		$Sprite.play("Egg")
	else:
		$Sprite.play("Walk")
		$Sprite.scale.x = direction

func stomped(player: Player):
	if in_egg:
		damage_player(player)
	else:
		$GibSpawner.stomp_die(player)
