extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BecomingBench

## @identity
## name: "Matter that finds its shape"
## tier: medium
## lineage: A bench where a field of particles settles from disorder into an organized body. They
##   start as a roiling cloud above the tray, then fall into the silhouette of a creature — a head,
##   a spine, two limbs — hold it, then scatter and re-form. Entropy, on its way to morphology.
## truth: "ENTROPY BECOMING MORPHOLOGY — A CLOUD OF NOISE SETTLES INTO A LIVING SHAPE"
## applications: morphogenesis, self-assembly, simulated annealing, reaction-diffusion patterning —
##   the descent from high-entropy disorder to low-entropy organized form.

const N: int = 260

@export var bench_w: float = 1.3
@export var form_col: Color = Color(0.60, 0.92, 0.75)
@export var noise_col: Color = Color(0.55, 0.58, 0.92)
@export var bench_col: Color = Color(0.16, 0.17, 0.20)
@export var tray_col: Color = Color(0.10, 0.30, 0.28)
@export var label_col: Color = Color(0.92, 0.97, 0.95)
@export var cycle_rate: float = 0.12

var _t: float = 0.0
var _mm: MultiMesh = null
var _mi: MultiMeshInstance3D = null
var _targets: Array = []     # creature-silhouette positions
var _noise: Array = []       # scattered cloud positions
var _origin := Vector3(0.0, 1.1, 0.0)
var _top: float = 0.86


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("bench_w"):
		bench_w = clampf(float(config["bench_w"]), 0.9, 1.8)
	if config.has("form_col"):
		form_col = _parse_color(config["form_col"], form_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mm = null
	_mi = null
	_targets.clear()
	_noise.clear()
	_build()


func _build() -> void:
	# Bench + tray.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(bench_w + 0.2, 0.84, 0.6), _matte_mat(bench_col, 0.85)))
	add_child(_box(Vector3(0.0, _top, 0.0), Vector3(bench_w * 0.85, 0.04, 0.45), _glow_mat(tray_col, 0.25)))
	_origin = Vector3(0.0, _top + 0.45, 0.0)

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
	_mi.material_override = _glow_mat(form_col, 0.7)
	add_child(_mi)

	# Build the ORDERED target: a small creature silhouette facing +Z.
	_build_creature_targets()
	# Scatter the NOISE positions in a cloud over the tray.
	for i in range(N):
		_noise.append(_origin + Vector3(
			_rng.randf_range(-bench_w * 0.4, bench_w * 0.4),
			_rng.randf_range(-0.05, 0.45),
			_rng.randf_range(-0.2, 0.2),
		))
	_refresh(0.0)

	add_child(_billboard_label("ENTROPY BECOMING MORPHOLOGY", Vector3(0.0, 1.6, 0.0), 17, label_col))


func _build_creature_targets() -> void:
	# Distribute N particles across body parts so the cloud reads as a creature.
	var parts := [
		{ "c": Vector3(0.0, 0.18, 0.0), "r": 0.22, "w": 90 },     # body
		{ "c": Vector3(0.0, 0.42, 0.06), "r": 0.13, "w": 55 },    # head
		{ "c": Vector3(-0.26, 0.05, 0.0), "r": 0.10, "w": 35 },   # left limb
		{ "c": Vector3(0.26, 0.05, 0.0), "r": 0.10, "w": 35 },    # right limb
		{ "c": Vector3(0.0, 0.55, 0.10), "r": 0.05, "w": 18 },    # crest
		{ "c": Vector3(0.0, -0.05, -0.10), "r": 0.08, "w": 27 },  # tail nub
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
			var rr: float = pow(_rng.randf(), 0.5) * r
			_targets.append(_origin + c + dir * rr)
			idx += 1
	# Pad any remainder onto the body centre.
	while _targets.size() < N:
		_targets.append(_origin + Vector3(0.0, 0.18, 0.0) + Vector3(
			_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2)))


func _refresh(order: float) -> void:
	if _mm == null:
		return
	var stud: float = 0.016
	for i in range(N):
		var noise: Vector3 = _noise[i]
		var target: Vector3 = _targets[i]
		var jit := Vector3(
			sin(_t * 1.5 + float(i) * 0.9),
			cos(_t * 1.2 + float(i) * 0.6),
			sin(_t * 1.8 + float(i) * 1.3),
		) * 0.03 * (1.0 - order)
		var p: Vector3 = noise.lerp(target, order) + jit
		_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(stud, stud, stud)), p))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Settle 0 -> 1 (disorder -> creature), hold, then scatter back.
	var raw: float = sin(_t * TAU * cycle_rate) * 0.5 + 0.5
	var order: float = smoothstep(0.15, 0.85, raw)
	_refresh(order)
	if _mi != null:
		_mi.material_override = _glow_mat(noise_col.lerp(form_col, order), 0.7)
