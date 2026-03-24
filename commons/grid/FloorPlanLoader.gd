# FloorPlanLoader.gd
# Reads floor_plan.json from a map directory and generates 3D rooms with
# facade walls and mosaic floors.
#
# Integration point in GridSystem.gd:
#   After wall generation completes (in _on_wall_complete or _handle_player_spawn),
#   FloorPlanLoader.apply_floor_plan() should be called to overlay room-specific
#   floors and facade walls on top of the base grid structure.
#
#   Example integration (in GridSystem._on_wall_complete):
#     if floor_plan_loader and floor_plan_loader.has_floor_plan:
#         floor_plan_loader.apply_floor_plan(self, cube_size + gutter)
#
# Coordinate system (matches GridStructureComponent):
#   Grid: structure_layout[row][col], row 0 is top
#   World: Vector3(col * cell_size, y, row * cell_size)
#
# floor_plan.json schema:
# {
#   "rooms": [
#     {
#       "id": "atrium",
#       "cells": [[row, col], [row, col], ...],
#       "floor_pattern": "pompeii_mosaic_floor",
#       "floor_config": { "tiles_short": 12, "border_widths": [2, 1, 2], ... },
#       "wall_preset": "classical",
#       "wall_height": 4.0,
#       "doorways": [
#         { "row": 3, "col": 5, "direction": "E" },
#         ...
#       ]
#     },
#     ...
#   ]
# }

class_name FloorPlanLoader
extends Node

const FacadeComposerScript = preload("res://commons/facade_parts/facade_composer.gd")
const MosaicFloorBuilder = preload("res://commons/grid/MosaicFloorBuilder.gd")

var _floor_plan_data: Dictionary = {}
var has_floor_plan: bool = false


# ── Public API ──────────────────────────────────────────────────────────────

## Try to load floor_plan.json from the given map directory.
## Returns false if not found (map runs without floor plan features).
func load_floor_plan(map_dir: String) -> bool:
	var path := map_dir.path_join("floor_plan.json")

	if not FileAccess.file_exists(path):
		has_floor_plan = false
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("FloorPlanLoader: Cannot open %s" % path)
		has_floor_plan = false
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("FloorPlanLoader: JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		has_floor_plan = false
		return false

	if json.data is Dictionary:
		_floor_plan_data = json.data
		has_floor_plan = true
		var room_count: int = (_floor_plan_data.get("rooms", []) as Array).size()
		print("FloorPlanLoader: Loaded %d rooms from %s" % [room_count, path])
		return true

	push_error("FloorPlanLoader: Expected Dictionary root in %s" % path)
	has_floor_plan = false
	return false


## Generate 3D room geometry. Call after GridSystem generates the base structure.
func apply_floor_plan(parent: Node3D, cell_size: float) -> void:
	if not has_floor_plan:
		return

	var rooms: Array = _floor_plan_data.get("rooms", [])
	if rooms.is_empty():
		print("FloorPlanLoader: No rooms defined in floor plan")
		return

	var container := Node3D.new()
	container.name = "FloorPlanRooms"
	parent.add_child(container)

	for room in rooms:
		if not room is Dictionary:
			continue
		var room_id: String = str(room.get("id", "room"))
		var room_node := Node3D.new()
		room_node.name = "Room_%s" % room_id
		container.add_child(room_node)

		_place_room_floor(room, room_node, cell_size)
		_generate_room_walls(room, room_node, cell_size)

	print("FloorPlanLoader: Generated %d rooms" % rooms.size())


# ── Floor placement ─────────────────────────────────────────────────────────

func _place_room_floor(room: Dictionary, parent: Node3D, cell_size: float) -> void:
	var cells: Array = room.get("cells", [])
	if cells.is_empty():
		return

	# Compute bounding rect from cells — cells are [row, col]
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

	# Cell extents (max is inclusive, so add 1 for size)
	var cols_span: int = max_col - min_col + 1
	var rows_span: int = max_row - min_row + 1

	# Floor size in meters
	var room_w: float = cols_span * cell_size
	var room_h: float = rows_span * cell_size

	# Room center in world coords
	var center_x: float = (min_col + cols_span * 0.5) * cell_size
	var center_z: float = (min_row + rows_span * 0.5) * cell_size

	# ── New: try mosaic composition first ──────────────────────────────────
	var mosaic_comp: String = room.get("mosaic_composition", "")
	if not mosaic_comp.is_empty():
		var comp_path := "res://commons/patterns/mosaics/%s.json" % mosaic_comp
		var floor_node := MosaicFloorBuilder.build_floor(comp_path, Vector2(room_w, room_h), parent)
		if floor_node:
			floor_node.position = Vector3(center_x, 0.005, center_z)
			return

	# ── Fall back to old artifact-based floor pattern ──────────────────────
	var floor_pattern: String = str(room.get("floor_pattern", ""))
	if floor_pattern.is_empty():
		return

	# Try to load the floor pattern scene from the artifact registry
	var scene := _load_artifact_scene(floor_pattern)
	if not scene:
		push_warning("FloorPlanLoader: Floor pattern '%s' not found, using fallback" % floor_pattern)
		_place_fallback_floor(parent, min_col, min_row, room_w, room_h, cell_size)
		return

	var floor_instance: Node3D = scene.instantiate()
	parent.add_child(floor_instance)

	# Build config and apply
	var floor_config: Dictionary = room.get("floor_config", {}).duplicate()
	floor_config["floor_size"] = [room_w, room_h]

	if floor_instance.has_method("apply_grid_config"):
		floor_instance.apply_grid_config(floor_config)

	floor_instance.position = Vector3(center_x, 0.01, center_z)
	floor_instance.name = "Floor_%s" % str(room.get("id", "room"))

	print("FloorPlanLoader: Placed floor '%s' at (%.1f, %.1f) size %.1fx%.1f" % [
		floor_pattern, center_x, center_z, room_w, room_h
	])


func _place_fallback_floor(parent: Node3D, min_col: int, min_row: int,
		floor_w: float, floor_h: float, cell_size: float) -> void:
	var mesh_inst := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(floor_w, floor_h)
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.65, 0.55)
	mat.roughness = 0.9
	mesh_inst.material_override = mat

	var center_x: float = (min_col + floor_w / cell_size * 0.5) * cell_size
	var center_z: float = (min_row + floor_h / cell_size * 0.5) * cell_size
	mesh_inst.position = Vector3(center_x, 0.01, center_z)
	mesh_inst.name = "FallbackFloor"
	parent.add_child(mesh_inst)


