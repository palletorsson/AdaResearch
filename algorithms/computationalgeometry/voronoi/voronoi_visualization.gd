# ===========================================================================
# VoronoiVisualization — Fortune Sweep & Delaunay Dual
# Voronoi diagrams with animated Fortune's algorithm sweep line,
# Delaunay triangulation dual, and weighted power diagrams.
# Elevated features:
#   - Fortune's algorithm sweep line with beach line parabolas & circle events
#   - Delaunay triangulation dual animation
#   - Power diagrams for weighted sites
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

class_name VoronoiVisualization
extends Node3D

## Voronoi diagrams: Fortune sweep, Delaunay dual, power diagrams.
## VORONOI mode shows Fortune's sweep line with beach line parabolas.
## DELAUNAY mode highlights the dual triangulation with animated edges.
## POWER mode uses weighted sites for power diagrams.

# --- Configuration ---
@export var site_count: int = 12
@export var field_width: float = 6.0
@export var field_height: float = 5.0
@export var sweep_speed: float = 0.8
@export var grid_resolution: int = 80
@export var show_edges: bool = true
@export var show_cells: bool = true

# --- Mode ---
enum Mode { VORONOI, DELAUNAY, POWER }
var _mode: int = Mode.VORONOI

# --- Internal state ---
var _time: float = 0.0
var _sites: Array = []          # Array of Vector2
var _weights: Array = []        # float weights for power diagrams
var _cell_colors: Array = []    # Color per site
var _adjacency: Array = []      # Array of [i, j] pairs (Delaunay edges)
var _step_timer: float = 0.0

# Fortune sweep state
var _sweep_x: float = -INF
var _sweep_running: bool = false
var _sweep_done: bool = false
var _circle_events: Array = []  # Array of {center: Vector2, radius: float, site_indices: Array}
var _beach_breakpoints: Array = []  # Array of {left: int, right: int, x: float}

# Delaunay animation state
var _del_edge_progress: float = 0.0
var _del_animating: bool = false

# Cell data (computed)
var _cell_vertices: Array = []   # Array of PackedVector2Array per site
var _cell_areas: Array = []      # float area per site

# --- Rendering ---
var _cells_im: ImmediateMesh
var _cells_mi: MeshInstance3D
var _edges_im: ImmediateMesh
var _edges_mi: MeshInstance3D
var _sites_im: ImmediateMesh
var _sites_mi: MeshInstance3D
var _delaunay_im: ImmediateMesh
var _delaunay_mi: MeshInstance3D
var _sweep_im: ImmediateMesh
var _sweep_mi: MeshInstance3D
var _beach_im: ImmediateMesh
var _beach_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _mode_label: Label3D
var _info_label: Label3D
var _sweep_label: Label3D
var _equity_label: Label3D

# VR controls
var _control_panel: Node3D
var _count_slider: Node3D
var _speed_slider: Node3D

# Colors
const COL_SITE := Color(0.95, 0.3, 0.15)
const COL_SITE_GLOW := Color(1.0, 0.5, 0.2)
const COL_VORONOI_EDGE := Color(0.2, 0.75, 0.95)
const COL_DELAUNAY_EDGE := Color(0.95, 0.75, 0.15)
const COL_SWEEP_LINE := Color(0.9, 0.15, 0.9, 0.85)
const COL_BEACH_LINE := Color(0.2, 0.95, 0.4, 0.7)
const COL_CIRCLE_EVENT := Color(1.0, 0.4, 0.4, 0.5)
const COL_WEIGHT_RING := Color(0.6, 0.4, 1.0, 0.6)
const COL_GRID := Color(0.3, 0.3, 0.35, 0.15)

func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_generate_sites()
	_compute_diagram()
	_start_sweep()

# =========================================================================
# Materials
# =========================================================================

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

# =========================================================================
# Mesh instances
# =========================================================================

