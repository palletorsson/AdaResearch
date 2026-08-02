# lambda_slider.gd
# QFEP Lambda (λ) Parameter Controller
# Controls the entropy drive: how much a system values disorder vs order
# λ = 0: Pure order (crystal, rigidity, dark room)
# λ = 0.3-0.5: Edge of chaos (life, adaptation, creativity)
# λ = 1: Pure entropy (dissolution, noise, dispersal)

extends Node3D

class_name LambdaSlider

# @identity
# essence: slider_position / rail_length -> lambda in [0,1]; color_gradient(blue->green->red)
# desire: grab the entropy drive and feel the system shift from crystal to chaos under your hand
# critical_parameter: lambda — the single number that controls order/chaos balance across the entire QFEP system
# triggers: XR grab moves handle; slider_moved signal propagates to all connected visualizations; broadcasts globally
# emerges: the green zone at 0.3-0.5 where particles and color converge — the sweet spot finds you
# needs: VR XR slider grab [has], visual gradient rail [has], particle feedback [has], global broadcast [has]
# relationships: controls edge_core, qfep_reactor, queer_morphology_specimen; paired with phi_slider; central to every QFEP map
# truth: lambda is the entropy drive — the dial between crystallization and dissolution that every living system must negotiate

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (noted 2026-07-27, implemented 2026-07-31) —
# ONE AXIS, TWO FILES. phi_slider.gd carries
# the same `calibration` token with the same five values. The pair is the QFEP
# formula's own parameters made grabbable; it would be incoherent for them to
# speak different vocabularies about the same question.
#
#   calibration   WHAT THE SCALE CLAIMS ABOUT WHERE THE RIGHT VALUE LIES
#                 optimum · band · dispute · gap · none
#
# WHY THIS, AND NOT A REGISTER OR AN EXPOSURE AXIS. A slider is not a thing in a
# room and not a machine you operate. It is a claim that a quantity is
# continuous, ordered, and yours to set. For λ — a term in an epistemology, not a
# quantity — that claim is the whole argument, and the argument's limit is that
# there is no standard to calibrate it against. There is no metre bar in Sèvres
# for how much a system should value disorder. An instrument's authority comes
# from its calibration chain; this one's chain ends nowhere, and today's build
# covers that by painting the answer on in green.
#
# WHAT EACH VALUE DOES WITH THE PART IT CANNOT REPRESENT — the sieve's third
# question, which is what decides whether this is a family or a menu:
#   optimum  HIDES it.     One apex, coloured in. The question is settled, so the
#                          working face has nothing to argue and stays blank.
#   band     BOUNDS it.    Correctness is a tolerance, not a number. The claim
#                          survives, with its width admitted.
#   dispute  EXHIBITS it.  Three schools, three optima, none dominant. The
#                          disagreement becomes the thing the instrument shows.
#   gap      LEAVES A HOLE. The rail is cut where the recommended value sits. The
#                          scale cannot hold the position it recommends, and the
#                          word EDGE ends up labelling rail that is not there.
#   none     BUILDS THERE. An even ruler. Every position equally warranted, no
#                          colour argument at all. You have to site yourself.
#
# calibration=optimum is the legacy lineage, segment for segment: ten gradient
# boxes at their old sizes, positions, colours, emission 0.3 and alpha 0.6, the
# rail in its old grey, and the scale plate the other four inscribe is not built
# at all. All 23 placements are untouched.
#
# WHAT IT COST. The rail is no longer built in one readable pass — five branches
# now stand between a reader and the answer to "what colour is a segment". And
# `optimum`'s blank working face, which used to be merely an unbuilt surface, is
# now legible as a CLAIM (nothing to show because nothing is in doubt). That is a
# real foreclosure: this object can no longer be innocent about its confidence.
#
# NOT ROUTED THROUGH calibration: the λ value, its range, the colour meanings
# (blue order / green edge / red chaos), the three word-marks, and every
# threshold in is_at_edge() and get_state_description(). The regions the variants
# bracket, flag and cut are READ OUT of those thresholds, never invented — this
# pass stages the curriculum's last claims, it does not edit them.
# ─────────────────────────────────────────────────────────────────────────────

## Signal emitted when lambda value changes
signal lambda_changed(value: float)

## Signal emitted when slider is grabbed
signal slider_grabbed()

## Signal emitted when slider is released
signal slider_released()

## Current lambda value (0.0 to 1.0)
@export var lambda: float = 0.4:
	set(v):
		lambda = clamp(v, 0.0, 1.0)
		_update_visuals()
		emit_signal("lambda_changed", lambda)

## THE AXIS — what the scale claims about where the right value lies (see the
## promotion note above). optimum is the legacy lineage and paints the answer on;
## the other four inscribe the scale plate instead. Every region they bracket,
## flag or cut is read out of is_at_edge() and the shipped default — never
## invented here.
@export_enum("optimum", "band", "dispute", "gap", "none") var calibration: String = "optimum"

