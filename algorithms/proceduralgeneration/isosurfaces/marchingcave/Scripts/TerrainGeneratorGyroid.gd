extends TerrainGeneratorBase
class_name TerrainGeneratorGyroid

func get_class_name() -> String:
	return "TerrainGeneratorGyroid"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingGyroid.glsl"

func _process(_delta):
	# Disable per-frame updates for optimal static mesh generation
	pass

func _create_fallback_mesh() -> void:
	print("TerrainGeneratorGyroid: Creating fallback sphere...")
	# Just a Sphere for fallback
	var sphere = SphereMesh.new()
	sphere.radius = 20.0
	sphere.height = 40.0
	mesh = sphere
	_create_collision()
