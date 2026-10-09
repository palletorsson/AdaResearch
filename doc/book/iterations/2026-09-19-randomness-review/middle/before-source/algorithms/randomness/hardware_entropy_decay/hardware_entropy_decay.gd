# @identity
# essence: S_hardware = f(velocity, grip, head_rotation) — your body is the entropy source
# desire: move your hands fast, squeeze the grip, turn your head — and watch surfaces rust and corrode because of you
# critical_parameter: velocity_to_scratch — how aggressively hand speed maps to scratch intensity on the shader; disclosure — how much of the entropy's origin the rig prints on its face (oracle | tally | ledger | works | origin)
# triggers: _sample_hardware() reads XR controller velocity, grip pressure, head angular speed every frame
# emerges: a feedback loop where curiosity (moving to look) accelerates the decay you came to observe; at disclosure:oracle the same loop runs and the bay is bolted shut over it
# needs: XR controllers [has with fallback]; custom hardware_decay.gdshader [has]; VR RESET/PAUSE buttons [has]
# relationships: depends on random_decay_multimesh (conceptual); contrasts with entropy_jar (physics-based vs shader-based decay)
# truth: The observer is not separate from the system — every measurement is an intervention.

extends Node3D

## Hardware Entropy Decay
## Uses real VR hardware inputs to drive procedural surface decay:
## - Controller velocity → scratch intensity
## - Controller position → localized decay UV target
## - Grip pressure → grime buildup
## - Head angular velocity → entropy/weathering rate
## - Accumulated interaction time → overall decay progression
##
## Place in the grid and the player's own movements become the entropy source.

const DECAY_SHADER = preload("res://algorithms/randomness/hardware_entropy_decay/hardware_decay.gdshader")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02). The randomness family's ONE axis, adopted:
#
#   disclosure   oracle  <  tally  <  ledger  <  works  <  origin
#
# defined in prng_crank_machine.gd, already shared with coin_toss and
# random_number_book_page_1955. This rig's whole claim is that the entropy
# degrading these three specimens came from the player's own body — which is a
# claim about PROVENANCE, and provenance is what the family word already names.
# An artifact whose truth line is "the observer is not separate from the system"
# has exactly one interesting knob: how much of that relationship it prints.
#
#   oracle  Three specimens, visibly worn, on their columns. The service bay is
#           closed floor-to-lintel with a bolted blank plate stencilled SEALED,
#           and there is no source line. The surfaces are decaying and nothing
#           on the rig will tell you why, or by whom. Wear as a fact of nature.
#   tally   The board returns carrying the AGGREGATE only: how far gone each
#           quantity is — scratches, grime, entropy, decay — and how long it has
#           been running. The upper third of the seat, where the live inputs sat,
#           stays plated over. The damage totalled, the cause withheld.
#   ledger  + the live inputs: hand velocity, grip, head rotation, sample by
#           sample. The shutter retracts. Now you can watch a number move when
#           you move. Still nothing says what is producing those numbers.
#   works   + the source line: [ VR HARDWARE ACTIVE ] or [ SIMULATED ENTROPY ].
#           The rig names its own instrument, and admits when there is no player
#           and it is feeding on a sine wave instead. THE LEGACY RIG, byte for
#           byte — this is the default and 7 placements expect it.
#   origin  + the transfer function: a plate on the control bay printing which
#           channel drives which damage and by what coefficient, and three lit
#           channel rails running the whole length of the rig from the input bay
#           to the account bay. The rung at which "your movements become entropy"
#           stops being a wall label and becomes three multiplications you could
#           check.
#
# NOT PROMOTED, and it was the tempting one: the decay RATES. velocity_to_scratch
# and its four siblings are the artifact's most obvious parameters and they are
# invisible to a still — a rate only exists across frames, and the evidence loop
# is one PNG per variant. panel_count is not promoted either: three specimens or
# five is a quantity, not a claim.
#
# NOT TOUCHED: the shader, the sampling, the coefficients themselves. Every rung
# decays identically from identical input. This axis changes the RECORD, never
# the process it records.
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder, defined once next door. Preloaded rather than reached
## through class_name — class_name lookups are not reliable headless and every
## frame of the evidence loop is rendered headless.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

# --- Export tunables ---
@export_category("Decay Rates")
@export var velocity_to_scratch: float = 0.35        ## How much controller speed feeds scratch intensity
@export var grip_to_grime: float = 0.12              ## How fast grip accumulates grime
@export var head_to_entropy: float = 0.25            ## How head movement drives entropy
@export var passive_decay_rate: float = 0.002         ## Background decay per second
@export var interaction_decay_boost: float = 0.015    ## Extra decay when actively interacting
@export var decay_smoothing: float = 3.5              ## Lerp speed for visual smoothing

@export_category("Disclosure")
## THE AXIS — how much of the entropy's origin this rig admits. Same five rungs,
## same order, same spellings as prng_crank_machine and coin_toss. `works` is the
## legacy rig.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## The allow-list, in ladder order — the same five words the @export_enum above
## declares. What a map token is checked against.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## PIN. -1 (the default) is today's behaviour exactly: with no XR rig in the
## scene the sampler falls back to wall-clock sines, so the readouts and the
## shader's wear differ every time the artifact is instantiated and keep drifting
## for as long as it lives. Any value >= 0 replaces that clock with a fixed state
## derived from the seed and stops the accumulation, so two photographs of this
## rig can actually be compared.
##
## Nothing here calls randf — the noise is the CLOCK, which is worse, because it
## looks deterministic in the source. Without this pin a `disclosure` sweep would
## measure four different states of decay and report a bite that is entirely the
## sweep's own elapsed runtime. The DNA fixture must set it.
@export var entropy_seed: int = -1

