extends Control

var selected_world := 0

@export var num_of_worlds := 7

signal world_selected
signal cancelled
var active := false

var custom_campaign_json := {}

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

@onready var resource_getter := ResourceGetter.new()

@onready var world_icons := [%Slot1]

func _ready() -> void:
	add_child(resource_getter)
	for i in %SlotContainer.get_children():
		i.focus_entered.connect(slot_focused.bind(i.get_index()))

func _process(_delta: float) -> void:
	if active:
		handle_input()
		Global.world_num = selected_world + 1

func clear_world_icons() -> void:
	for i in world_icons:
		if i.get_index() > 0:
			world_icons.erase(i)
			i.free()

func open() -> void:
	if starting_value == -1:
		starting_value = Global.world_num
	selected_world = Global.world_num - 1
	clear_world_icons()
	add_worlds()
	setup_visuals()
	show()
	await get_tree().process_frame
	selected_world = clamp(selected_world, 0, %SlotContainer.get_child_count() - 1)
	$%SlotContainer.get_child(selected_world).grab_focus()
	active = true

func add_worlds() -> void:
	var idx := 0
	for i in custom_campaign_json.number_of_worlds:
		if idx > 0:
			var new_slot = %Slot1.duplicate()
			world_icons.append(new_slot)
			%SlotContainer.add_child(new_slot)
			new_slot.focus_entered.connect(slot_focused.bind(idx))
		idx += 1

func setup_visuals() -> void:
	print(custom_campaign_json)
	var idx := 0
	for i in %SlotContainer.get_children():
		if is_instance_valid(i) == false:
			continue
		var level_theme = custom_campaign_json.world_themes[idx][0]
		var campaign_idx = ["Day", "Night"].find(custom_campaign_json.world_themes[idx][1])
		print(custom_campaign_json["levels_per_world"])
		var levels_per_world = custom_campaign_json["levels_per_world"][idx]
		var world_visited = (SaveManager.visited_levels.substr((idx) * levels_per_world, levels_per_world) != "0".repeat(levels_per_world) or Global.debug_mode or idx == 0)
		if world_visited == false:
			level_theme = "Mystery"
		i.get_node("Icon").region_rect = CustomLevelContainer.THEME_RECTS.get(level_theme, CustomLevelContainer.THEME_RECTS.Overworld)
		i.get_node("Icon").texture = resource_getter.get_resource(load(CustomLevelContainer.ICON_TEXTURES[campaign_idx]), false)
		i.get_node("Icon/Number").position.y = 17
		i.get_node("Icon/Number").region_rect.position.y = clamp(NUMBER_Y.find(level_theme) * 12, 0, 76)
		i.get_node("Icon/Number").region_rect.position.x = clamp((idx) * 12, 0, 160)
		idx += 1

func handle_input() -> void:
	if Global.multibind_action_just_pressed("ui_accept"):
		if SaveManager.visited_levels.substr((selected_world) * 4, 4) == "0000" and not Global.debug_mode and selected_world != 0:
			AudioManager.play_sfx("bump")
		else:
			select_world()
	elif Global.multibind_action_just_pressed("ui_back"):
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
		owner.world_id = selected_world + 1
	Global.world_num = selected_world + 1
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
	clear_world_icons()
	hide()