func _create_mesh_instances() -> void:
	_cells_im = ImmediateMesh.new()
	_cells_mi = MeshInstance3D.new()
	_cells_mi.mesh = _cells_im
	_cells_mi.material_override = _mat_alpha
	add_child(_cells_mi)

	_edges_im = ImmediateMesh.new()
	_edges_mi = MeshInstance3D.new()
	_edges_mi.mesh = _edges_im
	_edges_mi.material_override = _mat_unshaded
	add_child(_edges_mi)

	_sites_im = ImmediateMesh.new()
	_sites_mi = MeshInstance3D.new()
	_sites_mi.mesh = _sites_im
	_sites_mi.material_override = _mat_unshaded
	add_child(_sites_mi)

	_delaunay_im = ImmediateMesh.new()
	_delaunay_mi = MeshInstance3D.new()
	_delaunay_mi.mesh = _delaunay_im
	_delaunay_mi.material_override = _mat_alpha
	add_child(_delaunay_mi)

	_sweep_im = ImmediateMesh.new()
	_sweep_mi = MeshInstance3D.new()
	_sweep_mi.mesh = _sweep_im
	_sweep_mi.material_override = _mat_alpha
	add_child(_sweep_mi)

	_beach_im = ImmediateMesh.new()
	_beach_mi = MeshInstance3D.new()
	_beach_mi.mesh = _beach_im
	_beach_mi.material_override = _mat_alpha
	add_child(_beach_mi)

# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Voronoi Diagrams"
	_title_label.font_size = 48
	_title_label.position = Vector3(0, field_height * 0.5 + 0.6, 0)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.modulate = Color(0.9, 0.9, 1.0)
	add_child(_title_label)

	_mode_label = Label3D.new()
	_mode_label.font_size = 32
	_mode_label.position = Vector3(0, field_height * 0.5 + 0.3, 0)
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.modulate = Color(0.7, 0.85, 1.0)
	add_child(_mode_label)

	_info_label = Label3D.new()
	_info_label.font_size = 24
	_info_label.position = Vector3(-field_width * 0.5 - 0.8, field_height * 0.3, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(0.8, 0.8, 0.8)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_info_label)

	_sweep_label = Label3D.new()
	_sweep_label.font_size = 20
	_sweep_label.position = Vector3(-field_width * 0.5 - 0.8, -0.2, 0)
	_sweep_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sweep_label.modulate = Color(0.9, 0.5, 0.9)
	_sweep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_sweep_label)

	_equity_label = Label3D.new()
	_equity_label.font_size = 22
	_equity_label.position = Vector3(-field_width * 0.5 - 0.8, -field_height * 0.3, 0)
	_equity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_equity_label.modulate = Color(0.7, 0.9, 0.7)
	_equity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_equity_label)

# =========================================================================
# VR Controls
# =========================================================================

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("VORONOI", [
		[
			{"type": "slider_h", "label": "SITES", "default": clampf(float(site_count - 4) / 36.0, 0.0, 1.0)},
			{"type": "slider_h", "label": "SPEED", "default": clampf(sweep_speed / 3.0, 0.0, 1.0)},
		],
		[
			{"type": "button", "label": "MODE"},
			{"type": "button", "label": "RESTART"},
		],
	])
	_control_panel.position = Vector3(-field_width * 0.3, -field_height * 0.5 - 0.5, 0.05)
	add_child(_control_panel)

	# SITES slider (Param_0)
	_count_slider = _control_panel.find_child("Param_0", true, false)
	if _count_slider and _count_slider.has_signal("slider_moved"):
		_count_slider.slider_moved.connect(_on_count_slider)

	# SPEED slider (Param_1)
	_speed_slider = _control_panel.find_child("Param_1", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_slider)

	# MODE (Btn_0)
	var mode_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if mode_btn:
		var area = mode_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_mode_pressed)

	# RESTART (Btn_1)
	var restart_btn: Node = _control_panel.find_child("Btn_1", true, false)
	if restart_btn:
		var area2 = restart_btn.get_node_or_null("InteractableAreaButton")
		if area2:
			area2.button_pressed.connect(_on_restart_pressed)

