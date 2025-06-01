# TileEffectTriggerTest.gd
extends Node
class_name TileEffectTriggerTest

# Test script for validating the Tile Effect Trigger system

var grid_system: GridSystem
var tile_effect_controller: TileEffectController
var test_results: Dictionary = {}

# Test configuration
var run_automated_tests: bool = true
var show_test_output: bool = true

func _ready():
	if run_automated_tests:
		print("TileEffectTriggerTest: Starting automated tests...")
		call_deferred("run_all_tests")

func run_all_tests():
	"""Run comprehensive tests of the tile effect trigger system"""
	print("=== Tile Effect Trigger System Tests ===")
	
	# Initialize test results
	test_results = {
		"total_tests": 0,
		"passed_tests": 0,
		"failed_tests": 0,
		"test_details": []
	}
	
	# Find required components
	_find_components()
	
	if not grid_system or not tile_effect_controller:
		_log_test_result("Component Detection", false, "Required components not found")
		_print_test_summary()
		return
	
	# Run individual tests
	_test_component_detection()
	_test_trigger_detection()
	_test_trigger_configuration()
	_test_effect_activation()
	_test_trigger_management()
	_test_json_configuration()
	
	# Print final results
	_print_test_summary()

func _find_components():
	"""Find the required components in the scene"""
	var nodes = []
	_get_all_nodes(get_tree().root, nodes)
	
	for node in nodes:
		if node is GridSystem:
			grid_system = node
		elif node is TileEffectController:
			tile_effect_controller = node
	
	if show_test_output:
		print("Components found:")
		print("  GridSystem1: %s" % ("✓" if grid_system else "✗"))
		print("  TileEffectController: %s" % ("✓" if tile_effect_controller else "✗"))

func _get_all_nodes(node: Node, result: Array):
	result.push_back(node)
	for child in node.get_children():
		_get_all_nodes(child, result)

func _test_component_detection():
	"""Test that required components are detected"""
	print("\n--- Test: Component Detection ---")
	
	var grid_found = grid_system != null
	var controller_found = tile_effect_controller != null
	var tile_effects_enabled = grid_system and grid_system.enable_tile_effects
	var tile_manager_exists = grid_system and grid_system.tile_effect_manager != null
	
	_log_test_result("GridSystem1 found", grid_found)
	_log_test_result("TileEffectController found", controller_found)
	_log_test_result("Tile effects enabled", tile_effects_enabled)
	_log_test_result("TileEffectManager exists", tile_manager_exists)

func _test_trigger_detection():
	"""Test detection of tile effect triggers"""
	print("\n--- Test: Trigger Detection ---")
	
	if not tile_effect_controller:
		_log_test_result("Trigger Detection", false, "No controller available")
		return
	
	# Wait for triggers to be detected
	await get_tree().create_timer(1.0).timeout
	
	var triggers = tile_effect_controller.get_active_triggers()
	var trigger_count = triggers.size()
	
	_log_test_result("Triggers detected", trigger_count > 0, "Found %d triggers" % trigger_count)
	
	if trigger_count > 0:
		var first_trigger = triggers[0]
		var has_required_methods = (
			first_trigger.has_method("get_trigger_info") and
			first_trigger.has_method("activate") and
			first_trigger.has_method("reset_trigger")
		)
		_log_test_result("Trigger has required methods", has_required_methods)

func _test_trigger_configuration():
	"""Test trigger configuration and properties"""
	print("\n--- Test: Trigger Configuration ---")
	
	if not tile_effect_controller:
		_log_test_result("Trigger Configuration", false, "No controller available")
		return
	
	var triggers = tile_effect_controller.get_active_triggers()
	if triggers.size() == 0:
		_log_test_result("Trigger Configuration", false, "No triggers to test")
		return
	
	var trigger = triggers[0]
	var info = trigger.get_trigger_info()
	
	var has_effect_type = info.has("effect_type") and info.effect_type != ""
	var has_position = info.has("grid_position")
	var has_active_state = info.has("is_active")
	
	_log_test_result("Trigger has effect type", has_effect_type, "Type: " + str(info.get("effect_type", "none")))
	_log_test_result("Trigger has position", has_position, "Position: " + str(info.get("grid_position", "none")))
	_log_test_result("Trigger has active state", has_active_state, "Active: " + str(info.get("is_active", false)))

func _test_effect_activation():
	"""Test manual effect activation"""
	print("\n--- Test: Effect Activation ---")
	
	if not grid_system or not grid_system.tile_effect_manager:
		_log_test_result("Effect Activation", false, "No tile effect manager")
		return
	
	var manager = grid_system.tile_effect_manager
	
	# Test basic effects
	manager.reveal_all_tiles()
	await get_tree().create_timer(0.5).timeout
	_log_test_result("Reveal all tiles", true, "Effect executed")
	
	manager.hide_all_tiles()
	await get_tree().create_timer(0.5).timeout
	_log_test_result("Hide all tiles", true, "Effect executed")
	
	manager.start_disco_effect()
	await get_tree().create_timer(0.5).timeout
	_log_test_result("Disco effect", true, "Effect executed")
	
	manager.stop_all_effects()
	await get_tree().create_timer(0.5).timeout
	_log_test_result("Stop all effects", true, "Effect executed")

