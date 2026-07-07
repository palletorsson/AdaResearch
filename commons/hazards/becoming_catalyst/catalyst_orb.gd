# @identity
# essence: gesture(form/tick/dissolve) -> emissive sphere + cone of effect -> creature.receive_catalyst_field
# desire: the audiotactile body of the orb gesture — visible while it lives, gone the instant the palms part
# critical_parameter: _cone_length (scales with distance-from-head for two-handed; fixed 2 m for one-handed); _mode_id (drives hue)
# triggers: form()/update_state()/dissolve() called by OrbGestureDetector signals; cone Area3D body_entered/exited
# emerges: capability-as-relation — the orb has no inventory representation; existing only while the gesture exists
# needs: OrbGestureDetector signals [has]; HazardCreatureBase.receive_catalyst_field [added]
# relationships: receives from OrbGestureDetector; dispatches to HazardCreatureBase children inside the cone
# truth: the catalyst is felt before it is seen — hum and haptic before vision. No numbers on screen. Ever.

# CatalystOrb.gd
# Audiovisual presence for the orb gesture. Driven by OrbGestureDetector
# signals; carries no game logic beyond the cone-overlap dispatch into
# HazardCreatureBase.receive_catalyst_field().
#
# Per the sieve-recorded design rule (doc/ORB_GESTURE_SLICE.md):
# no reticle, no hit confirmation, no damage number, no toast.
# Audiotactile + creature-visual change are the only feedback channels.

extends Node3D
class_name CatalystOrb

# ── Held-matter: per-mode form selection ────────────────────────────────
# 2026-05-11: the orb stops being one noise sphere for every mode.
# Three modes get their own held-form because their substance differs
# ontologically from a sphere (sieve pass: doc/sieve_passes/
# 2026-05-11T19-25-26_activation-verbs.md). The other seven keep the
# baseline sphere for now — they'll be added as production confirms the
# hypothesis.
const CUSTOM_FORM_MODES := ["swarm", "forces", "branching"]
const ORB_NOISE_SHADER := preload("res://commons/hazards/becoming_catalyst/orb_noise.gdshader")

# 3-stop palettes for the custom-form modes (matched to the gallery's
# held_matter captures).
const MODE_PALETTES := {
	"forces":    [Color(0.95, 0.65, 0.20), Color(0.95, 0.85, 0.30), Color(1.00, 1.00, 0.75)],
	"branching": [Color(0.30, 0.55, 0.30), Color(0.45, 0.85, 0.50), Color(0.85, 0.95, 0.70)],
	"swarm":     [Color(0.85, 0.45, 0.05), Color(1.00, 0.75, 0.20), Color(1.00, 0.95, 0.65)],
}

# ── State (set by detector signals) ─────────────────────────────────────
var _mode_id: String = "primitives"
var _origin: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.FORWARD
var _cone_length: float = 2.0
var _is_two_handed: bool = false
var _active: bool = false

# Creatures currently inside the cone (advance dose every tick).
var _creatures_in_cone: Array[Node] = []

# ── Node refs (built procedurally in _ready) ────────────────────────────
var _mesh: MeshInstance3D = null
var _mat: StandardMaterial3D = null
var _light: OmniLight3D = null
var _cone_area: Area3D = null
var _cone_collider: CollisionShape3D = null
var _cone_shape: CylinderShape3D = null  # cylinder approximates a cone for Area3D

# Holder for per-mode form decoration (only used when _mode_id is in
# CUSTOM_FORM_MODES — otherwise _mesh is the orb and _form_holder is empty).
var _form_holder: Node3D = null
# Tracks the mode the form was last built for; avoids rebuilding every
# update_state tick.
var _current_form_mode: String = ""


func _ready() -> void:
	_build_visual()
	_build_cone()
	set_visible(false)


# ── Public API — called by OrbGestureDetector ───────────────────────────

