# floor_plan_space.gd
# Standalone artifact that loads a floor_plan.json and builds the complete 3D
# space (walls + floors) without any GridSystem dependency.
#
# Usage:
#   1. Place the scene, set plan_path to a floor_plan.json resource path
#   2. Or call apply_grid_config({"plan_path": "res://...", "wall_preset": "classical"})
#   3. On _ready() it loads the JSON and builds all rooms
#
# Wall rotations match FloorPlanLoader.gd: N=180, S=0, E=-90, W=90

extends Node3D
class_name FloorPlanSpace

const FacadeComposerScript = preload("res://commons/facade_parts/facade_composer.gd")
const MosaicFloorBuilder = preload("res://commons/grid/MosaicFloorBuilder.gd")

@export var plan_path: String = ""
@export var default_wall_preset: String = "classical"
@export var y_offset: float = -10.0  # EXTREME test — should be way underground
var _placed_as_artifact: bool = false  # Skip camera/lights when in a map

var _floor_plan_data: Dictionary = {}
var _built: bool = false


func _ready() -> void:
	_load_and_build()


func apply_grid_config(config: Dictionary) -> void:
	_placed_as_artifact = true
	if config.has("plan_path"):
		plan_path = str(config["plan_path"])
	if config.has("wall_preset"):
		default_wall_preset = str(config["wall_preset"])
	if config.has("y_offset"):
		y_offset = float(config["y_offset"])
	_load_and_build()


# ── Load & build ──────────────────────────────────────────────────────────────

func _load_and_build() -> void:
	# Clear previous build
	for child in get_children():
		child.queue_free()
	_built = false

	var path := plan_path
	if path.is_empty():
		# Auto-detect from current map if placed as artifact
		var current_map := _get_current_map_name()
		if not current_map.is_empty():
			path = "res://commons/maps/%s/floor_plan.json" % current_map
		else:
			path = "res://commons/maps/MANN_Gallery_Museum/floor_plan.json"

	if not _load_plan(path):
		push_warning("FloorPlanSpace: Could not load plan from %s" % path)
		return

	_build_all_rooms()
	_built = true


func _get_current_map_name() -> String:
	# Try to get the current map name from the GridSystem
	var gs = get_tree().get_first_node_in_group("grid_system") if is_inside_tree() else null
	if gs and gs.has_method("get_current_map_name"):
		return gs.get_current_map_name()
	# Try GameManager singleton
	if Engine.has_singleton("GameManager"):
		var gm = Engine.get_singleton("GameManager")
		if gm.has_method("get_current_map"):
			return gm.get_current_map()
	# Try to find GridSystem by name in the scene
	if is_inside_tree():
		var grid = get_tree().root.find_child("GridSystem", true, false)
		if grid and grid.has_node("GridDataComponent"):
			var data_comp = grid.get_node("GridDataComponent")
			if data_comp.has_method("get_current_map_name"):
				return data_comp.get_current_map_name()
	return ""


