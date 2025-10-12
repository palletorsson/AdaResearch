extends SceneTree

## Test runner for Ch 01 Vectors scripts
## Run with: godot --headless -s test_ch01_scripts.gd --quit

func _init():
	print("=== Testing Ch 01 Vectors Scripts ===")

	var scripts_to_test = [
		"res://algorithms/vectors/noc_ch01/example_1_1_bouncing_ball_with_no_vectors_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_2_bouncing_ball_with_vectors_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_3_vector_subtraction_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_4_vector_multiplication_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_5_vector_magnitude_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_6_vector_normalize_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_7_motion_101_velocity_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_8_motion_101_velocity_and_constant_acceleration_vr.gd",
		"res://algorithms/vectors/noc_ch01/example_1_9_motion_101_velocity_and_random_acceleration_vr.gd",
		"res://algorithms/vectors/noc_ch01/exercise_1_3_solution_3_d_bouncing_ball_vr.gd",
		"res://algorithms/vectors/noc_ch01/exercise_1_5_solution_accelerate_and_decelerate_vr.gd",
		"res://algorithms/vectors/noc_ch01/exercise_1_8_solution_attraction_magnitude_vr.gd"
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
		print("✅ All Ch 01 scripts passed basic validation!")
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

	var has_vrentity = source_code.contains("VREntity") or source_code.contains("extends Node3D")
	var has_mover = source_code.contains("Mover") or source_code.contains("Ball")

	print("  ✓ Script loads successfully")
	if has_vrentity:
		print("  ✓ Has VREntity/Node3D reference")
	if has_mover:
		print("  ✓ Has motion entity (Mover/Ball)")

	return true
