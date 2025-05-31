# UtilityDataTemplate.gd
# Base template for all utility data files
# Provides standardized structure and validation for map utility data

extends RefCounted
class_name UtilityDataTemplate

# Map metadata
var map_name: String = ""
var description: String = ""
var version: String = "1.0"

# The main layout data array
# Each sub-array represents a row (Z-axis)
# Each element in a row represents a column (X-axis)
# Y-axis is calculated automatically based on structure height
var layout_data: Array = []

# Validation and utility functions

# Validate this utility data
func validate() -> Dictionary:
	return UtilityRegistry.validate_utility_grid(layout_data)

# Get summary of utilities used
func get_utility_summary() -> Dictionary:
	var summary = {
		"total_cells": 0,
		"empty_cells": 0,
		"utility_cells": 0,
		"by_type": {},
		"by_category": {},
		"unknown_types": [],
		"dimensions": get_dimensions()
	}
	
	for z in range(layout_data.size()):
		var row = layout_data[z]
		for x in range(row.size()):
			summary.total_cells += 1
			var cell_value = str(row[x]).strip_edges()
			
			if cell_value.is_empty() or cell_value == " ":
				summary.empty_cells += 1
				continue
			
			summary.utility_cells += 1
			
			# Parse cell to get type
			var parsed = UtilityRegistry.parse_utility_cell(cell_value)
			var utility_type = parsed.type
			
			# Check if valid type
			if UtilityRegistry.is_valid_utility_type(utility_type):
				# Count by type
				if not summary.by_type.has(utility_type):
					summary.by_type[utility_type] = 0
				summary.by_type[utility_type] += 1
				
				# Count by category
				var category = UtilityRegistry.get_utility_category(utility_type)
				if not summary.by_category.has(category):
					summary.by_category[category] = 0
				summary.by_category[category] += 1
			else:
				if not summary.unknown_types.has(utility_type):
					summary.unknown_types.append(utility_type)
	
	return summary

# Get grid dimensions
func get_dimensions() -> Dictionary:
	if layout_data.is_empty():
		return {"width": 0, "depth": 0}
	
	var max_width = 0
	var depth = layout_data.size()
	
	for row in layout_data:
		if row.size() > max_width:
			max_width = row.size()
	
	return {"width": max_width, "depth": depth}

# Print utility mapping comment
func print_utility_mapping() -> void:
	print(UtilityRegistry.generate_utility_mapping_comment())

# Validate and print any issues
func validate_and_report() -> bool:
	var validation = validate()
	
	if validation.valid:
		print("✅ Utility data validation passed for map '%s'" % map_name)
		var summary = get_utility_summary()
		print("   Total utilities: %d" % summary.utility_cells)
		print("   Categories used: %s" % str(summary.by_category.keys()))
		return true
	else:
		print("❌ Utility data validation FAILED for map '%s'" % map_name)
		for error in validation.errors:
			print("   ERROR: %s" % error)
		for warning in validation.warnings:
			print("   WARNING: %s" % warning)
		if validation.unknown_types.size() > 0:
			print("   Unknown types: %s" % str(validation.unknown_types))
		return false

# Generate properly formatted utility data file content
func generate_file_content() -> String:
	var content_lines = [
		"extends UtilityDataTemplate",
		"",
		"# Map utility data",
		"# Generated automatically - edit with care",
		"",
		"func _init():",
		"\tmap_name = \"%s\"" % map_name,
		"\tdescription = \"%s\"" % description,
		"\tversion = \"%s\"" % version,
		"",
		"\t# Layout data - each row represents Z-axis, each column represents X-axis",
		"\tlayout_data = ["
	]
	
	# Add layout data
	for z in range(layout_data.size()):
		var row = layout_data[z]
		var row_str = "\t\t["
		for x in range(row.size()):
			var cell = str(row[x])
			row_str += "\"%s\"" % cell
			if x < row.size() - 1:
				row_str += ", "
		row_str += "]"
		if z < layout_data.size() - 1:
			row_str += ","
		content_lines.append(row_str)
	
	content_lines.append("\t]")
	content_lines.append("")
	content_lines.append(UtilityRegistry.generate_utility_mapping_comment())
	
	return "\n".join(content_lines)

# Helper function to resize grid
func resize_grid(new_width: int, new_depth: int, fill_value: String = " ") -> void:
	# Resize depth (add/remove rows)
	while layout_data.size() < new_depth:
		layout_data.append([])
	
	while layout_data.size() > new_depth:
		layout_data.pop_back()
	
	# Resize width (add/remove columns)
	for z in range(layout_data.size()):
		var row = layout_data[z]
		
		# Add columns if needed
		while row.size() < new_width:
			row.append(fill_value)
		
		# Remove columns if needed
		while row.size() > new_width:
			row.pop_back()

# Helper function to set utility at position
func set_utility_at(x: int, z: int, utility_code: String) -> bool:
	if z < 0 or z >= layout_data.size():
		return false
	
	var row = layout_data[z]
	if x < 0 or x >= row.size():
		return false
	
	row[x] = utility_code
	return true

# Helper function to get utility at position
func get_utility_at(x: int, z: int) -> String:
	if z < 0 or z >= layout_data.size():
		return " "
	
	var row = layout_data[z]
	if x < 0 or x >= row.size():
		return " "
	
	return str(row[x])

# Clear all utilities (set to empty)
func clear_all() -> void:
	for z in range(layout_data.size()):
		var row = layout_data[z]
		for x in range(row.size()):
			row[x] = " "

# Fill area with utility type
func fill_area(start_x: int, start_z: int, end_x: int, end_z: int, utility_code: String) -> void:
	for z in range(start_z, end_z + 1):
		for x in range(start_x, end_x + 1):
			set_utility_at(x, z, utility_code) 