## THE VOCABULARY LIVES HERE, ONCE. phi_slider.gd preloads this script and reads
## this list, normalise_calibration() and the plate builder below out of it, so the
## two files cannot drift apart on what the five words are or what they inscribe.
## The @export_enum line above is the one thing that has to be written out twice —
## an annotation argument must be a literal — and normalise_calibration() is what
## keeps that from mattering: a word in one annotation and not in this list falls
## back to the legacy look instead of rendering something the registry never
## declared. This list is also what tools/apply_dna_block.py derives the registry
## declaration from.
const CALIBRATIONS: PackedStringArray = ["optimum", "band", "dispute", "gap", "none"]

## Read out of the code, not invented: is_at_edge() spans λ 0.3..0.5, and the
## shipped default (default_position in _build_slider, _get_lambda_color's pivot)
## sits at 0.4.
const CALIB_LO := 0.3
const CALIB_HI := 0.5
const CALIB_APEX := 0.4
const CALIB_NEUTRAL := Color(0.50, 0.51, 0.53)
const CALIB_PLATE := Color(0.14, 0.15, 0.17)

## Face of the scale plate on the lectern's fascia. The rail is 20 mm of a 1.3 m
## body, so an argument confined to the rail is a few pixels in any frame that
## contains the instrument; the fascia is the only surface on this housing wide
## enough to carry the claim AND clear of the λ readout and the rail itself. It is
## also where an instrument's calibration certificate belongs.
const CALIB_PLATE_W := 0.55
const CALIB_PLATE_H := 0.20

## Housing — cabinet grammar, VERTICAL dialect (body = "scale lectern").
## This was the purest case of the pattern the grammar exists to fix: a bare rail
## lying at y=0 with its ORDER / EDGE / CHAOS marks at y=-0.05, BELOW the floor, and
## the λ value billboarding in the air above it. Nothing to stand at, nothing to
## reach. The lectern gives the rail a body: the slider rides a wedge shoulder in
## the reach band, the scale marks are inlaid on the fascia beneath it, and the
## value reads from a screen seated in the backboard.
@export var console_body: bool = true
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "LM-02"
## Height of the shoulder the rail rides on.
@export var deck_height: float = 0.95

## Visual size of the slider rail
@export var rail_length: float = 0.5
@export var rail_height: float = 0.02
@export var rail_depth: float = 0.05

## Handle size
@export var handle_radius: float = 0.03

## Show particle effects
@export var show_particles: bool = true

## Show value label
@export var show_label: bool = true

## Connect to global QFEP system
@export var broadcast_globally: bool = true

# Internal references
var _slider: XRToolsInteractableSlider
var _handle: XRToolsInteractableHandle
var _rail_mesh: MeshInstance3D
var _handle_mesh: MeshInstance3D
var _label: Label3D
var _particles: GPUParticles3D
var _rail_material: StandardMaterial3D
var _handle_material: StandardMaterial3D
var _is_grabbed: bool = false
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
var _cab: Node3D     # the lectern
var _rig: Node3D     # the rail assembly, lifted onto the shoulder
## Every node `calibration` owns — the rail, the colour argument on it and the scale
## plate. Tracked so a `#calibration:` token arriving after _ready() can free exactly
## these and build the other lineage, touching neither the XR slider, the handle, the
## word-marks, the particles nor the lectern.
var _calib_nodes: Array[Node] = []
var _built: bool = false

## Front-to-back depth of the lectern. Named because the fascia mount has to land on
## the same face _create_console() builds.
const CONSOLE_DEPTH: float = 0.30

# Glow parameters (like grab_sphere)
const GLOW_EMISSION_ENERGY: float = 2.0

# Color gradient for lambda visualization
const COLOR_ORDER = Color(0.2, 0.4, 0.9, 1.0)      # Blue - pure order (λ=0)
const COLOR_EDGE = Color(0.2, 0.9, 0.4, 1.0)       # Green - edge of chaos (λ≈0.4)
const COLOR_CHAOS = Color(0.9, 0.2, 0.2, 1.0)      # Red - pure chaos (λ=1)

func _ready() -> void:
	if console_body:
		_create_console()
	_build_slider()
	_build_visuals()
	_update_visuals()
	
	# Register globally
	if broadcast_globally:
		add_to_group("qfep_lambda_controllers")
	
	print("LambdaSlider ready at λ = %.2f" % lambda)

## Where the rail rides. The slider is authored from x=0 to x=rail_length at y=0,
## so the stage centres it on the shoulder and lifts it into the reach band without
## touching a single authored coordinate.
func _stage() -> Node3D:
	if not console_body:
		return self
	if _rig == null:
		_rig = Node3D.new()
		_rig.name = "RailAssembly"
		_rig.position = Vector3(-rail_length * 0.5, deck_height + 0.055, 0.055)
		add_child(_rig)
	return _rig


