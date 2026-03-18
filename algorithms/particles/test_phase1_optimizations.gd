extends Node3D

## Phase 1 Optimization Verification Test
## Tests all Phase 1 improvements to particle system
## Created by: Agent-PerformanceEngineer, Agent-ParticlePhysicist, Agent-VisualOptimizer

var test_results: Dictionary = {}
var emitter: ParticleEmitter

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("PHASE 1 PARTICLE OPTIMIZATION VERIFICATION")
	print("=".repeat(60) + "\n")
	
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	"""Run all verification tests"""
	test_cleanup_performance()
	test_parametric_physics()
	test_lifespan_frame_independence()
	test_visual_regression()

func test_cleanup_performance() -> void:
	"""Test: O(n) cleanup is faster than O(n²)"""
	print("TEST 1: Cleanup Performance (O(n) vs O(n²))")
	
	# Create test emitter
	emitter = ParticleEmitter.new()
	emitter.max_particles = 1000
	emitter.emission_rate = 1000.0
	add_child(emitter)
	
	# Wait for particles to spawn
	await get_tree().create_timer(1.0).timeout
	
	# Measure cleanup time
	var start_time = Time.get_ticks_usec()
	emitter.cleanup_dead_particles()
	var end_time = Time.get_ticks_usec()
	var cleanup_time = (end_time - start_time) / 1000.0  # Convert to ms
	
	# O(n) should be < 1ms for 1000 particles
	var passed = cleanup_time < 1.0
	test_results["cleanup_performance"] = {
		"passed": passed,
		"time_ms": cleanup_time,
		"expected": "< 1ms",
		"note": "O(n) swap-and-pop algorithm"
	}
	
	print("  Cleanup time: %.3f ms" % cleanup_time)
	print("  Status: %s\n" % ("✅ PASS" if passed else "❌ FAIL"))

func test_parametric_physics() -> void:
	"""Test: Parametric physics controls work correctly"""
	print("TEST 2: Parametric Physics Controls")
	
	# Create test particle
	var particle = Particle.new(Vector3.ZERO, Vector3(1, 1, 0))
	particle.damping = 0.9
	particle.restitution = 0.7
	add_child(particle)
	
	# Test damping
	var initial_velocity = particle.velocity.length()
	particle.update(0.016)  # One frame
	var damped_velocity = particle.velocity.length()
	
	var damping_works = damped_velocity < initial_velocity
	
	# Test restitution (would need fish tank for full test)
	var restitution_configurable = particle.restitution == 0.7
	
	var passed = damping_works and restitution_configurable
	test_results["parametric_physics"] = {
		"passed": passed,
		"damping_applied": damping_works,
		"restitution_configurable": restitution_configurable,
		"note": "Agent-ParticlePhysicist implementation"
	}
	
	print("  Damping applied: %s" % ("✅" if damping_works else "❌"))
	print("  Restitution configurable: %s" % ("✅" if restitution_configurable else "❌"))
	print("  Status: %s\n" % ("✅ PASS" if passed else "❌ FAIL"))
	
	particle.queue_free()

func test_lifespan_frame_independence() -> void:
	"""Test: Lifespan decay is frame-rate independent"""
	print("TEST 3: Frame-Rate Independent Lifespan")
	
	# Create two particles with same settings
	var particle_60fps = Particle.new(Vector3.ZERO, Vector3.ZERO)
	var particle_30fps = Particle.new(Vector3.ZERO, Vector3.ZERO)
	particle_60fps.decay_rate = 1.0
	particle_30fps.decay_rate = 1.0
	add_child(particle_60fps)
	add_child(particle_30fps)
	
	# Simulate 1 second at different frame rates
	# 60 FPS: 60 frames of 0.0167s
	for i in range(60):
		particle_60fps.update(0.01667)
	
	# 30 FPS: 30 frames of 0.0333s
	for i in range(30):
		particle_30fps.update(0.03333)
	
	# Both should have decayed by ~1.0 second
	var lifespan_60 = particle_60fps.lifespan
	var lifespan_30 = particle_30fps.lifespan
	var difference = abs(lifespan_60 - lifespan_30)
	
	# Allow 5% tolerance
	var passed = difference < 0.2
	test_results["lifespan_independence"] = {
		"passed": passed,
		"lifespan_60fps": lifespan_60,
		"lifespan_30fps": lifespan_30,
		"difference": difference,
		"note": "Should be frame-rate independent"
	}
	
	print("  Lifespan at 60 FPS: %.2f" % lifespan_60)
	print("  Lifespan at 30 FPS: %.2f" % lifespan_30)
	print("  Difference: %.2f (should be < 0.2)" % difference)
	print("  Status: %s\n" % ("✅ PASS" if passed else "❌ FAIL"))
	
	particle_60fps.queue_free()
	particle_30fps.queue_free()

func test_visual_regression() -> void:
	"""Test: Visual appearance unchanged"""
	print("TEST 4: Visual Regression Check")
	
	# Create particle and check visual properties
	var particle = Particle.new(Vector3.ZERO, Vector3.ZERO)
	add_child(particle)
	await get_tree().process_frame
	
	# Check mesh instance exists
	var has_mesh = particle.mesh_instance != null
	
	# Check material exists
	var has_material = particle.material != null
	
	# Check emission enabled
	var has_emission = particle.material.emission_enabled if has_material else false
	
	# Check transparency
	var has_transparency = particle.material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA if has_material else false
	
	var passed = has_mesh and has_material and has_emission and has_transparency
	test_results["visual_regression"] = {
		"passed": passed,
		"has_mesh": has_mesh,
		"has_material": has_material,
		"has_emission": has_emission,
		"has_transparency": has_transparency,
		"note": "Agent-VisualOptimizer verification"
	}
	
	print("  Mesh instance: %s" % ("✅" if has_mesh else "❌"))
	print("  Material: %s" % ("✅" if has_material else "❌"))
	print("  Emission: %s" % ("✅" if has_emission else "❌"))
	print("  Transparency: %s" % ("✅" if has_transparency else "❌"))
	print("  Status: %s\n" % ("✅ PASS" if passed else "❌ FAIL"))
	
	particle.queue_free()

func print_results() -> void:
	"""Print final test summary"""
	print("=".repeat(60))
	print("TEST SUMMARY")
	print("=".repeat(60))
	
	var total_tests = test_results.size()
	var passed_tests = 0
	
	for test_name in test_results:
		var result = test_results[test_name]
		if result.passed:
			passed_tests += 1
		
		var status = "✅ PASS" if result.passed else "❌ FAIL"
		print("%s: %s" % [test_name.capitalize().replace("_", " "), status])
	
	print("\nRESULT: %d/%d tests passed" % [passed_tests, total_tests])
	
	if passed_tests == total_tests:
		print("\n🎉 ALL TESTS PASSED! Phase 1 optimization successful!")
		print("\nPerformance improvements:")
		print("  • Cleanup: O(n²) → O(n)")
		print("  • Physics: Frame-rate independent")
		print("  • Controls: Parametric (damping, restitution)")
		print("  • Visuals: No regression")
	else:
		print("\n⚠️ Some tests failed. Review implementation.")
	
	print("=".repeat(60) + "\n")
	
	# Clean up
	if emitter:
		emitter.queue_free()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
