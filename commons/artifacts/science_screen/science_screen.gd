## ScienceScreen — A large VR display showing 2D abstractions of 3D content.
##
## The meeting point of 2D and 3D in Ada Research. You EXPERIENCE the pattern
## with your body while you UNDERSTAND it with your eyes. Split consciousness:
## the 3D world around you rendered as a flat, legible grid on this screen.
##
## Detects nearby artifacts that have grid data (via apply_grid_config) and
## renders a simplified pixel-grid view on a SubViewport. Shows algorithm name,
## grid dimensions, pattern type, and cell counts as overlay text.
##
## Grid config keys:
##   screen_width   - Width in meters (0.5–4.0, default 2.0)
##   screen_height  - Height in meters (0.5–3.0, default 1.5)
##   scan_radius    - How far to look for artifacts (1.0–20.0, default 8.0)
##   label          - Override the algorithm name text
##   highlight      - Highlight color as "r,g,b" (0–1 floats)
##   border         - Border color as "r,g,b"
##   bg             - Background color as "r,g,b"
extends Node3D
class_name ScienceScreen

## Physical dimensions
@export var screen_width: float = 3.0
@export var screen_height: float = 2.2

## Colors
@export var screen_color: Color = Color(0.05, 0.05, 0.08)
@export var border_color: Color = Color(0.3, 0.3, 0.35)
@export var grid_color: Color = Color(0.15, 0.2, 0.25)
@export var highlight_color: Color = Color(0.2, 0.8, 0.4)

## Scanning
@export var scan_radius: float = 8.0
@export var scan_interval: float = 1.0

## Internal nodes
var _screen_mesh: MeshInstance3D
var _border_mesh: MeshInstance3D
var _stand_mesh: MeshInstance3D
var _viewport: SubViewport
var _canvas: Control
var _label_name: String = ""
var _override_label: String = ""

## Grid data extracted from nearby artifact
var _grid_cols: int = 0
var _grid_rows: int = 0
var _grid_cells: Array = []  # 2D array of int (color indices)
var _cell_count: int = 0
var _pattern_type: String = "none"
var _source_artifact_name: String = ""

## Point tracking mode — when a pickable point is nearby
var _tracking_point: Node3D = null
var _point_mode: bool = false
var _point_trail: Array[Vector3] = []  # Trail of recent positions
const MAX_TRAIL := 60

## Viewport resolution
const VP_WIDTH: int = 768
const VP_HEIGHT: int = 576

## Scan timer
var _scan_timer: float = 0.0

func _ready() -> void:
	_build_screen()
	_build_viewport()
	_apply_viewport_to_screen()
	# Initial scan
	_scan_for_artifacts()

func _process(delta: float) -> void:
	_scan_timer += delta
	if _scan_timer >= scan_interval:
		_scan_timer = 0.0
		_scan_for_artifacts()
		if not _point_mode:
			_scan_for_points()

	# Track point position for trail
	if _point_mode and is_instance_valid(_tracking_point) and _tracking_point.visible:
		var pos := _tracking_point.global_position
		_point_trail.append(pos)
		if _point_trail.size() > MAX_TRAIL:
			_point_trail.pop_front()

	_canvas.queue_redraw()


# ═══════════════════════════════════════════════════════════════════
# CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════

