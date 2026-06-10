# rhizome_vault.gd
# A walk-in ~10x10 m cluster of low dome pods joined by open tunnel ribs.
# Post-crisis architecture: after the tower cracks, you grow sideways.
# No main entrance, no centre, no front — six vaults, many doors, the middle
# of the footprint left deliberately empty (the absent center), emissive
# root-runners crawling the ground and up over the domes, pulsing.
#
# @identity
# essence: A building with no root. Six squashed vault-pods scattered so that
#   their centroid is empty ground; every pod connects sideways to 2-4 others
#   through open arch-rib tunnels, and at least one connection crosses
#   another's path — the graph refuses to be a tree. Entrances face outward
#   on four sides at once: no door is THE door.
# desire: To be entered from anywhere. To never be approached frontally,
#   because it has no front. To let the walker discover that the middle —
#   where a foundation, an altar, a root would stand — holds nothing but
#   floor, and that nothing is what holds the whole thing together.
# critical_parameter: connection_density — the slider between tree and
#   rhizome. At zero the pods hold only their sideways ring; raise it and
#   chords multiply, paths cross, hierarchy becomes unrecoverable.
# triggers: walk in through any archway → a pod interior breathes in its own
#   hue, out of sync with its neighbours; follow a glowing root-runner across
#   the ground → a light-pulse overtakes you, climbs the dome, and the nodule
#   where root meets vault flares as it arrives.
# emerges: The felt sense that connection, not foundation, is what carries
#   load here. You cannot stand at the heart of it — there is no heart —
#   yet every pod is reachable from every other, and from outside.
# relationships: foundationscrisis — this is what gets built after that tower
#   cracked; rhizome_navigator (graph theory) — the same refusal of the tree,
#   here at architectural scale you walk through instead of look at; the
#   biome ring — growth as architecture, runners as roots made visible.
# truth: After the proof fails, grow sideways — every point is a beginning.
extends Node3D
class_name RhizomeVault

# ── DNA (overridable via apply_grid_config) ─────────────────────────────────
@export var pod_count: int = 6                 # number of vault pods (3..10)
@export_range(0.0, 1.0) var connection_density: float = 0.5  # tree→rhizome slider
@export var rng_seed: int = 19                 # deterministic layout seed
@export var runner_color: Color = Color(0.55, 0.92, 0.38, 1.0)  # bio-green base

# ── Architectural constants ─────────────────────────────────────────────────
const FOOTPRINT_HALF: float = 5.0       # ~10x10 m footprint
const GROUND_TOP: float = 0.03          # top surface of the ground plate
const TUNNEL_WIDTH: float = 1.6         # outer arch width
const TUNNEL_HEIGHT: float = 2.2        # arch crown height
const DOOR_CLEAR_HALF: float = 0.72     # half clear width of dome openings
const EMPTY_CENTRE_RADIUS: float = 1.6  # no pod may sit this close to centroid
const AMBER: Color = Color(1.0, 0.72, 0.25, 1.0)

# ── Runtime state ───────────────────────────────────────────────────────────
var _build_root: Node3D = null
var _built: bool = false
var _time: float = 0.0
var _centroid: Vector3 = Vector3.ZERO
var _crossing_point: Vector3 = Vector3.ZERO
var _has_crossing: bool = false

# Pod entries: {pos: Vector3 (y=0), r: float, h: float, links: Array[int],
#               entrance: bool, openings: Array[float], hue: Color}
var _pods: Array = []
# Connection entries: [ia, ib]
var _connections: Array = []
# Runner entries: {points, cum, total, phase, speed, bead, start_mat, end_mat}
var _runners: Array = []
# Pod interior lights (breathe out of sync).
var _pod_lights: Array = []
var _light_base: Array = []
var _breath_speed: Array = []
var _breath_phase: Array = []


func _ready() -> void:
	_build()


# ── Grid integration ─────────────────────────────────────────────────────────
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("pod_count"):
		pod_count = int(config_data["pod_count"])
	if config_data.has("connection_density"):
		connection_density = clampf(float(config_data["connection_density"]), 0.0, 1.0)
	if config_data.has("seed"):
		rng_seed = int(config_data["seed"])
	if config_data.has("rng_seed"):
		rng_seed = int(config_data["rng_seed"])
	if config_data.has("runner_color"):
		var rc = config_data["runner_color"]
		if rc is Color:
			runner_color = rc
		elif rc is String:
			runner_color = Color.from_string(rc, runner_color)
	if config_data.has("scale"):
		var scale_factor: float = float(config_data["scale"])
		if scale_factor > 0.01:
			scale = Vector3.ONE * scale_factor
	if _built:
		_build()