func _load_plan(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("FloorPlanSpace: File not found: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("FloorPlanSpace: JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		return false

	if json.data is Dictionary:
		_floor_plan_data = json.data
		return true

	push_error("FloorPlanSpace: Expected Dictionary root in %s" % path)
	return false


func _build_all_rooms() -> void:
	var rooms: Array = _floor_plan_data.get("rooms", [])
	if rooms.is_empty():
		print("FloorPlanSpace: No rooms defined")
		return

	var cell_size: float = float(_floor_plan_data.get("cell_size", 1.0))

	# Build per-room doorway lookups from the top-level doorways array
	var room_doorways: Dictionary = _build_room_doorway_map()

	var container := Node3D.new()
	container.name = "FloorPlanRooms"
	container.position.y = y_offset
	add_child(container)
	print("FloorPlanSpace: y_offset=%s, container.y=%s, global_pos=%s" % [y_offset, container.position.y, global_position])

	var global_seen_edges: Dictionary = {}  # Shared across all rooms to prevent double walls

	for room in rooms:
		if not room is Dictionary:
			continue
		var room_id: String = str(room.get("id", "room"))
		var room_node := Node3D.new()
		room_node.name = "Room_%s" % room_id
		container.add_child(room_node)

		_place_room_floor(room, room_node, cell_size)
		_place_room_ceiling(room, room_node, cell_size)
		_generate_room_walls(room, room_node, cell_size, room_doorways.get(room_id, []), global_seen_edges)
		_place_room_wall_patterns(room, room_node, cell_size)
		_build_exhibit_walls(room, room_node, cell_size)

	print("FloorPlanSpace: Built %d rooms from floor plan" % rooms.size())

	# Add a simple fly camera only when running standalone (not placed in a map)
	if not _placed_as_artifact and not get_viewport().get_camera_3d():
		_add_fly_camera(rooms, cell_size)


# ── Doorway mapping ──────────────────────────────────────────────────────────
# The floor_plan.json has top-level doorways like:
#   { "from": "room_a", "to": "corridor", "cells": [[3, 5]] }
# We need per-room doorway edges: { row, col, direction }
# A doorway cell between two rooms means the wall edge separating them is open.

func _build_room_doorway_map() -> Dictionary:
	var result: Dictionary = {}  # room_id -> Array of {row, col, direction}

	# First build cell->room lookup
	var cell_to_room: Dictionary = {}
	var rooms: Array = _floor_plan_data.get("rooms", [])
	for room in rooms:
		if not room is Dictionary:
			continue
		var room_id: String = str(room.get("id", "room"))
		var cells: Array = room.get("cells", [])
		for cell in cells:
			if cell is Array and cell.size() >= 2:
				cell_to_room["%d,%d" % [int(cell[0]), int(cell[1])]] = room_id

	var doorways: Array = _floor_plan_data.get("doorways", [])
	for dw in doorways:
		if not dw is Dictionary:
			continue
		var from_id: String = str(dw.get("from", ""))
		var to_id: String = str(dw.get("to", ""))
		var dw_cells: Array = dw.get("cells", [])

		for dc in dw_cells:
			if not dc is Array or dc.size() < 2:
				continue
			var row: int = int(dc[0])
			var col: int = int(dc[1])
			var cell_key := "%d,%d" % [row, col]

			# Determine which room this cell belongs to and the direction toward the other room
			var cell_room: String = cell_to_room.get(cell_key, "")

			# The doorway cell could belong to either room. Check neighbors.
			var dirs := {"N": [row - 1, col], "S": [row + 1, col], "E": [row, col + 1], "W": [row, col - 1]}
			for dir in dirs:
				var nr: int = dirs[dir][0]
				var nc: int = dirs[dir][1]
				var nkey := "%d,%d" % [nr, nc]
				var neighbor_room: String = cell_to_room.get(nkey, "")

				# If this cell and neighbor belong to different rooms involved in this doorway
				if cell_room != "" and neighbor_room != "" and cell_room != neighbor_room:
					if (cell_room == from_id and neighbor_room == to_id) or \
					   (cell_room == to_id and neighbor_room == from_id):
						# Add doorway edge for this cell's room
						if not result.has(cell_room):
							result[cell_room] = []
						result[cell_room].append({"row": row, "col": col, "direction": dir})
						# Add the reciprocal for neighbor room
						var opp_dir := _opposite_dir(dir)
						if not result.has(neighbor_room):
							result[neighbor_room] = []
						result[neighbor_room].append({"row": nr, "col": nc, "direction": opp_dir})

	return result


func _opposite_dir(dir: String) -> String:
	match dir:
		"N": return "S"
		"S": return "N"
		"E": return "W"
		"W": return "E"
	return dir


# ── Floor placement ──────────────────────────────────────────────────────────

func _place_room_floor(room: Dictionary, parent: Node3D, cell_size: float) -> void:
	var cells: Array = room.get("cells", [])
	if cells.is_empty():
		return

	# Compute bounding rect from ALL cells
	var min_row: int = 999999
	var max_row: int = -999999
	var min_col: int = 999999
	var max_col: int = -999999

	for cell in cells:
		if not cell is Array or cell.size() < 2:
			continue
		var row: int = int(cell[0])
		var col: int = int(cell[1])
		min_row = mini(min_row, row)
		max_row = maxi(max_row, row)
		min_col = mini(min_col, col)
		max_col = maxi(max_col, col)

	if min_row > max_row:
		return

	var cols_span: int = max_col - min_col + 1
	var rows_span: int = max_row - min_row + 1
	var wt: float = _floor_plan_data.get("wall_thickness", 0.5)
	var bbox_area: int = cols_span * rows_span
	# Rooms with doorway cells may have slightly more cells than the bbox.
	# Use 0.7 threshold to handle rooms with doorway extensions gracefully.
	# True L-shapes and corridors will have much lower ratios (< 0.5).
	var is_rectangular: bool = cells.size() >= bbox_area * 0.7 and float(bbox_area) / float(cells.size()) < 2.0

	# Inset floor by half wall thickness so it fits inside the walls
	var room_w: float = cols_span * cell_size - wt
	var room_h: float = rows_span * cell_size - wt
	var center_x: float = (min_col + cols_span * 0.5) * cell_size
	var center_z: float = (min_row + rows_span * 0.5) * cell_size

	# Non-rectangular rooms (L-shapes, corridors): render per-cell quads
	if not is_rectangular:
		_place_per_cell_floor(cells, parent, cell_size, room)
		return

	# Try mosaic composition first (rectangular rooms only)
	var mosaic_comp: String = room.get("mosaic_composition", "")
	if not mosaic_comp.is_empty():
		var comp_path := "res://commons/patterns/mosaics/%s.json" % mosaic_comp
		var floor_node := MosaicFloorBuilder.build_floor(comp_path, Vector2(room_w, room_h), parent)
		if floor_node:
			floor_node.position = Vector3(center_x, 0.0, center_z)
			return

	# Fall back to artifact-based floor pattern
	var floor_pattern: String = str(room.get("floor_pattern", ""))
	if floor_pattern.is_empty():
		_place_fallback_floor(parent, center_x, center_z, room_w, room_h)
		return

	var scene := _load_artifact_scene(floor_pattern)
	if not scene:
		push_warning("FloorPlanSpace: Floor pattern '%s' not found, using fallback" % floor_pattern)
		_place_fallback_floor(parent, center_x, center_z, room_w, room_h)
		return

	var floor_instance: Node3D = scene.instantiate()
	parent.add_child(floor_instance)

	var floor_config: Dictionary = room.get("floor_config", {}).duplicate()
	floor_config["floor_size"] = [room_w, room_h]

	if floor_instance.has_method("apply_grid_config"):
		floor_instance.apply_grid_config(floor_config)

	floor_instance.position = Vector3(center_x, 0.005, center_z)  # Artifact floor above base
	floor_instance.name = "Floor_%s" % str(room.get("id", "room"))

	print("FloorPlanSpace: Placed floor '%s' at (%.1f, %.1f) size %.1fx%.1f" % [
		floor_pattern, center_x, center_z, room_w, room_h
	])


func _place_per_cell_floor(cells: Array, parent: Node3D, cell_size: float, room: Dictionary) -> void:
	## Render individual cell quads for non-rectangular rooms (L-shapes, corridors).
	var mat := StandardMaterial3D.new()
	var color_hex: String = str(room.get("color", "#B0A890"))
	mat.albedo_color = Color.html(color_hex) if color_hex.begins_with("#") else Color(0.7, 0.65, 0.55)
	mat.roughness = 0.85

	var verts := PackedVector3Array()
	var y: float = 0.001
	for cell in cells:
		if not cell is Array or cell.size() < 2:
			continue
		var r: int = int(cell[0])
		var c: int = int(cell[1])
		var x0: float = c * cell_size
		var z0: float = r * cell_size
		var x1: float = x0 + cell_size
		var z1: float = z0 + cell_size
		verts.append(Vector3(x0, y, z0))
		verts.append(Vector3(x1, y, z0))
		verts.append(Vector3(x1, y, z1))
		verts.append(Vector3(x0, y, z0))
		verts.append(Vector3(x1, y, z1))
		verts.append(Vector3(x0, y, z1))

	if verts.is_empty():
		return

	var arr_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr_mesh.surface_set_material(0, mat)

	var mi := MeshInstance3D.new()
	mi.mesh = arr_mesh
	mi.name = "PerCellFloor_%s" % str(room.get("id", "room"))
	parent.add_child(mi)

	print("FloorPlanSpace: Per-cell floor for '%s' (%d cells)" % [str(room.get("id", "")), cells.size()])


func _place_fallback_floor(parent: Node3D, cx: float, cz: float,
		floor_w: float, floor_h: float) -> void:
	var mesh_inst := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(floor_w, floor_h)
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.65, 0.55)
	mat.roughness = 0.9
	mesh_inst.material_override = mat

	mesh_inst.position = Vector3(cx, 0.001, cz)  # Base floor slightly above ground
	mesh_inst.name = "FallbackFloor"
	parent.add_child(mesh_inst)


# ── Ceiling placement ────────────────────────────────────────────────────────

func _place_room_ceiling(room: Dictionary, parent: Node3D, cell_size: float) -> void:
	var ceiling_pattern: String = str(room.get("ceiling_pattern", ""))
	if ceiling_pattern.is_empty():
		return

	var cells: Array = room.get("cells", [])
	if cells.is_empty():
		return

	# Compute bounding rect
	var min_row: int = 999999
	var max_row: int = -999999
	var min_col: int = 999999
	var max_col: int = -999999
	for cell in cells:
		if not cell is Array or cell.size() < 2:
			continue
		var row: int = int(cell[0])
		var col: int = int(cell[1])
		min_row = mini(min_row, row)
		max_row = maxi(max_row, row)
		min_col = mini(min_col, col)
		max_col = maxi(max_col, col)

	if min_row > max_row:
		return

	var cols_span: int = max_col - min_col + 1
	var rows_span: int = max_row - min_row + 1
	var wt: float = _floor_plan_data.get("wall_thickness", 0.5)
	var wall_height: float = float(room.get("wall_height", 3.0))

	var room_w: float = cols_span * cell_size - wt
	var room_h: float = rows_span * cell_size - wt
	var center_x: float = (min_col + cols_span * 0.5) * cell_size
	var center_z: float = (min_row + rows_span * 0.5) * cell_size

	var scene := _load_artifact_scene(ceiling_pattern)
	if not scene:
		push_warning("FloorPlanSpace: Ceiling pattern '%s' not found, skipping" % ceiling_pattern)
		return

	var ceiling_instance: Node3D = scene.instantiate()
	parent.add_child(ceiling_instance)

	var ceiling_config: Dictionary = room.get("ceiling_config", {}).duplicate()
	ceiling_config["floor_size"] = [room_w, room_h]

	if ceiling_instance.has_method("apply_grid_config"):
		ceiling_instance.apply_grid_config(ceiling_config)

	# Place at wall_height, flipped upside down
	ceiling_instance.position = Vector3(center_x, wall_height, center_z)
	ceiling_instance.rotation_degrees.x = 180.0
	ceiling_instance.name = "Ceiling_%s" % str(room.get("id", "room"))

	print("FloorPlanSpace: Placed ceiling '%s' at (%.1f, %.1f) y=%.1f size %.1fx%.1f" % [
		ceiling_pattern, center_x, center_z, wall_height, room_w, room_h
	])


# ── Wall pattern placement ───────────────────────────────────────────────────

func _place_room_wall_patterns(room: Dictionary, parent: Node3D, cell_size: float) -> void:
	var wall_pattern: String = str(room.get("wall_pattern", ""))
	if wall_pattern.is_empty():
		return

	var cells: Array = room.get("cells", [])
	if cells.is_empty():
		return

	var wall_height: float = float(room.get("wall_height", 3.0))
	var wt: float = _floor_plan_data.get("wall_thickness", 0.5)

	var scene := _load_artifact_scene(wall_pattern)
	if not scene:
		push_warning("FloorPlanSpace: Wall pattern '%s' not found, skipping" % wall_pattern)
		return

	# Build cell set for boundary detection
	var cell_set: Dictionary = {}
	for cell in cells:
		if cell is Array and cell.size() >= 2:
			cell_set["%d,%d" % [int(cell[0]), int(cell[1])]] = true

	# Find boundary edges (same logic as wall generation)
	var boundary_edges: Array = []
	for cell in cells:
		if not cell is Array or cell.size() < 2:
			continue
		var row: int = int(cell[0])
		var col: int = int(cell[1])
		var neighbors := {
			"N": "%d,%d" % [row - 1, col],
			"S": "%d,%d" % [row + 1, col],
			"E": "%d,%d" % [row, col + 1],
			"W": "%d,%d" % [row, col - 1],
		}
		for dir in neighbors:
			if not cell_set.has(neighbors[dir]):
				boundary_edges.append({"row": row, "col": col, "dir": dir})

	# Group into segments for wall-sized pattern panels
	var segments := _group_wall_pattern_segments(boundary_edges)

	var wall_patterns_container := Node3D.new()
	wall_patterns_container.name = "WallPatterns"
	parent.add_child(wall_patterns_container)

	var pattern_count: int = 0
	for seg in segments:
		var dir: String = seg["dir"]
		var edges: Array = seg["edges"]
		if edges.is_empty():
			continue

		var seg_length: int = edges.size()
		var seg_meters: float = seg_length * cell_size
		var start_row: int = edges[0]["row"]
		var start_col: int = edges[0]["col"]

		# Calculate wall center position and rotation (same as wall placement)
		var wall_pos: Vector3
		var wall_rot_y: float
		# Pattern offset from wall surface: half wall thickness + tiny gap inward
		var pattern_inset: float = wt * 0.5 + 0.01

		match dir:
			"N":
				var cx: float = (start_col + seg_length * 0.5) * cell_size
				var cz: float = start_row * cell_size + pattern_inset
				wall_pos = Vector3(cx, wall_height * 0.5, cz)
				wall_rot_y = 0.0
			"S":
				var cx: float = (start_col + seg_length * 0.5) * cell_size
				var cz: float = (start_row + 1) * cell_size - pattern_inset
				wall_pos = Vector3(cx, wall_height * 0.5, cz)
				wall_rot_y = 180.0
			"E":
				var cx: float = (start_col + 1) * cell_size - pattern_inset
				var cz: float = (start_row + seg_length * 0.5) * cell_size
				wall_pos = Vector3(cx, wall_height * 0.5, cz)
				wall_rot_y = 90.0
			"W":
				var cx: float = start_col * cell_size + pattern_inset
				var cz: float = (start_row + seg_length * 0.5) * cell_size
				wall_pos = Vector3(cx, wall_height * 0.5, cz)
				wall_rot_y = -90.0

		var pattern_instance: Node3D = scene.instantiate()
		wall_patterns_container.add_child(pattern_instance)

		# Configure the pattern to fit the wall dimensions
		var pattern_config: Dictionary = room.get("wall_config", {}).duplicate()
		pattern_config["floor_size"] = [seg_meters, wall_height]

		if pattern_instance.has_method("apply_grid_config"):
			pattern_instance.apply_grid_config(pattern_config)

		pattern_instance.position = wall_pos
		# Rotate upright (stand on wall face) then orient to wall direction
		pattern_instance.rotation_degrees = Vector3(-90.0, wall_rot_y, 0.0)
		pattern_instance.name = "WallPattern_%s_%d" % [dir, pattern_count]
		pattern_count += 1

	print("FloorPlanSpace: Placed %d wall pattern panels for room '%s'" % [
		pattern_count, str(room.get("id", "room"))
	])


## Group boundary edges into contiguous segments for wall patterns (no doorway filtering).
func _group_wall_pattern_segments(edges: Array) -> Array:
	var by_dir: Dictionary = { "N": [], "S": [], "E": [], "W": [] }
	for e in edges:
		var dir: String = e["dir"]
		if by_dir.has(dir):
			by_dir[dir].append(e)

	var all_segments: Array = []

	for dir in ["N", "S"]:
		var dir_edges: Array = by_dir[dir]
		if dir_edges.is_empty():
			continue
		var by_row: Dictionary = {}
		for e in dir_edges:
			var r: int = e["row"]
			if not by_row.has(r):
				by_row[r] = []
			by_row[r].append(e)
		for r in by_row:
			var row_edges: Array = by_row[r]
			row_edges.sort_custom(func(a, b): return a["col"] < b["col"])
			var current_seg: Array = []
			for e in row_edges:
				if current_seg.size() > 0:
					var last_col: int = current_seg[-1]["col"]
					if e["col"] != last_col + 1:
						all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })
						current_seg.clear()
				current_seg.append(e)
			if current_seg.size() > 0:
				all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })

	for dir in ["E", "W"]:
		var dir_edges: Array = by_dir[dir]
		if dir_edges.is_empty():
			continue
		var by_col: Dictionary = {}
		for e in dir_edges:
			var c: int = e["col"]
			if not by_col.has(c):
				by_col[c] = []
			by_col[c].append(e)
		for c in by_col:
			var col_edges: Array = by_col[c]
			col_edges.sort_custom(func(a, b): return a["row"] < b["row"])
			var current_seg: Array = []
			for e in col_edges:
				if current_seg.size() > 0:
					var last_row: int = current_seg[-1]["row"]
					if e["row"] != last_row + 1:
						all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })
						current_seg.clear()
				current_seg.append(e)
			if current_seg.size() > 0:
				all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })

	return all_segments


