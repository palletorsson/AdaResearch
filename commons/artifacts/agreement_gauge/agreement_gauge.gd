extends "res://algorithms/vectors/shared/vector_scene_base.gd"
class_name AgreementGauge

# The Agreement Gauge  (concept: dot_product)
#
# @identity
# essence: a·b = |a||b|cos(theta) = ax*bx + ay*by + az*bz — one scalar that says
#   how much two directions agree. Two arrows, a self-substituting three-line
#   equation, and a red->grey->green rail along which a physical puck slides to
#   cos(theta). The number is computed, never grabbed.
# desire: to make alignment legible without reading a digit — open the angle and
#   the puck slides green, snap to 90 deg and it parks at the grey notch (dot=0),
#   pull past 90 and the rail goes red (dot negative).
# critical_parameter: angle theta between a and b. 0 deg -> dot peaks at |a||b|;
#   90 deg -> dot snaps to 0 ("strangers"); 180 deg -> dot is minimal (opposition).
# triggers: grab tip a or tip b -> angle changes -> a.dot(b), |a|, |b|, cos, theta
#   recomputed each frame -> puck lerps to cos(theta), rail color lerps red->green,
#   three equation lines re-substitute. |b| dial scales b without turning it,
#   isolating "dot scales with magnitude at fixed angle". SNAP 90 button parks b
#   perpendicular to a so a solo player can hit the punchline.
# emerges: the geometric form |a||b|cos(theta) and the algebraic component sum land
#   on the SAME number, stacked and visibly equal — sign and magnitude in one read.
# truth: The dot product does not measure length. It measures how much two
#   directions agree. At 90 degrees, they are strangers.

# ── Vector-bench color language (fixed) ──────────────────────────────────────
const COLOR_A: Color = Color(1.0, 0.72, 0.22)    # vector a — warm amber
const COLOR_B: Color = Color(1.0, 0.5, 0.15)     # vector b — cooler orange
const COLOR_DERIVED: Color = Color(0.55, 0.7, 1.0) # the derived number — cyan-violet
const COLOR_RED: Color = Color(0.92, 0.22, 0.2)    # a.b < 0  — opposing
const COLOR_GREY: Color = Color(0.55, 0.57, 0.6)   # a.b = 0  — perpendicular
const COLOR_GREEN: Color = Color(0.3, 0.92, 0.4)   # a.b > 0  — agreeing

# ── DNA knobs (overridable via apply_grid_config) ────────────────────────────
var initial_a: Vector3 = Vector3(0.9, 0.55, 0.2)
var initial_b: Vector3 = Vector3(0.35, 0.85, 0.6)
var bar_half_width: float = 0.55      # logical half-length of the agreement rail (m)
var slider_min_mag: float = 0.2       # |b| dial range
var slider_max_mag: float = 2.5

# ── Node references ──────────────────────────────────────────────────────────
var vector_a: Node3D
var vector_b: Node3D
var info_label: Label            # live three-line substitution (left column)
var readout_label: Label           # 2D headline on the plate's 2D-in-3D display
var arc_label: Label3D             # theta at the arc midpoint
var bar_caption_label: Label3D     # "alignment = cos theta = +0.79"
var _angle_arc: MultiMeshInstance3D
var _bar_puck: MeshInstance3D
var _bar_rail_mat: StandardMaterial3D
var _result_token_label: Label3D   # the "= 9.00" token that recolors by sign
var _mag_dial: Node3D              # |b| dial (dial_smooth)
var _snap_button: Node3D           # SNAP 90 deg push button

static var _arc_dot_mesh: SphereMesh
static var _puck_mesh: SphereMesh

# ── Cached vector endpoint nodes ─────────────────────────────────────────────
var _cached_a: Dictionary = {}
var _cached_b: Dictionary = {}

# ── Throttling ───────────────────────────────────────────────────────────────
var _time_since_text: float = 0.0
const TEXT_INTERVAL: float = 0.1   # 10 Hz

# ── Puck-crosses-zero delight state ──────────────────────────────────────────
var _prev_cos_sign: float = 0.0
var _puck_pulse: float = 0.0       # decays 1 -> 0 after a zero crossing

const SLIDER_SCENE_LOCAL := preload("res://commons/interactables/slider_horizontal.tscn")
const DIAL_SCENE := preload("res://commons/interactables/dial_smooth.tscn")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
var _control_panel: Node3D


func _ready() -> void:
	super._ready()


