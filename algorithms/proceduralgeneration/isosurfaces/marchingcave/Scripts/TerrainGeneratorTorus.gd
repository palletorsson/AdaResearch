extends TerrainGeneratorBase

func get_class_name() -> String:
	return "TerrainGeneratorTorus"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/marchingcave/Compute/MarchingCubesTorus.glsl"

func _create_fallback_mesh():
	print("TerrainGeneratorTorus: Creating fallback simple torus...")
	_create_fallback_torus()
	print("✅ Fallback torus created")

func _create_fallback_torus():
	var torus = TorusMesh.new()
	torus.inner_radius = 30.0
	torus.outer_radius = 50.0
	torus.rings = 48
	torus.ring_segments = 24
	mesh = torus
	# Ensure collision is created for the primitive mesh if needed
	create_trimesh_collision() 
	
	print("✅ Fallback torus created")
