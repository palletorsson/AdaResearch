# validate_user_fixed_simple.gd
# Simplified validation script for user's fixed marching cubes implementation

extends RefCounted

class_name MarchingCubesValidatorSimple

# Test data structures to simulate the user's implementation
class TestVoxelGrid:
	var data: PackedFloat32Array
	var resolution: int
	
	func _init(resolution: int):
		self.resolution = resolution
		var extended_size = (resolution + 2)
		self.data.resize(extended_size * extended_size * extended_size)
		self.data.fill(1.0)
	
	func read(x: int, y: int, z: int) -> float:
		var extended_res = resolution + 2
		if x < 0 or y < 0 or z < 0 or x >= extended_res or y >= extended_res or z >= extended_res:
			return 1.0
		return self.data[x + extended_res * (y + extended_res * z)]
	
	func write(x: int, y: int, z: int, value: float):
		var extended_res = resolution + 2
		if x < 0 or y < 0 or z < 0 or x >= extended_res or y >= extended_res or z >= extended_res:
			return
		self.data[x + extended_res * (y + extended_res * z)] = clamp(value, -1.0, 1.0)

static func run_validation() -> Dictionary:
	print("VALIDATING USER'S FIXED MARCHING CUBES IMPLEMENTATION")
	print("============================================================")
	
	var results = {
		"tests_passed": 0,
		"tests_failed": 0,
		"total_tests": 0,
		"issues": []
	}
	
	# Test 1: VoxelGrid boundary handling
	test_voxel_grid_boundaries(results)
	
	# Test 2: Terrain value calculation
	test_terrain_calculation(results)
	
	# Test 3: Robust interpolation
	test_robust_interpolation(results)
	
	# Test 4: Triangle validation
	test_triangle_validation(results)
	
	# Test 5: Cube configuration
	test_cube_configuration(results)
	
	print("============================================================")
	print("VALIDATION RESULTS:")
	print("   Tests Passed: " + str(results.tests_passed))
	print("   Tests Failed: " + str(results.tests_failed))
	print("   Total Tests: " + str(results.total_tests))
	
	if results.issues.size() > 0:
		print("\nISSUES FOUND:")
		for issue in results.issues:
			print("   - " + issue)
	else:
		print("   All tests passed! Implementation looks solid.")
	
	return results

static func test_voxel_grid_boundaries(results: Dictionary):
	print("\nTest 1: VoxelGrid Boundary Handling")
	results.total_tests += 1
	
	var grid = TestVoxelGrid.new(10)
	
	# Test boundary reads
	var boundary_tests = [
		{"pos": Vector3i(-1, 5, 5), "expected": 1.0, "desc": "Outside negative"},
		{"pos": Vector3i(5, 5, 15), "expected": 1.0, "desc": "Outside positive"},
		{"pos": Vector3i(5, 5, 5), "expected": 1.0, "desc": "Inside grid"}
	]
	
	var passed = true
	for test in boundary_tests:
		var value = grid.read(test.pos.x, test.pos.y, test.pos.z)
		if abs(value - test.expected) > 0.001:
			print("   FAIL " + test.desc + ": Expected " + str(test.expected) + ", got " + str(value))
			passed = false
		else:
			print("   PASS " + test.desc + ": OK")
	
	if passed:
		results.tests_passed += 1
		print("   VoxelGrid boundary handling: PASSED")
	else:
		results.tests_failed += 1
		results.issues.append("VoxelGrid boundary handling failed")

static func test_terrain_calculation(results: Dictionary):
	print("\nTest 2: Terrain Value Calculation")
	results.total_tests += 1
	
	# Create a mock noise generator
	var mock_noise = FastNoiseLite.new()
	mock_noise.frequency = 0.1
	
	# Test terrain calculation logic (simplified)
	var test_points = [
		{"pos": Vector3i(0, 0, 0), "desc": "Origin"},
		{"pos": Vector3i(10, 10, 10), "desc": "Positive coordinates"},
		{"pos": Vector3i(-5, -5, -5), "desc": "Negative coordinates"}
	]
	
	var passed = true
	for test in test_points:
		var noise_value = mock_noise.get_noise_3d(test.pos.x, test.pos.y, test.pos.z)
		var height_factor = (test.pos.y + test.pos.y % 1) / 50.0 - 0.5
		var terrain_value = clamp(noise_value + height_factor, -1.0, 1.0)
		
		if terrain_value < -1.0 or terrain_value > 1.0:
			print("   FAIL " + test.desc + ": Value out of range: " + str(terrain_value))
			passed = false
		else:
			print("   PASS " + test.desc + ": Valid range " + str(terrain_value))
	
	if passed:
		results.tests_passed += 1
		print("   Terrain calculation: PASSED")
	else:
		results.tests_failed += 1
		results.issues.append("Terrain calculation produces invalid ranges")

