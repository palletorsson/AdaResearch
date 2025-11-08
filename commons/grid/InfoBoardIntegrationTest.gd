# InfoBoardIntegrationTest.gd
# Test script to verify ib: utilities work in GridSystem
extends Node3D

@export var test_map_data: Dictionary = {
	"utilities": [
		["ib:vectors", " ", "ib:forces:1.5"],
		[" ", "ib:randomwalk", " "],
		["t", " ", "l"]
	]
}

func _ready():
	print("InfoBoardIntegrationTest: Starting integration test")
	_test_utility_parsing()
	_test_info_board_validation()
	_test_registry_integration()

func _test_utility_parsing():
	print("InfoBoardIntegrationTest: Testing utility parsing...")
	var test_cells = [
		"ib:vectors",
		"ib:forces:1.5",
		"ib:randomwalk:0.5",
		"t:next",
		"l:2.0"
	]
	for cell in test_cells:
		var parsed = UtilityRegistry.parse_utility_cell(cell)
		print("  %s -> type: %s, params: %s" % [cell, parsed.type, parsed.parameters])
		if cell.begins_with("ib:"):
			var parts = cell.split(":")
			var board_type = parts[1] if parts.size() > 1 else ""
			var height_offset = 0.0
			if parts.size() > 2 and parts[2].is_valid_float():
				height_offset = float(parts[2])
			print("    Board type: %s, Height offset: %.1f" % [board_type, height_offset])

func _test_info_board_validation():
	print("InfoBoardIntegrationTest: Testing info board validation...")
	var test_board_types = ["vectors", "forces", "randomwalk", "invalid_type"]
	for board_type in test_board_types:
		var is_valid = InfoBoardRegistry.is_valid_board_type(board_type)
		var status := "Valid" if is_valid else "Invalid"
		print("  %s: %s" % [board_type, status])
		if is_valid:
			var board_info = InfoBoardRegistry.get_board_info(board_type)
			print("    Name: %s" % board_info.get("name", "Unknown"))
			print("    Scene: %s" % board_info.get("scene", "Unknown"))

func _test_registry_integration():
	print("InfoBoardIntegrationTest: Testing registry integration...")
	var test_grid = [
		["ib:vectors", "ib:forces:1.5", " "],
		["t:next", "ib:randomwalk", "l:2.0"],
		[" ", " ", "ib:invalid_type"]
	]
	var validation = UtilityRegistry.validate_utility_grid(test_grid)
	var validation_status := "Valid" if validation.valid else "Invalid"
	print("  Validation result: %s" % validation_status)
	if not validation.valid:
		print("  Errors:")
		for error in validation.errors:
			print("    %s" % error)
	if not validation.warnings.is_empty():
		print("  Warnings:")
		for warning in validation.warnings:
			print("    %s" % warning)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("InfoBoardIntegrationTest: Testing utility parsing")
				_test_utility_parsing()
			KEY_2:
				print("InfoBoardIntegrationTest: Testing info board validation")
				_test_info_board_validation()
			KEY_3:
				print("InfoBoardIntegrationTest: Testing registry integration")
				_test_registry_integration()
			KEY_4:
				print("InfoBoardIntegrationTest: Testing complete integration")
				_test_complete_integration()

func _test_complete_integration():
	print("InfoBoardIntegrationTest: Testing complete integration...")
	var utility_layout = test_map_data.utilities
	var info_board_data: Array = []
	var regular_utilities: Array = []
	for z in range(utility_layout.size()):
		var row = utility_layout[z]
		for x in range(row.size()):
			var utility_cell = str(row[x]).strip_edges()
			if utility_cell.is_empty() or utility_cell == " ":
				continue
			if utility_cell.begins_with("ib:"):
				var parts = utility_cell.split(":")
				var board_type = parts[1] if parts.size() > 1 else ""
				var height_offset = 0.0
				if parts.size() > 2 and parts[2].is_valid_float():
					height_offset = float(parts[2])
				if InfoBoardRegistry.is_valid_board_type(board_type):
					info_board_data.append({
						"board_type": board_type,
						"position": Vector3i(x, 0, z),
						"height_offset": height_offset
					})
					print("  Found info board: %s at (%d, %d) with height %.1f" % [board_type, x, z, height_offset])
					var scene_path = InfoBoardRegistry.get_board_scene_path(board_type)
					print("    Scene path: %s" % scene_path)
					var scene_status := "Yes" if ResourceLoader.exists(scene_path) else "No"
					print("    Scene exists: %s" % scene_status)
				else:
					print("  Invalid info board type: %s" % board_type)
			else:
				var utility_type = utility_cell.split(":")[0]
				var utility_params: Array = []
				if ":" in utility_cell:
					var split_parts = utility_cell.split(":")
					if split_parts.size() > 1:
						utility_params = split_parts.slice(1, split_parts.size())
				regular_utilities.append({
					"type": utility_type,
					"position": Vector3i(x, 0, z),
					"parameters": utility_params
				})
				print("  Found regular utility: %s at (%d, %d)" % [utility_type, x, z])
	print("  Summary: %d info boards, %d regular utilities" % [info_board_data.size(), regular_utilities.size()])
	print("  Testing positioning calculation:")
	for board_data in info_board_data:
		var grid_pos: Vector3i = board_data.get("position", Vector3i.ZERO)
		var board_type: String = board_data.get("board_type", "")
		var height_offset: float = board_data.get("height_offset", 0.0)
		var cube_size = 1.0
		var gutter = 0.0
		var total_size = cube_size + gutter
		var y_pos = 0
		var position = Vector3(grid_pos.x, y_pos, grid_pos.z) * total_size
		position.y += height_offset
		print("    %s at grid (%d, %d) -> 3D position %s" % [board_type, grid_pos.x, grid_pos.z, position])
