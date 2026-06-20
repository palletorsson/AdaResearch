extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DimensionRoom

## @identity
## name: "Fractal dimension"
## tier: large
## lineage: a room you walk into to measure a coastline — box-counting at room scale,
##   the same Koch coastline covered by coarser then finer grids.
## essence: A big fractal coastline lies on the floor. Three covering grids sit beside it,
##   each finer than the last (coarse / medium / fine). As the boxes shrink, the COUNT of
##   boxes touching the coast grows — but not as fast as a filled area would. That growth
##   rate IS the dimension. You stand between a line (D=1) and a plane (D=2) and read where
##   the coast falls: about 1.26.
## truth: "between 1D and 2D" — the count grows like S^D, and for this coast D ≈ log 4 / log 3.

@export var koch_depth: int = 4
@export var floor_size: float = 7.0
@export var coast_span: float = 3.4         # footprint of the coastline on the floor
@export var coast_color: Color = Color(0.40, 0.80, 1.0)
@export var hit_color: Color = Color(1.0, 0.74, 0.28)
@export var miss_color: Color = Color(0.16, 0.20, 0.27)
@export var floor_col: Color = Color(0.10, 0.12, 0.16)
@export var label_col: Color = Color(0.84, 0.92, 1.0)

var _t: float = 0.0
var _coast_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("koch_depth"):
		koch_depth = clampi(int(config["koch_depth"]), 1, 5)
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_coast_root = null
	_build()


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


func _koch_points(depth: int) -> PackedVector2Array:
	# Koch curve polyline from (0,0) to (1,0) in unit space.
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
	# --- room floor ---------------------------------------------------------
	var floor_mat: StandardMaterial3D = _matte_mat(floor_col, 0.92, 0.05)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), floor_mat))

	var root := Node3D.new()
	root.name = "CoastSway"
	add_child(root)
	_coast_root = root

	# The coastline lies flat on the floor (XZ plane), occupying coast_span wide
	# on the LEFT half of the room. Map unit-x -> world-x, unit-y -> world-z.
	var pts: PackedVector2Array = _koch_points(koch_depth)
	var seg_count: int = pts.size() - 1
	var ox: float = -floor_size * 0.5 + 0.6
	var oz: float = -coast_span * 0.5
	var lift: float = 0.06

	# --- coastline as a MultiMesh of flat segment boxes --------------------
	var coast_field: MultiMeshInstance3D = _field(seg_count, true)
	coast_field.name = "Coast"
	var cmm: MultiMesh = coast_field.multimesh
	var thick: float = 0.05
	for i in range(seg_count):
		var a2: Vector2 = pts[i]
		var b2: Vector2 = pts[i + 1]
		var wa := Vector3(ox + a2.x * coast_span, lift, oz + a2.y * coast_span)
		var wb := Vector3(ox + b2.x * coast_span, lift, oz + b2.y * coast_span)
		var mid: Vector3 = (wa + wb) * 0.5
		var seg_len: float = maxf(wa.distance_to(wb), 0.0001)
		var dir: Vector3 = (wb - wa) / seg_len
		var ang: float = atan2(dir.z, dir.x)
		var basis := Basis(Vector3(0, 1, 0), -ang).scaled(Vector3(seg_len, thick, thick))
		cmm.set_instance_transform(i, Transform3D(basis, mid))
		cmm.set_instance_color(i, coast_color)
	root.add_child(coast_field)

	# --- three covering grids at finer and finer scales --------------------
	# Each grid covers the SAME footprint; we report (N, S) for each.
	var scales: PackedInt32Array = PackedInt32Array([6, 12, 24])
	var grid_z_off: float = coast_span * 0.5 + 1.0   # set grids on near side of the coast
	var d_estimates: PackedFloat32Array = PackedFloat32Array()
	for gi in range(scales.size()):
		var grid_n: int = scales[gi]
		var cell: float = coast_span / float(grid_n)
		# Which cells does the coast touch? Sample the polyline densely.
		var hit := {}
		var samples: int = maxi(seg_count * 4, 800)
		for s in range(samples + 1):
			var f: float = float(s) / float(samples)
			var idx_f: float = f * float(seg_count)
			var seg_i: int = clampi(int(idx_f), 0, seg_count - 1)
			var local_f: float = idx_f - float(seg_i)
			var p2v: Vector2 = pts[seg_i].lerp(pts[seg_i + 1], local_f)
			var gx: int = clampi(int(p2v.x * float(grid_n)), 0, grid_n - 1)
			var gyc: int = clampi(int(p2v.y * float(grid_n)), 0, grid_n - 1)
			hit[gyc * grid_n + gx] = true

		var grid_field: MultiMeshInstance3D = _field(grid_n * grid_n, true)
		grid_field.name = "Grid_%d" % grid_n
		var gmm: MultiMesh = grid_field.multimesh
		var gz_base: float = grid_z_off + float(gi) * (coast_span + 0.5)
		var n_hits: int = 0
		for gy in range(grid_n):
			for gx in range(grid_n):
				var key: int = gy * grid_n + gx
				var is_hit: bool = hit.has(key)
				if is_hit:
					n_hits += 1
				var cx: float = ox + (float(gx) + 0.5) * cell
				var cz: float = gz_base + (float(gy) + 0.5) * cell - coast_span * 0.5
				var box_s: float = cell * (0.92 if is_hit else 0.8)
				var box_h: float = 0.08 if is_hit else 0.02
				var basis2 := Basis().scaled(Vector3(box_s, box_h, box_s))
				gmm.set_instance_transform(key, Transform3D(basis2, Vector3(cx, box_h * 0.5 + 0.01, cz)))
				gmm.set_instance_color(key, hit_color if is_hit else miss_color)
		root.add_child(grid_field)

		var d_val: float = log(float(n_hits)) / log(float(grid_n)) if n_hits > 0 else 0.0
		d_estimates.append(d_val)
		# per-grid floating count label
		add_child(_billboard_label("S=%d  N=%d  D=%.2f" % [grid_n, n_hits, d_val],
			Vector3(ox + coast_span * 0.5, 1.0 + float(gi) * 0.0, gz_base + coast_span * 0.5 + 0.3), 18, hit_color))

	# --- overhead labels ----------------------------------------------------
	var d_best: float = d_estimates[d_estimates.size() - 1] if d_estimates.size() > 0 else 0.0
	add_child(_billboard_label("COASTLINE D ≈ %.2f" % d_best, Vector3(0.0, 3.2, 0.0), 24, label_col))
	add_child(_billboard_label("BETWEEN 1D AND 2D", Vector3(0.0, 3.6, 0.0), 30, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _coast_root != null:
		_coast_root.position.y = sin(_t * 0.6) * 0.01