func _build_screen() -> void:
	# ── Screen quad (standing upright, face toward +Z) ──
	_screen_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(screen_width, screen_height)
	plane.orientation = PlaneMesh.FACE_Z
	_screen_mesh.mesh = plane
	_screen_mesh.position = Vector3(0, screen_height * 0.5 + 0.05, 0)
	add_child(_screen_mesh)

	# Screen base material (will be replaced by viewport texture)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = screen_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mesh.material_override = mat

	# ── Border frame ──
	_border_mesh = MeshInstance3D.new()
	var border_plane := PlaneMesh.new()
	var border_margin := 0.04
	border_plane.size = Vector2(screen_width + border_margin * 2, screen_height + border_margin * 2)
	border_plane.orientation = PlaneMesh.FACE_Z
	_border_mesh.mesh = border_plane
	_border_mesh.position = Vector3(0, screen_height * 0.5 + 0.05, -0.005)
	add_child(_border_mesh)

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = border_color
	border_mat.metallic = 0.6
	border_mat.roughness = 0.3
	_border_mesh.material_override = border_mat

	# ── Simple stand (thin box below screen) ──
	_stand_mesh = MeshInstance3D.new()
	var stand_box := BoxMesh.new()
	stand_box.size = Vector3(0.08, screen_height * 0.5 + 0.05, 0.08)
	_stand_mesh.mesh = stand_box
	_stand_mesh.position = Vector3(0, (screen_height * 0.5 + 0.05) * 0.5, -0.02)
	add_child(_stand_mesh)

	var stand_mat := StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.15, 0.15, 0.18)
	stand_mat.metallic = 0.7
	stand_mat.roughness = 0.25
	_stand_mesh.material_override = stand_mat

func _build_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(VP_WIDTH, VP_HEIGHT)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.canvas_item_default_texture_filter = SubViewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)

	_canvas = _ScreenCanvas.new()
	_canvas.screen_ref = self
	_canvas.size = Vector2(VP_WIDTH, VP_HEIGHT)
	_viewport.add_child(_canvas)

func _apply_viewport_to_screen() -> void:
	if not _viewport or not _screen_mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _viewport.get_texture()
	mat.emission_enabled = true
	mat.emission_texture = _viewport.get_texture()
	mat.emission_energy_multiplier = 1.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mesh.material_override = mat


# ═══════════════════════════════════════════════════════════════════
# ARTIFACT SCANNING
# ═══════════════════════════════════════════════════════════════════

func _scan_for_artifacts() -> void:
	var best_node: Node = null
	var best_dist: float = scan_radius + 1.0

	# Walk siblings and their children looking for grid-aware artifacts
	var parent := get_parent()
	if not parent:
		return

	var my_pos := global_position
	_scan_subtree(parent, my_pos, best_dist, best_node)

	if best_node:
		_extract_grid_data(best_node)

## Recursively scan a subtree for the nearest artifact with grid data
func _scan_subtree(node: Node, origin: Vector3, best_dist: float, best_node: Node) -> void:
	for child in node.get_children():
		if child == self:
			continue
		if child is Node3D and child.has_method("apply_grid_config"):
			var d: float = origin.distance_to((child as Node3D).global_position)
			if d < best_dist and d < scan_radius:
				best_dist = d
				best_node = child
				_source_artifact_name = child.name
		# Also check grandchildren (one level deeper)
		for grandchild in child.get_children():
			if grandchild == self:
				continue
			if grandchild is Node3D and grandchild.has_method("apply_grid_config"):
				var d: float = origin.distance_to((grandchild as Node3D).global_position)
				if d < best_dist and d < scan_radius:
					best_dist = d
					best_node = grandchild
					_source_artifact_name = grandchild.name

func _scan_for_points() -> void:
	## Look for nearby pickable points (XRToolsPickable with position data)
	var parent := get_parent()
	if not parent:
		return
	var my_pos := global_position
	_scan_point_subtree(parent, my_pos)

func _scan_point_subtree(node: Node, origin: Vector3) -> void:
	for child in node.get_children():
		if child == self:
			continue
		if child is Node3D:
			var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
			var is_point: bool = "point" in lookup or "point" in child.name.to_lower()
			if is_point and child.get("freeze") != null:
				var d: float = origin.distance_to(child.global_position)
				if d < scan_radius:
					_tracking_point = child
					_point_mode = true
					_label_name = "POINT TRACKER"
					_source_artifact_name = lookup if lookup != "" else child.name
					print("[ScienceScreen] Tracking point: %s" % _source_artifact_name)
					return
		for grandchild in child.get_children():
			if grandchild is Node3D:
				var lookup: String = str(grandchild.get_meta("artifact_lookup_name", ""))
				var is_point: bool = "point" in lookup or "point" in grandchild.name.to_lower()
				if is_point and grandchild.get("freeze") != null:
					var d: float = origin.distance_to(grandchild.global_position)
					if d < scan_radius:
						_tracking_point = grandchild
						_point_mode = true
						_label_name = "POINT TRACKER"
						_source_artifact_name = lookup if lookup != "" else grandchild.name
						print("[ScienceScreen] Tracking point: %s" % _source_artifact_name)
						return


