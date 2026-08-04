# @identity
# essence: E(S) = f(phi, delta_e, constraint) -- morphing dodecahedron with 3 Q-FEP parameter beams
# desire: a dodecahedron whose shape responds to three Q-FEP parameters, beams probing the landscape
# critical_parameter: _phi / _delta_e / _constraint -- three Q-FEP dimensions deform body and aim beams
# triggers: parameter oscillation drives deformation; beams sweep based on Q-FEP state; proximity attacks
# emerges: Q-FEP parameter space made physical -- the creature IS the theory, body IS the equation
# needs: HazardCreatureBase [has]; dodecahedron mesh [has]; 3 parameter beams [has]; Q-FEP mapping [has]; VR interaction [missing]
# relationships: embodies qfeplaboratory sequence; theoretical capstone creature of the bestiary
# truth: the Q-FEP calibrator does not demonstrate the theory -- it IS the theory, parameters made flesh.

extends HazardCreatureBase
class_name QFEPCalibrator
## QFEP Laboratory sequence creature — morphing dodecahedron with 3 parameter beams.
## Parameters oscillate sinusoidally and dynamically change the creature's behavior:
##   phi (gold beam): controls rotation speed — high phi = fast spin, hard to hit
##   delta_e (cyan beam): controls damage — high delta_e = more damage but slower
##   constraint (magenta beam): controls detection — larger detection, smaller attack range
## Body pulses with emission based on combined parameter energy.

@export_group("Parameters")
@export var phi_frequency: float = 0.7
@export var delta_e_frequency: float = 0.5
@export var constraint_frequency: float = 0.3
@export var phi_amplitude: float = 1.0
@export var delta_e_amplitude: float = 1.0
@export var constraint_amplitude: float = 1.0

@export_group("Beam Visual")
@export var beam_length: float = 0.6
@export var beam_radius: float = 0.02

@export_group("Attack")
@export var base_damage: float = 10.0
@export var base_detection: float = 7.0
@export var base_attack_range: float = 1.5


# ── DNA (stage 2) ────────────────────────────────────────────────────────
# --- DNA (stage 2, promoted 2026-08-03) ---
# Everything this file already exported was a RATE or a LENGTH: phi_frequency,
# beam_radius, base_damage. Not one of them is legible in a still photograph, which
# is why the sweep refused this artifact for having no turnable knobs. What IS in the
# frame is the beams — three of them, 0.6 m long on a 0.9 m creature — and the placard
# under them. Both are claims about the theory, not about the model.
@export_group("DNA")

## AXIS — WHICH PARAMETERS DOES THE INSTRUMENT ADMIT IT HAS? The essence line of this
## file is `E(S) = f(phi, delta_e, constraint)`, and the three beams are that equation
## standing up in the world: one probe per term, gold, cyan, magenta. Three was never a
## fact about Q-FEP. It was one instrument's account of how many dimensions the landscape
## has, hard-coded three times over in _build_mesh. An instrument that carries a single
## beam is not a smaller calibrator; it is a DIFFERENT THEORY, one that says the energy
## of a situation is a function of exactly one thing.
##
##   all         gold, cyan and magenta. The shipped calibrator, byte for byte —
##               E(S) = f(phi, delta_e, constraint), the whole declared parameter space
##   phi         gold alone. Everything is rotation: form, speed, the ability to be hit
##   delta_e     cyan alone. Everything is energy cost — the theory as a damage budget
##   constraint  magenta alone. Everything is what may be detected and what may be reached
##   none        the bare body and its two legs. An instrument that admits no parameters:
##               it still moves, still spins, still hurts you, and shows no account of why
##
## Wholly deterministic — no randf reaches this branch — so five variants are five
## photographs of one creature rather than five different creatures.
@export_enum("all", "phi", "delta_e", "constraint", "none") var admits: String = "all"