## THE LECTERN. A column to the floor, a wedge shoulder the rail rides on, and a
## backboard carrying the λ readout under a sign band.
func _create_console() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_accent: Color = pal["accent"]
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	var w: float = rail_length + 0.13
	var d: float = CONSOLE_DEPTH
	var h: float = deck_height
	var face_z: float = d * 0.5

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_cab = cab

	# column to the floor (G2)
	cab.add_child(HangarKit.box(Vector3(0, h * 0.5, 0), Vector3(w, h, d), shell))
	cab.add_child(HangarKit.box(
		Vector3(0, 0.03, 0), Vector3(w - 0.10, 0.06, d - 0.10), dark))
	var gb: MeshInstance3D = HangarKit.grime_band(w * 0.88, 0.05, face_z + 0.003, col_body)
	if gb:
		gb.position.y = 0.075
		cab.add_child(gb)
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(sx * (w * 0.5 + 0.015), h * 0.5, 0.0),
			Vector3(0.030, h, d + 0.016), steel))
	# ember line under the working lip (G7)
	cab.add_child(HangarKit.box(
		Vector3(0, h - 0.012, face_z + 0.004),
		Vector3(w * 0.98, 0.007, 0.006), accent))
	var code: MeshInstance3D = HangarKit.stencil(
		unit_code, Vector2(0.10, 0.024), col_accent.lightened(0.22))
	if code:
		code.position = Vector3(-w * 0.5 + 0.09, h - 0.10, face_z + 0.004)
		cab.add_child(code)
	var bar: Node3D = HangarKit.three_color_bar(w * 0.34, 0.013)
	if bar:
		bar.position = Vector3(0.0, 0.30, face_z + 0.005)
		cab.add_child(bar)

	# wedge shoulder — the sloped shelf the rail rides on
	var shoulder: MeshInstance3D = HangarKit.wedge(w * 0.94, 0.11, d * 0.86, d * 0.30, steel)
	if shoulder:
		shoulder.position = Vector3(0.0, h + 0.045, -d * 0.40)
		cab.add_child(shoulder)

	# backboard + cap sign band (G1: the title is part of the body)
	var back_h: float = 0.30
	var back_z: float = -d * 0.5 + 0.035
	cab.add_child(HangarKit.box(
		Vector3(0, h + back_h * 0.5, back_z), Vector3(w, back_h, 0.07), shell))
	cab.add_child(HangarKit.box(
		Vector3(0, h + back_h + 0.026, back_z), Vector3(w + 0.04, 0.052, 0.10), steel))
	var sign: MeshInstance3D = HangarKit.stencil(
		"LAMBDA", Vector2(w * 0.52, 0.030), col_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, h + back_h + 0.026, back_z + 0.052)
		cab.add_child(sign)

	# λ readout seated in a milled pocket on the backboard
	var scr_w: float = w * 0.52
	var scr_h: float = 0.14
	var scr_y: float = h + back_h * 0.52
	var scr_z: float = back_z + 0.035
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, scr_z + 0.002),
		Vector3(scr_w + 0.026, scr_h + 0.030, 0.014), dark))
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, scr_z + 0.009),
		Vector3(scr_w, scr_h, 0.005), HangarKit.emissive(pal["screen"], 0.45)))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.04, 0.05, 0.08)
	glass.roughness = 0.15
	glass.emission_enabled = true
	glass.emission = Color(0.05, 0.08, 0.12)
	glass.emission_energy_multiplier = 0.5
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, scr_z + 0.0135), Vector3(scr_w, scr_h, 0.004), glass))
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y + scr_h * 0.5 + 0.010, scr_z + 0.011),
		Vector3(scr_w + 0.026, 0.005, 0.005), accent))