@export_category("Display")
@export var panel_count: int = 3                      ## Number of display panels (cube, sphere, cylinder)
@export var panel_spacing: float = 1.4
@export var pedestal_height: float = 0.7
@export var show_readouts: bool = true

## Housing (cabinet grammar — see commons/data/cabinet_grammar.json).
@export var finish: String = "terminal"
@export var wear: float = 0.12
@export var unit_code: String = "HE-06"
@export var plinth_height: float = 0.0
@export var base_surface_color: Color = Color(0.65, 0.68, 0.72)
@export var rust_color: Color = Color(0.45, 0.18, 0.05)
@export var dirt_color: Color = Color(0.22, 0.18, 0.12)

# --- State ---
var _decay_amount: float = 0.0
var _scratch_intensity: float = 0.0
var _grime_buildup: float = 0.0
var _entropy_rate: float = 0.0
var _touch_uv: Vector2 = Vector2(0.5, 0.5)

# Smoothed display values (for shader)
var _display_decay: float = 0.0
var _display_scratch: float = 0.0
var _display_grime: float = 0.0
var _display_entropy: float = 0.0

# Hardware tracking
var _prev_left_pos: Vector3 = Vector3.ZERO
var _prev_right_pos: Vector3 = Vector3.ZERO
var _prev_head_basis: Basis = Basis.IDENTITY
var _left_velocity: float = 0.0
var _right_velocity: float = 0.0
var _head_angular_speed: float = 0.0
var _grip_left: float = 0.0
var _grip_right: float = 0.0
var _has_prev_frame: bool = false

# Interaction stats
var _total_scratches: float = 0.0
var _total_grime: float = 0.0
var _total_entropy: float = 0.0
var _peak_velocity: float = 0.0
var _interaction_seconds: float = 0.0

# Scene references
var _shader_materials: Array[ShaderMaterial] = []
var _display_meshes: Array[MeshInstance3D] = []
# Consolidated readout board — one panel, rebuilt (cache-guarded) only when text changes.
var _readout_anchor: Node3D            # holds the current baked text-block
var _readout_block: Node3D             # the live text-block child (freed + rebuilt on change)
var _readout_max_width: float = 0.56
var _readout_line_h: float = 0.052
var _readout_cache: String = ""        # guards rebuild: last rendered joined-lines string
var _source_anchor: Node3D             # holds the status board
var _source_cache: String = ""         # guards status rebuild
var _source_pos: Vector3 = Vector3.ZERO
var _active: bool = true
var _paused: bool = false

## Everything the AXIS owns: the readout plate and its board, the blank shutter,
## the origin plate and its channel rails. A rung change frees exactly these and
## builds them again — the specimens, the columns and the rig are not the account
## and must survive a rung change untouched.
var _axis_owned: Array[Node] = []
var _built: bool = false
## True when entropy_seed >= 0: the sampler is replaced by a fixed state.
var _pinned: bool = false


## Rank of the current rung, 0..4, read through the family's one table.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(disclosure, 3))


func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child, so the meta
	# read happens here, before any geometry exists. apply_grid_config() arrives
	# call_deferred — after this — and is a re-read, not the read.
	_read_meta_overrides()
	_build_pedestal()
	_build_display_surfaces()
	_build_title()
	if show_readouts and _rung() >= 1:
		_build_readout_panel()
	_build_vr_controls()
	_build_source_indicator()
	_build_rig()
	# APPENDED LAST so every child index and position above is untouched on the
	# legacy path. At `works` both of these add nothing at all.
	_build_disclosure_shutter()
	_build_origin_panel()
	if entropy_seed >= 0:
		_pin_state()
	_built = true


func _process(delta: float) -> void:
	if _pinned:
		return   # a pinned rig holds its state so two frames can be compared
	if _paused:
		return

	# --- Sample VR hardware ---
	_sample_hardware(delta)

	# --- Feed hardware into decay parameters ---
	var max_vel := maxf(_left_velocity, _right_velocity)
	var max_grip := maxf(_grip_left, _grip_right)

	# Scratch intensity from velocity (fast hands = scratches)
	_scratch_intensity = clampf(max_vel * velocity_to_scratch, 0.0, 1.0)

	# Grime from sustained grip (holding tight = grime accumulates)
	if max_grip > 0.3:
		_grime_buildup = clampf(_grime_buildup + max_grip * grip_to_grime * delta, 0.0, 1.0)

	# Entropy from head movement
	_entropy_rate = clampf(_head_angular_speed * head_to_entropy, 0.0, 1.0)

	# Overall decay: passive + interaction-boosted
	var interaction_active := max_vel > 0.1 or max_grip > 0.2 or _head_angular_speed > 0.05
	var decay_rate := passive_decay_rate
	if interaction_active:
		decay_rate += interaction_decay_boost
		_interaction_seconds += delta
	_decay_amount = clampf(_decay_amount + decay_rate * delta, 0.0, 1.0)

	# Touch UV from dominant controller position (mapped to 0-1 range)
	var controller_pos := _get_dominant_controller_position()
	if controller_pos != Vector3.ZERO:
		# Map controller XZ relative to artifact to UV space
		var local_pos := to_local(controller_pos)
		_touch_uv = Vector2(
			clampf(local_pos.x / 3.0 + 0.5, 0.0, 1.0),
			clampf(local_pos.z / 3.0 + 0.5, 0.0, 1.0)
		)

	# --- Accumulate stats ---
	_total_scratches += _scratch_intensity * delta
	_total_grime = _grime_buildup
	_total_entropy += _entropy_rate * delta
	_peak_velocity = maxf(_peak_velocity, max_vel)

	# --- Smooth display values ---
	_display_decay = lerpf(_display_decay, _decay_amount, delta * decay_smoothing)
	_display_scratch = lerpf(_display_scratch, _scratch_intensity, delta * decay_smoothing * 2.0)
	_display_grime = lerpf(_display_grime, _grime_buildup, delta * decay_smoothing)
	_display_entropy = lerpf(_display_entropy, _entropy_rate, delta * decay_smoothing * 2.0)

	# --- Push to shader ---
	for mat in _shader_materials:
		mat.set_shader_parameter("decay_amount", _display_decay)
		mat.set_shader_parameter("scratch_intensity", _display_scratch)
		mat.set_shader_parameter("grime_buildup", _display_grime)
		mat.set_shader_parameter("entropy_rate", _display_entropy)
		mat.set_shader_parameter("touch_uv", _touch_uv)

	# --- Update readouts ---
	if show_readouts:
		_update_readouts()