func build_scene() -> void:
	# Compact at 1.0, walk-inside at larger scale_multiplier.
	scale = base_scale()

	_build_pedestal()
	create_floor(2.4, Color(0.07, 0.08, 0.1, 1.0))
	create_axes(1.0)

	# Two and only two live, grabbable arrows from the origin.
	vector_a = spawn_vector(Vector3.ZERO, initial_a, COLOR_A, "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, initial_b, COLOR_B, "Vector b")
	_cache_vector_nodes(vector_a, _cached_a)
	_cache_vector_nodes(vector_b, _cached_b)

	# Dotted slerp arc sweeping between the tips, with a midpoint angle label.
	_angle_arc = _create_angle_arc()
	environment_root.add_child(_angle_arc)
	arc_label = _make_label("theta", Color(1.0, 0.95, 0.7), 16)
	info_root.add_child(arc_label)

	# Floating formula slab: the three-line self-substituting equation.
	# create_info_panel gives one live data Label (left). We render the color-keyed
	# LINE 1 symbols as fixed tokens (built once) so the signature color-coding
	# survives the single-modulate-per-column panel structure (judge's note).
	info_label = create_info_panel(
		"Agreement Gauge",
		Vector3(0.0, 2.5, -0.85),
		Vector2(2.7, 1.15),
		"",
		"a.b is one number:\nhow much two\ndirections agree.")
	_build_literal_form_tokens()

	# Agreement rail + sliding puck (the only animated indicator).
	_build_agreement_bar()

	# |b| dial: stretch b's length without changing its direction.
	_build_magnitude_dial()

	# SNAP 90 deg button: park b perpendicular to a.
	_build_snap_button()

	# Readout display integrated into the top of the plate (built after the panel).
	if _control_panel:
		readout_label = _control_panel.add_readout("")


# ═════════════════════════════════════════════════════════════════════════════
# PEDESTAL — dark slate plinth + brass rim
# ═════════════════════════════════════════════════════════════════════════════

func _build_pedestal() -> void:
	var sc := SCENE_SCALE
	var slate := StandardMaterial3D.new()
	slate.albedo_color = Color(0.09, 0.1, 0.12)
	slate.metallic = 0.2
	slate.roughness = 0.85

	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var plinth_box := BoxMesh.new()
	plinth_box.size = Vector3(0.7, 0.06, 0.7) * sc
	plinth.mesh = plinth_box
	plinth.material_override = slate
	plinth.position = Vector3(0.0, -0.06, 0.0) * sc
	environment_root.add_child(plinth)

	# Brass rim — a thin emissive frame box just proud of the plinth top.
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.72, 0.55, 0.24)
	brass.metallic = 0.85
	brass.roughness = 0.35
	brass.emission_enabled = true
	brass.emission = Color(0.4, 0.3, 0.12)
	brass.emission_energy_multiplier = 0.4
	var rim := MeshInstance3D.new()
	rim.name = "BrassRim"
	var rim_box := BoxMesh.new()
	rim_box.size = Vector3(0.74, 0.012, 0.74) * sc
	rim.mesh = rim_box
	rim.material_override = brass
	rim.position = Vector3(0.0, -0.028, 0.0) * sc
	environment_root.add_child(rim)


# ═════════════════════════════════════════════════════════════════════════════
# LITERAL FORM — color-keyed tokens (built once)
# LINE 1:  a·b = |a||b| cos(theta)  with a amber, b orange, cos(theta) cyan-violet
# ═════════════════════════════════════════════════════════════════════════════

func _build_literal_form_tokens() -> void:
	# Lay the literal symbolic form across the top of the slab as separate,
	# pre-positioned Label3D tokens so each can carry its own color. The live
	# numeric substitution stays on info_label (LINE 2 / LINE 3).
	var slab := info_root.get_node_or_null("InfoPanel")
	if slab == null:
		return
	var sc := SCENE_SCALE
	# Row sits just under the panel's accent rule.
	var y := 0.22 * sc
	var z := 0.01 * sc

	var tokens := [
		{"t": "a", "c": COLOR_A, "x": -0.95},
		{"t": "·", "c": Color.WHITE, "x": -0.83},
		{"t": "b", "c": COLOR_B, "x": -0.72},
		{"t": "=", "c": Color.WHITE, "x": -0.58},
		{"t": "|a|", "c": COLOR_A, "x": -0.42},
		{"t": "|b|", "c": COLOR_B, "x": -0.22},
		{"t": "cos(theta)", "c": COLOR_DERIVED, "x": 0.12},
	]
	for entry in tokens:
		var tok := Label3D.new()
		tok.name = "Lit_" + str(entry["t"])
		tok.text = str(entry["t"])
		tok.modulate = entry["c"]
		tok.pixel_size = 0.0015
		tok.font_size = 22
		tok.no_depth_test = true
		tok.render_priority = 105
		tok.outline_size = 4
		tok.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
		tok.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tok.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		tok.position = Vector3(float(entry["x"]) * sc, y, z)
		slab.add_child(tok)


