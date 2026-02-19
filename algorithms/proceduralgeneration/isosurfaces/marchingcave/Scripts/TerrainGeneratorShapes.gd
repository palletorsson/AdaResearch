class_name TerrainGeneratorShapes extends TerrainGeneratorBase

enum ShapeType {
	HUMAN = 0,
	CHAIR = 1,
	HOUSE = 2,
	BOTTLE = 3,
	CUP = 4,
	COMPUTER = 5,
	MICROSCOPE = 6,
	FLASK = 7,
	DNA = 8,
	ATOM = 9,
	SCULPTURE = 10,
	SPHERE = 11,
	TORUS = 12
}

@export var shape_type : ShapeType = ShapeType.HUMAN

func get_class_name() -> String:
	return "TerrainGeneratorShapes"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesShapes.glsl"

func get_params_array():
	# Get base parameters first
	var params = super.get_params_array()
	# Append our specific shape ID
	params.append(float(shape_type))
	return params

func _create_fallback_mesh():
	print("TerrainGeneratorShapes: Creating fallback mesh...")
	var sphere = SphereMesh.new()
	sphere.radius = 10.0
	sphere.height = 20.0
	mesh = sphere
	_create_collision()
	print("✅ Fallback mesh created")

	# continuous_update defaults to false in base class, so it auto-stops after first mesh
