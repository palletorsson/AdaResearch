# InfoBoardPositioningTest.gd
# Test script to verify info board positioning works like other utilities
extends Node3D

@export var test_map_data: Dictionary = {
	"utilities": [
		["ib:vectors", "t:next", "ib:forces:1.5"],
		["l:2.0", "ib:randomwalk", "sp:100"],
		[" ", " ", "ib:unitcircle:0.5"]
	]
}

func _ready():
	print("InfoBoardPositioningTest: Testing info board positioning")
	_test_positioning_calculation()

func _test_positioning_calculation():
	"""Test that info boards are positioned like other utilities"""
	print("InfoBoardPositioningTest: Testing positioning calculation...")
	
	var utility_layout = test_map_data.utilities
	var cube_size = 1.0
	var gutter = 0.0
	var total_size = cube_size + gutter
	
	print("  Grid layout:")
	for z in range(utility_layout.size()):
		var row = utility_layout[z]
		var row_str = "  Row %d: " % z
		for x in range(row.size()):
			row_str += "[%d,%d]:%s " % [x, z, row[x]]
		print(row_str)
	
	print("\n  Position calculations:")
	for z in range(utility_layout.size()):
		var row = utility_layout[z]
		for x in range(row.size()):
			var utility_cell = str(row[x]).strip_edges()
			
			if utility_cell.is_empty() or utility_cell == " ":
				continue
			
			# Calculate position like GridUtilitiesComponent does
			var y_pos = 0  # Simulated find_highest_y_at(x, z)
			var position = Vector3(x, y_pos, z) * total_size
			
			if utility_cell.begins_with("ib:"):
				# Parse height offset for info boards
				var parts = utility_cell.split(":")
				var height_offset = 0.0
				if parts.size() > 2 and parts[2].is_valid_float():
					height_offset = float(parts[2])
				position.y += height_offset
				
				print("    %s at grid (%d, %d) -> 3D position %s (height offset: %.1f)" % [
					utility_cell, x, z, position, height_offset
				])
			else:
				print("    %s at grid (%d, %d) -> 3D position %s" % [
					utility_cell, x, z, position
				])

func _input(event):
	"""Handle input for testing"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("InfoBoardPositioningTest: Testing positioning calculation")
				_test_positioning_calculation()
			KEY_2:
				print("InfoBoardPositioningTest: Testing utility parsing")
				_test_utility_parsing()

func _test_utility_parsing():
	"""Test parsing of different utility types"""
	print("InfoBoardPositioningTest: Testing utility parsing...")
	
	var test_utilities = [
		"ib:vectors",
		"ib:forces:1.5", 
		"ib:randomwalk:0.5",
		"t:next",
		"l:2.0",
		"sp:100"
	]
	
	for utility in test_utilities:
		if utility.begins_with("ib:"):
			var parts = utility.split(":")
			var board_type = parts[1] if parts.size() > 1 else ""
			var height_offset = 0.0
			if parts.size() > 2 and parts[2].is_valid_float():
				height_offset = float(parts[2])
			
			print("  Info board: %s (type: %s, height: %.1f)" % [utility, board_type, height_offset])
		else:
			var parsed = UtilityRegistry.parse_utility_cell(utility)
			print("  Regular utility: %s (type: %s, params: %s)" % [utility, parsed.type, parsed.parameters])