# ── Build orchestration ──────────────────────────────────────────────────────
func _build() -> void:
	if _build_root != null and is_instance_valid(_build_root):
		_build_root.queue_free()
	_build_root = Node3D.new()
	_build_root.name = "Generated"
	add_child(_build_root)

	_pods.clear()
	_connections.clear()
	_runners.clear()
	_pod_lights.clear()
	_light_base.clear()
	_breath_speed.clear()
	_breath_phase.clear()
	_has_crossing = false

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed

	_layout_pods(rng)
	_plan_connections(rng)
	_find_crossing()
	_build_ground()
	_build_pods(rng)
	_build_tunnels()
	_build_runners(rng)
	_build_labels()
	_build_capture_camera()

	_built = true


# ── Layout: a-central seeded scatter ────────────────────────────────────────
func _layout_pods(rng: RandomNumberGenerator) -> void:
	var n: int = clampi(pod_count, 3, 10)
	var hue_start: float = rng.randf()
	for i in range(n):
		var base_az: float = TAU * float(i) / float(n)
		var az: float = base_az + rng.randf_range(-0.18, 0.18)
		var ring_r: float = 3.25 + rng.randf_range(-0.35, 0.35)
		var pod_r: float = rng.randf_range(1.3, 1.6)
		var pod_h: float = rng.randf_range(2.2, 2.8)
		var pod_hue_f: float = fposmod(hue_start + 0.381966 * float(i), 1.0)
		_pods.append({
			"pos": Vector3(cos(az) * ring_r, 0.0, sin(az) * ring_r),
			"r": pod_r,
			"h": pod_h,
			"links": [],
			"entrance": false,
			"openings": [],
			"hue": Color.from_hsv(pod_hue_f, rng.randf_range(0.5, 0.7), 0.95),
		})
	# Relax overlaps, keep everything inside the footprint.
	for _relax_pass in range(6):
		for i in range(n):
			for j in range(i + 1, n):
				var pa: Dictionary = _pods[i]
				var pb: Dictionary = _pods[j]
				var delta: Vector3 = (pb["pos"] as Vector3) - (pa["pos"] as Vector3)
				var dist: float = delta.length()
				var want: float = float(pa["r"]) + float(pb["r"]) + 0.7
				if dist < want and dist > 0.001:
					var push: Vector3 = delta / dist * ((want - dist) * 0.5)
					pa["pos"] = (pa["pos"] as Vector3) - push
					pb["pos"] = (pb["pos"] as Vector3) + push
		for i in range(n):
			var pd: Dictionary = _pods[i]
			var p: Vector3 = pd["pos"]
			p.y = 0.0
			var d_origin: float = p.length()
			var max_r: float = FOOTPRINT_HALF - 0.15 - float(pd["r"])
			if d_origin > max_r and d_origin > 0.001:
				p = p / d_origin * max_r
			elif d_origin < 1.9 and d_origin > 0.001:
				p = p / d_origin * 1.9
			pd["pos"] = p
	# The absent center: compute the centroid and push every pod off it.
	var centroid: Vector3 = Vector3.ZERO
	for pd in _pods:
		centroid += pd["pos"] as Vector3
	centroid /= float(n)
	centroid.y = 0.0
	_centroid = centroid
	for pd in _pods:
		var p: Vector3 = pd["pos"]
		var away: Vector3 = p - centroid
		if away.length() < EMPTY_CENTRE_RADIUS:
			var dirn: Vector3 = Vector3(1, 0, 0)
			if away.length() > 0.01:
				dirn = away.normalized()
			pd["pos"] = centroid + dirn * EMPTY_CENTRE_RADIUS


# ── Connections: ring + crossing chords + density extras ───────────────────
func _plan_connections(rng: RandomNumberGenerator) -> void:
	var n: int = _pods.size()
	var degree_arr: Array = []
	for i in range(n):
		degree_arr.append(0)
	var keyset: Dictionary = {}
	# Sideways ring — every pod holds at least two neighbours.
	for i in range(n):
		_try_add_connection(i, (i + 1) % n, degree_arr, keyset)
	# Two chords that cross each other — rhizomes don't respect planarity.
	if n >= 4:
		_try_add_connection(0, 2, degree_arr, keyset)
		_try_add_connection(1, 3, degree_arr, keyset)
	# Density-driven extra chords (tree → rhizome slider).
	var extras: int = clampi(roundi(clampf(connection_density, 0.0, 1.0) * 3.0), 0, 4)
	var added: int = 0
	var start_i: int = rng.randi_range(0, n - 1)
	for k in range(n):
		if added >= extras:
			break
		var ia: int = (start_i + k) % n
		var ib: int = (ia + 2) % n
		if _try_add_connection(ia, ib, degree_arr, keyset):
			added += 1
	# Many entrances: the 4 least-connected pods get outward archways too.
	var order: Array = []
	for i in range(n):
		order.append(i)
	order.sort_custom(func(a, b): return int(degree_arr[a]) < int(degree_arr[b]))
	var entrance_total: int = mini(4, n)
	for k in range(entrance_total):
		var pe: Dictionary = _pods[int(order[k])]
		pe["entrance"] = true
	# Record opening azimuths per pod (links + outward entrance).
	for i in range(n):
		var pd: Dictionary = _pods[i]
		var pos: Vector3 = pd["pos"]
		var op: Array = pd["openings"]
		for li in pd["links"]:
			var other: Vector3 = (_pods[int(li)] as Dictionary)["pos"]
			op.append(atan2(other.z - pos.z, other.x - pos.x))
		if bool(pd["entrance"]):
			var outward: Vector3 = pos - _centroid
			op.append(atan2(outward.z, outward.x))


