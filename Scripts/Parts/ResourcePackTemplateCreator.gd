extends Node

var files := []
var directories := []

signal fnt_file_downloaded(text: String)

var downloaded_fnt_text := []

signal pack_created

const base_info_json := {
	"name": "New Pack",
	"description": "Template, give me a description!",
	"author": "Me, until you change it",
	"version": "1.0",
	"format": 0
}

const disallowed_files := ["bgm","ctex","json","fnt", "svg"]

func create_template() -> void:
	await get_tree().process_frame
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
		if i.contains(".fnt") or i.contains("ScoreFont"):
			data = await download_fnt_text(i) 
			## Imagine being one of the best open source game engines, yet not able to get the FUCKING CONTENTS
			## OF AN FNT FILE SO INSTEAD YOU HAVE TO WRITE THE MOST BULLSHIT CODE TO DOWNLOAD THE FUCKING FILE
			## FROM THE FUCKING GITHUB REPO. WHY? BECAUSE GODOT IS SHIT. FUCK GODOT.
		elif i.contains(".svg"):
			## DON'T import SVGs
			continue
		elif disallowed_files.has(i.get_extension()) == false and i.contains("res://"):
			var resource = load(i)
			if resource is Texture:
				if OS.is_debug_build(): print("texture:" + i)
				var image: Image = resource.get_image()
				image.convert(Image.FORMAT_RGBA8)
				data = image.save_png_to_buffer()
			elif resource is AudioStream:
				match i.get_extension():
					"mp3":
						if OS.is_debug_build(): print("mp3:" + i)
						data = resource.get_data()
					"wav":
						## guzlad: CAN NOT BE format FORMAT_IMA_ADPCM or FORMAT_QOA as they don't support the save function
						## guzlad: Should be FORMAT_16_BITS like most of our other .wav files 
						if OS.is_debug_build(): print("wav:" + i)
						var wav_file: AudioStreamWAV = load(i)
						if !OS.is_debug_build():
							wav_file.save_to_wav(destination)
						else:
							print(error_string(wav_file.save_to_wav(destination)))
					## guzlad: No OGG yet
					_:
						data = resource.get_data()
		else:
			if OS.is_debug_build(): print("else:" + i)
			var old_file = FileAccess.open(i, FileAccess.READ)
			data = old_file.get_buffer(old_file.get_length())
			if OS.is_debug_build(): print("else error: " + error_string(old_file.get_error()))
			old_file.close()

		if !data.is_empty():
			if OS.is_debug_build(): print("saving:" + i)
			var new_file = FileAccess.open(destination, FileAccess.WRITE)
			new_file.store_buffer(data)
			if OS.is_debug_build(): print("saving error: " + error_string(new_file.get_error()))
			new_file.close()
	
	var pack_info_path = Global.config_path.path_join("resource_packs/new_pack/pack_info.json")
	DirAccess.make_dir_recursive_absolute(pack_info_path.get_base_dir())
	var file = FileAccess.open(pack_info_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(base_info_json, "\t", false))
	file.close()
	print("Done")
	pack_created.emit()

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
			#print(i)
			var target_path = base_dir + "/" + i
			var rom_assets_path = target_path.replace("res://Assets", Global.config_path.path_join("resource_packs/BaseAssets"))
			if FileAccess.file_exists(rom_assets_path):
				files.append(rom_assets_path)
			else:
				files.append(target_path)
