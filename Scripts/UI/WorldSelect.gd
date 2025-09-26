extends Control

var selected_world := 0

@export var world_offset := 0

@export var num_of_worlds := 7

signal world_selected
signal cancelled
var active := false

var cursor_index := 0

var starting_value := -1

const NUMBER_Y := [
	"Overworld",
	"Underground",
	"Castle",
	"Snow",
	"Space",
	"Volcano"
]

func _ready() -> void:
	for i in %SlotContainer.get_children():
		i.focus_entered.connect(slot_focused.bind(i.get_index()))

func _process(_delta: float) -> void:
	if active:
		handle_input()
		Global.world_num = selected_world + 1 + world_offset

func open() -> void:
	if starting_value == -1:
		starting_value = Global.world_num
	selected_world = Global.world_num - 1 - world_offset
	setup_visuals()
	show()
	await get_tree().process_frame
	if Global.current_game_mode != Global.GameMode.CAMPAIGN:
		selected_world = clamp(selected_world, 0, 7)
	$%SlotContainer.get_child(selected_world).grab_focus()
	active = true

func setup_visuals() -> void:
	var idx := 0
	%Slot1.focus_neighbor_left = %Slot8.get_path()
	%Slot8.focus_neighbor_right = %Slot1.get_path()
	if Global.current_campaign == "SMBLL" && (Global.game_beaten or Global.debug_mode) && Global.current_game_mode == Global.GameMode.CAMPAIGN:
		%Slot1.focus_neighbor_left = %Slot13.get_path()
		%Slot8.focus_neighbor_right = %Slot9.get_path()
	for i in %SlotContainer.get_children():
		if idx >= 8:
			i.visible = Global.current_campaign == "SMBLL" && (Global.game_beaten or Global.debug_mode) && Global.current_game_mode == Global.GameMode.CAMPAIGN
		if i.visible == false:
			idx += 1
			continue
		var level_theme = Global.LEVEL_THEMES[Global.current_campaign][idx + world_offset]
		var world_visited = (SaveManager.visited_levels.substr((idx + world_offset) * 4, 4) != "0000" or Global.debug_mode or idx == 0)
		if world_visited == false:
			level_theme = "Mystery"
		var resource_getter = ResourceGetter.new() #Is it safe to be making a new one of these per icon?
		i.get_node("Icon").region_rect = CustomLevelContainer.THEME_RECTS[level_theme]
		i.get_node("Icon").texture = resource_getter.get_resource(CustomLevelContainer.ICON_TEXTURES[0 if (idx <= 3 or idx >= 8) and Global.current_campaign != "SMBANN" else 1])
		i.get_node("Icon/Number").region_rect.position.y = clamp(NUMBER_Y.find(level_theme) * 12, 0, 9999)
		i.get_node("Icon/Number").region_rect.position.x = (idx + world_offset) * 12
		idx += 1

func handle_input() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if SaveManager.visited_levels.substr((selected_world + world_offset) * 4, 4) == "0000" and not Global.debug_mode and selected_world != 0:
			AudioManager.play_sfx("bump")
		else:
			select_world()
	elif Input.is_action_just_pressed("ui_back"):
		close()
		cleanup()
		cancelled.emit()
		return

func slot_focused(idx := 0) -> void:
	selected_world = idx
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_global_sfx("menu_move")

func select_world() -> void:
	if owner is Level:
		owner.world_id = selected_world + world_offset + 1
	Global.world_num = selected_world + world_offset + 1
	world_selected.emit()
	close()

func cleanup() -> void:
	await get_tree().physics_frame
	Global.world_num = starting_value
	starting_value = -1
	Global.world_num = clamp(Global.world_num, 1, Level.get_world_count())
	if owner is Level:
		owner.world_id = clamp(owner.world_id, 1, Level.get_world_count())

func close() -> void:
	active = false
	Global.world_num = 1
	hide()
