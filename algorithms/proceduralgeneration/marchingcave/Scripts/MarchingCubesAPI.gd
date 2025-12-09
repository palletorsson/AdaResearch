class_name MarchingCubesAPI extends Object

# Mapping of string names to ShapeType enum indices in TerrainGeneratorShapes
# usage: var my_obj = MarchingCubesAPI.create("computer")

const SHAPE_MAP = {
	"human": 0,
	"chair": 1,
	"house": 2,
	"bottle": 3,
	"cup": 4,
	"computer": 5,
	"computerscreen": 5 # Alias
}

static func create(shape_name: String, position: Vector3 = Vector3.ZERO, scale: float = 1.0) -> Node3D:
	"""
	Creates a new Marching Cubes object by name.
	Returns the container Node3D containing the mesh.
	"""
	var key = shape_name.to_lower().replace("mc:", "")
	
	if not key in SHAPE_MAP:
		push_error("MarchingCubesAPI: Unknown shape '%s'. Available: %s" % [shape_name, SHAPE_MAP.keys()])
		return null
		
	var shape_id = SHAPE_MAP[key]
	
	# Load the generator script
	var generator_script = load("res://algorithms/proceduralgeneration/marchingcave/Scripts/TerrainGeneratorShapes.gd")
	
	# Create container
	var container = Node3D.new()
	container.name = "MC_" + shape_name.capitalize()
	container.position = position
	container.scale = Vector3.ONE * scale
	
	# Create generator instance
	var terrain = MeshInstance3D.new()
	terrain.name = "Generator"
	terrain.set_script(generator_script)
	
	# Configure for single static object
	terrain.shape_type = shape_id
	terrain.chunk_scale = 120.0 # Standard size for complete objects
	terrain.iso_level = 0.0
	terrain.noise_scale = 1.0
	
	# Objects (chair, computer, etc.) need outward facing normals/colliders
	# unlike caves which are inward facing.
	terrain.invert_faces = true 
	
	# Add default nice material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.9) # Default clay/white
	material.metallic = 0.1
	material.roughness = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain.material_override = material
	
	container.add_child(terrain)
	
	return container

const MATERIALS = {
	"default": {
		"albedo": Color(0.8, 0.8, 0.9),
		"metallic": 0.1,
		"roughness": 0.5
	},
	"bakelite": {
		"albedo": Color(0.15, 0.08, 0.05), # Dark brownish black
		"metallic": 0.0,
		"roughness": 0.1, # Very shiny
		"specular": 0.8
	},
	"plastic_red": {
		"albedo": Color(0.8, 0.1, 0.1),
		"metallic": 0.0,
		"roughness": 0.2
	},
	"metal": {
		"albedo": Color(0.7, 0.7, 0.7),
		"metallic": 1.0,
		"roughness": 0.2
	}
}

static func apply_material(object: Node3D, material_name: String):
	"""
	Applies a preset material to the Marching Cubes object.
	"""
	var generator = object.find_child("Generator")
	if not generator:
		return
		
	var key = material_name.to_lower()
	if not key in MATERIALS:
		print("MarchingCubesAPI: Unknown material '%s'" % material_name)
		return
		
	var props = MATERIALS[key]
	var material = StandardMaterial3D.new()
	
	if "albedo" in props: material.albedo_color = props["albedo"]
	if "metallic" in props: material.metallic = props["metallic"]
	if "roughness" in props: material.roughness = props["roughness"]
	if "specular" in props: material.metallic_specular = props["specular"]
	
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	generator.material_override = material
	print("MarchingCubesAPI: Applied material '%s'" % material_name)

static func list_available_shapes() -> Array:
	return SHAPE_MAP.keys()
