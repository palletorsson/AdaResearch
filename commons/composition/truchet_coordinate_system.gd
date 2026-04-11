## TruchetCS — Rectangular grid with per-cell rotation state
## Same grid layout as RectangularCS, but each cell carries a rotation
## (0, 90, 180, 270 degrees) that determines how its pattern is oriented.
## Natural for Islamic interlace, Celtic knots, pipe networks.
##
## The rotation creates emergent curves and connections between tiles.
##
## Features:
##   - 8 rotation rules: RANDOM, CHECKERBOARD, ZONE_BASED, SPIRAL, GRADIENT,
##     WAVE, DIAGONAL_WAVE, SMITH (binary Truchet from parity)
##   - 4 mesh styles: QUAD, DIAGONAL_SPLIT, ARC_PAIR, QUARTER_CIRCLES
##   - Connectivity analysis: which tile edges connect to neighbors
##   - Procedural geometry built into the mesh (not just a flat quad)

extends "res://commons/composition/coordinate_system.gd"

# ═══════════════════════════════════════════════════════════════════
# ENUMS
# ═══════════════════════════════════════════════════════════════════

enum RotationRule {
	RANDOM,          ## Pseudorandom per cell
	CHECKERBOARD,    ## Alternating 0/180 on (x+y)%2
	ZONE_BASED,      ## Quadrant-based (0..3)
	SPIRAL,          ## Rotation follows a spiral from center outward
	GRADIENT,        ## Smooth rotation gradient across the grid
	WAVE,            ## Sine-wave based rotation bands
	DIAGONAL_WAVE,   ## Diagonal sine-wave ripple
	SMITH,           ## Smith diagram: binary (0 or 1) from (x+y) parity — classic Truchet
}

enum MeshStyle {
	QUAD,             ## Plain quad (rotation applied externally via transform)
	DIAGONAL_SPLIT,   ## Two triangles split along the diagonal
	ARC_PAIR,         ## Two quarter-circle arcs at opposite corners
	QUARTER_CIRCLES,  ## Quarter circles at all four corners (maze-like)
}

# ═══════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════

var rotation_rule: int = RotationRule.RANDOM
var mesh_style: int = MeshStyle.QUAD
var rotations: Dictionary = {}  # Vector2i -> int (0, 1, 2, 3 = 0deg, 90deg, 180deg, 270deg)
var _rng = RandomNumberGenerator.new()

## Arc resolution for curved mesh styles (segments per quarter arc)
var arc_segments: int = 8

## Wave frequency for WAVE / DIAGONAL_WAVE rules
var wave_frequency: float = 1.0

## Gradient direction for GRADIENT rule (radians, 0 = left-to-right)
var gradient_angle: float = 0.0

# ═══════════════════════════════════════════════════════════════════
# INIT
# ═══════════════════════════════════════════════════════════════════

func _init(w: int = 20, h: int = 20, cs: float = 1.0) -> void:
	type = Type.TRUCHET
	grid_width = w
	grid_height = h
	cell_size = cs
	_rng.seed = w * 1000 + h
	_assign_rotations()

# ═══════════════════════════════════════════════════════════════════
# ROTATION ASSIGNMENT
# ═══════════════════════════════════════════════════════════════════

func set_rotation_rule(rule: int, seed_val: int = 42) -> void:
	rotation_rule = rule
	_rng.seed = seed_val
	_assign_rotations()

func set_mesh_style(style: int) -> void:
	mesh_style = style

func _assign_rotations() -> void:
	rotations.clear()
	for gy in grid_height:
		for gx in grid_width:
			var key = Vector2i(gx, gy)
			rotations[key] = _compute_rotation(gx, gy)

func _compute_rotation(gx: int, gy: int) -> int:
	match rotation_rule:
		RotationRule.RANDOM:
			return _rng.randi_range(0, 3)

		RotationRule.CHECKERBOARD:
			return ((gx + gy) % 2) * 2  # 0deg or 180deg

		RotationRule.ZONE_BASED:
			var qx: int = 0 if gx < grid_width / 2 else 1
			var qy: int = 0 if gy < grid_height / 2 else 1
			return qx + qy * 2

		RotationRule.SPIRAL:
			return _spiral_rotation(gx, gy)

		RotationRule.GRADIENT:
			return _gradient_rotation(gx, gy)

		RotationRule.WAVE:
			return _wave_rotation(gx, gy)

		RotationRule.DIAGONAL_WAVE:
			return _diagonal_wave_rotation(gx, gy)

		RotationRule.SMITH:
			return (gx + gy) % 2  # Binary: 0 or 1 only

		_:
			return 0

