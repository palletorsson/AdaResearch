# qfep_reactor.gd
# Central QFEP visualization orb - responds to lambda and phi in real-time
# The heart of the QFEP laboratory

extends Node3D
class_name QFEPReactor

# @identity
# essence: QFE = (1-lambda) - lambda*0.8 + phi*0.2; visualized as pulsing orb with color(lambda) and jitter(chaos)
# desire: stand before the reactor and watch theory become light — adjust sliders and see the formula respond
# critical_parameter: lambda — shifts reactor from crystalline blue through living green to chaotic red with position jitter
# triggers: set_lambda/set_phi from connected sliders; pulse_speed triples at edge of chaos; jitter activates above 0.6
# emerges: the reactor appears to think at the edge — fast pulsing, maximum particles, bright green glow
# needs: VR slider connections via group system [has], label display [has], particle system [has]
# relationships: central to QFEP_Sandbox; depends on lambda_slider and phi_slider; connects to reactive_particles; computes QFE in real-time
# truth: the reactor is the QFEP formula made tangible — not a metaphor for the equation but the equation itself, running

# ─── DNA · hand promotion 2026-08-04 ─────────────────────────────────────────
# Refused by the runner for NO TURNABLE KNOBS: this file had zero @export and no
# apply_grid_config, so no map token could reach anything in it.
#
# THE DEAD DRIVER. _connect_to_sliders() waits a frame and looks for the group
# "qfep_slider". Nothing in the repository ever calls add_to_group("qfep_slider")
# — lambda_slider.gd and phi_slider.gd both declare the signals and neither joins
# the group — so set_lambda() and set_phi() have never been called in any room.
# current_lambda has stood at its initialiser, 0.4, everywhere, forever. An orb
# whose whole claim is that the state MOVES has only ever drawn one state. This
# is the same disease edge_core was promoted for two hours earlier, found
# independently in a second file.
#
#   station  WHERE ON THE LAMBDA LINE THIS REACTOR STANDS when nothing is
#            driving it, which today is everywhere. The word, the three values
#            and the fallback rule are edge_core's, character for character:
#            these are two bodies on one line and they should measure alike.
#            Nothing about the colours is invented — COLOR_ORDER / COLOR_EDGE /
#            COLOR_CHAOS are already in this file and are the very constants
#            edge_core's promotion copied out; station only chooses which lambda
#            the existing _update_visuals() is painting.
#
#              edge   (DEFAULT, the lineage) lambda 0.4. Smooth 32x16 orb,
#                     green, 100 particles in a 0.35 m cloud, pulse tripled.
#              order  lambda 0.05 — CRYSTALLINE by this file's own
#                     get_state_name(). The orb becomes a solid you can count
#                     the faces of (7 segments, 4 rings — edge_core's numbers,
#                     so the pair crystallises alike), blue, the cloud calm.
#              chaos  lambda 0.95 — DISSOLUTION. The body shrinks to a speck at
#                     0.12x radius and the cloud loses its boundary: emission
#                     radius 0.35 -> 0.85, three times the population. Red, and
#                     jittering, both of which the shipped code already does
#                     above 0.6 and has never been asked to do.
#
#   readout  WHAT THE INSTRUMENT COMMITS TO ABOUT THE NUMBERS IT IS READING.
#            none < numeral < gradation < lattice, taken character for character
#            from commons/primitives/line/line.gd, its twin xyz_slider_plate.gd
#            and qfep_calibrator, INCLUDING their rule that an unrecognised word
#            reads as `numeral` rather than `none`, so a typo can never strip the
#            placard off a live room. Strictly additive, rung over rung.
#            numeral is the shipped Label3D and changes nothing. gradation lays
#            the lambda line itself under the orb with the edge band painted on
#            it — the interval 0.3..0.5 that is_at_edge() has always tested for
#            and never drawn. lattice raises that line into the lambda x phi
#            plane, the parameter space this artifact is standing in, with the
#            edge band as a REGION rather than a point.
#
# WHY NOT THE PULSE OR THE GLOW, which are what the description leads with. The
# evidence is ONE STILL PNG per value and a rate is invisible to it — info_board
# was swept across five duration exports and produced six identical tiles.
# pulse_speed, the breathing and the emission wobble are all left exactly as they
# were and none of them is declared. Every value above is FORM or PLACE: facet
# count, cloud radius, a scale that is drawn or is not.
#
# NOT ROUTED THROUGH set_lambda(). That function is untouched, so if a driver is
# ever wired up it overrides the colour exactly as before; station is only where
# the reactor stands when nothing is driving it.
# ─────────────────────────────────────────────────────────────────────────────

