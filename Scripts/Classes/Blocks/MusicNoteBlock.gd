extends NoteBlock

const INTRUMENT_SFX := [
	preload("uid://gsk2lqo8a608"), 
	preload("uid://ch68d4iy1nn2e"), 
	preload("uid://b5wwm2720dks"), 
	preload("uid://b8x38vefni36o"), 
	preload("uid://d4ec6sm3ilh73"), 
	preload("uid://c62pc2e3w30va"), 
	preload("uid://dcdihfu6fpjg1"), 
	preload("uid://byet8ricnkvsf"),
	preload("uid://dipd14hygq0ue"),
	preload("uid://v5shor4xhmte"),
	preload("uid://bp1ekr6dxqsfh"),
	preload("uid://cos22481qnlhx"),
	preload("uid://h1fyjk51gvka"),
	preload("uid://j06hg01gfshy"),
	preload("uid://d32wvw1qf7uw3"),
	preload("uid://b5wwm2720dks"),
	preload("uid://c0cgm63slvmxt"),
	preload("uid://c32qv5uvxdq2k"),
 	preload("uid://dg8ycbqm3m75"),
	preload("uid://ch1wowaof5slq"),
	preload("uid://lua5xtsqftqa")
	]

var pitch := 0.0
var sfx_stream = null

static var can_play := false

@export var play_on_load := false

@export_enum("Bass", "Flute", "Marimba", "Piano", "Rhodes", "Steel", "Trumpet", "Violin", "Bongo", "Clarinet", "Fantasia", "FretlessBass", "Hihat", "Hit", "Kick", "Marimba", "OrchestraHit", "Oud", "PowerSnare", "SlapBass", "Timpani") var instrument := 0:
	set(value):
		sfx_stream = INTRUMENT_SFX[value]
		instrument = value
		play_sfx_preview()

@export_enum("A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#") var note := 3:
	set(value):
		note = value
		pitch = get_pitch_scale()
		play_sfx_preview()

@export_range(1, 5) var octave := 2:
	set(value):
		octave = value
		pitch = get_pitch_scale()
		play_sfx_preview()

@export_range(0.0, 1.0, 0.1) var volume := 1.0:
	set(value):
		volume = value
		play_sfx_preview()

func _ready() -> void:
	await get_tree().create_timer(0.1, true).timeout
	can_play = true

func _exit_tree() -> void:
	can_play = false

func get_pitch_scale() -> float:
	var semitone_offset = (octave - 2) * 12 + (note - 3)  # C4 is the base note (note index 3)
	return 2.0 ** (semitone_offset / 12.0)

func _process(_delta: float) -> void:
	%Note.frame = note
	%Octave.frame = octave + 12

func play_sfx_preview() -> void:
	if get_node_or_null("Instrument") != null and can_play:
		$Instrument.stream = sfx_stream
		$Instrument.pitch_scale = pitch
		$Instrument.volume_linear = volume
		$Instrument.play()


func on_screen_entered() -> void:
	if play_on_load and not Global.level_editor_is_editing():
		play_sfx_preview()
