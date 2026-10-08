extends SceneTree

## Can a person actually walk through it? (2026-09-03)
##
## A statue's evidence is a photograph. A BUILDING's is not, and this project has
## already recorded why: every rule in the artifact-DNA section assumes one frame
## from one standpoint, and five of seven INERT verdicts turned out to be facts
## about that camera rather than about the artifact. For a thing you walk inside,
## every property is anamorphic by construction. So the evidence here is the
## PLAYER'S OWN CAPSULE, cast through the structure by the physics server.
##
## The envelope is read from commons/scenes/desktop_player.tscn rather than typed
## here, because a probe that hardcodes the body it is testing against is testing
## its own opinion. Godot 4's CharacterBody3D has NO step height and DesktopPlayer
## adds none, so a lip of any size is a wall — which is the single fact most
## likely to make a beautiful interior unwalkable.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_radial_inside.gd

const SCENE := "res://commons/artifacts/radial_inside/radial_inside.tscn"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const REPORT := "res://ada_run/radial_inside_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _cap_r: float = 0.30
var _cap_h: float = 1.80


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _read_envelope()

	var n: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	n.set("seed", 3)
	root.add_child(n)
	await process_frame
	await physics_frame
	await physics_frame

	# --- what got built ------------------------------------------------------
	var meshes: Array = _meshes(n)
	var tris: int = 0
	var box := AABB()
	var first: bool = true
	for m in meshes:
		if m.mesh == null:
			continue
		for s in range(m.mesh.get_surface_count()):
			var a: Array = m.mesh.surface_get_arrays(s)
			if not a.is_empty():
				tris += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var wb: AABB = m.global_transform * m.mesh.get_aabb()
		box = wb if first else box.merge(wb)
		first = false
	_check(meshes.size() >= 8 and tris > 4000,
		"%d mesh(es), %d triangles, %.1f x %.1f x %.1f m" % [meshes.size(), tris,
			box.size.x, box.size.y, box.size.z],
		"nothing of architectural size was built")
	_check(box.size.length() > 20.0, "it is %.1f m across the diagonal" % box.size.length(),
		"this is a sculpture, not a structure — %.1f m diagonal" % box.size.length())

	# --- IS THERE COLLISION AT ALL, and is it the curved kind? ---------------
	#
	# The museum's own collision is axis-aligned boxes on a 1 m lattice — one
	# function, one shape type, no rotation, in 22,386 lines. A curved walkable
	# structure therefore CANNOT be built by the museum and must carry its own,
	# so the first question is whether it did.
	var shapes: Array = _shapes(n)
	var tri_shapes: int = 0
	for cs in shapes:
		if cs.shape is ConcavePolygonShape3D:
			tri_shapes += 1
	_check(tri_shapes >= 4, "%d collider(s), %d of them trimesh" % [shapes.size(), tri_shapes],
		"no trimesh collision — the floor is decoration and the player falls through it")

	# --- THE WALK ------------------------------------------------------------
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h

	# probe along the tunnel's own axis, which is +z by construction
	var z0: float = box.position.z + 1.0
	var z1: float = box.position.z + box.size.z - 1.0
	var steps: int = 26
	var stood: int = 0
	var headroom_min: float = 1.0e9
	var headroom_at: float = 0.0
	var floor_gaps: Array[String] = []
	var slopes: Array[float] = []
	var prev_floor: Vector3 = Vector3.INF
	var worst_ang: float = -1.0
	var worst_where: String = "nothing"
	var stuck_where: Array[String] = []

	# WALK THE SPINE, NOT THE BOUNDING BOX. The tunnel wanders in x by design, so
	# a straight probe line down the middle of the AABB spends half its stations
	# inside the wall and reports a building with no floor. Ask the structure
	# where its centre line actually is.
	var spine: Array = n.call("spine_points") if n.has_method("spine_points") else []
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var c: Vector3 = Vector3(box.position.x + box.size.x * 0.5, 0.0, lerpf(z0, z1, t))
		if not spine.is_empty():
			# BOTH MOUTHS ARE OPEN BY DESIGN — you walk in one end and out the
			# other — so the stations run between the first and last ring rather
			# than to the very lip, where there is correctly nothing underfoot.
			var lo: int = 1
			var hi: int = maxi(1, spine.size() - 2)
			c = spine[clampi(lo + int(round(t * float(hi - lo))), 0, spine.size() - 1)]
		var z: float = c.z
		# find the floor by dropping a ray from above the spine at this station
		var from := Vector3(c.x, c.y + 5.0, z)
		var to := Vector3(c.x, c.y - 8.0, z)
		# FALL, DO NOT JUST RAYCAST. The first thing under a downward ray can be the
		# TOP OF A WALL FEATURE — a marched blob bulging off the shell — and the
		# probe was reporting that as the floor, calling its 72-degree flank a
		# ramp, and then standing the capsule on top of it inside the surrounding
		# geometry. A player dropped there would slide off it and keep going. So
		# the probe keeps casting downward past anything steeper than the engine's
		# own floor_max_angle, which is what landing actually is.
		var hit: Dictionary = {}
		var cursor: Vector3 = from
		for _hop in range(8):
			var ray := PhysicsRayQueryParameters3D.create(cursor, to)
			var h2: Dictionary = space.intersect_ray(ray)
			if h2.is_empty():
				break
			var slope: float = rad_to_deg(acos(clampf((h2["normal"] as Vector3).dot(Vector3.UP), -1.0, 1.0)))
			if slope <= 45.0:
				hit = h2
				break
			cursor = (h2["position"] as Vector3) + Vector3(0.0, -0.05, 0.0)
		if hit.is_empty():
			floor_gaps.append("z=%.1f" % z)
			continue
		var floor_p: Vector3 = hit["position"]
		var up: Vector3 = hit["normal"]
		var ang: float = rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
		slopes.append(ang)
		# NAME THE OFFENDER. "the steepest surface is 72 degrees" is not actionable;
		# "the steepest surface is 72 degrees and it is a Cartilage blob at z 12.3"
		# tells you which of five builders to open.
		if ang > worst_ang:
			worst_ang = ang
			var owner: Node = hit.get("collider")
			var who: String = "?"
			if owner != null:
				who = String(owner.name)
				if owner.get_parent() != null:
					who = String(owner.get_parent().name) + "/" + who
			worst_where = "%s at z %.1f" % [who, z]
		# CAN THE BODY STAND HERE? Not "is there room" — put the actual capsule in.
		# STAND THE CAPSULE 6 cm CLEAR AND ZERO THE MARGIN. A shape query carries a
		# default 0.04 m margin, so a capsule resting 2 cm above the floor overlaps
		# the floor and reports "stuck" — which is what it did, at 14 of 26
		# stations, on a building that was fine underfoot. A gate that fires on its
		# own tolerance is worse than no gate.
		var tf := Transform3D(Basis(), floor_p + Vector3(0.0, _cap_h * 0.5 + 0.06, 0.0))
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = tf
		q.margin = 0.0
		var blocked: Array = space.intersect_shape(q, 4)
		if blocked.is_empty():
			stood += 1
		else:
			var names: Array[String] = []
			for b in blocked:
				var bn: Node = b.get("collider")
				if bn != null:
					names.append(String(bn.get_parent().name) if bn.get_parent() != null else String(bn.name))
			stuck_where.append("z %.1f in %s" % [z, ", ".join(names)])
		# headroom: ray up from the standing point
		var up_from: Vector3 = floor_p + Vector3(0.0, 0.05, 0.0)
		var up_to: Vector3 = up_from + Vector3(0.0, 8.0, 0.0)
		var uhit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(up_from, up_to))
		var head: float = float(uhit["position"].y - up_from.y) if not uhit.is_empty() else 8.0
		if head < headroom_min:
			headroom_min = head
			headroom_at = z
		# AND THE STEP. There is no step height in this engine, so any rise
		# between adjacent floor samples is a wall the player will simply stop at.
		if prev_floor != Vector3.INF:
			var rise: float = floor_p.y - prev_floor.y
			var run: float = Vector2(floor_p.x - prev_floor.x, floor_p.z - prev_floor.z).length()
			if run > 0.01 and rise > 0.0:
				slopes.append(rad_to_deg(atan2(rise, run)))
		prev_floor = floor_p

	_check(floor_gaps.is_empty(), "a floor was found at all %d station(s)" % steps,
		"no floor under %d station(s): %s — the player falls out of the building at %s"
			% [floor_gaps.size(), ", ".join(floor_gaps), floor_gaps[0] if not floor_gaps.is_empty() else "?"])
	_check(stood >= steps - floor_gaps.size(),
		"the player's own capsule (r %.2f, h %.2f) fits at %d of %d station(s)" % [_cap_r, _cap_h, stood, steps],
		"the capsule is stuck at %d station(s): %s" % [steps - floor_gaps.size() - stood, "; ".join(stuck_where)])
	_check(headroom_min >= 2.0, "tightest headroom %.2f m at z %.1f (want >= 2.00)" % [headroom_min, headroom_at],
		"you cannot stand up at z %.1f — %.2f m of headroom" % [headroom_at, headroom_min])

	var worst: float = 0.0
	for s in slopes:
		worst = maxf(worst, s)
	_check(worst <= 45.0, "steepest floor %.1f deg, %s (engine limit 45, no step height)" % [worst, worst_where],
		"a %.1f deg surface is a wall, not a floor — %s — and there is no step height to climb it"
			% [worst, worst_where])

	# --- THE APERTURES -------------------------------------------------------
	var lips: int = 0
	var cart: int = 0
	for m in meshes:
		if String(m.name).begins_with("Lips"):
			lips += 1
		if String(m.name).begins_with("Cartilage"):
			cart += 1
	_check(cart >= 1, "%d marched junction(s) and %d aperture lip mesh(es)" % [cart, lips],
		"no soft junction was marched — the whole hard/soft argument is missing")

	# --- AND THE THING THE WHOLE PIECE IS ABOUT ------------------------------
	#
	# You are on the WRONG SIDE of the shell. If the lumen skin is not cull_front
	# the interior renders as backfaces of an exterior, which is the bug this work
	# is a critique of, arrived at by accident.
	# A material flag would be the easy thing to check and it would prove nothing:
	# a ShaderMaterial has no cull_mode at all. What decides whether you are on the
	# inside is the WINDING, so that is what gets measured — every lumen normal
	# must point back toward the tunnel's centre line.
	var faces: int = 0
	var inward: int = 0
	for m in meshes:
		if not String(m.name).begins_with("Lumen"):
			continue
		var arr: Array = m.mesh.surface_get_arrays(0)
		if arr.is_empty():
			continue
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		for vi in range(0, vs.size(), 3):
			var mid: Vector3 = (vs[vi] + vs[vi + 1] + vs[vi + 2]) / 3.0
			# nearest spine station, so the test works on a tunnel that curves
			var best: Vector3 = mid
			var bd: float = 1.0e9
			for sp_v in spine:
				var sp: Vector3 = sp_v
				var d: float = sp.distance_squared_to(mid)
				if d < bd:
					bd = d
					best = sp
			var to_axis: Vector3 = (best - mid).normalized()
			faces += 1
			if ns[vi].dot(to_axis) > 0.0:
				inward += 1
	var frac: float = float(inward) / float(maxi(faces, 1))
	_check(faces > 0 and frac > 0.92,
		"%d of %d lumen face(s) point INWARD (%.1f%%) — you are on the inside of the shell"
			% [inward, faces, frac * 100.0],
		"only %.1f%% of lumen faces point inward: standing in it you are looking at the backfaces of an outside"
			% (frac * 100.0))

	n.queue_free()
	_finish()


## The player's real capsule, read rather than assumed.
func _read_envelope() -> void:
	if not ResourceLoader.exists(PLAYER):
		_lines.append("[probe] note  %s not found — using the documented 0.30 / 1.80" % PLAYER)
		return
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	for cs in _shapes(p):
		if cs.shape is CapsuleShape3D:
			_cap_r = (cs.shape as CapsuleShape3D).radius
			_cap_h = (cs.shape as CapsuleShape3D).height
			break
	_lines.append("[probe] envelope read from the player: capsule r %.2f m, h %.2f m" % [_cap_r, _cap_h])
	p.free()


## The tunnel's centre x at a given z — the spine wanders, so a straight probe
## line down the middle of the AABB would walk into the wall.
func _centre_x(box: AABB, _z: float) -> float:
	return box.position.x + box.size.x * 0.5


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out


func _shapes(n: Node) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	if n is CollisionShape3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_shapes(c))
	return out


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