# ── Wall generation ─────────────────────────────────────────────────────────

func _generate_room_walls(room: Dictionary, parent: Node3D, cell_size: float) -> void:
	var cells: Array = room.get("cells", [])
	if cells.is_empty():
		return

	var wall_height: float = float(room.get("wall_height", 3.0))
	var wall_preset: String = str(room.get("wall_preset", "default"))
	var wall_thickness: float = float(_floor_plan_data.get("wall_thickness", 0.5))
	var doorways: Array = room.get("doorways", [])

	# Build a set of cells for fast lookup — key: "row,col"
	var cell_set: Dictionary = {}
	for cell in cells:
		if cell is Array and cell.size() >= 2:
			cell_set["%d,%d" % [int(cell[0]), int(cell[1])]] = true

	# Build a set of doorway positions — key: "row,col,dir"
	var doorway_set: Dictionary = {}
	for dw in doorways:
		if dw is Dictionary:
			var key := "%d,%d,%s" % [int(dw.get("row", 0)), int(dw.get("col", 0)), str(dw.get("direction", ""))]
			doorway_set[key] = true

	# Find boundary edges: for each cell, check each direction
	# An edge exists where the neighbor in that direction is NOT in this room
	var boundary_edges: Array = []  # Array of { row, col, dir }

	for cell in cells:
		if not cell is Array or cell.size() < 2:
			continue
		var row: int = int(cell[0])
		var col: int = int(cell[1])

		# Check 4 neighbors
		var neighbors := {
			"N": "%d,%d" % [row - 1, col],
			"S": "%d,%d" % [row + 1, col],
			"E": "%d,%d" % [row, col + 1],
			"W": "%d,%d" % [row, col - 1],
		}

		for dir in neighbors:
			if not cell_set.has(neighbors[dir]):
				# This edge is a boundary
				var dw_key := "%d,%d,%s" % [row, col, dir]
				var is_doorway: bool = doorway_set.has(dw_key)
				boundary_edges.append({
					"row": row,
					"col": col,
					"dir": dir,
					"is_doorway": is_doorway,
				})

	# Deduplicate shared edges between rooms — two adjacent rooms share the
	# same physical edge. Use a canonical edge key so each edge is only built
	# once. We keep the first occurrence (arbitrary but consistent).
	var seen_edges: Dictionary = {}
	var unique_edges: Array = []
	for e in boundary_edges:
		var canon_key: String = _canonical_edge_key(e["row"], e["col"], e["dir"])
		if not seen_edges.has(canon_key):
			seen_edges[canon_key] = true
			unique_edges.append(e)
	boundary_edges = unique_edges

	# Group contiguous boundary edges into wall segments by direction
	var segments := _group_into_segments(boundary_edges)

	# Build each wall segment
	var wall_container := Node3D.new()
	wall_container.name = "Walls"
	parent.add_child(wall_container)

	for seg in segments:
		_build_wall_segment(seg, wall_container, cell_size, wall_height, wall_preset, wall_thickness)

	print("FloorPlanLoader: Generated %d wall segments for room '%s'" % [
		segments.size(), str(room.get("id", "room"))
	])