func _try_add_connection(ia: int, ib: int, degree_arr: Array, keyset: Dictionary) -> bool:
	if ia == ib:
		return false
	var lo: int = mini(ia, ib)
	var hi: int = maxi(ia, ib)
	var key: String = "%d_%d" % [lo, hi]
	if keyset.has(key):
		return false
	if int(degree_arr[ia]) >= 4 or int(degree_arr[ib]) >= 4:
		return false
	keyset[key] = true
	degree_arr[ia] = int(degree_arr[ia]) + 1
	degree_arr[ib] = int(degree_arr[ib]) + 1
	_connections.append([ia, ib])
	var la: Array = (_pods[ia] as Dictionary)["links"]
	la.append(ib)
	var lb: Array = (_pods[ib] as Dictionary)["links"]
	lb.append(ia)
	return true


func _find_crossing() -> void:
	if _pods.size() < 4:
		return
	var a0: Vector3 = (_pods[0] as Dictionary)["pos"]
	var a1: Vector3 = (_pods[2] as Dictionary)["pos"]
	var b0: Vector3 = (_pods[1] as Dictionary)["pos"]
	var b1: Vector3 = (_pods[3] as Dictionary)["pos"]
	var hit: Dictionary = _segment_cross_xz(a0, a1, b0, b1)
	if bool(hit.get("hit", false)):
		_has_crossing = true
		_crossing_point = hit["point"]


func _segment_cross_xz(a0: Vector3, a1: Vector3, b0: Vector3, b1: Vector3) -> Dictionary:
	var p: Vector2 = Vector2(a0.x, a0.z)
	var r: Vector2 = Vector2(a1.x, a1.z) - p
	var q: Vector2 = Vector2(b0.x, b0.z)
	var s_vec: Vector2 = Vector2(b1.x, b1.z) - q
	var denom: float = r.cross(s_vec)
	if absf(denom) < 0.0001:
		return {"hit": false}
	var t_par: float = (q - p).cross(s_vec) / denom
	var u_par: float = (q - p).cross(r) / denom
	if t_par > 0.05 and t_par < 0.95 and u_par > 0.05 and u_par < 0.95:
		var hp: Vector2 = p + r * t_par
		return {"hit": true, "point": Vector3(hp.x, 0.0, hp.y)}
	return {"hit": false}


# ── Ground plate + collider ─────────────────────────────────────────────────
func _build_ground() -> void:
	var plate: MeshInstance3D = MeshInstance3D.new()
	plate.name = "GroundPlate"
	var pm: BoxMesh = BoxMesh.new()
	pm.size = Vector3(FOOTPRINT_HALF * 2.0 - 0.2, 0.06, FOOTPRINT_HALF * 2.0 - 0.2)
	plate.mesh = pm
	var plate_mat: StandardMaterial3D = StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.055, 0.06, 0.055, 1.0)
	plate_mat.roughness = 0.95
	plate.material_override = plate_mat
	plate.position = Vector3(0.0, GROUND_TOP - 0.03, 0.0)
	_build_root.add_child(plate)

	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "FloorBody"
	var fshape: CollisionShape3D = CollisionShape3D.new()
	var fbox: BoxShape3D = BoxShape3D.new()
	fbox.size = Vector3(FOOTPRINT_HALF * 2.0, 0.1, FOOTPRINT_HALF * 2.0)
	fshape.shape = fbox
	fshape.position = Vector3(0.0, GROUND_TOP - 0.05, 0.0)
	floor_body.add_child(fshape)
	_build_root.add_child(floor_body)


