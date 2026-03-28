class_name SwapContainer
extends BoxContainer

@export var test_node: Control = null
@export var dummy_node: Control = null

func _ready() -> void:
	resized.connect(check)

func check() -> void:
	if size.x > test_node.size.x:
		test_node.show()
		dummy_node.hide()
	else:
		test_node.hide()
		dummy_node.show()
