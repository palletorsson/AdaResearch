extends Node3D

@export var spacing : float = 4.0  # Meters between shapes
@export var shape_scale : float = 0.025  # Scale down from SDF units to VR meters

func _ready() -> void:
	var shape_names = ["Human", "Chair", "House", "Bottle", "Cup", "Computer"]
	
	for i in range(6):
		var generator = TerrainGeneratorShapes.new()
		generator.shape_type = i
		generator.name = shape_names[i]
		
		# Position in a 3x2 grid at ground level, in front of origin
		var col = i % 3
		var row = int(i / 3)
		var x = (col - 1) * spacing
		var z = -(row + 1) * spacing  # In front of player
		
		generator.position = Vector3(x, 0, z)
		generator.scale = Vector3.ONE * shape_scale
		
		# Settings
		generator.noise_scale = 1.0 
		generator.iso_level = 0.0
		generator.chunk_scale = 120.0
		generator.center_position = Vector3(0, 0, 0)
		generator.invert_faces = true  # View from outside
		
		# Non-reflective material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(float(i) / 6.0, 0.6, 0.9)
		material.metallic = 0.0
		material.roughness = 1.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		generator.material_override = material
		
		add_child(generator)
		
		# Add label
		var label = Label3D.new()
		label.text = shape_names[i]
		label.position = Vector3(x, 1.5, z)
		label.font_size = 32
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		
		print("Spawned " + shape_names[i])

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