# ── Pods: cut-open squashed domes, lights, spores, colliders, arches ───────
func _build_pods(rng: RandomNumberGenerator) -> void:
	for i in range(_pods.size()):
		var pd: Dictionary = _pods[i]
		var pos: Vector3 = pd["pos"]
		var pod_r: float = float(pd["r"])
		var pod_h: float = float(pd["h"])
		var pod_hue: Color = pd["hue"]
		var openings: Array = pd["openings"]
		var half_angle: float = asin(clampf(DOOR_CLEAR_HALF / pod_r, 0.2, 0.95))
		var door_h: float = minf(2.0, pod_h * 0.82)

		var pod_node: Node3D = Node3D.new()
		pod_node.name = "Pod%d" % i
		pod_node.position = Vector3(pos.x, GROUND_TOP, pos.z)
		_build_root.add_child(pod_node)

		# Dome shell with real holes at every opening.
		var dome: MeshInstance3D = MeshInstance3D.new()
		dome.name = "Dome"
		dome.mesh = _build_dome_mesh(pod_r, pod_h, openings, half_angle, door_h)
		var dome_mat: StandardMaterial3D = StandardMaterial3D.new()
		dome_mat.albedo_color = Color(0.16, 0.145, 0.125, 1.0).lerp(pod_hue, 0.12)
		dome_mat.roughness = 0.92
		dome_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		dome.material_override = dome_mat
		pod_node.add_child(dome)

		# Interior light — a different hue per pod; heterogeneity, not identity.
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "PodLight"
		light.light_color = pod_hue
		light.omni_range = pod_r * 2.6
		light.shadow_enabled = false
		var base_energy: float = 1.1 + rng.randf_range(0.0, 0.35)
		light.light_energy = base_energy
		light.position = Vector3(0.0, pod_h * 0.45, 0.0)
		pod_node.add_child(light)
		_pod_lights.append(light)
		_light_base.append(base_energy)
		_breath_speed.append(rng.randf_range(0.5, 1.1))
		_breath_phase.append(rng.randf_range(0.0, TAU))

		# Spore-spheres at varied heights.
		var spore_total: int = rng.randi_range(2, 3)
		for _sp in range(spore_total):
			var rf: float = rng.randf_range(0.25, 0.65)
			var ceil_y: float = pod_h * sqrt(maxf(1.0 - rf * rf, 0.0))
			var sy: float = rng.randf_range(0.45, maxf(0.5, ceil_y * 0.75))
			var saz: float = rng.randf_range(0.0, TAU)
			var spore: MeshInstance3D = MeshInstance3D.new()
			var sm: SphereMesh = SphereMesh.new()
			var sr: float = rng.randf_range(0.05, 0.09)
			sm.radius = sr
			sm.height = sr * 2.0
			sm.radial_segments = 12
			sm.rings = 6
			spore.mesh = sm
			spore.material_override = _make_emissive_mat(pod_hue, 2.2)
			spore.position = Vector3(cos(saz) * rf * pod_r, sy, sin(saz) * rf * pod_r)
			pod_node.add_child(spore)

		# Approximate wall colliders — sector boxes, archways left open.
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "PodWalls"
		var sectors: int = 12
		for s in range(sectors):
			var saz2: float = TAU * (float(s) + 0.5) / float(sectors)
			if _azimuth_in_openings(saz2, openings, half_angle + 0.10):
				continue
			var cshape: CollisionShape3D = CollisionShape3D.new()
			var cbox: BoxShape3D = BoxShape3D.new()
			cbox.size = Vector3(2.0 * pod_r * sin(PI / float(sectors)) + 0.1, door_h, 0.2)
			cshape.shape = cbox
			var wall_r: float = pod_r * 0.93
			cshape.position = Vector3(cos(saz2) * wall_r, door_h * 0.5, sin(saz2) * wall_r)
			cshape.rotation = Vector3(0.0, -saz2 - PI * 0.5, 0.0)
			body.add_child(cshape)
		pod_node.add_child(body)

		# Outward archway frame for entrance pods — no door is the door.
		if bool(pd["entrance"]):
			var outward: Vector3 = pos - _centroid
			outward.y = 0.0
			if outward.length() > 0.01:
				outward = outward.normalized()
			else:
				outward = Vector3(1, 0, 0)
			var arch_pos: Vector3 = Vector3(pos.x, GROUND_TOP, pos.z) + outward * pod_r
			_add_arch_rib(_build_root, arch_pos, outward, 1.55, minf(TUNNEL_HEIGHT, door_h + 0.25), _tunnel_mat())


