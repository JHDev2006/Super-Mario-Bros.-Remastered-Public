extends Control

var selected_level := 0

signal level_selected
signal cancelled
var active := false

var starting_value := -1

const LEVEL_ICON_JSON_PATH := "res://Assets/Sprites/UI/LevelIcons/LevelIcons.json"

var level_icons := []

const NUMBER_Y := [
	"Overworld",
	"Underground",
	"Castle",
	"Snow",
	"Space",
	"Volcano"
]

@onready var resource_getter := ResourceGetter.new()

@onready var slots := [%Slot1]

var custom_campaign_json := {}

func _ready() -> void:
	add_child(resource_getter)
	for i in %SlotContainer.get_children():
		i.focus_entered.connect(slot_selected.bind(i.get_index()))

func clear_slots() -> void:
	for i in slots:
		if i.get_index() > 0:
			print(i)
			i.free()
			slots.erase(i)

func add_new_slots() -> void:
	var levels_per_world = custom_campaign_json.levels_per_world[Global.world_num - 1]
	for i in levels_per_world - 1:
		var new_slot = %Slot1.duplicate()
		slots.append(new_slot)
		%SlotContainer.add_child(new_slot)

func _process(_delta: float) -> void:
	if active:
		handle_input()
		Global.level_num = selected_level + 1

func open() -> void:
	if starting_value == -1:
		starting_value = Global.level_num
	level_icons = custom_campaign_json.get("level_icons", [])
	selected_level = Global.level_num - 1
	clear_slots()
	add_new_slots()
	setup_level_icon_data()
	setup_visuals()
	show()
	$%SlotContainer.get_child(selected_level).grab_focus()
	await get_tree().create_timer(0.1).timeout
	active = true

var visited_levels := "0000"

const ICON_DAY := ("res://Assets/Sprites/UI/LevelIcons/DayLevelIcons.png")
const ICON_NIGHT := ("res://Assets/Sprites/UI/LevelIcons/NightLevelIcons.png")
const ICON_LOCKED := ("res://Assets/Sprites/UI/LevelIcons/LockedLevelIcon.png")
var icon_size := [56, 32]

func setup_level_icon_data() -> void:
	var json = JSON.parse_string(FileAccess.open(LEVEL_ICON_JSON_PATH, FileAccess.READ).get_as_text())
	icon_size = json.icon_size
	for key in json.icon_data:
		if get(key) is Dictionary and json.icon_data[key] is Dictionary:
			Global.merge_dict(get(key), json.icon_data[key])
		else:
			set(key, json.icon_data[key])

func setup_visuals() -> void:
	var idx := 0
	for i in %SlotContainer.get_children():
		if i.visible == false or level_icons.is_empty() or is_instance_valid(i) == false:
			continue
		var levels_per_world = custom_campaign_json.levels_per_world[Global.world_num - 1]
		var level_theme = Global.LEVEL_THEMES[Global.current_campaign][Global.world_num - 1]
		visited_levels = (SaveManager.visited_levels.substr((Global.world_num - 1) * levels_per_world, levels_per_world))
		var level_visited = SaveManager.visited_levels[SaveManager.get_level_idx(Global.world_num, idx + 1)] != "0" or Global.debug_mode
		var cur_level = level_icons[Global.world_num - 1][idx]
		var cur_icon = ICON_LOCKED if not level_visited else ICON_NIGHT if cur_level[0] == "night" else ICON_DAY
		cur_icon = resource_getter.get_resource(load(cur_icon))
		var grid_size = [cur_icon.get_width() - icon_size[0], cur_icon.get_height() - icon_size[1]]
		var clamp_icon = clamp([cur_level[1][0] * icon_size[0], cur_level[1][1] * icon_size[1]], [0, 0], grid_size)
		i.get_node("Icon").texture = cur_icon
		i.get_node("Icon").region_rect = Rect2(clamp_icon[0], clamp_icon[1], icon_size[0], icon_size[1])
		i.get_node("Icon/Number").region_rect.position.y = clamp(NUMBER_Y.find(level_theme) * 12, 0, 9999)
		i.get_node("Icon/Number").region_rect.position.x = (idx) * 12
		idx += 1

func handle_input() -> void:
	selected_level = clamp(selected_level, 0, 3)
	if Global.multibind_action_just_pressed("ui_accept"):
		if visited_levels[selected_level] == "0" and selected_level != 0 and not Global.debug_mode:
			AudioManager.play_sfx("bump")
		else:
			select_world()
	elif Global.multibind_action_just_pressed("ui_back"):
		close()
		cleanup()
		cancelled.emit()
		return

func select_world() -> void:
	if owner is Level:
		owner.level_id = selected_level + 1
	Global.level_num = selected_level + 1
	level_selected.emit()
	close()

func slot_selected(idx := 0) -> void:
	selected_level = idx
	if Settings.file.audio.extra_sfx == 1:
		AudioManager.play_global_sfx("menu_move")

func cleanup() -> void:
	await get_tree().process_frame
	Global.level_num = starting_value
	starting_value = -1
	Global.level_num = clamp(Global.level_num, 1, 4)
	if owner is Level:
		owner.level_id = clamp(owner.level_id, 1, 8)

func close() -> void:
	active = false
	clear_slots()
	hide()