# ── Wall generation ──────────────────────────────────────────────────────────

func _generate_room_walls(room: Dictionary, parent: Node3D, cell_size: float,
		doorway_edges: Array, global_seen_edges: Dictionary = {}) -> void:
	var cells: Array = room.get("cells", [])
	if cells.is_empty():
		return

	var wall_height: float = float(room.get("wall_height", 3.0))
	var wall_preset: String = str(room.get("wall_preset", default_wall_preset))
	var wall_thickness: float = float(_floor_plan_data.get("wall_thickness", 0.5))

	# Build cell set for fast lookup
	var cell_set: Dictionary = {}
	for cell in cells:
		if cell is Array and cell.size() >= 2:
			cell_set["%d,%d" % [int(cell[0]), int(cell[1])]] = true

	# Build doorway set from the doorway_edges array
	var doorway_set: Dictionary = {}
	for dw in doorway_edges:
		if dw is Dictionary:
			var key := "%d,%d,%s" % [int(dw.get("row", 0)), int(dw.get("col", 0)), str(dw.get("direction", ""))]
			doorway_set[key] = true

	# Also check room-level doorways (legacy format)
	var room_doorways: Array = room.get("doorways", [])
	for dw in room_doorways:
		if dw is Dictionary:
			var key := "%d,%d,%s" % [int(dw.get("row", 0)), int(dw.get("col", 0)), str(dw.get("direction", ""))]
			doorway_set[key] = true

	# Open edges — exterior entrances where no wall should be built
	var open_edges: Array = room.get("open_edges", [])
	for oe in open_edges:
		if oe is Dictionary:
			var key := "%d,%d,%s" % [int(oe.get("row", 0)), int(oe.get("col", 0)), str(oe.get("dir", ""))]
			doorway_set[key] = true

	# Find boundary edges
	var boundary_edges: Array = []
	for cell in cells:
		if not cell is Array or cell.size() < 2:
			continue
		var row: int = int(cell[0])
		var col: int = int(cell[1])

		var neighbors := {
			"N": "%d,%d" % [row - 1, col],
			"S": "%d,%d" % [row + 1, col],
			"E": "%d,%d" % [row, col + 1],
			"W": "%d,%d" % [row, col - 1],
		}

		for dir in neighbors:
			if not cell_set.has(neighbors[dir]):
				var dw_key := "%d,%d,%s" % [row, col, dir]
				var is_doorway: bool = doorway_set.has(dw_key)
				boundary_edges.append({
					"row": row,
					"col": col,
					"dir": dir,
					"is_doorway": is_doorway,
				})

	# Deduplicate shared edges globally (prevents double walls between rooms)
	var unique_edges: Array = []
	for e in boundary_edges:
		var canon_key: String = _canonical_edge_key(e["row"], e["col"], e["dir"])
		if not global_seen_edges.has(canon_key):
			global_seen_edges[canon_key] = true
			unique_edges.append(e)
	boundary_edges = unique_edges

	# Group into segments
	var segments := _group_into_segments(boundary_edges)

	# Build walls
	var wall_container := Node3D.new()
	wall_container.name = "Walls"
	parent.add_child(wall_container)

	for seg in segments:
		_build_wall_segment(seg, wall_container, cell_size, wall_height, wall_preset, wall_thickness)

	print("FloorPlanSpace: Generated %d wall segments for room '%s'" % [
		segments.size(), str(room.get("id", "room"))
	])


