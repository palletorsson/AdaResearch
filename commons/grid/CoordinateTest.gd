# CoordinateTest.gd
# Quick test to verify coordinate system
extends Node3D

func _ready():
	print("CoordinateTest: Testing coordinate system")
	
	# Test grid layout
	var utility_layout = [
		["ib:vectors", "t:next", "ib:forces:1.5"],
		["l:2.0", "ib:randomwalk", "sp:100"],
		[" ", " ", "ib:unitcircle:0.5"]
	]
	
	print("Grid layout:")
	for z in range(utility_layout.size()):
		var row = utility_layout[z]
		var row_str = "  Row %d: " % z
		for x in range(row.size()):
			row_str += "[%d,%d]:%s " % [x, z, row[x]]
		print(row_str)
	
	print("\nCoordinate mapping (x, z) -> Vector3(x, y, z):")
	for z in range(utility_layout.size()):
		var row = utility_layout[z]
		for x in range(row.size()):
			var utility_cell = str(row[x]).strip_edges()
			if not utility_cell.is_empty() and utility_cell != " ":
				var y_pos = 0  # Simulated
				var position = Vector3(x, y_pos, z)
				print("  %s at grid (%d, %d) -> Vector3(%d, %d, %d)" % [utility_cell, x, z, position.x, position.y, position.z])