func _build_slider() -> void:
	# Create the XR Tools slider - horizontal along X axis
	_slider = XRToolsInteractableSlider.new()
	_slider.name = "InteractableSlider"
	_slider.slider_limit_min = 0.0
	_slider.slider_limit_max = rail_length
	_slider.slider_position = lambda * rail_length
	_slider.default_position = 0.4 * rail_length
	_slider.default_on_release = false
	_slider.slider_steps = 0.0  # Continuous
	
	# Create HandleOrigin node - this is the reference point for the handle
	# Matches the working slider_horizontal.tscn structure
	var handle_origin = Node3D.new()
	handle_origin.name = "HandleOrigin"
	
	# Create handle for grabbing - make it feel like grab_sphere
	_handle = XRToolsInteractableHandle.new()
	_handle.name = "InteractableHandle"
	
	# CRITICAL: Configure RigidBody3D settings so it doesn't fall!
	_handle.gravity_scale = 0.0
	_handle.collision_layer = 262144  # Bit 18 - XR pickable layer
	_handle.collision_mask = 0  # Don't collide with anything
	_handle.freeze = true  # Freeze until grabbed
	_handle.picked_up_layer = 0  # Match working slider
	
	# Handle collision shape - larger for easier grabbing
	var handle_collision = CollisionShape3D.new()
	handle_collision.name = "CollisionShape3D"
	var handle_shape = SphereShape3D.new()
	handle_shape.radius = handle_radius * 2.0  # Larger collision for easier grab
	handle_collision.shape = handle_shape
	_handle.add_child(handle_collision)
	
	# Add grab point redirects for left and right hands (like working slider)
	var grab_redirect_left = XRToolsGrabPointRedirect.new()
	grab_redirect_left.name = "GrabPointRedirectLeft"
	_handle.add_child(grab_redirect_left)
	
	var grab_redirect_right = XRToolsGrabPointRedirect.new()
	grab_redirect_right.name = "GrabPointRedirectRight"
	_handle.add_child(grab_redirect_right)
	
	# BUILD ENTIRE HIERARCHY BEFORE ADDING TO TREE
	# This ensures _hook_child_handles() finds the handle when slider._ready() runs
	handle_origin.add_child(_handle)
	_slider.add_child(handle_origin)
	
	# NOW add to tree - slider._ready() will find and hook the handle
	_stage().add_child(_slider)
	
	# Connect our own signals after hierarchy is set up
	if _slider.has_signal("slider_moved"):
		_slider.slider_moved.connect(_on_slider_moved)
	if _handle.has_signal("grabbed"):
		_handle.grabbed.connect(_on_slider_grabbed)
	if _handle.has_signal("released"):
		_handle.released.connect(_on_slider_released)

func _build_visuals() -> void:
	_build_rail_and_scale()

	# Build the handle visual - attach to handle so it moves with grab
	_handle_mesh = MeshInstance3D.new()
	var handle_sphere = SphereMesh.new()
	handle_sphere.radius = handle_radius
	handle_sphere.height = handle_radius * 2
	_handle_mesh.mesh = handle_sphere
	
	_handle_material = StandardMaterial3D.new()
	_handle_material.albedo_color = COLOR_EDGE
	_handle_material.emission_enabled = true
	_handle_material.emission = COLOR_EDGE
	_handle_material.emission_energy_multiplier = 0.5
	_handle_mesh.material_override = _handle_material
	# Add mesh to the HANDLE so it follows the grab position
	_handle.add_child(_handle_mesh)
	
	# Build label
	if show_label:
		_label = Label3D.new()
		_label.text = "λ = 0.40"
		_label.font_size = 48
		_label.pixel_size = 0.001
		if console_body:
			# Reads AGAINST the screen seated in the backboard — no billboard, because
			# a value that turns to follow you is not part of the instrument.
			_label.position = Vector3(0, deck_height + 0.30 * 0.52, -0.30 * 0.5 + 0.055)
			_cab.add_child(_label)
		else:
			_label.position = Vector3(rail_length / 2, rail_height + 0.05, 0)
			_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(_label)
		
		# Add sublabels for scale
		_build_scale_labels()
	
	# Build particles
	if show_particles:
		_build_particles()

	_built = true

## THE RAIL AND THE COLOUR ARGUMENT ON IT — everything `calibration` owns, in one
## place. Statement for statement what _build_visuals() used to open with, so
## calibration=optimum still builds the grey rail and then _build_rail_gradient()
## and nothing else; the only addition on that path is _own(), which appends to an
## array and changes no geometry.
func _build_rail_and_scale() -> void:
	if calibration == "gap":
		# the rail in two spans — the scale cannot hold the position it recommends
		_build_rail_cut()
	else:
		# Build the rail
		_rail_mesh = MeshInstance3D.new()
		var rail_box = BoxMesh.new()
		rail_box.size = Vector3(rail_length, rail_height, rail_depth)
		_rail_mesh.mesh = rail_box
		_rail_mesh.position = Vector3(rail_length / 2, 0, 0)

		# Rail material with gradient texture
		_rail_material = StandardMaterial3D.new()
		_rail_material.albedo_color = Color(0.3, 0.3, 0.3)
		_rail_material.metallic = 0.3
		_rail_material.roughness = 0.7
		_rail_mesh.material_override = _rail_material
		_stage().add_child(_own(_rail_mesh))

	# The colour argument. optimum is the legacy lineage — ten gradient boxes,
	# segment for segment, and no scale plate. The other four withhold the painted
	# answer and inscribe the plate instead.
	match calibration:
		"band", "dispute", "gap", "none":
			_build_calibration(calibration)
		_:
			_build_rail_gradient()

