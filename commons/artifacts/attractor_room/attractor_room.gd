extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AttractorRoom

## @identity
## name: "Strange attractors"
## tier: large
## lineage: Lorenz (1963) — the butterfly that does not flap; a fixed orbit you can stand inside
## essence: A room-scale Lorenz attractor, ~3m across, that you walk around. The trajectory
##   loops on its two wings forever and never repeats a lap, yet stays trapped in a region
##   the size of the room. Sensitivity lives here: two nearby starts diverge, but neither
##   ever leaves the shape.
## truth: "NEVER REPEATS, NEVER ESCAPES" — bounded and unpredictable at once
## applications: climate, turbulence, encryption — the geometry of long-term unpredictability.

@export var steps: int = 4000
@export var dt: float = 0.006
@export var sigma: float = 10.0
@export var rho: float = 28.0
@export var beta: float = 8.0 / 3.0
@export var span: float = 3.0
@export var floor_size: float = 7.0
@export var floor_col: Color = Color(0.14, 0.15, 0.18)
@export var path_a: Color = Color(0.30, 0.60, 0.98)
@export var path_b: Color = Color(0.98, 0.40, 0.80)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _t: float = 0.0
var _sway: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("steps"):
		steps = clampi(int(config["steps"]), 800, 8000)
	if config.has("span"):
		span = float(config["span"])
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	if config.has("path_a"):
		path_a = _parse_color(config["path_a"], path_a)
	if config.has("path_b"):
		path_b = _parse_color(config["path_b"], path_b)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
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
	# Room floor
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), _matte_mat(floor_col, 0.95, 0.1)))
	# Plinth ring under the attractor
	add_child(_cylinder(Vector3(0.0, 0.05, 0.0), span * 0.55, 0.1, _matte_mat(Color(0.20, 0.21, 0.24), 0.9)))

	var sway := Node3D.new()
	sway.name = "AttractorSway"
	add_child(sway)
	_sway = sway

	var pts: Array = _lorenz_points()
	var n: int = pts.size()

	# Centre on the cloud centroid and scale the whole orbit to `span`.
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var centroid := Vector3.ZERO
	for p: Vector3 in pts:
		centroid += p
		lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
		hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))
	centroid /= float(max(n, 1))
	var extent: Vector3 = hi - lo
	var raw: float = maxf(extent.x, maxf(extent.y, extent.z))
	var s: float = span / maxf(raw, 0.001)

	var field := _field(n, false)
	var bm := field.multimesh.mesh as SphereMesh
	bm.radius = 0.45
	bm.height = 0.9
	# Lift so the orbit floats eye-high above the plinth.
	field.position = Vector3(0.0, span * 0.55 + 0.4, 0.0)

	for i in range(n):
		var local: Vector3 = (pts[i] - centroid) * s
		var f: float = float(i) / float(max(n - 1, 1))
		var xf := Transform3D(Basis().scaled(Vector3.ONE * 0.045), local)
		field.multimesh.set_instance_transform(i, xf)
		field.multimesh.set_instance_color(i, path_a.lerp(path_b, f))
	sway.add_child(field)

	add_child(_billboard_label("NEVER REPEATS, NEVER ESCAPES", Vector3(0.0, 3.6, 0.0), 30, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = _t * 0.12
