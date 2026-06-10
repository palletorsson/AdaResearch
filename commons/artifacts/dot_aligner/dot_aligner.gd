extends Node3D
class_name DotAligner

## @identity
## lineage: the dot product made playable — a·b = |a||b|cosθ — for the embodied
##   vectors-forces arc (an operations toy that fills the gap where only diagrams lived).
## essence: aim a turret at a drifting foe; the dot of (aim · direction-to-foe) is the
##   charge; full alignment locks a beam and converts the foe FOE -> FRIEND.
## truth: alignment is a number you can feel — point at the thing and the angle closes;
##   the dot product is how much two directions agree, and agreement here is mercy, not a kill.
##
## DNA: alignment 0..1 sets how close the aim is to the foe (drives cosθ, the beam, the
## conversion). seed jitters the foe's bearing. color_a = steel rig, color_b = vectors,
## accent = lock beam / friend glow.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var alignment: float = 0.78
@export var color_a: Color = Color(0.52, 0.56, 0.62)      # steel rig / barrel
@export var color_b: Color = Color(0.35, 0.80, 0.95)      # the vectors a, b
@export var accent: Color = Color(0.98, 0.82, 0.32)       # lock beam / charge
@export var foe_color: Color = Color(0.90, 0.26, 0.24)    # enemy red
@export var friend_color: Color = Color(0.40, 0.92, 0.45) # befriended green
@export var emissive: bool = true
@export var complexity: int = 6
@export var sculpt_height: float = 2.0
@export var sculpt_width: float = 2.4

const MAX_ANGLE_DEG := 72.0
const LOCK_DOT := 0.985   # cosθ above which the foe is converted

const SLIDER_SCENE := "res://commons/interactables/slider_horizontal.tscn"
const DISPLAY_SIZE := 0.78   # the demo is scaled to sit on the console top

var _rng := RandomNumberGenerator.new()
var _rack_built := false
var _demo_root: Node3D
var _monitor_label: Label3D
var _slider: Node