## AXIS — what the apparatus commits to about the parameter values it is reading. Taken
## character for character from commons/primitives/line/line.gd and its twin
## commons/primitives/point/xyz_slider_plate.gd, which own this vocabulary: one ordered
## ladder, monotone in evidence, `none < numeral < gradation < lattice`. It fits here
## without bending because the question is identical — what does the apparatus commit to
## about the quantity it is showing you — and this artifact is the one in the corpus that
## has a genuine parameter SPACE to draw at rung 3.
##
##   none       no placard at all. Three beams and no numbers: an instrument that reads
##              itself and tells you nothing
##   numeral    THE SHIPPED calibrator — `phi=0.50  de=0.50  C=0.50` on a billboard.
##              A number, and no scale to put it on
##   gradation  + a 0..1 track per admitted parameter with a marker riding it. The same
##              number, now on a public scale, so a reading has a somewhere-to-be
##   lattice    + the unit cube of the parameter space itself, its three edges from the
##              origin coloured phi / delta_e / constraint, and a marker at this instant's
##              point inside it. What is in frame stops being the reading and becomes the
##              SPACE — the part that is true before the creature has measured anything
##
## Anything unrecognised builds as `numeral`, NOT as `none`: a typo must not silently
## delete the readout from a live room. That rule is line.gd's too.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral"

## Allow-lists for the map-token path. An unrecognised token leaves the value alone.
const ADMITS: PackedStringArray = ["all", "phi", "delta_e", "constraint", "none"]
const READOUTS: PackedStringArray = ["none", "numeral", "gradation", "lattice"]
const AXIS_NAMES: PackedStringArray = ["phi", "delta_e", "constraint"]

const GAUGE_WIDTH: float = 0.28
const GAUGE_BASE_Y: float = 0.84
const GAUGE_STEP_Y: float = 0.05
const LATTICE_SIZE: float = 0.3
const LATTICE_Y: float = 1.0

# Parameters (0..1 oscillating)
var _phi: float = 0.5
var _delta_e: float = 0.5
var _constraint: float = 0.5

# Visual refs
var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _phi_beam: MeshInstance3D = null
var _phi_mat: StandardMaterial3D = null
var _delta_e_beam: MeshInstance3D = null
var _delta_e_mat: StandardMaterial3D = null
var _constraint_beam: MeshInstance3D = null
var _constraint_mat: StandardMaterial3D = null
var _label: Label3D = null
# Readout rungs 2 and 3. Empty under the shipped `numeral`, so the two loops that walk
# them in _process_visual are no-ops for every existing placement.
var _gauge_meshes: Array[MeshInstance3D] = []
var _gauge_markers: Array[MeshInstance3D] = []
var _gauge_params: PackedStringArray = PackedStringArray()
var _lattice_meshes: Array[MeshInstance3D] = []
var _lattice_marker: MeshInstance3D = null
var _lattice_origin: Vector3 = Vector3.ZERO
var _leg_roots: Array[Node3D] = []
var _leg_meshes: Array[MeshInstance3D] = []
var _walk_phase: float = 0.0

# State
var _time: float = 0.0
var _spin_angle: float = 0.0
var _attack_cooldown: float = 0.0

# Colors
const PHI_COLOR: Color = Color(0.95, 0.8, 0.1)       # Gold
const DELTA_E_COLOR: Color = Color(0.1, 0.9, 0.9)     # Cyan
const CONSTRAINT_COLOR: Color = Color(0.9, 0.1, 0.85)  # Magenta
const BODY_COLOR: Color = Color(0.3, 0.25, 0.5)        # Deep purple


## HazardCreatureBase's own default patrol speed, and this creature's. The write below is
## guarded against the first: exports are set on the instance BEFORE add_child (by the DNA
## sweep, and by anything else that configures a scene pre-tree), so an unconditional
## `patrol_speed = 1.5` here silently discards a supplied value. Nothing in the repo
## supplies one today, so the single existing placement takes the branch and gets 1.5
## exactly as before. chase_speed and detection_radius are NOT guarded because
## _apply_parameter_effects overwrites both every frame from _phi / _constraint — to pin
## this creature for a capture, set base_detection, not detection_radius.
const BASE_PATROL_SPEED := 1.8
const OWN_PATROL_SPEED := 1.5