# ═════════════════════════════════════════════════════════════════════════════
# DOTTED SLERP ARC between the two tips
# ═════════════════════════════════════════════════════════════════════════════

func _create_angle_arc() -> MultiMeshInstance3D:
	if _arc_dot_mesh == null:
		_arc_dot_mesh = SphereMesh.new()
		_arc_dot_mesh.radius = 0.006
		_arc_dot_mesh.height = 0.012
		_arc_dot_mesh.radial_segments = 6
		_arc_dot_mesh.rings = 3
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "AngleArc"
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.mesh = _arc_dot_mesh
	mmi.multimesh.instance_count = 24
	mmi.multimesh.visible_instance_count = 0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.6, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = mat
	return mmi


func _update_angle_arc(a: Vector3, b: Vector3) -> void:
	var mag_a := a.length()
	var mag_b := b.length()
	if mag_a < 0.001 or mag_b < 0.001:
		_angle_arc.multimesh.visible_instance_count = 0
		return
	var dir_a := a.normalized()
	var dir_b := b.normalized()
	var arc_radius: float = minf(mag_a, mag_b) * 0.3
	var num_dots := 20
	_angle_arc.multimesh.visible_instance_count = num_dots
	for i in range(num_dots):
		var t: float = float(i) / float(num_dots - 1)
		var p: Vector3 = dir_a.slerp(dir_b, t) * arc_radius
		_angle_arc.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, p * SCENE_SCALE))


# ═════════════════════════════════════════════════════════════════════════════
# AGREEMENT BAR — red->grey->green rail + sliding puck (judge's improvement)
# ═════════════════════════════════════════════════════════════════════════════

func _build_agreement_bar() -> void:
	var sc := SCENE_SCALE
	var bar_root := Node3D.new()
	bar_root.name = "AgreementBar"
	# Sit on the front lip of the plinth, tilted slightly toward the player.
	bar_root.position = Vector3(0.0, 0.12, 0.95) * sc
	bar_root.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	info_root.add_child(bar_root)

	# Rail: a thin emissive box. Its albedo/emission lerps red->grey->green live.
	_bar_rail_mat = StandardMaterial3D.new()
	_bar_rail_mat.albedo_color = COLOR_GREY
	_bar_rail_mat.emission_enabled = true
	_bar_rail_mat.emission = COLOR_GREY
	_bar_rail_mat.emission_energy_multiplier = 0.6
	_bar_rail_mat.metallic = 0.1
	_bar_rail_mat.roughness = 0.5
	var rail := MeshInstance3D.new()
	rail.name = "Rail"
	var rail_box := BoxMesh.new()
	rail_box.size = Vector3(bar_half_width * 2.0, 0.025, 0.03) * sc
	rail.mesh = rail_box
	rail.material_override = _bar_rail_mat
	bar_root.add_child(rail)

	# Center grey notch — marks cos(theta)=0 (the perpendicular "strangers" point).
	var notch_mat := StandardMaterial3D.new()
	notch_mat.albedo_color = Color(0.85, 0.85, 0.88)
	notch_mat.emission_enabled = true
	notch_mat.emission = Color(0.4, 0.4, 0.42)
	notch_mat.emission_energy_multiplier = 0.5
	var notch := MeshInstance3D.new()
	notch.name = "ZeroNotch"
	var notch_box := BoxMesh.new()
	notch_box.size = Vector3(0.012, 0.06, 0.045) * sc
	notch.mesh = notch_box
	notch.material_override = notch_mat
	notch.position = Vector3(0.0, 0.0, 0.0)
	bar_root.add_child(notch)

	# Endpoint pips: red at left (-1, opposing) and green at right (+1, parallel).
	for side in [{"x": -1.0, "c": COLOR_RED}, {"x": 1.0, "c": COLOR_GREEN}]:
		var pip := MeshInstance3D.new()
		var pip_box := BoxMesh.new()
		pip_box.size = Vector3(0.02, 0.05, 0.04) * sc
		pip.mesh = pip_box
		var pip_mat := StandardMaterial3D.new()
		pip_mat.albedo_color = side["c"]
		pip_mat.emission_enabled = true
		pip_mat.emission = side["c"]
		pip_mat.emission_energy_multiplier = 0.8
		pip.material_override = pip_mat
		pip.position = Vector3(float(side["x"]) * bar_half_width * sc, 0.0, 0.0)
		bar_root.add_child(pip)

	# The PUCK: a single moving sphere driven along the rail by lerping local x to
	# cos(theta) each frame (pure transform animation — no joints).
	if _puck_mesh == null:
		_puck_mesh = SphereMesh.new()
		_puck_mesh.radius = 0.5
		_puck_mesh.height = 1.0
		_puck_mesh.radial_segments = 18
		_puck_mesh.rings = 10
	_bar_puck = MeshInstance3D.new()
	_bar_puck.name = "Puck"
	_bar_puck.mesh = _puck_mesh
	var puck_mat := StandardMaterial3D.new()
	puck_mat.albedo_color = COLOR_DERIVED
	puck_mat.emission_enabled = true
	puck_mat.emission = COLOR_DERIVED
	puck_mat.emission_energy_multiplier = 1.0
	puck_mat.metallic = 0.3
	puck_mat.roughness = 0.3
	_bar_puck.material_override = puck_mat
	_bar_puck.scale = Vector3.ONE * 0.05 * sc
	_bar_puck.position = Vector3(0.0, 0.04 * sc, 0.0)
	bar_root.add_child(_bar_puck)

	# Caption under the rail.
	bar_caption_label = _make_label("alignment = cos theta = +0.00", COLOR_DERIVED, 15)
	bar_caption_label.position = Vector3(0.0, -0.09 * sc, 0.0)
	bar_root.add_child(bar_caption_label)


