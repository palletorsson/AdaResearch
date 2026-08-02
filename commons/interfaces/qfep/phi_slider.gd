# phi_slider.gd
# QFEP Phi (φ) Parameter Controller
# Controls rate of entropy change sensitivity
# φ < 0: System resists change (conservative)
# φ = 0: Neutral to change
# φ > 0: System embraces change (queer signature)

extends Node3D

class_name PhiSlider

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-31) — the other file of lambda_slider's ONE
# AXIS, TWO FILES pairing; the full design argument lives in that file's note.
# Same `calibration` token, same five values: what the scale claims about where
# the right value lies.
#
#   optimum  the legacy lineage, segment for segment: ten gradient boxes at
#            their old sizes and colours, the grey rail, no scale plate. The
#            painted answer — purple is wrong, gold is right.
#   band     the claim as a tolerance: has_queer_signature()'s region (φ > 0.2)
#            admitted whole, its width shown, no apex inside it.
#   dispute  three schools, none dominant: the neutral school (φ = 0), the
#            shipped default (φ = 0.3), and the far register get_state_description
#            names "Queer Signature" (marked at its midpoint, φ = 0.75).
#   gap      the rail cut over the whole recommended region. For φ the
#            recommendation is one-sided, so the cut takes the scale's entire
#            positive-beyond-0.2 reach and EMBRACE labels rail that is not there.
#   none     an even ruler. Every position equally warranted — which for THIS
#            parameter is itself the loudest claim, since the artifact's truth
#            line says positive φ is the point.
#
# Regions are READ OUT of has_queer_signature(), get_state_description() and the
# shipped default — never invented here. calibration=optimum leaves all shipped
# placements untouched.
# ─────────────────────────────────────────────────────────────────────────────

# @identity
# essence: slider_position -> phi in [-1,1]; color_gradient(purple->gray->gold)
# desire: grab the becoming dial and choose: resist change or embrace it
# critical_parameter: phi — rate sensitivity that determines whether the system fights or welcomes transformation
# triggers: XR grab moves handle; phi_changed signal propagates globally; particles shift direction with sign
# emerges: the asymmetry of the scale — negative phi feels heavy (downward particles), positive phi feels liberating (upward)
# needs: VR XR slider grab [has], visual gradient rail [has], particle feedback [has], global broadcast [has]
# relationships: controls queer_morphology_specimen, fluid_form, rigid_sculpture; paired with lambda_slider; the queer signature of QFEP
# truth: phi is the queer parameter — positive phi means the system does not merely tolerate change but seeks it as generative

## Signal emitted when phi value changes
signal phi_changed(value: float)

## Signal emitted when slider is grabbed
signal slider_grabbed()

## Signal emitted when slider is released
signal slider_released()

## Current phi value (-1.0 to 1.0)
@export var phi: float = 0.3:
	set(v):
		phi = clamp(v, -1.0, 1.0)
		_update_visuals()
		emit_signal("phi_changed", phi)

## THE AXIS — what the scale claims about where the right value lies (see the
## promotion note above; the design argument lives in lambda_slider.gd).
@export_enum("optimum", "band", "dispute", "gap", "none") var calibration: String = "optimum"

## THE VOCABULARY IS NOT DUPLICATED HERE. The allow-list, the normaliser and the scale
## plate builder all live in lambda_slider.gd and this file reads them out of it, so
## the pair cannot drift apart on what the five words are or what they inscribe. Only
## the @export_enum line above is written out twice — an annotation argument has to be
## a literal — and normalise_calibration() is what keeps that from mattering: a word in
## one annotation and not in the shared list falls back to the legacy look. What this
## file supplies is only φ's own numbers: where its recommended region sits, which
## positions disagree, and what colour its scale uses there.
const CalibrationAxis = preload("res://commons/interfaces/qfep/lambda_slider.gd")

