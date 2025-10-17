extends Node

const DEFAULT_SFX_LIBRARY := {
	"small_jump": ("res://Assets/Audio/SFX/SmallJump.wav"),
	"big_jump": ("res://Assets/Audio/SFX/BigJump.wav"),
	"coin": ("res://Assets/Audio/SFX/Coin.wav"),
	"bump": ("res://Assets/Audio/SFX/Bump.wav"),
	"skid": ("res://Assets/Audio/SFX/Skid.wav"),
	"pipe": ("res://Assets/Audio/SFX/Pipe.wav"),
	"damage": ("res://Assets/Audio/SFX/Damage.wav"),
	"power_up": ("res://Assets/Audio/SFX/Powerup.wav"),
	"item_appear": ("res://Assets/Audio/SFX/ItemAppear.wav"),
	"block_break": ("res://Assets/Audio/SFX/BreakBlock.wav"),
	"enemy_stomp": ("res://Assets/Audio/SFX/Stomp.wav"),
	"kick": ("res://Assets/Audio/SFX/Kick.wav"),
	"fireball": ("res://Assets/Audio/SFX/Fireball.wav"),
	"1_up": ("res://Assets/Audio/SFX/1up.wav"),
	"cannon": ("res://Assets/Audio/SFX/Cannon.wav"),
	"checkpoint": ("res://Assets/Audio/SFX/Checkpoint.wav"),
	"magic": ("res://Assets/Audio/SFX/Magic.wav"),
	"beep": ("res://Assets/Audio/SFX/Score.wav"),
	"switch": ("res://Assets/Audio/SFX/Switch.wav"),
	"boo_laugh": ("res://Assets/Audio/SFX/BooLaugh.wav"),
	"icicle_fall": ("res://Assets/Audio/SFX/IcicleFall.wav"),
	"icicle_break": ("res://Assets/Audio/SFX/IcicleCrash.wav"),
	"score": "res://Assets/Audio/SFX/ScoreLoop.wav",
	"score_end": "res://Assets/Audio/SFX/Score.wav",
	"pause": ("res://Assets/Audio/SFX/Pause.wav"),
	"spring": ("res://Assets/Audio/SFX/Spring.wav"),
	"swim": ("res://Assets/Audio/SFX/Swim.wav"),
	"dry_bones_crumble": ("res://Assets/Audio/SFX/DryBonesCrumble.wav"),
	"clock_get": ("res://Assets/Audio/SFX/ClockGet.wav"),
	"bowser_flame": ("res://Assets/Audio/SFX/BowserFire.wav"),
	"correct": ("res://Assets/Audio/SFX/Correct.wav"),
	"note_block": ("res://Assets/Audio/SFX/NoteBlock.wav"),
	"podoboo": ("res://Assets/Audio/SFX/Podoboo.wav"),
	"hammer_throw": ("res://Assets/Audio/SFX/HammerThrow.wav"),
	"firework": "res://Assets/Audio/SFX/Firework.wav",
	"timer_beep": "res://Assets/Audio/SFX/TimerBeep.wav",
	"hachisuke": "res://Assets/Audio/SFX/Hachisuke.wav",
	"hammer_hit": "res://Assets/Audio/SFX/HammerHit.wav",
	"burner": "res://Assets/Audio/SFX/Burner.wav",
	"rank_up_1": "res://Assets/Audio/SFX/RankUpCBA.wav",
	"rank_up_2": "res://Assets/Audio/SFX/RankUpSP.wav",
	"rank_down": "res://Assets/Audio/SFX/RankDown.wav",
	"combo_lost": "res://Assets/Audio/SFX/ComboMeterLoss.wav",
	"lakitu_throw": "res://Assets/Audio/SFX/LakituThrow.wav",
	"lift_fall": "res://Assets/Audio/SFX/LiftFall.wav",
	"cheep_cheep": "res://Assets/Audio/SFX/CheepCheepJump.wav",
	"menu_move": "res://Assets/Audio/SFX/MenuNavigate.wav",
	"timer_warning": "res://Assets/Audio/SFX/TimerRunningLow.wav",
	"door_open": "res://Assets/Audio/SFX/DoorOpen.wav",
	"door_close": "res://Assets/Audio/SFX/DoorClose.wav",
	"key_collect": "res://Assets/Audio/SFX/KeyCollect.wav",
	"lucky_star": "res://Assets/Audio/SFX/LuckyStar.wav",
	"bumper": "res://Assets/Audio/SFX/Bumper.wav",
	"bumper_high": "res://Assets/Audio/SFX/BumperHigh.wav",
	"door_unlock": "res://Assets/Audio/SFX/DoorUnlock.wav",
	"door_locked": "res://Assets/Audio/SFX/DoorLocked.wav"
}

@onready var sfx_library = DEFAULT_SFX_LIBRARY.duplicate()

@onready var music_player: AudioStreamPlayer = $Music
@onready var music_override_player: AudioStreamPlayer = $MusicOverride

var music_override_priority := -1

