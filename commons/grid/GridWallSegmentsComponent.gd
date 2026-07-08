# GridWallSegmentsComponent.gd
# INTERIOR wall segments from an optional `layers.walls` grid — the Two Point
# Museum move: partition a floor plate into wings with thin walls and doorways.
#
# Encoding (per cell, string): edge letters n/e/s/w = solid wall on that edge;
# UPPERCASE N/E/S/W = a doorway in that edge's wall. Empty/" " = nothing.
#   "e"  wall on the east edge
#   "nE" wall north + doorway east
# Shared edges are deduped (cell's "n" == northern neighbor's "s"); declare
# either side. Config via settings.wall_segments {height, thickness, color,
# door_width, door_height}. Purely additive: maps without a walls layer are
# untouched.

extends Node
class_name GridWallSegmentsComponent

var grid_system: Node3D
var data_component: GridDataComponent

var cube_size: float = 1.0
var gutter: float = 0.0
var wall_height: float = 3.2
var wall_thickness: float = 0.16
var door_width: float = 1.2
var door_height: float = 2.3
var wall_color: Color = Color(0.86, 0.82, 0.72)

var _container: Node3D
var _built_edges: Dictionary = {}
var _mat: StandardMaterial3D

signal wall_segments_complete(segment_count: int)

func initialize(grid_sys: Node3D, data_comp: GridDataComponent, settings: Dictionary = {}) -> void:
	grid_system = grid_sys
	data_component = data_comp
	cube_size = settings.get("cube_size", cube_size)
	gutter = settings.get("gutter", gutter)

func generate_segments(walls_layer: Array, structure_layer: Array, config: Dictionary = {}) -> void:
	if walls_layer.is_empty():
		return
	wall_height = float(config.get("height", wall_height))
	wall_thickness = float(config.get("thickness", wall_thickness))
	door_width = float(config.get("door_width", door_width))
	door_height = float(config.get("door_height", door_height))
	var c = config.get("color")
	if c is Array and c.size() >= 3:
		wall_color = Color(c[0], c[1], c[2])

	clear_segments()
	_container = Node3D.new()
	_container.name = "WallSegments"
	grid_system.add_child(_container)

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = wall_color
	_mat.roughness = 0.85

	var total := cube_size + gutter
	var count := 0
	for row in walls_layer.size():
		var cells = walls_layer[row]
		for col in cells.size():
			var code := str(cells[col]).strip_edges()
			if code.is_empty():
				continue
			for ch in code:
				var lower := String(ch).to_lower()
				if not lower in ["n", "e", "s", "w"]:
					continue
				var is_door := String(ch) != lower
				var key := _edge_key(col, row, lower)
				if _built_edges.has(key):
					continue
				_built_edges[key] = true
				_build_edge(col, row, lower, is_door, structure_layer, total)
				count += 1
	print("GridWallSegmentsComponent: built %d wall segments (%d with doors)" % [count, _door_count])
	wall_segments_complete.emit(count)

var _door_count := 0

# Normalize a cell edge to a unique key: north/south edges are horizontal
# edges keyed by the row ABOVE them; east/west are vertical edges keyed by
# the column to their WEST.
func _edge_key(col: int, row: int, edge: String) -> String:
	match edge:
		"n": return "h:%d:%d" % [col, row]
		"s": return "h:%d:%d" % [col, row + 1]
		"w": return "v:%d:%d" % [col, row]
		"e": return "v:%d:%d" % [col + 1, row]
	return "?"

func _cell_floor_y(col: int, row: int, structure_layer: Array, total: float) -> float:
	if row < structure_layer.size():
		var cells = structure_layer[row]
		if col < cells.size():
			var h := int(str(cells[col]).strip_edges().to_float())
			return GridCommon.surface_world_y(h, total, cube_size * 0.5)
	return 0.0

func _build_edge(col: int, row: int, edge: String, is_door: bool,
		structure_layer: Array, total: float) -> void:
	var center: Vector3 = GridCommon.grid_to_world_position(Vector3i(col, 0, row), cube_size, gutter)
	var base_y := _cell_floor_y(col, row, structure_layer, total)
	var half := total * 0.5
	var along_x := edge in ["n", "s"]
	var offset := Vector3.ZERO
	match edge:
		"n": offset = Vector3(0, 0, -half)
		"s": offset = Vector3(0, 0, half)
		"w": offset = Vector3(-half, 0, 0)
		"e": offset = Vector3(half, 0, 0)
	var mid := center + offset
	var seg_len := total + wall_thickness   # slight overlap closes corners

	if not is_door:
		_wall_box(mid, base_y, seg_len, wall_height, along_x)
		return

	_door_count += 1
	# doorway: two jambs + a lintel above the opening
	var jamb_len: float = maxf(0.05, (seg_len - door_width) * 0.5)
	var jamb_off: float = (door_width + jamb_len) * 0.5
	var side := Vector3(jamb_off, 0, 0) if along_x else Vector3(0, 0, jamb_off)
	_wall_box(mid + side, base_y, jamb_len, wall_height, along_x)
	_wall_box(mid - side, base_y, jamb_len, wall_height, along_x)
	var lintel_h: float = maxf(0.05, wall_height - door_height)
	_wall_box(mid, base_y + door_height, door_width, lintel_h, along_x)

func _wall_box(mid: Vector3, base_y: float, length: float, height: float, along_x: bool) -> void:
	var size := Vector3(length, height, wall_thickness) if along_x \
		else Vector3(wall_thickness, height, length)
	var body := StaticBody3D.new()
	body.position = Vector3(mid.x, base_y + height * 0.5, mid.z)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _mat
	body.add_child(mesh)
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col_shape.shape = shape
	body.add_child(col_shape)
	_container.add_child(body)

func clear_segments() -> void:
	if _container and is_instance_valid(_container):
		_container.queue_free()
	_container = null
	_built_edges.clear()
	_door_count = 0