## Rail positions in t = (φ+1)/2 space, read out of the code, not invented:
## has_queer_signature() opens at φ 0.2 → t 0.6; the shipped default φ 0.3 sits
## at t 0.65; get_state_description's "Queer Signature" register (φ ≥ 0.5) has
## its midpoint at φ 0.75 → t 0.875; neutral φ 0 sits at t 0.5.
const CALIB_QUEER := 0.6
const CALIB_APEX := 0.65
const CALIB_NEUTRAL_T := 0.5
const CALIB_FAR := 0.875
const CALIB_NEUTRAL := Color(0.50, 0.51, 0.53)
const CALIB_PLATE := Color(0.14, 0.15, 0.17)

## Face of the scale plate. φ has no housing to hang it on — this is the bare rail
## lying at y=0 that lambda_slider's note complains about — so the plate stands behind
## the rail and rises from it, which is the free space here and costs the framing about
## four percent. Height only; the width follows rail_length so the plate reads as the
## same scale drawn flat.
const CALIB_PLATE_H := 0.13

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
## Every node `calibration` owns — the rail, the colour argument on it and the scale
## plate. Tracked so a `#calibration:` token arriving after _ready() can free exactly
## these and build the other lineage, touching neither the XR slider, the handle, the
## word-marks nor the particles.
var _calib_nodes: Array[Node] = []
var _built: bool = false

# Glow parameters (like grab_sphere)
const GLOW_EMISSION_ENERGY: float = 2.0

# Color gradient for phi visualization
const COLOR_RESIST = Color(0.6, 0.3, 0.7, 1.0)     # Purple - resists change (φ<0)
const COLOR_NEUTRAL = Color(0.7, 0.7, 0.7, 1.0)   # Gray - neutral (φ=0)
const COLOR_EMBRACE = Color(1.0, 0.8, 0.2, 1.0)   # Gold - embraces change (φ>0)

func _ready() -> void:
	_build_slider()
	_build_visuals()
	_update_visuals()
	
	# Register globally
	if broadcast_globally:
		add_to_group("qfep_phi_controllers")
	
	print("PhiSlider ready at φ = %.2f" % phi)

func _build_slider() -> void:
	# Create the XR Tools slider - horizontal along X axis
	_slider = XRToolsInteractableSlider.new()
	_slider.name = "InteractableSlider"
	_slider.slider_limit_min = 0.0
	_slider.slider_limit_max = rail_length
	# Convert phi (-1 to 1) to slider position (0 to rail_length)
	_slider.slider_position = (phi + 1.0) / 2.0 * rail_length
	_slider.default_position = 0.65 * rail_length  # Default φ=0.3
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
	add_child(_slider)
	
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
	_handle_material.albedo_color = COLOR_EMBRACE
	_handle_material.emission_enabled = true
	_handle_material.emission = COLOR_EMBRACE
	_handle_material.emission_energy_multiplier = 0.5
	_handle_mesh.material_override = _handle_material
	# Add mesh to the HANDLE so it follows the grab position
	_handle.add_child(_handle_mesh)
	
	# Build label
	if show_label:
		_label = Label3D.new()
		_label.text = "φ = +0.30"
		_label.font_size = 48
		_label.pixel_size = 0.001
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
## calibration=optimum still builds the grey rail and then _build_rail_gradient() and
## nothing else; the only addition on that path is _own(), which appends to an array
## and changes no geometry.
func _build_rail_and_scale() -> void:
	if calibration == "gap":
		# the rail stops where the recommendation begins — the scale cannot hold
		# the region it recommends
		_build_rail_cut()
	else:
		# Build the rail
		_rail_mesh = MeshInstance3D.new()
		var rail_box = BoxMesh.new()
		rail_box.size = Vector3(rail_length, rail_height, rail_depth)
		_rail_mesh.mesh = rail_box
		_rail_mesh.position = Vector3(rail_length / 2, 0, 0)

		# Rail material
		_rail_material = StandardMaterial3D.new()
		_rail_material.albedo_color = Color(0.3, 0.3, 0.3)
		_rail_material.metallic = 0.3
		_rail_material.roughness = 0.7
		_rail_mesh.material_override = _rail_material
		add_child(_own(_rail_mesh))

	# The colour argument. optimum is the legacy lineage — ten gradient boxes,
	# segment for segment, and no scale plate. The other four withhold the painted
	# answer and inscribe the plate instead.
	match calibration:
		"band", "dispute", "gap", "none":
			_build_calibration(calibration)
		_:
			_build_rail_gradient()