## Group boundary edges into contiguous wall segments.
## Edges in the same direction that share a contiguous line are merged.
## Doorway edges split segments.
func _group_into_segments(edges: Array) -> Array:
	# Separate edges by direction
	var by_dir: Dictionary = { "N": [], "S": [], "E": [], "W": [] }
	for e in edges:
		var dir: String = e["dir"]
		if by_dir.has(dir):
			by_dir[dir].append(e)

	var all_segments: Array = []

	# N/S walls run along columns (same row), so sort by col
	for dir in ["N", "S"]:
		var dir_edges: Array = by_dir[dir]
		if dir_edges.is_empty():
			continue

		# Group by row first, then sort by col within each row
		var by_row: Dictionary = {}
		for e in dir_edges:
			var r: int = e["row"]
			if not by_row.has(r):
				by_row[r] = []
			by_row[r].append(e)

		for r in by_row:
			var row_edges: Array = by_row[r]
			row_edges.sort_custom(func(a, b): return a["col"] < b["col"])

			# Merge contiguous non-doorway edges
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

	# E/W walls run along rows (same col), so sort by row
	for dir in ["E", "W"]:
		var dir_edges: Array = by_dir[dir]
		if dir_edges.is_empty():
			continue

		# Group by col first, then sort by row within each col
		var by_col: Dictionary = {}
		for e in dir_edges:
			var c: int = e["col"]
			if not by_col.has(c):
				by_col[c] = []
			by_col[c].append(e)

		for c in by_col:
			var col_edges: Array = by_col[c]
			col_edges.sort_custom(func(a, b): return a["row"] < b["row"])

			# Merge contiguous non-doorway edges
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


## Build a single wall segment (either facade or simple box).
## Walls are 0.5m thick slabs centered ON the cell boundary edge.
## N/S walls extend by wall_thickness/2 at each end to cover corners,
## preventing gaps where perpendicular walls meet.
func _build_wall_segment(segment: Dictionary, parent: Node3D,
		cell_size: float, wall_height: float, wall_preset: String,
		wall_thickness: float) -> void:
	var dir: String = segment["dir"]
	var edges: Array = segment["edges"]
	if edges.is_empty():
		return

	var seg_length: int = edges.size()
	var seg_meters: float = seg_length * cell_size

	# Determine segment start cell
	var start_row: int = edges[0]["row"]
	var start_col: int = edges[0]["col"]

	# N/S walls extend by half-thickness at each end to cover corners.
	# E/W walls do NOT extend, so they butt up against N/S walls without overlap.
	var corner_ext: float = wall_thickness * 0.5 if dir in ["N", "S"] else 0.0
	var total_length: float = seg_meters + corner_ext * 2.0

	# Compute wall position and rotation
	# World coords: x = col * cell_size, z = row * cell_size
	# Walls are centered ON the boundary edge between cells
	var wall_pos: Vector3
	var wall_rot_y: float  # Degrees

	# Facade decorative side faces +Z in local space.
	# We ADD 180° to flip the facade so decorative side faces INWARD.
	# Without the flip, the decorative side faces away from the room.
	match dir:
		"N":
			# North edge: top of cell row -> z = row * cell_size
			# Room is south (+Z). Flip facade 180° so decorative side faces south.
			var cx: float = (start_col + seg_length * 0.5) * cell_size
			var cz: float = start_row * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = 180.0
		"S":
			# South edge: bottom of cell row -> z = (row + 1) * cell_size
			# Room is north (-Z). No flip needed, decorative side already faces +Z→north after 0°.
			var cx: float = (start_col + seg_length * 0.5) * cell_size
			var cz: float = (start_row + 1) * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = 0.0
		"E":
			# East edge: right of cell col -> x = (col + 1) * cell_size
			# Room is west (-X). Rotate -90° so +Z→-X = faces west into room.
			var cx: float = (start_col + 1) * cell_size
			var cz: float = (start_row + seg_length * 0.5) * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = -90.0
		"W":
			# West edge: left of cell col -> x = col * cell_size
			# Room is east (+X). Rotate 90° so +Z→+X = faces east into room.
			var cx: float = start_col * cell_size
			var cz: float = (start_row + seg_length * 0.5) * cell_size
			wall_pos = Vector3(cx, wall_height * 0.5, cz)
			wall_rot_y = 90.0

	if wall_preset != "default" and wall_preset != "":
		_build_facade_wall(parent, wall_pos, wall_rot_y, total_length, wall_height, wall_preset, wall_thickness)
	else:
		_build_simple_wall(parent, wall_pos, wall_rot_y, total_length, wall_height, wall_thickness)


