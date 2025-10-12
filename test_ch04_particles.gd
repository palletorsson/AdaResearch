extends SceneTree

## Test runner for Ch 04 Particles scripts
## Run with: godot --headless -s test_ch04_particles.gd --quit

func _init():
	print("=== Testing Ch 04 Particles Scripts ===")

	var scripts_to_test = [
		"res://algorithms/particles/example_4_1_single_particle_vr.gd",
		"res://algorithms/particles/example_4_2_array_particles_vr.gd",
		"res://algorithms/particles/example_4_3_particle_emitter_vr.gd",
		"res://algorithms/particles/example_4_4_multiple_emitters_vr.gd",
		"res://algorithms/particles/example_4_5_inheritance_polymorphism_vr.gd",
		"res://algorithms/particles/example_4_6_particle_repeller_vr.gd"
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
		print("✅ All Ch 04 Particles scripts passed basic validation!")
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
	var has_particle = source_code.contains("Particle") or source_code.contains("particle")

	print("  ✓ Script loads successfully")
	if has_node3d:
		print("  ✓ Extends Node3D")
	if has_particle:
		print("  ✓ Has particle system references")

	return true
