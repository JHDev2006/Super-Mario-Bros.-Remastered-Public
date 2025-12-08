extends Node

static var selected_index := 0

var active := true
var boo_index := 0

const levels := {
	"SMB1": SMB1_LEVELS,
	"SMBLL": SMBLL_LEVELS,
	"SMBS": SMBS_LEVELS
}

const SMB1_LEVELS := [
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo1-1.tscn",
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo1-2.tscn",
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo1-3.tscn",
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo1-4.tscn",
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo2-1.tscn",
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo2-2.tscn",
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo2-3.tscn",
	"res://Scenes/Levels/SMB1/YouVSBoo/Boo2-4.tscn"
]

const SMBLL_LEVELS := [
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo1-1.tscn",
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo1-2.tscn",
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo1-3.tscn",
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo1-4.tscn",
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo2-1.tscn",
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo2-2.tscn",
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo2-3.tscn",
	"res://Scenes/Levels/SMBLL/YouVSBoo/Boo2-4.tscn",
]

const SMBS_LEVELS := [
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo1-1.tscn", 
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo1-2.tscn",
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo1-3.tscn",
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo1-4.tscn",
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo2-1.tscn",
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo2-2.tscn",
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo2-3.tscn",
	"res://Scenes/Levels/SMBS/YouVsBoo/Boo2-4.tscn"
]

func _ready() -> void:
	AudioManager.stop_all_music()
	Global.player_power_states = "0000"
	Global.get_node("GameHUD").hide()
	boo_index = BooRaceHandler.boo_colour
	Global.current_game_mode = Global.GameMode.BOO_RACE
	Global.reset_values()
	LevelPersistance.reset_states()
	Level.first_load = true
	Level.can_set_time = true
	setup_visuals()
	%LevelLabels.get_child(BooRaceHandler.current_level_id).grab_focus()
	$Music.play()

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func setup_visuals() -> void:
	for i in %LevelLabels.get_child_count():
		if i >= 1:
			var level_unlocked = int(BooRaceHandler.cleared_boo_levels[i - 1]) > 0
			%LevelLabels.get_child(i).modulate = Color.WHITE if level_unlocked else Color.DIM_GRAY
			%LevelLabels.get_child(i).get_node("Control/Sprite2D").visible = level_unlocked
		if int(BooRaceHandler.cleared_boo_levels[i]) > 0:
			%LevelLabels.get_child(i).get_node("Control/Sprite2D").frame = clamp(int(BooRaceHandler.cleared_boo_levels[i]), 0, 4)
			%LevelLabels.get_child(i).get_node("Control/Sprite2D").modulate = Color.DIM_GRAY if int(BooRaceHandler.cleared_boo_levels[i]) >= 5 else Color.WHITE
	for i in %Boos.get_children():
		if i is Node2D:
			i.visible = $BooSelect.selected_boo == int(i.name)
			i.modulate = Color.BLACK if int(BooRaceHandler.cleared_boo_levels[selected_index]) < int(i.name) else Color.WHITE
			if int(BooRaceHandler.cleared_boo_levels[selected_index]) > int(i.name):
				i.modulate = Color.DIM_GRAY
			i.play("Lose" if int(BooRaceHandler.cleared_boo_levels[selected_index]) > int(i.name) else "Idle")

func _process(_delta: float) -> void:
	handle_input()
	$BooSelect.lvl_idx = selected_index

func open() -> void:
	active = true

func set_current_level_idx(new_idx := 0) -> void:
	selected_index = new_idx
	update_pb()

func update_pb() -> void:
	var pb_string := "--:--:--"
	if BooRaceHandler.best_times[selected_index] >= 0:
		pb_string = SpeedrunHandler.gen_time_string(SpeedrunHandler.format_time(BooRaceHandler.best_times[selected_index]))
	%PB.text = "PB: " + pb_string

func handle_input() -> void:
	if active == false:
		return
	if Input.is_action_just_pressed("ui_back"):
		TitleScreen.return_to = TitleScreen.TITLE_RETURN.CHALLENGEOPTIONS
		TitleScreen.return_selected_index = 0
		Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
	if Input.is_action_just_pressed("ui_accept"):
		level_selected()

func regrab_focus() -> void:
	%LevelLabels.get_child(selected_index).grab_focus()

func level_selected() -> void:
	if selected_index > 0:
		if int(BooRaceHandler.cleared_boo_levels[selected_index - 1]) <= 0 and not Global.debug_mode:
			AudioManager.play_global_sfx("bump")
			return
	active = false
	Global.reset_values()
	Global.clear_saved_values()
	ResourceSetter.cache.clear()
	ResourceSetterNew.cache.clear()
	$BooSelect.open()
	await $CharacterSelect.selected
	Global.transition_to_scene(levels[Global.current_campaign][selected_index])
