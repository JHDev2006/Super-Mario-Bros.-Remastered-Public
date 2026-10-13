extends Node2D

signal enemy_killed

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	for i in get_parent().get_children():
		if i is Enemy:
			if i.killed.is_connected(enemy_dead) == false:
				i.killed.connect(enemy_dead.unbind(1))

func enemy_dead(_dir := 0) -> void:
	enemy_killed.emit()
