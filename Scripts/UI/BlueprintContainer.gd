extends HBoxContainer

var path := ""

signal blueprint_selected(path)
signal blueprint_deleted

func _ready() -> void:
	%BlueprintName.text = path.get_file().to_upper()

func delete_blueprint() -> void:
	DirAccess.remove_absolute(path)
	blueprint_deleted.emit()
	queue_free()

func select() -> void:
	blueprint_selected.emit(path)
