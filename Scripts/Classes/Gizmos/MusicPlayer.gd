extends Node2D

@export var song_to_play := 0

static var old_song = null
static var currently_playing := 0
var queue_position := -1
static var song_queue := []
var playing := false

func play_song() -> void:
	$Sprite2D/AnimationPlayer.play("Playing")
	if song_queue.is_empty():
		old_song = Global.current_level.music
	song_queue.append(song_to_play)
	update_queue()


func stop_song() -> void:
	$Sprite2D/AnimationPlayer.play("RESET")
	song_queue.erase(song_to_play)
	queue_position = -1
	update_queue()

func update_queue() -> void:
	if Global.level_editor_is_editing():
		return
	if song_queue.size() > 0:
		Global.current_level.music = load(LevelEditor.music_track_list[song_queue.back()])
	else:
		Global.current_level.music = old_song

func toggle() -> void:
	if playing:
		stop_song()
	else:
		play_song()


func on_level_start() -> void:
	song_queue.clear()

func _exit_tree() -> void:
	song_queue.clear()
