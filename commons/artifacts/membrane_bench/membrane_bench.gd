extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MembraneBench

## @identity
## name: "The membrane"
## tier: medium
## lineage: A selectively-permeable wall standing on a bench. Small particles drift through
##   the pores; big ones strike it and bounce. The boundary chooses what counts as inside.
## truth: "THE MARKOV BLANKET MADE FLESH — IT LETS THE SMALL THROUGH, TURNS THE LARGE AWAY"
## applications: ion channels, cell walls, the Markov blanket of active inference — a self
##   defined by what it admits and what it refuses.

const N_SMALL: int = 18
const N_BIG: int = 7

@export var wall_w: float = 0.9
@export var wall_h: float = 0.55
@export var membrane_col: Color = Color(0.45, 0.78, 0.95)
@export var small_col: Color = Color(0.55, 0.95, 0.60)
@export var big_col: Color = Color(0.95, 0.45, 0.40)
@export var bench_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _small_mm: MultiMesh = null
var _big_mm: MultiMesh = null
var _small_p: Array = []   # each: { pos, vel, phase }
var _big_p: Array = []
var _wall_z: float = 0.0
var _origin := Vector3(0.0, 0.85 + 0.3, 0.0)   # bench top + half wall height


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("wall_w"):
		wall_w = clampf(float(config["wall_w"]), 0.6, 1.4)
	if config.has("membrane_col"):
		membrane_col = _parse_color(config["membrane_col"], membrane_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_small_mm = null
	_big_mm = null
	_small_p.clear()
	_big_p.clear()
	_build()


func _build() -> void:
	# Bench the membrane stands on.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.2, 0.84, 0.7), _matte_mat(bench_col, 0.85)))

	var top: float = 0.86
	# A clear tank to hold the medium, the membrane bisecting it.
	add_child(_box(Vector3(0.0, top + wall_h * 0.5, 0.0), Vector3(wall_w + 0.1, wall_h, 0.55), _glass_mat(Color(0.6, 0.7, 0.85), 0.12)))

	# The membrane wall itself — a perforated sheet facing +Z, at z = 0.
	add_child(_box(Vector3(0.0, top + wall_h * 0.5, _wall_z), Vector3(wall_w, wall_h, 0.012), _glass_mat(membrane_col, 0.35)))
	# Pore studs along the membrane so it reads as porous, not solid.
	for i in range(6):
		var px: float = (float(i) - 2.5) * (wall_w / 6.0)
		add_child(_torus(Vector3(px, top + wall_h * 0.5, _wall_z), 0.03, 0.006, _glow_mat(membrane_col, 0.7)))

	_origin = Vector3(0.0, top + wall_h * 0.5, 0.0)

	# Small particles — start on +Z side, will pass through to -Z.
	_small_mm = _make_field(N_SMALL, 0.018, small_col)
	for i in range(N_SMALL):
		_small_p.append({
			"pos": _rand_in_tank(0.18),
			"vel": Vector3(0, 0, -_rng.randf_range(0.06, 0.14)),
			"phase": _rng.randf() * TAU,
		})
	# Big particles — bounce off, stay on +Z side.
	_big_mm = _make_field(N_BIG, 0.05, big_col)
	for i in range(N_BIG):
		_big_p.append({
			"pos": _rand_in_tank(0.16) + Vector3(0, 0, 0.08),
			"vel": Vector3(0, 0, -_rng.randf_range(0.05, 0.10)),
			"phase": _rng.randf() * TAU,
		})

	_refresh()

	add_child(_billboard_label("THE MARKOV BLANKET MADE FLESH —\nSMALL THROUGH, LARGE TURNED AWAY", Vector3(0.0, 1.6, 0.0), 17, label_col))


func _make_field(n: int, r: float, col: Color) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = _glow_mat(col, 0.7)
	add_child(mi)
	return mm


func _rand_in_tank(zmin: float) -> Vector3:
	return _origin + Vector3(
		_rng.randf_range(-wall_w * 0.42, wall_w * 0.42),
		_rng.randf_range(-wall_h * 0.4, wall_h * 0.4),
		_rng.randf_range(zmin, 0.22),
	)


func _refresh() -> void:
	for i in range(_small_p.size()):
		var t := Transform3D.IDENTITY
		t.origin = (_small_p[i]["pos"] as Vector3) - _origin
		_small_mm.set_instance_transform(i, t)
	for i in range(_big_p.size()):
		var bt := Transform3D.IDENTITY
		var s: float = 1.0 + sin(_t * 2.0 + float(_big_p[i]["phase"])) * 0.08
		bt.basis = Basis().scaled(Vector3(s, s, s))
		bt.origin = (_big_p[i]["pos"] as Vector3) - _origin
		_big_mm.set_instance_transform(i, bt)


func _step_particles(arr: Array, can_pass: bool) -> void:
	for i in range(arr.size()):
		var p: Dictionary = arr[i]
		var pos: Vector3 = p["pos"]
		var vel: Vector3 = p["vel"]
		pos += vel
		var local: Vector3 = pos - _origin
		# Membrane at z = _wall_z; big particles bounce, small pass.
		if not can_pass and local.z <= _wall_z + 0.02 and vel.z < 0.0:
			vel.z = absf(vel.z)
		# Wrap-around inside the tank so the demo never empties.
		if local.z < -0.24:
			local.z = 0.24
			local.x = _rng.randf_range(-wall_w * 0.42, wall_w * 0.42)
			pos = _origin + local
			vel.z = -absf(vel.z)
		if absf(local.x) > wall_w * 0.46:
			vel.x = -vel.x
		# Gentle vertical drift.
		pos.y = _origin.y + sin(_t * 1.2 + float(p["phase"])) * wall_h * 0.32
		p["pos"] = pos
		p["vel"] = vel


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_step_particles(_small_p, true)
	_step_particles(_big_p, false)
	_refresh()
