class_name ROMVerifier
extends Node

var args = OS.get_cmdline_args()
const VALID_HASH := "c9b34443c0414f3b91ef496d8cfee9fdd72405d673985afa11fb56732c96152b"

func _ready() -> void:
	Global.get_node("GameHUD").hide()
	var validRomFound = false
	for i in args:
		if i.is_valid_filename():
			if(is_valid_rom((i))):
				on_file_dropped(args)
				validRomFound = true 
	if(!validRomFound):
		get_window().files_dropped.connect(on_file_dropped)
	await get_tree().physics_frame
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)	
  
func on_file_dropped(files: PackedStringArray) -> void:
	for i in files:
		if i.contains(".zip"):
			zip_error()
			return
		elif is_valid_rom(i):
			Global.rom_path = i
			verified()
			copy_rom(i)
			return
	error()

func copy_rom(file_path := "") -> void:
	DirAccess.copy_absolute(file_path, Global.ROM_PATH)

static func get_hash(file_path := "") -> String:
	var file_bytes = FileAccess.open(file_path, FileAccess.READ).get_buffer(40976)
	var data = file_bytes.slice(16)
	return Marshalls.raw_to_base64(data).sha256_text()

static func is_valid_rom(rom_path := "") -> bool:
	return get_hash(rom_path) == VALID_HASH

func error() -> void:
	%Error.show()
	$ErrorSFX.play()

func zip_error() -> void:
	$ErrorSFX.play()
	%ZipError.show()

func verified() -> void:
	$BGM.queue_free()
	%DefaultText.queue_free()
	%SuccessMSG.show()
	$SuccessSFX.play()
	await get_tree().create_timer(3, false).timeout
	if not Global.rom_assets_exist:
		Global.transition_to_scene("res://Scenes/Levels/RomResourceGenerator.tscn")
	else:
		Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func create_file_pointer(file_path := "") -> void:
	var pointer = FileAccess.open(Global.ROM_POINTER_PATH, FileAccess.WRITE)
	pointer.store_string(file_path)
	pointer.close()
