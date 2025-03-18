# Array2DHelper.gd
extends Node
class_name Array2DHelper

# Creates a 2D array of size (width x height) and fills it with default_value.
# Usage : grid = Array2DHelper.create_2d_array(columns, rows, 1)
static func create_2d_array(width: int, height: int, default_value: Variant) -> Array:
	"""
	Creates a 2D array (width x height) initialized with a default value.
	"""
	var result = []
	for x in range(width):
		var row = []
		for y in range(height):
			row.append(default_value)
		result.append(row)
	return result
