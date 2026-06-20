extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AbjectBench

## @identity
## name: "The abject as force"
## tier: medium
## lineage: A bench where a soft body leaks across its boundary — it drips down a glass plate,
##   seeps past its drawn edge, reaches a pseudopod out into the world, then pulls back. Affect
##   as a force: softness that is felt precisely because it will not stay contained.
## truth: "ABJECTION AS A GENERATIVE FORCE — SOFTNESS AS A FEELING THAT CROSSES ITS OWN EDGE"
## applications: Kristeva's abject, affect theory, the leaky boundary, wetware that overflows its
##   vessel — the productive failure of the line between inside and out.

const N_DRIPS: int = 14
const N_SEEP: int = 40

@export var bench_w: float = 1.3
@export var body_col: Color = Color(0.70, 0.38, 0.60)
@export var drip_col: Color = Color(0.88, 0.45, 0.58)
@export var edge_col: Color = Color(0.95, 0.80, 0.40)
@export var bench_col: Color = Color(0.16, 0.15, 0.18)
@export var label_col: Color = Color(0.95, 0.90, 0.94)

var _t: float = 0.0
var _body: MeshInstance3D = null
var _pseudo: MeshInstance3D = null
var _drip_mm: MultiMesh = null
var _drips: Array = []        # each: { x:float, phase:float }
var _seep_mm: MultiMesh = null
var _seep: Array = []         # each: Vector3 dir on a disc
var _top: float = 0.86
var _body_pos := Vector3(0.0, 1.1, 0.0)
var _edge_z: float = 0.22


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("bench_w"):
		bench_w = clampf(float(config["bench_w"]), 0.9, 1.8)
	if config.has("body_col"):
		body_col = _parse_color(config["body_col"], body_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_body = null
	_pseudo = null
	_drip_mm = null
	_drips.clear()
	_seep_mm = null
	_seep.clear()
	_build()


func _build() -> void:
	# Bench.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(bench_w + 0.2, 0.84, 0.6), _matte_mat(bench_col, 0.85)))
	_body_pos = Vector3(0.0, _top + 0.26, 0.0)

	# The drawn boundary on the bench top — a bright ring the body should stay inside.
	add_child(_torus(Vector3(0.0, _top + 0.005, 0.0), 0.3, 0.006, _glow_mat(edge_col, 0.7)))

	# Glass plate at the front the body drips down.
	add_child(_box(Vector3(0.0, _top + 0.18, _edge_z), Vector3(bench_w * 0.7, 0.36, 0.01), _glass_mat(Color(0.6, 0.7, 0.85), 0.12)))

	# The soft body, sitting on the line, facing +Z.
	_body = _sphere(_body_pos, 0.16, _glow_mat(body_col, 0.55))
	add_child(_body)

	# A pseudopod — reaches out past the edge into the world, then withdraws.
	# Unit-height cylinder (height 1.0) so runtime Y-scale maps directly to its length.
	_pseudo = _cylinder(Vector3.ZERO, 0.04, 1.0, _glow_mat(drip_col, 0.6))
	add_child(_pseudo)

	# Drips running down the glass plate.
	_drip_mm = _make_field(N_DRIPS, 0.022, drip_col)
	for i in range(N_DRIPS):
		_drips.append({ "x": _rng.randf_range(-bench_w * 0.3, bench_w * 0.3), "phase": _rng.randf() })
	# Seep field on the bench top — studs creeping outward past the ring.
	_seep_mm = _make_field(N_SEEP, 0.015, body_col)
	for i in range(N_SEEP):
		var a: float = _rng.randf() * TAU
		_seep.append(Vector3(cos(a), 0.0, sin(a)))
	_refresh()

	add_child(_billboard_label("ABJECTION AS A GENERATIVE FORCE —\nSOFTNESS AS A FEELING", Vector3(0.0, 1.6, 0.0), 17, label_col))


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


func _refresh() -> void:
	if _drip_mm != null:
		for i in range(_drips.size()):
			var d: Dictionary = _drips[i]
			var phase: float = fmod(_t * 0.4 + float(d["phase"]), 1.0)
			var y: float = _top + 0.36 - phase * 0.4
			var stretch: float = 1.0 + phase * 2.0
			var t := Transform3D(Basis().scaled(Vector3(1.0, stretch, 1.0)), Vector3(float(d["x"]), y, _edge_z - 0.01))
			_drip_mm.set_instance_transform(i, t)
	if _seep_mm != null:
		for i in range(_seep.size()):
			var dir: Vector3 = _seep[i]
			# Each seep stud creeps outward past the 0.3 ring, breathing in and out.
			var reach: float = 0.3 + (sin(_t * 0.8 + float(i) * 0.6) * 0.5 + 0.5) * 0.18
			var p := Vector3(dir.x * reach, _top + 0.01, dir.z * reach)
			_seep_mm.set_instance_transform(i, Transform3D.IDENTITY.translated(p))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Body strains and overflows — never a clean contained sphere.
	if _body != null:
		var sx: float = 1.0 + sin(_t * 1.2) * 0.12
		var sy: float = 1.0 + cos(_t * 0.85) * 0.16
		_body.scale = Vector3(sx, sy, sx)
	# Pseudopod reaches out and withdraws — the body crossing its own edge.
	# Unit-height cylinder: orient with _basis_y_to, then scale Y to the gap length.
	if _pseudo != null:
		var reach: float = (sin(_t * 0.7) * 0.5 + 0.5) * 0.4 + 0.1
		var tip: Vector3 = _body_pos + Vector3(sin(_t * 0.5) * 0.1, -0.05, reach)
		var h: float = maxf(_body_pos.distance_to(tip), 0.001)
		_pseudo.transform = Transform3D(_basis_y_to(tip - _body_pos).scaled(Vector3(1.0, h, 1.0)), (_body_pos + tip) * 0.5)
	_refresh()
