extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GradientDescentOptimizer

## @identity
## name: "Settling: gradient descent toward max Q"
## tier: applied
## lineage: the marble-in-a-bowl wearing a lab coat — the exact motion a neural net makes
##   while training. Same downhill walk, just on a loss surface instead of a physical one.
## essence: An optimiser device, ~1m, with a soft body descending an energy landscape while a
##   readout counts steps and reports the energy falling. Each step takes the gradient and
##   moves a little downhill; the energy curve drops and flattens. This is the bridge: settling
##   a soft body and training a model are one algorithm — follow the slope of a cost toward its
##   minimum. The blob rolling into the basin is a network learning, slowed down to watch.
## truth: "TRAINING IS SETTLING — THE SAME WALK DOWNHILL TOWARD MAX Q"
## applications: machine learning, control, fitting — gradient descent is the engine of training.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var grid: int = 24
@export var span: float = 0.8
@export var amp: float = 0.13
@export var learning_rate: float = 0.06
@export var surf_low: Color = Color(0.20, 0.28, 0.50)
@export var surf_high: Color = Color(0.90, 0.50, 0.95)
@export var ball_col: Color = Color(0.95, 0.85, 0.40)
@export var trail_col: Color = Color(0.50, 0.95, 0.85)
@export var readout_col: Color = Color(0.55, 0.95, 0.80)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sway: Node3D = null
var _ball: MeshInstance3D = null
var _trail_mm: MultiMesh = null
var _readout: Label3D = null
# Descent state — the optimiser's current point on the surface (x,z).
var _p: Vector2 = Vector2.ZERO
var _step: int = 0
var _trail: Array = []
const TRAIL_MAX := 40


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 12, 40)
	if config.has("span"):
		span = float(config["span"])
	if config.has("learning_rate"):
		learning_rate = clampf(float(config["learning_rate"]), 0.01, 0.2)
	if config.has("ball_col"):
		ball_col = _parse_color(config["ball_col"], ball_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_ball = null
	_trail_mm = null
	_readout = null
	_build()


func _energy(x: float, z: float) -> float:
	# A loss surface with a clear global basin near centre plus wrinkles (local minima).
	var bowl: float = (x * x + z * z) * 0.5
	var wrinkle: float = sin(x * 7.0) * 0.18 + cos(z * 6.0) * 0.16
	return amp * (bowl + wrinkle)


func _grad(x: float, z: float) -> Vector2:
	var e: float = 0.012
	var gx: float = (_energy(x + e, z) - _energy(x - e, z)) / (2.0 * e)
	var gz: float = (_energy(x, z + e) - _energy(x, z - e)) / (2.0 * e)
	return Vector2(gx, gz)


func _surface_mesh() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	mm.instance_count = grid * grid
	var cell: float = span / float(grid)
	var lo: float = INF
	var hi: float = -INF
	for gz in range(grid):
		for gx in range(grid):
			var x: float = (float(gx) / float(grid - 1) - 0.5) * span
			var z: float = (float(gz) / float(grid - 1) - 0.5) * span
			var h: float = _energy(x, z)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	var idx: int = 0
	for gz in range(grid):
		for gx in range(grid):
			var x: float = (float(gx) / float(grid - 1) - 0.5) * span
			var z: float = (float(gz) / float(grid - 1) - 0.5) * span
			var h: float = _energy(x, z)
			var ct: float = (h - lo) / maxf(hi - lo, 1e-4)
			var xf := Transform3D(Basis().scaled(Vector3(cell * 0.95, 0.02, cell * 0.95)), Vector3(x, h, z))
			mm.set_instance_transform(idx, xf)
			mm.set_instance_color(idx, surf_low.lerp(surf_high, ct))
			idx += 1
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _ball_world() -> Vector3:
	return Vector3(_p.x, _energy(_p.x, _p.y) + 0.035, _p.y)


func _build() -> void:
	# Device base + pillar (applied tier ~1m device)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.0, 0.2, 0.9), _matte_mat(Color(0.15, 0.16, 0.19), 0.85)))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.08, 0.5, _steel_mat(Color(0.34, 0.36, 0.40))))

	var sway := Node3D.new()
	sway.name = "OptSway"
	add_child(sway)
	_sway = sway

	# Loss surface on top
	var surf := _surface_mesh()
	surf.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(surf)

	# Descending ball — start high on a slope.
	_p = Vector2(span * 0.34, -span * 0.30)
	_step = 0
	_trail.clear()
	var ball_holder := Node3D.new()
	ball_holder.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(ball_holder)
	_ball = _sphere(_ball_world(), 0.04, _glow_mat(ball_col, 1.6))
	ball_holder.add_child(_ball)

	# Trail of past positions (the descent path).
	var trail_mi := MultiMeshInstance3D.new()
	var tmm := MultiMesh.new()
	tmm.transform_format = MultiMesh.TRANSFORM_3D
	var tsm := SphereMesh.new()
	tsm.radius = 0.016
	tsm.height = 0.032
	tmm.mesh = tsm
	tmm.instance_count = TRAIL_MAX
	_trail_mm = tmm
	trail_mi.multimesh = tmm
	trail_mi.material_override = _glow_mat(trail_col, 1.0)
	ball_holder.add_child(trail_mi)
	_refresh_trail()

	# Readout panel
	add_child(_box(Vector3(0.55, 1.1, 0.3), Vector3(0.36, 0.22, 0.02), _matte_mat(Color(0.09, 0.10, 0.13), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.55, 1.1, 0.32), 16, readout_col)
	add_child(_readout)

	add_child(_billboard_label("TRAINING IS SETTLING — THE WALK DOWNHILL", Vector3(0.0, 1.62, 0.0), 20, label_col))


func _readout_text() -> String:
	return "GRADIENT DESCENT\nstep: %d\nenergy: %.4f\nlr: %.3f\n(= a net training)" % [_step, _energy(_p.x, _p.y), learning_rate]


func _refresh_trail() -> void:
	if _trail_mm == null:
		return
	for i in range(TRAIL_MAX):
		var t := Transform3D.IDENTITY
		if i < _trail.size():
			t.origin = _trail[i]
			# Older points shrink away.
			var s: float = 0.4 + 0.6 * (float(i) / float(max(_trail.size() - 1, 1)))
			t = t.scaled(Vector3.ONE * s)
		else:
			t = t.scaled(Vector3.ZERO)
		_trail_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# One descent step every ~0.12s so the motion is watchable.
	if fmod(_t, 0.12) < delta:
		var g: Vector2 = _grad(_p.x, _p.y)
		_p -= g * learning_rate
		_p.x = clampf(_p.x, -span * 0.5, span * 0.5)
		_p.y = clampf(_p.y, -span * 0.5, span * 0.5)
		_step += 1
		_trail.append(_ball_world())
		if _trail.size() > TRAIL_MAX:
			_trail.pop_front()
		_refresh_trail()
		# Restart from a fresh slope once it has clearly converged (re-runs the demo).
		if _grad(_p.x, _p.y).length() < 0.002 and _step > 30:
			_p = Vector2(_rng.randf_range(-span * 0.4, span * 0.4), _rng.randf_range(-span * 0.4, span * 0.4))
			_step = 0
			_trail.clear()
		if _readout != null:
			_readout.text = _readout_text()

	if _ball != null:
		_ball.position = _ball_world()
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.25) * 0.1
