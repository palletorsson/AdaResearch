extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DimensionMeter

## @identity
## name: "Fractal dimension"
## tier: applied
## lineage: a handheld instrument — drop a fractal specimen on the stage, a scanner head
##   sweeps it, and the gauge needle settles on its fractal dimension.
## essence: A tabletop device. A Sierpinski/Koch specimen sits under a scanning head that
##   rakes back and forth; the readout panel solves D = log N / log S live, and a small
##   needle gauge swings between the 1.0 (line) and 2.0 (plane) pins. A real instrument for
##   an unreal number: the dimension that isn't a whole number.
## truth: "D = log N / log S" — measured, not assumed; the needle finds the non-integer.

@export var koch_depth: int = 4
@export var span: float = 0.36              # specimen footprint on the stage (m)
@export var grid_n: int = 12                # scanner grid resolution
@export var specimen_color: Color = Color(0.50, 0.85, 1.0)
@export var hit_color: Color = Color(1.0, 0.76, 0.30)
@export var miss_color: Color = Color(0.16, 0.20, 0.27)
@export var scan_color: Color = Color(0.40, 1.0, 0.65)
@export var label_color: Color = Color(0.85, 0.92, 1.0)

var _t: float = 0.0
var _scanner: Node3D = null
var _needle: Node3D = null
var _d_value: float = 1.26


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
		grid_n = clampi(int(config["grid_n"]), 4, 20)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_scanner = null
	_needle = null
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
	# --- device body (~1 m) -------------------------------------------------
	var body_mat: StandardMaterial3D = _matte_mat(Color(0.22, 0.24, 0.28), 0.7, 0.2)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(0.9, 0.20, 0.6), body_mat))
	# raised stage where the specimen sits
	var stage_mat: StandardMaterial3D = _matte_mat(Color(0.05, 0.06, 0.09), 0.95)
	add_child(_box(Vector3(-0.12, 0.22, 0.0), Vector3(0.46, 0.04, 0.46), stage_mat))

	# scanner gantry: two posts + a rail the head rides on
	var post_mat: StandardMaterial3D = _steel_mat(Color(0.50, 0.54, 0.60))
	add_child(_box(Vector3(-0.36, 0.42, -0.20), Vector3(0.04, 0.40, 0.04), post_mat))
	add_child(_box(Vector3(-0.36, 0.42, 0.20), Vector3(0.04, 0.40, 0.04), post_mat))
	add_child(_cylinder_between(Vector3(-0.36, 0.60, -0.20), Vector3(-0.36, 0.60, 0.20), 0.012, post_mat))

	var ox: float = -0.12 - span * 0.5
	var oz: float = -span * 0.5
	var stage_y: float = 0.245

	# --- the specimen: Koch curve as a MultiMesh of segment boxes ----------
	var pts: PackedVector2Array = _koch_points(koch_depth)
	var seg_count: int = pts.size() - 1
	var spec_field: MultiMeshInstance3D = _field(seg_count, true)
	spec_field.name = "Specimen"
	var smm: MultiMesh = spec_field.multimesh
	var thick: float = 0.006
	for i in range(seg_count):
		var a2: Vector2 = pts[i]
		var b2: Vector2 = pts[i + 1]
		var wa := Vector3(ox + a2.x * span, stage_y, oz + a2.y * span)
		var wb := Vector3(ox + b2.x * span, stage_y, oz + b2.y * span)
		var mid: Vector3 = (wa + wb) * 0.5
		var seg_len: float = maxf(wa.distance_to(wb), 0.0001)
		var dir: Vector3 = (wb - wa) / seg_len
		var ang: float = atan2(dir.z, dir.x)
		var basis := Basis(Vector3(0, 1, 0), -ang).scaled(Vector3(seg_len, thick, thick))
		smm.set_instance_transform(i, Transform3D(basis, mid))
		smm.set_instance_color(i, specimen_color)
	add_child(spec_field)

	# --- covering grid + box count -----------------------------------------
	var cell: float = span / float(grid_n)
	var hit := {}
	var samples: int = maxi(seg_count * 6, 700)
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
	grid_field.name = "ScanGrid"
	var gmm: MultiMesh = grid_field.multimesh
	var n_hits: int = 0
	for gy in range(grid_n):
		for gx in range(grid_n):
			var key: int = gy * grid_n + gx
			var is_hit: bool = hit.has(key)
			if is_hit:
				n_hits += 1
			var cx: float = ox + (float(gx) + 0.5) * cell
			var cz: float = oz + (float(gy) + 0.5) * cell
			var box_s: float = cell * (0.9 if is_hit else 0.7)
			var box_h: float = 0.012 if is_hit else 0.004
			var basis2 := Basis().scaled(Vector3(box_s, box_h, box_s))
			gmm.set_instance_transform(key, Transform3D(basis2, Vector3(cx, stage_y - 0.006, cz)))
			gmm.set_instance_color(key, hit_color if is_hit else miss_color)
	add_child(grid_field)

	_d_value = log(float(n_hits)) / log(float(grid_n)) if grid_n > 1 and n_hits > 0 else 1.0

	# --- scanner head that rakes across the specimen -----------------------
	var head := Node3D.new()
	head.name = "ScanHead"
	add_child(head)
	_scanner = head
	var head_mat: StandardMaterial3D = _glow_mat(scan_color, 1.6)
	head.add_child(_box(Vector3(-0.36, 0.58, 0.0), Vector3(0.06, 0.05, 0.05), head_mat))
	# a thin scan blade dropping to the stage
	head.add_child(_box(Vector3(-0.36, 0.41, 0.0), Vector3(0.004, 0.30, span * 1.05), _glow_mat(scan_color, 1.0)))

	# --- needle gauge: swings between 1.0 and 2.0 pins ---------------------
	var gauge_mat: StandardMaterial3D = _matte_mat(Color(0.04, 0.05, 0.08), 0.9)
	add_child(_box(Vector3(0.30, 0.40, 0.18), Vector3(0.28, 0.24, 0.02), gauge_mat))
	add_child(_billboard_label("1.0", Vector3(0.20, 0.46, 0.20), 12, miss_color))
	add_child(_billboard_label("2.0", Vector3(0.40, 0.46, 0.20), 12, miss_color))
	var pivot := Node3D.new()
	pivot.name = "NeedlePivot"
	pivot.position = Vector3(0.30, 0.34, 0.19)
	add_child(pivot)
	_needle = pivot
	var needle_mat: StandardMaterial3D = _glow_mat(hit_color, 2.0)
	var needle := _box(Vector3(0.0, 0.07, 0.0), Vector3(0.008, 0.14, 0.008), needle_mat)
	pivot.add_child(needle)
	# fixed needle angle from D∈[1,2] -> [+60°, -60°]
	var frac: float = clampf((_d_value - 1.0), 0.0, 1.0)
	pivot.rotation.z = lerpf(PI / 3.0, -PI / 3.0, frac)

	# --- readout + label ----------------------------------------------------
	add_child(_billboard_label("N=%d  S=%d" % [n_hits, grid_n], Vector3(0.0, 0.56, 0.18), 16, hit_color))
	add_child(_billboard_label("D = log N / log S = %.3f" % _d_value, Vector3(0.0, 0.70, 0.18), 18, label_color))
	add_child(_billboard_label("DIMENSION METER", Vector3(0.0, 0.90, 0.0), 24, label_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _scanner != null:
		# rake the head across the specimen footprint
		_scanner.position.z = sin(_t * 1.3) * (span * 0.5)
	if _needle != null:
		# tiny live jitter around the settled reading
		var frac: float = clampf((_d_value - 1.0), 0.0, 1.0)
		_needle.rotation.z = lerpf(PI / 3.0, -PI / 3.0, frac) + sin(_t * 5.0) * 0.02
