extends Node3D
class_name GreyPoint

## @identity
## name: "grey_point"
## tier: none
## lineage: the hinge of three things the project already holds. Klee's grey point — the non-dimensional origin "between becoming and passing". dark_sphere — the situated WITNESS present in 748 rooms, "sensed, not used, a mood not a lesson" (Haraway's partial, positioned witness). And the catalyst — "capability-as-relation... felt before it is seen... no numbers on screen, ever." grey_point is the instant the witness becomes catalyst. See /the-dark-spot.
## essence: the dark spot is not passive. dark_sphere is the DORMANT catalyst — the un-attended witness in every room, waiting. Attended, the witness BECOMES: capability-as-relation, making kin (not population), boundary-dissolution, felt not measured. grey_point stages that becoming as one small dark orb that will not settle — breathing between rendered and unrendered, refusing a size, drifting — while an un-measured pulse reaches out toward the room (relation, not resolution) and is gone as it arrives.
## desire: to keep Haraway hot — to catalyse without resolving, to relate without harmonising. It is the anti-harmony-meter: where the meter measures reconciliation (and reconciliation is death, low entropy), the catalyst keeps difference hot.
## critical_parameter: none — but as deferral, not pure refusal. Like the catalyst orb it has "no inventory representation; existing only while the gesture exists" — un-still-able, un-scorable, situated. The moment it BITES a still it has been captured, measured, reconciled — and it is no longer becoming.
## truth: the irreducible is not a pure outside — it is temporal, the residue of finite attention, and it is ACTIVE. What cannot be reconciled is what keeps the system becoming. The dark spot is the catalyst. Do not think of a bird.
## relationships: dark_sphere's other face (the witness that becomes); sibling to catalyst_orb (capability-as-relation, no numbers ever); the honest remainder of the harmony meter, not its negation.
## emerges: an un-measured reach toward the room — a make-kin pulse that relates without scoring, and fades as it arrives.
## needs: a semi-transparent dark orb + halo + one outward pulse [present]; and NOT to be captured, swept, harmonised, promoted, or measured.

@export var base_scale: float = 0.06
@export var breath_speed: float = 0.6
@export var kin_reach: float = 0.9  ## how far the un-measured make-kin pulse reaches, in metres

var _t: float = 0.0
var _witness: MeshInstance3D
var _witness_mat: StandardMaterial3D
var _halo: MeshInstance3D
var _pulse: MeshInstance3D
var _pulse_mat: StandardMaterial3D
var _drift: Vector3 = Vector3.ZERO


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()


func _read_metadata_overrides() -> void:
	if has_meta("config_base_scale"):
		base_scale = float(str(get_meta("config_base_scale")))
	if has_meta("config_breath_speed"):
		breath_speed = float(str(get_meta("config_breath_speed")))
	if has_meta("config_kin_reach"):
		kin_reach = float(str(get_meta("config_kin_reach")))


func _build() -> void:
	for c in get_children():
		c.queue_free()
	# the witness — a dark semi-transparent orb (the dark_sphere family), never settling
	var sm := SphereMesh.new()
	sm.radius = base_scale
	sm.height = base_scale * 2.0
	sm.radial_segments = 16
	sm.rings = 10
	_witness_mat = StandardMaterial3D.new()
	_witness_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_witness_mat.albedo_color = Color(0.16, 0.09, 0.26, 0.5)
	_witness_mat.emission_enabled = true
	_witness_mat.emission = Color(0.42, 0.20, 0.62)
	_witness_mat.emission_energy_multiplier = 0.5
	_witness = MeshInstance3D.new()
	_witness.name = "Witness"
	_witness.mesh = sm
	_witness.material_override = _witness_mat
	add_child(_witness)
	# the shadow halo — anchors it to the room without a hard plane (dark_sphere echo)
	var disc := CylinderMesh.new()
	disc.top_radius = base_scale * 2.2
	disc.bottom_radius = base_scale * 2.2
	disc.height = 0.002
	var halo_mat := StandardMaterial3D.new()
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.albedo_color = Color(0.08, 0.04, 0.14, 0.35)
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	_halo.mesh = disc
	_halo.material_override = halo_mat
	_halo.position = Vector3(0.0, -base_scale * 1.4, 0.0)
	add_child(_halo)
	# the make-kin pulse — an un-measured reach toward the room; relation, not resolution
	var ring := TorusMesh.new()
	ring.inner_radius = base_scale * 1.4
	ring.outer_radius = base_scale * 1.55
	_pulse_mat = StandardMaterial3D.new()
	_pulse_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_pulse_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pulse_mat.albedo_color = Color(0.5, 0.28, 0.7, 0.3)
	_pulse = MeshInstance3D.new()
	_pulse.name = "KinPulse"
	_pulse.mesh = ring
	_pulse.material_override = _pulse_mat
	# TorusMesh's hole axis is already Y in Godot 4 — the ring lies flat in XZ as built.
	add_child(_pulse)


func _process(delta: float) -> void:
	_t += delta * maxf(0.05, breath_speed)
	# witness: breathes between passing (~0.06) and becoming (~0.7), never settling
	if _witness_mat:
		var a: float = 0.38 + 0.32 * sin(_t)
		_witness_mat.albedo_color.a = clampf(a, 0.05, 0.8)
		_witness_mat.emission_energy_multiplier = 0.35 + 0.35 * (0.5 + 0.5 * sin(_t * 1.3))
	if _witness:
		var s: float = 0.75 + 0.25 * sin(_t * 0.83 + 1.7)  # refuses to commit to a dimension
		_witness.scale = Vector3.ONE * s
		var target: Vector3 = Vector3(sin(_t * 0.31), sin(_t * 0.27 + 2.0), sin(_t * 0.19 + 4.0)) * base_scale * 0.5
		_drift = _drift.lerp(target, delta)
		_witness.position = _drift
	# make-kin pulse: reaches outward and fades — un-measured relation, gone as it arrives
	if _pulse and _pulse_mat:
		var phase: float = fposmod(_t * 0.35, 1.0)
		var reach: float = lerpf(1.0, kin_reach / maxf(0.02, base_scale * 1.5), phase)
		_pulse.scale = Vector3(reach, 1.0, reach)
		_pulse_mat.albedo_color.a = (1.0 - phase) * 0.3