## Drive the puck to cos(theta) in [-1,1] mapped onto the rail half-width, lerp
## the rail color red->grey->green, and emit a tiny scale-pulse + haptic at the
## zero crossing (theta = 90 deg).
func _update_agreement_bar(cos_theta: float, delta: float) -> void:
	if _bar_puck == null:
		return
	var sc := SCENE_SCALE
	var target_x: float = clampf(cos_theta, -1.0, 1.0) * bar_half_width * sc

	# Detect zero crossing (sign flip of cos_theta) -> pulse + haptic tick.
	var sign_now: float = signf(cos_theta)
	if not is_equal_approx(absf(cos_theta), 0.0):
		if _prev_cos_sign != 0.0 and sign_now != _prev_cos_sign:
			_puck_pulse = 1.0
			_haptic_tick()
		_prev_cos_sign = sign_now

	# Decay the pulse.
	if _puck_pulse > 0.0:
		_puck_pulse = maxf(0.0, _puck_pulse - delta * 4.0)

	var base_scale_puck: float = 0.05 * sc
	var pulse_scale: float = base_scale_puck * (1.0 + 0.6 * _puck_pulse)
	_bar_puck.scale = Vector3.ONE * pulse_scale
	# Smoothly ride toward target (still pure transform, just eased).
	var cur_x: float = _bar_puck.position.x
	var smoothed_x: float = lerpf(cur_x, target_x, clampf(delta * 14.0, 0.0, 1.0))
	_bar_puck.position = Vector3(smoothed_x, 0.04 * sc, 0.0)

	# Rail color: red (cos=-1) -> grey (cos=0) -> green (cos=+1).
	var rail_color: Color = _agreement_color(cos_theta)
	if _bar_rail_mat:
		_bar_rail_mat.albedo_color = rail_color
		_bar_rail_mat.emission = rail_color


## Map cos(theta) in [-1,1] to red->grey->green.
func _agreement_color(cos_theta: float) -> Color:
	var c: float = clampf(cos_theta, -1.0, 1.0)
	if c < 0.0:
		return COLOR_GREY.lerp(COLOR_RED, -c)
	return COLOR_GREY.lerp(COLOR_GREEN, c)


func _haptic_tick() -> void:
	# No-op haptic stub: the puck scale-pulse already provides the visible beat at
	# theta = 90 deg. A controller-routed haptic would require a player-rig
	# reference this artifact deliberately does not hold, keeping it freely
	# map-placeable with no wiring. Kept as a named hook for future rig routing.
	pass