func _on_ready() -> void:
	max_health = 90.0
	_health = max_health
	if is_equal_approx(patrol_speed, BASE_PATROL_SPEED):
		patrol_speed = OWN_PATROL_SPEED
	chase_speed = 2.5
	contact_damage = base_damage
	detection_radius = base_detection


func _create_materials() -> void:
	_body_mat = _make_material(BODY_COLOR, BODY_COLOR * 0.8)

	_phi_mat = _make_material(PHI_COLOR, PHI_COLOR)
	_phi_mat.emission_energy_multiplier = 2.0

	_delta_e_mat = _make_material(DELTA_E_COLOR, DELTA_E_COLOR)
	_delta_e_mat.emission_energy_multiplier = 2.0

	_constraint_mat = _make_material(CONSTRAINT_COLOR, CONSTRAINT_COLOR)
	_constraint_mat.emission_energy_multiplier = 2.0


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.65
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.65

	# Dodecahedron approximated with IcoSphereMesh (low subdivision)
	var ico := SphereMesh.new()
	ico.radius = 0.3
	ico.height = 0.6
	ico.radial_segments = 10
	ico.rings = 5
	_body_mesh = _add_mesh(ico, _body_mat)
	_body_mesh.name = "Body"

	_build_beams()

	# Build 2 legs
	for i in range(2):
		_build_leg(i)

	_build_readout()


## The parameter beams the instrument admits it has. Under the default `all` this is the
## shipped body: the same three blocks, in the same order, with the same numbers.
func _build_beams() -> void:
	if _admits_parameter("phi"):
		_build_phi_beam()
	if _admits_parameter("delta_e"):
		_build_delta_e_beam()
	if _admits_parameter("constraint"):
		_build_constraint_beam()


func _build_phi_beam() -> void:
	# Phi beam (gold) — extends upward-right
	var phi_cyl := CylinderMesh.new()
	phi_cyl.height = beam_length
	phi_cyl.top_radius = beam_radius * 0.5
	phi_cyl.bottom_radius = beam_radius
	_phi_beam = _add_mesh(phi_cyl, _phi_mat, Vector3(0.0, 0.0, 0.0))
	_phi_beam.name = "PhiBeam"
	_phi_beam.rotation.z = -PI / 4.0
	_phi_beam.position = Vector3(0.2, 0.2, 0.0)

	# Phi tip sphere
	var phi_tip := SphereMesh.new()
	phi_tip.radius = 0.04
	phi_tip.height = 0.08
	var phi_tip_mi := MeshInstance3D.new()
	phi_tip_mi.mesh = phi_tip
	phi_tip_mi.set_surface_override_material(0, _phi_mat)
	phi_tip_mi.position = Vector3(0.0, beam_length * 0.5, 0.0)
	_phi_beam.add_child(phi_tip_mi)


func _build_delta_e_beam() -> void:
	# Delta_e beam (cyan) — extends upward-left
	var de_cyl := CylinderMesh.new()
	de_cyl.height = beam_length
	de_cyl.top_radius = beam_radius * 0.5
	de_cyl.bottom_radius = beam_radius
	_delta_e_beam = _add_mesh(de_cyl, _delta_e_mat, Vector3(0.0, 0.0, 0.0))
	_delta_e_beam.name = "DeltaEBeam"
	_delta_e_beam.rotation.z = PI / 4.0
	_delta_e_beam.position = Vector3(-0.2, 0.2, 0.0)

	# Delta_e tip sphere
	var de_tip := SphereMesh.new()
	de_tip.radius = 0.04
	de_tip.height = 0.08
	var de_tip_mi := MeshInstance3D.new()
	de_tip_mi.mesh = de_tip
	de_tip_mi.set_surface_override_material(0, _delta_e_mat)
	de_tip_mi.position = Vector3(0.0, beam_length * 0.5, 0.0)
	_delta_e_beam.add_child(de_tip_mi)


