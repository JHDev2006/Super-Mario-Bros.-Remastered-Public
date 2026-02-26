@tool
extends Window


signal dir_selected(dir_path)

@onready var directory_list: VBoxContainer = $"%DirectoryList"


func generate_dir_buttons(dir_path: String) -> void:
	clear_directory_list()
	var dir_paths := _ModLoaderPath.get_dir_paths_in_dir(dir_path)

	for path in dir_paths:
		var dir_name: String = path.split('/')[-1]

		var dir_btn := Button.new()
		dir_btn.text = dir_name

		directory_list.add_child(dir_btn)
		dir_btn.pressed.connect(_on_dir_btn_dir_selected.bind(path))


func clear_directory_list() -> void:
	for child in directory_list.get_children():
		directory_list.remove_child(child)
		child.queue_free()


func _on_dir_btn_dir_selected(path: String) -> void:
	dir_selected.emit(path)


func _on_close_requested() -> void:
	hide()
