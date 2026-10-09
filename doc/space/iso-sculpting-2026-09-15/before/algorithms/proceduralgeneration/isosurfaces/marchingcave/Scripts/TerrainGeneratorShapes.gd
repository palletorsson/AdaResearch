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

var preserve_empty_result := false

func create_mesh() -> void:
	# This museum comparison treats a successful zero-triangle dispatch as absence.
	# Inspect the raw GPU counter so a safety-aborted large result is not called empty.
	if thread and thread.is_started():
		thread.wait_to_finish()
		thread = null
	if preserve_empty_result and rendering_device != null and counter_data_bytes != null and counter_data_bytes.size() >= 4 and counter_data_bytes.decode_s32(0) == 0:
		array_mesh.clear_surfaces()
		mesh = array_mesh
		for child in get_children():
			if child is StaticBody3D: child.queue_free()
		waiting_for_meshthread = false
		_initial_generation_done = true
		set_process(false)
		print("TerrainGeneratorShapes: verified empty extracted result")
		return
	super.create_mesh()

func _create_fallback_mesh() -> void:
	print("TerrainGeneratorShapes: Creating fallback mesh...")
	var sphere = SphereMesh.new()
	sphere.radius = 10.0
	sphere.height = 20.0
	mesh = sphere
	_create_collision()
	print("✅ Fallback mesh created")

	# continuous_update defaults to false in base class, so it auto-stops after first mesh
