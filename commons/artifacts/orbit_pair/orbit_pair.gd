extends Node3D
class_name OrbitPair

## @identity
## lineage: gravity made playable — F = G m₁m₂ / r², the inverse-square attraction that
##   holds two bodies in orbit about their shared centre of mass. The clean rebuild of the
##   old two-body sim, for the embodied vectors-forces arc (gravity / orbits gap).
## essence: two bodies pull on each other along the line between them, equal and opposite
##   (Newton's third law); they don't fall together because they're falling *around* a
##   point that balances their masses — the barycenter. Make one heavier and that point
##   slides toward it; the orbits resize to match.
## truth: an orbit is two things falling toward each other and missing, forever, around a
##   centre that belongs to neither.
##
## DNA: mass_ratio 0..1 from an equal binary (symmetric) to a dominant star + planet
## (barycenter slides toward the heavy one). seed sets the orbital phase. color_a star,
## color_b planet, accent gravity vectors, orbit_color the paths.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var mass_ratio: float = 0.6
@export var color_a: Color = Color(0.98, 0.82, 0.40)     # the heavier body (star)
@export var color_b: Color = Color(0.45, 0.72, 0.96)     # the lighter body (planet)
@export var accent: Color = Color(0.96, 0.45, 0.42)      # gravity force vectors
@export var orbit_color: Color = Color(0.40, 0.60, 0.72) # the orbit paths
@export var emissive: bool = true
@export var complexity: int = 6
@export var sculpt_height: float = 1.6
@export var sculpt_width: float = 2.6

const SEP := 1.15   # total separation scale

var _built := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not _built:
		_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("mass_ratio"): mass_ratio = clampf(float(config_data["mass_ratio"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("sculpt_height"): sculpt_height = float(config_data["sculpt_height"])
	if config_data.has("sculpt_width"): sculpt_width = float(config_data["sculpt_width"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	orbit_color = _parse_color(config_data.get("orbit_color", orbit_color), orbit_color)
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
	rig.name = "OrbitPairRig"
	add_child(rig)

	# --- the two-body system ----------------------------------------------------
	var m1: float = 1.0 + mass_ratio * 2.6     # heavier (star)
	var m2: float = 1.0                         # lighter (planet)
	var d1: float = SEP * m2 / (m1 + m2)        # star's distance from barycenter
	var d2: float = SEP * m1 / (m1 + m2)        # planet's distance (further, lighter)
	var phi: float = _rng.randf_range(0.0, TAU)
	var radial: Vector3 = Vector3(cos(phi), 0.0, sin(phi))
	var orbit_y: float = 0.5
	var bary: Vector3 = Vector3(0.0, orbit_y, 0.0)
	var p1: Vector3 = bary + radial * d1        # star
	var p2: Vector3 = bary - radial * d2        # planet (opposite side)
	var r: float = p1.distance_to(p2)           # = SEP
	var force: float = m1 * m2 / (r * r)        # G = 1; same magnitude on both (3rd law)

	# --- orbit paths (dotted rings around the barycenter) -----------------------
	_add_orbit_ring(rig, bary, d1, _glow_mat(orbit_color.lerp(color_a, 0.3), 0.7))
	_add_orbit_ring(rig, bary, d2, _glow_mat(orbit_color.lerp(color_b, 0.3), 0.7))
	# barycenter marker
	rig.add_child(_sphere(bary, 0.035, _glow_mat(Color(0.9, 0.9, 0.95), 0.8)))
	rig.add_child(_dashed(p1, p2, 0.01, _glow_mat(Color(0.5, 0.52, 0.58), 0.4)))   # the line of attraction

	# --- the bodies -------------------------------------------------------------
	var r1: float = 0.13 * pow(m1, 0.34)
	var r2: float = 0.13 * pow(m2, 0.34)
	rig.add_child(_sphere(p1, r1, _glow_mat(color_a, 1.6)))                          # star (glows)
	# Halo scales with mass dominance, so an equal binary reads as two equal bodies.
	rig.add_child(_sphere(p1, r1 * (1.15 + mass_ratio * 0.95), _halo_mat(color_a)))  # star halo
	rig.add_child(_sphere(p2, r2, _body_mat(color_b)))                              # planet

	# --- the gravity vectors: equal and opposite, along the connecting line ------
	var to2: Vector3 = (p2 - p1).normalized()
	var fscale: float = 0.5
	rig.add_child(_arrow(p1, p1 + to2 * force * fscale, 0.026, _glow_mat(accent, 1.6)))   # pull on star → planet
	rig.add_child(_arrow(p2, p2 - to2 * force * fscale, 0.026, _glow_mat(accent, 1.6)))   # pull on planet → star

	# --- velocity tangents (which way they're falling-around) -------------------
	var tangent: Vector3 = Vector3(-radial.z, 0.0, radial.x)   # perpendicular to radius
	rig.add_child(_arrow(p1, p1 + tangent * (d1 * 0.7 + 0.12), 0.02, _glow_mat(color_a.lerp(Color.WHITE, 0.3), 1.0)))
	rig.add_child(_arrow(p2, p2 - tangent * (d2 * 0.7 + 0.12), 0.02, _glow_mat(color_b.lerp(Color.WHITE, 0.3), 1.0)))

	# --- readout ----------------------------------------------------------------
	var label := Label3D.new()
	label.text = "F = G m₁m₂ / r²   (equal & opposite)\nm₁ : m₂ = %.1f : 1" % m1
	label.font_size = 28
	label.modulate = Color(0.96, 0.98, 1.0)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = bary + Vector3(0.0, maxf(d1, d2) + 0.32, 0.0)
	rig.add_child(label)

	_settle(rig)


func _add_orbit_ring(parent: Node3D, center: Vector3, radius: float, mat: Material) -> void:
	var n: int = clampi(complexity * 5 + 12, 24, 60)
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		parent.add_child(_sphere(center + Vector3(cos(a) * radius, 0.0, sin(a) * radius), 0.012, mat))


# ---------------------------------------------------------------------------
# materials
# ---------------------------------------------------------------------------

func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy if emissive else energy * 0.3
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


func _body_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	m.metallic = 0.2
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.3 if emissive else 0.1
	return m


func _halo_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.18)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 1.4 if emissive else 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	var head_len: float = 0.11
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
	var n: int = 11
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