## Bookkeeping only — no geometry, no parenting. Returns what it is given so it can
## be wrapped around an add_child argument without moving any code.
func _own(n: Node3D) -> Node3D:
	_calib_nodes.append(n)
	return n

func _build_rail_gradient() -> void:
	# Create gradient segments on the rail
	var segment_count = 10
	var segment_width = rail_length / segment_count
	
	for i in range(segment_count):
		var segment = MeshInstance3D.new()
		var segment_mesh = BoxMesh.new()
		segment_mesh.size = Vector3(segment_width * 0.9, rail_height * 1.1, rail_depth * 0.5)
		segment.mesh = segment_mesh
		segment.position = Vector3(segment_width * (i + 0.5), 0, rail_depth * 0.3)
		
		var t = float(i) / float(segment_count - 1)
		var color = _get_lambda_color(t)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.6
		segment.material_override = mat

		_stage().add_child(_own(segment))

## ── THE SCALE PLATE ──────────────────────────────────────────────────────────
## The working face the four non-legacy calibrations inscribe. optimum never
## builds it: with the question settled there is nothing to argue.

func _build_calibration(mode: String) -> void:
	# the even coat: the legacy segments' geometry with the colour argument
	# withheld; gap omits the segments whose centre falls inside the region the
	# scale cannot hold
	var segment_count = 10
	var segment_width = rail_length / segment_count
	for i in range(segment_count):
		var t = (float(i) + 0.5) / float(segment_count)
		if mode == "gap" and t > CALIB_LO and t < CALIB_HI:
			continue
		_calib_box(Vector3(segment_width * (i + 0.5), 0, rail_depth * 0.3),
			Vector3(segment_width * 0.9, rail_height * 1.1, rail_depth * 0.5),
			_calib_mat(CALIB_NEUTRAL, 0.12, 0.6))
	# the plate itself, on the lectern's fascia — cut with the rail under gap
	_build_scale_plate(mode)
	if mode == "band":
		# correctness as a tolerance: the region admitted whole, its width shown,
		# no apex inside it
		_calib_box(Vector3(rail_length * (CALIB_LO + CALIB_HI) * 0.5, rail_height * 1.2, rail_depth * 0.75),
			Vector3(rail_length * (CALIB_HI - CALIB_LO), rail_height * 2.4, rail_depth * 0.35),
			_calib_mat(COLOR_EDGE, 0.5, 0.35))
		_calib_post(CALIB_LO, rail_height * 3.5, COLOR_EDGE)
		_calib_post(CALIB_HI, rail_height * 3.5, COLOR_EDGE)
	elif mode == "dispute":
		# three schools, three optima, none dominant — each candidate flagged in
		# the scale's own colour at that position, at equal height
		for s in [CALIB_LO, CALIB_APEX, CALIB_HI]:
			_calib_post(s, rail_height * 6.0, _get_lambda_color(s))
			_calib_box(Vector3(rail_length * s, rail_height * 6.0 + 0.014, rail_depth * 0.75),
				Vector3(0.026, 0.020, 0.012), _calib_mat(_get_lambda_color(s), 1.2, 1.0))
	elif mode == "none":
		# an even ruler: a tick at every tenth, every position equally warranted
		for i in range(11):
			_calib_post(float(i) / 10.0, rail_height * 1.8, CALIB_NEUTRAL.lightened(0.25))
	# gap adds nothing further: the hole is the inscription

## gap's rail: two spans and a hole where is_at_edge() says the right value
## lives. The EDGE word-mark keeps its position and ends up labelling rail that
## is not there.
func _build_rail_cut() -> void:
	_rail_material = StandardMaterial3D.new()
	_rail_material.albedo_color = Color(0.3, 0.3, 0.3)
	_rail_material.metallic = 0.3
	_rail_material.roughness = 0.7
	for span in [[0.0, CALIB_LO], [CALIB_HI, 1.0]]:
		var piece = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(rail_length * (span[1] - span[0]), rail_height, rail_depth)
		piece.mesh = box
		piece.position = Vector3(rail_length * (span[0] + span[1]) * 0.5, 0, 0)
		piece.material_override = _rail_material
		_stage().add_child(_own(piece))

## WHERE THE PLATE HANGS. On the lectern it is the fascia, in the clear band between
## the three-colour bar at y=0.30 and the unit code at y=h-0.10: the working face of a
## lectern is its front, it is the widest clean surface on this body, and it stands in
## front of neither the rail nor the λ readout. With console_body off there is no
## fascia, so the plate stands behind the rail the way phi_slider's does.
func _calibration_mount() -> Node3D:
	var mount := Node3D.new()
	mount.name = "CalibrationPlate"
	if console_body and _cab != null:
		mount.position = Vector3(0.0, deck_height * 0.60, CONSOLE_DEPTH * 0.5 + 0.004)
		_cab.add_child(_own(mount))
	else:
		mount.position = Vector3(rail_length * 0.5,
			rail_height * 0.5 + CALIB_PLATE_H * 0.55, -rail_depth * 0.62)
		_stage().add_child(_own(mount))
	return mount

