extends SceneTree

# Quick compile test for WFC

func _init():
	print("=== Testing WFC Compilation ===")

	# Test WFCTile
	var tile = WFCTile.new("test", 1.0)
	tile.color = Color.RED
	tile.set_compatible(Vector3.RIGHT, ["test"])
	print("✓ WFCTile works")

	# Test WFCSolver
	var solver = WFCSolver.new(Vector3(5, 1, 5), 123)
	solver.add_tile_type(tile)
	print("✓ WFCSolver works")

	print("=== All WFC classes compile successfully ===")
	quit()
