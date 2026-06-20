extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DimensionBench

## @identity
## name: "Fractal dimension"
## tier: medium
## lineage: box-counting on a bench — Mandelbrot's ruler laid against a Koch curve, and
##   the count of boxes that touch it read off as a dimension.
## essence: A Koch-curve specimen stands on the bench, draped under a grid of small boxes.
##   The boxes that the curve passes through light up; you count them (N) at scale (S) and
##   the readout solves D = log N / log S. The same curve, counted at a finer grid, fills
##   MORE boxes than a line would and FEWER than a plane — its dimension sits between 1 and 2.
## truth: "D = log N / log S" — count how the cover grows as the ruler shrinks.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var koch_depth: int = 4
@export var grid_n: int = 8                 # boxes per side of the covering grid
@export var span: float = 0.62              # width of the specimen panel (m)
@export var curve_color: Color = Color(0.45, 0.85, 1.0)
@export var box_hit_color: Color = Color(1.0, 0.78, 0.30)
@export var box_miss_color: Color = Color(0.18, 0.22, 0.30)
@export var label_color: Color = Color(0.85, 0.92, 1.0)

var _t: float = 0.0
var _curve_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("koch_depth"):
		koch_depth = clampi(int(config["koch_depth"]), 1, 5)
	if config.has("grid_n"):
		grid_n = clampi(int(config["grid_n"]), 2, 16)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_curve_root = null
	_build()


# --- MultiMesh field helper --------------------------------------------------

func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


# --- Koch curve point generation ---------------------------------------------

func _koch_points(depth: int) -> PackedVector2Array:
	# Returns the polyline of a Koch curve from (0,0) to (1,0), in unit space.
	var pts := PackedVector2Array()
	pts.append(Vector2(0.0, 0.0))
	pts.append(Vector2(1.0, 0.0))
	for _it in range(depth):
		var out := PackedVector2Array()
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var d: Vector2 = b - a
			var p1: Vector2 = a + d / 3.0
			var p2: Vector2 = a + d * (2.0 / 3.0)
			# peak of the bump: rotate (p2-p1) by -60 degrees about p1
			var seg: Vector2 = p2 - p1
			var ang: float = -PI / 3.0
			var peak: Vector2 = p1 + Vector2(
				seg.x * cos(ang) - seg.y * sin(ang),
				seg.x * sin(ang) + seg.y * cos(ang))
			out.append(a)
			out.append(p1)
			out.append(peak)
			out.append(p2)
		out.append(pts[pts.size() - 1])
		pts = out
	return pts


func _build() -> void:
	# --- bench base + pillar ------------------------------------------------
	var base_mat: StandardMaterial3D = _matte_mat(Color(0.20, 0.22, 0.26), 0.85)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.20, 0.7), base_mat))
	var top_mat: StandardMaterial3D = _steel_mat(Color(0.40, 0.44, 0.50))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.04, 0.7), top_mat))
	add_child(_cylinder(Vector3(0.0, 0.50, -0.18), 0.05, 0.70, base_mat))

	# --- specimen panel that the curve + grid sit on (facing +Z) -----------
	var panel_y: float = 1.18
	var panel_z: float = 0.16
	var panel_mat: StandardMaterial3D = _matte_mat(Color(0.05, 0.06, 0.09), 0.95)
	add_child(_box(Vector3(0.0, panel_y, panel_z - 0.02), Vector3(span + 0.08, span + 0.08, 0.02), panel_mat))

	var root := Node3D.new()
	root.name = "CurveSway"
	add_child(root)
	_curve_root = root

	# Unit→world placement: the unit square [0,1]² maps onto the panel.
	var ox: float = -span * 0.5
	var oy: float = panel_y - span * 0.5

	# --- the Koch curve specimen (one MultiMesh of segment boxes) ----------
	var pts: PackedVector2Array = _koch_points(koch_depth)
	var seg_count: int = pts.size() - 1
	var curve_field: MultiMeshInstance3D = _field(seg_count, true)
	curve_field.name = "Curve"
	var cmm: MultiMesh = curve_field.multimesh
	var thick: float = 0.008
	for i in range(seg_count):
		var a2: Vector2 = pts[i]
		var b2: Vector2 = pts[i + 1]
		var wa := Vector3(ox + a2.x * span, oy + a2.y * span, panel_z)
		var wb := Vector3(ox + b2.x * span, oy + b2.y * span, panel_z)
		var mid: Vector3 = (wa + wb) * 0.5
		var seg_len: float = maxf(wa.distance_to(wb), 0.0001)
		var dir: Vector3 = (wb - wa) / seg_len
		var ang: float = atan2(dir.y, dir.x)
		var basis := Basis(Vector3(0, 0, 1), ang).scaled(Vector3(seg_len, thick, thick))
		cmm.set_instance_transform(i, Transform3D(basis, mid))
		cmm.set_instance_color(i, curve_color)
	root.add_child(curve_field)

	# --- covering grid: grid_n × grid_n boxes; hits light up ----------------
	var cell: float = span / float(grid_n)
	# Mark cells the curve passes through by sampling the polyline densely.
	var hit := {}
	var samples: int = maxi(seg_count * 6, 600)
	for s in range(samples + 1):
		var f: float = float(s) / float(samples)
		var idx_f: float = f * float(seg_count)
		var seg_i: int = clampi(int(idx_f), 0, seg_count - 1)
		var local_f: float = idx_f - float(seg_i)
		var p2v: Vector2 = pts[seg_i].lerp(pts[seg_i + 1], local_f)
		var gx: int = clampi(int(p2v.x * float(grid_n)), 0, grid_n - 1)
		var gy: int = clampi(int(p2v.y * float(grid_n)), 0, grid_n - 1)
		hit[gy * grid_n + gx] = true

	var grid_field: MultiMeshInstance3D = _field(grid_n * grid_n, true)
	grid_field.name = "Grid"
	var gmm: MultiMesh = grid_field.multimesh
	var n_hits: int = 0
	for gy in range(grid_n):
		for gx in range(grid_n):
			var key: int = gy * grid_n + gx
			var is_hit: bool = hit.has(key)
			if is_hit:
				n_hits += 1
			var cx: float = ox + (float(gx) + 0.5) * cell
			var cy: float = oy + (float(gy) + 0.5) * cell
			var depth_z: float = panel_z - 0.012 if is_hit else panel_z - 0.018
			var box_s: float = cell * (0.92 if is_hit else 0.86)
			var basis2 := Basis().scaled(Vector3(box_s, box_s, 0.006))
			gmm.set_instance_transform(key, Transform3D(basis2, Vector3(cx, cy, depth_z)))
			gmm.set_instance_color(key, box_hit_color if is_hit else box_miss_color)
	root.add_child(grid_field)

	# --- readout: D = log N / log S -----------------------------------------
	# Scale S = grid_n (the curve box was unit; we count at 1/grid_n cells).
	var d_val: float = log(float(n_hits)) / log(float(grid_n)) if grid_n > 1 and n_hits > 0 else 0.0
	add_child(_billboard_label("N=%d  S=%d  D=%.3f" % [n_hits, grid_n, d_val], Vector3(0.0, 1.12, 0.30), 18, box_hit_color))
	add_child(_billboard_label("D = log N / log S", Vector3(0.0, 1.6, 0.0), 26, label_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _curve_root != null:
		_curve_root.rotation.y = sin(_t * 0.4) * 0.05
