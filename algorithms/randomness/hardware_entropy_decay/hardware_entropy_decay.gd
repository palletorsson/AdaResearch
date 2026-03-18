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

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const DECAY_SHADER = preload("res://algorithms/randomness/hardware_entropy_decay/hardware_decay.gdshader")

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
var _readout_labels: Array[Label3D] = []
var _title_label: Label3D
var _stats_label: Label3D
var _source_label: Label3D
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
	_title_label = Label3D.new()
	_title_label.text = "HARDWARE ENTROPY DECAY"
	_title_label.font_size = 48
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, pedestal_height + 1.45, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.95, 0.85, 0.65)
	_title_label.outline_size = 6
	_title_label.outline_modulate = Color(0.2, 0.1, 0.05)
	add_child(_title_label)

	var subtitle := Label3D.new()
	subtitle.text = "Your VR movements become entropy"
	subtitle.font_size = 24
	subtitle.pixel_size = 0.001
	subtitle.position = Vector3(0, pedestal_height + 1.3, 0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.7, 0.75)
	add_child(subtitle)


func _build_readout_panel() -> void:
	# Stats display panel (floating to the right)
	var panel_x := float(panel_count) * panel_spacing * 0.5 + 0.8
	var panel_y := pedestal_height + 0.2

	# Panel backing
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.65, 0.9, 0.015)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.04, 0.04, 0.06)
	back_mat.metallic = 0.2
	back.material_override = back_mat
	back.position = Vector3(panel_x, panel_y + 0.45, -0.01)
	add_child(back)

	# Readout header
	var header := Label3D.new()
	header.text = "HARDWARE INPUTS"
	header.font_size = 18
	header.pixel_size = 0.001
	header.position = Vector3(panel_x, panel_y + 0.85, 0)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.modulate = Color(0.3, 1.0, 0.4)
	add_child(header)

	# Create individual readout lines
	var labels_text := [
		"VELOCITY",
		"GRIP",
		"HEAD ROT",
		"SCRATCHES",
		"GRIME",
		"ENTROPY",
		"DECAY",
		"TIME"
	]

	for i in range(labels_text.size()):
		var lbl := Label3D.new()
		lbl.name = "Readout_%d" % i
		lbl.text = "%s: ---" % labels_text[i]
		lbl.font_size = 12
		lbl.pixel_size = 0.001
		lbl.position = Vector3(panel_x - 0.28, panel_y + 0.72 - i * 0.1, 0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.modulate = Color(0.7, 0.8, 0.7)
		add_child(lbl)
		_readout_labels.append(lbl)

	# Stats label (below readouts)
	_stats_label = Label3D.new()
	_stats_label.text = ""
	_stats_label.font_size = 10
	_stats_label.pixel_size = 0.001
	_stats_label.position = Vector3(panel_x, panel_y - 0.05, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.modulate = Color(0.5, 0.5, 0.6)
	add_child(_stats_label)


func _build_source_indicator() -> void:
	# Small indicator showing whether we're reading real VR or fallback
	_source_label = Label3D.new()
	_source_label.font_size = 10
	_source_label.pixel_size = 0.001
	_source_label.position = Vector3(0, pedestal_height + 1.15, 0)
	_source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_source_label)
	_update_source_indicator()


func _build_vr_controls() -> void:
	var panel := Node3D.new()
	panel.name = "VRControlPanel"
	var panel_x := -float(panel_count) * panel_spacing * 0.5 - 0.8
	panel.position = Vector3(panel_x, pedestal_height + 0.3, 0.5)
	panel.rotation_degrees = Vector3(-25, 20, 0)
	add_child(panel)

	# Panel backing
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.36, 0.12, 0.008)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.06, 0.06, 0.08)
	back_mat.metallic = 0.3
	back.material_override = back_mat
	back.position.z = -0.008
	panel.add_child(back)

	# RESET button
	var reset_btn := PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(-0.1, 0.0, 0)
	reset_btn.scale = Vector3(0.7, 0.7, 0.7)
	panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")

	var reset_area := reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(func(_b): _reset())

	# PAUSE button
	var pause_btn := PUSH_BUTTON.instantiate()
	pause_btn.name = "PauseBtn"
	pause_btn.position = Vector3(0.1, 0.0, 0)
	pause_btn.scale = Vector3(0.7, 0.7, 0.7)
	panel.add_child(pause_btn)
	_add_button_label(pause_btn, "PAUSE")

	var pause_area := pause_btn.get_node_or_null("InteractableAreaButton")
	if pause_area:
		pause_area.button_pressed.connect(func(_b):
			_paused = not _paused
			_update_source_indicator()
		)


func _add_button_label(btn: Node3D, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.022, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(lbl)


# ============================================================
# UPDATES
# ============================================================

func _update_readouts() -> void:
	if _readout_labels.size() < 8:
		return

	var max_vel := maxf(_left_velocity, _right_velocity)
	var max_grip := maxf(_grip_left, _grip_right)

	_readout_labels[0].text = "VELOCITY:  %.2f m/s" % max_vel
	_readout_labels[0].modulate = Color(0.7, 0.8, 0.7).lerp(Color(1.0, 0.3, 0.2), clampf(max_vel / 3.0, 0.0, 1.0))

	_readout_labels[1].text = "GRIP:      %.1f%%" % (max_grip * 100.0)
	_readout_labels[1].modulate = Color(0.7, 0.8, 0.7).lerp(Color(1.0, 0.8, 0.2), max_grip)

	_readout_labels[2].text = "HEAD ROT:  %.2f r/s" % _head_angular_speed
	_readout_labels[2].modulate = Color(0.7, 0.8, 0.7).lerp(Color(0.4, 0.6, 1.0), clampf(_head_angular_speed, 0.0, 1.0))

	_readout_labels[3].text = "SCRATCHES: %.1f%%" % (_display_scratch * 100.0)
	_readout_labels[4].text = "GRIME:     %.1f%%" % (_display_grime * 100.0)
	_readout_labels[5].text = "ENTROPY:   %.1f%%" % (_display_entropy * 100.0)
	_readout_labels[6].text = "DECAY:     %.1f%%" % (_display_decay * 100.0)

	# Color the decay readout based on severity
	var decay_color_val := Color(0.3, 1.0, 0.4).lerp(Color(1.0, 0.2, 0.1), _display_decay)
	_readout_labels[6].modulate = decay_color_val

	_readout_labels[7].text = "TIME:      %.0fs" % _interaction_seconds

	# Stats summary
	if _stats_label:
		_stats_label.text = "Peak: %.1f m/s | Total scratch: %.1f" % [_peak_velocity, _total_scratches]


func _update_source_indicator() -> void:
	if _source_label == null:
		return

	if _paused:
		_source_label.text = "[ PAUSED ]"
		_source_label.modulate = Color(1.0, 0.5, 0.2)
	else:
		var xr_origin := _find_xr_origin()
		if xr_origin:
			_source_label.text = "[ VR HARDWARE ACTIVE ]"
			_source_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			_source_label.text = "[ SIMULATED ENTROPY ]"
			_source_label.modulate = Color(0.6, 0.6, 0.8)


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