func _on_count_slider(_val: float) -> void:
	var nv: float = _count_slider.get_normalized_value()
	site_count = int(4 + nv * 36)
	_restart()

func _on_speed_slider(_val: float) -> void:
	var nv: float = _speed_slider.get_normalized_value()
	sweep_speed = nv * 3.0

func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	_restart()

func _on_restart_pressed() -> void:
	_restart()

# =========================================================================
# Site generation
# =========================================================================

func _generate_sites() -> void:
	_sites.clear()
	_weights.clear()
	_cell_colors.clear()

	var hw := field_width * 0.45
	var hh := field_height * 0.45

	for i in range(site_count):
		var pos := Vector2(randf_range(-hw, hw), randf_range(-hh, hh))
		_sites.append(pos)
		_weights.append(randf_range(0.3, 1.5))
		var hue := float(i) / float(maxi(site_count, 1))
		_cell_colors.append(Color.from_hsv(hue, 0.55, 0.85, 0.35))

# =========================================================================
# Diagram computation (grid-based nearest-site)
# =========================================================================

func _compute_diagram() -> void:
	_cell_vertices.clear()
	_cell_areas.clear()
	_adjacency.clear()

	var hw := field_width * 0.5
	var hh := field_height * 0.5
	var n := _sites.size()
	if n == 0:
		return

	# Grid ownership map
	var ownership: Array = []
	ownership.resize(grid_resolution * grid_resolution)
	for gx in range(grid_resolution):
		for gy in range(grid_resolution):
			var wx: float = -hw + (gx + 0.5) / float(grid_resolution) * field_width
			var wy: float = -hh + (gy + 0.5) / float(grid_resolution) * field_height
			var gp := Vector2(wx, wy)
			var best := 0
			var best_d: float = _site_distance(gp, 0)
			for s in range(1, n):
				var d: float = _site_distance(gp, s)
				if d < best_d:
					best_d = d
					best = s
			ownership[gx * grid_resolution + gy] = best

	# Extract boundary vertices per cell and adjacency
	var adj_set: Dictionary = {}
	var cell_points: Array = []
	cell_points.resize(n)
	for i in range(n):
		cell_points[i] = []

	var dx := field_width / float(grid_resolution)
	var dy := field_height / float(grid_resolution)

	for gx in range(grid_resolution):
		for gy in range(grid_resolution):
			var owner: int = ownership[gx * grid_resolution + gy]
			var wx: float = -hw + (gx + 0.5) * dx
			var wy: float = -hh + (gy + 0.5) * dy
			var is_boundary := false

			# Check 4-neighbors for adjacency
			for dir in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx: int = gx + dir[0]
				var ny: int = gy + dir[1]
				if nx >= 0 and nx < grid_resolution and ny >= 0 and ny < grid_resolution:
					var neighbor: int = ownership[nx * grid_resolution + ny]
					if neighbor != owner:
						is_boundary = true
						var key: int = mini(owner, neighbor) * 10000 + maxi(owner, neighbor)
						adj_set[key] = [mini(owner, neighbor), maxi(owner, neighbor)]
				else:
					is_boundary = true

			cell_points[owner].append(Vector2(wx, wy))

	# Build adjacency list
	for key in adj_set:
		_adjacency.append(adj_set[key])

	# Build convex hulls for each cell
	for i in range(n):
		var pts: Array = cell_points[i]
		if pts.size() < 3:
			_cell_vertices.append(PackedVector2Array())
			_cell_areas.append(0.0)
			continue
		var hull: PackedVector2Array = _convex_hull(pts)
		_cell_vertices.append(hull)
		_cell_areas.append(_polygon_area(hull))

	# Detect circle events from Delaunay triples
	_detect_circle_events()

func _site_distance(point: Vector2, site_idx: int) -> float:
	var d2: float = point.distance_squared_to(_sites[site_idx])
	if _mode == Mode.POWER:
		return d2 - _weights[site_idx] * _weights[site_idx]
	return d2