## Group boundary edges into contiguous wall segments.
func _group_into_segments(edges: Array) -> Array:
	var by_dir: Dictionary = { "N": [], "S": [], "E": [], "W": [] }
	for e in edges:
		var dir: String = e["dir"]
		if by_dir.has(dir):
			by_dir[dir].append(e)

	var all_segments: Array = []

	# N/S walls run along columns (same row), sort by col
	for dir in ["N", "S"]:
		var dir_edges: Array = by_dir[dir]
		if dir_edges.is_empty():
			continue

		var by_row: Dictionary = {}
		for e in dir_edges:
			var r: int = e["row"]
			if not by_row.has(r):
				by_row[r] = []
			by_row[r].append(e)

		for r in by_row:
			var row_edges: Array = by_row[r]
			row_edges.sort_custom(func(a, b): return a["col"] < b["col"])

			var current_seg: Array = []
			for e in row_edges:
				if e["is_doorway"]:
					if current_seg.size() > 0:
						all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })
						current_seg.clear()
					continue
				if current_seg.size() > 0:
					var last_col: int = current_seg[-1]["col"]
					if e["col"] != last_col + 1:
						all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })
						current_seg.clear()
				current_seg.append(e)
			if current_seg.size() > 0:
				all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })

	# E/W walls run along rows (same col), sort by row
	for dir in ["E", "W"]:
		var dir_edges: Array = by_dir[dir]
		if dir_edges.is_empty():
			continue

		var by_col: Dictionary = {}
		for e in dir_edges:
			var c: int = e["col"]
			if not by_col.has(c):
				by_col[c] = []
			by_col[c].append(e)

		for c in by_col:
			var col_edges: Array = by_col[c]
			col_edges.sort_custom(func(a, b): return a["row"] < b["row"])

			var current_seg: Array = []
			for e in col_edges:
				if e["is_doorway"]:
					if current_seg.size() > 0:
						all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })
						current_seg.clear()
					continue
				if current_seg.size() > 0:
					var last_row: int = current_seg[-1]["row"]
					if e["row"] != last_row + 1:
						all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })
						current_seg.clear()
				current_seg.append(e)
			if current_seg.size() > 0:
				all_segments.append({ "dir": dir, "edges": current_seg.duplicate() })

	return all_segments