## Build a facade wall from a preset JSON.
## The facade is placed centered on the edge, facing inward toward the room.
func _build_facade_wall(parent: Node3D, pos: Vector3, rot_y: float,
		width: float, height: float, preset_name: String,
		wall_thickness: float = 0.5) -> void:
	var preset_path := "res://commons/facade_parts/presets/%s.json" % preset_name

	if not FileAccess.file_exists(preset_path):
		push_warning("FloorPlanLoader: Facade preset '%s' not found at %s, using simple wall" % [
			preset_name, preset_path
		])
		_build_simple_wall(parent, pos, rot_y, width, height, wall_thickness)
		return

	# Load and modify the preset
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

	# Override facade dimensions to match this wall segment
	if not preset_data.has("facade"):
		preset_data["facade"] = {}
	preset_data["facade"]["total_width"] = width
	preset_data["facade"]["total_height"] = height

	# Adjust bays proportionally — roughly 1 bay per 3 meters
	var bays: int = maxi(1, roundi(width / 3.0))
	preset_data["facade"]["bays"] = bays

	# Build facade via FacadeComposer
	var facade_node: Node3D = FacadeComposerScript.build_from_dict(preset_data)

	# FacadeComposer builds facades in the XY plane, origin at bottom-left,
	# facing +Z. We need to:
	# 1. Center it horizontally (shift by -width/2)
	# 2. Shift it down by wall_height/2 (since pos is at wall center)
	# 3. Rotate to face the correct direction
	var wall_root := Node3D.new()
	wall_root.name = "FacadeWall_%s" % preset_name
	parent.add_child(wall_root)

	wall_root.position = pos
	wall_root.rotation_degrees.y = rot_y

	# Offset the facade so it is centered on the wall_root
	facade_node.position = Vector3(-width * 0.5, -height * 0.5, 0.0)
	wall_root.add_child(facade_node)


## Build a simple box wall (fallback).
## Creates a BoxMesh of (length x wall_height x wall_thickness) centered on the edge.
func _build_simple_wall(parent: Node3D, pos: Vector3, rot_y: float,
		width: float, height: float, wall_thickness: float = 0.5) -> void:
	var wall_root := Node3D.new()
	wall_root.name = "SimpleWall"
	parent.add_child(wall_root)

	wall_root.position = pos
	wall_root.rotation_degrees.y = rot_y

	# Visual mesh — width along the wall, height vertical, wall_thickness depth
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

	# Collision
	var body := StaticBody3D.new()
	body.name = "WallCollision"
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, wall_thickness)
	col_shape.shape = shape
	body.add_child(col_shape)
	wall_root.add_child(body)


# ── Edge deduplication helper ──────────────────────────────────────────────

## Return a canonical key for a cell boundary edge so that the same physical
## edge referenced from either side produces the same key.
## E.g. cell (3,5) East == cell (3,6) West → both map to "3,6,W".
## Convention: pick the lexicographically smaller key from the two equivalent
## representations (cell-side vs neighbor-side).
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


# ── Artifact loading helper ─────────────────────────────────────────────────

## Try to load an artifact scene by lookup_name from the registry.
## Searches commons/artifacts/<lookup_name>/<lookup_name>.tscn
func _load_artifact_scene(lookup_name: String) -> PackedScene:
	var scene_path := "res://commons/artifacts/%s/%s.tscn" % [lookup_name, lookup_name]

	if ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene:
			return scene

	# Try alternate path without subfolder
	var alt_path := "res://commons/artifacts/%s.tscn" % lookup_name
	if ResourceLoader.exists(alt_path):
		var scene := load(alt_path) as PackedScene
		if scene:
			return scene

	return null
