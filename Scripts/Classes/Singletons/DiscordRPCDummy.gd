extends Node
class_name DiscordRPCDummy

var app_id: int
var start_timestamp: int
var details: String

func get_is_discord_working() -> bool:
	return false

func refresh() -> void:
	pass

func run_callbacks() -> void:
	pass
