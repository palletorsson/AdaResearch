extends SceneTree

## Test runner for Ch 03 Oscillation scripts
## Run with: godot --headless -s test_ch03_scripts.gd --quit

func _init():
	print("=== Testing Ch 03 Oscillation Scripts ===")

	var scripts_to_test = [
		"res://algorithms/oscillation/noc_ch03/example_1_10_accelerating_towards_the_mouse_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_1_angular_motion_using_rotate_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_10_swinging_pendulum_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_11_a_spring_connection_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_2_forces_with_arbitrary_angular_motion_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_3_pointing_in_the_direction_of_motion_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_4_polar_to_cartesian_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_5_simple_harmonic_motion_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_6_simple_harmonic_motion_ii_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_7_oscillator_objects_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_8_static_wave_vr.gd",
		"res://algorithms/oscillation/noc_ch03/example_3_9_the_wave_vr.gd",
		"res://algorithms/oscillation/noc_ch03/exercise_3_1_baton_vr.gd",
		"res://algorithms/oscillation/noc_ch03/exercise_3_11_oop_wave_vr.gd",
		"res://algorithms/oscillation/noc_ch03/exercise_3_12_additive_wave_vr.gd",
		"res://algorithms/oscillation/noc_ch03/exercise_3_15_double_pendulum_vr.gd",
		"res://algorithms/oscillation/noc_ch03/exercise_3_5_spiral_vr.gd",
		"res://algorithms/oscillation/noc_ch03/exercise_3_6_asteroids_vr.gd"
	]

	var all_passed = true
	var error_count = 0
	var warning_count = 0

	for script_path in scripts_to_test:
		var result = test_script(script_path)
		if not result:
			all_passed = false
			error_count += 1

	print("\n" + "=".repeat(60))
	print("SUMMARY: Tested " + str(scripts_to_test.size()) + " scripts")
	if all_passed:
		print("✅ All Ch 03 scripts passed basic validation!")
	else:
		print("❌ " + str(error_count) + " script(s) have errors - see above")
	print("=".repeat(60))

	quit()

func test_script(path: String) -> bool:
	print("\n--- Testing: " + path.get_file() + " ---")

	# Check if file exists
	if not FileAccess.file_exists(path):
		print("  ❌ ERROR: File does not exist")
		return false

	# Try to load the script
	var script = load(path)
	if script == null:
		print("  ❌ ERROR: Failed to load script")
		return false

	# Check if it's a valid GDScript
	if not script is GDScript:
		print("  ❌ ERROR: Not a valid GDScript")
		return false

	# Try to parse it
	var source_code = script.source_code
	if source_code == null or source_code == "":
		print("  ❌ ERROR: Script has no source code")
		return false

	# Check for class dependencies
	var has_vrentity = source_code.contains("VREntity") or source_code.contains("extends Node3D")
	var has_mover = source_code.contains("Mover")
	var has_oscillator = source_code.contains("Oscillator")
	var has_pendulum = source_code.contains("Pendulum")
	var has_spring = source_code.contains("Spring")

	print("  ✓ Script loads successfully")
	if has_vrentity:
		print("  ✓ Has VREntity/Node3D reference")
	if has_mover:
		print("  ✓ Has Mover class")
	if has_oscillator:
		print("  ✓ Has Oscillator class")
	if has_pendulum:
		print("  ✓ Has Pendulum class")
	if has_spring:
		print("  ✓ Has Spring class")

	return true