# ============================================================
# HARDWARE SAMPLING
# ============================================================

func _sample_hardware(delta: float) -> void:
	# Find XR controllers and camera
	var xr_origin := _find_xr_origin()
	if xr_origin == null:
		# Fallback: use mouse/keyboard entropy
		_sample_fallback(delta)
		return

	# Left controller
	var left := _find_controller(xr_origin, "LeftHand")
	if left:
		var pos := left.global_position
		if _has_prev_frame:
			_left_velocity = pos.distance_to(_prev_left_pos) / maxf(delta, 0.001)
		_prev_left_pos = pos
		# Read grip action
		if left is XRController3D:
			_grip_left = (left as XRController3D).get_float("grip")

	# Right controller
	var right := _find_controller(xr_origin, "RightHand")
	if right:
		var pos := right.global_position
		if _has_prev_frame:
			_right_velocity = pos.distance_to(_prev_right_pos) / maxf(delta, 0.001)
		_prev_right_pos = pos
		if right is XRController3D:
			_grip_right = (right as XRController3D).get_float("grip")

	# Head tracking (XRCamera3D)
	var camera := _find_xr_camera(xr_origin)
	if camera:
		var current_basis := camera.global_transform.basis
		if _has_prev_frame:
			var rotation_diff := (_prev_head_basis.inverse() * current_basis).get_euler()
			_head_angular_speed = rotation_diff.length() / maxf(delta, 0.001)
		_prev_head_basis = current_basis

	_has_prev_frame = true


func _sample_fallback(delta: float) -> void:
	# Non-VR fallback: use time-based noise and mouse position
	var t := Time.get_ticks_msec() / 1000.0
	_left_velocity = absf(sin(t * 1.3)) * 0.5
	_right_velocity = absf(cos(t * 0.9)) * 0.4
	_head_angular_speed = absf(sin(t * 0.7)) * 0.3
	_grip_left = (sin(t * 0.5) + 1.0) * 0.25
	_grip_right = (cos(t * 0.4) + 1.0) * 0.25
	_has_prev_frame = true


func _find_xr_origin() -> XROrigin3D:
	# Walk up tree to find XROrigin3D
	var node := get_parent()
	while node:
		if node is XROrigin3D:
			return node as XROrigin3D
		# Search children of root for XROrigin3D
		for child in node.get_children():
			if child is XROrigin3D:
				return child as XROrigin3D
		node = node.get_parent()

	# Broader search from scene root
	var root := get_tree().root
	return _find_child_of_type(root, "XROrigin3D") as XROrigin3D


func _find_controller(origin: XROrigin3D, name_hint: String) -> Node3D:
	for child in origin.get_children():
		if child is XRController3D:
			if name_hint.to_lower() in child.name.to_lower():
				return child
	# Deeper search
	for child in origin.get_children():
		var found := _find_child_of_type(child, "XRController3D")
		if found and name_hint.to_lower() in found.name.to_lower():
			return found as Node3D
	return null


func _find_xr_camera(origin: XROrigin3D) -> XRCamera3D:
	for child in origin.get_children():
		if child is XRCamera3D:
			return child as XRCamera3D
	return _find_child_of_type(origin, "XRCamera3D") as XRCamera3D


func _find_child_of_type(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.get_class() == type_name:
			return child
		var found := _find_child_of_type(child, type_name)
		if found:
			return found
	return null


func _get_dominant_controller_position() -> Vector3:
	# Return position of the controller with higher velocity
	var xr_origin := _find_xr_origin()
	if xr_origin == null:
		return Vector3.ZERO

	var right := _find_controller(xr_origin, "RightHand")
	var left := _find_controller(xr_origin, "LeftHand")

	if right and _right_velocity >= _left_velocity:
		return right.global_position
	elif left:
		return left.global_position
	return Vector3.ZERO


# ============================================================
# KEYBOARD INPUT (fallback + direct control)
# ============================================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_paused = not _paused
	elif event.is_action_pressed("ui_home"):
		_reset()


# ============================================================
# BUILD SCENE
# ============================================================

func _build_pedestal() -> void:
	# A slim spine strip UNDER the specimen columns only — the rig's own canon
	# plinth (_build_rig) supplies the base that meets the floor. The old full
	# 1.8m-deep slab jutted ~0.9m forward of the body and doubled the base read.
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	var total_width := float(panel_count) * panel_spacing + 0.4
	base_mesh.size = Vector3(total_width, 0.05, 0.30)
	base.mesh = base_mesh
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.09, 0.09, 0.105)
	base_mat.metallic = 0.3
	base_mat.roughness = 0.7
	base.material_override = base_mat
	base.position = Vector3(0, 0.03, -0.34)   # align with the rig plinth (back_z + 0.08)
	add_child(base)