## THE FIRST AXIS. edge is the legacy lineage. The registry declaration is
## derived from THIS LINE by tools/apply_dna_block.py.
@export_enum("edge", "order", "chaos") var station: String = "edge"

## THE SECOND AXIS. numeral is the shipped Label3D.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral"

## CAPTURE FIXTURE, not an axis. -1.0 is live time and the shipped behaviour.
## Untyped on purpose: a typed float rejects the string a fixture passes before
## _ready. Non-negative pins the pulse phase and the chaos jitter so that three
## stations are photographed at one instant instead of at three.
@export var freeze_time = -1.0

## The allow-lists a map token is checked against.
const STATIONS: PackedStringArray = ["edge", "order", "chaos"]
const READOUTS: PackedStringArray = ["none", "numeral", "gradation", "lattice"]

## Where each station stands on the lambda line. EDGE_LAMBDA is the shipped
## initialiser, unchanged. The other two are read off this file's own branches:
## 0.05 is CRYSTALLINE and below the 0.3 colour split, 0.95 is DISSOLUTION and
## above both the 0.7 pulse split and the 0.6 jitter split.
const ORDER_LAMBDA: float = 0.05
const EDGE_LAMBDA: float = 0.4
const CHAOS_LAMBDA: float = 0.95

## Fixed so the jitter is one sequence and not a new object every boot.
const JITTER_SEED: int = 40405

# Readout geometry. The plane stands in FRONT of the orb and inside its own
# vertical extent (|y| <= 0.28 against the core's 0.3), so the merged AABB grows
# only sideways — the artifact's ground plane, and therefore its seating in every
# room, is the same at every rung.
const READOUT_Z: float = 0.52
const RULE_Y: float = -0.28
const RULE_SPAN: float = 0.90
const PLANE_H: float = 0.56

# State
var current_lambda := 0.4
var current_phi := 0.0
var current_qfe := 0.0

# Visual components
var core_mesh: MeshInstance3D
var particle_system: GPUParticles3D
var core_material: ShaderMaterial
var glow_light: OmniLight3D

# Animation
var time := 0.0
var pulse_phase := 0.0

# Colors for different states
const COLOR_ORDER := Color(0.2, 0.4, 1.0)      # Blue - crystalline
const COLOR_EDGE := Color(0.2, 1.0, 0.5)       # Green - alive
const COLOR_CHAOS := Color(1.0, 0.3, 0.2)      # Red - dissolution

# DNA internals
var _built: bool = false
var _frozen: bool = false
var _particle_scale: float = 1.0
var _readout_root: Node3D = null
var _lambda_marker: MeshInstance3D = null
var _plane_marker: MeshInstance3D = null
var _rng := RandomNumberGenerator.new()

# Signals
signal state_changed(lambda: float, phi: float, qfe: float)

func _ready():
	_read_axis_words()
	current_lambda = _station_lambda()
	_rng.seed = JITTER_SEED

	_create_core()
	_create_particles()
	_create_light()
	_create_label()
	_build_readout()

	add_to_group("qfep_reactive")
	add_to_group("interactable")

	_built = true
	_apply_freeze()

	# Connect to global lambda/phi if available
	_connect_to_sliders()

## A map token reaches here as metadata the grid stamps before add_child; the
## sweep sets the export directly, so the export is the fallback.
func _read_axis_words() -> void:
	var want_station: String = station
	if has_meta("config_station"):
		want_station = str(get_meta("config_station"))
	elif has_meta("station"):
		want_station = str(get_meta("station"))
	station = _normalise_station(want_station)

	var want_readout: String = readout
	if has_meta("config_readout"):
		want_readout = str(get_meta("config_readout"))
	elif has_meta("readout"):
		want_readout = str(get_meta("readout"))
	readout = _normalise_readout(want_readout)

	if has_meta("config_freeze_time"):
		freeze_time = float(str(get_meta("config_freeze_time")))

