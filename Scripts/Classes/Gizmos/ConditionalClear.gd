class_name ConditionalClear
extends Node2D

@export_enum("Validate", "Fail") var on_power := 0

@export var statement := ""

static var valid := true
static var checked := false

func on_level_start() -> void:
	$CanvasLayer.hide()
	if checked == false:
		valid = on_power
		if statement != "":
			%Title.text = "Clear Condition" if on_power == 0 else "Fail Condition"
			%Description.text = statement
			$CanvasLayer.show()
			$CanvasLayer/AnimationPlayer.play("Show")
			$CanvasLayer/PauseDisplay/VBoxContainer/Title.text = %Title.text
			$CanvasLayer/Description/VBoxContainer/Description.text = %Description.text
	checked = true

func _process(delta: float) -> void:
	$CanvasLayer/PauseDisplay.visible = Global.game_paused

func powered() -> void:
	if on_power == 0:
		validate()
	else:
		ruin()

func validate() -> void:
	valid = true
	$CanvasLayer/AnimationPlayer.play("Cleared")
	AudioManager.play_global_sfx("correct")

func ruin() -> void:
	valid = false
	$CanvasLayer/AnimationPlayer.play("Fail")
	await get_tree().create_timer(0.5, false).timeout
	get_tree().call_group("Players", "die")
