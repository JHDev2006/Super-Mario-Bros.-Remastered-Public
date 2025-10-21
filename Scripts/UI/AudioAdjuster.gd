extends Node

func master_changed(new_value := 0) -> void:
	AudioServer.set_bus_volume_linear(0, float(new_value) / 10)
	Settings.file.audio.master = new_value

func music_changed(new_value := 0) -> void:
	AudioServer.set_bus_volume_linear(1, float(new_value) / 10)
	Settings.file.audio.music = new_value

func sfx_changed(new_value := 0) -> void:
	AudioServer.set_bus_volume_linear(2, float(new_value) / 10)
	Settings.file.audio.sfx = new_value

func athletic_changed(new_value := 0) -> void:
	Settings.file.audio.extra_bgm = new_value

func skid_changed(new_value := 0) -> void:
	Settings.file.audio.skid_sfx = new_value

func extra_sfx_changed(new_value := 0) -> void:
	Settings.file.audio.extra_sfx = new_value

func pause_bgm_changed(new_value := 0) -> void:
	Settings.file.audio.pause_bgm = new_value

func menu_bgm_changed(new_value := 0) -> void:
	Settings.file.audio.menu_bgm = new_value

func blank(_hello := 0) -> void:
	pass

func set_value(value_name := "", value := 0) -> void:
	{
		"master": master_changed,
		"music": music_changed,
		"sfx": sfx_changed,
		"athletic_bgm": blank,
		"extra_bgm": athletic_changed,
		"skid_sfx": skid_changed,
		"extra_sfx": extra_sfx_changed,
		"pause_bgm": pause_bgm_changed,
		"menu_bgm": menu_bgm_changed
	}[value_name].call(value)
