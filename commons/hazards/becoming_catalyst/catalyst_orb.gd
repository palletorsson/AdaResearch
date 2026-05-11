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
	if _mat:
		_mat.albedo_color = c
		_mat.emission = c
		_mat.emission_energy_multiplier = 3.0 if _is_two_handed else 1.6
	if _mesh:
		var s: float = 1.0 if _is_two_handed else 0.65
		_mesh.scale = Vector3.ONE * s
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