func _convex_hull(points: Array) -> PackedVector2Array:
	if points.size() < 3:
		var r := PackedVector2Array()
		for p in points:
			r.append(p)
		return r

	# Graham scan
	var start: Vector2 = points[0]
	for p in points:
		if p.y < start.y or (p.y == start.y and p.x < start.x):
			start = p

	var sorted_pts: Array = points.duplicate()
	sorted_pts.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var aa: float = atan2(a.y - start.y, a.x - start.x)
		var ab: float = atan2(b.y - start.y, b.x - start.x)
		if abs(aa - ab) < 1e-9:
			return a.distance_squared_to(start) < b.distance_squared_to(start)
		return aa < ab
	)

	var hull: Array = []
	for p in sorted_pts:
		while hull.size() > 1:
			var o: Vector2 = hull[hull.size() - 2]
			var a: Vector2 = hull[hull.size() - 1]
			if (a.x - o.x) * (p.y - o.y) - (a.y - o.y) * (p.x - o.x) <= 0:
				hull.pop_back()
			else:
				break
		hull.append(p)

	var result := PackedVector2Array()
	for p in hull:
		result.append(p)
	return result

func _polygon_area(verts: PackedVector2Array) -> float:
	if verts.size() < 3:
		return 0.0
	var area := 0.0
	for i in range(verts.size()):
		var j := (i + 1) % verts.size()
		area += verts[i].x * verts[j].y
		area -= verts[j].x * verts[i].y
	return absf(area) * 0.5

# =========================================================================
# Circle event detection (circumcircles of Delaunay triples)
# =========================================================================

func _detect_circle_events() -> void:
	_circle_events.clear()
	# Build adjacency lookup
	var adj_map: Dictionary = {}
	for edge in _adjacency:
		var a: int = edge[0]
		var b: int = edge[1]
		if not adj_map.has(a):
			adj_map[a] = []
		if not adj_map.has(b):
			adj_map[b] = []
		adj_map[a].append(b)
		adj_map[b].append(a)

	# Find triples sharing edges
	var found: Dictionary = {}
	for edge in _adjacency:
		var a: int = edge[0]
		var b: int = edge[1]
		if not adj_map.has(a) or not adj_map.has(b):
			continue
		for c in adj_map[a]:
			if c > b and adj_map[b].has(c):
				var key: int = a * 100000000 + b * 10000 + c
				if found.has(key):
					continue
				found[key] = true
				var cc: Dictionary = _circumcircle(_sites[a], _sites[b], _sites[c])
				if cc.size() > 0:
					_circle_events.append({
						"center": cc["center"],
						"radius": cc["radius"],
						"sites": [a, b, c]
					})

func _circumcircle(a: Vector2, b: Vector2, c: Vector2) -> Dictionary:
	var ax: float = a.x; var ay: float = a.y
	var bx: float = b.x; var by: float = b.y
	var cx: float = c.x; var cy: float = c.y
	var d: float = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
	if absf(d) < 1e-10:
		return {}
	var ux: float = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
	var uy: float = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d
	var center := Vector2(ux, uy)
	var radius: float = center.distance_to(a)
	return {"center": center, "radius": radius}

# =========================================================================
# Sweep control
# =========================================================================

func _start_sweep() -> void:
	_sweep_x = -field_width * 0.5 - 0.5
	_sweep_running = true
	_sweep_done = false
	_del_edge_progress = 0.0
	_del_animating = _mode == Mode.DELAUNAY

func _restart() -> void:
	_generate_sites()
	_compute_diagram()
	_start_sweep()

# =========================================================================
# Process
# =========================================================================

func _process(delta: float) -> void:
	_time += delta

	# Advance sweep line
	if _sweep_running and not _sweep_done:
		_sweep_x += sweep_speed * delta
		if _sweep_x > field_width * 0.5 + 0.5:
			_sweep_done = true
			_sweep_running = false

	# Delaunay edge animation
	if _del_animating and _sweep_done:
		_del_edge_progress += delta * 0.8
		if _del_edge_progress >= 1.0:
			_del_edge_progress = 1.0
			_del_animating = false

	_draw_all()
	_update_labels()