func _build_display_surfaces() -> void:
	var shapes: Array[Mesh] = []

	# Create diverse meshes to show decay on different geometries
	if panel_count >= 1:
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 0.8, 0.8)
		shapes.append(box)

	if panel_count >= 2:
		var sphere := SphereMesh.new()
		sphere.radius = 0.45
		sphere.height = 0.9
		sphere.radial_segments = 48
		sphere.rings = 24
		shapes.append(sphere)

	if panel_count >= 3:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.35
		cylinder.bottom_radius = 0.35
		cylinder.height = 0.9
		cylinder.radial_segments = 36
		shapes.append(cylinder)

	# Add extra shapes if more panels requested
	if panel_count >= 4:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.15
		torus.outer_radius = 0.4
		shapes.append(torus)

	if panel_count >= 5:
		var prism := PrismMesh.new()
		prism.size = Vector3(0.7, 0.8, 0.7)
		shapes.append(prism)

	var start_x := -float(shapes.size() - 1) * panel_spacing * 0.5

	for i in range(shapes.size()):
		# Pedestal column
		var column := MeshInstance3D.new()
		var col_mesh := CylinderMesh.new()
		col_mesh.top_radius = 0.15
		col_mesh.bottom_radius = 0.18
		col_mesh.height = pedestal_height
		column.mesh = col_mesh
		var col_mat := StandardMaterial3D.new()
		col_mat.albedo_color = Color(0.18, 0.18, 0.2)
		col_mat.metallic = 0.5
		col_mat.roughness = 0.6
		column.material_override = col_mat
		column.position = Vector3(start_x + i * panel_spacing, pedestal_height * 0.5 + 0.06, 0)
		add_child(column)

		# Display object with decay shader
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "DecaySurface_%d" % i
		mesh_inst.mesh = shapes[i]

		var shader_mat := ShaderMaterial.new()
		shader_mat.shader = DECAY_SHADER
		shader_mat.set_shader_parameter("base_color", Vector3(base_surface_color.r, base_surface_color.g, base_surface_color.b))
		shader_mat.set_shader_parameter("rust_color", Vector3(rust_color.r, rust_color.g, rust_color.b))
		shader_mat.set_shader_parameter("dirt_color", Vector3(dirt_color.r, dirt_color.g, dirt_color.b))
		mesh_inst.material_override = shader_mat

		mesh_inst.position = Vector3(start_x + i * panel_spacing, pedestal_height + 0.5, 0)
		add_child(mesh_inst)

		_shader_materials.append(shader_mat)
		_display_meshes.append(mesh_inst)

		# Slow rotation for visual interest
		var spinner := Node3D.new()
		spinner.name = "Spinner_%d" % i
		spinner.set_meta("speed", 0.15 + i * 0.08)
		spinner.set_meta("mesh", mesh_inst)
		add_child(spinner)

	# Start rotation in process
	set_process(true)


func _build_title() -> void:
	# Title board — integrated 2D-in-3D tag, painted onto its own face.
	var title: Node3D = BakedText.make_tag(
		"HARDWARE ENTROPY DECAY",
		Color(0.95, 0.85, 0.65), 0.13,
		Color(0.10, 0.06, 0.03), false,
		Color(0.86, 0.40, 0.16))
	if title:
		title.name = "FloatTitle"
		title.position = Vector3(0, pedestal_height + 1.55, 0)
		add_child(title)

	# Subtitle board — spaced below the title so the two never overlap.
	var subtitle := BakedText.make_tag(
		"Your VR movements become entropy",
		Color(0.72, 0.72, 0.78), 0.06,
		Color(0.06, 0.06, 0.08), false,
		Color(0, 0, 0, 0))
	if subtitle:
		subtitle.name = "FloatSub"
		subtitle.position = Vector3(0, pedestal_height + 1.36, 0)
		add_child(subtitle)


func _build_readout_panel() -> void:
	# One consolidated readout panel to the right — header + all 8 live readouts +
	# stats summary render onto a SINGLE surface (make_text_block), so nothing floats
	# free and nothing overlaps. The backing plate frames the whole board.
	var panel_x := float(panel_count) * panel_spacing * 0.5 + 0.85
	var panel_cy := pedestal_height + 0.65   # vertical centre of the board

	# Opaque backing plate — one plate behind the whole readout column.
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.68, 0.98, 0.02)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.04, 0.04, 0.06)
	back_mat.metallic = 0.2
	back_mat.roughness = 0.6
	back.material_override = back_mat
	back.position = Vector3(panel_x, panel_cy, -0.012)
	add_child(back)
	_axis_owned.append(back)

	# Anchor for the live baked text-block, sitting just in front of the plate.
	_readout_anchor = Node3D.new()
	_readout_anchor.name = "ReadoutBlock"
	_readout_anchor.position = Vector3(panel_x, panel_cy, 0.004)
	add_child(_readout_anchor)
	_axis_owned.append(_readout_anchor)

	# Seed with a placeholder so the board reads before the first update.
	_rebuild_readout_block([
		"HARDWARE INPUTS", "",
		"VELOCITY   ---", "GRIP       ---", "HEAD ROT   ---",
		"SCRATCHES  ---", "GRIME      ---", "ENTROPY    ---",
		"DECAY      ---", "TIME       ---", "",
		"Peak ---  Total ---",
	])


