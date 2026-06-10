extends Node3D
class_name ProjectionShadow

## @identity
## lineage: vector projection made playable — proj_n(a) = (a · n̂) n̂ — the third
##   operations toy (with dot_aligner and torque_crank) for the embodied vectors-forces arc.
## essence: a sun overhead, an object floating off a rail; the object's shadow lands on the
##   rail, and the shadow's distance from the origin IS a · n̂ — the projection of the
##   object's position onto the axis. The part that doesn't reach the rail is the rejection.
## truth: a projection is the part of one vector that lives along another — the shadow it
##   casts; what's left over is what makes it different.
##
## DNA: projection 0..1 swings the object from perpendicular (no shadow, a ⟂ n̂) to
## along the rail (full shadow, a ∥ n̂). seed jitters length. color_a = rail/axis,
## color_b = the vector a, accent = the projection shadow, sun_color = the light.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var projection: float = 0.7
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # rail / axis n̂
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the vector a
@export var accent: Color = Color(0.98, 0.82, 0.32)      # the projection shadow
@export var sun_color: Color = Color(1.0, 0.92, 0.62)    # the light
@export var emissive: bool = true
@export var complexity: int = 6
@export var sculpt_height: float = 2.0
@export var sculpt_width: float = 2.6

var _built := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not _built:
		_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("projection"): projection = clampf(float(config_data["projection"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("sculpt_height"): sculpt_height = float(config_data["sculpt_height"])
	if config_data.has("sculpt_width"): sculpt_width = float(config_data["sculpt_width"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	sun_color = _parse_color(config_data.get("sun_color", sun_color), sun_color)
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
	rig.name = "ProjectionShadowRig"
	add_child(rig)

	# --- the geometry -----------------------------------------------------------
	var reach: float = _rng.randf_range(1.2, 1.45)            # |a|
	var origin: Vector3 = Vector3.ZERO                        # O on the rail
	var n_hat: Vector3 = Vector3.RIGHT                        # the axis n̂ (+X)
	var alpha: float = acos(clampf(projection, 0.0, 1.0))     # angle of a from the rail
	var px: float = reach * projection                       # a·n̂  = |a| cos α
	var py: float = reach * sqrt(maxf(1.0 - projection * projection, 0.0))  # rejection height
	var p: Vector3 = origin + Vector3(px, py, 0.0)           # the object
	var foot: Vector3 = origin + Vector3(px, 0.0, 0.0)       # where the shadow lands = (a·n̂)n̂
	var proj_len: float = px

	var steel := _steel_mat(color_a)

	# --- the rail (the axis n̂) + a low catch-wall behind it ---------------------
	var rail_len: float = reach + 0.35
	rig.add_child(_box(Vector3(rail_len * 0.5, 0.0, 0.0), Vector3(rail_len, 0.05, 0.18), steel))
	rig.add_child(_arrow(Vector3(0.0, 0.05, 0.0), Vector3(rail_len, 0.05, 0.0), 0.018, _glow_mat(color_a, 0.6)))
	# origin marker
	rig.add_child(_sphere(origin + Vector3(0.0, 0.05, 0.0), 0.05, _glow_mat(Color(0.9, 0.9, 0.95), 0.6)))

	# --- the vector a (O → object) ----------------------------------------------
	rig.add_child(_arrow(origin + Vector3(0.0, 0.05, 0.0), p, 0.03, _glow_mat(color_b, 1.4)))
	# the object casting the shadow
	rig.add_child(_box(p, Vector3(0.20, 0.20, 0.20), _glow_mat(color_b.lerp(Color.WHITE, 0.25), 0.8)))

	# --- the sun + light rays straight down onto the object ---------------------
	var sun_pos: Vector3 = p + Vector3(0.0, 0.95, 0.0)
	rig.add_child(_sphere(sun_pos, 0.16, _glow_mat(sun_color, 4.5)))
	# faint rays from sun, down through the object to the foot (the cast direction)
	var ray_mat := _glow_mat(sun_color, 0.5)
	for dx in [-0.07, 0.0, 0.07]:
		rig.add_child(_cylinder_between(sun_pos + Vector3(dx, 0.0, 0.0), foot + Vector3(dx, 0.0, 0.0), 0.004, ray_mat))

	# --- the projection (the shadow): O → foot, bright on the rail --------------
	rig.add_child(_box(Vector3(proj_len * 0.5, 0.028, 0.0), Vector3(maxf(proj_len, 0.02), 0.06, 0.22),
		_glow_mat(accent, 1.4 + 1.6 * projection)))
	rig.add_child(_sphere(foot + Vector3(0.0, 0.04, 0.0), 0.07, _glow_mat(accent, 2.4)))
	# a flat shadow blob of the object on the rail
	rig.add_child(_box(foot + Vector3(0.0, 0.03, 0.0), Vector3(0.22, 0.012, 0.22), _shadow_mat()))

	# --- the rejection (object → foot, the perpendicular drop) ------------------
	if py > 0.03:
		rig.add_child(_dashed(p, foot, 0.014, _glow_mat(color_b.lerp(Color(0.2, 0.2, 0.24), 0.5), 0.5)))

	# --- readout ----------------------------------------------------------------
	var label := Label3D.new()
	label.text = "proj = (a · n̂) n̂\na · n̂ = %.2f   α = %d°" % [proj_len, int(roundf(rad_to_deg(alpha)))]
	label.font_size = 28
	label.modulate = Color(0.96, 0.98, 1.0)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = p + Vector3(0.0, 0.55, 0.0)
	rig.add_child(label)

	_settle(rig)


# ---------------------------------------------------------------------------
# materials
# ---------------------------------------------------------------------------

func _steel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.6
	m.roughness = 0.45
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


func _shadow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.05, 0.07)
	m.roughness = 1.0
	return m


# ---------------------------------------------------------------------------
# primitives (shared pattern with dot_aligner / torque_crank)
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
	var head_len: float = 0.13
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
	var n: int = 7
	for i in range(n):
		if i % 2 == 1:
			continue
		var t0: float = float(i) / float(n)
		var t1: float = float(i + 1) / float(n)
		root.add_child(_cylinder_between(a.lerp(b, t0), a.lerp(b, t1), radius, mat))
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