# =========================================================================
# Drawing
# =========================================================================

func _draw_all() -> void:
	_draw_cells()
	_draw_edges()
	_draw_sites()
	_draw_delaunay()
	_draw_sweep_line()
	_draw_beach_line()

# --- Cells (filled polygons) ---
func _draw_cells() -> void:
	_cells_im.clear_surfaces()
	if not show_cells:
		return

	var n := _sites.size()
	for i in range(n):
		var verts: PackedVector2Array = _cell_vertices[i] if i < _cell_vertices.size() else PackedVector2Array()
		if verts.size() < 3:
			continue

		# In sweep mode, only reveal cells left of sweep line
		var reveal: bool = _sweep_done or _mode != Mode.VORONOI
		if not reveal:
			# Check if site is left of sweep
			if _sites[i].x > _sweep_x:
				continue

		var col: Color = _cell_colors[i] if i < _cell_colors.size() else Color(0.5, 0.5, 0.5, 0.3)

		_cells_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for t in range(1, verts.size() - 1):
			_cells_im.surface_set_color(col)
			_cells_im.surface_add_vertex(Vector3(verts[0].x, 0.0, verts[0].y))
			_cells_im.surface_set_color(col)
			_cells_im.surface_add_vertex(Vector3(verts[t].x, 0.0, verts[t].y))
			_cells_im.surface_set_color(col)
			_cells_im.surface_add_vertex(Vector3(verts[t + 1].x, 0.0, verts[t + 1].y))
		_cells_im.surface_end()

# --- Voronoi edges ---
func _draw_edges() -> void:
	_edges_im.clear_surfaces()
	if not show_edges:
		return

	var n := _cell_vertices.size()
	if n == 0:
		return

	_edges_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(n):
		var verts: PackedVector2Array = _cell_vertices[i]
		if verts.size() < 3:
			continue

		# In sweep mode, only reveal edges left of sweep
		if _mode == Mode.VORONOI and not _sweep_done and _sites[i].x > _sweep_x:
			continue

		for j in range(verts.size()):
			var a: Vector2 = verts[j]
			var b: Vector2 = verts[(j + 1) % verts.size()]
			_edges_im.surface_set_color(COL_VORONOI_EDGE)
			_edges_im.surface_add_vertex(Vector3(a.x, 0.02, a.y))
			_edges_im.surface_set_color(COL_VORONOI_EDGE)
			_edges_im.surface_add_vertex(Vector3(b.x, 0.02, b.y))
	_edges_im.surface_end()

# --- Sites (diamond markers) ---
func _draw_sites() -> void:
	_sites_im.clear_surfaces()
	var n := _sites.size()
	if n == 0:
		return

	_sites_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(n):
		var s: Vector2 = _sites[i]
		var r := 0.12
		var pulse: float = 1.0 + sin(_time * 2.5 + i * 0.7) * 0.08
		r *= pulse
		var col: Color = COL_SITE

		# Diamond (4 triangles)
		var top := Vector3(s.x, 0.05, s.y - r)
		var right := Vector3(s.x + r, 0.05, s.y)
		var bottom := Vector3(s.x, 0.05, s.y + r)
		var left := Vector3(s.x - r, 0.05, s.y)
		var up := Vector3(s.x, 0.05 + r * 0.7, s.y)
		var down := Vector3(s.x, 0.05 - r * 0.3, s.y)

		for tri in [[top, right, up], [right, bottom, up], [bottom, left, up], [left, top, up],
					[right, top, down], [bottom, right, down], [left, bottom, down], [top, left, down]]:
			_sites_im.surface_set_color(col)
			_sites_im.surface_add_vertex(tri[0])
			_sites_im.surface_set_color(COL_SITE_GLOW)
			_sites_im.surface_add_vertex(tri[1])
			_sites_im.surface_set_color(col)
			_sites_im.surface_add_vertex(tri[2])

		# Power diagram weight ring
		if _mode == Mode.POWER:
			var w: float = _weights[i] if i < _weights.size() else 1.0
			_draw_weight_ring(s, w)

	_sites_im.surface_end()

