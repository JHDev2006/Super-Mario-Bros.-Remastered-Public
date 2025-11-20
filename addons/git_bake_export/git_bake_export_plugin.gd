@tool
extends EditorExportPlugin
class_name GitBakeExportPlugin

func _get_name() -> String:
	return "Git Bake Export Plugin"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	var bake_hash: bool = ProjectSettings.get_setting("application/bake_hash", false)
	var hash: String = get_git_hash() if bake_hash else ""
	var data := {
		"version": version,
		"git_hash": hash
	}

	# Write JSON
	var f := FileAccess.open("res://version.json", FileAccess.WRITE_READ)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

	print("Baked version.json with %s%s" % [version, ("-" + hash) if hash != "" else ""])

func get_git_hash() -> String:
	var hash := ""
	var output := []
	var root := ProjectSettings.globalize_path("res://")

	# Short commit hash
	if OS.execute("git", ["-C", root, "rev-parse", "--short", "HEAD"], output, true) == OK and output.size() > 0:
		hash = output[0].strip_edges()

	# Dirty check
	output.clear()
	if OS.execute("git", ["-C", root, "status", "--porcelain"], output, true) == OK and output.size() > 0:
		hash += "-dirty"

	# Ahead-of-upstream check
	output.clear()
	if OS.execute("git", ["-C", root, "rev-list", "--left-right", "--count", "@{upstream}...HEAD"], output, true) == OK and output.size() > 0:
		var counts: Array = output[0].strip_edges().split("\t")
		if counts.size() == 2 and int(counts[0]) > 0:
			hash += "-dirty"

	return hash
