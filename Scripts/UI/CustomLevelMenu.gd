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

func _ready() -> void:
	has_entered = true
	ResourceSetterNew.cache.clear()
	ResourceSetter.cache.clear()
	Global.get_node("GameHUD").hide()
	Checkpoint.passed_checkpoints.clear()
	Global.world_num = 1
	Global.level_num = 1
	Global.reset_values()
	Checkpoint.sublevel_id = 0
	Global.current_campaign = "SMB1"
	AudioManager.stop_all_music()
	Global.second_quest = false
	%LevelList.open(true)
	await get_tree().process_frame
	if last_played_container != null:
		print(saved_search_values)
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

func clear_saved_stuff() -> void:
	%LSSLevelInfo.saved_stuff.clear()
	saved_search_values = [-1, -1, -1]
	%LSSBrowser.number_of_pages = -1

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func new_level() -> void:
	Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	LevelEditor.load_play = false
	LevelEditor.level_name = ""
	LevelEditor.level_author = ""
	LevelEditor.level_desc = ""
	LevelEditor.difficulty = 0
	LevelEditor.level_file = LevelEditor.BLANK_FILE.duplicate(true)
	Global.transition_to_scene("res://Scenes/Levels/LevelEditor.tscn")

func back_to_title_screen() -> void:
	clear_saved_stuff()
	if Global.transitioning_scene:
		await Global.transition_finished
	Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func edit_level() -> void:
	clear_saved_stuff()
	Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	LevelEditor.load_play = false
	Global.transition_to_scene("res://Scenes/Levels/LevelEditor.tscn")

func play_level() -> void:
	Global.current_game_mode = Global.GameMode.CUSTOM_LEVEL
	Settings.file.difficulty.inf_lives = 1
	LevelEditor.load_play = true
	$CharacterSelect.open()
	await $CharacterSelect.selected
	LevelTransition.level_to_transition_to = ("res://Scenes/Levels/LevelEditor.tscn")
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func online_play() -> void:
	lss_level_played()
	Global.current_game_mode = Global.GameMode.CUSTOM_LEVEL
	Settings.file.difficulty.inf_lives = 1
	LevelEditor.load_play = true
	$LSSCharacterSelect.open()
	await $LSSCharacterSelect.selected
	LevelTransition.level_to_transition_to = ("res://Scenes/Levels/LevelEditor.tscn")
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func lss_level_played() -> void:
	last_played_container = %LSSLevelInfo.container_to_play.duplicate()
	level_id = %LSSLevelInfo.container_to_play.level_id
	print(level_id)
	page_number_save = %LSSBrowser.page_number
	saved_search_values[0] = %LSSBrowser.page_number
	saved_search_values[1] = %LSSBrowser.filter
	saved_search_values[2] = %LSSBrowser.order

func delete_level() -> void:
	DirAccess.remove_absolute(current_level_file)
	go_back_to_list()
	%LevelList.refresh()
	if %LevelList.containers.is_empty() == false:
		%LevelList.containers[0].grab_focus()
	else:
		$BG/Border/Levels/VBoxContainer/LevelList/TopBit/Button.grab_focus()

func go_back_to_list() -> void:
	$BG/Border/Levels/VBoxContainer/LevelList.show()
	%LevelInfo.hide()

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
