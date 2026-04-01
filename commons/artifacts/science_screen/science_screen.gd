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

## Line tracking mode — two endpoints forming a line segment
var _line_mode: bool = false
var _tracking_line_p1: Node3D = null
var _tracking_line_p2: Node3D = null

## Draw dot mode — tracks a drawing artifact's trail
var _draw_mode: bool = false
var _tracking_draw_dot: Node3D = null

## Triangle mode — three vertices forming a triangle
var _triangle_mode: bool = false
var _tracking_tri_points: Array[Node3D] = []

## Generic mode — catch-all for other artifact types
var _generic_mode: bool = false
var _generic_mode_name: String = ""
var _tracking_generic: Node3D = null

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
		# Scan for visualization modes in priority order
		if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode and not _generic_mode:
			_scan_for_points()
		if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode and not _generic_mode:
			_scan_for_lines()
		if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode and not _generic_mode:
			_scan_for_draw_dot()
		if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode and not _generic_mode:
			_scan_for_triangles()
		if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode and not _generic_mode:
			_scan_for_generic()

	# Track point position for trail
	if _point_mode and is_instance_valid(_tracking_point) and _tracking_point.visible:
		var pos: Vector3 = _tracking_point.global_position
		_point_trail.append(pos)
		if _point_trail.size() > MAX_TRAIL:
			_point_trail.pop_front()

	_canvas.queue_redraw()


# ═══════════════════════════════════════════════════════════════════
# CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════

func _build_screen() -> void:
	var screen_y: float = screen_height * 0.5 + 0.05

	# ── Outer bevel (dark, larger border for depth) ──
	var outer_bevel: MeshInstance3D = MeshInstance3D.new()
	var outer_plane: PlaneMesh = PlaneMesh.new()
	var outer_margin: float = 0.07
	outer_plane.size = Vector2(screen_width + outer_margin * 2, screen_height + outer_margin * 2)
	outer_plane.orientation = PlaneMesh.FACE_Z
	outer_bevel.mesh = outer_plane
	outer_bevel.position = Vector3(0, screen_y, -0.012)
	add_child(outer_bevel)

	var outer_mat: StandardMaterial3D = StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.08, 0.08, 0.1)
	outer_mat.metallic = 0.8
	outer_mat.roughness = 0.2
	outer_bevel.material_override = outer_mat

	# ── Inner border frame (lighter) ──
	_border_mesh = MeshInstance3D.new()
	var border_plane: PlaneMesh = PlaneMesh.new()
	var border_margin: float = 0.04
	border_plane.size = Vector2(screen_width + border_margin * 2, screen_height + border_margin * 2)
	border_plane.orientation = PlaneMesh.FACE_Z
	_border_mesh.mesh = border_plane
	_border_mesh.position = Vector3(0, screen_y, -0.008)
	add_child(_border_mesh)

	var border_mat: StandardMaterial3D = StandardMaterial3D.new()
	border_mat.albedo_color = border_color
	border_mat.metallic = 0.6
	border_mat.roughness = 0.3
	_border_mesh.material_override = border_mat

	# ── Screen quad (standing upright, face toward +Z) ──
	_screen_mesh = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(screen_width, screen_height)
	plane.orientation = PlaneMesh.FACE_Z
	_screen_mesh.mesh = plane
	_screen_mesh.position = Vector3(0, screen_y, 0)
	add_child(_screen_mesh)

	# Screen base material (will be replaced by viewport texture)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = screen_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mesh.material_override = mat

	# ── LED indicator dot (top-right corner, small green sphere) ──
	var led: MeshInstance3D = MeshInstance3D.new()
	var led_sphere: SphereMesh = SphereMesh.new()
	led_sphere.radius = 0.012
	led_sphere.height = 0.024
	led.mesh = led_sphere
	led.position = Vector3(screen_width * 0.5 + border_margin + 0.01, screen_y + screen_height * 0.5 + border_margin - 0.01, 0.005)
	add_child(led)

	var led_mat: StandardMaterial3D = StandardMaterial3D.new()
	led_mat.albedo_color = Color(0.2, 1.0, 0.3)
	led_mat.emission_enabled = true
	led_mat.emission = Color(0.2, 1.0, 0.3)
	led_mat.emission_energy_multiplier = 2.0
	led_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	led.material_override = led_mat

	# ── "ADA RESEARCH" label (bottom-left of border, 3D text via Label3D) ──
	var brand_label: Label3D = Label3D.new()
	brand_label.text = "ADA RESEARCH"
	brand_label.font_size = 28
	brand_label.modulate = Color(0.35, 0.35, 0.4)
	brand_label.position = Vector3(-screen_width * 0.5 + 0.15, screen_y - screen_height * 0.5 - border_margin - 0.015, 0.002)
	brand_label.pixel_size = 0.001
	brand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(brand_label)

	# ── Stand pole ──
	_stand_mesh = MeshInstance3D.new()
	var stand_box: BoxMesh = BoxMesh.new()
	stand_box.size = Vector3(0.06, screen_y, 0.06)
	_stand_mesh.mesh = stand_box
	_stand_mesh.position = Vector3(0, screen_y * 0.5, -0.02)
	add_child(_stand_mesh)

	var stand_mat: StandardMaterial3D = StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.15, 0.15, 0.18)
	stand_mat.metallic = 0.7
	stand_mat.roughness = 0.25
	_stand_mesh.material_override = stand_mat

	# ── Stand base (wider foot) ──
	var base_mesh: MeshInstance3D = MeshInstance3D.new()
	var base_box: BoxMesh = BoxMesh.new()
	base_box.size = Vector3(0.3, 0.02, 0.2)
	base_mesh.mesh = base_box
	base_mesh.position = Vector3(0, 0.01, -0.02)
	add_child(base_mesh)

	var base_mat: StandardMaterial3D = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.12, 0.12, 0.15)
	base_mat.metallic = 0.8
	base_mat.roughness = 0.2
	base_mesh.material_override = base_mat

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


