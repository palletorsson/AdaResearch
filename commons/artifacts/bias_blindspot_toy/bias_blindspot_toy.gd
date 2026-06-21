extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BiasBlindspotToy

## @identity
## name: Bias Blindspot Toy
## truth: Every model has a shape it can't see from inside itself.
##
## Bias as structural incompleteness — SMALL, held (~0.4m, no base).
## A little classifier with a visible BLIND SPOT: a disc of input space the
## model "sees" (lit cells, classified blue/teal), and a dark wedge it is
## blind to. Samples that land in the wedge get mislabelled and flash amber-red.

@export var blind_angle_deg: float = 62.0  # angular width of the blind wedge
@export var sample_rate: float = 0.7       # seconds between new samples
@export var ring_cells: int = 28           # cells around the seeing-ring

const COOL_WHITE := Color(0.90, 0.92, 0.97)
const SLATE := Color(0.36, 0.40, 0.50)
const PURPLE := Color(0.58, 0.42, 0.92)
const SEE_TEAL := Color(0.30, 0.82, 0.78)
const SEE_BLUE := Color(0.42, 0.58, 0.95)
const BLIND_DARK := Color(0.06, 0.06, 0.10)
const MISLABEL := Color(0.98, 0.36, 0.22)  # warm-red flash for misread samples

var _disc_radius: float = 0.17
var _ring_cell_nodes: Array[MeshInstance3D] = []
var _sample: MeshInstance3D = null
var _sample_mat: StandardMaterial3D = null
var _sample_angle: float = 0.0
var _sample_t: float = 0.0
var _sample_in_blind: bool = false
var _timer: float = 0.0
var _scanner: Node3D = null
var _scan_phase: float = 0.0


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


func _build() -> void:
	_ring_cell_nodes.clear()

	# Seeing-disc base (the model's representable input space) — cool/formal.
	var disc_mat: StandardMaterial3D = _glass_mat(SEE_BLUE, 0.16)
	add_child(_cylinder(Vector3(0, 0, 0), _disc_radius, 0.012, disc_mat))

	# Purple wireframe rim — formal boundary of "what is modelled at all".
	var rim_mat: StandardMaterial3D = _glow_mat(PURPLE, 1.4)
	add_child(_torus(Vector3(0, 0.008, 0), _disc_radius, 0.006, rim_mat))

	# The seeing-ring: cells the model can classify. Blind wedge stays dark.
	var half: float = deg_to_rad(blind_angle_deg) * 0.5
	for i in range(ring_cells):
		var a: float = TAU * float(i) / float(ring_cells)
		var in_blind: bool = absf(_angle_diff(a, 0.0)) < half
		var r: float = _disc_radius * 0.82
		var pos := Vector3(cos(a) * r, 0.02, sin(a) * r)
		var cell_mat: StandardMaterial3D
		if in_blind:
			cell_mat = _matte_mat(BLIND_DARK, 0.95)
		else:
			# alternate the two "seen" classes around the lit arc
			cell_mat = _glow_mat(SEE_TEAL if i % 2 == 0 else SEE_BLUE, 1.5)
		var cell: MeshInstance3D = _box(pos, Vector3(0.022, 0.018, 0.022), cell_mat)
		cell.rotation.y = -a
		add_child(cell)
		_ring_cell_nodes.append(cell)

	# The blind wedge made visible: a dark fan slab over the unseen angles.
	var wedge_mat: StandardMaterial3D = _matte_mat(BLIND_DARK, 0.98)
	var steps: int = 6
	for j in range(steps):
		var frac: float = (float(j) + 0.5) / float(steps)
		var a2: float = -half + deg_to_rad(blind_angle_deg) * frac
		var rr: float = _disc_radius * (0.30 + 0.55 * frac)
		var w: float = _disc_radius * 0.16 * frac + 0.01
		var p := Vector3(cos(a2) * rr * 0.5, 0.016, sin(a2) * rr * 0.5)
		var slab: MeshInstance3D = _box(p, Vector3(rr, 0.01, w), wedge_mat)
		slab.rotation.y = -a2
		add_child(slab)

	# A constructive amber tag on the blind wedge — "named, built-around".
	var tag_mat: StandardMaterial3D = _glow_mat(Color(0.98, 0.72, 0.28), 1.8)
	var tag_a: float = 0.0
	add_child(_sphere(Vector3(cos(tag_a) * _disc_radius * 0.6, 0.05, sin(tag_a) * _disc_radius * 0.6), 0.012, tag_mat))

	# Central classifier core (slate steel) — the model "looking out".
	add_child(_cylinder(Vector3(0, 0.03, 0), 0.035, 0.05, _steel_mat(SLATE)))
	add_child(_sphere(Vector3(0, 0.062, 0), 0.022, _glow_mat(COOL_WHITE, 1.2)))

	# Rotating scan beam from the core — sweeps, but cannot enter the wedge.
	_scanner = Node3D.new()
	add_child(_scanner)
	var beam_mat: StandardMaterial3D = _glow_mat(SEE_TEAL, 1.6)
	var beam: MeshInstance3D = _box(Vector3(_disc_radius * 0.42, 0.045, 0), Vector3(_disc_radius * 0.82, 0.006, 0.01), beam_mat)
	_scanner.add_child(beam)

	# A moving sample dot that gets classified or mislabelled.
	_sample_mat = _glow_mat(SEE_BLUE, 1.7)
	_sample = _sphere(Vector3(0, 0.05, 0), 0.018, _sample_mat)
	add_child(_sample)
	_spawn_sample()

	# Billboard title.
	add_child(_billboard_label("BLIND SPOT", Vector3(0, 0.30, 0), 30, COOL_WHITE))


