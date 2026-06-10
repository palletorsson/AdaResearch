extends Node3D
class_name TorqueCrank

## @identity
## lineage: the cross product made playable — τ = r × F = |r||F|sinθ — the second
##   half of the operations pair (with dot_aligner) for the embodied vectors-forces arc.
## essence: push a lever arm off-axis; the perpendicular torque it produces spins a
##   flywheel. Force along the arm does nothing; force across it spins hardest.
## truth: the cross product is what's left over when two directions refuse to align —
##   a third axis, perpendicular to both, that turns the world.
##
## DNA: leverage 0..1 sets the angle between the arm r and the push F (0 = along the
## arm → zero torque, 1 = perpendicular → max). seed jitters the arm bearing.
## color_a = steel rig, color_b = the arm r, accent = the torque axis τ + flywheel glow.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var leverage: float = 0.78
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # steel rig
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the arm vector r
@export var force_color: Color = Color(0.98, 0.58, 0.30) # the push F
@export var accent: Color = Color(0.98, 0.82, 0.32)      # the torque axis / flywheel
@export var emissive: bool = true
@export var complexity: int = 6
@export var sculpt_height: float = 2.0
@export var sculpt_width: float = 2.2

var _built := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not _built:
		_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("leverage"): leverage = clampf(float(config_data["leverage"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("sculpt_height"): sculpt_height = float(config_data["sculpt_height"])
	if config_data.has("sculpt_width"): sculpt_width = float(config_data["sculpt_width"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	force_color = _parse_color(config_data.get("force_color", force_color), force_color)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_build()


func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = (value as String).split(",")
		if parts.size() >= 3:
			return Color(float(parts[0]), float(parts[1]), float(parts[2]), 1.0 if parts.size() < 4 else float(parts[3]))
	return fallback


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_built = true
	_rng.seed = hash(seed)

	var rig := Node3D.new()
	rig.name = "TorqueCrankRig"
	add_child(rig)

	# --- the physics ------------------------------------------------------------
	var bearing: float = deg_to_rad(_rng.randf_range(-22.0, 22.0))
	var arm_len: float = 0.82
	var hub_y: float = 0.92
	var hub: Vector3 = Vector3(0.0, hub_y, 0.0)
	var r_dir: Vector3 = Vector3(cos(bearing), 0.0, sin(bearing)).normalized()   # vector r (lever arm)
	var arm_tip: Vector3 = hub + r_dir * arm_len
	var phi: float = leverage * (PI * 0.5)                                        # angle of F from the arm
	var f_dir: Vector3 = r_dir.rotated(Vector3.UP, phi).normalized()             # vector F (push)
	var torque_vec: Vector3 = r_dir.cross(f_dir)                                  # τ = r × F (along ±Y)
	var torque_mag: float = clampf(torque_vec.length(), 0.0, 1.0)                # = sin(phi)
	var tau_axis: Vector3 = (Vector3.UP if torque_vec.y >= 0.0 else Vector3.DOWN)
	var theta_deg: float = rad_to_deg(phi)
	var spin_angle: float = torque_mag * deg_to_rad(48.0)                        # how far the wheel has turned

	var steel := _steel_mat(color_a)

	# --- rig: pedestal + axle ---------------------------------------------------
	rig.add_child(_cylinder(Vector3(0.0, 0.22, 0.0), 0.30, 0.44, steel))
	rig.add_child(_cylinder(Vector3(0.0, hub_y * 0.5 + 0.02, 0.0), 0.05, hub_y, steel))   # axle (τ runs up this)
	rig.add_child(_sphere(hub, 0.10, steel))

	# --- flywheel (spins about the axle by spin_angle) --------------------------
	var wheel := Node3D.new()
	wheel.position = hub
	wheel.rotation.y = spin_angle
	rig.add_child(wheel)
	var wheel_glow := _glow_mat(accent, 0.5 + torque_mag * 2.6)
	var rim := _torus(Vector3.ZERO, 0.40, 0.05, wheel_glow)
	wheel.add_child(rim)
	var spokes: int = clampi(complexity, 4, 8)
	for i in range(spokes):
		var ang: float = TAU * float(i) / float(spokes)
		var dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		wheel.add_child(_cylinder_between(Vector3.ZERO, dir * 0.39, 0.02, steel))

	# --- the vectors ------------------------------------------------------------
	# r — the lever arm
	rig.add_child(_arrow(hub, arm_tip, 0.03, _glow_mat(color_b, 1.3)))
	# F — the push at the tip
	rig.add_child(_arrow(arm_tip, arm_tip + f_dir * 0.55, 0.03, _glow_mat(force_color, 1.5)))
	# τ — the torque axis up the axle, length ∝ |r||F|sinθ
	var tau_len: float = 0.25 + torque_mag * 0.85
	rig.add_child(_arrow(hub, hub + tau_axis * tau_len, 0.034, _glow_mat(accent, 1.2 + torque_mag * 2.5)))

	# --- spin indicator: curved arrows around the axle, brightness ∝ torque -----
	if torque_mag > 0.04:
		_add_spin_arrows(rig, hub + tau_axis * (tau_len * 0.55), 0.22, torque_mag, _glow_mat(accent, 1.0 + torque_mag * 3.0))

	# --- readout ----------------------------------------------------------------
	var rpm: int = int(roundf(torque_mag * 320.0))
	var label := Label3D.new()
	label.text = "τ = r × F = |r||F| sin θ = %.2f\nθ = %d°\n%d rpm" % [torque_mag, int(roundf(theta_deg)), rpm]
	label.font_size = 28
	label.modulate = Color(0.96, 0.98, 1.0)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	# Keep the readout low and in front of the rig so a tall τ arrow can't push it off-frame.
	label.position = hub + Vector3(0.0, 0.6, 0.55)
	rig.add_child(label)

	_settle(rig)


# ---------------------------------------------------------------------------
# materials
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# primitives (shared pattern with dot_aligner)
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


func _torus(center: Vector3, radius: float, tube: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube
	mesh.outer_radius = radius + tube
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _add_spin_arrows(parent: Node3D, center: Vector3, radius: float, strength: float, mat: Material) -> void:
	var steps: int = clampi(complexity + 6, 8, 18)
	var sweep: float = lerpf(0.6, 2.4, strength)
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var ang: float = t * sweep
		var dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		var dot := _sphere(center + dir * radius, 0.016, mat)
		parent.add_child(dot)


# ---------------------------------------------------------------------------
# settle
# ---------------------------------------------------------------------------

func _settle(rig: Node3D) -> void:
	var aabb: AABB = _subtree_aabb(rig)
	if aabb.size.length() < 0.001:
		return
	var span: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var target: float = maxf(sculpt_height, sculpt_width)
	var s: float = 1.0 if span <= 0.001 else clampf(target / span, 0.2, 4.0)
	rig.scale = Vector3.ONE * s
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