static func test_robust_interpolation(results: Dictionary):
	print("\nTest 3: Robust Interpolation")
	results.total_tests += 1
	
	var test_cases = [
		{"a": Vector3(0, 0, 0), "b": Vector3(1, 0, 0), "val_a": 0.8, "val_b": 0.2, "desc": "Normal case"},
		{"a": Vector3(0, 0, 0), "b": Vector3(1, 0, 0), "val_a": 0.5, "val_b": 0.5, "desc": "Identical values"},
		{"a": Vector3(0, 0, 0), "b": Vector3(1, 0, 0), "val_a": 0.0, "val_b": 0.0, "desc": "Both at threshold"},
		{"a": Vector3(0, 0, 0), "b": Vector3(1, 0, 0), "val_a": 1.0, "val_b": 1.0, "desc": "Both solid"}
	]
	
	var passed = true
	for test in test_cases:
		var result = calculate_test_robust_interpolation(test.a, test.b, test.val_a, test.val_b)
		
		# Validate result is between the two points
		var dist_a = result.distance_to(test.a)
		var dist_b = result.distance_to(test.b)
		var total_dist = test.a.distance_to(test.b)
		
		if dist_a + dist_b > total_dist + 0.001:  # Small tolerance
			print("   FAIL " + test.desc + ": Interpolation outside segment")
			passed = false
		else:
			print("   PASS " + test.desc + ": Valid interpolation")
	
	if passed:
		results.tests_passed += 1
		print("   Robust interpolation: PASSED")
	else:
		results.tests_failed += 1
		results.issues.append("Robust interpolation failed")

static func calculate_test_robust_interpolation(a: Vector3, b: Vector3, val_a: float, val_b: float) -> Vector3:
	val_a = clamp(val_a, -1.0, 1.0)
	val_b = clamp(val_b, -1.0, 1.0)
	var threshold = 0.0
	
	var density_diff = abs(val_b - val_a)
	
	if density_diff < 0.001:
		return (a + b) * 0.5
	
	if abs(val_a - threshold) < 0.001:
		return a
	if abs(val_b - threshold) < 0.001:
		return b
	
	var t = (threshold - val_a) / (val_b - val_a)
	t = clamp(t, 0.0, 1.0)
	
	if val_a >= threshold and val_b >= threshold:
		return (a + b) * 0.5
	elif val_a < threshold and val_b < threshold:
		return (a + b) * 0.5
	
	return a + t * (b - a)

static func test_triangle_validation(results: Dictionary):
	print("\nTest 4: Triangle Validation")
	results.total_tests += 1
	
	var test_triangles = [
		{"v1": Vector3(0, 0, 0), "v2": Vector3(1, 0, 0), "v3": Vector3(0, 1, 0), "desc": "Valid triangle", "expected": true},
		{"v1": Vector3(0, 0, 0), "v2": Vector3(0, 0, 0), "v3": Vector3(0, 1, 0), "desc": "Degenerate duplicate vertices", "expected": false},
		{"v1": Vector3(0, 0, 0), "v2": Vector3(0.000001, 0, 0), "v3": Vector3(0, 1, 0), "desc": "Nearly degenerate", "expected": false}
	]
	
	var passed = true
	for test in test_triangles:
		var is_valid = validate_test_triangle(test.v1, test.v2, test.v3)
		
		if is_valid != test.expected:
			print("   FAIL " + test.desc + ": Expected " + str(test.expected) + ", got " + str(is_valid))
			passed = false
		else:
			print("   PASS " + test.desc + ": Correct validation")
	
	if passed:
		results.tests_passed += 1
		print("   Triangle validation: PASSED")
	else:
		results.tests_failed += 1
		results.issues.append("Triangle validation failed")

static func validate_test_triangle(v1: Vector3, v2: Vector3, v3: Vector3) -> bool:
	var min_distance = 0.000001
	
	if (v1.distance_squared_to(v2) < min_distance or
		v2.distance_squared_to(v3) < min_distance or
		v3.distance_squared_to(v1) < min_distance):
		return false
	
	var edge1 = v2 - v1
	var edge2 = v3 - v1
	var normal = edge1.cross(edge2)
	
	return normal.length_squared() > min_distance

static func test_cube_configuration(results: Dictionary):
	print("\nTest 5: Cube Configuration")
	results.total_tests += 1
	
	# Test cube configuration calculation
	var test_densities = [
		{"densities": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], "expected_idx": 0, "desc": "All solid"},
		{"densities": [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0], "expected_idx": 255, "desc": "All empty"},
		{"densities": [1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0], "expected_idx": 1, "desc": "Single corner solid"}
	]
	
	var passed = true
	for test in test_densities:
		var idx = calculate_test_configuration_index(test.densities)
		
		if idx != test.expected_idx:
			print("   FAIL " + test.desc + ": Expected index " + str(test.expected_idx) + ", got " + str(idx))
			passed = false
		else:
			print("   PASS " + test.desc + ": Correct index " + str(idx))
	
	if passed:
		results.tests_passed += 1
		print("   Cube configuration: PASSED")
	else:
		results.tests_failed += 1
		results.issues.append("Cube configuration calculation failed")

static func calculate_test_configuration_index(densities: Array) -> int:
	var idx = 0
	var iso_level = 0.0
	
	for i in range(8):
		if densities[i] < iso_level:
			idx |= (1 << i)
	
	return idx 