## Build a single wall segment.
## Wall rotations: N=180, S=0, E=-90, W=90
func _build_wall_segment(segment: Dictionary, parent: Node3D,
		cell_size: float, wall_height: float, wall_preset: String,
		wall_thickness: float) -> void:
	var dir: String = segment["dir"]
	var edges: Array = segment["edges"]
	if edges.is_empty():
		return

	var seg_length: int = edges.size()
	var seg_meters: float = seg_length * cell_size

	var start_row: int = edges[0]["row"]
	var start_col: int = edges[0]["col"]

	# N/S walls extend by half wall_thickness on each end to close corner gaps.
	# E/W walls stay exact length to butt against the extended N/S walls.
	var corner_ext: float = 0.0
	if dir == "N" or dir == "S":
		corner_ext = wall_thickness * 0.5
	var total_length: float = seg_meters + corner_ext * 2.0

	var wall_pos: Vector3
	var wall_rot_y: float

	match dir:
		"N":
			var cx: float = (start_col + seg_length * 0.5) * cell_size
			var cz: float = start_row * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = 180.0
		"S":
			var cx: float = (start_col + seg_length * 0.5) * cell_size
			var cz: float = (start_row + 1) * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = 0.0
		"E":
			var cx: float = (start_col + 1) * cell_size
			var cz: float = (start_row + seg_length * 0.5) * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = -90.0
		"W":
			var cx: float = start_col * cell_size
			var cz: float = (start_row + seg_length * 0.5) * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = 90.0

	if wall_preset != "default" and wall_preset != "":
		_build_facade_wall(parent, wall_pos, wall_rot_y, total_length, wall_height, wall_preset, wall_thickness)
	else:
		_build_simple_wall(parent, wall_pos, wall_rot_y, total_length, wall_height, wall_thickness)


