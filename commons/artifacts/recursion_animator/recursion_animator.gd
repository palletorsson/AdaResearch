extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RecursionAnimator

## @identity
## name: "Recursive trees"
## tier: applied
## lineage: a stop-motion of recursion — the same split-and-recurse tree, but caught
##   one frame per level so you watch the call stack deepen and then reset.
## essence: A small device that animates recursion. Every beat it grows the tree one
##   recursion level deeper — 1, 2, 3, up to six — then folds back to a single trunk and
##   begins again. The readout names the current depth. The point made visible: the same
##   rule run to a deeper base case produces exponentially more structure, and the whole
##   crown was always implied by the first split. It rebuilds only on the tick, not every
##   frame — the tree is still between beats.
## truth: "recursion depth — one more level, exponentially more tree"
## applications: depth as a dial — watch how far a recursive rule unfolds, and feel the
##   cost and the bloom of each extra level.

@export var max_depth: int = 6
@export var step_seconds: float = 1.5
@export var branch_angle: float = 26.0
@export var shrink: float = 0.74
@export var bark_col: Color = Color(0.46, 0.30, 0.16)
@export var bud_col: Color = Color(0.46, 0.86, 0.40)
@export var case_col: Color = Color(0.12, 0.14, 0.18)
@export var label_col: Color = Color(0.86, 0.94, 0.7)

var _t: float = 0.0
var _accum: float = 0.0
var _cur_depth: int = 1
var _tree_root: Node3D = null
var _readout: Label3D = null

# branch accumulators (rebuilt each tick)
var _seg_a: Array[Vector3] = []
var _seg_b: Array[Vector3] = []
var _seg_r: Array[float] = []
var _seg_c: Array[Color] = []
var _buds: Array[Vector3] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_depth"):
		max_depth = clampi(int(config["max_depth"]), 1, 7)
	if config.has("step_seconds"):
		step_seconds = clampf(float(config["step_seconds"]), 0.4, 5.0)
	if config.has("branch_angle"):
		branch_angle = float(config["branch_angle"])
	if config.has("bark_col"):
		bark_col = _parse_color(config["bark_col"], bark_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tree_root = null
	_readout = null
	_cur_depth = 1
	_accum = 0.0
	_build()


func _build() -> void:
	# ~1m device: a base console with a recursion readout, and the tree growing above.
	var base_y: float = 0.10
	add_child(_box(Vector3(0.0, base_y, 0.0), Vector3(0.5, 0.2, 0.4), _matte_mat(case_col, 0.6, 0.3)))
	# slanted readout face
	var face: MeshInstance3D = _box(Vector3(0.0, 0.26, 0.16), Vector3(0.42, 0.16, 0.02), _glow_mat(Color(0.06, 0.09, 0.12), 0.6))
	face.rotation.x = deg_to_rad(-28.0)
	add_child(face)

	# Depth dial — a ring of pips, one lit per current level.
	var pip_mat_off: StandardMaterial3D = _matte_mat(Color(0.2, 0.22, 0.26), 0.7, 0.2)
	for i in range(max_depth):
		var x: float = lerpf(-0.18, 0.18, float(i) / float(maxi(max_depth - 1, 1)))
		var lit: bool = i < _cur_depth
		var mat: StandardMaterial3D = _glow_mat(bud_col, 2.2) if lit else pip_mat_off
		var pip: MeshInstance3D = _sphere(Vector3(x, 0.30, 0.20), 0.012, mat)
		pip.rotation.x = deg_to_rad(-28.0)
		pip.name = "pip_%d" % i
		add_child(pip)

	# Readout label on the face.
	_readout = _billboard_label(_readout_text(), Vector3(0.0, 0.40, 0.18), 18, label_col)
	add_child(_readout)

	# Tree growing out of the top of the device.
	var root := Node3D.new()
	root.name = "AnimTree"
	root.position = Vector3(0.0, 0.20, 0.0)
	add_child(root)
	_tree_root = root
	_rebuild_tree()

	# Title label above.
	add_child(_billboard_label("RECURSION DEPTH", Vector3(0.0, 1.15, 0.0), 24, label_col))


func _readout_text() -> String:
	var leaves: int = int(pow(2.0, float(_cur_depth - 1)))
	return "DEPTH %d / %d\n%d branch tips" % [_cur_depth, max_depth, leaves]


# Rebuild just the tree subtree for the current depth (called on the tick, not per frame).
func _rebuild_tree() -> void:
	if _tree_root == null:
		return
	for c in _tree_root.get_children():
		_tree_root.remove_child(c)
		c.queue_free()

	_seg_a.clear()
	_seg_b.clear()
	_seg_r.clear()
	_seg_c.clear()
	_buds.clear()

	_grow(Vector3.ZERO, Vector3.UP, 0.16, _cur_depth)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	mm.mesh = cyl
	mm.instance_count = _seg_a.size()
	for i in range(_seg_a.size()):
		var a: Vector3 = _seg_a[i]
		var b: Vector3 = _seg_b[i]
		var rr: float = _seg_r[i]
		var length: float = maxf(a.distance_to(b), 0.001)
		var basis: Basis = _basis_y_to(b - a).scaled(Vector3(rr, length, rr))
		mm.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
		mm.set_instance_color(i, _seg_c[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "AnimBranches"
	mi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.vertex_color_use_as_albedo = true
	bmat.roughness = 0.8
	bmat.emission_enabled = true
	bmat.emission = Color.WHITE
	bmat.emission_energy_multiplier = 0.14 if emissive else 0.0
	mi.material_override = bmat
	_tree_root.add_child(mi)

	if not _buds.is_empty():
		var bm := MultiMesh.new()
		bm.transform_format = MultiMesh.TRANSFORM_3D
		bm.use_colors = true
		bm.mesh = SphereMesh.new()
		bm.instance_count = _buds.size()
		for i in range(_buds.size()):
			var s: float = 0.016
			bm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), _buds[i]))
			bm.set_instance_color(i, bud_col)
		var bmi := MultiMeshInstance3D.new()
		bmi.name = "AnimBuds"
		bmi.multimesh = bm
		var budmat := StandardMaterial3D.new()
		budmat.vertex_color_use_as_albedo = true
		budmat.emission_enabled = true
		budmat.emission = Color.WHITE
		budmat.emission_energy_multiplier = 0.6 if emissive else 0.0
		bmi.material_override = budmat
		_tree_root.add_child(bmi)


