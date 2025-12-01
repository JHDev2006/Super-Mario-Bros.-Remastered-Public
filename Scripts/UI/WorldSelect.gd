extends Control

var selected_world := 0

@export var has_speedrun_stuff := false
@export var has_challenge_stuff := false
@export var has_disco_stuff := false

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

const RANK_MEDALS := preload("res://Assets/Sprites/UI/RankMedals.png")

func _ready() -> void:
	for i in %SlotContainer.get_children():
		i.focus_entered.connect(slot_focused.bind(i.get_index()))
	# SkyanUltra: lowkey kind of hate you joe for how this
	# is implemented but ngl it works so why complain i guess
	var slot_container = [
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot1/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot1/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot2/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot2/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot3/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot3/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot4/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot4/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot5/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot5/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot6/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot6/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot7/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot7/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot8/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot8/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot9/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot9/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot10/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot10/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot11/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot11/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot12/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot12/Icon/Medal/Full/PRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot13/Icon/Medal/Full/SRankParticles,
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/SlotContainer/Slot13/Icon/Medal/Full/PRankParticles,
	]
	for i in slot_container:
		start_particle(i)

func start_particle(particle: GPUParticles2D) -> void:
	await get_tree().create_timer(randf_range(0, 5)).timeout
	particle.emitting = true

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
		setup_marathon_bits(i.get_node("Icon/Medal"), i.get_node("Icon/Medal/Full"), idx + world_offset)
		setup_disco_bits(i.get_node("Icon/Medal"), i.get_node("Icon/Medal/Full"), i.get_node("Icon/Medal/Full/SRankParticles"), i.get_node("Icon/Medal/Full/PRankParticles"), idx + world_offset)
		idx += 1

func setup_disco_bits(medal_outline: TextureRect, medal: NinePatchRect, s_rank_pfx: GPUParticles2D, p_rank_pfx: GPUParticles2D, world_num := 1) -> void:
	if has_disco_stuff == false: return
	var saved_rank_ids = []
	var lowest_rank = -1
	for i in 4:
		saved_rank_ids.append(DiscoLevel.level_ranks[SaveManager.get_level_idx(world_num + 1, i + 1)])
		for rank in DiscoLevel.RANK_IDs.size():
			if DiscoLevel.RANK_IDs[rank] == saved_rank_ids[i] and (lowest_rank > rank + 1 or lowest_rank < 0):
				lowest_rank = rank + 1
	medal_outline.visible = true
	medal.texture = RANK_MEDALS
	medal.visible = lowest_rank != -1
	var medal_rect_x = lowest_rank * 8
	medal.region_rect = Rect2(medal_rect_x, 16, 8, 8)
	s_rank_pfx.visible = lowest_rank == 6
	p_rank_pfx.visible = lowest_rank == 7
	

func setup_marathon_bits(medal_outline: TextureRect, medal: NinePatchRect, world_num := 1) -> void:
	if has_speedrun_stuff == false: return
	var saved_medal_ids = []
	for i in 4:
		var best_warpless_time = SpeedrunHandler.best_level_warpless_times[world_num][i]
		var best_any_time = SpeedrunHandler.best_level_any_times.get(str(world_num + 1) + "-" + str(i + 1), -1)
		var gold_warpless_time = SpeedrunHandler.LEVEL_GOLD_WARPLESS_TIMES[Global.current_campaign][world_num][i]
		var gold_any_time := -1.0
		if SpeedrunHandler.LEVEL_GOLD_ANY_TIMES[Global.current_campaign].has(str(world_num + 1) + "-" + str(i + 1)):
			gold_any_time = SpeedrunHandler.LEVEL_GOLD_ANY_TIMES[Global.current_campaign][str(world_num + 1) + "-" + str(i + 1)]
		var medal_id = -1
		for o in SpeedrunHandler.MEDAL_CONVERSIONS:
			var target_time = gold_warpless_time * SpeedrunHandler.MEDAL_CONVERSIONS[o]
			medal_id += 1 if SpeedrunHandler.met_target_time(best_warpless_time, target_time) else 0
		saved_medal_ids.append(medal_id)
		if gold_any_time != -1:
			medal_id = -1
			for o in SpeedrunHandler.MEDAL_CONVERSIONS:
				var target_time = gold_any_time * SpeedrunHandler.MEDAL_CONVERSIONS[o]
				medal_id += 1 if SpeedrunHandler.met_target_time(best_any_time, target_time) else 0
			saved_medal_ids.append(medal_id)
	medal_outline.visible = true
	medal.visible = saved_medal_ids.min() >= 0
	var medal_rect_x = saved_medal_ids.min() * 8
	medal.region_rect = Rect2(medal_rect_x, 0, 8, 8)

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