func _draw_weight_ring(center: Vector2, weight: float) -> void:
	# Weight ring is drawn separately in the sweep mesh to keep sites mesh clean
	pass

# --- Delaunay triangulation edges ---
func _draw_delaunay() -> void:
	_delaunay_im.clear_surfaces()
	if _mode != Mode.DELAUNAY and _mode != Mode.VORONOI:
		return
	if _adjacency.is_empty():
		return

	# In VORONOI mode show Delaunay dimly; in DELAUNAY mode show prominently
	var alpha: float = 0.3 if _mode == Mode.VORONOI else 0.85
	var progress: float = 1.0
	if _mode == Mode.DELAUNAY:
		progress = clampf(_del_edge_progress, 0.0, 1.0) if _del_animating else 1.0
		if not _sweep_done:
			progress = 0.0

	var edge_count: int = int(ceil(float(_adjacency.size()) * progress))

	_delaunay_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for e in range(mini(edge_count, _adjacency.size())):
		var pair: Array = _adjacency[e]
		var a: Vector2 = _sites[pair[0]]
		var b: Vector2 = _sites[pair[1]]
		var col := Color(COL_DELAUNAY_EDGE.r, COL_DELAUNAY_EDGE.g, COL_DELAUNAY_EDGE.b, alpha)

		# In VORONOI sweep mode, only show edges where both sites are left of sweep
		if _mode == Mode.VORONOI and not _sweep_done:
			if a.x > _sweep_x or b.x > _sweep_x:
				continue

		_delaunay_im.surface_set_color(col)
		_delaunay_im.surface_add_vertex(Vector3(a.x, 0.04, a.y))
		_delaunay_im.surface_set_color(col)
		_delaunay_im.surface_add_vertex(Vector3(b.x, 0.04, b.y))
	_delaunay_im.surface_end()

# --- Fortune's sweep line ---
func _draw_sweep_line() -> void:
	_sweep_im.clear_surfaces()
	if _sweep_done and _mode != Mode.POWER:
		return

	var hh := field_height * 0.5

	if _mode == Mode.VORONOI and not _sweep_done:
		# Vertical sweep line
		_sweep_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var lw := 0.03
		var col: Color = COL_SWEEP_LINE
		_add_quad(_sweep_im, col,
			Vector3(_sweep_x - lw, -0.01, -hh),
			Vector3(_sweep_x + lw, -0.01, -hh),
			Vector3(_sweep_x + lw, -0.01, hh),
			Vector3(_sweep_x - lw, -0.01, hh))
		_sweep_im.surface_end()

		# Circle events
		if not _circle_events.is_empty():
			_sweep_im.surface_begin(Mesh.PRIMITIVE_LINES)
			for evt in _circle_events:
				var c: Vector2 = evt["center"]
				var r: float = evt["radius"]
				# Only show circles near the sweep line
				var right_edge: float = c.x + r
				if right_edge < _sweep_x - 1.0 or c.x - r > _sweep_x + 2.0:
					continue
				var active: bool = absf(right_edge - _sweep_x) < 0.5
				var ecol: Color = COL_CIRCLE_EVENT if not active else Color(1.0, 1.0, 0.3, 0.8)
				var segs := 24
				for s in range(segs):
					var a1: float = TAU * s / float(segs)
					var a2: float = TAU * (s + 1) / float(segs)
					_sweep_im.surface_set_color(ecol)
					_sweep_im.surface_add_vertex(Vector3(c.x + cos(a1) * r, 0.03, c.y + sin(a1) * r))
					_sweep_im.surface_set_color(ecol)
					_sweep_im.surface_add_vertex(Vector3(c.x + cos(a2) * r, 0.03, c.y + sin(a2) * r))
			_sweep_im.surface_end()

	# Power diagram weight rings
	if _mode == Mode.POWER:
		_sweep_im.surface_begin(Mesh.PRIMITIVE_LINES)
		for i in range(_sites.size()):
			var s: Vector2 = _sites[i]
			var w: float = _weights[i] if i < _weights.size() else 1.0
			var r: float = w * 0.5
			var segs := 20
			for seg in range(segs):
				var a1: float = TAU * seg / float(segs)
				var a2: float = TAU * (seg + 1) / float(segs)
				_sweep_im.surface_set_color(COL_WEIGHT_RING)
				_sweep_im.surface_add_vertex(Vector3(s.x + cos(a1) * r, 0.06, s.y + sin(a1) * r))
				_sweep_im.surface_set_color(COL_WEIGHT_RING)
				_sweep_im.surface_add_vertex(Vector3(s.x + cos(a2) * r, 0.06, s.y + sin(a2) * r))
		_sweep_im.surface_end()

