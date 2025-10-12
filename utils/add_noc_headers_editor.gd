@tool
extends EditorScript

# ===========================================================================
# NOC Header Addition Tool (Editor Version)
# Run this from: File > Run in Godot Editor
# ===========================================================================

# Example number to title mapping
var example_titles = {
	# Chapter 1 - Vectors
	"example_1_1_bouncing_ball_with_no_vectors_vr": "Bouncing Ball with No Vectors",
	"example_1_2_bouncing_ball_with_vectors_vr": "Bouncing Ball with Vectors",
	"example_1_3_vector_subtraction_vr": "Vector Subtraction",
	"example_1_4_vector_multiplication_vr": "Vector Multiplication",
	"example_1_5_vector_magnitude_vr": "Vector Magnitude",
	"example_1_6_vector_normalize_vr": "Vector Normalize",
	"example_1_7_motion_101_velocity_vr": "Motion 101: Velocity",
	"example_1_8_motion_101_velocity_and_constant_acceleration_vr": "Motion 101: Velocity and Constant Acceleration",
	"example_1_9_motion_101_velocity_and_random_acceleration_vr": "Motion 101: Velocity and Random Acceleration",
	"example_1_10_accelerating_towards_the_mouse_vr": "Accelerating Towards the Mouse",

	# Chapter 1 - Exercises
	"exercise_1_3_solution_3_d_bouncing_ball_vr": "Exercise 1.3: 3D Bouncing Ball",
	"exercise_1_5_solution_accelerate_and_decelerate_vr": "Exercise 1.5: Accelerate and Decelerate",
	"exercise_1_8_solution_attraction_magnitude_vr": "Exercise 1.8: Attraction Magnitude",

	# Chapter 2 - Forces
	"example_2_1_forces_vr": "Forces",
	"example_2_2_forces_mass_variation_vr": "Forces: Mass Variation",
	"example_2_3_gravity_scaled_by_mass_vr": "Gravity Scaled by Mass",
	"example_2_4_friction_vr": "Friction",
	"example_2_5_fluid_resistance_vr": "Fluid Resistance",
	"example_2_6_single_attractor_vr": "Single Attractor",
	"example_2_7_multiple_attractors_vr": "Multiple Attractors",
	"example_2_8_two_body_attraction_vr": "Two-Body Attraction",
	"example_2_9_n_body_attraction_vr": "N-Body Attraction",

	# Chapter 3 - Oscillation
	"example_3_1_angular_motion_using_rotate_vr": "Angular Motion Using Rotate",
	"example_3_2_forces_with_arbitrary_angular_motion_vr": "Forces with Arbitrary Angular Motion",
	"example_3_3_pointing_in_the_direction_of_motion_vr": "Pointing in the Direction of Motion",
	"example_3_4_polar_to_cartesian_vr": "Polar to Cartesian",
	"example_3_5_simple_harmonic_motion_vr": "Simple Harmonic Motion",
	"example_3_6_simple_harmonic_motion_ii_vr": "Simple Harmonic Motion II",
	"example_3_7_oscillator_objects_vr": "Oscillator Objects",
	"example_3_8_static_wave_vr": "Static Wave",
	"example_3_9_the_wave_vr": "The Wave",
	"example_3_10_swinging_pendulum_vr": "Swinging Pendulum",
	"example_3_11_a_spring_connection_vr": "A Spring Connection",

	# Chapter 4 - Particles
	"example_4_1_single_particle_vr": "Single Particle",
	"example_4_2_array_particles_vr": "Array of Particles",
	"example_4_3_particle_emitter_vr": "Particle Emitter",
	"example_4_4_multiple_emitters_vr": "Multiple Emitters",
	"example_4_5_inheritance_polymorphism_vr": "Inheritance and Polymorphism",
	"example_4_6_particle_repeller_vr": "Particle Repeller",

	# Chapter 5 - Steering
	"noc_5_01_seek_vr": "Seek",
	"noc_5_02_arrive_vr": "Arrive",
	"noc_5_03_stay_within_walls_vr": "Stay Within Walls",
	"noc_5_04_flow_field_vr": "Flow Field",
	"noc_5_05_path_following_simple_vr": "Path Following (Simple)",
	"noc_5_07_separation_vr": "Separation",
	"noc_5_08_separation_and_seek_vr": "Separation and Seek",
	"noc_5_08_path_following_vr": "Path Following",
	"example_5_9_flocking_vr": "Flocking",
	"example_5_9_flocking_with_binning_vr": "Flocking with Binning",
	"example_5_12_sine_cosine_lookup_table_vr": "Sine/Cosine Lookup Table",

	# Chapter 6 - Physics
	"example_6_1_basic_rigidbody_vr": "Basic RigidBody",
	"example_6_2_falling_boxes_vr": "Falling Boxes",
	"example_6_3_compound_bodies_vr": "Compound Bodies",
	"example_6_4_windmill_vr": "Windmill",
	"example_6_5_chain_vr": "Chain",
	"example_6_6_grab_vr": "Grab",
	"example_6_7_bridge_vr": "Bridge",
	"example_6_8_collision_layers_vr": "Collision Layers",

	# Chapter 8 - Fractals
	"example_8_1_recursion_vr": "Recursion",
	"example_8_2_recursion_vr": "Recursion (Variant)",
	"example_8_3_recursion_circles_vr": "Recursion: Circles",
	"example_8_4_cantor_set_vr": "Cantor Set",
	"example_8_5_koch_curve_vr": "Koch Curve",
	"example_8_6_recursive_tree_vr": "Recursive Tree",
	"example_8_7_stochastic_tree_vr": "Stochastic Tree",
	"example_8_8_lsystem_string_only_vr": "L-System (String Only)",
	"example_8_9_lsystem_tree_vr": "L-System Tree",

	# Chapter 11 - Neuroevolution
	"example_11_1_flappy_bird_vr": "Flappy Bird",
	"example_11_2_flappy_bird_neuroevolution_vr": "Flappy Bird Neuroevolution",
	"example_11_3_smart_rockets_neuroevolution_vr": "Smart Rockets Neuroevolution",
	"example_11_4_neuroevolution_steering_seek_vr": "Neuroevolution Steering: Seek",
	"example_11_5_creature_sensors_vr": "Creature Sensors",
	"example_11_6_neuroevolution_ecosystem_vr": "Neuroevolution Ecosystem",

	# Special cases
	"example_0_1_random_walk": "Random Walk",
	"example_custom_tileset": "Custom Tileset (WFC)",
}

