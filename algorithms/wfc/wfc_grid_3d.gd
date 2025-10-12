extends Node3D
class_name WFCGrid3D

# WFC 3D Grid Manager
# Manages the generation and visualization of a 3D WFC grid

@export var grid_width: int = 10
@export var grid_height: int = 1
@export var grid_depth: int = 10
@export var tile_size: float = 1.0
@export var auto_generate: bool = false
@export var generation_seed: int = 0
@export var animate_generation: bool = false
@export var animation_speed: float = 0.1

var solver: WFCSolver
var tile_nodes = {}  # Dictionary of Vector3 position -> WFCTile3D node
var tile_types = {}  # Dictionary of tile_id -> WFCTile

signal generation_started
signal generation_complete
signal tile_placed(position, tile_id)

func _ready():
	# Initialize solver
	solver = WFCSolver.new(Vector3(grid_width, grid_height, grid_depth), generation_seed)

	# Connect signals
	solver.tile_collapsed.connect(_on_tile_collapsed)
	solver.generation_complete.connect(_on_generation_complete)

	# Setup default tiles if none are added
	if tile_types.is_empty():
		setup_default_tiles()

	# Register tiles with solver
	for tile_id in tile_types:
		solver.add_tile_type(tile_types[tile_id])

	if auto_generate:
		call_deferred("generate")

func add_tile_type(tile: WFCTile):
	"""Add a tile type to the tileset"""
	tile_types[tile.tile_id] = tile
	if solver:
		solver.add_tile_type(tile)

func setup_default_tiles():
	"""Create a simple default tileset for testing"""
	# Empty tile
	var empty = WFCTile.new("empty", 2.0)
	empty.color = Color(0.1, 0.1, 0.1)
	empty.set_compatible(Vector3.RIGHT, ["empty", "ground", "wall"])
	empty.set_compatible(Vector3.LEFT, ["empty", "ground", "wall"])
	empty.set_compatible(Vector3.UP, ["empty"])
	empty.set_compatible(Vector3.DOWN, ["empty", "ground"])
	empty.set_compatible(Vector3(0, 0, 1), ["empty", "ground", "wall"])
	empty.set_compatible(Vector3(0, 0, -1), ["empty", "ground", "wall"])
	add_tile_type(empty)

	# Ground tile
	var ground = WFCTile.new("ground", 1.0)
	ground.color = Color(0.3, 0.6, 0.3)
	ground.set_compatible(Vector3.RIGHT, ["ground", "wall"])
	ground.set_compatible(Vector3.LEFT, ["ground", "wall"])
	ground.set_compatible(Vector3.UP, ["empty", "wall"])
	ground.set_compatible(Vector3.DOWN, ["ground"])
	ground.set_compatible(Vector3(0, 0, 1), ["ground", "wall"])
	ground.set_compatible(Vector3(0, 0, -1), ["ground", "wall"])
	add_tile_type(ground)

	# Wall tile
	var wall = WFCTile.new("wall", 0.5)
	wall.color = Color(0.6, 0.4, 0.2)
	wall.set_compatible(Vector3.RIGHT, ["wall", "ground", "empty"])
	wall.set_compatible(Vector3.LEFT, ["wall", "ground", "empty"])
	wall.set_compatible(Vector3.UP, ["wall", "empty"])
	wall.set_compatible(Vector3.DOWN, ["wall", "ground"])
	wall.set_compatible(Vector3(0, 0, 1), ["wall", "ground", "empty"])
	wall.set_compatible(Vector3(0, 0, -1), ["wall", "ground", "empty"])
	add_tile_type(wall)

func generate():
	"""Generate the WFC grid"""
	emit_signal("generation_started")
	clear_grid()

	print("WFC: Starting generation with grid size ", Vector3(grid_width, grid_height, grid_depth))

	# Run the solver
	var success = solver.generate()

	if success:
		print("WFC: Generation successful!")
		if not animate_generation:
			# Instantiate all tiles at once
			instantiate_all_tiles()
	else:
		print("WFC: Generation failed!")

	return success

func clear_grid():
	"""Clear all existing tiles"""
	for node in tile_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	tile_nodes.clear()

func _on_tile_collapsed(position: Vector3, tile_id: String):
	"""Called when a tile is collapsed by the solver"""
	emit_signal("tile_placed", position, tile_id)

	if animate_generation:
		# Instantiate tile immediately for animated generation
		instantiate_tile(position, tile_id)
		# Small delay for animation
		await get_tree().create_timer(animation_speed).timeout

func _on_generation_complete():
	"""Called when generation is complete"""
	emit_signal("generation_complete")
	print("WFC: Generation complete - ", tile_nodes.size(), " tiles placed")

func instantiate_all_tiles():
	"""Instantiate all tiles from the solved grid"""
	var collapsed_grid = solver.get_collapsed_grid()

	for pos in collapsed_grid:
		var tile_id = collapsed_grid[pos]
		instantiate_tile(pos, tile_id)

func instantiate_tile(pos: Vector3, tile_id: String):
	"""Create a 3D tile at the given position"""
	if not tile_types.has(tile_id):
		return

	# Create tile node
	var tile_node = WFCTile3D.new()
	add_child(tile_node)

	# Setup with tile type and position
	tile_node.setup(tile_types[tile_id], pos, tile_size)

	# Store reference
	tile_nodes[pos] = tile_node

func get_tile_at(pos: Vector3) -> WFCTile3D:
	"""Get the tile node at a grid position"""
	if tile_nodes.has(pos):
		return tile_nodes[pos]
	return null

func regenerate():
	"""Clear and regenerate the grid"""
	generate()
