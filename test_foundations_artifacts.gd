extends Node3D
## Test script for Foundations artifacts
## Run this scene to validate all Gamwell×QFEP artifacts

var test_results: Array[String] = []
var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("\n" + "="*60)
	print("FOUNDATIONS ARTIFACTS TEST")
	print("="*60 + "\n")
	
	# Add camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 1, 4)
	add_child(camera)
	
	# Run tests
	test_godel_statement_plaque()
	test_russell_set_box()
	test_magritte_pipe()
	test_escher_staircase()
	test_florensky_sphere()
	test_bifurcation_diagram()
	
	# Summary
	print("\n" + "="*60)
	print("RESULTS: %d passed, %d failed" % [tests_passed, tests_failed])
	print("="*60)
	
	for result in test_results:
		print(result)
	
	# Auto-quit after tests
	await get_tree().create_timer(2.0).timeout
	get_tree().quit(0 if tests_failed == 0 else 1)

func test_godel_statement_plaque() -> void:
	print("\n[TEST] GodelStatementPlaque...")
	
	var scene = load("res://commons/interfaces/foundations/godel_statement_plaque.tscn")
	if not scene:
		_fail("GodelStatementPlaque", "Scene failed to load")
		return
	
	var instance = scene.instantiate()
	add_child(instance)
	
	# Check it has the expected properties
	if not instance.has_method("advance_statement"):
		_fail("GodelStatementPlaque", "Missing advance_statement() method")
		return
	
	if not instance.has_signal("paradox_triggered"):
		_fail("GodelStatementPlaque", "Missing paradox_triggered signal")
		return
	
	# Test cycling through statements
	var initial_index = instance.current_index
	instance.advance_statement()
	if instance.current_index != initial_index + 1:
		_fail("GodelStatementPlaque", "advance_statement() didn't increment index")
		return
	
	_pass("GodelStatementPlaque", "All checks passed")
	instance.queue_free()

func test_russell_set_box() -> void:
	print("\n[TEST] RussellSetBox...")
	
	var scene = load("res://commons/interfaces/foundations/russell_set_box.tscn")
	if not scene:
		_fail("RussellSetBox", "Scene failed to load")
		return
	
	var instance = scene.instantiate()
	add_child(instance)
	
	if not instance.has_method("open_next_layer"):
		_fail("RussellSetBox", "Missing open_next_layer() method")
		return
	
	if not instance.has_signal("infinite_regress_detected"):
		_fail("RussellSetBox", "Missing infinite_regress_detected signal")
		return
	
	# Test opening layers
	var initial_depth = instance._current_depth
	instance.open_next_layer()
	if instance._current_depth != initial_depth + 1:
		_fail("RussellSetBox", "open_next_layer() didn't increment depth")
		return
	
	_pass("RussellSetBox", "All checks passed")
	instance.queue_free()

func test_magritte_pipe() -> void:
	print("\n[TEST] MagrittePipe...")
	
	var scene = load("res://commons/interfaces/foundations/magritte_pipe.tscn")
	if not scene:
		_fail("MagrittePipe", "Scene failed to load")
		return
	
	var instance = scene.instantiate()
	add_child(instance)
	
	if not instance.has_method("advance_layer"):
		_fail("MagrittePipe", "Missing advance_layer() method")
		return
	
	if instance.layers.size() < 5:
		_fail("MagrittePipe", "Expected at least 5 representation layers")
		return
	
	# Check first layer text
	if not instance.layers[0].contains("pipe"):
		_fail("MagrittePipe", "First layer should mention 'pipe'")
		return
	
	_pass("MagrittePipe", "All checks passed")
	instance.queue_free()

func test_escher_staircase() -> void:
	print("\n[TEST] EscherStaircase...")
	
	var scene = load("res://commons/interfaces/foundations/escher_staircase.tscn")
	if not scene:
		_fail("EscherStaircase", "Scene failed to load")
		return
	
	var instance = scene.instantiate()
	add_child(instance)
	
	if not instance.has_method("climb_step"):
		_fail("EscherStaircase", "Missing climb_step() method")
		return
	
	if not instance.has_signal("paradox_completed"):
		_fail("EscherStaircase", "Missing paradox_completed signal")
		return
	
	# Check step count
	if instance._total_steps < 4:
		_fail("EscherStaircase", "Expected at least 4 steps")
		return
	
	_pass("EscherStaircase", "All checks passed")
	instance.queue_free()

func test_florensky_sphere() -> void:
	print("\n[TEST] FlorenskySphere...")
	
	var scene = load("res://commons/interfaces/foundations/florensky_sphere.tscn")
	if not scene:
		_fail("FlorenskySphere", "Scene failed to load")
		return
	
	var instance = scene.instantiate()
	add_child(instance)
	
	if not instance.has_method("observe"):
		_fail("FlorenskySphere", "Missing observe() method")
		return
	
	if not instance.has_method("cycle_state"):
		_fail("FlorenskySphere", "Missing cycle_state() method")
		return
	
	# Check default state is BOTH (paraconsistent)
	if instance.current_state != instance.LogicState.BOTH:
		_fail("FlorenskySphere", "Default state should be BOTH (A ∧ ¬A)")
		return
	
	_pass("FlorenskySphere", "All checks passed")
	instance.queue_free()

func test_bifurcation_diagram() -> void:
	print("\n[TEST] BifurcationDiagram...")
	
	var scene = load("res://commons/interfaces/foundations/bifurcation_diagram.tscn")
	if not scene:
		_fail("BifurcationDiagram", "Scene failed to load")
		return
	
	var instance = scene.instantiate()
	add_child(instance)
	
	if not instance.has_method("set_r_value"):
		_fail("BifurcationDiagram", "Missing set_r_value() method")
		return
	
	if not instance.has_method("get_regime"):
		_fail("BifurcationDiagram", "Missing get_regime() method")
		return
	
	# Test regime detection
	instance.set_r_value(2.8)
	if not instance.get_regime().contains("STABLE"):
		_fail("BifurcationDiagram", "r=2.8 should be STABLE regime")
		return
	
	instance.set_r_value(3.8)
	if not instance.get_regime().contains("CHAOS"):
		_fail("BifurcationDiagram", "r=3.8 should be CHAOS regime")
		return
	
	_pass("BifurcationDiagram", "All checks passed")
	instance.queue_free()

func _pass(test_name: String, message: String) -> void:
	tests_passed += 1
	var result = "✓ PASS: %s - %s" % [test_name, message]
	test_results.append(result)
	print(result)

func _fail(test_name: String, message: String) -> void:
	tests_failed += 1
	var result = "✗ FAIL: %s - %s" % [test_name, message]
	test_results.append(result)
	print(result)
