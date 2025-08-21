# test_unified_implementation.gd
# Test script for the unified landscape cave generator

extends Node3D

func _ready():
	print("=== Testing Unified Landscape Cave Generator ===")
	test_basic_functionality()
	test_parameter_changes()
	test_lookup_tables()
	print("=== All tests completed ===")

func test_basic_functionality():
	print("\n1. Testing basic functionality...")
	
	# Create generator instance
	var generator = LandscapeCaveGenerator.new()
	add_child(generator)
	
	# Test initialization
	assert(generator.noise_terrain != null, "Terrain noise should be initialized")
	assert(generator.noise_cave_primary != null, "Cave noise should be initialized")
	assert(generator.edge_table.size() == 256, "Edge table should have 256 entries")
	assert(generator.triangle_table.size() == 256, "Triangle table should have 256 entries")
	
	print("✓ Basic initialization successful")
	
	# Test density calculation
	var test_positions = [
		Vector3(0, 0, 0),
		Vector3(10, 5, 10),
		Vector3(-5, -2, 8)
	]
	
	for pos in test_positions:
		var density = generator.calculate_density_at_position(pos)
		assert(density >= 0.0 and density <= 1.0, "Density should be in range [0,1]")
	
	print("✓ Density calculation working")
	
	# Test chunk creation
	generator.fixed_map_size = true
	generator.num_chunks = Vector3i(2, 1, 2)
	generator.bounds_size = 10.0
	generator.num_points_per_axis = 8  # Small for fast testing
	
	await generator.generate_world()
	
	assert(generator.chunks.size() > 0, "Chunks should be generated")
	print("✓ World generation successful")
	
	generator.queue_free()

func test_parameter_changes():
	print("\n2. Testing parameter changes...")
	
	var generator = LandscapeCaveGenerator.new()
	add_child(generator)
	
	# Test terrain parameters
	var original_height = generator.terrain_height
	generator.set_terrain_parameters({"height": 15.0})
	assert(generator.terrain_height == 15.0, "Terrain height should update")
	
	# Test cave parameters
	var original_density = generator.cave_density
	generator.set_cave_parameters({"density": 0.8})
	assert(generator.cave_density == 0.8, "Cave density should update")
	
	print("✓ Parameter updates working")
	
	generator.queue_free()

func test_lookup_tables():
	print("\n3. Testing marching cubes lookup tables...")
	
	var edge_table = MarchingCubesLookupTables.get_edge_table()
	var triangle_table = MarchingCubesLookupTables.get_triangle_table()
	
	assert(edge_table.size() == 256, "Edge table should have 256 entries")
	assert(triangle_table.size() == 256, "Triangle table should have 256 entries")
	
	# Test specific known configurations
	assert(triangle_table[0].is_empty(), "Configuration 0 should be empty")
	assert(not triangle_table[1].is_empty(), "Configuration 1 should have triangles")
	
	# Test edge vertex mapping
	var edge_vertices = MarchingCubesLookupTables.get_edge_vertices()
	assert(edge_vertices.size() == 12, "Should have 12 edge connections")
	
	print("✓ Lookup tables validated")

func test_triangle_generation():
	print("\n4. Testing triangle generation...")
	
	var generator = LandscapeCaveGenerator.new()
	add_child(generator)
	
	# Create a simple test chunk
	var chunk = generator.TerrainChunk.new(Vector3i.ZERO, AABB(Vector3.ZERO, Vector3.ONE * 10))
	
	# Test triangle creation
	var test_triangle = generator.Triangle.new(
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 1, 0)
	)
	
	assert(test_triangle.vertices.size() == 3, "Triangle should have 3 vertices")
	assert(test_triangle.normals.size() == 3, "Triangle should have 3 normals")
	
	print("✓ Triangle generation working")
	
	generator.queue_free()

func _on_test_complete():
	print("All tests passed! ✓")
	get_tree().quit()