## Bookkeeping only — no geometry, no parenting. Returns what it is given so it can be
## wrapped around an add_child argument without moving any code.
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
		var color = _get_phi_color((t * 2.0) - 1.0)  # -1 to 1
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.6
		segment.material_override = mat

		add_child(_own(segment))

## ── THE SCALE PLATE ──────────────────────────────────────────────────────────
## The working face the four non-legacy calibrations inscribe. optimum never
## builds it. Mirrors lambda_slider's plate; regions are φ's own.

func _build_calibration(mode: String) -> void:
	# the even coat: the legacy segments' geometry with the colour argument
	# withheld; gap omits every segment inside the recommended region
	var segment_count = 10
	var segment_width = rail_length / segment_count
	for i in range(segment_count):
		var t = (float(i) + 0.5) / float(segment_count)
		if mode == "gap" and t > CALIB_QUEER:
			continue
		_calib_box(Vector3(segment_width * (i + 0.5), 0, rail_depth * 0.3),
			Vector3(segment_width * 0.9, rail_height * 1.1, rail_depth * 0.5),
			_calib_mat(CALIB_NEUTRAL, 0.12, 0.6))
	# the plate itself — cut with the rail under gap, plus a bare end post where
	# the scale claims to end with no rail to hold it. The post also keeps gap's
	# bounding box as wide as every other value's, so a sweep sheet compares five
	# frames at one scale instead of measuring the camera moving.
	_build_scale_plate(mode)
	if mode == "gap":
		_calib_post(1.0, rail_height * 3.0, CALIB_NEUTRAL.lightened(0.25))
	if mode == "band":
		# the claim as a tolerance: has_queer_signature()'s whole region, its
		# width admitted, no apex inside it
		_calib_box(Vector3(rail_length * (CALIB_QUEER + 1.0) * 0.5, rail_height * 1.2, rail_depth * 0.75),
			Vector3(rail_length * (1.0 - CALIB_QUEER), rail_height * 2.4, rail_depth * 0.35),
			_calib_mat(COLOR_EMBRACE, 0.5, 0.35))
		_calib_post(CALIB_QUEER, rail_height * 3.5, COLOR_EMBRACE)
		_calib_post(1.0, rail_height * 3.5, COLOR_EMBRACE)
	elif mode == "dispute":
		# three schools, three optima, none dominant — each candidate flagged in
		# the scale's own colour at that position, at equal height
		for s in [CALIB_NEUTRAL_T, CALIB_APEX, CALIB_FAR]:
			var c = _get_phi_color(s * 2.0 - 1.0)
			_calib_post(s, rail_height * 6.0, c)
			_calib_box(Vector3(rail_length * s, rail_height * 6.0 + 0.014, rail_depth * 0.75),
				Vector3(0.026, 0.020, 0.012), _calib_mat(c, 1.2, 1.0))
	elif mode == "none":
		# an even ruler: a tick at every tenth, every position equally warranted
		for i in range(11):
			_calib_post(float(i) / 10.0, rail_height * 1.8, CALIB_NEUTRAL.lightened(0.25))
	# gap adds nothing further: the hole is the inscription

## gap's rail: one span that stops at has_queer_signature()'s threshold. The
## EMBRACE word-mark keeps its position at the far end and labels rail that is
## not there.
func _build_rail_cut() -> void:
	_rail_material = StandardMaterial3D.new()
	_rail_material.albedo_color = Color(0.3, 0.3, 0.3)
	_rail_material.metallic = 0.3
	_rail_material.roughness = 0.7
	var piece = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(rail_length * CALIB_QUEER, rail_height, rail_depth)
	piece.mesh = box
	piece.position = Vector3(rail_length * CALIB_QUEER * 0.5, 0, 0)
	piece.material_override = _rail_material
	add_child(_own(piece))

