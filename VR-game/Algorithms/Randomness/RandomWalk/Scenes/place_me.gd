extends Node3D

@onready var camera = $SubViewport/ViewPortCamera3D

func _ready():
	# Wait briefly to ensure all nodes are properly initialized
	await get_tree().create_timer(0.1).timeout
	
	# Place the camera at the same position as placeMe but 1 meter higher
	if camera:
		camera.global_position = global_position + Vector3(0, 0.2, -0.25)
		print("Camera positioned at: ", camera.global_position)
	else:
		push_error("ViewPortCamera3D not found!")