## Build a facade wall from a preset JSON.
func _build_facade_wall(parent: Node3D, pos: Vector3, rot_y: float,
		width: float, height: float, preset_name: String,
		wall_thickness: float = 0.5) -> void:
	var preset_path := "res://commons/facade_parts/presets/%s.json" % preset_name

	if not FileAccess.file_exists(preset_path):
		push_warning("FloorPlanSpace: Facade preset '%s' not found at %s, using simple wall" % [
			preset_name, preset_path
		])
		_build_simple_wall(parent, pos, rot_y, width, height, wall_thickness)
		return

	var file := FileAccess.open(preset_path, FileAccess.READ)
	if not file:
		_build_simple_wall(parent, pos, rot_y, width, height, wall_thickness)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK or not json.data is Dictionary:
		_build_simple_wall(parent, pos, rot_y, width, height, wall_thickness)
		return

	var preset_data: Dictionary = json.data.duplicate(true)

	if not preset_data.has("facade"):
		preset_data["facade"] = {}
	preset_data["facade"]["total_width"] = width
	preset_data["facade"]["total_height"] = height

	var bays: int = maxi(1, roundi(width / 3.0))
	preset_data["facade"]["bays"] = bays

	var facade_node: Node3D = FacadeComposerScript.build_from_dict(preset_data)

	var wall_root := Node3D.new()
	wall_root.name = "FacadeWall_%s" % preset_name
	parent.add_child(wall_root)

	wall_root.position = pos
	wall_root.rotation_degrees.y = rot_y

	facade_node.position = Vector3(-width * 0.5, -height * 0.5, 0.0)
	wall_root.add_child(facade_node)