## ── Line scanning: find artifacts with "line" in lookup_name that have two child points ──
func _scan_for_lines() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var is_line: bool = "line" in lookup or "line" in cname
		if not is_line:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		# Find two child points (RigidBody3D or Node3D with "point" / "p1" / "p2" in name)
		var points: Array[Node3D] = []
		for sub in child.get_children():
			if sub is Node3D:
				var sn: String = sub.name.to_lower()
				if "point" in sn or "p1" in sn or "p2" in sn or "endpoint" in sn or sub.get("freeze") != null:
					points.append(sub as Node3D)
		if points.size() >= 2:
			_tracking_line_p1 = points[0]
			_tracking_line_p2 = points[1]
			_line_mode = true
			_label_name = "LINE ANALYZER"
			_source_artifact_name = lookup if lookup != "" else child.name
			print("[ScienceScreen] Tracking line: %s" % _source_artifact_name)
			return

## ── Draw dot scanning: find artifacts with "draw_dot" in lookup_name ──
func _scan_for_draw_dot() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var is_draw: bool = "draw_dot" in lookup or "draw_dot" in cname or "draw" in lookup
		if not is_draw:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		_tracking_draw_dot = child as Node3D
		_draw_mode = true
		_label_name = "DRAW PATH TRACER"
		_source_artifact_name = lookup if lookup != "" else child.name
		print("[ScienceScreen] Tracking draw_dot: %s" % _source_artifact_name)
		return

## ── Triangle scanning: find artifacts with "triangle" in lookup_name ──
func _scan_for_triangles() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var is_tri: bool = "triangle" in lookup or "triangle" in cname
		if not is_tri:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		# Collect child points (vertices)
		var verts: Array[Node3D] = []
		for sub in child.get_children():
			if sub is Node3D:
				var sn: String = sub.name.to_lower()
				if "point" in sn or "vertex" in sn or "vert" in sn or sub.get("freeze") != null:
					verts.append(sub as Node3D)
		if verts.size() >= 3:
			_tracking_tri_points = [verts[0], verts[1], verts[2]]
			_triangle_mode = true
			_label_name = "TRIANGLE ANALYZER"
			_source_artifact_name = lookup if lookup != "" else child.name
			print("[ScienceScreen] Tracking triangle: %s" % _source_artifact_name)
			return