func _spiral_rotation(gx: int, gy: int) -> int:
	## Compute angle from grid center, map to rotation index.
	## Creates a vortex / spiral pattern.
	var cx: float = float(grid_width - 1) * 0.5
	var cy: float = float(grid_height - 1) * 0.5
	var dx: float = float(gx) - cx
	var dy: float = float(gy) - cy
	var angle: float = atan2(dy, dx)
	var dist: float = sqrt(dx * dx + dy * dy)
	# Spiral: angle + distance determines rotation
	var spiral_angle: float = angle + dist * 0.5 * wave_frequency
	# Map to 0..3
	var idx: int = int(floor(fmod(spiral_angle / (PI * 0.5) + 100.0, 4.0)))
	return clampi(idx, 0, 3)

func _gradient_rotation(gx: int, gy: int) -> int:
	## Linear gradient across the grid. gradient_angle controls direction.
	var nx: float = float(gx) / maxf(float(grid_width - 1), 1.0)
	var ny: float = float(gy) / maxf(float(grid_height - 1), 1.0)
	var proj: float = nx * cos(gradient_angle) + ny * sin(gradient_angle)
	var idx: int = int(floor(proj * 4.0 * wave_frequency)) % 4
	if idx < 0:
		idx += 4
	return idx

func _wave_rotation(gx: int, gy: int) -> int:
	## Horizontal sine wave: rotation oscillates across rows.
	var phase: float = float(gx) * wave_frequency * 0.5 + float(gy) * 0.3
	var val: float = sin(phase * PI)
	# Map [-1, 1] to [0, 3]
	var idx: int = int(floor((val + 1.0) * 2.0)) % 4
	return clampi(idx, 0, 3)

func _diagonal_wave_rotation(gx: int, gy: int) -> int:
	## Diagonal ripple: wave travels along x+y diagonal.
	var diag: float = float(gx + gy) * wave_frequency * 0.4
	var val: float = sin(diag * PI) + cos(diag * PI * 0.7) * 0.5
	# Map to 0..3
	var idx: int = int(floor((val + 1.5) * 1.33)) % 4
	return clampi(idx, 0, 3)

# ═══════════════════════════════════════════════════════════════════
# ROTATION QUERY
# ═══════════════════════════════════════════════════════════════════

func get_rotation(cell_key) -> int:
	return rotations.get(cell_key, 0)

func get_rotation_degrees(cell_key) -> float:
	return float(get_rotation(cell_key)) * 90.0

# ═══════════════════════════════════════════════════════════════════
# CELL ITERATION & POSITION
# ═══════════════════════════════════════════════════════════════════

func iterate_cells() -> Array:
	var cells: Array = []
	for gy in grid_height:
		for gx in grid_width:
			cells.append(Vector2i(gx, gy))
	return cells

func cell_to_world(cell_key) -> Vector3:
	var gx: int = cell_key.x
	var gy: int = cell_key.y
	var wx: float = (float(gx) - float(grid_width) / 2.0 + 0.5) * cell_size
	var wz: float = (float(gy) - float(grid_height) / 2.0 + 0.5) * cell_size
	return Vector3(wx, 0.0, wz)

func cell_to_normalized(cell_key) -> Vector2:
	return Vector2(
		(float(cell_key.x) + 0.5) / float(grid_width),
		(float(cell_key.y) + 0.5) / float(grid_height)
	)

# ═══════════════════════════════════════════════════════════════════
# MESH GENERATION
# ═══════════════════════════════════════════════════════════════════

func create_cell_mesh(cell_key) -> Mesh:
	match mesh_style:
		MeshStyle.QUAD:
			return _create_quad_mesh()
		MeshStyle.DIAGONAL_SPLIT:
			return _create_diagonal_split_mesh(cell_key)
		MeshStyle.ARC_PAIR:
			return _create_arc_pair_mesh(cell_key)
		MeshStyle.QUARTER_CIRCLES:
			return _create_quarter_circles_mesh(cell_key)
		_:
			return _create_quad_mesh()

func _create_quad_mesh() -> Mesh:
	## Original plain quad — rotation is applied as a mesh transform.
	var quad = QuadMesh.new()
	quad.size = Vector2(cell_size * 0.96, cell_size * 0.96)
	return quad