## λ's numbers into the shared builder. The three schools are the same three optima
## the rail flags — CALIB_LO / CALIB_APEX / CALIB_HI — and every colour is read out of
## _get_lambda_color(), so the plate cannot say anything the rail does not.
func _build_scale_plate(mode: String) -> void:
	inscribe_scale_plate(_calibration_mount(), mode, CALIB_PLATE_W, CALIB_PLATE_H,
		CALIB_LO, CALIB_HI, PackedFloat32Array([CALIB_LO, CALIB_APEX, CALIB_HI]),
		PackedColorArray([_get_lambda_color(CALIB_LO), _get_lambda_color(CALIB_APEX),
			_get_lambda_color(CALIB_HI)]),
		COLOR_EDGE, CALIB_NEUTRAL, CALIB_PLATE)

func _calib_post(t: float, h: float, color: Color) -> void:
	_calib_box(Vector3(rail_length * t, h * 0.5, rail_depth * 0.75),
		Vector3(0.008, h, 0.008), _calib_mat(color, 0.8, 1.0))

func _calib_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	_stage().add_child(_own(calib_box(pos, size, mat)))

func _calib_mat(color: Color, emissive_energy: float, alpha: float) -> StandardMaterial3D:
	return calib_mat(color, emissive_energy, alpha)

## MAP CONFIG — `lambda_slider#calibration:dispute`. GridInteractablesComponent calls
## this deferred, after _ready() has already built one lineage, so a word that changes
## anything has to tear its own nodes down and build again. It frees only what _own()
## recorded. A config key we do not own, or a word outside CALIBRATIONS, changes
## nothing at all — which is why the tokens already in maps (#locked:, #value:) still
## reach this method and still do exactly what they did before: nothing here.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("calibration"):
		return
	var before: String = calibration
	calibration = normalise_calibration(str(config_data["calibration"]), calibration)
	if calibration == before or not _built:
		return
	_rebuild_calibration()
	print("LambdaSlider: calibration=%s" % calibration)

func _rebuild_calibration() -> void:
	for n in _calib_nodes:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_calib_nodes.clear()
	_build_rail_and_scale()

func _build_scale_labels() -> void:
	# Order label (λ=0)
	var label_order = Label3D.new()
	label_order.text = "ORDER"
	label_order.font_size = 24
	label_order.pixel_size = 0.001
	label_order.position = Vector3(0, -rail_height - 0.03, 0)
	label_order.modulate = COLOR_ORDER
	_stage().add_child(label_order)
	
	# Edge label (λ≈0.4)
	var label_edge = Label3D.new()
	label_edge.text = "EDGE"
	label_edge.font_size = 24
	label_edge.pixel_size = 0.001
	label_edge.position = Vector3(rail_length * 0.4, -rail_height - 0.03, 0)
	label_edge.modulate = COLOR_EDGE
	_stage().add_child(label_edge)
	
	# Chaos label (λ=1)
	var label_chaos = Label3D.new()
	label_chaos.text = "CHAOS"
	label_chaos.font_size = 24
	label_chaos.pixel_size = 0.001
	label_chaos.position = Vector3(rail_length, -rail_height - 0.03, 0)
	label_chaos.modulate = COLOR_CHAOS
	_stage().add_child(label_chaos)

func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = 50
	_particles.lifetime = 2.0
	_particles.position = Vector3(rail_length / 2, rail_height + 0.1, 0)
	
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_mat.emission_box_extents = Vector3(rail_length / 2, 0.05, 0.05)
	particle_mat.direction = Vector3(0, 1, 0)
	particle_mat.spread = 30.0
	particle_mat.initial_velocity_min = 0.05
	particle_mat.initial_velocity_max = 0.15
	particle_mat.gravity = Vector3(0, -0.1, 0)
	particle_mat.scale_min = 0.5
	particle_mat.scale_max = 1.5
	_particles.process_material = particle_mat
	
	# Particle mesh
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.005
	particle_mesh.height = 0.01
	_particles.draw_pass_1 = particle_mesh
	
	_stage().add_child(_particles)

func _on_slider_moved(position: float) -> void:
	# Convert slider position to lambda value
	lambda = position / rail_length
	
func _on_slider_grabbed(_interactable) -> void:
	_is_grabbed = true
	emit_signal("slider_grabbed")
	# Apply glow effect like grab_sphere
	if _handle_material:
		_handle_material.emission_energy_multiplier = GLOW_EMISSION_ENERGY
		# Scale up slightly when grabbed
		if _handle_mesh:
			var tween = create_tween()
			tween.tween_property(_handle_mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.1)
	
