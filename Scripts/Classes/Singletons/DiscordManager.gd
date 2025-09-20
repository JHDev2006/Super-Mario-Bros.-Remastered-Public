extends Node

var enabled: bool = ProjectSettings.get_setting("application/use_discord", false) and not (OS.has_feature("linux") and OS.has_feature("arm64"))
var rpc = null

class DiscordRPCStub:
	var app_id
	var start_timestamp
	var details
	var state
	var large_image
	var small_image

	func start(): pass
	func refresh(): pass
	func get_is_discord_working() -> bool: return false
	func shutdown(): pass

func _ready() -> void:
	if enabled:
		rpc = Engine.get_singleton("DiscordRPC")
	else:
		rpc = DiscordRPCStub.new()
	setup_discord_rpc()
	
func _process(_delta: float) -> void:
	if enabled:
		rpc.run_callbacks()

func setup_discord_rpc() -> void:
	if not enabled:
		return
	rpc.app_id = 1331261692381757562
	rpc.start_timestamp = int(Time.get_unix_time_from_system())
	rpc.details = "In Title Screen.."
	if rpc.get_is_discord_working():
		rpc.refresh()

func set_discord_status(details: String = "") -> void:
	if not enabled:
		return
	rpc.details = details
	if rpc.get_is_discord_working():
		rpc.refresh()

func update_discord_status(details: String) -> void:
	if not enabled:
		return
	rpc.details = details
	rpc.state = details
	rpc.large_image = (Global.level_theme + Global.theme_time).to_lower()
	rpc.small_image = Global.current_campaign.to_lower()
	if rpc.get_is_discord_working():
		rpc.refresh()

func refresh_discord_rpc() -> void:
	if not enabled:
		return
	if not rpc.get_is_discord_working():
		return
	Global.update_game_status()
	update_discord_status("")
	rpc.refresh()
