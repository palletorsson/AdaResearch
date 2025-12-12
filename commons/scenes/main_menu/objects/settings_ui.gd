extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var scene = $Viewport2Din3D.get_scene_instance()
	# Scene logic is handled internally by settings_ui_content.gd