func _normalise_station(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	if STATIONS.has(word):
		return word
	return "edge"

## An unrecognised word reads as the legacy numeral, never as none — line.gd's
## rule, and for the same reason: a typo must not delete a placard from a room.
func _normalise_readout(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	if READOUTS.has(word):
		return word
	return "numeral"

func _station_lambda() -> float:
	match station:
		"order":
			return ORDER_LAMBDA
		"chaos":
			return CHAOS_LAMBDA
		_:
			return EDGE_LAMBDA

## The ladder as a rank, so each rung is strictly additive over the one below.
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

func _create_core():
	core_mesh = MeshInstance3D.new()
	core_mesh.name = "Core"

	var sphere := SphereMesh.new()
	var radius: float = 0.3
	if station == "chaos":
		# the body is gone; what is left is a speck inside the reaction
		radius = 0.3 * 0.12
	sphere.radius = radius
	sphere.height = radius * 2.0
	if station == "order":
		# faceted: a solid whose sides you can count
		sphere.radial_segments = 7
		sphere.rings = 4
	else:
		sphere.radial_segments = 32
		sphere.rings = 16
	core_mesh.mesh = sphere

	# Create shader material for dynamic effects
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_EDGE
	material.emission_enabled = true
	material.emission = COLOR_EDGE
	material.emission_energy_multiplier = 2.0
	material.roughness = 0.2
	material.metallic = 0.8
	core_mesh.material_override = material
	core_material = null  # Using StandardMaterial3D for now

	add_child(core_mesh)

func _create_particles():
	particle_system = GPUParticles3D.new()
	particle_system.name = "Particles"
	particle_system.amount = 100
	particle_system.lifetime = 2.0
	particle_system.explosiveness = 0.0
	particle_system.randomness = 0.5

	# Create particle material
	var particle_mat := ParticleProcessMaterial.new()
	particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	var emission_radius: float = 0.35
	_particle_scale = 1.0
	if station == "chaos":
		# the cloud loses its boundary and gains a population
		emission_radius = 0.85
		_particle_scale = 3.0
	particle_mat.emission_sphere_radius = emission_radius
	particle_mat.direction = Vector3(0, 1, 0)
	particle_mat.spread = 180.0
	particle_mat.initial_velocity_min = 0.1
	particle_mat.initial_velocity_max = 0.3
	particle_mat.gravity = Vector3.ZERO
	particle_mat.scale_min = 0.02
	particle_mat.scale_max = 0.05
	particle_mat.color = COLOR_EDGE
	particle_system.process_material = particle_mat

	# Create particle mesh
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.02
	particle_mesh.height = 0.04
	particle_system.draw_pass_1 = particle_mesh

	add_child(particle_system)

func _create_light():
	glow_light = OmniLight3D.new()
	glow_light.name = "GlowLight"
	glow_light.light_color = COLOR_EDGE
	glow_light.light_energy = 2.0
	glow_light.omni_range = 3.0
	glow_light.omni_attenuation = 1.5
	add_child(glow_light)

## RUNG 1, and the shipped placard. Rung 0 builds nothing, and _update_visuals
## already looks the label up with get_node_or_null, so its absence costs nothing.
func _create_label():
	if _readout_rank() < 1:
		return
	var label := Label3D.new()
	label.name = "StateLabel"
	label.text = "λ=%.2f  φ=%.2f" % [current_lambda, current_phi]
	label.font_size = 32
	label.position = Vector3(0, 0.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1, 0.8)
	add_child(label)

func _process(delta):
	if _frozen:
		return
	time += delta

	# Animate based on current state
	_update_animation(delta)
	_update_visuals()

func _update_animation(delta):
	# Null guard: only ever true for the one frame a rebuild is in flight.
	if not is_instance_valid(core_mesh):
		return
	# Pulse speed depends on lambda (faster at edge of chaos)
	var pulse_speed: float = 1.0
	if current_lambda > 0.25 and current_lambda < 0.55:
		pulse_speed = 3.0  # Faster at edge
	elif current_lambda > 0.7:
		pulse_speed = 5.0 + _rng.randf() * 2.0  # Chaotic

	pulse_phase += delta * pulse_speed

	# Core breathing animation
	var breath: float = 1.0 + sin(pulse_phase) * 0.1 * (1.0 + current_lambda)
	core_mesh.scale = Vector3.ONE * breath

	# Add chaos jitter at high lambda
	if current_lambda > 0.6:
		var jitter: float = current_lambda - 0.6
		core_mesh.position = Vector3(
			_rng.randf_range(-jitter, jitter) * 0.1,
			_rng.randf_range(-jitter, jitter) * 0.1,
			_rng.randf_range(-jitter, jitter) * 0.1
		)
	else:
		core_mesh.position = Vector3.ZERO

func _update_visuals():
	# Null guard: only ever true for the one frame a rebuild is in flight.
	if not is_instance_valid(core_mesh) or not is_instance_valid(particle_system):
		return
	# Calculate color based on lambda
	var color: Color
	if current_lambda < 0.3:
		color = COLOR_ORDER.lerp(COLOR_EDGE, current_lambda / 0.3)
	elif current_lambda < 0.5:
		color = COLOR_EDGE
	else:
		color = COLOR_EDGE.lerp(COLOR_CHAOS, (current_lambda - 0.5) / 0.5)

	# Phi affects saturation/intensity
	if current_phi > 0:
		color = color.lightened(current_phi * 0.3)
	else:
		color = color.darkened(-current_phi * 0.3)

	# Apply to materials
	var mat = core_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
		mat.emission = color
		mat.emission_energy_multiplier = 1.5 + sin(pulse_phase * 2) * 0.5

	# Update light
	glow_light.light_color = color
	glow_light.light_energy = 1.5 + sin(pulse_phase) * 0.5

	# Update particles
	var proc_mat = particle_system.process_material as ParticleProcessMaterial
	if proc_mat:
		proc_mat.color = color
		# More particles at edge of chaos
		var particle_mult: float = 1.0
		if current_lambda > 0.3 and current_lambda < 0.5:
			particle_mult = 2.0
		particle_system.amount = int(50 * particle_mult * _particle_scale)

		# Particle behavior changes with lambda
		proc_mat.initial_velocity_max = 0.1 + current_lambda * 0.4
		proc_mat.spread = 90 + current_lambda * 90

	# Update label
	var label = get_node_or_null("StateLabel") as Label3D
	if label:
		label.text = "λ=%.2f  φ=%.2f" % [current_lambda, current_phi]
		label.modulate = color

	# Rungs 2 and 3: the marker follows the state along the drawn scale.
	if is_instance_valid(_lambda_marker):
		_lambda_marker.position = Vector3(_lambda_to_x(current_lambda), RULE_Y + 0.036, READOUT_Z)
	if is_instance_valid(_plane_marker):
		_plane_marker.position = Vector3(_lambda_to_x(current_lambda), _phi_to_y(current_phi), READOUT_Z)

func set_lambda(value: float):
	current_lambda = clamp(value, 0.0, 1.0)
	_calculate_qfe()
	state_changed.emit(current_lambda, current_phi, current_qfe)

func set_phi(value: float):
	current_phi = clamp(value, -1.0, 1.0)
	_calculate_qfe()
	state_changed.emit(current_lambda, current_phi, current_qfe)

func _calculate_qfe():
	# Simplified QFE calculation for visualization
	# QFE = F - λE(S) + φΔE(S,t)
	var F: float = 1.0 - current_lambda  # F decreases as lambda increases
	var entropy_term: float = current_lambda * 0.8
	var rate_term: float = current_phi * 0.2
	current_qfe = F - entropy_term + rate_term

func _connect_to_sliders():
	# Find lambda and phi sliders in scene and connect
	await get_tree().process_frame

	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(set_lambda)
			print("QFEPReactor: Connected to lambda slider")
		if slider.has_signal("phi_changed"):
			slider.phi_changed.connect(set_phi)
			print("QFEPReactor: Connected to phi slider")

# Check if currently at edge of chaos
func is_at_edge() -> bool:
	return current_lambda > 0.3 and current_lambda < 0.5

# Get state description
func get_state_name() -> String:
	if current_lambda < 0.2:
		return "CRYSTALLINE"
	elif current_lambda < 0.35:
		return "APPROACHING EDGE"
	elif current_lambda < 0.5:
		return "EDGE OF CHAOS"
	elif current_lambda < 0.7:
		return "TURBULENT"
	else:
		return "DISSOLUTION"

# ─── DNA implementation ──────────────────────────────────────────────────────
# Nothing below this line runs for a bare token at the shipped words.

## Pin the animation so that N stations are N photographs of one instant rather
## than of N phases. Never entered at the shipped freeze_time.
func _apply_freeze() -> void:
	var ft: float = float(freeze_time)
	if ft < 0.0:
		return
	time = ft
	pulse_phase = ft
	_update_animation(0.0)
	_update_visuals()
	_frozen = true

func _lambda_to_x(value: float) -> float:
	return (clamp(value, 0.0, 1.0) - 0.5) * RULE_SPAN

func _phi_to_y(value: float) -> float:
	return RULE_Y + (clamp(value, -1.0, 1.0) + 1.0) * 0.5 * PLANE_H

func _readout_bar(size: Vector3, pos: Vector3, tint: Color, energy: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = energy
	if tint.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = mat
	mi.mesh = box
	mi.position = pos
	_readout_root.add_child(mi)
	return mi

## RUNG 2 — the lambda line itself, laid under the orb, with the edge band
## painted across 0.3..0.5: the interval is_at_edge() has always tested for and
## the artifact has never drawn.
func _build_gradation() -> void:
	var steel := Color(0.72, 0.76, 0.82, 1.0)
	_readout_bar(Vector3(RULE_SPAN, 0.012, 0.02), Vector3(0.0, RULE_Y, READOUT_Z), steel * 0.5, 0.25)
	var band_w: float = RULE_SPAN * 0.2
	var band_x: float = _lambda_to_x(0.4)
	_readout_bar(Vector3(band_w, 0.016, 0.024), Vector3(band_x, RULE_Y, READOUT_Z), COLOR_EDGE, 2.0)
	for i in range(11):
		var lam: float = float(i) * 0.1
		var major: bool = i == 0 or i == 5 or i == 10
		var h: float = 0.026
		if major:
			h = 0.05
		_readout_bar(Vector3(0.008, h, 0.016),
				Vector3(_lambda_to_x(lam), RULE_Y + 0.006 + h * 0.5, READOUT_Z), steel, 0.8)
	_lambda_marker = _readout_bar(Vector3(0.022, 0.05, 0.03),
			Vector3(_lambda_to_x(current_lambda), RULE_Y + 0.036, READOUT_Z), Color.WHITE, 2.4)

## RUNG 3 — the same line raised into the parameter SPACE it is one axis of:
## lambda across, phi up, the edge band now a region rather than a point, and a
## marker at this reactor's point in it. True before anything has been measured.
func _build_lattice() -> void:
	var steel := Color(0.72, 0.76, 0.82, 1.0)
	var mid_y: float = RULE_Y + PLANE_H * 0.5
	# the phi axis, standing at the low-lambda end
	_readout_bar(Vector3(0.012, PLANE_H, 0.02),
			Vector3(_lambda_to_x(0.0) - 0.03, mid_y, READOUT_Z), steel * 0.6, 0.3)
	# the edge of chaos as a REGION of the space
	_readout_bar(Vector3(RULE_SPAN * 0.2, PLANE_H, 0.008),
			Vector3(_lambda_to_x(0.4), mid_y, READOUT_Z - 0.006),
			Color(COLOR_EDGE.r, COLOR_EDGE.g, COLOR_EDGE.b, 0.22), 0.9)
	# phi = 0, the line the queer term is measured from
	_readout_bar(Vector3(RULE_SPAN, 0.008, 0.014),
			Vector3(0.0, _phi_to_y(0.0), READOUT_Z), steel * 0.85, 0.6)
	for i in range(3):
		var lam: float = 0.25 + float(i) * 0.25
		_readout_bar(Vector3(0.005, PLANE_H, 0.01),
				Vector3(_lambda_to_x(lam), mid_y, READOUT_Z), steel * 0.35, 0.2)
	for j in range(2):
		var phi_line: float = -0.5 + float(j) * 1.0
		_readout_bar(Vector3(RULE_SPAN, 0.005, 0.01),
				Vector3(0.0, _phi_to_y(phi_line), READOUT_Z), steel * 0.35, 0.2)
	_plane_marker = _readout_bar(Vector3(0.036, 0.036, 0.036),
			Vector3(_lambda_to_x(current_lambda), _phi_to_y(current_phi), READOUT_Z),
			Color.WHITE, 3.0)

func _build_readout() -> void:
	var rank: int = _readout_rank()
	if rank < 2:
		return
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	add_child(_readout_root)
	_build_gradation()
	if rank >= 3:
		_build_lattice()

## Reachable configuration. Both branches are CHANGE-GUARDED and BUILD-GUARDED:
## a word outside the allow-list, a word this reactor already holds, or a call
## arriving before _ready has built once tears nothing down. Every existing
## placement is a bare token carrying neither key, so nothing rebuilds for them.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("station"):
		var want: String = _normalise_station(str(config_data["station"]))
		if want != station:
			station = want
			if _built:
				_rebuild_body()
	if config_data.has("readout"):
		var want_readout: String = _normalise_readout(str(config_data["readout"]))
		if want_readout != readout:
			readout = want_readout
			if _built:
				_rebuild_readout()

func _rebuild_body() -> void:
	for node in [core_mesh, particle_system, glow_light]:
		if is_instance_valid(node):
			node.queue_free()
	core_mesh = null
	particle_system = null
	glow_light = null
	current_lambda = _station_lambda()
	_create_core()
	_create_particles()
	_create_light()
	_apply_freeze()

func _rebuild_readout() -> void:
	var label: Node = get_node_or_null("StateLabel")
	if is_instance_valid(label):
		label.queue_free()
	if is_instance_valid(_readout_root):
		_readout_root.queue_free()
	_readout_root = null
	_lambda_marker = null
	_plane_marker = null
	_create_label()
	_build_readout()