## ── Generic scanning: catch-all for sorting, noise, wave, force, fractal, swarm, graph, mesh ──
func _scan_for_generic() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	var keywords: PackedStringArray = PackedStringArray([
		"sort", "noise", "wave", "force", "fractal", "swarm", "graph", "mesh",
		"boid", "flock", "particle", "field", "oscillat", "pendulum", "spring"
	])
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var combined: String = lookup.to_lower() + " " + cname
		var matched: bool = false
		var match_word: String = ""
		for kw in keywords:
			if kw in combined:
				matched = true
				match_word = kw
				break
		if not matched:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		_tracking_generic = child as Node3D
		_generic_mode = true
		_generic_mode_name = match_word
		_label_name = match_word.to_upper() + " MONITOR"
		_source_artifact_name = lookup if lookup != "" else child.name
		print("[ScienceScreen] Tracking generic (%s): %s" % [match_word, _source_artifact_name])
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

		var vp_size: Vector2 = size

		# ── Background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), screen_ref.screen_color)

		# ── Header bar ──
		var header_h: float = 32.0
		draw_rect(Rect2(0, 0, vp_size.x, header_h), Color(0.08, 0.08, 0.12))

		var title: String = screen_ref._label_name if screen_ref._label_name != "" else "SCIENCE SCREEN"
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 14
		draw_string(font, Vector2(8, 22), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, screen_ref.highlight_color)

		# ── Status line ──
		var status_y: float = header_h + 16
		var status: String = "%dx%d  |  %s  |  %d cells" % [
			screen_ref._grid_cols, screen_ref._grid_rows,
			screen_ref._pattern_type, screen_ref._cell_count
		]
		draw_string(font, Vector2(8, status_y), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.55))

		# ── Visualization area ──
		var grid_top: float = status_y + 12.0
		var grid_margin: float = 16.0
		var grid_area: Vector2 = Vector2(vp_size.x - grid_margin * 2, vp_size.y - grid_top - grid_margin)

		# ── Scanlines overlay (drawn at end for CRT feel) ──
		# Applied after content by each mode individually

		# ── Line tracking mode ──
		if screen_ref._line_mode and is_instance_valid(screen_ref._tracking_line_p1) and is_instance_valid(screen_ref._tracking_line_p2):
			_draw_line_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		# ── Draw dot tracking mode ──
		if screen_ref._draw_mode and is_instance_valid(screen_ref._tracking_draw_dot):
			_draw_dot_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		# ── Triangle tracking mode ──
		if screen_ref._triangle_mode and screen_ref._tracking_tri_points.size() >= 3:
			var tri_valid: bool = true
			for tp in screen_ref._tracking_tri_points:
				if not is_instance_valid(tp):
					tri_valid = false
					break
			if tri_valid:
				_draw_triangle_tracker(vp_size, grid_top, grid_margin, grid_area, font)
				return

		# ── Generic tracking mode ──
		if screen_ref._generic_mode and is_instance_valid(screen_ref._tracking_generic):
			_draw_generic_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

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

		# ── Scanlines ──
		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# SHARED HELPERS
	# ═══════════════════════════════════════════════════════════════

	func _draw_scanlines(vp_size: Vector2) -> void:
		var scanline_spacing: int = 3
		var y_pos: int = 0
		while y_pos < int(vp_size.y):
			draw_line(Vector2(0, float(y_pos)), Vector2(vp_size.x, float(y_pos)), Color(0.0, 0.0, 0.0, 0.04), 1.0)
			y_pos += scanline_spacing

	func _draw_xy_grid(vp_size: Vector2, grid_top_y: float, area: Vector2, font: Font, grid_range: float) -> Dictionary:
		## Draws a standard XY coordinate grid and returns {ox, oy, side, cx, cy}
		var side: float = minf(area.x, vp_size.y - grid_top_y - 70.0)
		var ox: float = (vp_size.x - side) * 0.5
		var oy: float = grid_top_y + 4.0

		# Grid background
		draw_rect(Rect2(ox - 1.0, oy - 1.0, side + 2.0, side + 2.0), Color(0.04, 0.04, 0.06))

		# Minor grid
		var minor_div: int = 20
		var minor_step: float = side / float(minor_div)
		for i in range(minor_div + 1):
			var p: float = float(i) * minor_step
			draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + side), Color(0.06, 0.07, 0.09), 0.5)
			draw_line(Vector2(ox, oy + p), Vector2(ox + side, oy + p), Color(0.06, 0.07, 0.09), 0.5)

		# Major grid
		var major_div: int = 4
		var major_step: float = side / float(major_div)
		for i in range(major_div + 1):
			var p: float = float(i) * major_step
			draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + side), Color(0.1, 0.12, 0.16), 1.0)
			draw_line(Vector2(ox, oy + p), Vector2(ox + side, oy + p), Color(0.1, 0.12, 0.16), 1.0)

		# Center axes
		var cx: float = ox + side * 0.5
		var cy: float = oy + side * 0.5
		draw_line(Vector2(ox, cy), Vector2(ox + side, cy), Color(0.7, 0.15, 0.15, 0.5), 1.5)
		draw_line(Vector2(cx, oy), Vector2(cx, oy + side), Color(0.15, 0.7, 0.15, 0.5), 1.5)

		# Axis labels
		draw_string(font, Vector2(ox + side + 4.0, cy + 4.0), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.2, 0.2))
		draw_string(font, Vector2(cx + 4.0, oy - 2.0), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.7, 0.2))

		# Scale labels
		var range_str: String = "%.0f" % grid_range
		draw_string(font, Vector2(ox - 2.0, cy + 14.0), "-%s" % range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))
		draw_string(font, Vector2(ox + side - 14.0, cy + 14.0), range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))

		return {"ox": ox, "oy": oy, "side": side, "cx": cx, "cy": cy}

	func _world_to_screen(world_pos: Vector3, cx: float, cy: float, side: float, grid_range: float) -> Vector2:
		var sx: float = cx + (world_pos.x / grid_range) * (side * 0.5)
		var sy: float = cy - (world_pos.y / grid_range) * (side * 0.5)
		return Vector2(sx, sy)


	# ═══════════════════════════════════════════════════════════════
	# LINE TRACKER
	# ═══════════════════════════════════════════════════════════════

	func _draw_line_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		var pos_a: Vector3 = screen_ref._tracking_line_p1.global_position
		var pos_b: Vector3 = screen_ref._tracking_line_p2.global_position
		var grid_range: float = 5.0

		# ── Background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.02, 0.02, 0.04))

		# ── Header ──
		draw_rect(Rect2(0.0, 0.0, vp_size.x, 36.0), Color(0.05, 0.05, 0.08))
		draw_string(font, Vector2(12.0, 25.0), "LINE SEGMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.8, 1.0))
		draw_string(font, Vector2(vp_size.x - 200.0, 25.0), "AB = |B - A|", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.3, 0.4))

		# ── XY grid ──
		var grid_top_y: float = 44.0
		var g: Dictionary = _draw_xy_grid(vp_size, grid_top_y, area, font, grid_range)
		var ox: float = g["ox"]
		var oy: float = g["oy"]
		var side: float = g["side"]
		var cx: float = g["cx"]
		var cy: float = g["cy"]

		# Map world to screen
		var sa: Vector2 = _world_to_screen(pos_a, cx, cy, side, grid_range)
		var sb: Vector2 = _world_to_screen(pos_b, cx, cy, side, grid_range)

		# ── Projection lines to axes ──
		draw_line(Vector2(sa.x, sa.y), Vector2(sa.x, cy), Color(0.7, 0.15, 0.15, 0.2), 1.0)
		draw_line(Vector2(sa.x, sa.y), Vector2(cx, sa.y), Color(0.15, 0.7, 0.15, 0.2), 1.0)
		draw_line(Vector2(sb.x, sb.y), Vector2(sb.x, cy), Color(0.7, 0.15, 0.15, 0.2), 1.0)
		draw_line(Vector2(sb.x, sb.y), Vector2(cx, sb.y), Color(0.15, 0.7, 0.15, 0.2), 1.0)

		# ── Connecting line (golden) ──
		draw_line(sa, sb, Color(1.0, 0.85, 0.3, 0.9), 2.5)

		# ── Endpoint A (cyan) ──
		draw_circle(sa, 12.0, Color(0.3, 0.9, 1.0, 0.15))
		draw_circle(sa, 7.0, Color(0.3, 0.9, 1.0, 0.4))
		draw_circle(sa, 4.0, Color(0.5, 1.0, 1.0))
		draw_string(font, Vector2(sa.x + 8.0, sa.y - 8.0), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.9, 1.0))

		# ── Endpoint B (orange) ──
		draw_circle(sb, 12.0, Color(1.0, 0.6, 0.2, 0.15))
		draw_circle(sb, 7.0, Color(1.0, 0.6, 0.2, 0.4))
		draw_circle(sb, 4.0, Color(1.0, 0.8, 0.5))
		draw_string(font, Vector2(sb.x + 8.0, sb.y - 8.0), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.6, 0.2))

		# ── Readout panel ──
		var panel_y: float = oy + side + 8.0
		draw_rect(Rect2(ox, panel_y, side, 60.0), Color(0.04, 0.04, 0.06))
		draw_rect(Rect2(ox, panel_y, side, 1.0), Color(0.15, 0.2, 0.25))

		# Distance
		var dx: float = pos_b.x - pos_a.x
		var dy: float = pos_b.y - pos_a.y
		var dist: float = sqrt(dx * dx + dy * dy)
		var dist_str: String = "|AB| = %.3f" % dist
		draw_string(font, Vector2(ox + 14.0, panel_y + 18.0), dist_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.3))

		# Angle
		var angle_rad: float = atan2(dy, dx)
		var angle_deg: float = rad_to_deg(angle_rad)
		var angle_str: String = "theta = %.1f deg" % angle_deg
		draw_string(font, Vector2(ox + side * 0.5 + 14.0, panel_y + 18.0), angle_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.8))

		# Coordinates
		var a_str: String = "A = (%.2f, %.2f)" % [pos_a.x, pos_a.y]
		var b_str: String = "B = (%.2f, %.2f)" % [pos_b.x, pos_b.y]
		draw_string(font, Vector2(ox + 14.0, panel_y + 40.0), a_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.9, 1.0, 0.7))
		draw_string(font, Vector2(ox + side * 0.5 + 14.0, panel_y + 40.0), b_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.6, 0.2, 0.7))

		# Delta
		var delta_str: String = "dx=%.2f  dy=%.2f" % [dx, dy]
		draw_string(font, Vector2(ox + 14.0, panel_y + 56.0), delta_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# DRAW DOT / PATH TRACER
	# ═══════════════════════════════════════════════════════════════

	func _draw_dot_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		var draw_node: Node3D = screen_ref._tracking_draw_dot
		var grid_range: float = 5.0

		# ── Background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.02, 0.02, 0.04))

		# ── Header ──
		draw_rect(Rect2(0.0, 0.0, vp_size.x, 36.0), Color(0.05, 0.05, 0.08))
		draw_string(font, Vector2(12.0, 25.0), "DRAW PATH TRACER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.8, 1.0))

		# ── XY grid ──
		var grid_top_y: float = 44.0
		var g: Dictionary = _draw_xy_grid(vp_size, grid_top_y, area, font, grid_range)
		var ox: float = g["ox"]
		var oy: float = g["oy"]
		var side: float = g["side"]
		var cx: float = g["cx"]
		var cy: float = g["cy"]

		# ── Get trail points from the draw_dot artifact ──
		var trail_points: Array = []
		if "_trail_points" in draw_node:
			trail_points = draw_node.get("_trail_points")
		elif "trail_points" in draw_node:
			trail_points = draw_node.get("trail_points")
		elif "points" in draw_node:
			trail_points = draw_node.get("points")

		# Fallback: use current position as single point
		if trail_points.size() == 0:
			trail_points = [draw_node.global_position]

		# ── Compute bounding box ──
		var min_x: float = 99999.0
		var max_x: float = -99999.0
		var min_y: float = 99999.0
		var max_y: float = -99999.0
		var total_length: float = 0.0

		for i in range(trail_points.size()):
			var tp: Vector3 = trail_points[i] if trail_points[i] is Vector3 else Vector3.ZERO
			if tp.x < min_x:
				min_x = tp.x
			if tp.x > max_x:
				max_x = tp.x
			if tp.y < min_y:
				min_y = tp.y
			if tp.y > max_y:
				max_y = tp.y
			if i > 0:
				var prev_tp: Vector3 = trail_points[i - 1] if trail_points[i - 1] is Vector3 else Vector3.ZERO
				var seg_dx: float = tp.x - prev_tp.x
				var seg_dy: float = tp.y - prev_tp.y
				total_length += sqrt(seg_dx * seg_dx + seg_dy * seg_dy)

		# ── Draw bounding box ──
		var bb_tl: Vector2 = _world_to_screen(Vector3(min_x, max_y, 0.0), cx, cy, side, grid_range)
		var bb_br: Vector2 = _world_to_screen(Vector3(max_x, min_y, 0.0), cx, cy, side, grid_range)
		var bb_width: float = bb_br.x - bb_tl.x
		var bb_height: float = bb_br.y - bb_tl.y
		if bb_width > 2.0 and bb_height > 2.0:
			draw_rect(Rect2(bb_tl.x, bb_tl.y, bb_width, bb_height), Color(0.3, 0.5, 0.8, 0.08))
			# Border of bounding box
			draw_line(Vector2(bb_tl.x, bb_tl.y), Vector2(bb_tl.x + bb_width, bb_tl.y), Color(0.3, 0.5, 0.8, 0.2), 1.0)
			draw_line(Vector2(bb_tl.x + bb_width, bb_tl.y), Vector2(bb_tl.x + bb_width, bb_tl.y + bb_height), Color(0.3, 0.5, 0.8, 0.2), 1.0)
			draw_line(Vector2(bb_tl.x + bb_width, bb_tl.y + bb_height), Vector2(bb_tl.x, bb_tl.y + bb_height), Color(0.3, 0.5, 0.8, 0.2), 1.0)
			draw_line(Vector2(bb_tl.x, bb_tl.y + bb_height), Vector2(bb_tl.x, bb_tl.y), Color(0.3, 0.5, 0.8, 0.2), 1.0)

		# ── Draw trail as connected line segments ──
		if trail_points.size() > 1:
			for i in range(trail_points.size() - 1):
				var p0: Vector3 = trail_points[i] if trail_points[i] is Vector3 else Vector3.ZERO
				var p1: Vector3 = trail_points[i + 1] if trail_points[i + 1] is Vector3 else Vector3.ZERO
				var s0: Vector2 = _world_to_screen(p0, cx, cy, side, grid_range)
				var s1: Vector2 = _world_to_screen(p1, cx, cy, side, grid_range)
				var trail_alpha: float = 0.3 + 0.7 * (float(i) / float(trail_points.size()))
				draw_line(s0, s1, Color(0.2, 0.9, 0.5, trail_alpha), 2.0)

		# ── Draw current position as a bright dot ──
		var cur_pos: Vector3 = draw_node.global_position
		var cur_screen: Vector2 = _world_to_screen(cur_pos, cx, cy, side, grid_range)
		draw_circle(cur_screen, 10.0, Color(0.2, 1.0, 0.5, 0.15))
		draw_circle(cur_screen, 6.0, Color(0.2, 1.0, 0.5, 0.4))
		draw_circle(cur_screen, 3.0, Color(0.5, 1.0, 0.7))

		# ── Readout panel ──
		var panel_y: float = oy + side + 8.0
		draw_rect(Rect2(ox, panel_y, side, 48.0), Color(0.04, 0.04, 0.06))
		draw_rect(Rect2(ox, panel_y, side, 1.0), Color(0.15, 0.2, 0.25))

		var count_str: String = "Points: %d" % trail_points.size()
		draw_string(font, Vector2(ox + 14.0, panel_y + 18.0), count_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.9, 0.5))

		var len_str: String = "Length: %.3f" % total_length
		draw_string(font, Vector2(ox + side * 0.4, panel_y + 18.0), len_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.8, 0.7))

		var pos_str: String = "Pos: (%.2f, %.2f)" % [cur_pos.x, cur_pos.y]
		draw_string(font, Vector2(ox + 14.0, panel_y + 40.0), pos_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.5))

		var bb_str: String = "BBox: %.2f x %.2f" % [max_x - min_x, max_y - min_y]
		draw_string(font, Vector2(ox + side * 0.5, panel_y + 40.0), bb_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.5, 0.8, 0.7))

		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# TRIANGLE ANALYZER
	# ═══════════════════════════════════════════════════════════════

	func _draw_triangle_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		var pa: Vector3 = screen_ref._tracking_tri_points[0].global_position
		var pb: Vector3 = screen_ref._tracking_tri_points[1].global_position
		var pc: Vector3 = screen_ref._tracking_tri_points[2].global_position
		var grid_range: float = 5.0

		# ── Background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.02, 0.02, 0.04))

		# ── Header ──
		draw_rect(Rect2(0.0, 0.0, vp_size.x, 36.0), Color(0.05, 0.05, 0.08))
		draw_string(font, Vector2(12.0, 25.0), "TRIANGLE ANALYZER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.8, 1.0))

		# ── XY grid ──
		var grid_top_y: float = 44.0
		var g: Dictionary = _draw_xy_grid(vp_size, grid_top_y, area, font, grid_range)
		var ox: float = g["ox"]
		var oy: float = g["oy"]
		var side: float = g["side"]
		var cx: float = g["cx"]
		var cy: float = g["cy"]

		# Map vertices to screen
		var sa: Vector2 = _world_to_screen(pa, cx, cy, side, grid_range)
		var sb: Vector2 = _world_to_screen(pb, cx, cy, side, grid_range)
		var sc: Vector2 = _world_to_screen(pc, cx, cy, side, grid_range)

		# ── Filled triangle (semi-transparent) ──
		var tri_color: Color = Color(0.3, 0.6, 0.9, 0.12)
		var tri_points: PackedVector2Array = PackedVector2Array([sa, sb, sc])
		var tri_colors: PackedColorArray = PackedColorArray([tri_color, tri_color, tri_color])
		draw_polygon(tri_points, tri_colors)

		# ── Triangle edges ──
		# AB (cyan to orange)
		draw_line(sa, sb, Color(0.4, 0.8, 0.9, 0.8), 2.0)
		# BC (orange to magenta)
		draw_line(sb, sc, Color(0.9, 0.5, 0.3, 0.8), 2.0)
		# CA (magenta to cyan)
		draw_line(sc, sa, Color(0.8, 0.3, 0.8, 0.8), 2.0)

		# ── Vertex A (cyan) ──
		draw_circle(sa, 10.0, Color(0.3, 0.9, 1.0, 0.2))
		draw_circle(sa, 5.0, Color(0.5, 1.0, 1.0))
		draw_string(font, Vector2(sa.x + 8.0, sa.y - 8.0), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.9, 1.0))

		# ── Vertex B (orange) ──
		draw_circle(sb, 10.0, Color(1.0, 0.6, 0.2, 0.2))
		draw_circle(sb, 5.0, Color(1.0, 0.8, 0.4))
		draw_string(font, Vector2(sb.x + 8.0, sb.y - 8.0), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.6, 0.2))

		# ── Vertex C (magenta) ──
		draw_circle(sc, 10.0, Color(0.9, 0.3, 0.8, 0.2))
		draw_circle(sc, 5.0, Color(1.0, 0.5, 0.9))
		draw_string(font, Vector2(sc.x + 8.0, sc.y - 8.0), "C", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.3, 0.8))

		# ── Centroid ──
		var centroid_x: float = (pa.x + pb.x + pc.x) / 3.0
		var centroid_y: float = (pa.y + pb.y + pc.y) / 3.0
		var centroid_screen: Vector2 = _world_to_screen(Vector3(centroid_x, centroid_y, 0.0), cx, cy, side, grid_range)
		draw_circle(centroid_screen, 4.0, Color(1.0, 1.0, 0.4, 0.6))
		draw_string(font, Vector2(centroid_screen.x + 6.0, centroid_screen.y - 4.0), "G", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 1.0, 0.4, 0.6))

		# ── Compute side lengths ──
		var ab_dx: float = pb.x - pa.x
		var ab_dy: float = pb.y - pa.y
		var len_ab: float = sqrt(ab_dx * ab_dx + ab_dy * ab_dy)

		var bc_dx: float = pc.x - pb.x
		var bc_dy: float = pc.y - pb.y
		var len_bc: float = sqrt(bc_dx * bc_dx + bc_dy * bc_dy)

		var ca_dx: float = pa.x - pc.x
		var ca_dy: float = pa.y - pc.y
		var len_ca: float = sqrt(ca_dx * ca_dx + ca_dy * ca_dy)

		# ── Compute angles (law of cosines) ──
		var angle_a: float = 0.0
		var angle_b: float = 0.0
		var angle_c: float = 0.0
		if len_ab > 0.001 and len_ca > 0.001:
			var cos_a: float = clampf((len_ab * len_ab + len_ca * len_ca - len_bc * len_bc) / (2.0 * len_ab * len_ca), -1.0, 1.0)
			angle_a = rad_to_deg(acos(cos_a))
		if len_ab > 0.001 and len_bc > 0.001:
			var cos_b: float = clampf((len_ab * len_ab + len_bc * len_bc - len_ca * len_ca) / (2.0 * len_ab * len_bc), -1.0, 1.0)
			angle_b = rad_to_deg(acos(cos_b))
		angle_c = 180.0 - angle_a - angle_b

		# ── Area (cross product / 2) ──
		var tri_area: float = absf((pb.x - pa.x) * (pc.y - pa.y) - (pc.x - pa.x) * (pb.y - pa.y)) * 0.5

		# ── Readout panel ──
		var panel_y: float = oy + side + 8.0
		draw_rect(Rect2(ox, panel_y, side, 68.0), Color(0.04, 0.04, 0.06))
		draw_rect(Rect2(ox, panel_y, side, 1.0), Color(0.15, 0.2, 0.25))

		# Side lengths
		var sides_str: String = "AB=%.2f  BC=%.2f  CA=%.2f" % [len_ab, len_bc, len_ca]
		draw_string(font, Vector2(ox + 14.0, panel_y + 16.0), sides_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.8, 0.9))

		# Angles
		var angles_str: String = "A=%.1f  B=%.1f  C=%.1f deg" % [angle_a, angle_b, angle_c]
		draw_string(font, Vector2(ox + 14.0, panel_y + 34.0), angles_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.7, 0.5))

		# Area
		var area_str: String = "Area = %.3f" % tri_area
		draw_string(font, Vector2(ox + 14.0, panel_y + 52.0), area_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.8, 0.3))

		# Centroid coordinates
		var cen_str: String = "Centroid = (%.2f, %.2f)" % [centroid_x, centroid_y]
		draw_string(font, Vector2(ox + side * 0.5, panel_y + 52.0), cen_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 1.0, 0.4, 0.5))

		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# GENERIC TRACKER (catch-all)
	# ═══════════════════════════════════════════════════════════════

	func _draw_generic_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		var target: Node3D = screen_ref._tracking_generic
		var mode_name: String = screen_ref._generic_mode_name

		# ── Background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.02, 0.02, 0.04))

		# ── Header ──
		draw_rect(Rect2(0.0, 0.0, vp_size.x, 36.0), Color(0.05, 0.05, 0.08))
		var header_text: String = mode_name.to_upper() + " MONITOR"
		draw_string(font, Vector2(12.0, 25.0), header_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.8, 1.0))
		draw_string(font, Vector2(vp_size.x - 180.0, 25.0), screen_ref._source_artifact_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.3, 0.4))

		# ── Visualization area ──
		var viz_top: float = 44.0
		var viz_margin: float = 20.0
		var viz_width: float = vp_size.x - viz_margin * 2.0
		var viz_height: float = vp_size.y - viz_top - 90.0

		# ── Draw background rect ──
		draw_rect(Rect2(viz_margin, viz_top, viz_width, viz_height), Color(0.04, 0.04, 0.06))

		# ── Mode-specific visualization ──
		if "sort" in mode_name:
			_draw_generic_sort(target, viz_margin, viz_top, viz_width, viz_height, font)
		elif "noise" in mode_name or "wave" in mode_name or "oscillat" in mode_name or "pendulum" in mode_name:
			_draw_generic_waveform(target, viz_margin, viz_top, viz_width, viz_height, font)
		elif "force" in mode_name or "swarm" in mode_name or "boid" in mode_name or "flock" in mode_name or "particle" in mode_name or "field" in mode_name or "spring" in mode_name:
			_draw_generic_scatter(target, viz_margin, viz_top, viz_width, viz_height, font)
		elif "graph" in mode_name or "mesh" in mode_name:
			_draw_generic_graph(target, viz_margin, viz_top, viz_width, viz_height, font)
		else:
			_draw_generic_radar(target, viz_margin, viz_top, viz_width, viz_height, font)

		# ── Info panel ──
		var panel_y: float = viz_top + viz_height + 8.0
		draw_rect(Rect2(viz_margin, panel_y, viz_width, 60.0), Color(0.04, 0.04, 0.06))
		draw_rect(Rect2(viz_margin, panel_y, viz_width, 1.0), Color(0.15, 0.2, 0.25))

		var pos: Vector3 = target.global_position
		var pos_str: String = "Position: (%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
		draw_string(font, Vector2(viz_margin + 14.0, panel_y + 18.0), pos_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.7, 0.9))

		var child_count: int = target.get_child_count()
		var child_str: String = "Children: %d" % child_count
		draw_string(font, Vector2(viz_margin + 14.0, panel_y + 38.0), child_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.5))

		var type_str: String = "Type: %s" % mode_name
		draw_string(font, Vector2(viz_margin + viz_width * 0.5, panel_y + 38.0), type_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.5))

		_draw_scanlines(vp_size)


	# ── Generic sub-modes ──

	func _draw_generic_sort(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Bar chart visualization — tries to read values from the artifact
		var values: Array = []
		if "values" in target:
			values = target.get("values")
		elif "data" in target:
			values = target.get("data")

		# Fallback: generate from children positions
		if values.size() == 0:
			for child in target.get_children():
				if child is Node3D:
					values.append(child.position.y)

		if values.size() == 0:
			# Deterministic fallback pattern
			var seed_hash: int = hash(target.name)
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = seed_hash
			for bar_idx in range(16):
				values.append(rng.randf_range(0.1, 1.0))

		var bar_count: int = mini(values.size(), 64)
		var bar_width: float = viz_w / float(bar_count)
		var max_val: float = 0.001
		for v_idx in range(bar_count):
			var v: float = absf(float(values[v_idx]))
			if v > max_val:
				max_val = v

		for bar_i in range(bar_count):
			var normalized: float = absf(float(values[bar_i])) / max_val
			var bar_h: float = normalized * viz_h * 0.9
			var bar_x: float = viz_x + float(bar_i) * bar_width + 1.0
			var bar_y: float = viz_y + viz_h - bar_h
			var hue: float = float(bar_i) / float(bar_count)
			var bar_color: Color = Color.from_hsv(hue * 0.3 + 0.4, 0.7, 0.8, 0.8)
			draw_rect(Rect2(bar_x, bar_y, maxf(bar_width - 2.0, 1.0), bar_h), bar_color)

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "n=%d" % bar_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_waveform(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Waveform line plot
		var mid_y: float = viz_y + viz_h * 0.5

		# Zero line
		draw_line(Vector2(viz_x, mid_y), Vector2(viz_x + viz_w, mid_y), Color(0.15, 0.15, 0.2), 1.0)

		# Generate waveform from target state
		var time_val: float = 0.0
		if "time" in target:
			time_val = float(target.get("time"))
		elif "_time" in target:
			time_val = float(target.get("_time"))
		else:
			time_val = float(Engine.get_frames_drawn()) * 0.016

		var step_count: int = int(viz_w)
		var prev_screen_y: float = mid_y
		for px in range(step_count):
			var t: float = float(px) / viz_w * 4.0 * PI + time_val
			var wave_val: float = sin(t) * 0.5 + sin(t * 2.3) * 0.25 + sin(t * 0.7) * 0.25
			var screen_y: float = mid_y - wave_val * viz_h * 0.4
			if px > 0:
				var alpha: float = 0.5 + 0.5 * absf(wave_val)
				draw_line(Vector2(viz_x + float(px) - 1.0, prev_screen_y), Vector2(viz_x + float(px), screen_y), Color(0.3, 0.8, 1.0, alpha), 1.5)
			prev_screen_y = screen_y

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "t=%.2f" % time_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_scatter(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Particle position scatter plot from children
		var scatter_range: float = 10.0
		var center_x: float = viz_x + viz_w * 0.5
		var center_y: float = viz_y + viz_h * 0.5
		var origin: Vector3 = target.global_position
		var particle_count: int = 0

		for child in target.get_children():
			if child is Node3D:
				var rel: Vector3 = child.global_position - origin
				var sx: float = center_x + (rel.x / scatter_range) * (viz_w * 0.45)
				var sy: float = center_y - (rel.y / scatter_range) * (viz_h * 0.45)
				# Clamp to visualization area
				sx = clampf(sx, viz_x + 2.0, viz_x + viz_w - 2.0)
				sy = clampf(sy, viz_y + 2.0, viz_y + viz_h - 2.0)
				var dot_hue: float = fmod(float(particle_count) * 0.1, 1.0)
				draw_circle(Vector2(sx, sy), 3.0, Color.from_hsv(dot_hue, 0.7, 0.9, 0.7))
				particle_count += 1

		# Cross-hairs at center
		draw_line(Vector2(center_x - 8.0, center_y), Vector2(center_x + 8.0, center_y), Color(0.5, 0.5, 0.6, 0.3), 1.0)
		draw_line(Vector2(center_x, center_y - 8.0), Vector2(center_x, center_y + 8.0), Color(0.5, 0.5, 0.6, 0.3), 1.0)

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "n=%d" % particle_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_graph(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Node and edge visualization from children
		var nodes_2d: Array = []  # Array of Vector2
		var origin: Vector3 = target.global_position
		var graph_range: float = 8.0
		var center_x: float = viz_x + viz_w * 0.5
		var center_y: float = viz_y + viz_h * 0.5

		for child in target.get_children():
			if child is Node3D:
				var rel: Vector3 = child.global_position - origin
				var nx: float = center_x + (rel.x / graph_range) * (viz_w * 0.4)
				var ny: float = center_y - (rel.y / graph_range) * (viz_h * 0.4)
				nodes_2d.append(Vector2(nx, ny))

		# Draw edges between nearby nodes
		for i in range(nodes_2d.size()):
			for j in range(i + 1, mini(nodes_2d.size(), i + 4)):
				var ni: Vector2 = nodes_2d[i]
				var nj: Vector2 = nodes_2d[j]
				var edge_dist: float = ni.distance_to(nj)
				if edge_dist < viz_w * 0.3:
					var edge_alpha: float = 1.0 - (edge_dist / (viz_w * 0.3))
					draw_line(ni, nj, Color(0.3, 0.5, 0.8, edge_alpha * 0.4), 1.0)

		# Draw nodes
		for k in range(nodes_2d.size()):
			var node_pos: Vector2 = nodes_2d[k]
			var node_hue: float = fmod(float(k) * 0.15, 1.0)
			draw_circle(node_pos, 5.0, Color.from_hsv(node_hue, 0.6, 0.9, 0.8))
			draw_circle(node_pos, 3.0, Color.from_hsv(node_hue, 0.4, 1.0))

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "V=%d" % nodes_2d.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_radar(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Fallback: radar/scope animation with artifact info
		var center_x: float = viz_x + viz_w * 0.5
		var center_y: float = viz_y + viz_h * 0.5
		var radius: float = minf(viz_w, viz_h) * 0.4

		# Concentric rings
		for ring_i in range(4):
			var ring_r: float = radius * (float(ring_i + 1) / 4.0)
			var ring_segments: int = 48
			for seg in range(ring_segments):
				var a0: float = float(seg) / float(ring_segments) * TAU
				var a1: float = float(seg + 1) / float(ring_segments) * TAU
				var r0: Vector2 = Vector2(center_x + cos(a0) * ring_r, center_y + sin(a0) * ring_r)
				var r1: Vector2 = Vector2(center_x + cos(a1) * ring_r, center_y + sin(a1) * ring_r)
				draw_line(r0, r1, Color(0.1, 0.2, 0.15, 0.4), 1.0)

		# Cross-hairs
		draw_line(Vector2(center_x - radius, center_y), Vector2(center_x + radius, center_y), Color(0.1, 0.3, 0.15, 0.3), 1.0)
		draw_line(Vector2(center_x, center_y - radius), Vector2(center_x, center_y + radius), Color(0.1, 0.3, 0.15, 0.3), 1.0)

		# Sweeping line (animated)
		var sweep_angle: float = fmod(float(Engine.get_frames_drawn()) * 0.03, TAU)
		var sweep_end_x: float = center_x + cos(sweep_angle) * radius
		var sweep_end_y: float = center_y + sin(sweep_angle) * radius
		draw_line(Vector2(center_x, center_y), Vector2(sweep_end_x, sweep_end_y), Color(0.2, 1.0, 0.4, 0.6), 2.0)

		# Sweep trail (fading arc behind the line)
		for trail_i in range(20):
			var trail_angle: float = sweep_angle - float(trail_i) * 0.05
			var trail_end_x: float = center_x + cos(trail_angle) * radius
			var trail_end_y: float = center_y + sin(trail_angle) * radius
			var trail_alpha: float = 0.3 * (1.0 - float(trail_i) / 20.0)
			draw_line(Vector2(center_x, center_y), Vector2(trail_end_x, trail_end_y), Color(0.2, 0.8, 0.3, trail_alpha), 1.0)

		# Center dot
		draw_circle(Vector2(center_x, center_y), 4.0, Color(0.3, 1.0, 0.5, 0.8))

		# Artifact name
		var name_str: String = screen_ref._source_artifact_name
		draw_string(font, Vector2(viz_x + 8.0, viz_y + viz_h - 8.0), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.7, 0.3, 0.6))