## WHERE THE PLATE HANGS. φ has no body — this is the bare rail at y=0 with its
## word-marks below the floor — so the plate stands behind the rail and rises from it.
## That is the only free space here, and it gives the rail the backing surface it has
## never had. lambda_slider hangs the identical plate on its lectern fascia instead;
## the mounting differs because the two bodies do, the inscription does not.
func _calibration_mount() -> Node3D:
	var mount := Node3D.new()
	mount.name = "CalibrationPlate"
	mount.position = Vector3(rail_length * 0.5, CALIB_PLATE_H * 0.5 - 0.005,
		-rail_depth * 0.62)
	add_child(_own(mount))
	return mount

## φ's numbers into the shared builder. The recommended region is
## has_queer_signature()'s, the three schools are the same three the rail flags, and
## every colour is read out of _get_phi_color(), so the plate cannot say anything the
## rail does not.
func _build_scale_plate(mode: String) -> void:
	CalibrationAxis.inscribe_scale_plate(_calibration_mount(), mode,
		rail_length, CALIB_PLATE_H, CALIB_QUEER, 1.0,
		PackedFloat32Array([CALIB_NEUTRAL_T, CALIB_APEX, CALIB_FAR]),
		PackedColorArray([_get_phi_color(CALIB_NEUTRAL_T * 2.0 - 1.0),
			_get_phi_color(CALIB_APEX * 2.0 - 1.0),
			_get_phi_color(CALIB_FAR * 2.0 - 1.0)]),
		COLOR_EMBRACE, CALIB_NEUTRAL, CALIB_PLATE)

func _calib_post(t: float, h: float, color: Color) -> void:
	_calib_box(Vector3(rail_length * t, h * 0.5, rail_depth * 0.75),
		Vector3(0.008, h, 0.008), _calib_mat(color, 0.8, 1.0))

func _calib_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	add_child(_own(CalibrationAxis.calib_box(pos, size, mat)))

func _calib_mat(color: Color, emissive_energy: float, alpha: float) -> StandardMaterial3D:
	return CalibrationAxis.calib_mat(color, emissive_energy, alpha)

## MAP CONFIG — `phi_slider#calibration:dispute`. GridInteractablesComponent calls this
## deferred, after _ready() has already built one lineage, so a word that changes
## anything has to tear its own nodes down and build again. It frees only what _own()
## recorded. A config key we do not own, or a word outside the shared allow-list,
## changes nothing at all.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("calibration"):
		return
	var before: String = calibration
	calibration = CalibrationAxis.normalise_calibration(
		str(config_data["calibration"]), calibration)
	if calibration == before or not _built:
		return
	_rebuild_calibration()
	print("PhiSlider: calibration=%s" % calibration)

func _rebuild_calibration() -> void:
	for n in _calib_nodes:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_calib_nodes.clear()
	_build_rail_and_scale()

func _build_scale_labels() -> void:
	# Resist label (φ=-1)
	var label_resist = Label3D.new()
	label_resist.text = "RESIST"
	label_resist.font_size = 24
	label_resist.pixel_size = 0.001
	label_resist.position = Vector3(0, -rail_height - 0.03, 0)
	label_resist.modulate = COLOR_RESIST
	add_child(label_resist)
	
	# Neutral label (φ=0)
	var label_neutral = Label3D.new()
	label_neutral.text = "NEUTRAL"
	label_neutral.font_size = 24
	label_neutral.pixel_size = 0.001
	label_neutral.position = Vector3(rail_length * 0.5, -rail_height - 0.03, 0)
	label_neutral.modulate = COLOR_NEUTRAL
	add_child(label_neutral)
	
	# Embrace label (φ=1)
	var label_embrace = Label3D.new()
	label_embrace.text = "EMBRACE"
	label_embrace.font_size = 24
	label_embrace.pixel_size = 0.001
	label_embrace.position = Vector3(rail_length, -rail_height - 0.03, 0)
	label_embrace.modulate = COLOR_EMBRACE
	add_child(label_embrace)