func _on_slider_released(_interactable) -> void:
	_is_grabbed = false
	emit_signal("slider_released")
	# Reset glow effect
	if _handle_material:
		_handle_material.emission_energy_multiplier = 0.5
		# Scale back to normal
		if _handle_mesh:
			var tween = create_tween()
			tween.tween_property(_handle_mesh, "scale", Vector3.ONE, 0.1)

func _update_visuals() -> void:
	# Update handle position
	if _slider:
		_slider.slider_position = lambda * rail_length
	
	# Update handle color
	var color = _get_lambda_color(lambda)
	if _handle_material:
		_handle_material.albedo_color = color
		_handle_material.emission = color
	
	# Update label
	if _label:
		_label.text = "λ = %.2f" % lambda
		_label.modulate = color
	
	# Update particles based on lambda
	if _particles and _particles.process_material:
		var particle_mat = _particles.process_material as ParticleProcessMaterial
		# More particles at higher lambda (more chaos)
		_particles.amount = int(lerp(10.0, 100.0, lambda))
		# Faster at higher lambda
		particle_mat.initial_velocity_max = lerp(0.05, 0.3, lambda)
		# More spread at higher lambda
		particle_mat.spread = lerp(10.0, 60.0, lambda)

func _get_lambda_color(value: float) -> Color:
	# Gradient: Blue (order) → Green (edge) → Red (chaos)
	if value < 0.4:
		# Order to Edge
		var t = value / 0.4
		return COLOR_ORDER.lerp(COLOR_EDGE, t)
	else:
		# Edge to Chaos
		var t = (value - 0.4) / 0.6
		return COLOR_EDGE.lerp(COLOR_CHAOS, t)

# ─────────────────────────────────────────────────────────────────────────────
# THE SHARED VOCABULARY. Everything below is static and phi_slider.gd calls it
# through a preload of this file. One allow-list, one normaliser, one plate
# builder, two instruments — because the pair are the same formula's parameters
# and a scale plate that argued differently on each would be two axes wearing one
# name. Each file supplies only what its own curriculum already states: where its
# recommended region sits, which positions disagree, and what colour its scale
# uses there.
# ─────────────────────────────────────────────────────────────────────────────

## Accept a value only if it names something both files actually build. A typo in a
## map token falls back to the shipped look rather than stranding a placement with a
## scale that claims nothing — and it is what keeps the two @export_enum lines from
## mattering if one of them ever drifts.
static func normalise_calibration(raw: String, fallback: String = "optimum") -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if CALIBRATIONS.has(v) else fallback

