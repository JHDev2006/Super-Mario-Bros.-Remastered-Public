extends Node

var files := []
var directories := []

signal fnt_file_downloaded(text: String)

var downloaded_fnt_text := []

const base_info_json := {
	"name": "New Pack",
	"description": "Template, give me a description!",
	"author": "Me, until you change it"
	}

func create_template() -> void:
	get_directories("res://Assets", files, directories)
	for i in directories:
		DirAccess.make_dir_recursive_absolute(i.replace("res://Assets", Global.config_path.path_join("resource_packs/new_pack")))
	for i in files:
		var destination = i
		if destination.contains("res://"):
			destination = i.replace("res://Assets", Global.config_path.path_join("resource_packs/new_pack"))
		else:
			destination = i.replace(Global.config_path.path_join("resource_packs/BaseAssets"), Global.config_path.path_join("resource_packs/new_pack"))
		var data = []
		if i.contains(".fnt"):
			data = await download_fnt_text(i) 
			## Imagine being one of the best open source game engines, yet not able to get the FUCKING CONTENTS
			## OF AN FNT FILE SO INSTEAD YOU HAVE TO WRITE THE MOST BULLSHIT CODE TO DOWNLOAD THE FUCKING FILE
			## FROM THE FUCKING GITHUB REPO. WHY? BECAUSE GODOT IS SHIT. FUCK GODOT.
		elif i.contains(".bgm") == false and i.contains(".ctex") == false and i.contains(".json") == false and i.contains("res://") and i.contains(".fnt") == false:
			var resource = load(i)
			if resource is Texture:
				data = resource.get_image().save_png_to_buffer()
			elif resource is AudioStream:
				data = resource.get_data()
		else:
			var old_file = FileAccess.open(i, FileAccess.READ)
			data = old_file.get_buffer(old_file.get_length())
			old_file.close()

		var new_file = FileAccess.open(destination, FileAccess.WRITE)
		new_file.store_buffer(data)
		new_file.close()
	
	var pack_info_path = Global.config_path.path_join("resource_packs/new_pack/pack_info.json")
	DirAccess.make_dir_recursive_absolute(pack_info_path.get_base_dir())
	var file = FileAccess.open(pack_info_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(base_info_json, "\t"))
	file.close()
	print("Done")

func download_fnt_text(file_path := "") -> PackedByteArray:
	var http = HTTPRequest.new()
	const GITHUB_URL = "https://raw.githubusercontent.com/JHDev2006/Super-Mario-Bros.-Remastered-Public/refs/heads/main/"
	var url = GITHUB_URL + file_path.replace("res://", "")
	add_child(http)
	http.request_completed.connect(file_downloaded)
	http.request(url, [], HTTPClient.METHOD_GET)
	await fnt_file_downloaded
	http.queue_free()
	return downloaded_fnt_text

func file_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	downloaded_fnt_text = body
	fnt_file_downloaded.emit(downloaded_fnt_text)

func get_directories(base_dir := "", files := [], directories := []) -> void:
	for i in DirAccess.get_directories_at(base_dir):
		if base_dir.contains("LevelGuides") == false and base_dir.contains(".godot") == false:
			directories.append(base_dir + "/" + i)
			get_directories(base_dir + "/" + i, files, directories)
			get_files(base_dir + "/" + i, files)

func get_files(base_dir := "", files := []) -> void:
	for i in DirAccess.get_files_at(base_dir):
		if base_dir.contains("LevelGuides") == false:
			i = i.replace(".import", "")
			print(i)
			var target_path = base_dir + "/" + i
			var rom_assets_path = target_path.replace("res://Assets", Global.config_path.path_join("resource_packs/BaseAssets"))
			if FileAccess.file_exists(rom_assets_path):
				files.append(rom_assets_path)
			else:
				files.append(target_path)
