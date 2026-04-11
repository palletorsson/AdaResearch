extends Node3D

# @identity
# essence: for x,y,z in range(4)³: cube.position = Vector3(x,y,z) with label "[x,y,z]" — 64 pickup cubes forming a solid 4×4×4 volume where every position is labeled with its three-dimensional index
# desire: to climb inside a three-dimensional array — to reach up and grab a cube at [2,3,1] and feel that three numbers describe a unique place in space that only you can occupy at that moment
# critical_parameter: spacing — at 1.0m the cubes form a compact volume you can reach into; increasing spacing makes the array a sparse structure you must move through rather than reach across
# triggers: picking up cubes physically empties cells from the volume — the 3D array becomes a sculpture with negative space carved by interaction
# emerges: students discover that volumetric indexing requires physical intuition that 2D indexing does not — you must think in three directions simultaneously, and your body knows how to do this even when your mind struggles
# needs: pickup cubes [has]; Label3D [x,y,z] labels [has]; no-depth-test labels ensure always-readable index [has]; apply_grid_config supports size_x/y/z/spacing overrides [has]; no live data visualization companion [missing]
# relationships: extends grid_2d_4x4 to 3 dimensions; final step in the 1D→2D→3D spatial array progression; connects to voxelnoise (3D grid with noise values) and grid_3d in the grid_editor sequence
# truth: a three-dimensional array is the minimum structure needed to represent volumetric space — every 3D game world, CT scan, and weather simulation is an indexed cube of values

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
	if config.is_empty():
		return
	var size_x = int(config["size_x"]) if config.has("size_x") else 4
	var size_y = int(config["size_y"]) if config.has("size_y") else 4
	var size_z = int(config["size_z"]) if config.has("size_z") else 4
	var spacing = float(config["spacing"]) if config.has("spacing") else 1.0
	var label_size = int(config["label_size"]) if config.has("label_size") else 28
	var label_color = Color.from_string(config["label_color"], Color.WHITE) if config.has("label_color") else Color.WHITE

	# Rebuild
	for child in get_children():
		if not child.owner:
			child.queue_free()
	await get_tree().process_frame

	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	for x in range(size_x):
		for y in range(size_y):
			for z in range(size_z):
				var cube_instance = pickup_cube_scene.instantiate()
				cube_instance.name = "Cube_%d_%d_%d" % [x, y, z]
				cube_instance.position = Vector3(x * spacing, y * spacing, z * spacing)

				var label = Label3D.new()
				label.text = "[%d, %d, %d]" % [x, y, z]
				label.font_size = label_size
				label.pixel_size = 0.003
				label.outline_size = 5
				label.outline_modulate = Color(0, 0, 0, 1)
				label.position = Vector3(0, 0.6, 0)
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.no_depth_test = true
				label.modulate = label_color
				cube_instance.add_child(label)

				add_child(cube_instance)
