# test_registry.gd
# Quick test to verify InfoBoardRegistry is accessible
extends Node

func _ready():
	print("=== Testing InfoBoardRegistry ===")

	# Test 1: Check if valid board type (using internal type name)
	var is_valid = InfoBoardRegistry.is_valid_board_type("randomwalk")
	print("Test 1 - is_valid_board_type('randomwalk'): %s" % is_valid)

	# Test 2: Get board info
	var info = InfoBoardRegistry.get_board_info("randomwalk")
	print("Test 2 - Board info: %s" % info)

	# Test 3: Get board name
	var name = InfoBoardRegistry.get_board_name("randomwalk")
	print("Test 3 - Board name: %s" % name)

	# Test 4: Get category color
	var color = InfoBoardRegistry.get_category_color("Randomness")
	print("Test 4 - Category color: %s" % color)

	# Test 5: Parse board cell (NEW syntax)
	var parsed = InfoBoardRegistry.parse_board_cell("ib:randomwalk:0.5")
	print("Test 5 - Parsed cell (ib:randomwalk:0.5): %s" % parsed)

	# Test 6: Parse board cell (OLD syntax for backwards compatibility)
	var parsed_old = InfoBoardRegistry.parse_board_cell("ib_randomwalk:0.5")
	print("Test 5b - Parsed cell (ib_randomwalk:0.5): %s" % parsed_old)

	# Test 7: Validate board config (using new syntax)
	var layout = [
		[" ", "ib:randomwalk", " "],
		[" ", " ", "ib:bfs"]
	]
	var validation = InfoBoardRegistry.validate_board_config(layout)
	print("Test 6 - Validation result: %s" % validation)

	# Test 8: Get all categories
	var categories = InfoBoardRegistry.get_all_categories()
	print("Test 7 - All categories: %s" % categories)

	print("=== All Tests Complete ===")