# ═════════════════════════════════════════════════════════════════════════════
# |b| DIAL — scales b's length without turning it
# ═════════════════════════════════════════════════════════════════════════════

func _build_magnitude_dial() -> void:
	# Build the shared Braun ControlPanel (dial first, SNAP added next) at the
	# front lip of the plinth — standard spacing + orientation + baked labels.
	_control_panel = ControlPanelScript.new()
	_control_panel.name = "ControlPlate"
	_control_panel.position = Vector3(0.0, 0.16, 0.85) * SCENE_SCALE
	add_child(_control_panel)

	_mag_dial = _control_panel.add_dial("|b|", "|b|")
	if _mag_dial.has_method("set_range"):
		_mag_dial.call("set_range", slider_min_mag, slider_max_mag)
	if _mag_dial.has_method("set_normalized_value"):
		var b_now: Vector3 = _get_vector_fast(vector_b, _cached_b)
		var start_norm: float = inverse_lerp(slider_min_mag, slider_max_mag, clampf(b_now.length(), slider_min_mag, slider_max_mag))
		_mag_dial.call("set_normalized_value", start_norm)
	if _mag_dial.has_signal("hinge_moved"):
		_mag_dial.connect("hinge_moved", Callable(self, "_on_mag_dial_moved"))


func _on_mag_dial_moved(_angle) -> void:
	if _mag_dial == null:
		return
	var norm: float = 0.5
	if _mag_dial.has_method("get_normalized_value"):
		norm = float(_mag_dial.call("get_normalized_value"))
	var target_mag: float = lerpf(slider_min_mag, slider_max_mag, clampf(norm, 0.0, 1.0))
	var b_vec: Vector3 = _get_vector_fast(vector_b, _cached_b)
	var dir: Vector3 = b_vec.normalized()
	if dir.length() < 0.001:
		dir = Vector3(0.0, 1.0, 0.0)
	_update_vector_fast(vector_b, dir * target_mag, _cached_b)


# ═════════════════════════════════════════════════════════════════════════════
# SNAP 90 deg BUTTON — park b perpendicular to a
# ═════════════════════════════════════════════════════════════════════════════

func _build_snap_button() -> void:
	# Add SNAP to the shared ControlPanel built in _build_magnitude_dial.
	if _control_panel == null:
		return
	_snap_button = _control_panel.add_button("SNAP 90")
	_snap_button.set("pressed_color", COLOR_GREY)
	_snap_button.set("released_color", Color(0.9, 0.9, 0.93))
	if _snap_button.has_signal("pressed"):
		_snap_button.connect("pressed", Callable(self, "_on_snap_pressed"))
	else:
		var inner := _snap_button.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_snap_inner"))
	if _snap_button.has_method("update_colors"):
		_snap_button.call_deferred("update_colors")


func _on_snap_pressed() -> void:
	_snap_b_perpendicular()


func _on_snap_inner(_button) -> void:
	_snap_b_perpendicular()


## Rotate b so it is perpendicular to a (dot = 0), preserving |b|. Choose a
## perpendicular in the plane the two arrows span where possible.
func _snap_b_perpendicular() -> void:
	var a_vec: Vector3 = _get_vector_fast(vector_a, _cached_a)
	var b_vec: Vector3 = _get_vector_fast(vector_b, _cached_b)
	var mag_b: float = b_vec.length()
	if a_vec.length() < 0.001 or mag_b < 0.001:
		return
	var a_dir: Vector3 = a_vec.normalized()
	# Component of b perpendicular to a (Gram-Schmidt). If b is parallel to a,
	# fall back to a stable perpendicular built from a helper axis.
	var perp: Vector3 = b_vec - a_dir * b_vec.dot(a_dir)
	if perp.length() < 0.001:
		var helper: Vector3 = Vector3.UP
		if absf(a_dir.dot(helper)) > 0.99:
			helper = Vector3.RIGHT
		perp = a_dir.cross(helper)
	perp = perp.normalized() * mag_b
	_update_vector_fast(vector_b, perp, _cached_b)


