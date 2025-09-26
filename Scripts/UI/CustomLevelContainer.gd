class_name CustomLevelContainer
extends Control

signal selected(this: CustomLevelContainer)

var level_name := ""
var level_author := ""
var level_desc := ""
var level_theme := "Overworld"
var level_time := 0
var game_style := "SMBLL"
var difficulty := 0
var file_path := ""
var is_downloaded := false
var thumbnail: Texture = null
var level_id := ""
var idx := 0

const CAMPAIGN_RECTS := {
	"SMB1": Rect2(0, 0, 42, 16),
	"SMBLL": Rect2(0, 16, 42, 16),
	"SMBS": Rect2(0, 32, 42, 16),
	"SMBANN": Rect2(0, 0, 42, 16)
}

const ICON_TEXTURES := [
	preload("uid://chtjq1vr0rpso"),
	preload("uid://cn8bcncfmdikq")
]

const THEME_RECTS := {
	"Overworld": Rect2(0, 0, 32, 32),
	"Underground": Rect2(32, 0, 32, 32),
	"Desert": Rect2(64, 0, 32, 32),
	"Snow": Rect2(96, 0, 32, 32),
	"Jungle": Rect2(128, 0, 32, 32),
	"Beach": Rect2(0, 32, 32, 32),
	"Garden": Rect2(32, 32, 32, 32),
	"Mountain": Rect2(64, 32, 32, 32),
	"Skyland": Rect2(96, 32, 32, 32),
	"Autumn": Rect2(128, 32, 32, 32),
	"Pipeland": Rect2(0, 64, 32, 32),
	"Space": Rect2(32, 64, 32, 32),
	"Underwater": Rect2(64, 64, 32, 32),
	"Volcano": Rect2(96, 64, 32, 32),
	"GhostHouse": Rect2(128, 64, 32, 32),
	"Castle": Rect2(0, 96, 32, 32),
	"CastleWater": Rect2(32, 96, 32, 32),
	"Mystery": Rect2(96, 96, 32, 32),
	"Airship": Rect2(128, 96, 32, 32),
	"Bonus": Rect2(0, 128, 32, 32)
}

func _ready() -> void:
	set_process(false)
	update_visuals()

func update_visuals() -> void:
	if is_downloaded and FileAccess.file_exists("user://custom_levels/downloaded/thumbnails/" + level_id + ".png"):
		thumbnail = ImageTexture.create_from_image(Image.load_from_file("user://custom_levels/downloaded/thumbnails/" + level_id + ".png"))
		%Thumbnail.texture = thumbnail
		%LevelIcon.hide()
		%Thumbnail.show()
	else:
		%Thumbnail.hide()
		%LevelIcon.show()
		%LevelIcon.texture = ResourceSetter.get_resource(ICON_TEXTURES[level_time])
		%LevelIcon.region_rect = THEME_RECTS[level_theme]
	
	%LevelName.text = level_name if level_name != "" else "(Unnamed Level)"
	%LevelAuthor.text = "By " + (level_author if level_author != "" else "Player")
	
	%CampaignIcon.region_rect = CAMPAIGN_RECTS[game_style]
	
	var idx := 0
	for i in %DifficultyStars.get_children():
		i.region_rect.position.x = 32 if idx > difficulty else [0, 8, 8, 16, 24][difficulty]
		idx += 1

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and visible:
		selected.emit(self)
