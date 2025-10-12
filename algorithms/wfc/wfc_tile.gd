extends RefCounted
class_name WFCTile

# Wave Function Collapse Tile Definition
# Defines a tile type with its compatibility rules

var tile_id: String
var rotation: int = 0  # 0, 90, 180, 270 degrees
var weight: float = 1.0  # Probability weight for selection

# Adjacency rules: which tiles can be placed in each direction
# Directions: +X, -X, +Y, -Y, +Z, -Z (right, left, up, down, forward, back)
var compatible_neighbors = {
	Vector3.RIGHT: [],   # +X
	Vector3.LEFT: [],    # -X
	Vector3.UP: [],      # +Y
	Vector3.DOWN: [],    # -Y
	Vector3(0, 0, 1): [], # +Z (forward)
	Vector3(0, 0, -1): [] # -Z (back)
}

# Visual mesh for this tile (scene path or mesh)
var mesh_scene: String = ""
var color: Color = Color.WHITE

func _init(id: String = "", w: float = 1.0):
	tile_id = id
	weight = w

func set_compatible(direction: Vector3, tile_ids: Array):
	"""Set which tile IDs are compatible in a given direction"""
	compatible_neighbors[direction] = tile_ids.duplicate()

func is_compatible_with(other_tile_id: String, direction: Vector3) -> bool:
	"""Check if another tile can be placed in the given direction"""
	if not compatible_neighbors.has(direction):
		return false
	return other_tile_id in compatible_neighbors[direction]

func get_compatible_in_direction(direction: Vector3) -> Array:
	"""Get all compatible tile IDs for a direction"""
	if compatible_neighbors.has(direction):
		return compatible_neighbors[direction]
	return []

func duplicate_tile() -> WFCTile:
	"""Create a copy of this tile"""
	var new_tile = WFCTile.new(tile_id, weight)
	new_tile.rotation = rotation
	new_tile.mesh_scene = mesh_scene
	new_tile.color = color
	for dir in compatible_neighbors:
		new_tile.compatible_neighbors[dir] = compatible_neighbors[dir].duplicate()
	return new_tile