func _build_source_indicator() -> void:
	# Small status board showing whether we're reading real VR or fallback.
	# Held in its own anchor, spaced below the subtitle; rebuilt only on change.
	# re-homed onto the service bay by _build_rig (the cabinet grammar: no
	# text outside the body). Seeded here so the anchor exists first.
	_source_pos = Vector3(0, pedestal_height + 1.21, 0)
	_source_anchor = Node3D.new()
	_source_anchor.name = "SourceIndicator"
	_source_anchor.position = _source_pos
	add_child(_source_anchor)
	_update_source_indicator()


func _build_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("ENTROPY DECAY", [
		[
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "PAUSE"},
		],
	])
	var panel_x := -float(panel_count) * panel_spacing * 0.5 - 0.8
	panel.position = Vector3(panel_x, pedestal_height + 0.345, -0.13)
	panel.rotation_degrees = Vector3(-15, 0, 0)
	panel.rotation_degrees = Vector3(-25, 20, 0)
	add_child(panel)

	# RESET button (Btn_0)
	var reset_btn: Node = panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset())

	# PAUSE button (Btn_1)
	var pause_btn: Node = panel.find_child("Btn_1", true, false)
	if pause_btn:
		var area = pause_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b):
				_paused = not _paused
				_update_source_indicator()
			)


# ============================================================
# UPDATES
# ============================================================

# Rebuild the consolidated readout board from a fresh set of lines. Cache-guarded
# by the caller (see _update_readouts) so the block is only re-baked when the text
# actually changes — BakedText itself also caches per-line textures.
func _rebuild_readout_block(lines: Array) -> void:
	if _readout_anchor == null:
		return
	if is_instance_valid(_readout_block):
		_readout_block.queue_free()
	_readout_block = BakedText.make_text_block(
		lines, Color(0.72, 0.86, 0.74),
		_readout_line_h, _readout_max_width, 0.014, true)
	if _readout_block:
		_readout_anchor.add_child(_readout_block)


func _update_readouts() -> void:
	if _readout_anchor == null:
		return                     # disclosure:oracle — there is no board to write on
	var max_vel := maxf(_left_velocity, _right_velocity)
	var max_grip := maxf(_grip_left, _grip_right)

	# disclosure:tally — the three LIVE INPUT rows are withheld. They are blanked
	# rather than removed: make_text_block skips an empty line without closing the
	# gap, so every surviving row keeps the exact y it has on the legacy board and
	# the tile difference is "these three rows are gone", not "the board reflowed".
	# The shutter is built over precisely that band.
	var live: bool = _rung() >= 2
	var lines := [
		"HARDWARE INPUTS" if live else "", "",
		("VELOCITY   %.2f m/s" % max_vel) if live else "",
		("GRIP       %.0f%%" % (max_grip * 100.0)) if live else "",
		("HEAD ROT   %.2f r/s" % _head_angular_speed) if live else "",
		"SCRATCHES  %.0f%%" % (_display_scratch * 100.0),
		"GRIME      %.0f%%" % (_display_grime * 100.0),
		"ENTROPY    %.0f%%" % (_display_entropy * 100.0),
		"DECAY      %.0f%%" % (_display_decay * 100.0),
		"TIME       %.0fs" % _interaction_seconds, "",
		"Peak %.1f  Total %.1f" % [_peak_velocity, _total_scratches],
	]
	var joined := "\n".join(PackedStringArray(lines))
	if joined == _readout_cache:
		return   # nothing changed — skip the rebuild
	_readout_cache = joined
	_rebuild_readout_block(lines)


func _update_source_indicator() -> void:
	if _source_anchor == null:
		return
	if _rung() < 3:
		# disclosure:oracle|tally|ledger — the rig does not name its instrument.
		# The anchor stays (the bay seat is still there); the board on it does not.
		for child in _source_anchor.get_children():
			child.queue_free()
		_source_cache = ""
		return

	var txt := ""
	var col := Color.WHITE
	var accent := Color(0.86, 0.40, 0.16)
	if _paused:
		txt = "[ PAUSED ]"
		col = Color(1.0, 0.55, 0.25)
		accent = Color(1.0, 0.55, 0.2)
	else:
		var xr_origin := _find_xr_origin()
		if xr_origin:
			txt = "[ VR HARDWARE ACTIVE ]"
			col = Color(0.4, 1.0, 0.5)
			accent = Color(0.2, 0.9, 0.35)
		else:
			txt = "[ SIMULATED ENTROPY ]"
			col = Color(0.7, 0.7, 0.85)
			accent = Color(0.4, 0.45, 0.7)

	if txt == _source_cache:
		return
	_source_cache = txt

	for child in _source_anchor.get_children():
		child.queue_free()
	var board := BakedText.make_tag(txt, col, 0.05, Color(0.05, 0.06, 0.08), false, accent)
	if board:
		_source_anchor.add_child(board)


