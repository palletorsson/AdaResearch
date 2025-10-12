extends SceneTree

## Simple test runner for Ch 11 scripts
## Run with: godot --headless -s test_ch11_scripts.gd --quit

func _init():
	print("=== Testing Ch 11 Neuroevolution Scripts ===")

	var scripts_to_test = [
		"res://algorithms/neuroevolution/noc_ch11/example_11_1_flappy_bird_vr.gd",
		"res://algorithms/neuroevolution/noc_ch11/example_11_2_flappy_bird_neuroevolution_vr.gd",
		"res://algorithms/neuroevolution/noc_ch11/example_11_3_smart_rockets_neuroevolution_vr.gd",
		"res://algorithms/neuroevolution/noc_ch11/example_11_4_neuroevolution_steering_seek_vr.gd",
		"res://algorithms/neuroevolution/noc_ch11/example_11_5_creature_sensors_vr.gd",
		"res://algorithms/neuroevolution/noc_ch11/example_11_6_neuroevolution_ecosystem_vr.gd"
	]

	var all_passed = true

	for script_path in scripts_to_test:
		var result = test_script(script_path)
		if not result:
			all_passed = false

	if all_passed:
		print("\n✅ All Ch 11 scripts passed basic validation!")
	else:
		print("\n❌ Some scripts have errors - see above")

	quit()

func test_script(path: String) -> bool:
	print("\n--- Testing: " + path + " ---")

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
	var has_vrentity = source_code.contains("VREntity")
	var has_neural_network = source_code.contains("NeuralNetwork")

	print("  ✓ Script loads successfully")
	print("  ✓ Has VREntity reference: " + str(has_vrentity))
	print("  ✓ Has NeuralNetwork reference: " + str(has_neural_network))

	return true
