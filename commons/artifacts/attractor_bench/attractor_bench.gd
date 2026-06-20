extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AttractorBench

## @identity
## name: "Strange attractors"
## tier: medium
## lineage: Lorenz (1963) — three coupled ODEs for convection, an accident that became chaos
## essence: A Lorenz attractor sitting on a bench top. Integrate three coupled rates and
##   the trajectory never settles to a point, never blows up, never crosses itself — it
##   winds forever on two looping wings. Deterministic, bounded, and never the same lap.
## truth: "CHAOS WITH A SHAPE" — disorder that lives inside a fixed, knowable form
## applications: weather, mixing, secure noise — systems too sensitive to predict yet
##   confined to a structure you can draw.

@export var steps: int = 4000
@export var dt: float = 0.006
@export var sigma: float = 10.0
@export var rho: float = 28.0
@export var beta: float = 8.0 / 3.0
@export var plot_scale: float = 0.05
@export var top_y: float = 0.86
@export var bench_color: Color = Color(0.18, 0.19, 0.22)
@export var path_a: Color = Color(0.25, 0.55, 0.95)
@export var path_b: Color = Color(0.95, 0.45, 0.85)
@export var label_col: Color = Color(0.80, 0.86, 0.94)

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
		steps = clampi(int(config["steps"]), 500, 8000)
	if config.has("plot_scale"):
		plot_scale = float(config["plot_scale"])
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
	# Bench base + top
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.7), _matte_mat(bench_color, 0.7)))
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.12, 0.04, 0.72), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))
	add_child(_cylinder(Vector3(0.0, 0.20, 0.0), 0.05, 0.40, _steel_mat(Color(0.35, 0.37, 0.4))))

	var sway := Node3D.new()
	sway.name = "AttractorSway"
	add_child(sway)
	_sway = sway

	var pts: Array = _lorenz_points()
	var n: int = pts.size()

	# Centre the attractor and lift it onto the bench top.
	# Lorenz z mean ~ rho-ish; recentre on the cloud's own centroid.
	var centroid := Vector3.ZERO
	for p: Vector3 in pts:
		centroid += p
	centroid /= float(max(n, 1))

	var field := _field(n, false)
	var bm := field.multimesh.mesh as SphereMesh
	bm.radius = 0.45
	bm.height = 0.9
	field.position = Vector3(0.0, top_y + 0.36, 0.0)

	for i in range(n):
		var local: Vector3 = (pts[i] - centroid) * plot_scale
		var f: float = float(i) / float(max(n - 1, 1))
		var xf := Transform3D(Basis().scaled(Vector3.ONE * 0.018), local)
		field.multimesh.set_instance_transform(i, xf)
		field.multimesh.set_instance_color(i, path_a.lerp(path_b, f))
	sway.add_child(field)

	add_child(_billboard_label("CHAOS WITH A SHAPE", Vector3(0.0, 1.6, 0.0), 28, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = _t * 0.25
