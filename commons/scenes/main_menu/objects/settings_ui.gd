extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var viewport = get_node_or_null("Viewport2Din3D")
	if not viewport:
		print("SettingsUI: Viewport2Din3D not found!")
		return
		
	var scene = viewport.get_scene_instance()
	# Scene logic is handled internally by settings_ui_content.gd
