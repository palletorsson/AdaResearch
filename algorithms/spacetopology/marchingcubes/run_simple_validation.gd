# run_simple_validation.gd
# Simple script to run marching cubes validation

extends SceneTree

func _init():
	# Load and run validation
	print("Loading validation script...")
	
	var validator_script = load("res://algorithms/spacetopology/marchingcubes/validate_user_fixed_simple.gd")
	var validator_class = validator_script as GDScript
	
	print("Running validation tests...")
	var results = validator_class.run_validation()
	
	print("\nValidation completed!")
	print("Final Results:")
	print("- Passed: " + str(results.tests_passed))
	print("- Failed: " + str(results.tests_failed))
	print("- Total: " + str(results.total_tests))
	
	var exit_code = 0 if results.tests_failed == 0 else 1
	quit(exit_code) 