func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = 30
	_particles.lifetime = 2.0
	_particles.position = Vector3(rail_length / 2, rail_height + 0.1, 0)
	
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_mat.emission_box_extents = Vector3(rail_length / 2, 0.05, 0.05)
	particle_mat.direction = Vector3(0, 1, 0)
	particle_mat.spread = 20.0
	particle_mat.initial_velocity_min = 0.05
	particle_mat.initial_velocity_max = 0.1
	particle_mat.gravity = Vector3(0, -0.1, 0)
	particle_mat.scale_min = 0.3
	particle_mat.scale_max = 1.0
	_particles.process_material = particle_mat
	
	# Particle mesh
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.004
	particle_mesh.height = 0.008
	_particles.draw_pass_1 = particle_mesh
	
	add_child(_particles)

func _on_slider_moved(position: float) -> void:
	# Convert slider position to phi value (-1 to 1)
	phi = (position / rail_length) * 2.0 - 1.0
	
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
		_slider.slider_position = (phi + 1.0) / 2.0 * rail_length
	
	# Update handle color
	var color = _get_phi_color(phi)
	if _handle_material:
		_handle_material.albedo_color = color
		_handle_material.emission = color
	
	# Update label
	if _label:
		var sign_str = "+" if phi >= 0 else ""
		_label.text = "φ = %s%.2f" % [sign_str, phi]
		_label.modulate = color
	
	# Update particles based on phi
	if _particles and _particles.process_material:
		var particle_mat = _particles.process_material as ParticleProcessMaterial
		# Direction based on phi: negative = downward, positive = upward
		if phi >= 0:
			particle_mat.direction = Vector3(0, 1, 0)
			particle_mat.initial_velocity_max = lerp(0.05, 0.2, phi)
		else:
			particle_mat.direction = Vector3(0, -0.5, 0)
			particle_mat.initial_velocity_max = lerp(0.05, 0.1, abs(phi))
		
		# More active at extremes
		_particles.amount = int(lerp(20.0, 50.0, abs(phi)))

func _get_phi_color(value: float) -> Color:
	# Gradient: Purple (resist) → Gray (neutral) → Gold (embrace)
	if value < 0:
		# Resist to Neutral
		var t = (value + 1.0) / 1.0  # -1 to 0 → 0 to 1
		return COLOR_RESIST.lerp(COLOR_NEUTRAL, t)
	else:
		# Neutral to Embrace
		var t = value / 1.0  # 0 to 1 → 0 to 1
		return COLOR_NEUTRAL.lerp(COLOR_EMBRACE, t)

# Public API

## Set phi value programmatically
func set_phi(value: float) -> void:
	phi = value

## Get current phi value
func get_phi() -> float:
	return phi

## Move slider to specific phi value
func move_to(value: float) -> void:
	if _slider:
		_slider.move_slider((value + 1.0) / 2.0 * rail_length)

## Get description of current phi state
func get_state_description() -> String:
	if phi < -0.5:
		return "Strongly Conservative"
	elif phi < -0.1:
		return "Resists Change"
	elif phi < 0.1:
		return "Neutral"
	elif phi < 0.5:
		return "Embraces Change"
	else:
		return "Queer Signature (fully embraces becoming)"

## Check if exhibiting queer signature (positive phi)
func has_queer_signature() -> bool:
	return phi > 0.2

## Static method to find all phi sliders in scene
static func get_all_sliders() -> Array:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.get_nodes_in_group("qfep_phi_controllers")
	return []

## Static method to get global phi value (average of all sliders)
static func get_global_phi() -> float:
	var sliders = get_all_sliders()
	if sliders.is_empty():
		return 0.3  # Default
	
	var total = 0.0
	for slider in sliders:
		if slider.has_method("get_phi"):
			total += slider.get_phi()
	
	return total / sliders.size()