var active_sfxs := {}

var current_level_theme := ""
var current_clip_idx := 0

signal music_beat

var queued_sfxs := []

var current_music_override: MUSIC_OVERRIDES

enum MUSIC_OVERRIDES{NONE=-1, STAR=0, DEATH, PSWITCH, BOWSER, TIME_WARNING, LEVEL_COMPLETE, CASTLE_COMPLETE, ENDING, FLAG_POLE, HAMMER, RACE_LOSE, RACE_WIN, WING, COIN_HEAVEN_BONUS}

const OVERRIDE_STREAMS := [
	("res://Assets/Audio/BGM/StarMan.json"),
	("res://Assets/Audio/BGM/PlayerDie.json"),
	("res://Assets/Audio/BGM/PSwitch.json"),
	"res://Assets/Audio/BGM/Bowser.json",
	"res://Assets/Audio/BGM/Hurry.json",
	"res://Assets/Audio/BGM/LevelFinish.json",
	"res://Assets/Audio/BGM/CastleFinish.json",
	"res://Assets/Audio/BGM/Ending.json",
	"res://Assets/Audio/SFX/FlagSlide.wav",
	("res://Assets/Audio/BGM/Hammer.json"),
	("res://Assets/Audio/BGM/LoseRace.json"),
	("res://Assets/Audio/BGM/WinRace.json"),
	"res://Assets/Audio/BGM/Wing.json",
	"res://Assets/Audio/BGM/PerfectCoinHeaven.mp3"
]

const MUSIC_BASE = preload("uid://da4vqkrpqnma0")

var character_sfx_map := {}

var audio_override_queue := []

func play_sfx(stream_name = "", position := Vector2.ZERO, pitch := 1.0) -> void:

	if queued_sfxs.has(stream_name):
		return
	queued_sfxs.append(stream_name)
	if stream_name is String:
		if active_sfxs.has(stream_name):
			active_sfxs[stream_name].queue_free()
	var player = AudioStreamPlayer2D.new()
	player.global_position = position
	var stream = stream_name
	var is_custom = false
	if stream_name is String:
		is_custom = sfx_library[stream_name].contains(Global.config_path.path_join("custom_characters"))
		stream = import_stream(sfx_library[stream_name])
	if is_custom == false:
		player.stream = ResourceSetter.get_resource(stream, player)
	else:
		player.stream = stream
	player.autoplay = true
	player.pitch_scale = pitch
	player.max_distance = 99999
	player.bus = "SFX"
	add_child(player)
	active_sfxs[stream_name] = player
	queued_sfxs.erase(stream_name)
	await player.finished
	active_sfxs.erase(stream_name)
	player.queue_free()

func play_global_sfx(stream_name := "") -> void:
	if get_viewport().get_camera_2d() == null:
		return
	play_sfx(stream_name, get_viewport().get_camera_2d().get_screen_center_position())

func _process(_delta: float) -> void:
	handle_music()

func on_beat(idx := 0) -> void:
	music_beat.emit(idx)

func stop_all_music() -> void:
	AudioManager.music_player.stop()
	if Global.current_level != null:
		Global.current_level.music = null
	AudioManager.audio_override_queue.clear()
	AudioManager.stop_music_override(MUSIC_OVERRIDES.NONE, true)

func kill_sfx(sfx_name := "") -> void:
	print(active_sfxs)
	if active_sfxs.has(sfx_name):
		active_sfxs[sfx_name].queue_free()
		active_sfxs.erase(sfx_name)

func set_music_override(stream: MUSIC_OVERRIDES, priority := 0, stop_on_finish := true, restart := true) -> void:
	if audio_override_queue.has(stream):
		if current_music_override == stream and restart:
			music_override_player.play()
		return
	if music_override_priority > priority:
		audio_override_queue.push_front(stream)
		return
	else:
		audio_override_queue.append(stream)
	current_music_override = stream
	print(OVERRIDE_STREAMS[stream])
	music_override_player.stream = create_stream_from_json(OVERRIDE_STREAMS[stream])
	music_override_player.bus = "Music" if stream != MUSIC_OVERRIDES.FLAG_POLE else "SFX"
	music_override_player.play()
	music_override_priority = priority
	if stop_on_finish:
		await music_override_player.finished
		stop_music_override(stream)


func stop_music_override(stream: MUSIC_OVERRIDES, force := false) -> void:
	if not force:
		if stream == null:
			return
		elif stream != current_music_override:
			audio_override_queue.erase(stream)
			return
	audio_override_queue.pop_back()
	current_music_override = MUSIC_OVERRIDES.NONE
	music_override_player.stop()
	music_override_priority = -1
	if audio_override_queue.is_empty():
		audio_override_queue.clear()
		music_override_priority = -1
		current_music_override = MUSIC_OVERRIDES.NONE
		music_override_player.stop()
	else:
		set_music_override(audio_override_queue[audio_override_queue.size() - 1])

func load_sfx_map(json := {}) -> void:
	sfx_library = DEFAULT_SFX_LIBRARY.duplicate()
	for i in json:
		sfx_library[i] = json[i]
	print(json)

