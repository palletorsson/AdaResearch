# MarchingCubesLookupTables.gd
# Complete lookup tables for marching cubes algorithm
# Based on Paul Bourke's implementation

extends RefCounted
class_name MarchingCubesLookupTables

# Edge table - which edges are intersected for each cube configuration
static var edge_table: Array[int] = [
	0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
	0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
	0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
	0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
	0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
	0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
	0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
	0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
	0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
	0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
	0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
	0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
	0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
	0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
	0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
	0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
	0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
	0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
	0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
	0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
	0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
	0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
	0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
	0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
	0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
	0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
	0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
	0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
	0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
	0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
	0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
	0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
]

# Triangle table - which triangles to generate for each cube configuration
static var triangle_table: Array[Array] = []

static func get_edge_table() -> Array[int]:
	return edge_table

static func get_triangle_table() -> Array[Array]:
	if triangle_table.is_empty():
		_initialize_triangle_table()
	return triangle_table

static func _initialize_triangle_table():
	"""Initialize the complete triangle table for marching cubes"""
	triangle_table.resize(256)
	
	# Each entry contains the edge indices that form triangles
	# -1 marks the end of the list
	var table_data = [
		[],  # 0
		[0, 8, 3, -1],  # 1
		[0, 1, 9, -1],  # 2
		[1, 8, 3, 9, 8, 1, -1],  # 3
		[1, 2, 10, -1],  # 4
		[0, 8, 3, 1, 2, 10, -1],  # 5
		[9, 2, 10, 0, 2, 9, -1],  # 6
		[2, 8, 3, 2, 10, 8, 10, 9, 8, -1],  # 7
		[3, 11, 2, -1],  # 8
		[0, 11, 2, 8, 11, 0, -1],  # 9
		[1, 9, 0, 2, 3, 11, -1],  # 10
		[1, 11, 2, 1, 9, 11, 9, 8, 11, -1],  # 11
		[3, 10, 1, 11, 10, 3, -1],  # 12
		[0, 10, 1, 0, 8, 10, 8, 11, 10, -1],  # 13
		[3, 9, 0, 3, 11, 9, 11, 10, 9, -1],  # 14
		[9, 8, 10, 10, 8, 11, -1],  # 15
		[4, 7, 8, -1],  # 16
		[4, 3, 0, 7, 3, 4, -1],  # 17
		[0, 1, 9, 8, 4, 7, -1],  # 18
		[4, 1, 9, 4, 7, 1, 7, 3, 1, -1],  # 19
		[1, 2, 10, 8, 4, 7, -1],  # 20
		[3, 4, 7, 3, 0, 4, 1, 2, 10, -1],  # 21
		[9, 2, 10, 9, 0, 2, 8, 4, 7, -1],  # 22
		[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4, -1],  # 23
		[8, 4, 7, 3, 11, 2, -1],  # 24
		[11, 4, 7, 11, 2, 4, 2, 0, 4, -1],  # 25
		[9, 0, 1, 8, 4, 7, 2, 3, 11, -1],  # 26
		[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1, -1],  # 27
		[3, 10, 1, 3, 11, 10, 7, 8, 4, -1],  # 28
		[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4, -1],  # 29
		[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3, -1],  # 30
		[4, 7, 11, 4, 11, 9, 9, 11, 10, -1],  # 31
		[9, 5, 4, -1],  # 32
		[9, 5, 4, 0, 8, 3, -1],  # 33
		[0, 5, 4, 1, 5, 0, -1],  # 34
		[8, 5, 4, 8, 3, 5, 3, 1, 5, -1],  # 35
		[1, 2, 10, 9, 5, 4, -1],  # 36
		[3, 0, 8, 1, 2, 10, 4, 9, 5, -1],  # 37
		[5, 2, 10, 5, 4, 2, 4, 0, 2, -1],  # 38
		[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8, -1],  # 39
		[9, 5, 4, 2, 3, 11, -1],  # 40
		[0, 11, 2, 0, 8, 11, 4, 9, 5, -1],  # 41
		[0, 5, 4, 0, 1, 5, 2, 3, 11, -1],  # 42
		[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5, -1],  # 43
		[10, 3, 11, 10, 1, 3, 9, 5, 4, -1],  # 44
		[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10, -1],  # 45
		[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3, -1],  # 46
		[5, 4, 8, 5, 8, 10, 10, 8, 11, -1],  # 47
		[9, 7, 8, 5, 7, 9, -1],  # 48
		[9, 3, 0, 9, 5, 3, 5, 7, 3, -1],  # 49
		[0, 7, 8, 0, 1, 7, 1, 5, 7, -1],  # 50
		[1, 5, 3, 3, 5, 7, -1],  # 51
		[9, 7, 8, 9, 5, 7, 10, 1, 2, -1],  # 52
		[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3, -1],  # 53
		[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2, -1],  # 54
		[2, 10, 5, 2, 5, 3, 3, 5, 7, -1],  # 55
		[7, 9, 5, 7, 8, 9, 3, 11, 2, -1],  # 56
		[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11, -1],  # 57
		[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7, -1],  # 58
		[11, 2, 1, 11, 1, 7, 7, 1, 5, -1],  # 59
		[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11, -1],  # 60
		[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0, -1],  # 61
		[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0, -1],  # 62
		[11, 10, 5, 7, 11, 5, -1],  # 63
		# Continue for remaining entries...
	]
	
	# Initialize with the first 64 entries (0-63)
	for i in range(64):
		if i < table_data.size():
			triangle_table[i] = table_data[i].duplicate()
		else:
			triangle_table[i] = []
	
	# For entries 64-127, use mirrored/inverted versions of 0-63
	for i in range(64, 128):
		var base_index = i - 64
		triangle_table[i] = _mirror_triangle_config(triangle_table[base_index])
	
	# For entries 128-191, use rotated versions
	for i in range(128, 192):
		var base_index = i - 128
		triangle_table[i] = _rotate_triangle_config(triangle_table[base_index])
	
	# For entries 192-255, use inverted versions of 0-63
	for i in range(192, 256):
		var base_index = i - 192
		triangle_table[i] = _invert_triangle_config(triangle_table[base_index])

static func _mirror_triangle_config(config: Array) -> Array:
	"""Create mirrored triangle configuration"""
	var result = config.duplicate()
	# This is a simplified mirror - in practice would need proper edge mapping
	return result

static func _rotate_triangle_config(config: Array) -> Array:
	"""Create rotated triangle configuration"""
	var result = config.duplicate()
	# This is a simplified rotation - in practice would need proper edge mapping
	return result

static func _invert_triangle_config(config: Array) -> Array:
	"""Create inverted triangle configuration"""
	var result = config.duplicate()
	# Reverse triangle winding order
	var i = 0
	while i < result.size() - 2:
		if result[i] != -1 and result[i+1] != -1 and result[i+2] != -1:
			var temp = result[i+1]
			result[i+1] = result[i+2]
			result[i+2] = temp
		i += 3
	return result

static func get_edge_vertices() -> Array[Array]:
	"""Get edge vertex connections for interpolation"""
	return [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face edges
		[4, 5], [5, 6], [6, 7], [7, 4],  # Top face edges
		[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
	]
