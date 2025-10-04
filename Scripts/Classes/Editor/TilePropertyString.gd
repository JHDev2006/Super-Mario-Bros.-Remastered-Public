extends TilePropertyContainer

signal editing_start
signal editing_finished

func open_menu() -> void:
	editing_start.emit()
	$CanvasLayer.show()

func on_pressed() -> void:
	set_value(Global.sanitize_string($CanvasLayer/Panel/VBoxContainer/TextEdit.text))
	editing_finished.emit()
	$CanvasLayer.hide()
