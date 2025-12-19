extends Node3D

signal player_height_changed(new_height)

func _on_player_height_changed(new_height):
	emit_signal("player_height_changed", new_height)

# Called when the node enters the scene tree for the first time.
func _ready():
	var viewport = get_node_or_null("Screen/Viewport2Din3D")
	if not viewport:
		print("SettingsUI (2D): Screen/Viewport2Din3D not found!")
		return
		
	var scene = viewport.get_scene_instance()
	if scene:
		scene.connect("player_height_changed", _on_player_height_changed)
