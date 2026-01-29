extends Node3D

@export var spacing : float = 60.0

func _ready():
	var shape_names = ["Human", "Chair", "House", "Bottle", "Cup", "Computer"]
	
	for i in range(6):
		var generator = TerrainGeneratorShapes.new()
		generator.shape_type = i
		generator.name = shape_names[i]
		
		# Position in a line or grid
		var x = ((i % 3) - 1) * spacing
		var z = (floor(i / 3) - 0.5) * spacing
		
		generator.position = Vector3(x, 0, z)
		
		# Settings
		generator.noise_scale = 1.0 
		generator.iso_level = 0.0
		# Scale up the mesh to be visible and clear
		generator.scale = Vector3(1, 1, 1) 
		# Big chunk size to contain the whole SDF
		generator.chunk_scale = 120.0 
		generator.center_position = Vector3(0, 0, 0)
		
		add_child(generator)
		
		# Add label
		var label = Label3D.new()
		label.text = shape_names[i]
		label.position = generator.position + Vector3(0, 25, 0)
		label.font_size = 64
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		
		print("Spawned " + shape_names[i])

func _process(delta):
	# Rotate camera or objects?
	pass