func _extract_grid_data(node: Node) -> void:
	# Try to read grid dimensions from common patterns
	_grid_cols = 0
	_grid_rows = 0
	_grid_cells = []
	_cell_count = 0
	_pattern_type = "unknown"

	# Check for known grid properties
	if "grid_width" in node:
		_grid_cols = int(node.get("grid_width"))
	elif "cols" in node:
		_grid_cols = int(node.get("cols"))
	elif "width" in node:
		var w = node.get("width")
		if w is int or w is float:
			_grid_cols = int(w)

	if "grid_height" in node:
		_grid_rows = int(node.get("grid_height"))
	elif "rows" in node:
		_grid_rows = int(node.get("rows"))
	elif "height" in node:
		var h = node.get("height")
		if h is int or h is float:
			_grid_rows = int(h)

	# Check for cell/grid data arrays
	if "cells" in node:
		var c = node.get("cells")
		if c is Array:
			_grid_cells = c
			_cell_count = _count_active_cells(c)
	elif "grid" in node:
		var g = node.get("grid")
		if g is Array:
			_grid_cells = g
			_cell_count = _count_active_cells(g)

	# Check for pattern/algorithm type
	if "algorithm_name" in node:
		_pattern_type = str(node.get("algorithm_name"))
	elif "pattern_type" in node:
		_pattern_type = str(node.get("pattern_type"))
	elif "rule" in node:
		_pattern_type = "Rule %s" % str(node.get("rule"))

	# Fallback: generate a representative grid from the artifact class name
	if _grid_cols == 0 and _grid_rows == 0:
		_grid_cols = 8
		_grid_rows = 8
		_pattern_type = _classify_artifact(node)
		_generate_representative_grid(node)

	_label_name = _override_label if _override_label != "" else _source_artifact_name

func _count_active_cells(data: Array) -> int:
	var count := 0
	for row in data:
		if row is Array:
			for cell in row:
				if cell is int and cell > 0:
					count += 1
				elif cell is bool and cell:
					count += 1
				elif cell is float and cell > 0.0:
					count += 1
		elif row is int and row > 0:
			count += 1
	return count

func _classify_artifact(node: Node) -> String:
	var class_str: String = node.get_class() if node.get_class() != "Node3D" else node.name
	class_str = class_str.to_snake_case().replace("_", " ")
	return class_str

