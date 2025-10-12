extends SceneTree

## Test runner for Ch 06 Physics scripts
## Run with: godot --headless -s test_ch06_physics.gd --quit

func _init():
	print("=== Testing Ch 06 Physics Scripts ===")

	var scripts_to_test = [
		"res://algorithms/physics/example_6_1_basic_rigidbody_vr.gd",
		"res://algorithms/physics/example_6_2_falling_boxes_vr.gd",
		"res://algorithms/physics/example_6_3_compound_bodies_vr.gd",
		"res://algorithms/physics/example_6_4_windmill_vr.gd",
		"res://algorithms/physics/example_6_5_chain_vr.gd",
		"res://algorithms/physics/example_6_6_grab_vr.gd",
		"res://algorithms/physics/example_6_7_bridge_vr.gd",
		"res://algorithms/physics/example_6_8_collision_layers_vr.gd"
	]

	var all_passed = true
	var error_count = 0

	for script_path in scripts_to_test:
		var result = test_script(script_path)
		if not result:
			all_passed = false
			error_count += 1

	print("\n" + "=".repeat(60))
	print("SUMMARY: Tested " + str(scripts_to_test.size()) + " scripts")
	if all_passed:
		print("✅ All Ch 06 Physics scripts passed basic validation!")
	else:
		print("❌ " + str(error_count) + " script(s) have errors - see above")
	print("=".repeat(60))

	quit()

func test_script(path: String) -> bool:
	print("\n--- Testing: " + path.get_file() + " ---")

	if not FileAccess.file_exists(path):
		print("  ❌ ERROR: File does not exist")
		return false

	var script = load(path)
	if script == null:
		print("  ❌ ERROR: Failed to load script")
		return false

	if not script is GDScript:
		print("  ❌ ERROR: Not a valid GDScript")
		return false

	var source_code = script.source_code
	if source_code == null or source_code == "":
		print("  ❌ ERROR: Script has no source code")
		return false

	var has_node3d = source_code.contains("extends Node3D")
	var has_physics = source_code.contains("RigidBody") or source_code.contains("physics") or source_code.contains("Physics")

	print("  ✓ Script loads successfully")
	if has_node3d:
		print("  ✓ Extends Node3D")
	if has_physics:
		print("  ✓ Has physics references")

	return true
