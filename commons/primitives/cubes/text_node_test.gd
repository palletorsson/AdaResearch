extends Node3D

# Test script to verify basic functionality
var test_var: int = 42

func _ready():
	print("Test script loaded successfully!")
	print("Test variable value: ", test_var)
	print("Global position: ", global_position)
	print("Can call add_child: ", has_method("add_child"))
	print("Can call get_tree: ", has_method("get_tree"))
	print("Can call create_tween: ", has_method("create_tween"))

func test_functions():
	print("Testing basic Node3D functions...")
	print("Position: ", global_position)
	print("Tree: ", get_tree())
	print("Tween: ", create_tween())