func _run():
	print("=== NOC Header Addition Tool ===")
	print("Starting batch processing...")
	add_headers_to_all_files()
	print("\n=== Complete! ===")

func add_headers_to_all_files():
	var files_to_process = [
		# Chapter 1 - Vectors
		"algorithms/vectors/noc_ch01/example_1_1_bouncing_ball_with_no_vectors_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_2_bouncing_ball_with_vectors_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_3_vector_subtraction_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_4_vector_multiplication_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_5_vector_magnitude_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_6_vector_normalize_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_7_motion_101_velocity_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_8_motion_101_velocity_and_constant_acceleration_vr.gd",
		"algorithms/vectors/noc_ch01/example_1_9_motion_101_velocity_and_random_acceleration_vr.gd",
		"algorithms/vectors/noc_ch01/exercise_1_3_solution_3_d_bouncing_ball_vr.gd",
		"algorithms/vectors/noc_ch01/exercise_1_5_solution_accelerate_and_decelerate_vr.gd",
		"algorithms/vectors/noc_ch01/exercise_1_8_solution_attraction_magnitude_vr.gd",

		# Chapter 2 - Forces
		"algorithms/forces/example_2_1_forces_vr.gd",
		"algorithms/forces/example_2_2_forces_mass_variation_vr.gd",
		"algorithms/forces/example_2_3_gravity_scaled_by_mass_vr.gd",
		"algorithms/forces/example_2_4_friction_vr.gd",
		"algorithms/forces/example_2_5_fluid_resistance_vr.gd",
		"algorithms/forces/example_2_6_single_attractor_vr.gd",
		"algorithms/forces/example_2_7_multiple_attractors_vr.gd",
		"algorithms/forces/example_2_8_two_body_attraction_vr.gd",
		"algorithms/forces/example_2_9_n_body_attraction_vr.gd",

		# Chapter 3 - Oscillation
		"algorithms/oscillation/noc_ch03/example_1_10_accelerating_towards_the_mouse_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_1_angular_motion_using_rotate_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_2_forces_with_arbitrary_angular_motion_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_3_pointing_in_the_direction_of_motion_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_4_polar_to_cartesian_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_5_simple_harmonic_motion_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_6_simple_harmonic_motion_ii_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_7_oscillator_objects_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_8_static_wave_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_9_the_wave_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_10_swinging_pendulum_vr.gd",
		"algorithms/oscillation/noc_ch03/example_3_11_a_spring_connection_vr.gd",

		# Chapter 4 - Particles
		"algorithms/particles/example_4_1_single_particle_vr.gd",
		"algorithms/particles/example_4_2_array_particles_vr.gd",
		"algorithms/particles/example_4_3_particle_emitter_vr.gd",
		"algorithms/particles/example_4_4_multiple_emitters_vr.gd",
		"algorithms/particles/example_4_5_inheritance_polymorphism_vr.gd",
		"algorithms/particles/example_4_6_particle_repeller_vr.gd",

		# Chapter 5 - Steering
		"algorithms/steering/noc_ch05/noc_5_01_seek_vr.gd",
		"algorithms/steering/noc_ch05/noc_5_02_arrive_vr.gd",
		"algorithms/steering/noc_ch05/noc_5_03_stay_within_walls_vr.gd",
		"algorithms/steering/noc_ch05/noc_5_04_flow_field_vr.gd",
		"algorithms/steering/noc_ch05/noc_5_05_path_following_simple_vr.gd",
		"algorithms/steering/noc_ch05/noc_5_07_separation_vr.gd",
		"algorithms/steering/noc_ch05/noc_5_08_separation_and_seek_vr.gd",
		"algorithms/steering/noc_ch05/noc_5_08_path_following_vr.gd",
		"algorithms/steering/noc_ch05/example_5_9_flocking_vr.gd",
		"algorithms/steering/noc_ch05/example_5_9_flocking_with_binning_vr.gd",
		"algorithms/steering/noc_ch05/example_5_12_sine_cosine_lookup_table_vr.gd",

		# Chapter 6 - Physics
		"algorithms/physics/example_6_1_basic_rigidbody_vr.gd",
		"algorithms/physics/example_6_2_falling_boxes_vr.gd",
		"algorithms/physics/example_6_3_compound_bodies_vr.gd",
		"algorithms/physics/example_6_4_windmill_vr.gd",
		"algorithms/physics/example_6_5_chain_vr.gd",
		"algorithms/physics/example_6_6_grab_vr.gd",
		"algorithms/physics/example_6_7_bridge_vr.gd",
		"algorithms/physics/example_6_8_collision_layers_vr.gd",

		# Chapter 8 - Fractals
		"algorithms/fractals/example_8_1_recursion_vr.gd",
		"algorithms/fractals/example_8_2_recursion_vr.gd",
		"algorithms/fractals/example_8_3_recursion_circles_vr.gd",
		"algorithms/fractals/example_8_4_cantor_set_vr.gd",
		"algorithms/fractals/example_8_5_koch_curve_vr.gd",
		"algorithms/fractals/example_8_6_recursive_tree_vr.gd",
		"algorithms/fractals/example_8_7_stochastic_tree_vr.gd",
		"algorithms/fractals/example_8_8_lsystem_string_only_vr.gd",
		"algorithms/fractals/example_8_9_lsystem_tree_vr.gd",

		# Chapter 11 - Neuroevolution
		"algorithms/neuroevolution/noc_ch11/example_11_1_flappy_bird_vr.gd",
		"algorithms/neuroevolution/noc_ch11/example_11_2_flappy_bird_neuroevolution_vr.gd",
		"algorithms/neuroevolution/noc_ch11/example_11_3_smart_rockets_neuroevolution_vr.gd",
		"algorithms/neuroevolution/noc_ch11/example_11_4_neuroevolution_steering_seek_vr.gd",
		"algorithms/neuroevolution/noc_ch11/example_11_5_creature_sensors_vr.gd",
		"algorithms/neuroevolution/noc_ch11/example_11_6_neuroevolution_ecosystem_vr.gd",

		# Other examples
		"algorithms/randomness/example_0_1_random_walk.gd",
		"algorithms/wfc/example_custom_tileset.gd",
	]

	var processed_count = 0
	var skipped_count = 0

	for file_path in files_to_process:
		var full_path = "res://" + file_path

		if process_file(full_path):
			processed_count += 1
			print("  ✓ Processed: %s" % file_path)
		else:
			skipped_count += 1
			print("  ⚠ Skipped: %s (already has header or not found)" % file_path)

	print("\n=== Summary ===")
	print("Processed: %d files" % processed_count)
	print("Skipped: %d files" % skipped_count)
	print("Total: %d files" % files_to_process.size())

