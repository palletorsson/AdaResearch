extends SceneTree

## Test runner for all remaining NOC chapters
## Run with: godot --headless -s test_all_remaining_chapters.gd --quit

func _init():
	print("=== Testing All Remaining NOC Chapters ===\n")

	var chapters = {
		"Ch 05 Steering": [
			"res://algorithms/steering/noc_ch05/example_5_12_sine_cosine_lookup_table_vr.gd",
			"res://algorithms/steering/noc_ch05/example_5_9_flocking_vr.gd",
			"res://algorithms/steering/noc_ch05/example_5_9_flocking_with_binning_vr.gd",
			"res://algorithms/steering/noc_ch05/exercise_5_13_crowd_path_following_vr.gd",
			"res://algorithms/steering/noc_ch05/exercise_5_2_vr.gd",
			"res://algorithms/steering/noc_ch05/exercise_5_4_wander_vr.gd",
			"res://algorithms/steering/noc_ch05/exercise_5_9_angle_between_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_01_seek_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_02_arrive_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_03_stay_within_walls_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_04_flow_field_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_05_path_following_simple_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_07_separation_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_08_path_following_vr.gd",
			"res://algorithms/steering/noc_ch05/noc_5_08_separation_and_seek_vr.gd"
		],
		"Ch 07 Cellular Automata": [
			"res://algorithms/cellularautomata/noc_ch07/7_1_elementary_ca_vr.gd",
			"res://algorithms/cellularautomata/noc_ch07/7_2_game_of_life_vr.gd",
			"res://algorithms/cellularautomata/noc_ch07/7_3_game_of_life_oop_vr.gd",
			"res://algorithms/cellularautomata/noc_ch07/7_8_hexagon_ca_vr.gd"
		],
		"Ch 09 Genetic Algorithms": [
			"res://algorithms/machinelearning/noc_ch09/9_1_ga_shakespeare_vr.gd",
			"res://algorithms/machinelearning/noc_ch09/9_2_smart_rockets_basic_vr.gd",
			"res://algorithms/machinelearning/noc_ch09/9_3_smart_rockets_vr.gd",
			"res://algorithms/machinelearning/noc_ch09/9_4_interactive_selection_vr.gd",
			"res://algorithms/machinelearning/noc_ch09/9_5_evolving_bloops_vr.gd",
			"res://algorithms/machinelearning/noc_ch09/9_6_ga_shakespeare_annotated_vr.gd"
		]
	}

	var total_tested = 0
	var total_errors = 0

	for chapter_name in chapters:
		print("\n" + "=".repeat(60))
		print("TESTING: " + chapter_name)
		print("=".repeat(60))

		var scripts = chapters[chapter_name]
		var chapter_errors = 0

		for script_path in scripts:
			var result = test_script(script_path)
			if not result:
				chapter_errors += 1
				total_errors += 1
			total_tested += 1

		if chapter_errors == 0:
			print("\n✅ " + chapter_name + ": All " + str(scripts.size()) + " scripts passed!")
		else:
			print("\n❌ " + chapter_name + ": " + str(chapter_errors) + " script(s) failed")

	print("\n" + "=".repeat(60))
	print("FINAL SUMMARY")
	print("=".repeat(60))
	print("Total scripts tested: " + str(total_tested))
	if total_errors == 0:
		print("✅ ALL SCRIPTS PASSED!")
	else:
		print("❌ " + str(total_errors) + " script(s) have errors")
	print("=".repeat(60))

	quit()

func test_script(path: String) -> bool:
	print("\n  Testing: " + path.get_file())

	if not FileAccess.file_exists(path):
		print("    ❌ File does not exist")
		return false

	var script = load(path)
	if script == null:
		print("    ❌ Failed to load script")
		return false

	if not script is GDScript:
		print("    ❌ Not a valid GDScript")
		return false

	var source_code = script.source_code
	if source_code == null or source_code == "":
		print("    ❌ Script has no source code")
		return false

	print("    ✓ PASS")
	return true
