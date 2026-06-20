extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name IfsBench

## @identity
## Iterated function systems (IFS) — MEDIUM, the chaos game on a bench.
## Truth: a fern appears with no fern ever drawn. Four affine maps, thrown at
## random ~4000 times, and the Barnsley fern condenses out of the dust. No leaf,
## no stem, no curve was authored — only the rule of where to go next.

@export var point_count: int = 4000
@export var seed_dot: float = 0.006
@export var fern_color: Color = Color(0.25, 0.85, 0.32)
@export var fern_height: float = 0.74

var _seeds: MultiMeshInstance3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _field(n: int, box: bool = false) -> MultiMeshInstance3D:
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
	mat.emission_energy_multiplier = 0.22 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# Bench base.
	var base_mat := _matte_mat(Color(0.14, 0.15, 0.18), 0.85)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.2, 0.7), base_mat))
	var pillar_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.9, pillar_mat))

	# The fern, condensed onto the bench top, facing +Z.
	_seeds = _field(point_count)
	add_child(_seeds)
	_plot_fern()

	add_child(_billboard_label("FOUR MAPS, A FERN", Vector3(0.0, 1.6, 0.0), 28, Color(0.7, 1.0, 0.75)))


func _plot_fern() -> void:
	var mm: MultiMesh = _seeds.multimesh
	# Barnsley fern is ~y in [0,10], x in [-2.5, 2.5]. Map to bench top.
	var origin := Vector3(0.0, 0.96, 0.0)
	var sx: float = (fern_height * 0.45) / 5.0   # x half-width -> world
	var sy: float = fern_height / 10.0           # y up
	var px: float = 0.0
	var py: float = 0.0
	for i in range(point_count):
		var r: float = _rng.randf()
		var nx: float = 0.0
		var ny: float = 0.0
		if r < 0.01:
			nx = 0.0
			ny = 0.16 * py
		elif r < 0.86:
			nx = 0.85 * px + 0.04 * py
			ny = -0.04 * px + 0.85 * py + 1.6
		elif r < 0.93:
			nx = 0.20 * px - 0.26 * py
			ny = 0.23 * px + 0.22 * py + 1.6
		else:
			nx = -0.15 * px + 0.28 * py
			ny = 0.26 * px + 0.24 * py + 0.44
		px = nx
		py = ny
		if i < 20:
			continue
		var pos := origin + Vector3(px * sx, py * sy, 0.0)
		var s: float = seed_dot
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
		# Slight tonal variation top-of-frond brighter.
		var t: float = clampf(py / 10.0, 0.0, 1.0)
		mm.set_instance_color(i, fern_color.lerp(Color(0.55, 1.0, 0.45), t * 0.6))
	# First 20 burn-in points parked off-screen.
	for j in range(20):
		mm.set_instance_transform(j, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), origin))
		mm.set_instance_color(j, Color(0, 0, 0, 0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _seeds:
		_seeds.rotation.y = sin(Time.get_ticks_msec() * 0.0004) * 0.08