func _create_diagonal_split_mesh(cell_key) -> Mesh:
	## Two triangles split along the diagonal. The rotation determines
	## which diagonal is used, creating classic Truchet diagonal patterns.
	## Each triangle gets a different surface for separate materials.
	var half: float = cell_size * 0.48
	var rot: int = get_rotation(cell_key)
	var st = SurfaceTool.new()
	var arr_mesh = ArrayMesh.new()

	# Triangle A (surface 0)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))  # Facing +Z (will be rotated to face up)
	if rot % 2 == 0:
		# Diagonal from top-left to bottom-right
		st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-half, half, 0))
		st.set_uv(Vector2(1, 0)); st.add_vertex(Vector3(half, half, 0))
		st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(half, -half, 0))
	else:
		# Diagonal from top-right to bottom-left
		st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-half, half, 0))
		st.set_uv(Vector2(1, 0)); st.add_vertex(Vector3(half, half, 0))
		st.set_uv(Vector2(0, 1)); st.add_vertex(Vector3(-half, -half, 0))
	st.commit(arr_mesh)

	# Triangle B (surface 1)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))
	if rot % 2 == 0:
		st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-half, half, 0))
		st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(half, -half, 0))
		st.set_uv(Vector2(0, 1)); st.add_vertex(Vector3(-half, -half, 0))
	else:
		st.set_uv(Vector2(1, 0)); st.add_vertex(Vector3(half, half, 0))
		st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(half, -half, 0))
		st.set_uv(Vector2(0, 1)); st.add_vertex(Vector3(-half, -half, 0))
	st.commit(arr_mesh)

	return arr_mesh

func _create_arc_pair_mesh(cell_key) -> Mesh:
	## Two quarter-circle arcs at opposite corners.
	## This creates the classic Truchet tile appearance — when tiles are
	## rotated, arcs connect across edges to form continuous curves.
	var half: float = cell_size * 0.48
	var rot: int = get_rotation(cell_key)
	var st = SurfaceTool.new()
	var arr_mesh = ArrayMesh.new()
	var segs: int = arc_segments
	var arc_radius: float = half  # Arcs reach from corner to mid-edge

	# Determine which pair of corners gets arcs based on rotation
	var corner_pairs: Array = []
	if rot % 2 == 0:
		# Arcs at bottom-left and top-right
		corner_pairs = [Vector2(-half, -half), Vector2(half, half)]
	else:
		# Arcs at top-left and bottom-right
		corner_pairs = [Vector2(-half, half), Vector2(half, -half)]

	# Surface 0: arc fill regions (fan triangles from each corner)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))

	for corner in corner_pairs:
		var cx: float = corner.x
		var cy: float = corner.y
		# Determine start angle based on which corner
		var start_angle: float = 0.0
		if cx < 0 and cy < 0:
			start_angle = 0.0        # bottom-left: arc from right to up
		elif cx > 0 and cy > 0:
			start_angle = PI          # top-right: arc from left to down
		elif cx < 0 and cy > 0:
			start_angle = PI * 1.5    # top-left: arc from down to right
		else:
			start_angle = PI * 0.5    # bottom-right: arc from up to left

		# Generate fan triangles for this arc
		for i in segs:
			var a0: float = start_angle + float(i) / float(segs) * PI * 0.5
			var a1: float = start_angle + float(i + 1) / float(segs) * PI * 0.5
			var p0 = Vector3(cx + cos(a0) * arc_radius, cy + sin(a0) * arc_radius, 0.0)
			var p1 = Vector3(cx + cos(a1) * arc_radius, cy + sin(a1) * arc_radius, 0.0)
			var center_v = Vector3(cx, cy, 0.0)

			# UV mapping: normalize to 0..1 range
			var uv_c = Vector2((cx + half) / (2.0 * half), (cy + half) / (2.0 * half))
			var uv0 = Vector2((p0.x + half) / (2.0 * half), (p0.y + half) / (2.0 * half))
			var uv1 = Vector2((p1.x + half) / (2.0 * half), (p1.y + half) / (2.0 * half))

			st.set_uv(uv_c); st.add_vertex(center_v)
			st.set_uv(uv0); st.add_vertex(p0)
			st.set_uv(uv1); st.add_vertex(p1)
	st.commit(arr_mesh)

	# Surface 1: background quad (the area NOT covered by arcs)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))
	# Simple full quad as background — arcs are drawn on top
	st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-half, -half, -0.001))
	st.set_uv(Vector2(1, 0)); st.add_vertex(Vector3(half, -half, -0.001))
	st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(half, half, -0.001))

	st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-half, -half, -0.001))
	st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(half, half, -0.001))
	st.set_uv(Vector2(0, 1)); st.add_vertex(Vector3(-half, half, -0.001))
	st.commit(arr_mesh)

	return arr_mesh

