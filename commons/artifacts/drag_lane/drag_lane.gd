extends Node3D
class_name DragLane

## @identity
## lineage: friction / drag made felt — F = -b·v, so velocity decays v ∝ e^(-bt) — a
##   forces toy for the embodied vectors-forces arc (the resistance you feel in the legs).
## essence: a runner enters a resistant medium at full tilt and slows; frozen
##   stroboscopically, its snapshots bunch together and its velocity arrows shrink as
##   the drag eats the motion. Run through air, water, honey — each pulls back harder.
## truth: drag is a force that only ever opposes — it never starts you moving, it only
##   spends what you already had; the faster you go, the harder it takes it back.
##
## DNA: drag 0..1 sweeps from glide (snapshots evenly spread) to dead-stop (snapshots
## pile up fast). seed jitters the medium. color_a lane, color_b runner + velocity,
## accent drag particles, medium_color the resistant volume.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var drag: float = 0.5
@export var color_a: Color = Color(0.50, 0.54, 0.60)      # lane / rig
@export var color_b: Color = Color(0.40, 0.82, 0.96)      # runner + velocity arrows
@export var accent: Color = Color(0.98, 0.82, 0.32)       # drag particles
@export var medium_color: Color = Color(0.30, 0.62, 0.85) # the resistant medium
@export var emissive: bool = true
@export var complexity: int = 6
@export var sculpt_height: float = 1.6
@export var sculpt_width: float = 3.0

var _built := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not _built:
		_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("drag"): drag = clampf(float(config_data["drag"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("sculpt_height"): sculpt_height = float(config_data["sculpt_height"])
	if config_data.has("sculpt_width"): sculpt_width = float(config_data["sculpt_width"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	medium_color = _parse_color(config_data.get("medium_color", medium_color), medium_color)
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
	rig.name = "DragLaneRig"
	add_child(rig)

	# --- the decay ---------------------------------------------------------------
	var snaps: int = clampi(complexity + 3, 6, 12)
	var retention: float = clampf(1.0 - drag * 0.62, 0.20, 0.985)   # per-step velocity factor
	var v0: float = 0.46
	var run_y: float = 0.42

	var positions: Array[float] = []
	var speeds: Array[float] = []
	var x: float = 0.0
	for i in range(snaps):
		var v: float = v0 * pow(retention, float(i))
		positions.append(x)
		speeds.append(v)
		x += maxf(v, 0.02)
	var lane_len: float = x + 0.5

	var steel := _steel_mat(color_a)

	# --- lane + start gate ------------------------------------------------------
	rig.add_child(_box(Vector3(lane_len * 0.5, 0.0, 0.0), Vector3(lane_len, 0.06, 0.7), steel))
	rig.add_child(_box(Vector3(0.0, 0.22, 0.0), Vector3(0.08, 0.44, 0.7), steel))           # start gate
	# the axis the runner travels (and the drag force opposes)
	rig.add_child(_arrow(Vector3(0.0, 0.05, 0.34), Vector3(lane_len, 0.05, 0.34), 0.016, _glow_mat(color_a, 0.5)))

	# --- the resistant medium (translucent volume + suspended particles) --------
	var med_start: float = positions[1] if positions.size() > 1 else 0.3
	var med_len: float = lane_len - med_start
	var medium := _box(Vector3(med_start + med_len * 0.5, run_y, 0.0), Vector3(med_len, 0.7, 0.66), _medium_mat(medium_color))
	rig.add_child(medium)
	var motes: int = clampi(int(med_len * 9.0), 8, 40)
	for _i in range(motes):
		var mx: float = _rng.randf_range(med_start, lane_len - 0.1)
		var my: float = run_y + _rng.randf_range(-0.28, 0.30)
		var mz: float = _rng.randf_range(-0.28, 0.28)
		rig.add_child(_sphere(Vector3(mx, my, mz), _rng.randf_range(0.012, 0.024), _glow_mat(accent, 1.0)))

	# --- stroboscopic runner: balls bunch up, velocity arrows shrink ------------
	for i in range(snaps):
		var fade: float = float(i) / float(snaps - 1)
		var ball_col: Color = color_b.lerp(Color(0.16, 0.18, 0.22), fade * 0.7)
		var energy: float = lerpf(1.2, 0.25, fade)
		rig.add_child(_sphere(Vector3(positions[i], run_y, 0.0), 0.13, _glow_mat(ball_col, energy)))
		# velocity arrow (forward), length ∝ speed
		var vlen: float = speeds[i] * 1.05
		if vlen > 0.05:
			var base: Vector3 = Vector3(positions[i], run_y + 0.24, 0.0)
			rig.add_child(_arrow(base, base + Vector3(vlen, 0.0, 0.0), 0.022, _glow_mat(color_b, lerpf(1.5, 0.5, fade))))

	# stop marker where motion has all but died
	rig.add_child(_sphere(Vector3(positions[snaps - 1] + speeds[snaps - 1], run_y, 0.0), 0.06, _glow_mat(accent, 2.4)))

	# --- readout ----------------------------------------------------------------
	var label := Label3D.new()
	label.text = "F = -b·v    v ∝ e^(-bt)\ndrag b = %.2f" % drag
	label.font_size = 28
	label.modulate = Color(0.96, 0.98, 1.0)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(lane_len * 0.5, run_y + 0.85, 0.0)
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


func _medium_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.22)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.25 if emissive else 0.0
	return m


# ---------------------------------------------------------------------------
# primitives (shared pattern with the operations toys)
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
