extends Node
## Over-the-air updater for the Android build. Does nothing on other platforms.
##
## Two kinds of update, both published as GitHub Release assets by .github/workflows/android-release.yml:
##   1. Content update: a full game .pck (scripts, scenes, art). Downloaded in the background,
##      verified with SHA-256, and mounted at the next launch. No reinstall needed.
##   2. APK update: needed when the native side changed (engine version, permissions...).
##      The player is prompted and the APK download is opened in the system installer flow.
##
## Keep it right after ModLoader (which insists on positions 1-2) and ahead of Global, so a staged .pck is mounted before the game autoloads load.

## Replaced with "owner/repo" by the CI workflow.
const REPO := "__REPO__"
## Sentinel split in two so the CI text substitution above never rewrites it.
const REPO_UNSET := "__REPO" + "__"
const MANIFEST_URL := "https://github.com/%s/releases/latest/download/update.json"
const OTA_DIR := "user://ota"
const PCK_PATH := "user://ota/update.pck"
const STATE_PATH := "user://ota/state.json"
const PENDING_FLAG := "user://ota/boot_pending"
## If the game stays up this long after mounting a .pck, the .pck is considered healthy.
const HEALTHY_AFTER_SECONDS := 10.0

var content_build := 0
var apk_base := 0

# --- Boot: mount a staged .pck before the other autoloads are loaded -------------------------

func _init() -> void:
	if not _is_active():
		return
	DirAccess.make_dir_recursive_absolute(OTA_DIR)
	_mount_staged_pack()

func _is_active() -> bool:
	return OS.has_feature("android") and REPO != REPO_UNSET

func _mount_staged_pack() -> void:
	if not FileAccess.file_exists(PCK_PATH):
		return
	var state := _read_state()
	var own_build := _read_int("res://android_build.txt") # the APK's built-in content, before mounting
	var pck_build := int(state.get("pck_build", 0))

	# Stale: a newer APK was installed since this .pck was downloaded.
	if pck_build <= own_build or int(state.get("pck_apk_base", 0)) > _read_int("res://android_apk_base.txt"):
		_discard_pack(state, false)
		return
	# Crash guard: the flag is only cleared once the game has run healthily after mounting.
	if FileAccess.file_exists(PENDING_FLAG):
		push_warning("OTA: previous boot with build %d never became healthy, discarding it." % pck_build)
		_discard_pack(state, true)
		return

	_write_text(PENDING_FLAG, "1")
	if not ProjectSettings.load_resource_pack(PCK_PATH, true):
		push_warning("OTA: failed to mount update.pck")
		_discard_pack(state, true)

func _discard_pack(state: Dictionary, mark_bad: bool) -> void:
	if mark_bad:
		state["bad_build"] = int(state.get("pck_build", 0))
	state.erase("pck_build")
	state.erase("pck_apk_base")
	_write_state(state)
	DirAccess.remove_absolute(PCK_PATH)
	DirAccess.remove_absolute(PENDING_FLAG)

# --- Runtime: check for updates ---------------------------------------------------------------

func _ready() -> void:
	if not _is_active():
		return
	content_build = _read_int("res://android_build.txt")
	apk_base = _read_int("res://android_apk_base.txt")
	_clear_flag_when_healthy()
	_check_for_update()

func _clear_flag_when_healthy() -> void:
	await get_tree().create_timer(HEALTHY_AFTER_SECONDS).timeout
	DirAccess.remove_absolute(PENDING_FLAG)

func _check_for_update() -> void:
	var result := await _fetch(MANIFEST_URL % REPO, "", 20.0)
	if not result.ok:
		return
	var manifest = JSON.parse_string(result.body.get_string_from_utf8())
	if not manifest is Dictionary:
		return
	var latest := int(manifest.get("build", 0))
	if latest <= content_build:
		return

	if int(manifest.get("apk_base", 0)) > apk_base:
		_show_apk_prompt(manifest)
		return

	var state := _read_state()
	if int(state.get("bad_build", 0)) == latest:
		return # this build crashed on this device before; wait for a newer one
	if int(state.get("pck_build", 0)) == latest and FileAccess.file_exists(PCK_PATH):
		return # already staged, waiting for a restart
	await _download_pack(manifest)

func _download_pack(manifest: Dictionary) -> void:
	var url := str(manifest.get("pck_url", ""))
	var expected_sha := str(manifest.get("pck_sha256", "")).to_lower()
	if url == "" or expected_sha == "":
		return
	var part_path := PCK_PATH + ".part"
	DirAccess.remove_absolute(part_path)
	var result := await _fetch(url, part_path, 600.0)
	if not result.ok:
		DirAccess.remove_absolute(part_path)
		return
	if FileAccess.get_sha256(part_path).to_lower() != expected_sha:
		push_warning("OTA: checksum mismatch, discarding download")
		DirAccess.remove_absolute(part_path)
		return

	DirAccess.remove_absolute(PCK_PATH)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(part_path), ProjectSettings.globalize_path(PCK_PATH))
	var state := _read_state()
	state["pck_build"] = int(manifest.get("build", 0))
	state["pck_apk_base"] = int(manifest.get("apk_base", 0))
	state["version"] = str(manifest.get("version", ""))
	_write_state(state)
	_show_toast("Update %s downloaded. Restart the game to apply it." % str(manifest.get("version", "")))

## Returns {ok: bool, code: int, body: PackedByteArray}. If to_file is set the body is written there instead.
func _fetch(url: String, to_file := "", timeout := 20.0) -> Dictionary:
	var http := HTTPRequest.new()
	http.max_redirects = 8
	http.timeout = timeout
	if to_file != "":
		http.download_file = to_file
	add_child(http)
	if http.request(url) != OK:
		http.queue_free()
		return {"ok": false, "code": 0, "body": PackedByteArray()}
	var r: Array = await http.request_completed
	http.queue_free()
	return {
		"ok": r[0] == HTTPRequest.RESULT_SUCCESS and r[1] == 200,
		"code": r[1],
		"body": r[3]
	}

# --- Minimal UI (independent of the game's own UI so it works on any screen) -------------------

func _make_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	return layer

func _show_toast(text: String) -> void:
	var layer := _make_layer()
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.offset_top = -14
	layer.add_child(label)
	await get_tree().create_timer(6.0, true).timeout
	layer.queue_free()

func _show_apk_prompt(manifest: Dictionary) -> void:
	var apk_url := str(manifest.get("apk_url", ""))
	if apk_url == "":
		return
	var layer := _make_layer()
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var label := Label.new()
	label.text = "App update %s available.\nThis one needs a reinstall." % str(manifest.get("version", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var update_button := Button.new()
	update_button.text = "Download"
	var later_button := Button.new()
	later_button.text = "Later"
	row.add_child(update_button)
	row.add_child(later_button)
	update_button.pressed.connect(func():
		OS.shell_open(apk_url)
		layer.queue_free())
	later_button.pressed.connect(layer.queue_free)
	update_button.grab_focus()

# --- Helpers -------------------------------------------------------------------------------------

func _read_int(path: String) -> int:
	return int(FileAccess.get_file_as_string(path).strip_edges())

func _read_state() -> Dictionary:
	if not FileAccess.file_exists(STATE_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
	return parsed if parsed is Dictionary else {}

func _write_state(state: Dictionary) -> void:
	_write_text(STATE_PATH, JSON.stringify(state))

func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