func _generate_representative_grid(node: Node) -> void:
	# Create a hash-based pattern from the artifact's properties
	var seed_val: int = hash(node.name) if node else 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	_grid_cells = []
	_cell_count = 0
	for y in range(_grid_rows):
		var row: Array = []
		for x in range(_grid_cols):
			var val: int = 0
			# Create structured patterns rather than pure noise
			var cx := x - _grid_cols / 2
			var cy := y - _grid_rows / 2
			var dist := sqrt(float(cx * cx + cy * cy))

			match (seed_val % 4):
				0:  # Concentric rings
					val = int(dist) % 3
				1:  # Diagonal stripes
					val = (x + y) % 3
				2:  # Checker
					val = (x + y) % 2 * 2
				3:  # Radial sectors
					var angle := atan2(float(cy), float(cx))
					val = int((angle + PI) / (PI * 2.0) * 4.0) % 3

			if val > 0:
				_cell_count += 1
			row.append(val)
		_grid_cells.append(row)


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("screen_width"):
		screen_width = clampf(float(config_data["screen_width"]), 0.5, 4.0)
	if config_data.has("screen_height"):
		screen_height = clampf(float(config_data["screen_height"]), 0.5, 3.0)
	if config_data.has("scan_radius"):
		scan_radius = clampf(float(config_data["scan_radius"]), 1.0, 20.0)
	if config_data.has("label"):
		_override_label = str(config_data["label"])
	if config_data.has("highlight"):
		highlight_color = _parse_color(str(config_data["highlight"]), highlight_color)
	if config_data.has("border"):
		border_color = _parse_color(str(config_data["border"]), border_color)
	if config_data.has("bg"):
		screen_color = _parse_color(str(config_data["bg"]), screen_color)

	# Rebuild with new dimensions
	_rebuild()
	print("[ScienceScreen] Config applied — %sx%s, scan=%.1fm" % [screen_width, screen_height, scan_radius])

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() == 3:
		return Color(
			clampf(parts[0].strip_edges().to_float(), 0.0, 1.0),
			clampf(parts[1].strip_edges().to_float(), 0.0, 1.0),
			clampf(parts[2].strip_edges().to_float(), 0.0, 1.0)
		)
	return Color.from_string(s, fallback)

func _rebuild() -> void:
	# Remove old nodes
	for child in get_children():
		child.queue_free()
	# Rebuild next frame after queue_free completes
	call_deferred("_deferred_rebuild")

func _deferred_rebuild() -> void:
	_build_screen()
	_build_viewport()
	_apply_viewport_to_screen()
	_scan_for_artifacts()


# ═══════════════════════════════════════════════════════════════════
# 2D CANVAS (draws inside SubViewport)
# ═══════════════════════════════════════════════════════════════════

