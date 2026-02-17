@tool
extends TextEdit

signal discard_last_console_error

var base_theme: Theme: set = set_base_theme
var editor_settings: EditorSettings: set = set_editor_settings

var last_text := ""
var last_selection: TextSelection

var highlight_settings: PackedStringArray = [
	"string_color", "background_color", "line_number_color",
	"text_selected_color", "selection_color", "brace_mismatch_color",
	"current_line_color", "word_highlighted_color", "number_color",
	"code_folding_color", "symbol_color"
]

var autobrace_pairs := {
	"(": ")",
	"{": "}",
	"[": "]",
	'"': '"',
	":": ",",
}


func _ready() -> void:
	last_text = text
	$"%ShouldValidate".connect("pressed", Callable(self, "validate"))
	validate()


func set_base_theme(p_base_theme: Theme) -> void:
	base_theme = p_base_theme
	add_theme_font_override("font", base_theme.get_font("source", "EditorFonts"))


func set_editor_settings(p_editor_settings: EditorSettings) -> void:
	editor_settings = p_editor_settings

#	TODO -> syntax_highlighter = get_setting_bool("text_editor/highlighting/syntax_highlighter")
	highlight_all_occurrences = get_setting_bool("text_editor/highlighting/highlight_all_occurrences")
	highlight_current_line = get_setting_bool("text_editor/highlighting/highlight_current_line")

	draw_tabs = get_setting_bool("text_editor/indent/draw_tabs")
	draw_spaces = get_setting_bool("text_editor/indent/draw_spaces")

	$ValidationDelay.wait_time = editor_settings.get_setting("text_editor/completion/idle_parse_delay")

#	TODO -> add_color_region('"', '"', get_highlight_color("string_color"))
	for highlight in highlight_settings:
		add_theme_color_override(highlight, get_highlight_color(highlight))


func get_highlight_color(name: String) -> Color:
	var color = editor_settings.get_setting("text_editor/highlighting/" + name)
	return color if color is Color else null


func get_setting_bool(setting: String) -> bool:
	var is_set = editor_settings.get_setting(setting)
	return is_set if is_set is bool else false


func validate() -> void:
	if not $"%ShouldValidate".pressed:
		$"%ErrorLabel".text = "Validation off"
		return

	var test_json_conv = JSON.new()
	test_json_conv.parse(text)
	var parsed := test_json_conv.get_data()
	if not parsed.error == OK:
		$"%ErrorLabel".text = "Line %s: %s" % [parsed.error_line +1, parsed.error_string]
		emit_signal("discard_last_console_error")

		return
	$"%ErrorLabel".text = "JSON is valid"


func _on_cursor_changed() -> void:
	if get_selected_text().length() > 0:
		last_selection = TextSelection.from_text_edit(self)
	else:
		last_selection = null


func _on_text_changed() -> void:
	$ValidationDelay.stop()
	$ValidationDelay.start()

	if get_setting_bool("text_editor/completion/auto_brace_complete"):
		autobrace()

	last_text = text


func autobrace() -> void:
	var line := get_line(get_caret_line())

	var char_before_cursor := ""
	if get_caret_column() > 0:
		char_before_cursor = line[get_caret_column()-1]

	var char_after_cursor := ""
	if get_caret_column() < line.length():
		char_after_cursor = line[get_caret_column()]

	# When deleting, also delete the autobraced character
	if Input.is_key_pressed(KEY_BACKSPACE):
		if char_after_cursor in autobrace_pairs.values():
			var deleted_character := first_different_character(text, last_text)
			if autobrace_pairs.has(deleted_character) and autobrace_pairs[deleted_character] == char_after_cursor:
				delete_character_after_cursor()

	# If we encounter a closing brace, "skip" over it
	# Since the character is written already, just delete the next one
	elif is_matching_closing_brace(char_before_cursor, char_after_cursor):
		delete_character_after_cursor()

	# If a character is in the autoclose dict, close it
	elif char_before_cursor in autobrace_pairs.keys():
		var closing_char: String = autobrace_pairs[char_before_cursor]
		var last_cursor_column := get_caret_column()

		if not last_selection:
			insert_text_at_caret(closing_char)
			set_caret_column(last_cursor_column)
			return

		# If there is a selection, surround that with the bracing characters
		# Pressing the alt key moves the selection left by one character
		if Input.is_key_pressed(KEY_ALT):
			if last_cursor_column == last_selection.from_col +1:
				# If selected right to left, it can be fixed by offsetting it right
				select(
					last_selection.from_line, last_selection.from_col +1,
					last_selection.to_line, last_selection.to_col +1
				)
				insert_text_at_caret(last_selection.enclosed_text + closing_char)
				set_caret_column(last_selection.to_col +1)
			else:
				# If selected left to right, something else goes wrong as well,
				# but it can be fixed by inserting the whole selection with braces
				# and removing the leftover trailing brace behind it afterwards
				insert_text_at_caret(char_before_cursor + last_selection.enclosed_text + closing_char)
				delete_character_after_cursor()
				set_caret_column(last_selection.to_col +1)
		else:
			insert_text_at_caret(last_selection.enclosed_text + closing_char)
			set_caret_column(last_selection.to_col +1)
		last_selection = null


func is_matching_closing_brace(new_character: String, char_after_cursor: String) -> bool:
	if not new_character == char_after_cursor:
		return false

	# Opening and closing brace are the same -> ""
	if char_after_cursor in autobrace_pairs.keys():
		return true

	# Opening and closing brace are different -> ()
	if new_character in autobrace_pairs.values():
		return true

	return false


func delete_character_after_cursor() -> void:
	var line_text := get_line(get_caret_line())
	var cursor_col := get_caret_column() +1
	var text_length := len(line_text)
	if cursor_col < 1 or cursor_col > text_length:
		return
	var left_text := line_text.substr(0, cursor_col - 1)
	var right_text := line_text.substr(cursor_col, text_length - cursor_col)
	set_line(get_caret_line(), left_text + right_text)
	set_caret_column(cursor_col - 1)


func first_different_character(str1: String, str2: String) -> String:
	var len1 := str1.length()
	var len2 := str2.length()

	if len1 == 0:
		return str2[0]
	if len2 == 0:
		return str1[0]

	for i in min(len1, len2):
		if not str1[i] == str2[i]:
			return str2[i]
	return ""


func _on_ValidationDelay_timeout() -> void:
	validate()


class TextSelection:
	var enclosed_text: String
	var from_line: int
	var from_col: int
	var to_line: int
	var to_col: int

	func _init(p_enclosed_text: String, p_from_line: int, p_from_col: int, p_to_line: int, p_to_col: int) -> void:
		enclosed_text = p_enclosed_text
		from_line = p_from_line
		from_col = p_from_col
		to_line = p_to_line
		to_col = p_to_col


	static func from_text_edit(text_edit: TextEdit) -> TextSelection:
		return TextSelection.new(
			text_edit.get_selection_text(),
			text_edit.get_selection_from_line(), text_edit.get_selection_from_column(),
			text_edit.get_selection_to_line(), text_edit.get_selection_to_column()
		)


	func _to_string() -> String:
		return "%s %s %s" % [ Vector2(from_line, from_col), enclosed_text, Vector2(to_line, to_col) ]
