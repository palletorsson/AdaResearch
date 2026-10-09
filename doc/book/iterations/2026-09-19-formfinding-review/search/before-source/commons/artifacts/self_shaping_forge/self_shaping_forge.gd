extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SelfShapingForge

## @identity
## name: "Matter that finds its shape"
## tier: applied
## lineage: A forge where matter finds its own shape. Raw cloud-stuff is fed in at the top; a soft
##   body descends a Q-gradient — not toward stillness but toward its liveliest, most coherent form,
##   the configuration of maximum Q — and emerges below. A readout tracks Q climbing as the form
##   settles. The project's whole thesis, made into a machine.
## truth: "GRADIENT DESCENT TOWARD MAX Q — STRUCTURE THAT PERSISTS BY MOVING, FOUND NOT IMPOSED"
## applications: simulated annealing, free-energy minimization, self-assembly reactors, morphogenetic
##   engines — apparatus that lets matter compute its own form instead of being stamped.

const N: int = 180

@export var form_col: Color = Color(0.60, 0.92, 0.75)
@export var raw_col: Color = Color(0.60, 0.62, 0.92)
@export var body_col: Color = Color(0.15, 0.16, 0.20)
@export var frame_col: Color = Color(0.45, 0.50, 0.58)
@export var readout_col: Color = Color(0.55, 0.98, 0.70)
@export var label_col: Color = Color(0.92, 0.97, 0.95)
@export var cycle_rate: float = 0.13

var _t: float = 0.0
var _q: float = 0.0
var _mm: MultiMesh = null
var _mi: MultiMeshInstance3D = null
var _raw: Array = []          # raw cloud positions (top, disorder)
var _targets: Array = []      # max-Q form positions (a coherent body)
var _readout: Label3D = null
var _q_bar: MeshInstance3D = null
var _chamber := Vector3(0.0, 0.55, 0.0)
var _q_max_y: float = 1.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cycle_rate"):
		cycle_rate = clampf(float(config["cycle_rate"]), 0.05, 0.4)
	if config.has("form_col"):
		form_col = _parse_color(config["form_col"], form_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mm = null
	_mi = null
	_raw.clear()
	_targets.clear()
	_readout = null
	_q_bar = null
	_q = 0.0
	_build()


func _build() -> void:
	# Device base — a ~1m forge.
	add_child(_box(Vector3(0.0, 0.06, 0.0), Vector3(1.0, 0.12, 0.5), _matte_mat(body_col, 0.8)))

	# Two upright frame posts + a glass chamber between them.
	add_child(_cylinder(Vector3(-0.34, 0.55, 0.0), 0.03, 1.0, _steel_mat(frame_col)))
	add_child(_cylinder(Vector3(0.34, 0.55, 0.0), 0.03, 1.0, _steel_mat(frame_col)))
	add_child(_box(Vector3(0.0, 1.06, 0.0), Vector3(0.74, 0.04, 0.5), _steel_mat(frame_col)))
	add_child(_box(_chamber, Vector3(0.6, 0.85, 0.45), _glass_mat(Color(0.5, 0.7, 0.85), 0.1)))

	# Feed hopper at top (raw material in).
	add_child(_cylinder(Vector3(0.0, 1.02, 0.0), 0.12, 0.08, _steel_mat(Color(0.4, 0.42, 0.48))))

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 3
	_mm.mesh = sm
	_mm.instance_count = N
	_mi = MultiMeshInstance3D.new()
	_mi.multimesh = _mm
	_mi.material_override = _glow_mat(raw_col, 0.7)
	add_child(_mi)

	# RAW: disordered cloud at the top of the chamber.
	for i in range(N):
		_raw.append(_chamber + Vector3(
			_rng.randf_range(-0.22, 0.22),
			_rng.randf_range(0.18, 0.34),
			_rng.randf_range(-0.16, 0.16),
		))
	# MAX-Q FORM: a coherent body lower in the chamber — the liveliest configuration.
	_build_form_targets()
	_refresh(0.0)

	# Q-meter bar on the right post.
	add_child(_box(Vector3(0.42, 0.55, 0.0), Vector3(0.03, 0.7, 0.03), _matte_mat(Color(0.1, 0.1, 0.12), 0.5)))
	_q_bar = _box(Vector3(0.42, 0.25, 0.0), Vector3(0.05, 0.02, 0.05), _glow_mat(readout_col, 0.9))
	add_child(_q_bar)
	_q_max_y = 0.55

	# Readout panel.
	add_child(_box(Vector3(0.0, 1.18, 0.0), Vector3(0.55, 0.18, 0.02), _matte_mat(Color(0.08, 0.09, 0.12), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.0, 1.18, 0.02), 14, readout_col)
	add_child(_readout)

	add_child(_billboard_label("SELF-SHAPING FORGE — DESCENT TOWARD MAX Q", Vector3(0.0, 1.42, 0.0), 18, label_col))


func _build_form_targets() -> void:
	# A coherent organized body lower in the chamber (head + torso + two limbs).
	var center := _chamber + Vector3(0.0, -0.12, 0.0)
	var parts := [
		{ "c": Vector3(0.0, 0.0, 0.0), "r": 0.16, "w": 80 },
		{ "c": Vector3(0.0, 0.20, 0.04), "r": 0.10, "w": 45 },
		{ "c": Vector3(-0.18, -0.06, 0.0), "r": 0.07, "w": 28 },
		{ "c": Vector3(0.18, -0.06, 0.0), "r": 0.07, "w": 27 },
	]
	var idx: int = 0
	for part in parts:
		var c: Vector3 = part["c"]
		var r: float = part["r"]
		var w: int = part["w"]
		for j in range(w):
			if idx >= N:
				break
			var dir := Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
			).normalized()
			_targets.append(center + c + dir * pow(_rng.randf(), 0.5) * r)
			idx += 1
	while _targets.size() < N:
		_targets.append(center + Vector3(_rng.randf_range(-0.14, 0.14), _rng.randf_range(-0.14, 0.14), _rng.randf_range(-0.14, 0.14)))


func _refresh(q: float) -> void:
	if _mm == null:
		return
	var stud: float = 0.014
	for i in range(N):
		var raw: Vector3 = _raw[i]
		var target: Vector3 = _targets[i]
		# Annealing jitter: large when Q is low, freezes as Q climbs.
		var jit := Vector3(
			sin(_t * 2.0 + float(i) * 0.9),
			cos(_t * 1.6 + float(i) * 0.6),
			sin(_t * 2.3 + float(i) * 1.4),
		) * 0.035 * (1.0 - q)
		var p: Vector3 = raw.lerp(target, q) + jit
		_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(stud, stud, stud)), p))


func _readout_text() -> String:
	var phase: String = "settling" if _q < 0.92 else "MAX Q"
	return "SELF-SHAPING FORGE\nstate: %s\nQ: %d%%" % [phase, int(round(_q * 100.0))]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Q climbs toward 1 (max-Q form), holds, resets — a forge cycle.
	var raw_q: float = sin(_t * TAU * cycle_rate) * 0.5 + 0.5
	_q = smoothstep(0.1, 0.9, raw_q)
	_refresh(_q)
	# Recolor raw-blue -> form-green as the body coheres.
	if _mi != null:
		_mi.material_override = _glow_mat(raw_col.lerp(form_col, _q), 0.7)
	# Q-meter bar grows upward.
	if _q_bar != null:
		var hgt: float = 0.04 + _q * 0.62
		_q_bar.scale = Vector3(1.0, hgt / 0.02, 1.0)
		_q_bar.position.y = 0.2 + hgt * 0.5
	if _readout != null:
		_readout.text = _readout_text()
