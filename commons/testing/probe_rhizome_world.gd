extends SceneTree

## Does the body still stop you when it is the size of a world? (2026-09-03)
##
## Palle: "can we put it around the museum like the world, really big". The body
## is scaled as a NODE rather than rebuilt, because cost tracks surface area and
## a 4x rebuild is about nine million triangles. That keeps the triangle count
## flat and turns the cell into a world-scale facet — but it stakes everything on
## one thing that Godot's own documentation is discouraging about:
##
##   A SCALED CollisionShape3D MAY NOT SCALE.
##
## If a ConcavePolygonShape3D quietly refuses, the visible body is four times the
## size of the thing you bump into, and there is no error, no warning and nothing
## in the frame to see. You would walk through a wall a hundred metres from where
## the wall appears to be. That is this project's favourite failure at the largest
## scale it has ever had available.
##
## So the collider's OWN world AABB is measured against the mesh's at each scale,
## from the physics server rather than from the node, and the player's capsule is
## walked in through the mouth at every scale as well.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_rhizome_world.gd

const SCENE := "res://commons/artifacts/radial_inside/rhizome_inside.tscn"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const REPORT := "res://ada_run/rhizome_world_probe.txt"
const SCALES: Array[float] = [1.0, 2.0, 4.0]

var _lines: Array[String] = []
var _fails: Array[String] = []
var _cap_r: float = 0.30
var _cap_h: float = 1.80


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_envelope()
	for k in SCALES:
		await _one(k)
	_finish()


func _one(k: float) -> void:
	var n: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	n.set("seed", 3)
	n.set("world_scale", k)
	root.add_child(n)
	await process_frame
	await physics_frame
	await physics_frame

	# the MESH extent, from the visible geometry
	var mbox := AABB()
	var first: bool = true
	var tris: int = 0
	for m in _meshes(n):
		if m.mesh == null:
			continue
		for s in range(m.mesh.get_surface_count()):
			var a: Array = m.mesh.surface_get_arrays(s)
			if not a.is_empty():
				tris += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var wb: AABB = m.global_transform * m.mesh.get_aabb()
		mbox = wb if first else mbox.merge(wb)
		first = false

	# the COLLIDER extent, asked of the physics server rather than of the node —
	# a node's transform says what was requested, not what the shape did with it
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var cbox := AABB()
	var cfirst: bool = true
	var nshapes: int = 0
	for cs in _shapes(n):
		if not (cs.shape is ConcavePolygonShape3D):
			continue
		nshapes += 1
		var faces: PackedVector3Array = (cs.shape as ConcavePolygonShape3D).get_faces()
		if faces.is_empty():
			continue
		var lo: Vector3 = faces[0]
		var hi: Vector3 = faces[0]
		for i in range(0, faces.size(), 31):
			lo = Vector3(minf(lo.x, faces[i].x), minf(lo.y, faces[i].y), minf(lo.z, faces[i].z))
			hi = Vector3(maxf(hi.x, faces[i].x), maxf(hi.y, faces[i].y), maxf(hi.z, faces[i].z))
		var local := AABB(lo, hi - lo)
		var wb2: AABB = cs.global_transform * local
		cbox = wb2 if cfirst else cbox.merge(wb2)
		cfirst = false

	var mdiag: float = mbox.size.length()
	var cdiag: float = cbox.size.length()
	var ratio: float = cdiag / maxf(mdiag, 0.001)
	_check(absf(ratio - 1.0) < 0.06,
		"x%.1f: mesh %.1f m across, colliders %.1f m across (ratio %.3f), %d shape(s), %d triangles"
			% [k, mdiag, cdiag, ratio, nshapes, tris],
		"x%.1f: the colliders are %.1f m across against a mesh of %.1f m (ratio %.3f) — the walls are not where they look"
			% [k, cdiag, mdiag, ratio])

	# AND THE TRIANGLE COUNT MUST NOT MOVE. If it does, something rebuilt at the
	# new scale and the whole reason for scaling the node has gone.
	if k > 1.0 and _base_tris > 0:
		_check(tris == _base_tris,
			"x%.1f: still %d triangles — the body was scaled, not rebuilt" % [k, tris],
			"x%.1f: %d triangles against %d at x1 — this rebuilt, and a 4x rebuild is ~9 M"
				% [k, tris, _base_tris])
	else:
		_base_tris = tris

	# ── and you can still get in ─────────────────────────────────────────
	var mouth: Vector3 = (n.call("entrance_point") as Vector3) * k
	var dir: Vector3 = n.call("entrance_dir")
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h
	var reach: float = 9.0 * k
	var blocked: float = -1.0
	for i in range(121):
		var t: float = 1.0 - float(i) / 120.0
		var q: Vector3 = mouth + dir * (reach * t)
		var pq := PhysicsShapeQueryParameters3D.new()
		pq.shape = cap
		pq.transform = Transform3D(Basis(), q)
		pq.margin = 0.0
		if not space.intersect_shape(pq, 1).is_empty():
			blocked = reach * t
			break
	_check(blocked < 0.0,
		"x%.1f: the player's own capsule (r %.2f, h %.2f) still walks in through the mouth"
			% [k, _cap_r, _cap_h],
		"x%.1f: blocked %.2f m out — the mouth does not survive the scale" % [k, blocked])

	n.queue_free()
	await process_frame


var _base_tris: int = 0


func _read_envelope() -> void:
	if not ResourceLoader.exists(PLAYER):
		return
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	for cs in _shapes(p):
		if cs.shape is CapsuleShape3D:
			_cap_r = (cs.shape as CapsuleShape3D).radius
			_cap_h = (cs.shape as CapsuleShape3D).height
			break
	_lines.append("[probe] envelope read from the player: capsule r %.2f m, h %.2f m (it does NOT scale)"
		% [_cap_r, _cap_h])
	p.free()


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