func _build_constraint_beam() -> void:
	# Constraint beam (magenta) — extends backward
	var c_cyl := CylinderMesh.new()
	c_cyl.height = beam_length
	c_cyl.top_radius = beam_radius * 0.5
	c_cyl.bottom_radius = beam_radius
	_constraint_beam = _add_mesh(c_cyl, _constraint_mat, Vector3(0.0, 0.0, 0.0))
	_constraint_beam.name = "ConstraintBeam"
	_constraint_beam.rotation.x = -PI / 4.0
	_constraint_beam.position = Vector3(0.0, 0.15, -0.2)

	# Constraint tip sphere
	var c_tip := SphereMesh.new()
	c_tip.radius = 0.04
	c_tip.height = 0.08
	var c_tip_mi := MeshInstance3D.new()
	c_tip_mi.mesh = c_tip
	c_tip_mi.set_surface_override_material(0, _constraint_mat)
	c_tip_mi.position = Vector3(0.0, beam_length * 0.5, 0.0)
	_constraint_beam.add_child(c_tip_mi)


func _build_leg(index: int) -> void:
	var root := Node3D.new()
	root.name = "Leg_%d" % index
	var x_offset: float = 0.12 if index == 0 else -0.12
	root.position = Vector3(x_offset, -0.35, 0.0)
	_mesh_root.add_child(root)
	_leg_roots.append(root)

	var cyl := CylinderMesh.new()
	cyl.height = 0.3
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.02
	var leg_mat := _make_material(Color(0.2, 0.15, 0.3), BODY_COLOR * 0.3)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, leg_mat)
	mi.position = Vector3(0, -0.15, 0)
	root.add_child(mi)
	_leg_meshes.append(mi)


func _get_param_text() -> String:
	return "phi=%.2f  de=%.2f  C=%.2f" % [_phi, _delta_e, _constraint]


# ── DNA implementation ───────────────────────────────────────────────────
# The admitted parameter set and the readout rung, and nothing else, live below here.


## Does the instrument put this Q-FEP term in the world as a beam?
func _admits_parameter(pname: String) -> bool:
	if admits == "none":
		return false
	if admits == "phi" or admits == "delta_e" or admits == "constraint":
		return admits == pname
	return true  # "all", and anything unrecognised: never silently strip a live creature


## The readout ladder as a rank, so each rung is strictly additive over the one below.
## Anything unrecognised reads as `numeral` — line.gd's rule, and for the same reason:
## a typo must not delete the placard from a room that has one.
func _readout_rank() -> int:
	match readout:
		"none":
			return 0
		"gradation":
			return 2
		"lattice":
			return 3
		_:
			return 1


func _param_color(pname: String) -> Color:
	match pname:
		"phi":
			return PHI_COLOR
		"delta_e":
			return DELTA_E_COLOR
		_:
			return CONSTRAINT_COLOR


func _param_material(pname: String) -> StandardMaterial3D:
	match pname:
		"phi":
			return _phi_mat
		"delta_e":
			return _delta_e_mat
		_:
			return _constraint_mat


func _param_value(pname: String) -> float:
	match pname:
		"phi":
			return _phi
		"delta_e":
			return _delta_e
		_:
			return _constraint


## Rung 1 is the shipped Label3D, unchanged; rungs 2 and 3 add to it and never move it.
func _build_readout() -> void:
	var rank: int = _readout_rank()
	if rank >= 1:
		# Label
		_label = Label3D.new()
		_label.text = _get_param_text()
		_label.font_size = 32
		_label.pixel_size = 0.003
		_label.modulate = Color(0.9, 0.9, 0.9, 0.9)
		_label.position = Vector3(0, 0.7, 0)
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_mesh_root.add_child(_label)
	if rank >= 2:
		_build_gauges()
	if rank >= 3:
		_build_lattice()