## Build a simple box wall (fallback).
func _build_simple_wall(parent: Node3D, pos: Vector3, rot_y: float,
		width: float, height: float, wall_thickness: float = 0.5) -> void:
	var wall_root := Node3D.new()
	wall_root.name = "SimpleWall"
	parent.add_child(wall_root)

	wall_root.position = pos
	wall_root.rotation_degrees.y = rot_y

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, wall_thickness)
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.58, 0.52)
	mat.roughness = 0.85
	mat.metallic = 0.05
	mesh_inst.material_override = mat
	wall_root.add_child(mesh_inst)

	# Wall colliders disabled — players can walk through walls for now
	#var body := StaticBody3D.new()
	#body.name = "WallCollision"
	#var col_shape := CollisionShape3D.new()
	#var shape := BoxShape3D.new()
	#shape.size = Vector3(width, height, wall_thickness)
	#col_shape.shape = shape
	#body.add_child(col_shape)
	#wall_root.add_child(body)


# ── Freestanding exhibit walls ─────────────────────────────────────────────

func _build_exhibit_walls(room: Dictionary, parent: Node3D, cell_size: float) -> void:
	var exhibit_walls: Array = room.get("exhibit_walls", [])
	if exhibit_walls.is_empty():
		return

	var wall_thickness: float = float(_floor_plan_data.get("wall_thickness", 0.5))
	var container := Node3D.new()
	container.name = "ExhibitWalls"
	parent.add_child(container)

	for i in exhibit_walls.size():
		var ew: Dictionary = exhibit_walls[i]
		if not ew is Dictionary:
			continue

		var preset_name: String = str(ew.get("preset", default_wall_preset))
		var ew_width: float = float(ew.get("width", 3.0))
		var ew_height: float = float(ew.get("height", 3.0))
		var ew_rotation: float = float(ew.get("rotation", 0.0))

		# Position from [row, col] cell coordinates
		var pos_arr: Array = ew.get("position", [0, 0])
		var ew_row: float = float(pos_arr[0]) if pos_arr.size() > 0 else 0.0
		var ew_col: float = float(pos_arr[1]) if pos_arr.size() > 1 else 0.0

		# Convert cell coords to world position (cell center)
		var world_x: float = (ew_col + 0.5) * cell_size
		var world_z: float = (ew_row + 0.5) * cell_size
		var ew_y_offset: float = float(ew.get("y_offset", 0.0))
		var world_pos := Vector3(world_x, ew_height * 0.5 + ew_y_offset, world_z)

		# Build the facade wall
		_build_facade_wall(container, world_pos, ew_rotation, ew_width, ew_height, preset_name, wall_thickness)

		# No pedestal for floating facades
		if ew_y_offset < 0.01:
			_build_exhibit_pedestal(container, world_x, world_z, ew_width, wall_thickness, ew_rotation)

	print("FloorPlanSpace: Placed %d exhibit walls in room '%s'" % [
		exhibit_walls.size(), str(room.get("id", "room"))
	])


## Build a thin dark pedestal base under an exhibit wall.
func _build_exhibit_pedestal(parent: Node3D, cx: float, cz: float,
		wall_width: float, wall_thickness: float, rot_y: float) -> void:
	var pedestal_height: float = 0.05
	var pedestal_margin: float = 0.1  # slightly wider than the wall on each side

	var pedestal_root := Node3D.new()
	pedestal_root.name = "ExhibitPedestal"
	parent.add_child(pedestal_root)

	pedestal_root.position = Vector3(cx, pedestal_height * 0.5, cz)
	pedestal_root.rotation_degrees.y = rot_y

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(
		wall_width + pedestal_margin * 2.0,
		pedestal_height,
		wall_thickness + pedestal_margin * 2.0
	)
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.13, 0.12)
	mat.roughness = 0.7
	mat.metallic = 0.1
	mesh_inst.material_override = mat
	pedestal_root.add_child(mesh_inst)


