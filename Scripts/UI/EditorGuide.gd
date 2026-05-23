extends Control


func on_item_selected(index: int) -> void:
	for i in %Guides.get_children():
		i.hide()
	
	var node_to_show := %Guides.get_child(index)
	if node_to_show != null: node_to_show.show()
