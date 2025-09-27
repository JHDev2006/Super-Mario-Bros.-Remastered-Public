extends Node

var files := []
var directories := []

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
		print("Copying '" + i + "' to: '" + destination)
		if i.contains(".bgm") or i.contains(".json") or i.contains(Global.config_path):
			DirAccess.copy_absolute(i, destination)
		else:
			var resource = load(i)
			if resource is Texture:
				resource.get_image().save_png(destination)
			elif resource is AudioStreamWAV:
				resource.save_to_wav(destination)
			elif resource is AudioStream:
				var file = FileAccess.open(destination, FileAccess.WRITE)
				file.store_buffer(resource.data)
				file.close()
			
	var pack_info_path = Global.config_path.path_join("resource_packs/new_pack/pack_info.json")
	DirAccess.make_dir_recursive_absolute(pack_info_path.get_base_dir())
	var file = FileAccess.open(pack_info_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(base_info_json, "\t"))
	file.close()
	print("Done")

func get_directories(base_dir := "", files := [], directories := []) -> void:
	for i in DirAccess.get_directories_at(base_dir):
		if base_dir.contains("LevelGuides") == false:
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