static func calib_mat(color: Color, emissive_energy: float, alpha: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emissive_energy
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = alpha
	return mat

## Builds a box; does NOT parent it. The caller owns where it goes, because one
## slider hangs its plate on a lectern fascia and the other stands it behind a bare
## rail.
static func calib_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	return mi

## THE SCALE PLATE — the working face the four non-legacy calibrations inscribe, and
## the one builder both sliders use.
##
## The mount's local frame IS the plate: x runs across the scale (t=0 at -w/2, t=1 at
## +w/2, the same t the rail uses), y up its face, +z out of it.
##
## WHY A PLATE AND NOT MORE MARKS ON THE RAIL. The rail is 20 mm tall on a 1.3 m
## instrument, and a capture frames an artifact by its bounding-box diagonal — so an
## argument confined to the rail is a few pixels high in the only evidence this loop
## has, and four different claims come out indistinguishable. The plate is the same
## claim at a size a still can read. The rail keeps its own marks; they anchor the
## plate's claim to the positions it is about.
static func inscribe_scale_plate(mount: Node3D, mode: String, w: float, h: float,
		lo: float, hi: float, marks: PackedFloat32Array,
		mark_colors: PackedColorArray, claim: Color, neutral: Color,
		ground: Color) -> void:
	if mode == "optimum":
		return

	# WHERE THE PLATE IS WHOLE. gap is the value that cuts it: the plate is built as
	# the pieces either side of the recommended region and the region itself is not
	# built at all, so the scale physically cannot carry the position it recommends.
	var spans: Array = [[0.0, 1.0]]
	if mode == "gap":
		spans = []
		if lo > 0.002:
			spans.append([0.0, lo])
		if hi < 0.998:
			spans.append([hi, 1.0])

	var slab: StandardMaterial3D = calib_mat(ground, 0.0, 1.0)
	var rule: StandardMaterial3D = calib_mat(neutral.lightened(0.20), 0.25, 1.0)
	for span in spans:
		var t0: float = float(span[0])
		var t1: float = float(span[1])
		if t1 - t0 < 0.004:
			continue
		mount.add_child(calib_box(
			Vector3(((t0 + t1) * 0.5 - 0.5) * w, 0.0, 0.0),
			Vector3((t1 - t0) * w, h, 0.006), slab))
		# the datum the whole scale is read against
		mount.add_child(calib_box(
			Vector3(((t0 + t1) * 0.5 - 0.5) * w, -h * 0.36, 0.005),
			Vector3((t1 - t0) * w, h * 0.05, 0.004), rule))

	match mode:
		"band":
			# ONE claim, with its width admitted. The ground outside the tolerance is
			# drawn dead — not wrong, just unwarranted — which is the whole difference
			# between a band and a point.
			var dead: StandardMaterial3D = calib_mat(neutral.darkened(0.20), 0.0, 1.0)
			for outside in [[0.0, lo], [hi, 1.0]]:
				var a: float = float(outside[0])
				var b: float = float(outside[1])
				if b - a < 0.004:
					continue
				mount.add_child(calib_box(
					Vector3(((a + b) * 0.5 - 0.5) * w, h * 0.06, 0.005),
					Vector3((b - a) * w, h * 0.74, 0.004), dead))
			mount.add_child(calib_box(
				Vector3(((lo + hi) * 0.5 - 0.5) * w, h * 0.06, 0.006),
				Vector3((hi - lo) * w, h * 0.74, 0.005), calib_mat(claim, 0.55, 1.0)))
			var brack: StandardMaterial3D = calib_mat(claim.lightened(0.45), 1.6, 1.0)
			for f in [lo, hi]:
				mount.add_child(calib_box(
					Vector3((float(f) - 0.5) * w, 0.0, 0.008),
					Vector3(w * 0.016, h, 0.006), brack))
		"dispute":
			# THREE claims and no arbiter. Each school holds the ground nearer to it
			# than to its neighbours and its optimum stands as a bright post — three
			# territories at equal strength, so the plate shows the disagreement
			# rather than resolving it.
			var edges := PackedFloat32Array()
			edges.append(0.0)
			for i in range(marks.size() - 1):
				edges.append((marks[i] + marks[i + 1]) * 0.5)
			edges.append(1.0)
			for i in range(marks.size()):
				var c: Color = claim
				if i < mark_colors.size():
					c = mark_colors[i]
				var a2: float = edges[i]
				var b2: float = edges[i + 1]
				if b2 - a2 > 0.004:
					mount.add_child(calib_box(
						Vector3(((a2 + b2) * 0.5 - 0.5) * w, h * 0.06, 0.005),
						Vector3((b2 - a2) * w, h * 0.74, 0.004),
						calib_mat(c.darkened(0.50), 0.10, 1.0)))
				mount.add_child(calib_box(
					Vector3((marks[i] - 0.5) * w, 0.0, 0.008),
					Vector3(w * 0.020, h, 0.006), calib_mat(c.lightened(0.25), 1.4, 1.0)))
		"none":
			# AN EVEN RULER. Twenty equal cells in one grey, alternating so the
			# division reads, and no colour anywhere on the plate: every position
			# equally warranted, nothing to find, you have to site yourself.
			var cell: StandardMaterial3D = calib_mat(neutral.lightened(0.30), 0.25, 1.0)
			for i in range(20):
				if i % 2 == 1:
					continue
				mount.add_child(calib_box(
					Vector3(((float(i) + 0.5) / 20.0 - 0.5) * w, h * 0.06, 0.005),
					Vector3(w * 0.05, h * 0.74, 0.004), cell))
		# gap inscribes nothing further: the hole is the inscription.

# Public API

## Set lambda value programmatically
func set_lambda(value: float) -> void:
	lambda = value

## Get current lambda value
func get_lambda() -> float:
	return lambda

## Move slider to specific lambda value
func move_to(value: float) -> void:
	if _slider:
		_slider.move_slider(value * rail_length)

## Get description of current lambda state
func get_state_description() -> String:
	if lambda < 0.2:
		return "Crystal (pure order)"
	elif lambda < 0.35:
		return "Stable (low entropy)"
	elif lambda < 0.5:
		return "Edge of Chaos (adaptive)"
	elif lambda < 0.7:
		return "Creative (high entropy)"
	else:
		return "Dissolution (chaos)"

## Check if at edge of chaos
func is_at_edge() -> bool:
	return lambda >= 0.3 and lambda <= 0.5

## Static method to find all lambda sliders in scene
static func get_all_sliders() -> Array:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.get_nodes_in_group("qfep_lambda_controllers")
	return []

## Static method to get global lambda value (average of all sliders)
static func get_global_lambda() -> float:
	var sliders = get_all_sliders()
	if sliders.is_empty():
		return 0.4  # Default
	
	var total = 0.0
	for slider in sliders:
		if slider.has_method("get_lambda"):
			total += slider.get_lambda()
	
	return total / sliders.size()
