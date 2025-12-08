class_name AchievementMenu
extends Node

const ACHIEVEMENT_CONTAINER = ("uid://8wnmuhtwu8ib")

var total_unlocked := 0

static var unlocked_achievements := "0000000000000000000000000000"

func _ready() -> void:
	unlocked_achievements = Global.achievements
	spawn_achievement_containers()
	$BG/Border/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.get_child(0).grab_focus()
	Global.get_node("GameHUD").hide()
	var percent = int((float(total_unlocked) / Global.achievements.length()) * 100)
	%Progress.text = str(percent) + "% "
	if percent == 100:
		%Progress.modulate = Color("FFB259")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_back"):
		TitleScreen.return_to = TitleScreen.TITLE_RETURN.EXTRAS
		TitleScreen.return_selected_index = 0
		Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func spawn_achievement_containers() -> void:
	var idx := 0
	for i in Global.achievements:
		if Global.HIDDEN_ACHIEVEMENTS.has(idx) and Global.achievements[idx] == "0":
			idx += 1
			continue
		var container = load(ACHIEVEMENT_CONTAINER).instantiate()
		container.achievement_id = idx
		container.unlocked = i == "1" or Global.debug_mode
		if i == "1":
			total_unlocked += 1
		else:
			if $ProgressCalculators.has_node(str(idx)):
				container.total_needed = $ProgressCalculators.get_node(str(idx)).target_number
				container.progress = $ProgressCalculators.get_node(str(idx)).get_progress()
		$BG/Border/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(container)
		idx += 1

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()