func handle_music() -> void:
	if Global.in_title_screen:
		current_level_theme = ""
	
	# guzlad: hack in the elif because it doesn't unpause itself like the normal music_player does
	if Global.game_paused and Settings.file.audio.pause_bgm == 0:
		AudioManager.music_player.stream_paused = true
		AudioManager.music_override_player.stream_paused = true
		return
	elif AudioManager.music_override_player.stream_paused == true:
		AudioManager.music_override_player.stream_paused = false
	
	AudioServer.set_bus_effect_enabled(1, 0, Global.game_paused and Settings.file.audio.pause_bgm == 1)
	
	if is_instance_valid(Global.current_level):
		if Global.current_level.music == null or current_music_override != MUSIC_OVERRIDES.NONE:
			music_player.stop()
			handle_music_override()
			return
		music_player.stream_paused = false
		if current_level_theme != Global.current_level.music.resource_path and Global.current_level.music != null:
			var stream = create_stream_from_json(Global.current_level.music.resource_path)
			music_player.stream = stream
			current_level_theme = Global.current_level.music.resource_path
		if music_player.is_playing() == false and current_music_override == MUSIC_OVERRIDES.NONE:
			music_player.stop()
			current_music_override = MUSIC_OVERRIDES.NONE
			music_player.play()
		if music_player.stream is AudioStreamInteractive and music_player.is_playing():
			if Global.time <= 100:
				if music_player.get_stream_playback().get_current_clip_index() != 1:
					music_player.get_stream_playback().switch_to_clip(1)
			elif music_player.get_stream_playback().get_current_clip_index() != 0:
				music_player.get_stream_playback().switch_to_clip(0)

func handle_music_override() -> void:
	if music_override_player.stream is AudioStreamInteractive and music_override_player.is_playing():
		if Global.time <= 100:
			if music_override_player.get_stream_playback().get_current_clip_index() != 1:
				music_override_player.get_stream_playback().switch_to_clip(1)
		elif music_override_player.get_stream_playback().get_current_clip_index() != 0:
			music_override_player.get_stream_playback().switch_to_clip(0)

func create_stream_from_json(json_path := "") -> AudioStream:
	if json_path.contains(".json") == false:
		var path = ResourceSetter.get_pure_resource_path(json_path)
		if path.contains(Global.config_path):
			match json_path.get_slice(".", 1):
				"wav":
					return AudioStreamWAV.load_from_file(ResourceSetter.get_pure_resource_path(json_path))
				"mp3":
					return AudioStreamMP3.load_from_file(ResourceSetter.get_pure_resource_path(json_path))
				"ogg":
					return AudioStreamOggVorbis.load_from_file(ResourceSetter.get_pure_resource_path(json_path))
		elif path.contains("res://"):
			return load(path)
	var bgm_file = $ResourceSetterNew.get_variation_json(JSON.parse_string(FileAccess.open(ResourceSetter.get_pure_resource_path(json_path), FileAccess.READ).get_as_text()).variations).source
	var path = json_path.replace(json_path.get_file(), bgm_file)
	path = ResourceSetter.get_pure_resource_path(path)
	var stream = null
	if path.get_file().contains(".bgm"):
		stream = generate_interactive_stream(JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text()))
	else:
		if path.contains("res://"):
			stream = load(path)
		elif path.contains(".mp3"):
			stream = AudioStreamMP3.load_from_file(path)
		elif path.contains(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(path)
	return stream

func generate_interactive_stream(bgm_file := {}) -> AudioStreamInteractive:
	var stream = MUSIC_BASE.duplicate()
	var normal_path = ResourceSetter.get_pure_resource_path("res://Assets/Audio/BGM/" + bgm_file.Normal.source)
	var hurry_path = ResourceSetter.get_pure_resource_path("res://Assets/Audio/BGM/" + bgm_file.Hurry.source)
	stream.set_clip_stream(0, import_stream(normal_path, bgm_file.Normal.loop))
	stream.set_clip_stream(1, import_stream(hurry_path, bgm_file.Hurry.loop))
	return stream

func import_stream(file_path := "", loop_point := -1.0) -> AudioStream:
	var path = file_path
	var stream = null
	if path.contains("res://"):
		stream = load(path)
	elif path.contains(".mp3"):
		stream = AudioStreamMP3.load_from_file(ResourceSetter.get_pure_resource_path(file_path))
	elif path.contains(".ogg"):
		stream = AudioStreamOggVorbis.load_from_file(ResourceSetter.get_pure_resource_path(file_path))
	elif path.contains(".wav"):
		stream = AudioStreamWAV.load_from_file(path)
		print([path, stream])
	if path.contains(".mp3"):
		stream.set_loop(loop_point >= 0)
		stream.set_loop_offset(loop_point)
	elif path.contains(".ogg"):
		stream.set_loop(loop_point >= 0)
		stream.set_loop_offset(loop_point)
	return stream
	
