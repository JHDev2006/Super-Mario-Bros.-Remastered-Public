class_name ROMVerifier
extends Node

# Array of valid ROM hashes
const VALID_HASH := [
	"c9b34443c0414f3b91ef496d8cfee9fdd72405d673985afa11fb56732c96152b"
]

var args: PackedStringArray

func _ready() -> void:
	args = OS.get_cmdline_args()
	Global.get_node("GameHUD").hide()

	# Try command line ROMs first
	for path in args:
		if path.is_valid_filename():
			if handle_rom(path):
				return
	
	# Fallback: local ROM
	var local_rom := find_local_rom()
	if local_rom != "" and handle_rom(local_rom):
		return
	
	# Otherwise wait for dropped files
	get_window().files_dropped.connect(on_file_dropped)
	await get_tree().physics_frame

	# Window setup
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func find_local_rom() -> String:
	var exe_dir := OS.get_executable_path().get_base_dir()
	var dir := DirAccess.open(exe_dir)
	if not dir:
		return ""
	for file_name in dir.get_files():
		if file_name.to_lower().ends_with(".nes"):
			return exe_dir.path_join(file_name)
	return ""

func on_file_dropped(files: PackedStringArray) -> void:
	for file in files:
		if file.ends_with(".zip"):
			zip_error()
			return
		if handle_rom(file):
			return
	error()

func handle_rom(path: String) -> bool:
	if not is_valid_rom(path):
		return false
	Global.rom_path = path
	copy_rom(path)
	verified()
	return true

func copy_rom(file_path: String) -> void:
	DirAccess.copy_absolute(file_path, Global.ROM_PATH)

static func get_hash(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	var file_bytes := file.get_buffer(40976)
	var data := file_bytes.slice(16)
	return Marshalls.raw_to_base64(data).sha256_text()

static func is_valid_rom(rom_path: String) -> bool:
	var hash := get_hash(rom_path)
	return hash in VALID_HASH

func error() -> void:
	%Error.show()
	$ErrorSFX.play()

func zip_error() -> void:
	%ZipError.show()
	$ErrorSFX.play()

func verified() -> void:
	$BGM.queue_free()
	%DefaultText.queue_free()
	%SuccessMSG.show()
	$SuccessSFX.play()
	await get_tree().create_timer(3, false).timeout
	
	var target_scene := "res://Scenes/Levels/TitleScreen.tscn"
	if not Global.rom_assets_exist:
		target_scene = "res://Scenes/Levels/RomResourceGenerator.tscn"
	Global.transition_to_scene(target_scene)

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func create_file_pointer(file_path: String) -> void:
	var pointer := FileAccess.open(Global.ROM_POINTER_PATH, FileAccess.WRITE)
	if pointer:
		pointer.store_string(file_path)
		pointer.close()
