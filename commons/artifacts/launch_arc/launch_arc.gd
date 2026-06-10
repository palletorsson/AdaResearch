extends Node3D
class_name LaunchArc

## @identity
## lineage: projectile motion made playable — a launch velocity bent into a parabola by
##   gravity — the F=ma / launch toy for the embodied vectors-forces arc (the pad that
##   throws you). Range = v² sin(2θ) / g; the arc is what F=ma does to a thrown vector.
## essence: a launch pad fires at angle θ with speed v; gravity pulls the path into a
##   parabola. The launch velocity decomposes into a horizontal vx and a vertical vy —
##   vx carries you, vy fights gravity, the trade between them sets the range.
## truth: you only ever launch a straight vector; the curve is the world's answer.
##
## DNA: angle 0..1 sets the launch angle (flat → steep), power 0..1 the launch speed.
## seed jitters nothing structural. color_a pad/components, color_b the arc + launch
## vector, accent the apex / range markers.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var angle: float = 0.5
@export_range(0.0, 1.0, 0.01) var power: float = 0.6
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # pad + component arrows
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the arc + launch vector
@export var accent: Color = Color(0.98, 0.72, 0.30)      # pad glow + apex / range
@export var emissive: bool = true
@export var complexity: int = 6
@export var sculpt_height: float = 1.8
@export var sculpt_width: float = 2.8

const GRAVITY := 3.0

var _built := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not _built:
		_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("angle"): angle = clampf(float(config_data["angle"]), 0.0, 1.0)
	if config_data.has("power"): power = clampf(float(config_data["power"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("sculpt_height"): sculpt_height = float(config_data["sculpt_height"])
	if config_data.has("sculpt_width"): sculpt_width = float(config_data["sculpt_width"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
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
	rig.name = "LaunchArcRig"
	add_child(rig)

	# --- the launch -------------------------------------------------------------
	var theta: float = deg_to_rad(lerpf(22.0, 70.0, angle))
	var v0: float = lerpf(2.0, 3.4, power)
	var vx: float = v0 * cos(theta)
	var vy: float = v0 * sin(theta)
	var t_land: float = 2.0 * vy / GRAVITY
	var rng_x: float = vx * t_land                       # range
	var apex_t: float = vy / GRAVITY
	var apex: Vector3 = Vector3(vx * apex_t, vy * apex_t - 0.5 * GRAVITY * apex_t * apex_t, 0.0)

	var pad_y: float = 0.06
	var origin: Vector3 = Vector3(0.0, pad_y, 0.0)

	# --- the launch pad (echoes force_pad) --------------------------------------
	var pad := _box(origin, Vector3(0.42, 0.07, 0.42), _glow_mat(accent, 1.4 + power * 1.6))
	pad.rotation.z = theta * 0.5    # tilt the pad toward the launch
	rig.add_child(pad)
	rig.add_child(_box(Vector3(0.0, pad_y - 0.06, 0.0), Vector3(0.5, 0.06, 0.5), _steel_mat(color_a)))
	# the ground the arc lands on
	var ground_len: float = rng_x + 0.5
	rig.add_child(_box(Vector3(ground_len * 0.5, -0.02, 0.0), Vector3(ground_len, 0.04, 0.6), _steel_mat(color_a)))

	# --- the trajectory (parabola of stroboscopic projectiles) ------------------
	var steps: int = clampi(complexity + 8, 12, 26)
	for i in range(steps + 1):
		var t: float = t_land * float(i) / float(steps)
		var px: float = vx * t
		var py: float = pad_y + vy * t - 0.5 * GRAVITY * t * t
		var fade: float = float(i) / float(steps)
		rig.add_child(_sphere(Vector3(px, py, 0.0), 0.05, _glow_mat(color_b, lerpf(1.4, 0.5, fade))))

	# --- the launch velocity vector + its components ----------------------------
	var launch_dir: Vector3 = Vector3(cos(theta), sin(theta), 0.0)
	var vis: float = 0.62                                  # display scale for velocity
	var lv: Vector3 = origin + launch_dir * v0 * vis
	rig.add_child(_arrow(origin, lv, 0.03, _glow_mat(color_b, 1.6)))
	# horizontal component vx and vertical component vy (dashed, steel)
	var corner: Vector3 = origin + Vector3(vx * vis, 0.0, 0.0)
	rig.add_child(_dashed(origin, corner, 0.018, _glow_mat(color_a, 0.8)))
	rig.add_child(_dashed(corner, lv, 0.018, _glow_mat(color_a, 0.8)))

	# --- apex + range markers ---------------------------------------------------
	rig.add_child(_sphere(apex + Vector3(0.0, pad_y, 0.0), 0.075, _glow_mat(accent, 2.6)))
	rig.add_child(_sphere(Vector3(rng_x, pad_y, 0.0), 0.085, _glow_mat(accent, 2.8)))
	# a faint vertical line marking the apex height
	rig.add_child(_dashed(Vector3(apex.x, pad_y, 0.0), apex + Vector3(0.0, pad_y, 0.0), 0.01,
		_glow_mat(accent.lerp(Color(0.2, 0.2, 0.24), 0.4), 0.4)))

	# --- readout ----------------------------------------------------------------
	var label := Label3D.new()
	label.text = "v₀ = %.1f   θ = %d°\nrange = v² sin 2θ / g = %.2f" % [v0, int(roundf(rad_to_deg(theta))), rng_x]
	label.font_size = 28
	label.modulate = Color(0.96, 0.98, 1.0)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = apex + Vector3(0.0, pad_y + 0.5, 0.0)
	rig.add_child(label)

	_settle(rig)


# ---------------------------------------------------------------------------
# materials
# ---------------------------------------------------------------------------

func _steel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.5
	m.roughness = 0.5
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
# primitives (shared pattern with the operations + drag toys)
# ---------------------------------------------------------------------------

func _basis_y_to(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	if y.length() < 0.0001:
		return Basis()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


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
	var head_len: float = 0.12
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


func _dashed(a: Vector3, b: Vector3, radius: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var n: int = 9
	for i in range(n):
		if i % 2 == 1:
			continue
		root.add_child(_cylinder_between(a.lerp(b, float(i) / float(n)), a.lerp(b, float(i + 1) / float(n)), radius, mat))
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