func _reset() -> void:
	_decay_amount = 0.0
	_scratch_intensity = 0.0
	_grime_buildup = 0.0
	_entropy_rate = 0.0
	_display_decay = 0.0
	_display_scratch = 0.0
	_display_grime = 0.0
	_display_entropy = 0.0
	_total_scratches = 0.0
	_total_grime = 0.0
	_total_entropy = 0.0
	_peak_velocity = 0.0
	_interaction_seconds = 0.0
	_paused = false

	for mat in _shader_materials:
		mat.set_shader_parameter("decay_amount", 0.0)
		mat.set_shader_parameter("scratch_intensity", 0.0)
		mat.set_shader_parameter("grime_buildup", 0.0)
		mat.set_shader_parameter("entropy_rate", 0.0)

	_update_source_indicator()


# Gentle spin of display objects
var _spin_time: float = 0.0

func _physics_process(delta: float) -> void:
	if _pinned:
		return   # the specimens hold their pose too, or the pin is only half a pin
	if _paused:
		return
	_spin_time += delta
	for i in range(_display_meshes.size()):
		var mesh := _display_meshes[i]
		var speed := 0.15 + i * 0.08
		mesh.rotation.y = _spin_time * speed
		# Gentle bob
		mesh.position.y = pedestal_height + 0.5 + sin(_spin_time * 0.5 + i * 1.2) * 0.03

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG PAID (2026-08-02): this was `pass`. GridInteractablesComponent parsed
## every `#token: value` on a hardware_entropy_decay placement, logged it, stashed it
## as metadata and then nothing on this artifact ever read it back — so any map that
## tried to configure this rig was configuring nothing, silently. It reads its
## metadata now. The grid sets that metadata BEFORE add_child and calls this method
## deferred, so _ready does the read that decides geometry; this is the re-read.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var before: String = disclosure
	_read_meta_overrides()
	if _built and disclosure != before:
		_rebuild_axis()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		disclosure = Disclosure.disclosure_name(str(get_meta("config_disclosure")))
	if has_meta("config_entropy_seed"):
		entropy_seed = int(str(get_meta("config_entropy_seed")))


## Free and rebuild EXACTLY what the axis owns. Called only when the rung actually
## changed, so a config that carries no disclosure key never disturbs a rig that is
## already standing (an unconditional rebuild here would free the readout board of
## every placement that passes any token at all).
func _rebuild_axis() -> void:
	for n in _axis_owned:
		if is_instance_valid(n):
			n.queue_free()
	_axis_owned.clear()
	_readout_anchor = null
	_readout_block = null
	_readout_cache = ""
	if show_readouts and _rung() >= 1:
		_build_readout_panel()
	_build_disclosure_shutter()
	_build_origin_panel()
	_source_cache = ""
	_update_source_indicator()
	if show_readouts and _rung() >= 1:
		_update_readouts()


## A fixed, reproducible state of wear. Reachable ONLY through entropy_seed >= 0,
## so no shipped placement can enter it. The numbers are a plain hash of the seed
## into 0..1 — arbitrary, but identical for identical seeds, which is the whole
## requirement. _process and _physics_process return immediately in this mode, so
## nothing drifts and nothing spins between one variant's frame and the next.
func _pin_state() -> void:
	_pinned = true
	var s: float = float(absi(entropy_seed) % 1000) / 1000.0
	_decay_amount = 0.20 + s * 0.45
	_scratch_intensity = 0.30 + s * 0.40
	_grime_buildup = 0.25 + s * 0.45
	_entropy_rate = 0.15 + s * 0.50
	_display_decay = _decay_amount
	_display_scratch = _scratch_intensity
	_display_grime = _grime_buildup
	_display_entropy = _entropy_rate
	_left_velocity = 0.8 + s
	_right_velocity = 0.5 + s * 0.5
	_head_angular_speed = 0.3 + s * 0.4
	_grip_left = s
	_grip_right = s * 0.7
	_total_scratches = 2.0 + s * 3.0
	_peak_velocity = 1.5 + s
	_interaction_seconds = 30.0 + s * 60.0
	for mat in _shader_materials:
		mat.set_shader_parameter("decay_amount", _display_decay)
		mat.set_shader_parameter("scratch_intensity", _display_scratch)
		mat.set_shader_parameter("grime_buildup", _display_grime)
		mat.set_shader_parameter("entropy_rate", _display_entropy)
		mat.set_shader_parameter("touch_uv", _touch_uv)
		# AND THE SHADER'S OWN CLOCK. hardware_decay.gdshader offsets both fbm
		# fields by TIME * time_drift, so the specimens — the three largest bright
		# objects in any frame of this rig — keep crawling even with every uniform
		# above frozen. Five variants captured 1.2 s apart in one boot would each
		# carry a different surface, and that difference would be scored as the
		# disclosure axis. Zero stops the crawl; it is reachable only through the
		# pin, so no placement ever sees a still surface.
		mat.set_shader_parameter("time_drift", 0.0)
	if show_readouts:
		_update_readouts()
	_update_source_indicator()


# ── DISCLOSURE GEOMETRY ──────────────────────────────────────────────────────
# Two builders, both no-ops at the legacy rung. The shutter SUBTRACTS (it plates
# over the service bay below `ledger`); the origin plate ADDS (above `works`).
# Neither touches the specimens, the columns, the shader or the sampling.