# --- Beach line (parabolic fronts) ---
func _draw_beach_line() -> void:
	_beach_im.clear_surfaces()
	if _mode != Mode.VORONOI or _sweep_done:
		return

	# Draw parabolic arcs for each site left of the sweep line
	_beach_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var hh := field_height * 0.5
	var segments := 60

	# Collect sites left of sweep, compute their parabola contribution
	var active_sites: Array = []
	for i in range(_sites.size()):
		if _sites[i].x < _sweep_x:
			active_sites.append(i)

	if active_sites.is_empty():
		_beach_im.surface_end()
		return

	# For each y position, find the beach line x (closest parabola to sweep)
	var prev_point := Vector3.ZERO
	var has_prev := false

	for seg in range(segments + 1):
		var y: float = -hh + float(seg) / float(segments) * field_height
		var best_x: float = -INF

		for si in active_sites:
			var sx: float = _sites[si].x
			var sy: float = _sites[si].y
			var dx: float = _sweep_x - sx
			if dx < 0.01:
				continue
			# Parabola: x = (y - sy)^2 / (2 * dx) + (sx + sweep_x) / 2
			var px: float = (y - sy) * (y - sy) / (2.0 * dx) + (sx + _sweep_x) * 0.5
			if px > best_x:
				best_x = px

		if best_x > -INF:
			# Clamp to field bounds
			best_x = clampf(best_x, -field_width * 0.5, field_width * 0.5)
			var current := Vector3(best_x, 0.01, y)
			if has_prev:
				_beach_im.surface_set_color(COL_BEACH_LINE)
				_beach_im.surface_add_vertex(prev_point)
				_beach_im.surface_set_color(COL_BEACH_LINE)
				_beach_im.surface_add_vertex(current)
			prev_point = current
			has_prev = true

	_beach_im.surface_end()

