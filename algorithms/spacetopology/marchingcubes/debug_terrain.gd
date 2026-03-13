#!/usr/bin/env -S godot --headless --script
# debug_terrain.gd - Detailed debugging of marching cubes issues

extends SceneTree

func _ready() -> void:
	print("🔍 DETAILED MARCHING CUBES DIAGNOSTIC")
 
	
	test_density_consistency()
	test_marching_cubes_basic()
	test_chunk_boundaries()
 
	quit()

func test_density_consistency() -> void:
	print("\n🧪 TEST 1: Density Calculation Consistency")
 
	
	var terrain_gen = TerrainGenerator.new()
	terrain_gen.configure_terrain({
		"size": Vector2(10, 10),
		"height": 2.0,
		"noise_frequency": 0.1,
		"threshold": 0.5
	})
	
	# Test density at various world positions
	var test_positions = [
		Vector3(0, 0, 0),
		Vector3(1, 0, 1), 
		Vector3(-1, 1, -1),
		Vector3(2.5, -0.5, 2.5)
	]
	
	for pos in test_positions:
		var density = terrain_gen.calculate_terrain_density(pos)
		print("  Position %v -> Density %.3f" % [pos, density])
		
		if density < 0 or density > 1:
			print("  ❌ INVALID DENSITY RANGE!")
		else:
			print("  ✅ Valid density")

func test_marching_cubes_basic() -> void:
	print("\n🧪 TEST 2: Basic Marching Cubes Algorithm")
 
	
	var mc = MarchingCubesGenerator.new()
	
	# Test with known cube configuration that SHOULD generate triangles
	var test_cases = [
		{
			"name": "Half-solid cube",
			"densities": [1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0],
			"expected": "> 0 triangles"
		},
		{
			"name": "Single corner solid", 
			"densities": [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
			"expected": "> 0 triangles"
		},
		{
			"name": "All solid",
			"densities": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
			"expected": "0 triangles"
		},
		{
			"name": "All empty",
			"densities": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
			"expected": "0 triangles"
		}
	]
	
	for test_case in test_cases:
		var cube_data = {
			"positions": [
				Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),
				Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)
			],
			"densities": test_case.densities
		}
		
		var triangles = mc.march_cube(cube_data)
		print("  %s: %d triangles (%s)" % [test_case.name, triangles.size(), test_case.expected])
		
		# Check triangle validity
		for i in range(triangles.size()):
			var triangle = triangles[i]
			if triangle.vertices.size() != 3:
				print("    ❌ Triangle %d has %d vertices (should be 3)" % [i, triangle.vertices.size()])
			elif triangle.normals.size() != 3:
				print("    ❌ Triangle %d has %d normals (should be 3)" % [i, triangle.normals.size()])
			else:
				print("    ✅ Triangle %d valid" % i)

func test_chunk_boundaries() -> void:
	print("\n🧪 TEST 3: Chunk Boundary Analysis")
 
	
	var terrain_gen = TerrainGenerator.new()
	terrain_gen.configure_terrain({
		"size": Vector2(10, 10),
		"height": 2.0,
		"noise_frequency": 0.1
	})
	
	# Create a small test setup
	terrain_gen.create_terrain_voxel_grid()
	
	if terrain_gen.terrain_chunks.size() == 0:
		print("  ❌ No chunks created!")
		return
	
	print("  ✅ Created %d chunks" % terrain_gen.terrain_chunks.size())
	
	# Fill one chunk with test data
	var test_chunk = terrain_gen.terrain_chunks[0]
	terrain_gen.fill_chunk_with_terrain(test_chunk)
	
	# Test boundary consistency
	print("  Testing boundary positions...")
	var boundary_issues = 0
	
	# Test right edge boundary
	for z in range(min(3, test_chunk.chunk_size.z)):
		var interior_pos = Vector3i(test_chunk.chunk_size.x - 1, 0, z)
		var boundary_pos = Vector3i(test_chunk.chunk_size.x, 0, z)
		
		if test_chunk.is_valid_position(interior_pos):
			var interior_density = test_chunk.get_density(interior_pos)
			var world_pos = test_chunk.local_to_world(boundary_pos)
			var expected_boundary_density = terrain_gen.calculate_terrain_density(world_pos)
			
			print("    Interior (%v): %.3f | Boundary (%v): %.3f" % 
				[interior_pos, interior_density, boundary_pos, expected_boundary_density])
			
			if abs(interior_density - expected_boundary_density) > 0.5:
				boundary_issues += 1
				print("      ⚠️  Large density jump detected!")
	
	if boundary_issues == 0:
		print("  ✅ No major boundary issues detected")
	else:
		print("  ❌ Found %d boundary issues" % boundary_issues) 