func _ready() -> void:
	_ensure_rack()
	_build_demo()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("alignment"): alignment = clampf(float(config_data["alignment"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("sculpt_height"): sculpt_height = float(config_data["sculpt_height"])
	if config_data.has("sculpt_width"): sculpt_width = float(config_data["sculpt_width"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	foe_color = _parse_color(config_data.get("foe_color", foe_color), foe_color)
	friend_color = _parse_color(config_data.get("friend_color", friend_color), friend_color)
	_ensure_rack()
	_build_demo()


func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = (value as String).split(",")
		if parts.size() >= 3:
			return Color(float(parts[0]), float(parts[1]), float(parts[2]), 1.0 if parts.size() < 4 else float(parts[3]))
	return fallback


## Rebuilds ONLY the demo (the rack + slider persist). Called once at _ready and
## again every time the slider moves.
func _build_demo() -> void:
	if _demo_root == null:
		return
	for child in _demo_root.get_children():
		_demo_root.remove_child(child)
		child.queue_free()
	_rng.seed = hash(seed)

	var rig := Node3D.new()
	rig.name = "DotAlignerRig"
	_demo_root.add_child(rig)

	# --- geometry of the problem -------------------------------------------------
	var head_y: float = 1.05
	var head: Vector3 = Vector3(0.0, head_y, 0.0)

	# Foe bearing: a seeded angle around the rig, slightly raised.
	var bearing: float = deg_to_rad(_rng.randf_range(28.0, 62.0))
	var reach: float = 1.15
	var dir_to_foe: Vector3 = Vector3(cos(bearing), 0.18, sin(bearing)).normalized()  # vector b
	var foe_pos: Vector3 = head + dir_to_foe * reach

	# Aim direction (vector a) = the foe bearing rotated away by (1-alignment)*MAX.
	var miss_angle: float = (1.0 - alignment) * deg_to_rad(MAX_ANGLE_DEG)
	var aim_dir: Vector3 = dir_to_foe.rotated(Vector3.UP, miss_angle).normalized()
	var dot: float = clampf(aim_dir.dot(dir_to_foe), -1.0, 1.0)
	var theta_deg: float = rad_to_deg(acos(dot))
	# Stay enemy-red until the aim genuinely closes; only then warm toward friend-green.
	var lock: float = clampf((dot - 0.78) / (LOCK_DOT - 0.78), 0.0, 1.0)
	var converted: bool = dot >= LOCK_DOT

	# --- the rig -----------------------------------------------------------------
	var steel := _steel_mat(color_a)
	# pedestal
	var ped := _cylinder(Vector3(0.0, 0.34, 0.0), 0.34, 0.68, steel)
	rig.add_child(ped)
	var collar := _cylinder(Vector3(0.0, 0.72, 0.0), 0.20, 0.12, steel)
	rig.add_child(collar)
	# swivel head
	var head_ball := _sphere(head, 0.16, steel)
	rig.add_child(head_ball)
	# barrel along the aim direction
	var barrel_len: float = 0.62
	var barrel_end: Vector3 = head + aim_dir * barrel_len
	rig.add_child(_cylinder_between(head, barrel_end, 0.052, steel))
	rig.add_child(_sphere(barrel_end, 0.06, _glow_mat(accent, 2.0 if converted else 0.6)))

	# --- the two vectors ---------------------------------------------------------
	var vec_mat := _glow_mat(color_b, 1.3)
	# a = aim (from head, extended past the barrel)
	rig.add_child(_arrow(head, head + aim_dir * (reach * 0.9), 0.028, _glow_mat(accent, 1.4)))
	# b = direction to foe
	rig.add_child(_arrow(head, foe_pos, 0.028, vec_mat))

	# angle arc between a and b at the head
	_add_arc(rig, head, aim_dir, dir_to_foe, 0.42, _glow_mat(accent, 1.6))

	# --- the foe (red) -> friend (green) ----------------------------------------
	var foe_tone: Color = foe_color.lerp(friend_color, lock)
	var foe := _box(foe_pos, Vector3(0.26, 0.26, 0.26), _foe_mat(foe_tone, lock))
	foe.rotation.y = _rng.randf_range(0.0, TAU)
	rig.add_child(foe)
	# little eyes so the cube reads as a creature (echo of catalyst_foe)
	for sx in [-1.0, 1.0]:
		var eye := _sphere(foe_pos + Vector3(0.07 * sx, 0.04, 0.0) + dir_to_foe * 0.12, 0.026,
			_glow_mat(Color(0.05, 0.05, 0.06) if not converted else Color(0.9, 1.0, 0.9), 0.2))
		rig.add_child(eye)

	# --- the lock beam -----------------------------------------------------------
	if lock > 0.05:
		var beam_mat := _glow_mat(accent.lerp(friend_color, lock * 0.6), 1.5 + lock * 4.5)
		var beam := _cylinder_between(barrel_end, foe_pos, 0.014 + 0.045 * lock, beam_mat)
		rig.add_child(beam)

	# --- charge ring (fills with the dot) ---------------------------------------
	var ring := _torus(head, 0.30, 0.022, _glow_mat(accent, 0.4 + lock * 3.2))
	rig.add_child(ring)

	# --- readout -> the monitor (not a billboard) --------------------------------
	var status: String = "FRIEND" if converted else ("LOCKING" if dot > 0.7 else "SEEKING")
	if _monitor_label:
		_monitor_label.text = "DOT  a · b\n\ncos θ = %.3f\nθ = %d°\n\n%s" % [dot, int(roundf(theta_deg)), status]
		_monitor_label.modulate = friend_color.lerp(Color(0.6, 1.0, 0.75), 0.4) if converted else Color(0.55, 0.92, 1.0)

	_settle(rig)


## Builds the console ONCE — the one surface: a body, a monitor screen on the left
## (the readout), a slider on the right (drives alignment), and a mount for the demo.
func _ensure_rack() -> void:
	if _rack_built:
		return
	_rack_built = true

	# console body + top trim
	add_child(_box(Vector3(0.0, 0.46, 0.0), Vector3(1.5, 0.92, 0.62), _panel_mat(Color(0.10, 0.11, 0.13))))
	add_child(_box(Vector3(0.0, 0.93, 0.0), Vector3(1.54, 0.04, 0.66), _panel_mat(Color(0.17, 0.18, 0.21))))

	# the monitor (left): a dark screen with the readout on its face
	var scr := Vector3(-0.48, 1.16, 0.10)
	add_child(_box(scr + Vector3(0.0, 0.0, -0.02), Vector3(0.54, 0.46, 0.05), _panel_mat(Color(0.04, 0.04, 0.06))))
	add_child(_box(scr, Vector3(0.48, 0.40, 0.01), _screen_mat()))
	_monitor_label = Label3D.new()
	_monitor_label.name = "MonitorReadout"
	_monitor_label.font_size = 36
	_monitor_label.pixel_size = 0.0011
	_monitor_label.modulate = Color(0.55, 0.92, 1.0)
	_monitor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_monitor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_monitor_label.position = scr + Vector3(0.0, 0.0, 0.012)
	_monitor_label.text = "DOT"
	add_child(_monitor_label)
	add_child(_label_plate("DOT-PRODUCT ALIGNER", Vector3(-0.48, 1.42, 0.10), 24, Color(0.78, 0.84, 0.94)))

	# the slider (right): drives the alignment DNA parameter
	if ResourceLoader.exists(SLIDER_SCENE):
		var s: Node = load(SLIDER_SCENE).instantiate()
		s.name = "AlignmentSlider"
		add_child(s)
		(s as Node3D).position = Vector3(0.46, 0.95, 0.16)
		if s.has_method("set_param_name"): s.call("set_param_name", "ALIGNMENT")
		if s.has_method("set_range"): s.call("set_range", 0.0, 1.0)
		if s.has_method("set_normalized_value"): s.call("set_normalized_value", alignment)
		if s.has_signal("slider_moved") and not s.is_connected("slider_moved", _on_slider_moved):
			s.connect("slider_moved", _on_slider_moved)
		_slider = s
	add_child(_label_plate("ALIGNMENT  (drag →)", Vector3(0.46, 1.06, 0.16), 20, Color(0.7, 0.8, 0.9)))

	# the demo mount — the 3D demonstration stands on the console top
	_demo_root = Node3D.new()
	_demo_root.name = "DemoMount"
	_demo_root.position = Vector3(0.12, 0.95, -0.02)
	add_child(_demo_root)


## The slider drives alignment, then only the demo rebuilds.
func _on_slider_moved(_value: Variant = null) -> void:
	if _slider and _slider.has_method("get_normalized_value"):
		alignment = clampf(_slider.call("get_normalized_value"), 0.0, 1.0)
	elif _value != null:
		alignment = clampf(float(_value), 0.0, 1.0)
	_build_demo()


# ---------------------------------------------------------------------------
# materials
# ---------------------------------------------------------------------------

func _panel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.25
	m.roughness = 0.8
	return m


func _screen_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.05, 0.05)
	m.emission_enabled = true
	m.emission = Color(0.05, 0.16, 0.13)
	m.emission_energy_multiplier = 0.7
	return m


func _label_plate(text: String, pos: Vector3, font: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.pixel_size = 0.0011
	l.modulate = col
	l.outline_size = 6
	l.position = pos
	return l


func _steel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.7
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = 0.12 if emissive else 0.0
	return m


func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy if emissive else energy * 0.3
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


func _foe_mat(c: Color, lock: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = (0.25 + 0.9 * lock) if emissive else 0.1
	return m


# ---------------------------------------------------------------------------
# primitives
# ---------------------------------------------------------------------------

func _basis_y_to(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	if y.length() < 0.0001:
		return Basis()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


func _cylinder(center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _cylinder_between(a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(_basis_y_to(b - a), (a + b) * 0.5)
	return mi


func _arrow(a: Vector3, b: Vector3, radius: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var dir: Vector3 = (b - a).normalized()
	var head_len: float = 0.14
	var shaft_end: Vector3 = b - dir * head_len
	root.add_child(_cylinder_between(a, shaft_end, radius, mat))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius * 2.6
	cone.height = head_len
	var tip := MeshInstance3D.new()
	tip.mesh = cone
	tip.material_override = mat
	tip.transform = Transform3D(_basis_y_to(dir), (shaft_end + b) * 0.5)
	root.add_child(tip)
	return root


func _sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _torus(center: Vector3, radius: float, tube: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube
	mesh.outer_radius = radius + tube
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _add_arc(parent: Node3D, center: Vector3, va: Vector3, vb: Vector3, radius: float, mat: Material) -> void:
	var steps: int = clampi(complexity + 4, 6, 16)
	var axis: Vector3 = va.cross(vb)
	if axis.length() < 0.0001:
		return
	axis = axis.normalized()
	var total: float = va.angle_to(vb)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var dir: Vector3 = va.rotated(axis, total * t).normalized()
		var dot := _sphere(center + dir * radius, 0.018, mat)
		parent.add_child(dot)


# ---------------------------------------------------------------------------
# settle — centre on the rig footprint and scale to the sculpt envelope
# ---------------------------------------------------------------------------

func _settle(rig: Node3D) -> void:
	var aabb: AABB = _subtree_aabb(rig)
	if aabb.size.length() < 0.001:
		return
	var span: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var target: float = DISPLAY_SIZE
	var s: float = 1.0 if span <= 0.001 else clampf(target / span, 0.2, 4.0)
	rig.scale = Vector3.ONE * s
	# Sit the demo on the console: centre it in X/Z, base at the mount origin.
	var c: Vector3 = aabb.get_center() * s
	rig.position = Vector3(-c.x, -aabb.position.y * s, -c.z)


func _subtree_aabb(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for child in node.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.mesh == null:
				continue
			var local: AABB = mi.mesh.get_aabb()
			var world: AABB = mi.transform * local
			if first:
				out = world
				first = false
			else:
				out = out.merge(world)
		elif child is Node3D:
			var sub: AABB = _subtree_aabb(child as Node3D)
			if sub.size.length() > 0.0001:
				if first:
					out = sub
					first = false
				else:
					out = out.merge(sub)
	return out