func form(mode_id: String, origin: Vector3, direction: Vector3, two_handed: bool) -> void:
	_mode_id = mode_id
	_origin = origin
	_direction = direction.normalized() if direction.length_squared() > 0.01 else Vector3.FORWARD
	_is_two_handed = two_handed
	_cone_length = 2.0  # initial; first tick may resize
	_active = true
	_apply_pose()
	_apply_mode_visuals()
	set_visible(true)


func update_state(mode_id: String, origin: Vector3, direction: Vector3, cone_length: float, two_handed: bool) -> void:
	if not _active:
		# A tick without a prior form — treat as form.
		form(mode_id, origin, direction, two_handed)
	_mode_id = mode_id
	_origin = origin
	if direction.length_squared() > 0.01:
		_direction = direction.normalized()
	_cone_length = cone_length
	_is_two_handed = two_handed
	_apply_pose()
	_apply_mode_visuals()
	_tick_creatures(get_physics_process_delta_time())


func dissolve() -> void:
	_active = false
	set_visible(false)
	_creatures_in_cone.clear()


# ── Pose / visual / cone shape ──────────────────────────────────────────

func _apply_pose() -> void:
	global_position = _origin
	# Orient so the cone's +Y axis points along _direction.
	var up: Vector3 = _direction.normalized()
	if up.length_squared() < 0.001:
		up = Vector3.FORWARD
	var ref: Vector3 = Vector3.UP if abs(up.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right: Vector3 = up.cross(ref).normalized()
	var front: Vector3 = right.cross(up).normalized()
	global_transform.basis = Basis(right, up, front)
	if _cone_shape != null and _cone_collider != null:
		_cone_shape.height = _cone_length
		_cone_shape.radius = 0.35
		_cone_collider.position = Vector3(0, _cone_length * 0.5, 0)


func _apply_mode_visuals() -> void:
	var c: Color = _color_for_mode(_mode_id)
	var wants_custom: bool = _mode_id in CUSTOM_FORM_MODES

	# Rebuild custom form only when the mode actually changes, not on
	# every tick — building meshes every frame would be expensive and
	# also reset any time-dependent animation in the form.
	if _mode_id != _current_form_mode:
		_rebuild_form()
		_current_form_mode = _mode_id

	# The default sphere is the form for non-custom modes only.
	if _mesh:
		_mesh.visible = not wants_custom
		if _mat and not wants_custom:
			_mat.albedo_color = c
			_mat.emission = c
			_mat.emission_energy_multiplier = 3.0 if _is_two_handed else 1.6
		var s: float = 1.0 if _is_two_handed else 0.65
		_mesh.scale = Vector3.ONE * s

	# Scale the custom form via its holder so one-handed bursts read as
	# smaller substance — same proportion as the default sphere.
	if _form_holder:
		var s2: float = 1.0 if _is_two_handed else 0.65
		_form_holder.scale = Vector3.ONE * s2

	# The point light always tracks the mode colour, whichever form.
	if _light:
		_light.light_energy = 2.5 if _is_two_handed else 1.4
		_light.light_color = c


func _color_for_mode(mode_id: String) -> Color:
	match mode_id:
		"primitives":     return Color(0.40, 0.95, 0.60)
		"transformation": return Color(0.50, 0.80, 1.00)
		"chromatic":      return Color(1.00, 0.55, 0.85)
		"forces":         return Color(0.90, 0.85, 0.40)
		"waveform":       return Color(0.60, 0.50, 1.00)
		"chaos":          return Color(1.00, 0.50, 0.30)
		"fractal":        return Color(0.50, 1.00, 0.80)
		"cellular":       return Color(0.95, 0.95, 0.95)
		"branching":      return Color(0.45, 0.85, 0.50)
		"swarm":          return Color(1.00, 0.75, 0.20)
		_:                return Color(0.90, 0.90, 0.95)


# ── Cone overlap → field dispatch ───────────────────────────────────────

func _on_cone_body_entered(body: Node3D) -> void:
	if body is HazardCreatureBase:
		if not _creatures_in_cone.has(body):
			_creatures_in_cone.append(body)


func _on_cone_body_exited(body: Node3D) -> void:
	_creatures_in_cone.erase(body)


func _tick_creatures(dt: float) -> void:
	if dt <= 0.0 or not _active:
		return
	var stale: Array[Node] = []
	for c in _creatures_in_cone:
		if not is_instance_valid(c):
			stale.append(c)
			continue
		c.call("receive_catalyst_field", dt, _mode_id)
	for s in stale:
		_creatures_in_cone.erase(s)


# ── Procedural build ────────────────────────────────────────────────────

func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	sphere.radial_segments = 32
	sphere.rings = 16
	_mesh.mesh = sphere
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_mat.albedo_color = Color(0.9, 0.95, 1.0)
	_mat.emission_enabled = true
	_mat.emission = Color(0.9, 0.95, 1.0)
	_mat.emission_energy_multiplier = 2.0
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color.a = 0.85
	_mesh.material_override = _mat
	add_child(_mesh)

	_light = OmniLight3D.new()
	_light.light_energy = 2.0
	_light.omni_range = 1.8
	_light.light_color = Color(0.9, 0.95, 1.0)
	add_child(_light)

	# Holder for per-mode custom forms. Populated by _rebuild_form()
	# when _mode_id is in CUSTOM_FORM_MODES; otherwise empty.
	_form_holder = Node3D.new()
	_form_holder.name = "FormHolder"
	add_child(_form_holder)


func _build_cone() -> void:
	_cone_area = Area3D.new()
	_cone_area.collision_layer = 0
	_cone_area.collision_mask = 2  # hazard creatures
	_cone_area.monitoring = true
	_cone_area.body_entered.connect(_on_cone_body_entered)
	_cone_area.body_exited.connect(_on_cone_body_exited)
	_cone_collider = CollisionShape3D.new()
	_cone_shape = CylinderShape3D.new()
	_cone_shape.height = _cone_length
	_cone_shape.radius = 0.35
	_cone_collider.shape = _cone_shape
	_cone_collider.position = Vector3(0, _cone_length * 0.5, 0)
	_cone_area.add_child(_cone_collider)
	add_child(_cone_area)


# ── Per-mode form construction (held_matter hypothesis) ─────────────────
# Custom forms are built into _form_holder. The bracelet, the gesture,
# the palette tint, and self-luminosity carry the family resemblance —
# the form carries the substance.

func _rebuild_form() -> void:
	# Clear any prior form.
	for child in _form_holder.get_children():
		_form_holder.remove_child(child)
		child.queue_free()

	if not (_mode_id in CUSTOM_FORM_MODES):
		# No custom form — _mesh handles this mode as the baseline sphere.
		return

	var palette: Array = MODE_PALETTES.get(_mode_id, [_color_for_mode(_mode_id)])
	match _mode_id:
		"swarm":
			_build_swarm_form(palette)
		"forces":
			_build_forces_form(palette)
		"branching":
			_build_branching_form(palette)


# Returns a noise+palette ShaderMaterial matching the gallery captures.
func _make_orb_shader_mat(
	palette: Array, noise_scale := 5.0, noise_amount := 0.06,
	time_scale := 0.6, emission_energy := 1.4) -> ShaderMaterial:
	# Ensure 3 stops — pad with the first colour if fewer.
	var p_a: Color = palette[0] if palette.size() > 0 else _color_for_mode(_mode_id)
	var p_b: Color = palette[1] if palette.size() > 1 else p_a
	var p_c: Color = palette[2] if palette.size() > 2 else p_b
	var mat := ShaderMaterial.new()
	mat.shader = ORB_NOISE_SHADER
	mat.set_shader_parameter("palette_a", p_a)
	mat.set_shader_parameter("palette_b", p_b)
	mat.set_shader_parameter("palette_c", p_c)
	mat.set_shader_parameter("noise_scale", noise_scale)
	mat.set_shader_parameter("noise_amount", noise_amount)
	mat.set_shader_parameter("time_scale", time_scale)
	mat.set_shader_parameter("emission_energy", emission_energy)
	mat.set_shader_parameter("halo_softness", 0.4)
	return mat


# Swarm form: 7 small bodies, no centre. The orb is plural.
func _build_swarm_form(palette: Array) -> void:
	var positions: Array[Vector3] = [
		Vector3( 0.00,  0.02,  0.00),
		Vector3( 0.10,  0.06, -0.04),
		Vector3(-0.11,  0.05,  0.03),
		Vector3( 0.06, -0.05,  0.05),
		Vector3(-0.08, -0.06, -0.04),
		Vector3( 0.13, -0.02, -0.06),
		Vector3(-0.13,  0.01,  0.05),
	]
	var radii: Array[float] = [0.070, 0.058, 0.060, 0.052, 0.055, 0.050, 0.054]
	for i in range(positions.size()):
		var body := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radii[i]
		sphere.height = radii[i] * 2.0
		sphere.radial_segments = 32
		sphere.rings = 16
		body.mesh = sphere
		# Slight per-body variation so the cluster doesn't read uniform.
		var ns := 5.0 + float(i) * 0.3 - 0.6
		var ts := 0.6 + float(i % 3) * 0.15
		body.material_override = _make_orb_shader_mat(palette, ns, 0.06, ts, 1.2)
		body.position = positions[i]
		_form_holder.add_child(body)


# Forces form: warm-amber atmosphere held between the hands. Bright
# core + concentric translucent shells.
func _build_forces_form(palette: Array) -> void:
	# Inner bright core.
	var core := MeshInstance3D.new()
	var s_core := SphereMesh.new()
	s_core.radius = 0.060
	s_core.height = 0.12
	s_core.radial_segments = 32
	s_core.rings = 16
	core.mesh = s_core
	core.material_override = _make_orb_shader_mat(palette, 4.0, 0.03, 0.4, 1.8)
	_form_holder.add_child(core)

	# Three concentric translucent halo shells, each more transparent
	# than the last. Gives the "atmosphere fading outward" reading.
	var c: Color = _color_for_mode(_mode_id)
	var shell_radii: Array[float] = [0.10, 0.14, 0.18]
	var shell_alphas: Array[float] = [0.32, 0.18, 0.10]
	for i in range(shell_radii.size()):
		var shell := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = shell_radii[i]
		s.height = shell_radii[i] * 2.0
		s.radial_segments = 32
		s.rings = 16
		shell.mesh = s
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(c.r, c.g, c.b, shell_alphas[i])
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 0.4 - 0.10 * i
		shell.material_override = mat
		_form_holder.add_child(shell)


# Branching form: vertical seed-pod + tendrils. The orb is a seed that
# remembers it will become tree.
func _build_branching_form(palette: Array) -> void:
	# Seed pod — sphere stretched vertically into a teardrop.
	var pod := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.075
	sphere.height = 0.15
	sphere.radial_segments = 32
	sphere.rings = 16
	pod.mesh = sphere
	pod.material_override = _make_orb_shader_mat(palette, 6.0, 0.05, 0.5, 1.4)
	pod.scale = Vector3(0.85, 1.4, 0.85)
	_form_holder.add_child(pod)

	# Three thin tendrils extending outward from the pod.
	var tendril_dirs: Array[Vector3] = [
		Vector3( 0.05,  0.13,  0.02),
		Vector3(-0.06,  0.11, -0.03),
		Vector3( 0.02, -0.10,  0.04),
	]
	var tendril_col: Color = palette[2] if palette.size() > 2 else _color_for_mode(_mode_id)
	for d in tendril_dirs:
		var tendril := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.004
		cyl.bottom_radius = 0.011
		cyl.height = d.length() * 1.4
		tendril.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = tendril_col
		mat.emission_enabled = true
		mat.emission = tendril_col
		mat.emission_energy_multiplier = 0.8
		tendril.material_override = mat
		# Orient along d.
		var up_dir := d.normalized()
		var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var rx := up_dir.cross(ref_v).normalized()
		var rz := rx.cross(up_dir).normalized()
		tendril.transform.basis = Basis(rx, up_dir, rz)
		tendril.position = d * 0.5
		_form_holder.add_child(tendril)
