extends Node3D

# 4x4x4 3D grid of cubes arranged in X, Y, and Z directions
# Each cube is spaced 1 units apart

func _ready() -> void:
	create_grid_3d()

func create_grid_3d() -> void:
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create 4x4x4 grid of cubes
	for x in range(4):
		for y in range(4):
			for z in range(4):
				var cube_instance = pickup_cube_scene.instantiate()
				cube_instance.name = "Cube_" + str(x) + "_" + str(y) + "_" + str(z)
				
				# Position cubes in a 4x4x4 grid, 1 units apart
				cube_instance.position = Vector3(x * 1.0, y * 1.0, z * 1.0)
				
				# Add Index Label - high visibility from all angles
				var label = Label3D.new()
				label.text = "[%d, %d, %d]" % [x, y, z]
				
				label.font_size = 28  # Slightly smaller for 3D density
				label.pixel_size = 0.003
				label.outline_size = 5  # Add outline for visibility
				label.outline_modulate = Color(0, 0, 0, 1)  # Black outline
				
				label.position = Vector3(0, 0.6, 0)
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.no_depth_test = true  # Always visible
				label.modulate = Color.WHITE
				cube_instance.add_child(label)
				
				add_child(cube_instance)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
