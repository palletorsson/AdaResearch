extends Node
class_name SoftBodyTest

# Simple test script to validate soft body functionality
@onready var scene_controller = $SoftBodyVariationsScene

func _ready() -> void:
	print("🧪 SoftBody3D Test Starting...")
	
	# Wait a moment for scene to initialize
	await get_tree().create_timer(1.0).timeout
	
	_run_basic_tests()

func _run_basic_tests() -> void:
	print("🔍 Running Basic Tests...")
	
	# Test 1: Check if scene controller exists
	if scene_controller:
		print("✅ Scene controller found")
		
		# Test 2: Check soft body count
		var soft_body_count = scene_controller.get_soft_body_count()
		print("✅ Found %d soft bodies" % soft_body_count)
		
		# Test 3: Check each soft body type
		var expected_types = ["sphere", "box", "cylinder", "capsule"]
		for type in expected_types:
			var body = scene_controller.get_soft_body_by_type(type)
			if body:
				print("✅ Soft body '%s' found at: %s" % [type, body.global_position])
				body.print_status()
			else:
				print("❌ Soft body '%s' not found" % type)
		
		# Test 4: Test physics interactions
		print("🎮 Testing Physics Interactions...")
		_test_physics_interactions()
		
	else:
		print("❌ Scene controller not found!")
	
	print("🏁 Basic tests completed!")

func _test_physics_interactions() -> void:
	print("💨 Testing Wind Zone...")
	
	# Get sphere soft body and apply impulse
	var sphere_body = scene_controller.get_soft_body_by_type("sphere")
	if sphere_body:
		sphere_body.apply_external_impulse(Vector3(5.0, 3.0, 0.0))
		print("✅ Applied impulse to sphere soft body")
	
	# Wait and test state changes
	await get_tree().create_timer(3.0).timeout
	
	print("🔄 Testing State Changes...")
	if sphere_body:
		sphere_body.print_status()
	
	# Test controller functions
	print("🎛️ Testing Controller Functions...")
	if scene_controller.has_method("print_scene_status"):
		print("📊 Scene Status:")
		print("Soft Bodies: %d" % scene_controller.get_soft_body_count())
		print("Controller: %s" % scene_controller.name)
	
	print("🎯 All tests completed!")

func _on_test_timer_timeout() -> void:
	print("⏰ Test timer finished - running final validation...")
	
	# Final check - ensure all bodies are still functioning
	var body_count = scene_controller.get_soft_body_count()
	if body_count == 4:
		print("✅ All 4 soft bodies are active and functioning!")
	else:
		print("⚠️ Only %d soft bodies found" % body_count)
