extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AttractorPlotter

## @identity
## name: "Strange attractors"
## tier: applied
## lineage: the pen plotter — a machine that draws an ODE one timestep at a time
## essence: A small plotter device. A pen on a swinging arm traces the Lorenz path onto a
##   plate while a panel shows the three equations driving it. The ink is the proof: a
##   deterministic recipe, integrated step by step, draws a shape that never closes.
## truth: "CHAOS WITH A SHAPE" — the same equation, the same orbit, drawn by hand of a machine
## applications: signal generators, chaotic oscillators, art machines — turning a rule into a mark.

@export var steps: int = 4000
@export var dt: float = 0.006
@export var sigma: float = 10.0
@export var rho: float = 28.0
@export var beta: float = 8.0 / 3.0
@export var plate_size: float = 0.7
@export var body_col: Color = Color(0.20, 0.21, 0.25)
@export var plate_col: Color = Color(0.92, 0.92, 0.88)
@export var ink_a: Color = Color(0.15, 0.35, 0.85)
@export var ink_b: Color = Color(0.85, 0.20, 0.55)
@export var pen_col: Color = Color(0.85, 0.88, 0.92)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _t: float = 0.0
var _pen_arm: Node3D = null
var _ink_pts: Array = []
var _pen_idx: int = 0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("steps"):
		steps = clampi(int(config["steps"]), 800, 8000)
	if config.has("plate_size"):
		plate_size = float(config["plate_size"])
	if config.has("ink_a"):
		ink_a = _parse_color(config["ink_a"], ink_a)
	if config.has("ink_b"):
		ink_b = _parse_color(config["ink_b"], ink_b)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_pen_arm = null
	_ink_pts = []
	_pen_idx = 0
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
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _lorenz_points() -> Array:
	var pts: Array = []
	var x: float = 0.1
	var y: float = 0.0
	var z: float = 0.0
	for _i in range(steps):
		var dx: float = sigma * (y - x)
		var dy: float = x * (rho - z) - y
		var dz: float = x * y - beta * z
		x += dx * dt
		y += dy * dt
		z += dz * dt
		pts.append(Vector3(x, y, z))
	return pts


func _build() -> void:
	# Device base + plate (the drawing surface, drawn flat at y ~ 0.66 top).
	add_child(_box(Vector3(0.0, 0.30, 0.0), Vector3(0.9, 0.6, 0.7), _matte_mat(body_col, 0.6, 0.2)))
	add_child(_box(Vector3(0.0, 0.62, 0.0), Vector3(plate_size, 0.02, plate_size), _matte_mat(plate_col, 0.4)))

	# Project the Lorenz orbit onto the plate (drop the z axis → a flat butterfly).
	var pts: Array = _lorenz_points()
	var n: int = pts.size()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var flat: Array = []
	for p: Vector3 in pts:
		var q := Vector2(p.x, p.z)
		flat.append(q)
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var ext: Vector2 = hi - lo
	var raw: float = maxf(ext.x, ext.y)
	var s: float = (plate_size * 0.86) / maxf(raw, 0.001)
	var cen := (lo + hi) * 0.5

	# Ink: small dots on the plate along the path.
	var field := _field(n, false)
	var bm := field.multimesh.mesh as SphereMesh
	bm.radius = 0.45
	bm.height = 0.9
	field.position = Vector3(0.0, 0.635, 0.0)
	for i in range(n):
		var q: Vector2 = (flat[i] - cen) * s
		var f: float = float(i) / float(max(n - 1, 1))
		var xf := Transform3D(Basis().scaled(Vector3.ONE * 0.006), Vector3(q.x, 0.0, q.y))
		field.multimesh.set_instance_transform(i, xf)
		field.multimesh.set_instance_color(i, ink_a.lerp(ink_b, f))
		_ink_pts.append(Vector3(q.x, 0.66, q.y))
	add_child(field)

	# Pen on a swinging arm — pivot at one corner of the device.
	var arm := Node3D.new()
	arm.name = "PenArm"
	arm.position = Vector3(-0.42, 0.78, -0.30)
	add_child(arm)
	_pen_arm = arm
	# arm beam reaching toward plate centre
	arm.add_child(_cylinder_between(Vector3.ZERO, Vector3(0.42, -0.12, 0.30), 0.012, _steel_mat(Color(0.45, 0.47, 0.5))))
	# pen tip holder at the reach end
	var tip := Node3D.new()
	tip.position = Vector3(0.42, -0.12, 0.30)
	arm.add_child(tip)
	tip.add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.01, 0.10, _matte_mat(pen_col, 0.5)))
	tip.add_child(_sphere(Vector3(0.0, -0.02, 0.0), 0.012, _glow_mat(ink_b, 1.8)))

	# Equation panel — a small upright board behind the plate.
	add_child(_box(Vector3(0.0, 0.78, -0.36), Vector3(0.62, 0.34, 0.02), _matte_mat(Color(0.08, 0.09, 0.11), 0.5)))
	add_child(_billboard_label("x' = 10(y - x)\ny' = x(28 - z) - y\nz' = xy - (8/3)z", Vector3(0.0, 0.86, -0.34), 12, Color(0.55, 0.85, 0.95)))

	add_child(_billboard_label("LORENZ PLOTTER", Vector3(0.0, 1.18, 0.0), 22, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Sweep the pen along the traced path (visual only — ink is already laid down).
	if _pen_arm != null and _ink_pts.size() > 0:
		_pen_idx = (_pen_idx + 3) % _ink_pts.size()
		var target: Vector3 = _ink_pts[_pen_idx]
		# Point the arm so its reach end roughly follows the dot under it.
		var dx: float = target.x - (-0.42)
		var dz: float = target.z - (-0.30)
		_pen_arm.rotation.y = atan2(dz, dx) - atan2(0.30, 0.42)
		_pen_arm.rotation.x = sin(_t * 1.4) * 0.02
