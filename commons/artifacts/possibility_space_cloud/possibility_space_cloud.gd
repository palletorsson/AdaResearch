extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PossibilitySpaceCloud

## @identity
## name: Possibility Space Cloud
## truth: entropy is the size of the space of what could be.
##
## E as POSSIBILITY SPACE (QFE = F − λE(S) + φΔE(S,t)). A phase box holds a cloud of
## state-points (one MultiMesh). The cloud BREATHES between a tiny tight cluster — LOW
## ENTROPY, few accessible states, ordered — and a vast filled volume — HIGH ENTROPY,
## many accessible states. The "ACCESSIBLE STATES" readout scales with the cloud's
## occupied volume. Entropy here is not motion or noise; it is the measure of the box
## of everything the system could presently be.

@export var point_count: int = 220
@export var phase_box: Vector3 = Vector3(0.7, 0.7, 0.7)
@export var breath_period: float = 7.0
@export var min_radius: float = 0.05  # tight ordered cluster
@export var max_radius: float = 0.45  # vast filled cloud
@export var low_color: Color = Color(0.4, 0.55, 1.0)   # ordered / cold
@export var high_color: Color = Color(0.55, 0.95, 1.0) # spread / bright cyan
@export var frame_color: Color = Color(0.6, 0.5, 0.95) # purple instrument frame

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _dirs: PackedVector3Array = PackedVector3Array()   # unit direction per point
var _radii: PackedFloat32Array = PackedFloat32Array()  # max fractional radius per point
var _phases: PackedFloat32Array = PackedFloat32Array()
var _title: Label3D
var _readout: Label3D
var _t: float = 0.0


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
	# --- floor base (y ~ 0) ---
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.4, 0.08, _steel_mat(Color(0.16, 0.18, 0.28))))
	add_child(_cylinder(Vector3(0.0, 0.32, 0.0), 0.045, 0.34, _steel_mat(frame_color * 0.7)))

	# --- phase box (the accessible-state container) centered ~0.72 ---
	var box_center: Vector3 = Vector3(0.0, 0.72, 0.0)
	add_child(_box(box_center, phase_box, _glass_mat(frame_color, 0.07)))
	_add_box_frame(box_center, phase_box, 0.011, _glow_mat(frame_color, 1.8))

	# axis ticks on the floor of the phase box to read it as a state-space
	var tick_mat: StandardMaterial3D = _glow_mat(low_color * 0.8, 0.8)
	add_child(_box(box_center + Vector3(0.0, -phase_box.y * 0.5 + 0.006, 0.0),
		Vector3(phase_box.x * 0.9, 0.008, 0.008), tick_mat))
	add_child(_box(box_center + Vector3(0.0, -phase_box.y * 0.5 + 0.006, 0.0),
		Vector3(0.008, 0.008, phase_box.z * 0.9), tick_mat))

	# --- the state-point cloud: ONE MultiMesh ---
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = point_count
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.011
	sph.height = 0.022
	sph.radial_segments = 6
	sph.rings = 3
	_mm.mesh = sph
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "StateCloud"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_mat(high_color, 2.2)
	_mm_inst.position = box_center
	add_child(_mm_inst)

	_dirs.resize(point_count)
	_radii.resize(point_count)
	_phases.resize(point_count)
	var i: int = 0
	while i < point_count:
		# random direction on a sphere; sqrt-biased radius for volume-uniform fill
		var d: Vector3 = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0))
		if d.length() < 0.001:
			d = Vector3.UP
		_dirs[i] = d.normalized()
		_radii[i] = sqrt(_rng.randf())  # 0..1, denser fill at larger radii
		_phases[i] = _rng.randf() * TAU
		_mm.set_instance_transform(i, Transform3D(Basis(), _dirs[i] * min_radius))
		_mm.set_instance_color(i, low_color)
		i += 1

	# --- titles / readout ---
	_title = _billboard_label("POSSIBILITY SPACE", Vector3(0.0, 1.5, 0.0), 28, high_color)
	add_child(_title)
	_readout = _billboard_label("", Vector3(0.0, 1.16, 0.0), 19, high_color)
	add_child(_readout)
	_update_readout(0.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# breathe: 0 = tight ordered cluster, 1 = vast filled cloud
	var breath: float = 0.5 - 0.5 * cos(_t * TAU / maxf(breath_period, 0.5))
	var radius_now: float = lerpf(min_radius, max_radius, breath)
	var col_now: Color = low_color.lerp(high_color, breath)

	var i: int = 0
	while i < point_count:
		var wobble: float = 1.0 + 0.06 * sin(_t * 1.7 + _phases[i])
		var r: float = radius_now * _radii[i] * wobble
		# keep within the box half-extent
		r = minf(r, phase_box.x * 0.46)
		var pos: Vector3 = _dirs[i] * r
		_mm.set_instance_transform(i, Transform3D(Basis(), pos))
		# brighter as it spreads
		_mm.set_instance_color(i, col_now.lerp(Color(1.0, 1.0, 1.0), 0.15 * breath))
		i += 1

	_update_readout(breath)

	if _title != null:
		_title.modulate = high_color.lerp(Color(1.0, 1.0, 1.0), 0.2 * breath)


func _update_readout(breath: float) -> void:
	if _readout == null:
		return
	# Accessible states scale with occupied VOLUME (~ radius^3). Express as a magnitude
	# that sweeps from "few" (ordered) to a huge number (spread).
	var radius_now: float = lerpf(min_radius, max_radius, breath)
	var vol_frac: float = pow(radius_now / max_radius, 3.0)  # 0..1 of the full box
	var states_exp: float = lerpf(1.0, 18.0, vol_frac)       # 10^1 .. 10^18
	var regime: String = "LOW ENTROPY — few accessible states (ordered)"
	if breath > 0.66:
		regime = "HIGH ENTROPY — many accessible states (spread)"
	elif breath > 0.33:
		regime = "RISING ENTROPY — the box of what could be widens"
	_readout.text = "ACCESSIBLE STATES ~ 10^%d\n%s\nS = log(states)" % [int(round(states_exp)), regime]


func _add_box_frame(center: Vector3, size: Vector3, r: float, mat: Material) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var corners: Array = [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz),
		Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),
		Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz),
		Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	for e in edges:
		var a: Vector3 = center + corners[e[0]]
		var b: Vector3 = center + corners[e[1]]
		add_child(_cylinder_between(a, b, r, mat))
