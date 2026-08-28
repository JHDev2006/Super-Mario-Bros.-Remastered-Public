class_name CustomLevelMenu
extends Node

static var current_level_file := ""

static var has_entered := false

var selected_lvl_idx := 0
const base64_charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
static var page_number_save := -1
static var last_played_container = null

static var saved_search_values := [-1, -1, -1]
static var level_id := ""

func _input(event: InputEvent) -> void:
	if (event is InputEventKey):
		if get_viewport().gui_get_focus_owner() == null or ($CharacterSelect.visible or $LSSCharacterSelect.visible):
			if (%LevelList.visible):
				$BG/Border/Levels/VBoxContainer/LevelList/TopBit/Button.grab_focus()
			if (%LevelInfo.visible):
				%Play.grab_focus()
				if not %Play.visible:
					%Edit.grab_focus()
			if (%LSSBrowser.visible):
				%RefreshList.grab_focus()
			if (%LSSLevelInfo.visible):
				%Download.grab_focus()
				if not %Download.visible:
					%OnlinePlay.grab_focus()
			if (%AutosavesList.visible and not $AutosaveSettings.visible):
				$BG/Border/Levels/VBoxContainer/AutosavesList/OpenSettings/SelectableLabel.grab_focus()
			if $AutosaveSettings.visible:
				$AutosaveSettings/Panel/ScrollContainer/Options/Enable.grab_focus()
			
func _ready() -> void:
	has_entered = true
	ResourceSetter.cache.clear()
	ResourceSetterNew.clear_cache()
	
	AudioManager.stop_all_music()
	Global.get_node("GameHUD").hide()
	Global.clear_saved_values()
	Global.reset_values()
	Global.current_campaign = "SMB1"
	Global.level_theme_changed.emit()
	Global.world_num = 1
	Global.level_num = 1
	Global.second_quest = false
	
	LevelEditor.sub_areas = [null, null, null, null, null]
	LevelEditor.sub_level_id = 0
	LevelEditor.selected_tile_index = 0
	LevelEditor.last_camera_position = Vector2(-128, -88)
	
	Checkpoint.sublevel_id = 0
	%LevelList.open(true)
	await get_tree().process_frame
	if last_played_container != null:
		%LSSBrowser.setup_page_numbers()
		%LSSBrowser.page_number = saved_search_values[0]
		%Page.selected_index = saved_search_values[0] - 1
		
		%LSSBrowser.filter = saved_search_values[1]
		%Sort.selected_index = saved_search_values[1]
		
		%LSSBrowser.order = saved_search_values[2]
		%Order.selected_index = %LSSBrowser.order
		
		%LSSLevelInfo.open(last_played_container)
		await get_tree().process_frame
		%LSSBrowser.grab_levels()
		%LevelList.close()
	$BGM.play()

func _process(delta: float) -> void:
	if ($CharacterSelect.visible):
		$CharacterSelect.grab_focus()
	if ($LSSCharacterSelect.visible):
		$LSSCharacterSelect.grab_focus()

func clear_saved_stuff() -> void:
	last_played_container = null
	%LSSLevelInfo.saved_stuff.clear()
	saved_search_values = [-1, -1, -1]
	%LSSBrowser.number_of_pages = -1

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func new_level() -> void:
	LevelEditor.load_play = false
	LevelEditor.level_name = LevelEditor.set_stack_level_name("UNNAMED LEVEL")
	LevelEditor.level_author = "PLAYER"
	LevelEditor.level_desc = ""
	LevelEditor.difficulty = 0
	LevelEditor.level_file = LevelEditor.BLANK_FILE.duplicate(true)
	
	Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	Global.transition_to_scene("res://Scenes/Levels/LevelEditor.tscn")

func back_to_title_screen() -> void:
	clear_saved_stuff()
	Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func edit_level() -> void:
	clear_saved_stuff()
	LevelEditor.load_play = false
	LevelEditor.current_layer = 0
	
	Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	Global.transition_to_scene("res://Scenes/Levels/LevelEditor.tscn")
	
	NewLevelBuilder.load_level(LevelEditor.level_file)

func play_level() -> void:
	Global.current_game_mode = Global.GameMode.CUSTOM_LEVEL
	LevelEditor.load_play = true
	$CharacterSelect.open()
	await $CharacterSelect.selected
	LevelTransition.level_to_transition_to = ("res://Scenes/Levels/LevelEditor.tscn")
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func online_play() -> void:
	lss_level_played()
	Global.current_game_mode = Global.GameMode.CUSTOM_LEVEL
	LevelEditor.load_play = true
	$LSSCharacterSelect.open()
	await $LSSCharacterSelect.selected
	LevelTransition.level_to_transition_to = ("res://Scenes/Levels/LevelEditor.tscn")
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func lss_level_played() -> void:
	last_played_container = %LSSLevelInfo.container_to_play.duplicate()
	level_id = %LSSLevelInfo.container_to_play.level_id
	page_number_save = %LSSBrowser.page_number
	saved_search_values[0] = %LSSBrowser.page_number
	saved_search_values[1] = %LSSBrowser.filter
	saved_search_values[2] = %LSSBrowser.order

func delete_level() -> void:
	DirAccess.remove_absolute(current_level_file)
	if %AutosaveTime.visible:
		go_back_to_autosaves()
		%AutosavesList.refresh()
	else:
		go_back_to_list()
		%LevelList.refresh()
		if %LevelList.containers.is_empty() == false:
			%LevelList.containers[0].grab_focus()
		else:
			$BG/Border/Levels/VBoxContainer/LevelList/TopBit/Button.grab_focus()

func go_back_to_list() -> void:
	$BG/Border/Levels/VBoxContainer/LevelList.show()
	%LevelInfo.hide()

func go_back_to_autosaves() -> void:
	%LevelInfo.close()
	%AutosavesList.open()

func open_lss_browser() -> void:
	$BG/Border/Levels/VBoxContainer/LevelList.hide()
	%LSSBrowser.open()

func show_lss_level_info(container: OnlineLevelContainer) -> void:
	for i in ["level_name", "level_author", "level_theme", "level_id", "thumbnail_url"]:
		%SelectedOnlineLevel.set(i, container.get(i))
	%SelectedOnlineLevel.setup_visuals()
	LevelEditor.level_name = container.level_name
	LevelEditor.level_author = container.level_author
	%LSSDescription.text = "Fetching Description..."
	$BG/Border/Levels/VBoxContainer/LSSBrowser.hide()
	%LSSLevelInfo.show()
	await get_tree().physics_frame
	%Download.grab_focus()
