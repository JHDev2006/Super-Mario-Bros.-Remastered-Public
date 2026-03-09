extends Button


var pack_folder_name := ""

var json := {}

const current_type := 3

func _ready() -> void:
	update_visuals()

func update_visuals() -> void:
	%LevelName.text = json.name
	%LevelAuthor.text = json.author
	var icon_path = Global.config_path + "level_packs/" + pack_folder_name + "/icon.png"
	if FileAccess.file_exists(icon_path):
		%Thumbnail.texture = import_image(icon_path)

func import_image(path := "") -> Texture:
	var texture = ImageTexture.create_from_image(Image.load_from_file(path))
	return texture