## One 0..1 track per ADMITTED parameter — the readout reports what the instrument
## admits, so an instrument down to a single beam gets a single gauge.
func _build_gauges() -> void:
	var row: int = 0
	for i in range(AXIS_NAMES.size()):
		var pname: String = AXIS_NAMES[int(i)]
		if not _admits_parameter(pname):
			continue
		var col: Color = _param_color(pname)
		var y: float = GAUGE_BASE_Y + float(row) * GAUGE_STEP_Y
		row += 1

		var track_mesh := BoxMesh.new()
		track_mesh.size = Vector3(GAUGE_WIDTH, 0.008, 0.006)
		var track_mat: StandardMaterial3D = _make_material(col * 0.3, col * 0.15)
		var track := MeshInstance3D.new()
		track.mesh = track_mesh
		track.set_surface_override_material(0, track_mat)
		track.position = Vector3(0.0, y, 0.0)
		_mesh_root.add_child(track)
		_gauge_meshes.append(track)

		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.022, 0.032, 0.014)
		var marker := MeshInstance3D.new()
		marker.mesh = marker_mesh
		marker.set_surface_override_material(0, _param_material(pname))
		marker.position = Vector3((_param_value(pname) - 0.5) * GAUGE_WIDTH, 0.0, 0.0)
		track.add_child(marker)
		_gauge_markers.append(marker)
		_gauge_params.append(pname)


## The parameter SPACE, drawn: a unit cube whose three edges from the origin corner carry
## the three parameter colours, with a marker at this instant's point inside it. This is
## the only rung that is true before the creature has measured anything.
func _build_lattice() -> void:
	var s: float = LATTICE_SIZE
	_lattice_origin = Vector3(-s * 0.5, LATTICE_Y, -s * 0.5)
	var neutral: StandardMaterial3D = _make_material(Color(0.5, 0.45, 0.65), Color(0.18, 0.16, 0.28))
	for i in range(8):
		var corner: int = int(i)
		for bit in range(3):
			var b: int = int(bit)
			var j: int = corner | (1 << b)
			if j == corner:
				continue
			var mat: StandardMaterial3D = neutral
			if corner == 0:
				var c: Color = _param_color(AXIS_NAMES[b])
				mat = _make_material(c, c)
			_add_lattice_edge(_lattice_origin + _lattice_corner(corner, s),
					_lattice_origin + _lattice_corner(j, s), mat)

	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.024
	marker_mesh.height = 0.048
	var marker_mat: StandardMaterial3D = _make_material(Color(1.0, 1.0, 1.0), Color(0.9, 0.9, 1.0))
	marker_mat.emission_energy_multiplier = 3.0
	_lattice_marker = MeshInstance3D.new()
	_lattice_marker.mesh = marker_mesh
	_lattice_marker.set_surface_override_material(0, marker_mat)
	_lattice_marker.position = _lattice_origin + Vector3(_phi, _delta_e, _constraint) * s
	_mesh_root.add_child(_lattice_marker)
	_lattice_meshes.append(_lattice_marker)


func _lattice_corner(index: int, s: float) -> Vector3:
	return Vector3(float(index & 1), float((index >> 1) & 1), float((index >> 2) & 1)) * s


