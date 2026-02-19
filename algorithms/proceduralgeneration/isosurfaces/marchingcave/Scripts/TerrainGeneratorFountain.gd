extends TerrainGeneratorBase
class_name TerrainGeneratorFountain

func get_class_name() -> String:
	return "TerrainGeneratorFountain"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingFountain.glsl"

func _create_fallback_mesh():
	print("TerrainGeneratorFountain: Creating fallback cylinder...")
	_create_simple_cylinder_mesh()
	print("✅ Fallback cylinder created")

func _create_simple_cylinder_mesh():
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 20.0
	cylinder.bottom_radius = 20.0
	cylinder.height = 100.0
	mesh = cylinder
	_create_collision()
