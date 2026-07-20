# @identity
# essence: S_hardware = f(velocity, grip, head_rotation) — your body is the entropy source
# desire: move your hands fast, squeeze the grip, turn your head — and watch surfaces rust and corrode because of you
# critical_parameter: velocity_to_scratch — how aggressively hand speed maps to scratch intensity on the shader
# triggers: _sample_hardware() reads XR controller velocity, grip pressure, head angular speed every frame
# emerges: a feedback loop where curiosity (moving to look) accelerates the decay you came to observe
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

# --- Export tunables ---
@export_category("Decay Rates")
@export var velocity_to_scratch: float = 0.35        ## How much controller speed feeds scratch intensity
@export var grip_to_grime: float = 0.12              ## How fast grip accumulates grime
@export var head_to_entropy: float = 0.25            ## How head movement drives entropy
@export var passive_decay_rate: float = 0.002         ## Background decay per second
@export var interaction_decay_boost: float = 0.015    ## Extra decay when actively interacting
@export var decay_smoothing: float = 3.5              ## Lerp speed for visual smoothing

@export_category("Display")
@export var panel_count: int = 3                      ## Number of display panels (cube, sphere, cylinder)
@export var panel_spacing: float = 1.4
@export var pedestal_height: float = 0.7
@export var show_readouts: bool = true

## Housing (cabinet grammar — see commons/data/cabinet_grammar.json).
@export var finish: String = "rams"
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


func _ready() -> void:
	_build_pedestal()
	_build_display_surfaces()
	_build_title()
	if show_readouts:
		_build_readout_panel()
	_build_vr_controls()
	_build_source_indicator()
	_build_rig()


func _process(delta: float) -> void:
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
	# Low platform base
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	var total_width := float(panel_count) * panel_spacing + 0.6
	base_mesh.size = Vector3(total_width, 0.06, 1.8)
	base.mesh = base_mesh
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.12, 0.12, 0.14)
	base_mat.metallic = 0.3
	base_mat.roughness = 0.7
	base.material_override = base_mat
	base.position = Vector3(0, 0.03, 0)
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

	# Anchor for the live baked text-block, sitting just in front of the plate.
	_readout_anchor = Node3D.new()
	_readout_anchor.name = "ReadoutBlock"
	_readout_anchor.position = Vector3(panel_x, panel_cy, 0.004)
	add_child(_readout_anchor)

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
	var max_vel := maxf(_left_velocity, _right_velocity)
	var max_grip := maxf(_grip_left, _grip_right)

	# Compose all readouts as lines on ONE surface. Values quantised so tiny
	# per-frame jitter doesn't force a rebuild every frame (cache guard below).
	var lines := [
		"HARDWARE INPUTS", "",
		"VELOCITY   %.2f m/s" % max_vel,
		"GRIP       %.0f%%" % (max_grip * 100.0),
		"HEAD ROT   %.2f r/s" % _head_angular_speed,
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


func apply_grid_config(config: Dictionary) -> void:
	pass


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
