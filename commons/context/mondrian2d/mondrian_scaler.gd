extends Node3D  # Corrected to Node3D since you're working with a 3D scene

@export var sprite3d_y_position = 0.0  # New export variable for Y position
# @export var sprite3d_scale = 1.0  # New export variable for Y position
func _ready():
	# Get reference to the SubViewport
	var viewport = $SubViewport
	#viewport.size = Vector2i(viewport_size_x, viewport_size_y)  # Set viewport size
	
	# Set the Y position of the Sprite3D
	var sprite3d = $StaticBody3D/CollisionShape3D/Sprite3D
	if sprite3d:
		var current_position = sprite3d.transform.origin
		sprite3d.transform.origin = Vector3(current_position.x, sprite3d_y_position, current_position.z)
	
	# Optional: You can also set up a scale for the Sprite3D if needed
	# sprite3d.scale = Vector3(sprite3d_scale, sprite3d_scale, sprite3d_scale)


func _on_grab_cube_grabbed(pickable: Variant, by: Variant) -> void:
	pass # Replace with function body.


func _on_grab_cube_dropped(pickable: Variant) -> void:
	pass # Replace with function body.