func _add_lattice_edge(a: Vector3, b: Vector3, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var thin: float = 0.005
	var box := BoxMesh.new()
	box.size = Vector3(maxf(absf(d.x), thin), maxf(absf(d.y), thin), maxf(absf(d.z), thin))
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.set_surface_override_material(0, mat)
	mi.position = (a + b) * 0.5
	_mesh_root.add_child(mi)
	_lattice_meshes.append(mi)


## Re-seat the beams on a new admitted set. Only the beams are touched — the body, the
## legs and the readout are the same nodes throughout.
func _rebuild_beams() -> void:
	for beam in [_phi_beam, _delta_e_beam, _constraint_beam]:
		if is_instance_valid(beam):
			beam.queue_free()
	_phi_beam = null
	_delta_e_beam = null
	_constraint_beam = null
	_build_beams()


func _rebuild_readout() -> void:
	if is_instance_valid(_label):
		_label.queue_free()
	_label = null
	for m in _gauge_meshes:
		if is_instance_valid(m):
			m.queue_free()   # markers are children of their track and go with it
	_gauge_meshes.clear()
	_gauge_markers.clear()
	_gauge_params.clear()
	for m in _lattice_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_lattice_meshes.clear()
	_lattice_marker = null
	_build_readout()


## Reachable configuration. The base forwards health / speed / damage and knew nothing
## about either axis, so a map token could not reach one. Both branches are CHANGE-GUARDED
## and BUILD-GUARDED: a word outside the allow-list, a word the creature already holds, or
## a call that arrives before _ready has built the body tears nothing down. Arriving early
## is fine on its own — the export is assigned and _ready then builds with it.
func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	if config.has("admits"):
		var a: String = str(config["admits"]).strip_edges().to_lower()
		if ADMITS.has(a) and a != admits:
			admits = a
			if _mesh_root != null:
				_rebuild_beams()
				# Rung 2 reports the admitted set, so it follows the beams.
				if _readout_rank() >= 2:
					_rebuild_readout()
	if config.has("readout"):
		var r: String = str(config["readout"]).strip_edges().to_lower()
		if READOUTS.has(r) and r != readout:
			readout = r
			if _mesh_root != null:
				_rebuild_readout()


func _process_visual(delta: float) -> void:
	_time += delta
	_attack_cooldown = max(0.0, _attack_cooldown - delta)

	# Oscillate parameters
	_phi = (sin(_time * phi_frequency * TAU) + 1.0) * 0.5 * phi_amplitude
	_delta_e = (sin(_time * delta_e_frequency * TAU) + 1.0) * 0.5 * delta_e_amplitude
	_constraint = (sin(_time * constraint_frequency * TAU) + 1.0) * 0.5 * constraint_amplitude

	# Apply parameter effects to behavior
	_apply_parameter_effects()

	# Body rotation — influenced by phi
	var spin_speed: float = 1.0 + _phi * 8.0
	_spin_angle += delta * spin_speed
	_body_mesh.rotation.y = _spin_angle
	_body_mesh.rotation.x = sin(_time * 1.5) * 0.15

	# Body emission pulse — combined parameter energy
	var combined_energy: float = (_phi + _delta_e + _constraint) / 3.0
	var pulse_color := BODY_COLOR.lerp(Color.WHITE, combined_energy * 0.4)
	_body_mat.albedo_color = pulse_color
	if _body_mat.emission_enabled:
		_body_mat.emission = pulse_color * 0.8
		_body_mat.emission_energy_multiplier = 1.0 + combined_energy * 3.0

	# Body scale pulsing
	var scale_pulse: float = 1.0 + sin(_time * 3.0) * combined_energy * 0.1
	_body_mesh.scale = Vector3(scale_pulse, scale_pulse, scale_pulse)

	# Update beam visuals — length scales with parameter value
	_update_beam(_phi_beam, _phi_mat, _phi, PHI_COLOR)
	_update_beam(_delta_e_beam, _delta_e_mat, _delta_e, DELTA_E_COLOR)
	_update_beam(_constraint_beam, _constraint_mat, _constraint, CONSTRAINT_COLOR)

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			var phase_offset: float = float(i) * PI
			_leg_roots[i].rotation.x = sin(_walk_phase + phase_offset) * 0.3
			_leg_roots[i].rotation.z = cos(_walk_phase + phase_offset) * 0.1

	# Update label
	if _label:
		_label.text = _get_param_text()

	# Readout rung 2 — markers ride the parameter they report. Empty under `numeral`,
	# so this loop does nothing at all for every existing placement.
	for i in range(_gauge_markers.size()):
		var gi: int = int(i)
		var marker: MeshInstance3D = _gauge_markers[gi]
		if is_instance_valid(marker):
			marker.position.x = (_param_value(_gauge_params[gi]) - 0.5) * GAUGE_WIDTH

	# Readout rung 3 — the point this instant occupies in the parameter space.
	if is_instance_valid(_lattice_marker):
		_lattice_marker.position = _lattice_origin \
				+ Vector3(_phi, _delta_e, _constraint) * LATTICE_SIZE


func _update_beam(beam: MeshInstance3D, mat: StandardMaterial3D, param_val: float, base_color: Color) -> void:
	if not is_instance_valid(beam):
		return

	# Scale beam length with parameter
	var s: float = 0.3 + param_val * 0.7
	beam.scale.y = s

	# Emission intensity
	var brightness: float = 1.0 + param_val * 3.0
	mat.emission_energy_multiplier = brightness

	# Color intensity
	var c: Color = base_color.lerp(Color.WHITE, param_val * 0.3)
	mat.albedo_color = c
	mat.emission = c


func _apply_parameter_effects() -> void:
	# Phi: high = fast spin, harder to hit (already applied via spin_speed)
	# Also affects patrol/chase speed slightly
	var phi_speed_bonus: float = _phi * 1.5
	chase_speed = 2.0 + phi_speed_bonus

	# Delta_e: high = more damage, but slower movement
	contact_damage = base_damage + _delta_e * 20.0
	var de_speed_penalty: float = _delta_e * 1.5
	chase_speed = max(1.0, chase_speed - de_speed_penalty)

	# Constraint: high = larger detection, smaller attack range
	detection_radius = base_detection + _constraint * 5.0
	# Attack range is used in _process_chase


func _process_chase(delta: float) -> void:
	var dist: float = _get_player_distance()

	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	# Move toward player
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			var move_dir: Vector3 = to_player.normalized()
			velocity.x = move_dir.x * chase_speed
			velocity.z = move_dir.z * chase_speed
			_face_direction(move_dir, delta * 5.0)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0

	# Attack when in range — range is inversely affected by constraint param
	var attack_range: float = base_attack_range * (1.0 - _constraint * 0.6)
	attack_range = max(0.5, attack_range)

	if dist < attack_range and _attack_cooldown <= 0.0:
		_perform_attack()


func _perform_attack() -> void:
	_attack_cooldown = 1.2

	if not is_instance_valid(_player_node):
		return

	# Damage scaled by delta_e
	var dmg: float = contact_damage
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("apply_health_damage"):
		gm.apply_health_damage(dmg)

	# Visual: all beams flash
	_flash_beam(_phi_beam, _phi_mat, PHI_COLOR)
	_flash_beam(_delta_e_beam, _delta_e_mat, DELTA_E_COLOR)
	_flash_beam(_constraint_beam, _constraint_mat, CONSTRAINT_COLOR)

	# Body pulse
	var attack_tween := create_tween()
	attack_tween.tween_property(_body_mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.08)
	attack_tween.tween_property(_body_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.15)


func _flash_beam(beam: MeshInstance3D, mat: StandardMaterial3D, base_color: Color) -> void:
	if not is_instance_valid(beam):
		return
	var tween := create_tween()
	tween.tween_property(mat, "emission_energy_multiplier", 8.0, 0.05)
	tween.tween_property(mat, "emission_energy_multiplier", 2.0, 0.3)


func _on_damaged(_amount: float) -> void:
	# Damage disrupts parameter oscillation phases
	_time += randf_range(0.5, 2.0)
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.DEAD:
		# Death: beams collapse inward, body shrinks
		var death_tween := create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(_mesh_root, "scale", Vector3.ZERO, 0.6)
		death_tween.tween_property(_body_mat, "emission_energy_multiplier", 0.0, 0.6)
