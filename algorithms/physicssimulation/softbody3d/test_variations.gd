extends Node3D

# Test script to validate all 10 sphere variations + additional bodies
func _ready():
	print("🔬 Testing Soft Body Variations...")
	
	await get_tree().create_timer(1.0).timeout
	_test_all_variations()

func _test_all_variations():
	var soft_body_variations = get_node("SoftBodyVariations")
	if not soft_body_variations:
		print("❌ SoftBodyVariations node not found!")
		return
	
	var children = soft_body_variations.get_children()
	print("📊 Found %d total soft bodies" % children.size())
	
	# Test the 10 sphere variations
	var sphere_count = 0
	var expected_spheres = [
		{"name": "SphereSoftBody01", "precision": 5, "pressure": 0.05},
		{"name": "SphereSoftBody02", "precision": 6, "pressure": 0.1},
		{"name": "SphereSoftBody03", "precision": 7, "pressure": 0.15},
		{"name": "SphereSoftBody04", "precision": 8, "pressure": 0.2},
		{"name": "SphereSoftBody05", "precision": 9, "pressure": 0.25},
		{"name": "SphereSoftBody06", "precision": 10, "pressure": 0.3},
		{"name": "SphereSoftBody07", "precision": 12, "pressure": 0.4},
		{"name": "SphereSoftBody08", "precision": 15, "pressure": 0.5},
		{"name": "SphereSoftBody09", "precision": 20, "pressure": 0.7},
		{"name": "SphereSoftBody10", "precision": 25, "pressure": 1.0}
	]
	
	print("\n🔍 Validating Sphere Variations:")
	for expected in expected_spheres:
		var body = soft_body_variations.get_node_or_null(expected.name)
		if body and body is SoftBody3D:
			var precision_match = body.simulation_precision == expected.precision
			var pressure_match = abs(body.pressure_coefficient - expected.pressure) < 0.001
			
			if precision_match and pressure_match:
				print("✅ %s: Precision=%d, Pressure=%.2f ✓" % [
					expected.name, body.simulation_precision, body.pressure_coefficient
				])
				sphere_count += 1
			else:
				print("❌ %s: Expected P=%d/%.2f, Got P=%d/%.2f" % [
					expected.name, expected.precision, expected.pressure,
					body.simulation_precision, body.pressure_coefficient
				])
		else:
			print("❌ %s: Not found or wrong type!" % expected.name)
	
	print("\n📈 Sphere Variation Summary:")
	print("  Expected: 10 sphere variations")
	print("  Found: %d sphere variations" % sphere_count)
	
	# Test additional body types
	print("\n🔍 Validating Additional Body Types:")
	var additional_bodies = ["BoxSoftBody", "CylinderSoftBody", "CapsuleSoftBody"]
	var additional_count = 0
	
	for body_name in additional_bodies:
		var body = soft_body_variations.get_node_or_null(body_name)
		if body and body is SoftBody3D:
			print("✅ %s: Found" % body_name)
			additional_count += 1
		else:
			print("❌ %s: Not found!" % body_name)
	
	print("\n📊 Final Summary:")
	print("  Total Bodies: %d" % children.size())
	print("  Sphere Variations: %d/10" % sphere_count)
	print("  Additional Bodies: %d/3" % additional_count)
	
	if sphere_count == 10 and additional_count == 3:
		print("🎉 All soft body variations configured correctly!")
	else:
		print("⚠️ Some configurations are missing or incorrect")
	
	# Test physics behavior differences
	print("\n🧪 Testing Physics Behavior Differences...")
	_test_physics_differences()

func _test_physics_differences():
	var soft_body_variations = get_node("SoftBodyVariations")
	var bodies = []
	
	# Get first 3 spheres for comparison
	for i in range(1, 4):
		var body_name = "SphereSoftBody%02d" % i
		var body = soft_body_variations.get_node_or_null(body_name)
		if body:
			bodies.append(body)
	
	if bodies.size() >= 3:
		print("💨 Applying test impulses to compare behavior...")
		
		# Apply same impulse to different bodies
		var test_force = Vector3(2.0, 1.0, 0.0)
		for body in bodies:
			if body.has_method("apply_impulse"):
				body.apply_impulse(test_force)
				print("  Applied impulse to %s (P=%.2f)" % [body.name, body.pressure_coefficient])
		
		print("⏰ Observe the different deformation behaviors!")
		print("   - Lower pressure = more deformation")
		print("   - Higher precision = smoother physics")
	
	print("\n🏁 Soft Body Variations Test Complete!")