class _ScreenCanvas extends Control:
	var screen_ref: ScienceScreen

	# Color palette for cell values
	var CELL_COLORS: Array = [
		Color(0.05, 0.05, 0.08),   # 0 — empty/background
		Color(0.2, 0.8, 0.4),      # 1 — primary (green)
		Color(0.3, 0.5, 0.9),      # 2 — secondary (blue)
		Color(0.9, 0.4, 0.2),      # 3 — tertiary (orange)
		Color(0.8, 0.2, 0.7),      # 4 — quaternary (magenta)
	]

	func _draw() -> void:
		if not screen_ref:
			return

		var vp_size := size

		# ── Background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), screen_ref.screen_color)

		# ── Header bar ──
		var header_h := 32.0
		draw_rect(Rect2(0, 0, vp_size.x, header_h), Color(0.08, 0.08, 0.12))

		var title := screen_ref._label_name if screen_ref._label_name != "" else "SCIENCE SCREEN"
		var font := ThemeDB.fallback_font
		var font_size := 14
		draw_string(font, Vector2(8, 22), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, screen_ref.highlight_color)

		# ── Status line ──
		var status_y := header_h + 16
		var status := "%dx%d  |  %s  |  %d cells" % [
			screen_ref._grid_cols, screen_ref._grid_rows,
			screen_ref._pattern_type, screen_ref._cell_count
		]
		draw_string(font, Vector2(8, status_y), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.55))

		# ── Visualization area ──
		var grid_top := status_y + 12.0
		var grid_margin := 16.0
		var grid_area := Vector2(vp_size.x - grid_margin * 2, vp_size.y - grid_top - grid_margin)

		# ── Point tracking mode ──
		if screen_ref._point_mode and is_instance_valid(screen_ref._tracking_point):
			_draw_point_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		if screen_ref._grid_cols > 0 and screen_ref._grid_rows > 0:
			var cell_w := grid_area.x / float(screen_ref._grid_cols)
			var cell_h := grid_area.y / float(screen_ref._grid_rows)
			var cell_size := minf(cell_w, cell_h)

			# Center the grid
			var total_w := cell_size * screen_ref._grid_cols
			var total_h := cell_size * screen_ref._grid_rows
			var ox := grid_margin + (grid_area.x - total_w) * 0.5
			var oy := grid_top + (grid_area.y - total_h) * 0.5

			# Draw grid background
			draw_rect(Rect2(ox - 1, oy - 1, total_w + 2, total_h + 2), screen_ref.grid_color)

			# Draw cells
			for row_idx in range(screen_ref._grid_rows):
				if row_idx >= screen_ref._grid_cells.size():
					break
				var row = screen_ref._grid_cells[row_idx]
				if not row is Array:
					continue
				for col_idx in range(screen_ref._grid_cols):
					if col_idx >= row.size():
						break
					var val: int = int(row[col_idx]) if row[col_idx] is int or row[col_idx] is float else 0
					var color: Color = CELL_COLORS[val % CELL_COLORS.size()]

					# Use highlight color for value 1
					if val == 1:
						color = screen_ref.highlight_color

					var cell_rect := Rect2(
						ox + col_idx * cell_size + 0.5,
						oy + row_idx * cell_size + 0.5,
						cell_size - 1.0,
						cell_size - 1.0
					)
					draw_rect(cell_rect, color)

			# Grid lines (subtle)
			var line_color := Color(screen_ref.grid_color, 0.3)
			for c in range(screen_ref._grid_cols + 1):
				var lx := ox + c * cell_size
				draw_line(Vector2(lx, oy), Vector2(lx, oy + total_h), line_color, 0.5)
			for r in range(screen_ref._grid_rows + 1):
				var ly := oy + r * cell_size
				draw_line(Vector2(ox, ly), Vector2(ox + total_w, ly), line_color, 0.5)
		else:
			# No data — show waiting message
			var msg := "Scanning for artifacts..."
			draw_string(font, Vector2(vp_size.x * 0.5 - 60, vp_size.y * 0.5), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.3, 0.35))

	func _draw_point_tracker(vp_size: Vector2, grid_top: float, margin: float, area: Vector2, font: Font) -> void:
		var pos: Vector3 = screen_ref._tracking_point.global_position
		var grid_range: float = 5.0

		# ── Scientific dark background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.02, 0.02, 0.04))

		# ── Header ──
		draw_rect(Rect2(0, 0, vp_size.x, 36), Color(0.05, 0.05, 0.08))
		draw_string(font, Vector2(12, 25), "POINT POSITION", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.8, 1.0))
		draw_string(font, Vector2(vp_size.x - 150, 25), "P = (x, y)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.3, 0.4))

		# ── Coordinate grid area (X horizontal, Y vertical) ──
		var grid_top_y: float = 44.0
		var side: float = minf(area.x, vp_size.y - grid_top_y - 50)
		var ox: float = (vp_size.x - side) * 0.5
		var oy: float = grid_top_y + 4

		# Grid background
		draw_rect(Rect2(ox - 1, oy - 1, side + 2, side + 2), Color(0.04, 0.04, 0.06))

		# Minor grid (thin)
		var minor_div: int = 20
		var minor_step: float = side / float(minor_div)
		for i in range(minor_div + 1):
			var p: float = float(i) * minor_step
			draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + side), Color(0.06, 0.07, 0.09), 0.5)
			draw_line(Vector2(ox, oy + p), Vector2(ox + side, oy + p), Color(0.06, 0.07, 0.09), 0.5)

		# Major grid (brighter)
		var major_div: int = 4
		var major_step: float = side / float(major_div)
		for i in range(major_div + 1):
			var p: float = float(i) * major_step
			draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + side), Color(0.1, 0.12, 0.16), 1.0)
			draw_line(Vector2(ox, oy + p), Vector2(ox + side, oy + p), Color(0.1, 0.12, 0.16), 1.0)

		# Center axes
		var cx: float = ox + side * 0.5
		var cy: float = oy + side * 0.5
		# X axis (red)
		draw_line(Vector2(ox, cy), Vector2(ox + side, cy), Color(0.7, 0.15, 0.15, 0.5), 1.5)
		# Y axis (green) — Godot Y maps to screen vertical
		draw_line(Vector2(cx, oy), Vector2(cx, oy + side), Color(0.15, 0.7, 0.15, 0.5), 1.5)

		# Axis labels with values
		draw_string(font, Vector2(ox + side + 4, cy + 4), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.2, 0.2))
		draw_string(font, Vector2(cx + 4, oy - 2), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.7, 0.2))

		# Scale labels at edges
		var range_str: String = "%.0f" % grid_range
		draw_string(font, Vector2(ox - 2, cy + 14), "-%s" % range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))
		draw_string(font, Vector2(ox + side - 14, cy + 14), range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))
		draw_string(font, Vector2(cx + 6, oy + side - 2), "-%s" % range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))
		draw_string(font, Vector2(cx + 6, oy + 10), range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))

		# ── Map position: X → screen X, Y → screen Y (inverted: up = positive) ──
		var dot_x: float = cx + (pos.x / grid_range) * (side * 0.5)
		var dot_y: float = cy - (pos.y / grid_range) * (side * 0.5)  # Invert Y so up is positive

		# ── Trail ──
		if screen_ref._point_trail.size() > 1:
			for i in range(screen_ref._point_trail.size() - 1):
				var t0: Vector3 = screen_ref._point_trail[i]
				var t1: Vector3 = screen_ref._point_trail[i + 1]
				var tx0: float = cx + (t0.x / grid_range) * (side * 0.5)
				var ty0: float = cy - (t0.y / grid_range) * (side * 0.5)
				var tx1: float = cx + (t1.x / grid_range) * (side * 0.5)
				var ty1: float = cy - (t1.y / grid_range) * (side * 0.5)
				var alpha: float = float(i) / float(screen_ref._point_trail.size()) * 0.5
				draw_line(Vector2(tx0, ty0), Vector2(tx1, ty1), Color(0.3, 0.8, 1.0, alpha), 1.5)

		# ── Projection lines from dot to axes ──
		# Dashed line to X axis
		draw_line(Vector2(dot_x, dot_y), Vector2(dot_x, cy), Color(0.7, 0.15, 0.15, 0.3), 1.0)
		# Dashed line to Y axis
		draw_line(Vector2(dot_x, dot_y), Vector2(cx, dot_y), Color(0.15, 0.7, 0.15, 0.3), 1.0)
		# Tick marks on axes
		draw_rect(Rect2(dot_x - 1, cy - 4, 2, 8), Color(0.9, 0.3, 0.3))
		draw_rect(Rect2(cx - 4, dot_y - 1, 8, 2), Color(0.3, 0.9, 0.3))

		# ── Point dot (glowing) ──
		draw_circle(Vector2(dot_x, dot_y), 16.0, Color(1.0, 0.6, 1.0, 0.1))
		draw_circle(Vector2(dot_x, dot_y), 11.0, Color(1.0, 0.6, 1.0, 0.25))
		draw_circle(Vector2(dot_x, dot_y), 6.0, Color(1.0, 0.8, 1.0))

		# ── Coordinate readout (bottom panel) ──
		var panel_y: float = oy + side + 8
		draw_rect(Rect2(ox, panel_y, side, 48), Color(0.04, 0.04, 0.06))
		draw_rect(Rect2(ox, panel_y, side, 1), Color(0.15, 0.2, 0.25))

		# X value
		var x_str: String = "x = %.3f" % pos.x
		draw_string(font, Vector2(ox + 14, panel_y + 20), x_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.3, 0.3))

		# Y value
		var y_str: String = "y = %.3f" % pos.y
		draw_string(font, Vector2(ox + side * 0.5 + 14, panel_y + 20), y_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.3, 0.9, 0.3))

		# Full vector
		var vec_str: String = "P = (%.2f, %.2f)" % [pos.x, pos.y]
		draw_string(font, Vector2(ox + 14, panel_y + 40), vec_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.6))