# ── Tunnels: open arch-rib pairs + floor strips ─────────────────────────────
func _build_tunnels() -> void:
	var rib_mat: StandardMaterial3D = _tunnel_mat()
	var strip_mat: StandardMaterial3D = StandardMaterial3D.new()
	strip_mat.albedo_color = Color(0.09, 0.08, 0.06, 1.0)
	strip_mat.roughness = 0.85
	strip_mat.emission_enabled = true
	strip_mat.emission = AMBER
	strip_mat.emission_energy_multiplier = 0.12
	for conn in _connections:
		var pa: Dictionary = _pods[int(conn[0])]
		var pb: Dictionary = _pods[int(conn[1])]
		var a_pos: Vector3 = pa["pos"]
		var b_pos: Vector3 = pb["pos"]
		var dirn: Vector3 = b_pos - a_pos
		dirn.y = 0.0
		var span: float = dirn.length()
		if span < 0.01:
			continue
		dirn = dirn / span
		var start_p: Vector3 = a_pos + dirn * float(pa["r"])
		var end_p: Vector3 = b_pos - dirn * float(pb["r"])
		var gap: float = start_p.distance_to(end_p)
		if gap < 0.05:
			continue
		# Floor strip — slightly proud of the ground, tucked under both pods.
		var strip: MeshInstance3D = MeshInstance3D.new()
		var sbox: BoxMesh = BoxMesh.new()
		sbox.size = Vector3(TUNNEL_WIDTH, 0.025, gap + 0.5)
		strip.mesh = sbox
		strip.material_override = strip_mat
		var mid: Vector3 = (start_p + end_p) * 0.5
		strip.transform = Transform3D(Basis.looking_at(dirn, Vector3.UP), Vector3(mid.x, GROUND_TOP + 0.012, mid.z))
		_build_root.add_child(strip)
		# Arch rib pairs along the gap — open-ended, walk straight through.
		if gap < 0.5:
			continue
		var stations: int = clampi(roundi(gap / 1.1), 1, 4)
		for st_i in range(stations):
			var f: float = (float(st_i) + 0.5) / float(stations)
			var base_p: Vector3 = start_p.lerp(end_p, f)
			base_p.y = GROUND_TOP
			_add_arch_rib(_build_root, base_p - dirn * 0.12, dirn, TUNNEL_WIDTH, TUNNEL_HEIGHT, rib_mat)
			_add_arch_rib(_build_root, base_p + dirn * 0.12, dirn, TUNNEL_WIDTH, TUNNEL_HEIGHT, rib_mat)


# ── Runners: branching emissive root-lines, ground + dome surface ───────────
func _build_runners(rng: RandomNumberGenerator) -> void:
	var n: int = _pods.size()
	if n < 2:
		return
	var ground_y: float = GROUND_TOP + 0.05
	var runner_total: int = clampi(n - 1, 3, 6)
	for _rk in range(runner_total):
		var ia: int = rng.randi_range(0, n - 1)
		var ib: int = (ia + 1 + rng.randi_range(0, n - 2)) % n
		var pa: Dictionary = _pods[ia]
		var pb: Dictionary = _pods[ib]
		var a_pos: Vector3 = pa["pos"]
		var b_pos: Vector3 = pb["pos"]
		var dirn: Vector3 = b_pos - a_pos
		dirn.y = 0.0
		if dirn.length() < 0.01:
			continue
		dirn = dirn.normalized()
		var side: Vector3 = Vector3(-dirn.z, 0.0, dirn.x)
		var hue_col: Color = runner_color.lerp(AMBER, rng.randf_range(0.0, 0.55))
		var strip_mat: StandardMaterial3D = _make_emissive_mat(hue_col, 1.6)

		var start_p: Vector3 = a_pos + dirn * (float(pa["r"]) * 0.98)
		var end_p: Vector3 = b_pos - dirn * (float(pb["r"]) * 0.98)
		start_p.y = ground_y
		end_p.y = ground_y

		# Ground polyline, 4-7 segments with lateral wobble.
		var seg_count: int = rng.randi_range(4, 7)
		var pts: PackedVector3Array = PackedVector3Array()
		pts.append(start_p)
		for s in range(1, seg_count):
			var f: float = float(s) / float(seg_count)
			var wobble: float = sin(f * PI)
			var p: Vector3 = start_p.lerp(end_p, f) + side * (rng.randf_range(-0.55, 0.55) * wobble)
			p.y = ground_y
			pts.append(p)
		pts.append(end_p)

		# Climb up over the destination dome along its surface.
		var az_b: float = atan2(end_p.z - b_pos.z, end_p.x - b_pos.x)
		var climb_steps: int = rng.randi_range(2, 3)
		var r_b: float = float(pb["r"])
		var h_b: float = float(pb["h"])
		for c in range(1, climb_steps + 1):
			var elev: float = 0.95 * float(c) / float(climb_steps + 1)
			var sp: Vector3 = b_pos + _dome_point(r_b * 1.03, h_b * 1.03, elev, az_b)
			sp.y += GROUND_TOP
			pts.append(sp)

		# Render strips.
		for idx in range(1, pts.size()):
			_add_strip(_build_root, pts[idx - 1], pts[idx], 0.08, strip_mat)

		# Branches — once or twice, off into the ground between pods.
		var branch_total: int = rng.randi_range(1, 2)
		for _bk in range(branch_total):
			var m: int = rng.randi_range(1, maxi(1, seg_count - 1))
			var prev_p: Vector3 = pts[m]
			var flip: float = 1.0
			if rng.randf() < 0.5:
				flip = -1.0
			var bdir: Vector3 = dirn.rotated(Vector3.UP, rng.randf_range(0.7, 1.4) * flip)
			var b_segs: int = rng.randi_range(2, 3)
			for _s2 in range(b_segs):
				var nxt: Vector3 = prev_p + bdir.rotated(Vector3.UP, rng.randf_range(-0.5, 0.5)) * rng.randf_range(0.5, 1.0)
				nxt.y = ground_y
				if Vector2(nxt.x, nxt.z).length() > FOOTPRINT_HALF - 0.3:
					break
				_add_strip(_build_root, prev_p, nxt, 0.06, strip_mat)
				prev_p = nxt

		# Nodules where the runner meets each pod.
		var start_mat: StandardMaterial3D = _make_emissive_mat(hue_col, 0.7)
		var end_mat: StandardMaterial3D = _make_emissive_mat(hue_col, 0.7)
		_add_nodule(_build_root, pts[0] + Vector3(0, 0.03, 0), start_mat)
		_add_nodule(_build_root, pts[pts.size() - 1], end_mat)

		# Pulse bead that travels the polyline.
		var bead: MeshInstance3D = MeshInstance3D.new()
		var bm: SphereMesh = SphereMesh.new()
		bm.radius = 0.055
		bm.height = 0.11
		bm.radial_segments = 10
		bm.rings = 5
		bead.mesh = bm
		bead.material_override = _make_emissive_mat(hue_col.lerp(Color.WHITE, 0.3), 5.0)
		bead.position = pts[0]
		_build_root.add_child(bead)

		# Cumulative arc lengths for sampling.
		var cum: PackedFloat32Array = PackedFloat32Array()
		cum.append(0.0)
		var total: float = 0.0
		for idx in range(1, pts.size()):
			total += pts[idx - 1].distance_to(pts[idx])
			cum.append(total)

		_runners.append({
			"points": pts,
			"cum": cum,
			"total": total,
			"phase": rng.randf(),
			"speed": rng.randf_range(0.10, 0.18),
			"bead": bead,
			"start_mat": start_mat,
			"end_mat": end_mat,
		})


