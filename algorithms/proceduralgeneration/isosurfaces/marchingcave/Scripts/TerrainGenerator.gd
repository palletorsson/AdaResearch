extends TerrainGeneratorBase

func get_class_name() -> String:
	return "TerrainGenerator"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubes.glsl"

func _create_fallback_mesh() -> void:
	print("TerrainGenerator: Creating fallback rainbow cave...")
	_create_simple_cave_mesh()
	print("✅ Fallback rainbow cave created")

func _create_simple_cave_mesh() -> void:
	# Create a simple tunnel/cave mesh as fallback
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create a long, winding organic cave tunnel
	var base_radius = 12.0
	var length = 200.0  # Much longer!
	var segments = 40   # More detail
	var rings = 100     # Many more sections
	
	# Generate vertices for organic tunnel
	for ring in range(rings + 1):
		var progress = float(ring) / rings
		var z = (progress - 0.5) * length
		
		# Cave path curves and winds through space
		var path_curve_x = sin(progress * PI * 4.0) * 30.0  # S-curves
		var path_curve_y = cos(progress * PI * 6.0) * 20.0  # Vertical waves
		
		# Radius varies along the tunnel (wider and narrower sections)
		var radius_variation = 0.7 + 0.6 * sin(progress * PI * 8.0)
		var current_radius = base_radius * radius_variation
		
		for seg in range(segments):
			var angle = float(seg) / segments * TAU
			var base_x = cos(angle) * current_radius
			var base_y = sin(angle) * current_radius
			
			# Multiple layers of organic noise
			var noise1 = sin(z * 0.02 + angle * 4.0) * 0.3      # Large bumps
			var noise2 = sin(z * 0.08 + angle * 12.0) * 0.15    # Medium details  
			var noise3 = sin(z * 0.2 + angle * 8.0) * 0.08      # Fine texture
			var noise4 = cos(z * 0.15 + angle * 6.0 + PI) * 0.12 # Asymmetric variations
			
			# Combine all noise layers
			var total_noise = 1.0 + noise1 + noise2 + noise3 + noise4
			
			# Add some chaos for more organic feeling
			var chaos_x = sin(z * 0.03 + angle * 7.0 + progress * 10.0) * 2.0
			var chaos_y = cos(z * 0.04 + angle * 5.0 + progress * 8.0) * 1.5
			
			# Final position with path curves and noise
			var final_x = (base_x * total_noise) + path_curve_x + chaos_x
			var final_y = (base_y * total_noise) + path_curve_y + chaos_y
			
			vertices.append(Vector3(final_x, final_y, z))
			
			# Calculate normal for proper lighting (pointing inward for cave feel)
			var normal_dir = Vector3(final_x - path_curve_x, final_y - path_curve_y, 0).normalized()
			normals.append(-normal_dir)  # Inward-facing normals
			
			# UV mapping with some distortion for interesting texture flow
			var u = float(seg) / segments
			var v = progress + sin(progress * PI * 4.0) * 0.1  # Flowing UV
			uvs.append(Vector2(u, v))
	
	# Generate indices for triangles (double-sided)
	for ring in range(rings):
		for seg in range(segments):
			var current = ring * segments + seg
			var next = ring * segments + (seg + 1) % segments
			var next_ring_current = (ring + 1) * segments + seg
			var next_ring_next = (ring + 1) * segments + (seg + 1) % segments
			
			# Two triangles per quad (front faces)
			indices.append(current)
			indices.append(next_ring_current)
			indices.append(next)
			
			indices.append(next)
			indices.append(next_ring_current)
			indices.append(next_ring_next)
			
			# Two triangles per quad (back faces - reversed winding)
			indices.append(current)
			indices.append(next)
			indices.append(next_ring_current)
			
			indices.append(next)
			indices.append(next_ring_next)
			indices.append(next_ring_next)
	
	# Create the mesh
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	print("✅ Created double-sided cave tunnel with ", vertices.size(), " vertices, ", indices.size() / 3, " triangles")
	_create_collision()