## The service-bay shutter. A bolted blank plate hung in front of the readout
## seat, sized to exactly the rows the rung withholds.
##
##   oracle  floor-to-lintel: the account is not merely absent, it is covered,
##           and the cover is stencilled. This is the whole right-hand bay of the
##           rig — the largest single surface change the artifact can make.
##   tally   the top of the seat only, down to the last withheld input row, so
##           the aggregate below it stays readable.
func _build_disclosure_shutter() -> void:
	var r: int = _rung()
	if r >= 2:
		return                                    # ledger and above: the seat is open
	var span: float = float(panel_count) * panel_spacing
	var readout_x: float = span * 0.5 + 0.85
	var panel_cy: float = pedestal_height + 0.65
	var top: float = panel_cy + 0.52
	# The last withheld text row (HEAD ROT, index 4) plus half a line of margin.
	# Line i sits at panel_cy + 0.370 - 0.066 * i — see BakedText.make_text_block.
	var bottom: float = panel_cy + 0.370 - 0.066 * 4.0 - 0.033
	var label: String = "AGGREGATE"
	if r == 0:
		bottom = 0.15                             # down to the plinth: the bay is sealed
		label = "SEALED"
	var h: float = maxf(top - bottom, 0.05)
	var cy: float = (top + bottom) * 0.5

	var node := Node3D.new()
	node.name = "DisclosureShutter"
	add_child(node)
	_axis_owned.append(node)

	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_panel: Color = pal["panel"]
	var plate: StandardMaterial3D = HangarKit.painted_metal(Color(0.13, 0.13, 0.15), 0.5, 0.45, 0.6)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	node.add_child(HangarKit.box(Vector3(readout_x, cy, 0.055), Vector3(0.80, h, 0.035), plate))
	# A lintel rail across the top — the shutter reads as DRAWN, not as a missing part.
	node.add_child(HangarKit.box(Vector3(readout_x, top + 0.02, 0.062), Vector3(0.84, 0.05, 0.05), steel))
	# Bolt rows down both edges.
	for sx in [-0.36, 0.36]:
		node.add_child(HangarKit.bolts(
			Vector3(readout_x + sx, bottom + 0.06, 0.075),
			Vector3(readout_x + sx, top - 0.06, 0.075),
			maxi(int(h / 0.22), 2), 0.014, steel))
	var q: MeshInstance3D = HangarKit.stencil(label, Vector2(0.34, 0.055))
	if q:
		q.position = Vector3(readout_x, minf(top - 0.10, cy + h * 0.5 - 0.10), 0.08)
		node.add_child(q)


## disclosure:origin — the transfer function, printed and drawn.
##
## A plate on the CONTROL bay (the input end of the rig) carrying the three
## coefficients and the passive rate, plus three lit channel rails running the
## whole width of the body from that bay to the service bay: input on the left,
## account on the right, and the path between them made a physical object. This
## is the rung at which the wall label "your VR movements become entropy" becomes
## three multiplications a visitor could check against the readout.
func _build_origin_panel() -> void:
	if _rung() < 4:
		return
	var span: float = float(panel_count) * panel_spacing
	var readout_x: float = span * 0.5 + 0.85
	var control_x: float = -span * 0.5 - 0.8
	var left: float = control_x - 0.42
	var right: float = readout_x + 0.42
	var body_top: float = pedestal_height + 0.96

	var node := Node3D.new()
	node.name = "OriginPanel"
	add_child(node)
	_axis_owned.append(node)

	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_panel: Color = pal["panel"]
	var face: StandardMaterial3D = HangarKit.painted_metal(Color(0.05, 0.055, 0.07), 0.35, 0.2, 0.55)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)

	# The plate, seated on the open face of the control bay above the keypad wedge.
	var plate_cy: float = body_top - 0.21
	node.add_child(HangarKit.box(Vector3(control_x, plate_cy, -0.185), Vector3(0.78, 0.44, 0.02),
		HangarKit.painted_metal(col_panel, 0.3)))
	node.add_child(HangarKit.box(Vector3(control_x, plate_cy, -0.175), Vector3(0.72, 0.38, 0.012), face))
	node.add_child(HangarKit.bolts(
		Vector3(control_x - 0.36, plate_cy - 0.19, -0.168),
		Vector3(control_x + 0.36, plate_cy - 0.19, -0.168), 4, 0.013, steel))

	var block: Node3D = BakedText.make_text_block([
		"TRANSFER",
		"VEL  x%.2f -> SCRATCH" % velocity_to_scratch,
		"GRIP x%.2f -> GRIME" % grip_to_grime,
		"HEAD x%.2f -> ENTROPY" % head_to_entropy,
		"IDLE  %.3f /s" % passive_decay_rate,
	], Color(0.72, 0.86, 0.74), 0.046, 0.62, 0.012, true)
	if block:
		block.position = Vector3(control_x, plate_cy, -0.166)
		node.add_child(block)

	# The three channels, drawn the full length of the body: input bay -> account
	# bay, passing the front of every mullion. One colour per channel, matching the
	# order printed on the plate above.
	var rail_cols: Array[Color] = [Color(0.62, 0.80, 1.00), Color(0.80, 0.62, 0.30), Color(1.00, 0.46, 0.18)]
	var rail_x0: float = left + 0.12
	var rail_x1: float = right - 0.12
	for i in range(3):
		var ry: float = 0.30 + float(i) * 0.085
		node.add_child(HangarKit.box(
			Vector3((rail_x0 + rail_x1) * 0.5, ry, -0.19),
			Vector3(rail_x1 - rail_x0, 0.045, 0.045),
			HangarKit.emissive(rail_cols[i], 1.9)))
		# A collar at each end so the rail reads as PLUGGED IN at both bays.
		for cx2 in [rail_x0, rail_x1]:
			node.add_child(HangarKit.box(Vector3(cx2, ry, -0.19), Vector3(0.07, 0.09, 0.09), steel))
	var code: MeshInstance3D = HangarKit.stencil("CHANNELS", Vector2(0.30, 0.05))
	if code:
		code.position = Vector3(control_x + 0.55, 0.56, -0.17)
		node.add_child(code)


