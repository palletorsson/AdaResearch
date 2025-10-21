# VectorsTest.gd
# Test script to verify Vectors info board is working
extends Node3D

@export var test_scene: PackedScene = preload("res://commons/infoboards_3d/boards/Vectors/VectorsInfoBoard.tscn")
var test_board: Node3D

func _ready():
	print("VectorsTest: Starting Vectors info board test")
	
	# Instantiate test board
	if test_scene:
		test_board = test_scene.instantiate()
		add_child(test_board)
		test_board.position = Vector3(0, 1.5, 0)
		
		print("VectorsTest: Vectors info board instantiated at position: ", test_board.position)
		
		# Wait a frame for the board to initialize
		await get_tree().process_frame
		
		# Check if the board is working
		_check_board_setup()
	else:
		print("VectorsTest: Failed to load Vectors info board scene")

func _check_board_setup():
	"""Check if the Vectors info board is properly set up"""
	if not test_board:
		print("VectorsTest: No test board found")
		return
	
	# Check for the UI control
	var ui_control = test_board.find_child("AlgorithmInfoBoardBase", true, false)
	if ui_control:
		print("VectorsTest: UI control found: ", ui_control.name)
		
		# Check if it's a VectorsInfoBoard
		if ui_control.get_script() and ui_control.get_script().get_global_name() == "VectorsInfoBoard":
			print("VectorsTest: VectorsInfoBoard script found")
		else:
			print("VectorsTest: VectorsInfoBoard script not found")
		
		# Check for VR input handler
		var vr_handler = test_board.find_child("VRInputHandler", true, false)
		if vr_handler:
			print("VectorsTest: VR input handler found")
		else:
			print("VectorsTest: VR input handler not found")
	else:
		print("VectorsTest: UI control not found")
	
	# Check for InteractionArea
	var interaction_area = test_board.find_child("InteractionArea", true, false)
	if interaction_area:
		print("VectorsTest: InteractionArea found: ", interaction_area.name)
	else:
		print("VectorsTest: InteractionArea not found")

func _input(event):
	"""Handle input for testing"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("VectorsTest: Testing board instantiation")
				_test_board_instantiation()
			KEY_2:
				print("VectorsTest: Testing registry lookup")
				_test_registry_lookup()
			KEY_3:
				print("VectorsTest: Testing VR functionality")
				_test_vr_functionality()

func _test_board_instantiation():
	"""Test if the board can be instantiated properly"""
	print("VectorsTest: Testing board instantiation...")
	
	if test_board:
		print("VectorsTest: Board is already instantiated")
		return
	
	# Try to instantiate again
	if test_scene:
		test_board = test_scene.instantiate()
		add_child(test_board)
		test_board.position = Vector3(2, 1.5, 0)
		print("VectorsTest: Second board instantiated at position: ", test_board.position)

func _test_registry_lookup():
	"""Test if the board is properly registered"""
	print("VectorsTest: Testing registry lookup...")
	
	# Check if InfoBoardRegistry can find the vectors board
	if InfoBoardRegistry.is_valid_board_type("vectors"):
		print("VectorsTest: 'vectors' board type is valid")
		
		var board_info = InfoBoardRegistry.get_board_info("vectors")
		print("VectorsTest: Board info: ", board_info)
		
		var scene_path = InfoBoardRegistry.get_board_scene_path("vectors")
		print("VectorsTest: Scene path: ", scene_path)
		
		if ResourceLoader.exists(scene_path):
			print("VectorsTest: Scene file exists")
		else:
			print("VectorsTest: Scene file missing: ", scene_path)
	else:
		print("VectorsTest: 'vectors' board type is not valid")

func _test_vr_functionality():
	"""Test VR functionality"""
	print("VectorsTest: Testing VR functionality...")
	
	if test_board:
		# Check for VR input handler
		var vr_handler = test_board.find_child("VRInputHandler", true, false)
		if vr_handler:
			print("VectorsTest: VR input handler found")
			
			# Check if it has the right script
			if vr_handler.get_script():
				print("VectorsTest: VR input handler script: ", vr_handler.get_script().get_global_name())
			else:
				print("VectorsTest: VR input handler has no script")
		else:
			print("VectorsTest: VR input handler not found")
		
		# Check for InteractionArea
		var interaction_area = test_board.find_child("InteractionArea", true, false)
		if interaction_area:
			print("VectorsTest: InteractionArea found")
			
			# Check collision shape
			var collision_shape = interaction_area.find_child("CollisionShape3D", true, false)
			if collision_shape:
				print("VectorsTest: CollisionShape3D found in InteractionArea")
			else:
				print("VectorsTest: CollisionShape3D not found in InteractionArea")
		else:
			print("VectorsTest: InteractionArea not found")
