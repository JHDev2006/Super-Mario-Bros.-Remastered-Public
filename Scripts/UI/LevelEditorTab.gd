extends MarginContainer

static var current_tab = null

@export var icon: Texture = null
@export var title := ""
@export var linked_control: Control = null
@export var first_pick := false

func _ready() -> void:
	if first_pick:
		tab_clicked()
	$HBoxContainer/Label.text = title
	$HBoxContainer/TextureRect.texture = icon
	update()

func update() -> void:
	$HBoxContainer/Label.visible = current_tab == self
	$Selected.visible = current_tab == self
	linked_control.visible = current_tab == self

func tab_clicked() -> void:
	current_tab = self
	get_tree().call_group("EditorTabs", "update")