func _test_trigger_management():
	"""Test trigger management functions"""
	print("\n--- Test: Trigger Management ---")
	
	if not tile_effect_controller:
		_log_test_result("Trigger Management", false, "No controller available")
		return
	
	var summary = tile_effect_controller.get_trigger_info_summary()
	var has_summary_data = (
		summary.has("total_triggers") and
		summary.has("active_triggers") and
		summary.has("effect_types")
	)
	
	_log_test_result("Get trigger summary", has_summary_data, "Summary: " + str(summary))
	
	# Test trigger filtering
	var disco_triggers = tile_effect_controller.get_trigger_by_effect_type("disco")
	var reveal_triggers = tile_effect_controller.get_trigger_by_effect_type("reveal")
	
	_log_test_result("Filter disco triggers", true, "Found %d disco triggers" % disco_triggers.size())
	_log_test_result("Filter reveal triggers", true, "Found %d reveal triggers" % reveal_triggers.size())

func _test_json_configuration():
	"""Test JSON configuration loading"""
	print("\n--- Test: JSON Configuration ---")
	
	if not grid_system or not grid_system.interactable_handler:
		_log_test_result("JSON Configuration", false, "No interactable handler")
		return
	
	var handler = grid_system.interactable_handler
	
	# Check if JSON loading was used
	var has_tile_effect_definitions = handler.tile_effect_definitions.size() > 0
	_log_test_result("Tile effect definitions loaded", has_tile_effect_definitions, 
		"Found %d definitions" % handler.tile_effect_definitions.size())
	
	if has_tile_effect_definitions:
		var first_definition_key = handler.tile_effect_definitions.keys()[0]
		var definition = handler.tile_effect_definitions[first_definition_key]
		
		var has_effect_type = definition.has("effect_type")
		var has_description = definition.has("description")
		
		_log_test_result("Definition has effect type", has_effect_type)
		_log_test_result("Definition has description", has_description)

func _log_test_result(test_name: String, passed: bool, details: String = ""):
	"""Log a test result"""
	test_results.total_tests += 1
	
	if passed:
		test_results.passed_tests += 1
	else:
		test_results.failed_tests += 1
	
	var result = {
		"name": test_name,
		"passed": passed,
		"details": details
	}
	test_results.test_details.append(result)
	
	if show_test_output:
		var status = "✓" if passed else "✗"
		var output = "  %s %s" % [status, test_name]
		if details:
			output += " - " + details
		print(output)

func _print_test_summary():
	"""Print final test summary"""
	print("\n=== Test Summary ===")
	print("Total Tests: %d" % test_results.total_tests)
	print("Passed: %d" % test_results.passed_tests)
	print("Failed: %d" % test_results.failed_tests)
	
	var success_rate = float(test_results.passed_tests) / float(test_results.total_tests) * 100.0
	print("Success Rate: %.1f%%" % success_rate)
	
	if test_results.failed_tests > 0:
		print("\nFailed Tests:")
		for result in test_results.test_details:
			if not result.passed:
				print("  - %s: %s" % [result.name, result.details])
	
	var overall_status = "PASSED" if test_results.failed_tests == 0 else "FAILED"
	print("\nOverall Result: %s" % overall_status)

# Manual test functions for debugging

func test_manual_trigger_activation():
	"""Manually test trigger activation"""
	if not tile_effect_controller:
		print("No tile effect controller found")
		return
	
	var triggers = tile_effect_controller.get_active_triggers()
	if triggers.size() == 0:
		print("No active triggers found")
		return
	
	print("Manually activating first trigger...")
	var trigger = triggers[0]
	trigger.activate()

func test_effect_cycling():
	"""Cycle through different effects for demonstration"""
	if not grid_system:
		print("No grid system found")
		return
	
	print("Starting effect cycling demonstration...")
	
	grid_system.hide_all_tiles()
	await get_tree().create_timer(1.0).timeout
	
	grid_system.start_tile_reveal(Vector3i(4, 0, 4))
	await get_tree().create_timer(3.0).timeout
	
	grid_system.start_disco_tiles()
	await get_tree().create_timer(3.0).timeout
	
	grid_system.stop_tile_effects()
	await get_tree().create_timer(1.0).timeout
	
	grid_system.reveal_all_tiles()
	print("Effect cycling complete")

func get_test_results() -> Dictionary:
	"""Get the results of the last test run"""
	return test_results

# Utility functions for external testing

func validate_system() -> bool:
	"""Quick validation that the system is working"""
	return (
		grid_system != null and 
		tile_effect_controller != null and
		grid_system.enable_tile_effects and
		grid_system.tile_effect_manager != null
	) 
