extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MengerBench

## @identity
## A bench showing the Menger sponge forming — iteration 0 (solid cube), 1, 2, 3 in a row.
## Truth: "infinite surface, zero volume". Watch the volume drain to nothing while the
## surface area climbs without bound. The carving rule is the same at every scale.

@export var max_depth: int = 3
@export var sponge_color: Color = Color(0.85, 0.55, 0.25)
@export var sway: bool = true

const STEP_SIZE: float = 0.32
const STEP_GAP: float = 0.42

var _all_cells: Array[Vector3] = []
var _all_colors: Array[Color] = []
var _leaf_sizes: Array[float] = []
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_depth"):
		max_depth = int(config["max_depth"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_build_bench()
	_compute_all()
	add_child(_sponge_field())
	add_child(_billboard_label("INFINITE SURFACE, ZERO VOLUME", Vector3(0.0, 1.6, 0.0), 20, sponge_color))
	# Small captions per step on the top of the bench.
	var steps: int = clampi(max_depth, 1, 3) + 1
	var total_w: float = float(steps - 1) * STEP_GAP
	for i in range(steps):
		var x: float = -total_w * 0.5 + float(i) * STEP_GAP
		add_child(_billboard_label("n=%d" % i, Vector3(x, 0.95, 0.0), 13, Color(0.7, 0.75, 0.8)))


func _build_bench() -> void:
	var top_mat := _matte_mat(Color(0.18, 0.2, 0.24), 0.7, 0.1)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.08, 0.45), top_mat))
	var leg_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_box(Vector3(-0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))


func _compute_all() -> void:
	_all_cells.clear()
	_all_colors.clear()
	_leaf_sizes.clear()
	var steps: int = clampi(max_depth, 1, 3) + 1
	var total_w: float = float(steps - 1) * STEP_GAP
	for i in range(steps):
		var x: float = -total_w * 0.5 + float(i) * STEP_GAP
		var divisions: int = int(pow(3.0, float(i)))
		var leaf: float = STEP_SIZE / float(maxi(divisions, 1))
		_leaf_sizes.append(leaf)
		var cells: Array[Vector3] = []
		_recurse(Vector3.ZERO, STEP_SIZE, i, cells)
		for p in cells:
			var world: Vector3 = p + Vector3(x, 1.05 + STEP_SIZE * 0.5, 0.0)
			_all_cells.append(world)
			var edge: float = clampf((absf(p.x) + absf(p.y) + absf(p.z)) / (STEP_SIZE * 1.5), 0.0, 1.0)
			_all_colors.append(sponge_color.lerp(Color(1.0, 0.85, 0.4), edge))


func _recurse(center: Vector3, size: float, level: int, out: Array[Vector3]) -> void:
	if level == 0:
		out.append(center)
		return
	var child: float = size / 3.0
	for ix in range(3):
		for iy in range(3):
			for iz in range(3):
				var mids: int = 0
				if ix == 1:
					mids += 1
				if iy == 1:
					mids += 1
				if iz == 1:
					mids += 1
				if mids >= 2:
					continue
				var off := Vector3(float(ix) - 1.0, float(iy) - 1.0, float(iz) - 1.0) * child
				_recurse(center + off, child, level - 1, out)


func _sponge_field() -> MultiMeshInstance3D:
	var n: int = _all_cells.size()
	var mi := _field(n, true)
	var mm: MultiMesh = mi.multimesh
	for i in range(n):
		# Per-cell leaf scale varies by step; encode via a small per-cell box size.
		var s: float = 0.96 * _nearest_leaf(_all_cells[i].x)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), _all_cells[i]))
		mm.set_instance_color(i, _all_colors[i])
	return mi


func _nearest_leaf(world_x: float) -> float:
	# Map world x back to which step column it belongs to, return that step's leaf size.
	var steps: int = _leaf_sizes.size()
	var total_w: float = float(steps - 1) * STEP_GAP
	var best_i: int = 0
	var best_d: float = 1e9
	for i in range(steps):
		var cx: float = -total_w * 0.5 + float(i) * STEP_GAP
		var d: float = absf(world_x - cx)
		if d < best_d:
			best_d = d
			best_i = i
	return _leaf_sizes[best_i]


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
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not sway:
		return
	_t += delta