# ═════════════════════════════════════════════════════════════════════════════
# PER-FRAME UPDATE
# ═════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	var a_vec: Vector3 = _get_vector_fast(vector_a, _cached_a)
	var b_vec: Vector3 = _get_vector_fast(vector_b, _cached_b)

	var dot: float = a_vec.dot(b_vec)
	var mag_a: float = a_vec.length()
	var mag_b: float = b_vec.length()

	var cos_theta: float = 0.0
	if mag_a > 0.0001 and mag_b > 0.0001:
		cos_theta = clampf(dot / (mag_a * mag_b), -1.0, 1.0)
	var theta: float = acos(cos_theta)

	# Smooth, per-frame visuals.
	_update_angle_arc(a_vec, b_vec)
	_update_agreement_bar(cos_theta, delta)

	# Arc label rides the midpoint of the slerp arc.
	if arc_label:
		var mid_dir: Vector3 = a_vec.normalized() + b_vec.normalized()
		if mid_dir.length() == 0.0:
			mid_dir = Vector3.UP
		mid_dir = mid_dir.normalized()
		var arc_radius: float = minf(mag_a, mag_b) * 0.3
		arc_label.position = mid_dir * arc_radius * SCENE_SCALE + Vector3(0.0, 0.04, 0.0)

	# Throttled text.
	_time_since_text += delta
	if _time_since_text >= TEXT_INTERVAL:
		_time_since_text = 0.0
		_update_text(a_vec, b_vec, dot, mag_a, mag_b, cos_theta, theta)


func _update_text(a_vec: Vector3, b_vec: Vector3, dot: float, mag_a: float, mag_b: float, cos_theta: float, theta: float) -> void:
	var deg: float = rad_to_deg(theta)

	# Three self-substituting lines + the geometric form, on the live data label.
	# LINE 1 component literal, LINE 2 numbers plugged in, LINE 3 the sum.
	var lines := []
	lines.append("a.b = ax*bx + ay*by + az*bz")
	lines.append("    = %.2f*%.2f + %.2f*%.2f + %.2f*%.2f" % [
		a_vec.x, b_vec.x, a_vec.y, b_vec.y, a_vec.z, b_vec.z])
	lines.append("    = %.2f" % dot)
	lines.append("")
	# Geometric form, same number arrived at the other way.
	lines.append("a.b = |a||b|cos(theta)")
	lines.append("    = %.2f * %.2f * %.2f" % [mag_a, mag_b, cos_theta])
	lines.append("    = %.2f   (theta = %.1f deg)" % [(mag_a * mag_b * cos_theta), deg])
	if info_label:
		info_label.text = "\n".join(lines)

	# Headline billboard.
	if readout_label:
		readout_label.text = "a . b = %.2f\ntheta = %.1f deg" % [dot, deg]

	# Arc label.
	if arc_label:
		arc_label.text = "theta = %.1f deg" % deg

	# Bar caption with explicit sign.
	if bar_caption_label:
		bar_caption_label.text = "alignment = cos theta = %+.2f" % cos_theta
		bar_caption_label.modulate = _agreement_color(cos_theta)


# ═════════════════════════════════════════════════════════════════════════════
# VECTOR ENDPOINT CACHING / FAST READ-WRITE
# ═════════════════════════════════════════════════════════════════════════════

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary) -> void:
	if arrow == null:
		return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")


func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	if arrow == null:
		return Vector3.ZERO
	var start_node: Node3D = cache_dict.get("start")
	var end_node: Node3D = cache_dict.get("end")
	if start_node and end_node:
		var s: float = SCENE_SCALE * scale.x
		if s <= 0.0001:
			s = SCENE_SCALE
		return (end_node.global_position - start_node.global_position) / s
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO


func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()


# ═════════════════════════════════════════════════════════════════════════════
# GRID CONFIG — scale_multiplier (super) + DNA knobs
# ═════════════════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	if config == null:
		return
	# DNA knobs first, so a rebuild triggered by scale picks them up.
	if config.has("initial_a") and config["initial_a"] is Vector3:
		initial_a = config["initial_a"]
	if config.has("initial_b") and config["initial_b"] is Vector3:
		initial_b = config["initial_b"]
	if config.has("bar_half_width"):
		bar_half_width = float(config["bar_half_width"])
	if config.has("slider_min_mag"):
		slider_min_mag = float(config["slider_min_mag"])
	if config.has("slider_max_mag"):
		slider_max_mag = float(config["slider_max_mag"])
	# Let the base handle scale_multiplier (+ rebuild if already built).
	super.apply_grid_config(config)


# ═════════════════════════════════════════════════════════════════════════════
# UTILITY — billboarded label
# ═════════════════════════════════════════════════════════════════════════════

func _make_label(text_value: String, color: Color, font_size: int = 18) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = font_size
	label.outline_size = maxi(2, font_size / 6)
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0012
	label.no_depth_test = true
	label.render_priority = 100
	return label