func process_file(file_path: String) -> bool:
	# Check if file exists
	if not FileAccess.file_exists(file_path):
		return false

	# Read the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false

	var content = file.get_as_text()
	file.close()

	# Check if it already has a NOC header
	if content.begins_with("# ========"):
		# Already has a header, skip
		return false

	# Extract filename to get example number
	var filename = file_path.get_file().get_basename()

	# Get the title
	var title = example_titles.get(filename, "Unknown Example")

	# Extract example number from filename
	var example_num = extract_example_number(filename)

	# Create the header
	var header = create_header(example_num, title)

	# Add header to content
	var new_content = header + content

	# Write back to file
	file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false

	file.store_string(new_content)
	file.close()

	return true

func extract_example_number(filename: String) -> String:
	# Extract number from patterns like "example_1_2_..." or "noc_5_01_..."
	var regex = RegEx.new()
	regex.compile("(?:example|noc|exercise)_([0-9]+)_([0-9]+)")
	var result = regex.search(filename)

	if result:
		var chapter = result.get_string(1)
		var example = result.get_string(2)
		return chapter + "." + example

	return ""

func create_header(example_num: String, title: String) -> String:
	var header = "# ===========================================================================\n"

	if example_num.is_empty():
		header += "# NOC Example: " + title + "\n"
	else:
		header += "# NOC Example " + example_num + ": " + title + "\n"

	header += "# Original: Daniel Shiffman (Processing) - https://natureofcode.com\n"
	header += "# Translation: AI-assisted Processing → GDScript, 2025\n"
	header += "#\n"
	header += "# This is a translation adapted for VR where the original algorithm and logic are maintained.\n"
	header += "# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)\n"
	header += "# ===========================================================================\n\n"

	return header