func _create_quarter_circles_mesh(cell_key) -> Mesh:
	## Quarter circles at all four corners — creates a maze-like pattern.
	## Each corner has an arc; rotation determines which corners are filled
	## vs hollow, producing four distinct tile states.
	var half: float = cell_size * 0.48
	var rot: int = get_rotation(cell_key)
	var st = SurfaceTool.new()
	var arr_mesh = ArrayMesh.new()
	var segs: int = arc_segments
	var arc_radius: float = half * 0.7

	# All four corners with their start angles
	var corners: Array = [
		{"pos": Vector2(-half, -half), "angle": 0.0},         # bottom-left
		{"pos": Vector2(half, -half), "angle": PI * 0.5},     # bottom-right
		{"pos": Vector2(half, half), "angle": PI},             # top-right
		{"pos": Vector2(-half, half), "angle": PI * 1.5},     # top-left
	]

	# Rotation determines which corners are "filled" (surface 0) vs "outlined" (surface 1)
	# rot 0: fill 0,2 / outline 1,3  (diagonal pair)
	# rot 1: fill 1,3 / outline 0,2  (other diagonal pair)
	# rot 2: fill 0,1 / outline 2,3  (bottom pair)
	# rot 3: fill 2,3 / outline 0,1  (top pair)
	var filled: Array = []
	match rot:
		0: filled = [0, 2]
		1: filled = [1, 3]
		2: filled = [0, 1]
		3: filled = [2, 3]

	# Surface 0: filled arcs
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))
	for ci in 4:
		if not ci in filled:
			continue
		var c = corners[ci]
		var cx: float = c["pos"].x
		var cy: float = c["pos"].y
		var sa: float = c["angle"]
		for i in segs:
			var a0: float = sa + float(i) / float(segs) * PI * 0.5
			var a1: float = sa + float(i + 1) / float(segs) * PI * 0.5
			var p0 = Vector3(cx + cos(a0) * arc_radius, cy + sin(a0) * arc_radius, 0.0)
			var p1 = Vector3(cx + cos(a1) * arc_radius, cy + sin(a1) * arc_radius, 0.0)
			var uv_c = Vector2((cx + half) / (2.0 * half), (cy + half) / (2.0 * half))
			var uv0 = Vector2((p0.x + half) / (2.0 * half), (p0.y + half) / (2.0 * half))
			var uv1 = Vector2((p1.x + half) / (2.0 * half), (p1.y + half) / (2.0 * half))
			st.set_uv(uv_c); st.add_vertex(Vector3(cx, cy, 0))
			st.set_uv(uv0); st.add_vertex(p0)
			st.set_uv(uv1); st.add_vertex(p1)
	st.commit(arr_mesh)

	# Surface 1: background fill
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))
	st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-half, -half, -0.001))
	st.set_uv(Vector2(1, 0)); st.add_vertex(Vector3(half, -half, -0.001))
	st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(half, half, -0.001))
	st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-half, -half, -0.001))
	st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(half, half, -0.001))
	st.set_uv(Vector2(0, 1)); st.add_vertex(Vector3(-half, half, -0.001))
	st.commit(arr_mesh)

	return arr_mesh

# ═══════════════════════════════════════════════════════════════════
# CONNECTIVITY ANALYSIS
# ═══════════════════════════════════════════════════════════════════

## Edge identifiers for connectivity:
##   0 = top edge, 1 = right edge, 2 = bottom edge, 3 = left edge
## A Truchet tile "connects" on an edge when its arc or diagonal exits
## through that edge. Two adjacent tiles are connected when the shared
## edge is an exit for both tiles.