func _add_nodule(parent: Node3D, pos: Vector3, mat: StandardMaterial3D) -> void:
	var nod: MeshInstance3D = MeshInstance3D.new()
	var nm: SphereMesh = SphereMesh.new()
	nm.radius = 0.085
	nm.height = 0.17
	nm.radial_segments = 12
	nm.rings = 6
	nod.mesh = nm
	nod.material_override = mat
	nod.position = pos
	parent.add_child(nod)


# ── Ground texts near two different entrances (no entrance is primary) ──────
func _build_labels() -> void:
	var texts: Array = [
		"RHIZOME\nenter anywhere",
		"no root. no center.\na map, not a tracing.",
	]
	var placed: int = 0
	for i in range(_pods.size()):
		if placed >= texts.size():
			break
		var pd: Dictionary = _pods[i]
		if not bool(pd["entrance"]):
			continue
		var pos: Vector3 = pd["pos"]
		var out_dir: Vector3 = pos - _centroid
		out_dir.y = 0.0
		if out_dir.length() < 0.01:
			out_dir = Vector3(1, 0, 0)
		else:
			out_dir = out_dir.normalized()
		var lbl: Label3D = Label3D.new()
		lbl.text = texts[placed]
		lbl.font_size = 46
		lbl.pixel_size = 0.0058
		lbl.modulate = Color(1.0, 0.93, 0.78, 1.0)
		lbl.outline_size = 10
		lbl.outline_modulate = Color(0.05, 0.06, 0.04, 1.0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var lp: Vector3 = pos + out_dir * (float(pd["r"]) + 1.15)
		lp.y = 0.0
		if lp.length() > FOOTPRINT_HALF - 0.4:
			lp = lp.normalized() * (FOOTPRINT_HALF - 0.4)
		lp.y = GROUND_TOP + 0.025
		lbl.position = lp
		lbl.rotation_degrees = Vector3(-90.0, rad_to_deg(atan2(out_dir.x, out_dir.z)), 0.0)
		_build_root.add_child(lbl)
		placed += 1


# ── CaptureCamera: inside the cluster, among it, not in front of it ─────────
func _build_capture_camera() -> void:
	var cam: Camera3D = Camera3D.new()
	cam.name = "CaptureCamera"
	cam.current = false
	cam.fov = 72.0
	cam.near = 0.05
	var target: Vector3
	if _has_crossing:
		target = _crossing_point
	elif _pods.size() > 0:
		target = (_pods[0] as Dictionary)["pos"]
	else:
		target = Vector3(1, 0, 0)
	target.y = 1.15
	var cam_pos: Vector3 = _centroid
	cam_pos.y = 1.6
	var aim: Vector3 = target - cam_pos
	if aim.length() < 0.1:
		aim = Vector3(1, 0, 0)
	# Step back a little from the empty centre so two pods flank the frame.
	cam_pos -= aim.normalized() * 0.7
	cam_pos.y = 1.6
	var look_dir: Vector3 = (target - cam_pos).normalized()
	cam.transform = Transform3D(Basis.looking_at(look_dir, Vector3.UP), cam_pos)
	_build_root.add_child(cam)


# ── Living: pulses propagate, pods breathe out of sync ──────────────────────
func _process(delta: float) -> void:
	_time += delta
	for i in range(_pod_lights.size()):
		var li: OmniLight3D = _pod_lights[i]
		if not is_instance_valid(li):
			continue
		var breath: float = 0.5 + 0.5 * sin(_time * float(_breath_speed[i]) + float(_breath_phase[i]))
		li.light_energy = float(_light_base[i]) * (0.65 + 0.55 * breath)
	for rd in _runners:
		var runner: Dictionary = rd
		var total: float = float(runner["total"])
		if total <= 0.001:
			continue
		var t: float = fposmod(_time * float(runner["speed"]) + float(runner["phase"]), 1.0)
		var bead: MeshInstance3D = runner["bead"]
		if is_instance_valid(bead):
			bead.position = _sample_polyline(runner["points"], runner["cum"], t * total) + Vector3(0, 0.04, 0)
		var end_mat: StandardMaterial3D = runner["end_mat"]
		if end_mat != null:
			end_mat.emission_energy_multiplier = 0.7 + 5.0 * _pulse_window(t, 0.97, 0.10)
		var start_mat: StandardMaterial3D = runner["start_mat"]
		if start_mat != null:
			start_mat.emission_energy_multiplier = 0.7 + 5.0 * _pulse_window(t, 0.03, 0.10)


func _pulse_window(t: float, center: float, width: float) -> float:
	var d: float = absf(wrapf(t - center, -0.5, 0.5))
	return clampf(1.0 - d / width, 0.0, 1.0)


func _sample_polyline(points: PackedVector3Array, cum: PackedFloat32Array, dist: float) -> Vector3:
	if points.size() == 0:
		return Vector3.ZERO
	if points.size() == 1:
		return points[0]
	for i in range(1, points.size()):
		if dist <= cum[i]:
			var seg_len: float = cum[i] - cum[i - 1]
			if seg_len <= 0.0001:
				return points[i]
			return points[i - 1].lerp(points[i], (dist - cum[i - 1]) / seg_len)
	return points[points.size() - 1]


# ── Geometry helpers ─────────────────────────────────────────────────────────
func _dome_point(pod_r: float, pod_h: float, elev: float, az: float) -> Vector3:
	return Vector3(pod_r * cos(elev) * cos(az), pod_h * sin(elev), pod_r * cos(elev) * sin(az))


func _dome_normal(pod_r: float, pod_h: float, elev: float, az: float) -> Vector3:
	return Vector3(cos(elev) * cos(az) / pod_r, sin(elev) / pod_h, cos(elev) * sin(az) / pod_r).normalized()


func _azimuth_in_openings(az: float, openings: Array, half_angle: float) -> bool:
	for o in openings:
		if absf(wrapf(az - float(o), -PI, PI)) < half_angle:
			return true
	return false


# Squashed hemisphere shell built quad by quad; quads inside an opening arc
# below door height are simply not emitted — the holes ARE the doors.
func _build_dome_mesh(pod_r: float, pod_h: float, openings: Array, half_angle: float, door_h: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lon_steps: int = 26
	var lat_steps: int = 9
	for j in range(lat_steps):
		var e0: float = (PI * 0.5) * float(j) / float(lat_steps)
		var e1: float = (PI * 0.5) * float(j + 1) / float(lat_steps)
		var last_ring: bool = (j == lat_steps - 1)
		for i in range(lon_steps):
			var a0: float = TAU * float(i) / float(lon_steps)
			var a1: float = TAU * float(i + 1) / float(lon_steps)
			var az_mid: float = (a0 + a1) * 0.5
			var y_bottom: float = pod_h * sin(e0)
			if y_bottom < door_h and _azimuth_in_openings(az_mid, openings, half_angle):
				continue
			var v00: Vector3 = _dome_point(pod_r, pod_h, e0, a0)
			var v10: Vector3 = _dome_point(pod_r, pod_h, e0, a1)
			var n00: Vector3 = _dome_normal(pod_r, pod_h, e0, a0)
			var n10: Vector3 = _dome_normal(pod_r, pod_h, e0, a1)
			if last_ring:
				st.set_normal(n00)
				st.add_vertex(v00)
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(0.0, pod_h, 0.0))
				st.set_normal(n10)
				st.add_vertex(v10)
			else:
				var v01: Vector3 = _dome_point(pod_r, pod_h, e1, a0)
				var v11: Vector3 = _dome_point(pod_r, pod_h, e1, a1)
				var n01: Vector3 = _dome_normal(pod_r, pod_h, e1, a0)
				var n11: Vector3 = _dome_normal(pod_r, pod_h, e1, a1)
				st.set_normal(n00)
				st.add_vertex(v00)
				st.set_normal(n01)
				st.add_vertex(v01)
				st.set_normal(n11)
				st.add_vertex(v11)
				st.set_normal(n00)
				st.add_vertex(v00)
				st.set_normal(n11)
				st.add_vertex(v11)
				st.set_normal(n10)
				st.add_vertex(v10)
	return st.commit()


# One semicircular arch rib (jambs + 5 arc segments) facing along dirn —
# you walk through it; nothing fills the span between ribs.
func _add_arch_rib(parent: Node3D, ground_pos: Vector3, dirn: Vector3, width: float, height: float, mat: StandardMaterial3D) -> void:
	var flat_dir: Vector3 = Vector3(dirn.x, 0.0, dirn.z)
	if flat_dir.length() < 0.01:
		return
	flat_dir = flat_dir.normalized()
	var side: Vector3 = Vector3(-flat_dir.z, 0.0, flat_dir.x)
	var rib: Node3D = Node3D.new()
	rib.transform = Transform3D(Basis(side, Vector3.UP, flat_dir), ground_pos)
	parent.add_child(rib)
	var half_w: float = width * 0.5
	var spring_h: float = maxf(height - half_w, 0.2)
	var thick: float = 0.13
	for sx in [-1.0, 1.0]:
		var jamb: MeshInstance3D = MeshInstance3D.new()
		var jb: BoxMesh = BoxMesh.new()
		jb.size = Vector3(thick, spring_h + 0.05, thick)
		jamb.mesh = jb
		jamb.material_override = mat
		jamb.position = Vector3(half_w * float(sx), spring_h * 0.5, 0.0)
		rib.add_child(jamb)
	var arc_steps: int = 5
	var prev: Vector2 = Vector2(half_w, spring_h)
	for k in range(1, arc_steps + 1):
		var ang: float = PI * float(k) / float(arc_steps)
		var pt: Vector2 = Vector2(half_w * cos(ang), spring_h + half_w * sin(ang))
		var dvec: Vector2 = pt - prev
		var seg_len: float = dvec.length()
		if seg_len > 0.001:
			var seg: MeshInstance3D = MeshInstance3D.new()
			var sb: BoxMesh = BoxMesh.new()
			sb.size = Vector3(thick, seg_len + thick * 0.6, thick)
			seg.mesh = sb
			seg.material_override = mat
			var seg_mid: Vector2 = (prev + pt) * 0.5
			seg.position = Vector3(seg_mid.x, seg_mid.y, 0.0)
			seg.rotation = Vector3(0.0, 0.0, atan2(-dvec.x, dvec.y))
			rib.add_child(seg)
		prev = pt


# Thin emissive strip from p0 to p1 (used by runners, on ground or dome).
func _add_strip(parent: Node3D, p0: Vector3, p1: Vector3, thickness: float, mat: StandardMaterial3D) -> void:
	var d: Vector3 = p1 - p0
	var seg_len: float = d.length()
	if seg_len < 0.01:
		return
	var dirn: Vector3 = d / seg_len
	var up_ref: Vector3 = Vector3.UP
	if absf(dirn.dot(up_ref)) > 0.95:
		up_ref = Vector3.RIGHT
	var mi: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(thickness, thickness * 0.35, seg_len + thickness * 0.5)
	mi.mesh = box
	mi.material_override = mat
	mi.transform = Transform3D(Basis.looking_at(dirn, up_ref), (p0 + p1) * 0.5)
	parent.add_child(mi)


# ── Materials ────────────────────────────────────────────────────────────────
func _make_emissive_mat(col: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 1.0)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m


func _tunnel_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.19, 0.155, 1.0)
	m.roughness = 0.88
	m.emission_enabled = true
	m.emission = AMBER
	m.emission_energy_multiplier = 0.18
	return m
