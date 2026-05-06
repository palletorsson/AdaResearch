# VRScrollTest.gd
# Test script for VR scroll functionality in Forces info board
extends Node3D

@export var test_board_scene: PackedScene = preload("res://commons/infoboards_3d/boards/Forces/ForcesInfoBoard_new.tscn")
var test_board: Node3D

func _ready():
	print("VRScrollTest: Starting VR scroll test")
	
	# Instantiate test board
	if test_board_scene:
		test_board = test_board_scene.instantiate()
		add_child(test_board)
		test_board.position = Vector3(0, 1.5, 0)
		
		print("VRScrollTest: Test board instantiated at position: ", test_board.position)
		
		# Wait a frame for the board to initialize
		await get_tree().process_frame
		
		# Check if VR input handler is working
		_check_vr_setup()
	else:
		print("VRScrollTest: Failed to load test board scene")

func _check_vr_setup():
	"""Check if VR input handler is properly set up"""
	if not test_board:
		print("VRScrollTest: No test board found")
		return
	
	# Find the VR input handler
	var vr_handler = test_board.find_child("VRInputHandler", true, false)
	if vr_handler:
		print("VRScrollTest: VR input handler found: ", vr_handler.name)
		
		# Check if it's a VRInfoBoardInput
		if vr_handler.get_script() and vr_handler.get_script().get_global_name() == "VRInfoBoardInput":
			print("VRScrollTest: VR input handler is properly configured")
		else:
			print("VRScrollTest: VR input handler script not found")
	else:
		print("VRScrollTest: VR input handler not found")
	
	# Check for InteractionArea
	var interaction_area = test_board.find_child("InteractionArea", true, false)
	if interaction_area:
		print("VRScrollTest: InteractionArea found: ", interaction_area.name)
		
		# Check collision shape
		var collision_shape = interaction_area.find_child("CollisionShape3D", true, false)
		if collision_shape:
			print("VRScrollTest: CollisionShape3D found in InteractionArea")
		else:
			print("VRScrollTest: CollisionShape3D not found in InteractionArea")
	else:
		print("VRScrollTest: InteractionArea not found")

func _input(event):
	"""Handle input for testing"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("VRScrollTest: Simulating VR trigger press")
				_simulate_vr_trigger()
			KEY_2:
				print("VRScrollTest: Testing scroll container access")
				_test_scroll_container()
			KEY_3:
				print("VRScrollTest: Testing VR controller detection")
				_test_vr_controller_detection()

func _simulate_vr_trigger():
	"""Simulate VR trigger input for testing"""
	if test_board:
		var vr_handler = test_board.find_child("VRInputHandler", true, false)
		if vr_handler and vr_handler.has_method("_handle_vr_scroll_input"):
			print("VRScrollTest: Simulating VR trigger input")
			# This would need to be called from the VR input handler
			# For now, just print that we found the handler
			print("VRScrollTest: VR input handler found and ready for testing")

func _test_scroll_container():
	"""Test scroll container access"""
	if test_board:
		# Find the UI control
		var ui_control = test_board.find_child("AlgorithmInfoBoardBase", true, false)
		if ui_control:
			print("VRScrollTest: UI control found: ", ui_control.name)
			
			# Try to access the scroll container
			var scroll_container = ui_control.get_node_or_null("MarginContainer/VBoxContainer/ContentArea/TextScroll")
			if scroll_container:
				print("VRScrollTest: ScrollContainer found: ", scroll_container.name)
				print("VRScrollTest: Current scroll position: ", scroll_container.scroll_vertical)
			else:
				print("VRScrollTest: ScrollContainer not found")
		else:
			print("VRScrollTest: UI control not found")

func _test_vr_controller_detection():
	"""Test VR controller detection"""
	print("VRScrollTest: Testing VR controller detection")
	
	# Check for XR controllers in the scene
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		print("VRScrollTest: XR origin found")
		
		var left_controller = xr_origin.find_child("LeftController", true, false)
		var right_controller = xr_origin.find_child("RightController", true, false)
		
		if left_controller:
			print("VRScrollTest: Left controller found: ", left_controller.name)
		if right_controller:
			print("VRScrollTest: Right controller found: ", right_controller.name)
	else:
		print("VRScrollTest: XR origin not found - VR may not be active")
	
	# Check for any XRController3D nodes
	var controllers = get_tree().get_nodes_in_group("xr_controllers")
	print("VRScrollTest: Found ", controllers.size(), " XR controllers in group")
	
	for controller in controllers:
		if controller is XRController3D:
			print("VRScrollTest: XRController3D found: ", controller.name)