## Returns which edges (0..3) this cell's pattern exits through.
## For DIAGONAL_SPLIT: the diagonal splits the tile; edges on the same
## side of the diagonal are connected.
## For ARC_PAIR: arcs exit through the two edges adjacent to each corner.
func get_exit_edges(cell_key) -> Array:
	var rot: int = get_rotation(cell_key)

	match mesh_style:
		MeshStyle.DIAGONAL_SPLIT:
			# Diagonal split: one diagonal connects top+right, other connects bottom+left
			if rot % 2 == 0:
				return [0, 1, 2, 3]  # Both sides exit all edges
			else:
				return [0, 1, 2, 3]

		MeshStyle.ARC_PAIR:
			# Classic arc pair: arcs at two opposite corners
			# Each arc exits through the two edges adjacent to its corner
			if rot % 2 == 0:
				# Arcs at bottom-left (exits bottom + left) and top-right (exits top + right)
				return [0, 1, 2, 3]  # All edges have arc exits
			else:
				# Arcs at top-left (exits top + left) and bottom-right (exits bottom + right)
				return [0, 1, 2, 3]

		MeshStyle.QUARTER_CIRCLES:
			# Only filled corners produce exits
			var exits: Array = []
			var filled: Array = []
			match rot:
				0: filled = [0, 2]  # bottom-left, top-right
				1: filled = [1, 3]  # bottom-right, top-left
				2: filled = [0, 1]  # bottom-left, bottom-right
				3: filled = [2, 3]  # top-right, top-left
			# Map corners to their adjacent edges
			# corner 0 (BL) -> edges 2 (bottom), 3 (left)
			# corner 1 (BR) -> edges 2 (bottom), 1 (right)
			# corner 2 (TR) -> edges 0 (top), 1 (right)
			# corner 3 (TL) -> edges 0 (top), 3 (left)
			var corner_edges: Array = [[2, 3], [2, 1], [0, 1], [0, 3]]
			for ci in filled:
				for e in corner_edges[ci]:
					if not e in exits:
						exits.append(e)
			return exits

		_:
			return [0, 1, 2, 3]  # QUAD: all edges potentially connected

## Returns true if two adjacent cells connect across their shared edge.
## neighbor_dir: Vector2i offset to the neighbor (e.g., Vector2i(1, 0) = right)
func cells_connect(cell_a, cell_b, neighbor_dir: Vector2i) -> bool:
	# Determine which edges are shared
	var edge_a: int = -1
	var edge_b: int = -1
	if neighbor_dir == Vector2i(0, -1):    # neighbor is above
		edge_a = 0; edge_b = 2
	elif neighbor_dir == Vector2i(1, 0):   # neighbor is right
		edge_a = 1; edge_b = 3
	elif neighbor_dir == Vector2i(0, 1):   # neighbor is below
		edge_a = 2; edge_b = 0
	elif neighbor_dir == Vector2i(-1, 0):  # neighbor is left
		edge_a = 3; edge_b = 1
	else:
		return false

	var exits_a: Array = get_exit_edges(cell_a)
	var exits_b: Array = get_exit_edges(cell_b)
	return edge_a in exits_a and edge_b in exits_b

## Returns all cells that are directly connected to the given cell
## through shared arc/diagonal exits.
func get_connected_neighbors(cell_key) -> Array:
	var neighbors: Array = []
	var directions: Array = [
		Vector2i(0, -1),   # top
		Vector2i(1, 0),    # right
		Vector2i(0, 1),    # bottom
		Vector2i(-1, 0),   # left
	]
	for dir in directions:
		var neighbor_key = cell_key + dir
		if not rotations.has(neighbor_key):
			continue
		if cells_connect(cell_key, neighbor_key, dir):
			neighbors.append(neighbor_key)
	return neighbors

## Traces a continuous curve through connected tiles starting from
## a given cell. Returns an array of Vector2i cell keys forming the path.
## Useful for visualizing the emergent curves in Truchet tilings.
func trace_curve(start_cell, max_steps: int = 100) -> Array:
	var path: Array = [start_cell]
	var visited: Dictionary = {start_cell: true}
	var current = start_cell

	for _step in max_steps:
		var next_cells: Array = get_connected_neighbors(current)
		var found_next: bool = false
		for nc in next_cells:
			if not visited.has(nc):
				visited[nc] = true
				path.append(nc)
				current = nc
				found_next = true
				break
		if not found_next:
			break

	return path

## Returns a connectivity summary: how many distinct connected components
## exist in the tiling. Lower = more connected / more flowing curves.
func compute_connectivity_stats() -> Dictionary:
	var all_cells: Array = iterate_cells()
	var visited: Dictionary = {}
	var component_count: int = 0
	var largest_component: int = 0

	for cell in all_cells:
		if visited.has(cell):
			continue
		# BFS from this cell
		component_count += 1
		var queue: Array = [cell]
		var comp_size: int = 0
		visited[cell] = component_count
		while queue.size() > 0:
			var c = queue.pop_front()
			comp_size += 1
			for neighbor in get_connected_neighbors(c):
				if not visited.has(neighbor):
					visited[neighbor] = component_count
					queue.append(neighbor)
		if comp_size > largest_component:
			largest_component = comp_size

	return {
		"total_cells": all_cells.size(),
		"components": component_count,
		"largest_component": largest_component,
		"connectivity_ratio": float(largest_component) / maxf(float(all_cells.size()), 1.0),
	}