# ── Edge deduplication helper ──────────────────────────────────────────────

func _canonical_edge_key(row: int, col: int, dir: String) -> String:
	var nr: int = row
	var nc: int = col
	var opp: String = dir
	match dir:
		"N":
			nr = row - 1; nc = col; opp = "S"
		"S":
			nr = row + 1; nc = col; opp = "N"
		"E":
			nr = row; nc = col + 1; opp = "W"
		"W":
			nr = row; nc = col - 1; opp = "E"
	var key_a := "%d,%d,%s" % [row, col, dir]
	var key_b := "%d,%d,%s" % [nr, nc, opp]
	return key_a if key_a < key_b else key_b


# ── Artifact loading helper ──────────────────────────────────────────────────

func _load_artifact_scene(lookup_name: String) -> PackedScene:
	# Try standard path: artifacts/{name}/{name}.tscn
	var scene_path := "res://commons/artifacts/%s/%s.tscn" % [lookup_name, lookup_name]
	if ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene:
			return scene

	# Try pompeii_mosaic_floor subfolder (all floor patterns live here)
	var mosaic_path := "res://commons/artifacts/pompeii_mosaic_floor/%s.tscn" % lookup_name
	if ResourceLoader.exists(mosaic_path):
		var scene := load(mosaic_path) as PackedScene
		if scene:
			return scene

	# Try flat path
	var alt_path := "res://commons/artifacts/%s.tscn" % lookup_name
	if ResourceLoader.exists(alt_path):
		var scene := load(alt_path) as PackedScene
		if scene:
			return scene

	# Try registry lookup
	var registry_path := "res://commons/artifacts/registry/arrays.json"
	if FileAccess.file_exists(registry_path):
		var file := FileAccess.open(registry_path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			var artifacts: Dictionary = json.data.get("artifacts", {})
			if artifacts.has(lookup_name):
				var entry: Dictionary = artifacts[lookup_name]
				var reg_scene: String = str(entry.get("scene", ""))
				if not reg_scene.is_empty() and ResourceLoader.exists(reg_scene):
					var scene := load(reg_scene) as PackedScene
					if scene:
						return scene

	return null


# ── Fly camera for standalone viewing ─────────────────────────────────────

func _add_fly_camera(rooms: Array, cell_size: float) -> void:
	# ── Compute bounding box of ALL rooms ──
	var min_row: int = 999999
	var max_row: int = -999999
	var min_col: int = 999999
	var max_col: int = -999999
	for room in rooms:
		for cell in room.get("cells", []):
			if cell is Array and cell.size() >= 2:
				var r: int = int(cell[0])
				var c: int = int(cell[1])
				min_row = mini(min_row, r)
				max_row = maxi(max_row, r)
				min_col = mini(min_col, c)
				max_col = maxi(max_col, c)

	if min_row > max_row:
		return  # no cells found

	# World-space extents
	var world_min_x: float = min_col * cell_size
	var world_max_x: float = (max_col + 1) * cell_size
	var world_min_z: float = min_row * cell_size
	var world_max_z: float = (max_row + 1) * cell_size

	var cx: float = (world_min_x + world_max_x) * 0.5
	var cz: float = (world_min_z + world_max_z) * 0.5
	var span_x: float = world_max_x - world_min_x
	var span_z: float = world_max_z - world_min_z
	var span_max: float = maxf(span_x, span_z)

	# ── Camera: high enough and far back to see everything with margin ──
	var cam_height: float = span_max * 0.7 + 4.0
	var cam_back: float = span_max * 0.55 + 6.0
	var cam_pitch: float = -atan2(cam_height, cam_back) * 180.0 / PI  # look toward center

	var cam := Camera3D.new()
	cam.name = "FlyCamera"
	cam.current = true
	cam.fov = 50.0
	cam.position = Vector3(cx, cam_height, cz + cam_back)
	cam.rotation_degrees = Vector3(cam_pitch, 0, 0)
	add_child(cam)

	# ── Main directional light (sun) — warm, slightly stronger ──
	var sun := DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.5
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	add_child(sun)

	# ── Secondary fill light from opposite side — cooler, softer ──
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.75, 0.82, 1.0)
	fill.light_energy = 0.6
	fill.rotation_degrees = Vector3(-35, -140, 0)
	fill.shadow_enabled = false
	add_child(fill)

	# ── Environment: warm ambient, warm background, subtle fog ──
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.ambient_light_color = Color(0.95, 0.88, 0.75)
	environment.ambient_light_energy = 0.55
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.22, 0.2, 0.18)
	# Subtle depth fog
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.25, 0.23, 0.2)
	environment.fog_density = 0.006
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 6.0
	env.environment = environment
	add_child(env)

	print("FloorPlanSpace: Camera at (%.1f, %.1f, %.1f), museum span %.0fx%.0f m" % [
		cx, cam_height, cz + cam_back, span_x, span_z
	])
