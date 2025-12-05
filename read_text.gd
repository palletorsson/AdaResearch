@tool
extends SceneTree

func _init():
	var file = FileAccess.open("res://addons/VR_VR_PT_2023.txt", FileAccess.READ)
	if file:
		print(file.get_as_text())
	else:
		print("Could not open file")
	quit()