## THE THREE-BAY RIG — the cabinet grammar in its widest vertical body.
## Three decaying specimens each get a BAY of one continuous back slab,
## divided by mullions; the readout takes a service bay on the right; the
## name moves from air into a sign band; a plinth closes the base.
func _build_rig() -> void:
	var span: float = float(panel_count) * panel_spacing
	var start_x: float = -(span - panel_spacing) * 0.5
	var readout_x: float = span * 0.5 + 0.85
	var control_x: float = -span * 0.5 - 0.8      # matches _build_vr_controls
	var left: float = control_x - 0.42
	var right: float = readout_x + 0.42
	var total_w: float = right - left
	var cx: float = (left + right) * 0.5
	var body_top: float = pedestal_height + 0.96
	var cap_h: float = 0.14
	var back_z: float = -0.42

	var rig := Node3D.new()
	rig.name = "Cabinet"
	add_child(rig)

	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# back slab + maroon flank + mullions between the bays
	rig.add_child(HangarKit.box(Vector3(cx, body_top * 0.5, back_z),
		Vector3(total_w, body_top, 0.06), shell))
	rig.add_child(HangarKit.box(Vector3(left + 0.05, body_top * 0.5, back_z + 0.06),
		Vector3(0.10, body_top, 0.20), maroon))
	for i in range(panel_count + 1):
		var mx: float = start_x - panel_spacing * 0.5 + float(i) * panel_spacing
		rig.add_child(HangarKit.box(Vector3(mx, body_top * 0.5, back_z + 0.07),
			Vector3(0.05, body_top, 0.16), shell))
		rig.add_child(HangarKit.bolts(
			Vector3(mx, 0.22, back_z + 0.16),
			Vector3(mx, body_top - 0.16, back_z + 0.16), 6, 0.008, steel))

	# control bay (left) — the pad's own bay, mirroring the service bay
	rig.add_child(HangarKit.box(Vector3(control_x, body_top * 0.5, back_z + 0.10),
		Vector3(0.80, body_top, 0.22), shell))
	rig.add_child(HangarKit.wedge(0.52, 0.26, 0.13, 0.035, dark))
	var w_node: Node = rig.get_child(rig.get_child_count() - 1)
	(w_node as Node3D).position = Vector3(control_x, pedestal_height + 0.30, back_z + 0.212)

	# service bay behind the readout column
	rig.add_child(HangarKit.box(Vector3(readout_x, body_top * 0.5, back_z + 0.10),
		Vector3(0.80, body_top, 0.22), shell))
	for gi in range(6):
		rig.add_child(HangarKit.box(
			Vector3(readout_x, 0.24 + float(gi) * 0.030, back_z + 0.215),
			Vector3(0.52, 0.012, 0.014), dark))
	var bar: Node3D = HangarKit.three_color_bar(0.46, 0.020)
	if bar:
		bar.position = Vector3(readout_x, pedestal_height + 0.06, back_z + 0.215)
		rig.add_child(bar)

	# the source indicator is text too — seat it on the service bay
	if _source_anchor != null and is_instance_valid(_source_anchor):
		_source_pos = Vector3(readout_x, pedestal_height - 0.10, back_z + 0.222)
		_source_anchor.position = _source_pos

	# retire the floating name — the sign band owns it now
	for n in ["FloatTitle", "FloatSub"]:
		var f: Node = get_node_or_null(n)
		if f != null:
			f.queue_free()

	# sign cap over a full-width ember line
	rig.add_child(HangarKit.box(Vector3(cx, body_top + cap_h * 0.5, back_z + 0.02),
		Vector3(total_w + 0.10, cap_h, 0.24), shell))
	rig.add_child(HangarKit.box(Vector3(cx, body_top + 0.006, back_z + 0.145),
		Vector3(total_w + 0.10, 0.008, 0.005), accent))
	rig.add_child(HangarKit.box(Vector3(cx, body_top + cap_h * 0.5, back_z + 0.142),
		Vector3(total_w - 0.12, 0.095, 0.014), dark))
	var sign_title: Node3D = BakedText.make_tag(
		"HARDWARE ENTROPY DECAY", Color(0.93, 0.94, 0.97), 0.038,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(cx, body_top + cap_h * 0.5 + 0.016, back_z + 0.152)
		rig.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"WEAR IS INFORMATION - THE SURFACE REMEMBERS", Color(0.55, 0.58, 0.66), 0.017,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(cx, body_top + cap_h * 0.5 - 0.026, back_z + 0.152)
		rig.add_child(sign_sub)

	# asset code + grime at the foot
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.14, 0.034),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(left + 0.22, 0.20, back_z + 0.165)
		rig.add_child(code)
	var gb: MeshInstance3D = HangarKit.grime_band(total_w * 0.9, 0.06, back_z + 0.162, col_body)
	if gb:
		gb.position.x = cx
		rig.add_child(gb)

	# plinth strip under the whole rig, and feet
	rig.add_child(HangarKit.box(Vector3(cx, 0.055, back_z + 0.08),
		Vector3(total_w, 0.11, 0.30), dark))
	var ped: Node3D = HangarKit.plinth(total_w, 0.30, plinth_height, finish, ew,
		col_accent, unit_code)
	if ped:
		ped.position = Vector3(cx, 0.0, back_z + 0.08)
		rig.add_child(ped)
