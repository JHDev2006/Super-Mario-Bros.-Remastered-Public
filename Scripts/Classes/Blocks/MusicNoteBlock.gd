extends NoteBlock

const INTRUMENT_SFX := [preload("uid://cat6p6cu42wcg"), preload("uid://dxo3oc43qfx8m"), preload("uid://bhuwwkdaknluc"), preload("uid://bcajl2n37uhxn"), preload("uid://kinypo6s61ol"), preload("uid://ck5no1ebkdai4"), preload("uid://g6vcleib15rq"), preload("uid://bkgpuuqklljjm")]

var pitch := 0.0
var sfx_stream = null

static var can_play := false

@export var play_on_load := false

@export_enum("Bass", "Flute", "Marimba", "Piano", "Rhodes", "Steel", "Trumpet", "Violin") var instrument := 0:
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
		print($Instrument.pitch_scale)
		$Instrument.stream = sfx_stream
		$Instrument.pitch_scale = pitch
		$Instrument.play()


func on_screen_entered() -> void:
	if play_on_load and LevelEditor.playing_level:
		play_sfx_preview()
