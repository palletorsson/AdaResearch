extends Node3D
## Quick test for WavefunctionResources
## Run this scene to verify the shared resources work correctly

func _ready() -> void:
	print("=== WavefunctionResources Test ===")
	
	# Test 1: Shared meshes
	print("\n1. Testing shared meshes...")
	var trail = WavefunctionResources.get_trail_sphere()
	var unit = WavefunctionResources.get_unit_sphere()
	var point = WavefunctionResources.get_point_sphere()
	print("   Trail sphere: radius=", trail.radius)
	print("   Unit sphere: radius=", unit.radius)
	print("   Point sphere: radius=", point.radius)
	
	# Verify they're cached (same instance)
	var trail2 = WavefunctionResources.get_trail_sphere()
	print("   Cache test: ", "PASS ✓" if trail == trail2 else "FAIL ✗")
	
	# Test 2: Materials
	print("\n2. Testing cached materials...")
	var mat1 = WavefunctionResources.get_emissive_material(Color.RED, 1.0)
	var mat2 = WavefunctionResources.get_emissive_material(Color.RED, 1.0)
	var mat3 = WavefunctionResources.get_emissive_material(Color.BLUE, 1.0)
	print("   Same color returns cached: ", "PASS ✓" if mat1 == mat2 else "FAIL ✗")
	print("   Different color creates new: ", "PASS ✓" if mat1 != mat3 else "FAIL ✗")
	
	# Test 3: Lookup tables
	print("\n3. Testing audio lookup tables...")
	var sine_0 = WavefunctionResources.fast_sine(0.0)
	var sine_25 = WavefunctionResources.fast_sine(0.25)
	var sine_50 = WavefunctionResources.fast_sine(0.5)
	print("   fast_sine(0.0) = %.4f (expected ~0)" % sine_0)
	print("   fast_sine(0.25) = %.4f (expected ~1)" % sine_25)
	print("   fast_sine(0.5) = %.4f (expected ~0)" % sine_50)
	print("   Sine accuracy: ", "PASS ✓" if abs(sine_25 - 1.0) < 0.01 else "FAIL ✗")
	
	var square_0 = WavefunctionResources.fast_square(0.0)
	var square_25 = WavefunctionResources.fast_square(0.25)
	var square_75 = WavefunctionResources.fast_square(0.75)
	print("   fast_square(0.0) = %.1f (expected 1)" % square_0)
	print("   fast_square(0.25) = %.1f (expected 1)" % square_25)
	print("   fast_square(0.75) = %.1f (expected -1)" % square_75)
	print("   Square accuracy: ", "PASS ✓" if square_0 == 1.0 and square_75 == -1.0 else "FAIL ✗")
	
	# Test 4: MultiMesh creation
	print("\n4. Testing MultiMesh helper...")
	var mmi = WavefunctionResources.create_trail_multimesh_instance(64, Color.ORANGE)
	print("   Instance count: ", mmi.multimesh.instance_count)
	print("   Has material: ", "PASS ✓" if mmi.material_override != null else "FAIL ✗")
	add_child(mmi)
	
	# Visual test - place some instances
	for i in range(64):
		var angle = float(i) / 64.0 * TAU
		var pos = Vector3(cos(angle) * 2, sin(angle) * 2, 0)
		mmi.multimesh.set_instance_transform(i, Transform3D(Basis(), pos))
	print("   Visual: Orange ring should appear")
	
	print("\n=== All Tests Complete ===")
	print("Check the 3D view for a ring of orange spheres.")
	
	# Add a camera so we can see
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 5)
	add_child(camera)
