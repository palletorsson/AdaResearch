@tool
class_name ElementLayout
extends Resource
## Stores a grid-based element layout that can be saved/loaded and instantiated at runtime.

## The subset this layout uses (e.g., "audio_rack", "glass_rack", "big_pipes")
@export var subset_id: String = ""

## Grid size in meters per cell
@export var grid_size: float = 0.08

## Orientation plane: "XY", "YZ", or "XZ"
@export var orientation_plane: String = "XY"

## Array of placed elements
## Each entry: { "id": String, "grid_pos": Vector3i, "rotation": int }
@export var placements: Array[Dictionary] = []

## Metadata
@export var layout_name: String = "Untitled"
@export var created_at: String = ""
@export var modified_at: String = ""


func _init():
	created_at = Time.get_datetime_string_from_system()
	modified_at = created_at


func add_placement(element_id: String, grid_pos: Vector3i, rotation: int = 0) -> int:
	"""Add a placement and return its index."""
	var placement = {
		"id": element_id,
		"grid_pos": grid_pos,
		"rotation": rotation
	}
	placements.append(placement)
	modified_at = Time.get_datetime_string_from_system()
	return placements.size() - 1


func remove_placement(index: int) -> Dictionary:
	"""Remove a placement by index and return it."""
	if index < 0 or index >= placements.size():
		return {}
	var removed = placements[index]
	placements.remove_at(index)
	modified_at = Time.get_datetime_string_from_system()
	return removed


func get_placement_at_grid(grid_pos: Vector3i) -> int:
	"""Find placement index at grid position, or -1 if empty."""
	for i in range(placements.size()):
		if placements[i].grid_pos == grid_pos:
			return i
	return -1


func clear():
	"""Remove all placements."""
	placements.clear()
	modified_at = Time.get_datetime_string_from_system()


func _normalize_rotation(rotation: int) -> int:
	var normalized = rotation % 4
	if normalized < 0:
		normalized += 4
	return normalized


func _get_rotated_size(size: Array, rotation: int) -> Array:
	var w: int = int(size[0]) if size.size() > 0 else 1
	var h: int = int(size[1]) if size.size() > 1 else 1
	var normalized_rotation = _normalize_rotation(rotation)
	if normalized_rotation == 1 or normalized_rotation == 3:
		var tmp = w
		w = h
		h = tmp
	return [w, h]


func grid_to_world(grid_pos: Vector3i, elem_size: Array = [1, 1], rotation: int = 0) -> Vector3:
	"""Convert grid position to world position based on orientation plane.
	   Position is centered for the element size."""
	var rotated_size = _get_rotated_size(elem_size, rotation)
	var half_w = rotated_size[0] / 2.0
	var half_h = rotated_size[1] / 2.0
	var world_pos := Vector3.ZERO
	match orientation_plane:
		"XY":  # Wall-mounted (audio rack)
			world_pos = Vector3(grid_pos.x + half_w, grid_pos.y + half_h, 0) * grid_size
		"YZ":  # Side view (glass rack)
			world_pos = Vector3(0, grid_pos.y + half_h, grid_pos.x + half_w) * grid_size
		"XZ":  # Top-down (big pipes)
			world_pos = Vector3(grid_pos.x + half_w, 0, grid_pos.y + half_h) * grid_size
	return world_pos


func world_to_grid(world_pos: Vector3) -> Vector3i:
	"""Convert world position to grid position."""
	var grid_pos := Vector3i.ZERO
	match orientation_plane:
		"XY":
			grid_pos = Vector3i(
				roundi(world_pos.x / grid_size),
				roundi(world_pos.y / grid_size),
				0
			)
		"YZ":
			grid_pos = Vector3i(
				roundi(world_pos.z / grid_size),
				roundi(world_pos.y / grid_size),
				0
			)
		"XZ":
			grid_pos = Vector3i(
				roundi(world_pos.x / grid_size),
				roundi(world_pos.z / grid_size),
				0
			)
	return grid_pos


func get_plane_normal() -> Vector3:
	"""Get the normal vector for the orientation plane."""
	match orientation_plane:
		"XY": return Vector3.BACK   # Z forward
		"YZ": return Vector3.RIGHT  # X forward
		"XZ": return Vector3.UP     # Y up
	return Vector3.BACK