func _grow(base: Vector3, dir: Vector3, length: float, d: int) -> void:
	var top: Vector3 = base + dir.normalized() * length
	var span: int = maxi(_cur_depth - 1, 1)
	var t: float = clampf(float(_cur_depth - d) / float(span), 0.0, 1.0)
	var col: Color = bark_col.lerp(bud_col, t)
	var radius: float = 0.01 * pow(shrink, float(_cur_depth - d)) + 0.002
	_seg_a.append(base)
	_seg_b.append(top)
	_seg_r.append(radius)
	_seg_c.append(col)

	if d <= 1:
		_buds.append(top)
		return

	var ang: float = deg_to_rad(branch_angle)
	var ref: Vector3 = Vector3.FORWARD if absf(dir.normalized().dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var axis: Vector3 = ref.cross(dir).normalized()
	axis = axis.rotated(dir.normalized(), float(_cur_depth - d) * 0.6)
	var left_dir: Vector3 = dir.normalized().rotated(axis, ang)
	var right_dir: Vector3 = dir.normalized().rotated(axis, -ang)
	var child_len: float = length * shrink
	_grow(top, left_dir, child_len, d - 1)
	_grow(top, right_dir, child_len, d - 1)


func _update_pips() -> void:
	for i in range(max_depth):
		var pip := get_node_or_null("pip_%d" % i)
		if pip is MeshInstance3D:
			var lit: bool = i < _cur_depth
			(pip as MeshInstance3D).material_override = (_glow_mat(bud_col, 2.2) if lit else _matte_mat(Color(0.2, 0.22, 0.26), 0.7, 0.2))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_accum += delta
	if _accum >= step_seconds:
		_accum = 0.0
		_cur_depth += 1
		if _cur_depth > max_depth:
			_cur_depth = 1
		_rebuild_tree()
		_update_pips()
		if _readout != null:
			_readout.text = _readout_text()
	# gentle sway between ticks
	if _tree_root != null:
		_tree_root.rotation.y = sin(_t * 0.5) * 0.12