func _spawn_sample() -> void:
	_sample_angle = _rng.randf() * TAU
	_sample_t = 0.0
	var half: float = deg_to_rad(blind_angle_deg) * 0.5
	_sample_in_blind = absf(_angle_diff(_sample_angle, 0.0)) < half


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Scan beam sweeps but skips across the blind wedge (snaps past it).
	_scan_phase += delta * 1.1
	var half: float = deg_to_rad(blind_angle_deg) * 0.5
	var sweep: float = fmod(_scan_phase, TAU)
	if absf(_angle_diff(sweep, 0.0)) < half:
		sweep = half * (1.0 if _angle_diff(sweep, 0.0) >= 0.0 else -1.0)
	if _scanner != null:
		_scanner.rotation.y = -sweep

	# Sample travels from core outward to its landing cell.
	_timer += delta
	_sample_t = minf(_sample_t + delta * 1.4, 1.0)
	var r: float = _disc_radius * 0.82 * _sample_t
	if _sample != null:
		_sample.position = Vector3(cos(_sample_angle) * r, 0.05, sin(_sample_angle) * r)

	# On arrival: correct classification (cool) or mislabel flash (warm-red).
	if _sample_mat != null:
		if _sample_t >= 1.0 and _sample_in_blind:
			var pulse: float = 0.5 + 0.5 * sin(_timer * 14.0)
			var c: Color = MISLABEL.lerp(BLIND_DARK, pulse * 0.4)
			_sample_mat.albedo_color = c
			_sample_mat.emission = c
			_sample_mat.emission_energy_multiplier = (1.5 + pulse * 1.8) if emissive else 0.0
		else:
			_sample_mat.albedo_color = SEE_TEAL
			_sample_mat.emission = SEE_TEAL
			_sample_mat.emission_energy_multiplier = 1.7 if emissive else 0.0

	if _timer >= sample_rate:
		_timer = 0.0
		_spawn_sample()

	# Gentle idle bob for the whole toy (held object liveliness).
	position.y = sin(Time.get_ticks_msec() * 0.0012) * 0.004


func _angle_diff(a: float, b: float) -> float:
	var d: float = fmod(a - b + PI, TAU)
	if d < 0.0:
		d += TAU
	return d - PI
