extends Node3D
class_name CircleTrain

## @identity
## lineage: centripetal force made playable — a = v²/r, F = m v²/r — an intermezzo for
##   the embodied vectors-forces arc: a high-speed maglev loop where the train shows its
##   own force vectors and you dial the speed.
## essence: velocity is always tangent to the ring; the force is always inward; and the
##   trick that makes circular motion feel alive is that the inward force grows with the
##   SQUARE of speed — double the speed, quadruple the pull. The train leans into it.
## truth: going in a circle is constant acceleration toward a centre you never reach —
##   straight-line desire bent by a force that only ever points sideways.
##
## DNA: speed 0..1 dials the train — the tangent velocity grows linearly, the inward
## centripetal force grows quadratically (the payoff). seed sets the train's position.
## color_a = neon track, color_b = velocity vector, accent = centripetal force,
## train_color = the glowing cars.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var speed: float = 0.7
@export var color_a: Color = Color(0.20, 0.85, 0.95)     # neon track
@export var color_b: Color = Color(0.55, 0.92, 1.0)      # velocity (tangent)
@export var accent: Color = Color(0.98, 0.42, 0.40)      # centripetal force (inward)
@export var train_color: Color = Color(0.85, 0.50, 0.98) # the glowing train cars
@export var emissive: bool = true
@export var complexity: int = 6
@export var sculpt_height: float = 1.4
@export var sculpt_width: float = 2.8

const TRACK_R := 1.0
const CARS := 4

var _built := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not _built:
		_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("speed"): speed = clampf(float(config_data["speed"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("sculpt_height"): sculpt_height = float(config_data["sculpt_height"])
	if config_data.has("sculpt_width"): sculpt_width = float(config_data["sculpt_width"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	train_color = _parse_color(config_data.get("train_color", train_color), train_color)
	_build()


func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = (value as String).split(",")
		if parts.size() >= 3:
			return Color(float(parts[0]), float(parts[1]), float(parts[2]), 1.0 if parts.size() < 4 else float(parts[3]))
	return fallback


func _ring_point(phi: float, r: float) -> Vector3:
	return Vector3(cos(phi) * r, 0.0, sin(phi) * r)


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_built = true
	_rng.seed = hash(seed)

	var rig := Node3D.new()
	rig.name = "CircleTrainRig"
	add_child(rig)

	# --- the physics ------------------------------------------------------------
	var v: float = lerpf(0.45, 1.5, speed)               # tangential speed
	var a_c: float = v * v / TRACK_R                      # centripetal accel = v²/r
	var run_y: float = 0.16
	var phi: float = _rng.randf_range(0.0, TAU)
	var pos: Vector3 = _ring_point(phi, TRACK_R) + Vector3(0.0, run_y, 0.0)
	var tangent: Vector3 = Vector3(-sin(phi), 0.0, cos(phi))   # CCW direction of travel
	var inward: Vector3 = -Vector3(cos(phi), 0.0, sin(phi))    # toward the centre

	# --- the neon track + hub ---------------------------------------------------
	rig.add_child(_torus(Vector3(0.0, run_y, 0.0), TRACK_R, 0.045, _glow_mat(color_a, 1.6)))
	rig.add_child(_torus(Vector3(0.0, run_y, 0.0), TRACK_R, 0.012, _glow_mat(color_a.lerp(Color.WHITE, 0.4), 2.6)))
	# centre hub + a faint radius spoke to the train (the r in v²/r)
	rig.add_child(_cylinder(Vector3(0.0, run_y * 0.5, 0.0), 0.10, run_y, _steel_mat(Color(0.30, 0.32, 0.38))))
	rig.add_child(_sphere(Vector3(0.0, run_y, 0.0), 0.10, _glow_mat(color_a, 1.0)))
	rig.add_child(_dashed(Vector3(0.0, run_y, 0.0), pos, 0.01, _glow_mat(color_a.lerp(Color(0.2, 0.2, 0.25), 0.5), 0.5)))

	# --- the train (cars trailing behind, leaning into the curve) ---------------
	var car_gap: float = 0.34 / TRACK_R
	for i in range(CARS):
		var cphi: float = phi - car_gap * float(i)
		var cpos: Vector3 = _ring_point(cphi, TRACK_R) + Vector3(0.0, run_y, 0.0)
		var fade: float = float(i) / float(CARS)
		var car := _box(cpos, Vector3(0.16, 0.13, 0.30), _glow_mat(train_color.lerp(color_a, fade * 0.5), lerpf(1.8, 0.7, fade)))
		car.rotation.y = -cphi
		# bank the car into the turn (visual flair, more at speed)
		car.rotation.z = lerpf(0.0, 0.5, speed) * (1.0 if i == 0 else 0.7)
		rig.add_child(car)

	# --- speed streaks behind the lead car (more + longer at speed) -------------
	var streaks: int = clampi(int(speed * 9.0) + 1, 1, 10)
	for i in range(streaks):
		var sphi: float = phi - car_gap * (CARS - 0.2) - 0.10 * float(i)
		var sp: Vector3 = _ring_point(sphi, TRACK_R) + Vector3(0.0, run_y, 0.0)
		rig.add_child(_sphere(sp, lerpf(0.05, 0.012, float(i) / float(streaks)), _glow_mat(color_b, lerpf(1.6, 0.3, float(i) / float(streaks)))))

	# --- the two vectors: velocity (tangent, ∝v) and centripetal (inward, ∝v²) --
	rig.add_child(_arrow(pos, pos + tangent * (v * 0.62), 0.028, _glow_mat(color_b, 1.6)))
	rig.add_child(_arrow(pos, pos + inward * (a_c * 0.42), 0.030, _glow_mat(accent, 1.4 + speed * 2.2)))

	# --- readout ----------------------------------------------------------------
	var label := Label3D.new()
	label.text = "v = %.2f  (tangent)\na = v² / r = %.2f  (inward)\nF_c = m v² / r" % [v, a_c]
	label.font_size = 28
	label.modulate = Color(0.96, 0.98, 1.0)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0.0, run_y + 0.95, 0.0)
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


# ---------------------------------------------------------------------------
# primitives (shared pattern with the operations + forces toys)
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


func _torus(center: Vector3, radius: float, tube: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube
	mesh.outer_radius = radius + tube
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
