class_name _ModLoaderCLI
extends RefCounted


# This Class provides util functions for working with cli arguments.
# Currently all of the included functions are internal and should only be used by the mod loader itself.

const LOG_NAME := "ModLoader:CLI"


# Check if the provided command line argument was present when launching the game
static func is_running_with_command_line_arg(argument: String) -> bool:
	for arg in OS.get_cmdline_args():
		if argument == arg.split("=")[0]:
			return true

	return false


# Get the command line argument value if present when launching the game
static func get_cmd_line_arg_value(argument: String) -> String:
	var args := _get_fixed_cmdline_args()

	for arg_index in args.size():
		var arg := args[arg_index] as String

		var key := arg.split("=")[0]
		if key == argument:
			# format: `--arg=value` or `--arg="value"`
			if "=" in arg:
				var value := arg.trim_prefix(argument + "=")
				value = value.trim_prefix('"').trim_suffix('"')
				value = value.trim_prefix("'").trim_suffix("'")
				return value

			# format: `--arg value` or `--arg "value"`
			elif arg_index +1 < args.size() and not args[arg_index +1].begins_with("--"):
				return args[arg_index + 1]

	return ""


static func _get_fixed_cmdline_args() -> PackedStringArray:
	return fix_godot_cmdline_args_string_space_splitting(OS.get_cmdline_args())


# Reverses a bug in Godot, which splits input strings at spaces even if they are quoted
# e.g. `--arg="some value" --arg-two 'more value'` becomes `[ --arg="some, value", --arg-two, 'more, value' ]`
static func fix_godot_cmdline_args_string_space_splitting(args: PackedStringArray) -> PackedStringArray:
	if not OS.has_feature("editor"): # only happens in editor builds
		return args
	if OS.has_feature("windows"): # windows is unaffected
		return args

	var fixed_args := PackedStringArray([])
	var fixed_arg := ""
	# if we encounter an argument that contains `=` followed by a quote,
	# or an argument that starts with a quote, take all following args and
	# concatenate them into one, until we find the closing quote
	for arg in args:
		var arg_string := arg as String
		if '="' in arg_string or '="' in fixed_arg or \
				arg_string.begins_with('"') or fixed_arg.begins_with('"'):
			if not fixed_arg == "":
				fixed_arg += " "
			fixed_arg += arg_string
			if arg_string.ends_with('"'):
				fixed_args.append(fixed_arg.trim_prefix(" "))
				fixed_arg = ""
				continue
		# same thing for single quotes
		elif "='" in arg_string or "='" in fixed_arg \
				or arg_string.begins_with("'") or fixed_arg.begins_with("'"):
			if not fixed_arg == "":
				fixed_arg += " "
			fixed_arg += arg_string
			if arg_string.ends_with("'"):
				fixed_args.append(fixed_arg.trim_prefix(" "))
				fixed_arg = ""
				continue

		else:
			fixed_args.append(arg_string)

	return fixed_args
