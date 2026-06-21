extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MicrostateCounter

## @identity
## name: Microstate Counter
## truth: entropy counts the ways — S = k log W; one macrostate, astronomically many microstates.
##
## E as POSSIBILITY SPACE (QFE = F − λE(S) + φΔE(S,t)). A sealed glass box of gas holds
## ONE fixed macrostate ("UNIFORM  T=300K") while its ~40 particles ceaselessly SHUFFLE
## into ever-new microstates. A readout climbs/holds a huge W and S = k log W — making the
## Boltzmann count legible: the macrostate never changes, yet the arrangements behind it
## are uncountably many. Entropy is not disorder; it is the size of the ways-to-be ledger.

@export var particle_count: int = 40
@export var box_size: Vector3 = Vector3(0.62, 0.62, 0.62)
@export var shuffle_speed: float = 1.4
@export var macrostate_label: String = "UNIFORM  T=300K"
@export var glow_color: Color = Color(0.45, 0.85, 1.0)
@export var particle_color: Color = Color(0.7, 0.95, 1.0)
@export var frame_color: Color = Color(0.55, 0.7, 0.95)

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _positions: PackedVector3Array = PackedVector3Array()
var _targets: PackedVector3Array = PackedVector3Array()
var _title: Label3D
var _readout: Label3D
var _t: float = 0.0
var _reshuffle_at: float = 0.0
var _log10_w: float = 0.0  # log10 of the number of microstates


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
	# --- floor base / instrument plinth (y ~ 0) ---
	var base_mat: StandardMaterial3D = _steel_mat(Color(0.16, 0.2, 0.3))
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.42, 0.08, base_mat))
	add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.36, 0.06, _matte_mat(Color(0.2, 0.26, 0.4), 0.6, 0.3)))

	# --- support pedestal up to the sealed box ---
	var post_mat: StandardMaterial3D = _steel_mat(frame_color * 0.7)
	add_child(_cylinder(Vector3(0.0, 0.32, 0.0), 0.05, 0.34, post_mat))

	# --- the sealed glass chamber (the macrostate container), centered ~0.72 ---
	var box_center: Vector3 = Vector3(0.0, 0.72, 0.0)
	var glass: StandardMaterial3D = _glass_mat(glow_color, 0.12)
	add_child(_box(box_center, box_size, glass))

	# glowing edge frame so the sealed boundary reads clearly
	_add_box_frame(box_center, box_size, 0.012, _glow_mat(frame_color, 2.0))

	# a thin emissive floor inside the chamber (the "gas resting plane")
	add_child(_box(box_center + Vector3(0.0, -box_size.y * 0.5 + 0.01, 0.0),
		Vector3(box_size.x * 0.92, 0.012, box_size.z * 0.92),
		_glow_mat(glow_color * 0.6, 1.0)))

	# --- the gas: ONE MultiMesh holding all microstate particles ---
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = particle_count
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.018
	sph.height = 0.036
	sph.radial_segments = 7
	sph.rings = 4
	_mm.mesh = sph
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "GasParticles"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_mat(particle_color, 2.4)
	_mm_inst.position = box_center
	add_child(_mm_inst)

	_positions.resize(particle_count)
	_targets.resize(particle_count)
	var i: int = 0
	while i < particle_count:
		var p: Vector3 = _random_in_box()
		_positions[i] = p
		_targets[i] = _random_in_box()
		_mm.set_instance_transform(i, Transform3D(Basis(), p))
		_mm.set_instance_color(i, particle_color)
		i += 1

	# --- titles / readouts (billboard) ---
	_title = _billboard_label("MICROSTATE COUNTER", Vector3(0.0, 1.5, 0.0), 28, glow_color)
	add_child(_title)

	# macrostate plate: the ONE thing that never changes
	add_child(_billboard_label("MACROSTATE", Vector3(0.0, 1.32, 0.0), 17, Color(0.8, 0.9, 1.0)))
	add_child(_billboard_label(macrostate_label, Vector3(0.0, 1.2, 0.0), 22, Color(1.0, 1.0, 1.0)))

	# the climbing ledger (W and S)
	_readout = _billboard_label("", Vector3(0.0, 1.04, 0.0), 18, glow_color)
	add_child(_readout)
	_refresh_count()
	_update_readout()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# Continuously interpolate each particle toward its current target microstate,
	# then re-roll a new target — the macrostate is fixed, the microstate never settles.
	var reached: bool = true
	var i: int = 0
	while i < particle_count:
		var cur: Vector3 = _positions[i]
		var tgt: Vector3 = _targets[i]
		var nxt: Vector3 = cur.lerp(tgt, clampf(delta * shuffle_speed * 2.2, 0.0, 1.0))
		_positions[i] = nxt
		if nxt.distance_to(tgt) > 0.02:
			reached = false
		# subtle thermal jitter so the gas always shimmers
		var jit: Vector3 = Vector3(
			sin(_t * 3.1 + float(i)) * 0.004,
			cos(_t * 2.7 + float(i) * 1.7) * 0.004,
			sin(_t * 2.3 + float(i) * 0.9) * 0.004)
		_mm.set_instance_transform(i, Transform3D(Basis(), nxt + jit))
		i += 1

	# whole gas drifts to a brand-new microstate arrangement on a cadence
	_reshuffle_at -= delta
	if reached or _reshuffle_at <= 0.0:
		_reshuffle_at = 0.7 / maxf(shuffle_speed, 0.1)
		var j: int = 0
		while j < particle_count:
			_targets[j] = _random_in_box()
			j += 1
		_refresh_count()

	_update_readout()

	# gentle instrument breathing on the title
	if _title != null:
		var pulse: float = 0.5 + 0.5 * sin(_t * 1.6)
		_title.modulate = glow_color.lerp(Color(1.0, 1.0, 1.0), 0.25 * pulse)


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

func _random_in_box() -> Vector3:
	var hx: float = box_size.x * 0.42
	var hy: float = box_size.y * 0.42
	var hz: float = box_size.z * 0.42
	return Vector3(
		_rng.randf_range(-hx, hx),
		_rng.randf_range(-hy, hy),
		_rng.randf_range(-hz, hz))


func _refresh_count() -> void:
	# W ~ phase-cells ^ particles. Each fresh draw nudges the exponent so S breathes
	# slightly while staying astronomically large — the ledger holds near a vast value.
	var cells: float = 24.0 + _rng.randf_range(-1.5, 1.5)
	_log10_w = float(particle_count) * (log(cells) / log(10.0))


func _update_readout() -> void:
	if _readout == null:
		return
	# S = k log W. Display in J/K with Boltzmann k, and W as a 10^N magnitude.
	var k: float = 1.380649e-23
	var ln_w: float = _log10_w * log(10.0)
	var s: float = k * ln_w
	var w_text: String = "W ~ 10^%d microstates" % int(round(_log10_w))
	var s_text: String = "S = k log W = %.2e J/K" % s
	_readout.text = w_text + "\n" + s_text + "\n(one macrostate, all of these)"


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
