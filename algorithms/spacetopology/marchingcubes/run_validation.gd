#!/usr/bin/env -S godot --headless --script
# run_validation.gd
# Test runner for marching cubes validation

extends SceneTree

func _ready():
	print("🚀 STARTING MARCHING CUBES VALIDATION...")
	print("")
	
	# Load the validator
	var validator_script = load("res://algorithms/spacetopology/marchingcubes/validate_user_fixed.gd")
	
	# Run validation
	var results = validator_script.run_validation()
	
	print("")
	print("🏁 VALIDATION COMPLETE!")
	
	# Summary
	var success_rate = 0.0
	if results.total_tests > 0:
		success_rate = (results.tests_passed * 100.0) / results.total_tests
	
	print("📈 Success Rate: %.1f%% (%d/%d tests passed)" % [success_rate, results.tests_passed, results.total_tests])
	
	if results.tests_failed == 0:
		print("🎉 ALL TESTS PASSED! The marching cubes implementation is working correctly.")
	else:
		print("⚠️  Some tests failed. Review the issues above.")
	
	# Exit with appropriate code
	var exit_code = 0 if results.tests_failed == 0 else 1
	quit(exit_code) 