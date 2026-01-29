extends TerrainGeneratorBase

func get_class_name() -> String:
	return "TerrainGeneratorFlat"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/marchingcave/Compute/MarchingCubesFlat.glsl"

func _create_fallback_mesh():
	print("TerrainGeneratorFlat: Creating fallback flat landscape...")
	_create_simple_flat_mesh()
	print("✅ Fallback flat landscape created")

func _create_simple_flat_mesh():
	# Create a simple flat plane with some hills as fallback
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create a large flat terrain grid
	var size = 200.0  # Size of terrain
	var segments = 50  # Resolution
	var step = size / segments
	
	# Generate vertices for flat terrain with hills
	for z in range(segments + 1):
		for x in range(segments + 1):
			var px = (x - segments / 2.0) * step
			var pz = (z - segments / 2.0) * step
			
			# Add some rolling hills
			var height = 0.0
			height += sin(px * 0.05) * cos(pz * 0.05) * 8.0
			height += sin(px * 0.15) * cos(pz * 0.12) * 3.0
			
			vertices.append(Vector3(px, height, pz))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(x) / segments, float(z) / segments))
	
	# Generate indices for triangles
	for z in range(segments):
		for x in range(segments):
			var i0 = z * (segments + 1) + x
			var i1 = i0 + 1
			var i2 = (z + 1) * (segments + 1) + x
			var i3 = i2 + 1
			
			# Two triangles per quad
			indices.append(i0)
			indices.append(i2)
			indices.append(i1)
			
			indices.append(i1)
			indices.append(i2)
			indices.append(i3)
	
	# Create the mesh
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	print("✅ Created flat landscape with ", vertices.size(), " vertices, ", indices.size() / 3, " triangles")
	_create_collision()