# --- Quad helper ---
func _add_quad(im: ImmediateMesh, col: Color, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	im.surface_set_color(col)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_add_vertex(b)
	im.surface_set_color(col)
	im.surface_add_vertex(c)
	im.surface_set_color(col)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_add_vertex(c)
	im.surface_set_color(col)
	im.surface_add_vertex(d)

# =========================================================================
# Labels
# =========================================================================

func _update_labels() -> void:
	var mode_names := ["Fortune's Sweep", "Delaunay Dual", "Power Diagram"]
	_mode_label.text = mode_names[_mode]

	# Info
	var total_area: float = 0.0
	var max_area: float = 0.0
	var min_area: float = INF
	for a in _cell_areas:
		total_area += a
		max_area = maxf(max_area, a)
		if a > 0.01:
			min_area = minf(min_area, a)
	if min_area == INF:
		min_area = 0.0
	var avg_area: float = total_area / maxf(float(_sites.size()), 1.0)

	_info_label.text = "Sites: %d\nCells: %d\nEdges: %d" % [
		_sites.size(), _cell_vertices.size(), _adjacency.size()]

	# Sweep progress
	if _mode == Mode.VORONOI and not _sweep_done:
		var pct: float = clampf((_sweep_x + field_width * 0.5) / field_width * 100.0, 0.0, 100.0)
		_sweep_label.text = "Sweep: %.0f%%\nCircle events: %d\nBeach arcs: %d" % [
			pct, _circle_events.size(), _count_active_arcs()]
	elif _mode == Mode.POWER:
		_sweep_label.text = "Weighted Voronoi\nWeights: %.2f–%.2f" % [
			_weights.min() if not _weights.is_empty() else 0.0,
			_weights.max() if not _weights.is_empty() else 0.0]
	elif _mode == Mode.DELAUNAY:
		_sweep_label.text = "Triangulation edges: %d\nCircumcircles: %d" % [
			_adjacency.size(), _circle_events.size()]
	else:
		_sweep_label.text = "Complete"

	# Spatial equity
	var variance_sum: float = 0.0
	for a in _cell_areas:
		var dev: float = a - avg_area
		variance_sum += dev * dev
	var std_dev: float = sqrt(variance_sum / maxf(float(_sites.size()), 1.0))
	var equity: float = clampf(1.0 - std_dev / maxf(avg_area, 0.01), 0.0, 1.0) * 100.0
	_equity_label.text = "Equity: %.0f%%\nArea range: %.1f–%.1f" % [equity, min_area, max_area]

func _count_active_arcs() -> int:
	var count := 0
	for i in range(_sites.size()):
		if _sites[i].x < _sweep_x:
			count += 1
	return count

# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("site_count"):
		site_count = clampi(int(config["site_count"]), 3, 40)
	if config.has("field_width"):
		field_width = clampf(float(config["field_width"]), 2.0, 12.0)
	if config.has("field_height"):
		field_height = clampf(float(config["field_height"]), 2.0, 10.0)
	if config.has("sweep_speed"):
		sweep_speed = clampf(float(config["sweep_speed"]), 0.1, 5.0)
	if config.has("show_edges"):
		show_edges = bool(config["show_edges"])
	if config.has("show_cells"):
		show_cells = bool(config["show_cells"])
	if config.has("grid_resolution"):
		grid_resolution = clampi(int(config["grid_resolution"]), 30, 150)
	if config.has("mode"):
		var m: String = str(config["mode"]).to_upper()
		match m:
			"VORONOI": _mode = Mode.VORONOI
			"DELAUNAY": _mode = Mode.DELAUNAY
			"POWER": _mode = Mode.POWER

	# Update slider visuals
	if _count_slider:
		_count_slider.set_normalized_value(clampf(float(site_count - 4) / 36.0, 0.0, 1.0))
	if _speed_slider:
		_speed_slider.set_normalized_value(clampf(sweep_speed / 3.0, 0.0, 1.0))

	# Reposition labels
	_title_label.position.y = field_height * 0.5 + 0.6
	_mode_label.position.y = field_height * 0.5 + 0.3
	_info_label.position.x = -field_width * 0.5 - 0.8
	_sweep_label.position.x = -field_width * 0.5 - 0.8
	_equity_label.position.x = -field_width * 0.5 - 0.8

	_restart()

# =========================================================================
# Utility
# =========================================================================

func get_algorithm_info() -> Dictionary:
	var mode_names := ["voronoi_fortune", "delaunay_dual", "power_diagram"]
	return {
		"name": "Voronoi Diagrams",
		"description": "Fortune sweep, Delaunay dual, power diagrams",
		"mode": mode_names[_mode],
		"properties": {
			"sites": _sites.size(),
			"cells": _cell_vertices.size(),
			"delaunay_edges": _adjacency.size(),
			"circle_events": _circle_events.size(),
		},
		"complexity": {
			"time": "O(n log n) Fortune / O(n²) grid",
			"space": "O(n)"
		}
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
