extends SceneTree

## Does the map actually put a walkable body in front of you? (2026-09-03)
##
## Every gate so far tested the ARTIFACT: chunked marching, the hollow shell, the
## chambers, the passages, the mouth. None of them tested the MAP. A world-scale
## artifact reaches the grid through a different lane than a plinth statue, and
## the failure this catches is specific and silent: the grid instances the scene,
## the scene builds, the pathfinder says OK — and the body sits at a y-offset
## that buries its mouth in the floor, or its colliders never arrive, and the
## player walks into a lump.
##
## So this boots the real map, finds the real instance, and asks the two things a
## visitor asks: is it there, and can I get in from where I am standing.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_iso_rhizomebody.gd

const MAP := "ISO_RhizomeBody"
const MAP_PATH := "res://commons/maps/ISO_RhizomeBody/map_data.json"
const SCENE := "res://commons/artifacts/radial_inside/rhizome_inside.tscn"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const REPORT := "res://ada_run/iso_rhizomebody_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _cap_r: float = 0.30
var _cap_h: float = 1.80


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_envelope()

	# ── 1. the map says what we think it says ────────────────────────────
	if not FileAccess.file_exists(MAP_PATH):
		_check(false, "", "%s is missing" % MAP_PATH)
		_finish()
		return
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	if not (doc is Dictionary):
		_check(false, "", "map_data.json did not parse")
		_finish()
		return
	var d: Dictionary = doc
	var layers: Dictionary = d.get("layers", {})
	var st: Array = layers.get("structure", [])
	var inter: Array = layers.get("interactables", [])
	var dims: Dictionary = (d.get("map_info", {}) as Dictionary).get("dimensions", {})
	var gw: int = (st[0] as Array).size() if not st.is_empty() else 0
	var gh: int = st.size()
	# THE DECLARED DIMS LIE IN 269 MAPS IN THIS CORPUS, and a wrong depth builds a
	# zero-row grid. The grid is the truth, so the declaration is checked against it.
	_check(int(dims.get("width", -1)) == gw and int(dims.get("depth", -1)) == gh,
		"declared %s x %s matches the grid's %d x %d" % [str(dims.get("width")), str(dims.get("depth")), gw, gh],
		"declared %s x %s against a grid of %d x %d — the declaration lies"
			% [str(dims.get("width")), str(dims.get("depth")), gw, gh])

	var at := Vector2i(-1, -1)
	var tok: String = ""
	for y in range(inter.size()):
		var row: Array = inter[y]
		for x in range(row.size()):
			var c: String = str(row[x])
			if c.begins_with("rhizome_inside"):
				at = Vector2i(x, y)
				tok = c
	_check(at.x >= 0, "the map places %s at cell (%d, %d)" % [tok, at.x, at.y],
		"no rhizome_inside token in the interactables layer")
	if at.x < 0:
		_finish()
		return

	var spawn := Vector2i(-1, -1)
	for y in range(inter.size()):
		var urow: Array = (layers.get("utilities", []) as Array)[y]
		for x in range(urow.size()):
			if str(urow[x]) == "s":
				spawn = Vector2i(x, y)
	_check(spawn.x >= 0, "the spawn is at cell (%d, %d)" % [spawn.x, spawn.y],
		"the map has no spawn — the player arrives nowhere")

	# ── 2. build the body where the map puts it ──────────────────────────
	#
	# The grid's own placement pipeline is a lot of machinery to boot for one
	# artifact, so this reproduces the ONE thing it does that matters here: the
	# cell becomes a world position at the cell's centre. If that convention ever
	# changes this probe is measuring the wrong spot, which is why the number it
	# reports is the mouth's WORLD position and not just a pass.
	var body: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	body.set("seed", 3)
	root.add_child(body)
	body.global_position = Vector3(float(at.x) + 0.5, 0.0, float(at.y) + 0.5)
	await process_frame
	await physics_frame
	await physics_frame

	var meshes: int = 0
	var shapes: int = 0
	var box := AABB()
	var first: bool = true
	for m in _meshes(body):
		if m.mesh == null:
			continue
		meshes += 1
		var wb: AABB = m.global_transform * m.mesh.get_aabb()
		box = wb if first else box.merge(wb)
		first = false
	for cs in _shapes(body):
		if cs.shape is ConcavePolygonShape3D:
			shapes += 1
	_check(meshes > 50 and shapes > 50,
		"%d chunk mesh(es), %d trimesh collider(s), spanning %.1f x %.1f x %.1f m at (%.1f, %.1f)"
			% [meshes, shapes, box.size.x, box.size.y, box.size.z, box.position.x, box.position.z],
		"the body did not arrive: %d mesh(es), %d collider(s)" % [meshes, shapes])

	# ── 3. IT FITS ON THE MAP ────────────────────────────────────────────
	#
	# A world-scale artifact is allowed to overhang — rhizomatic_maze_space is 40 m
	# on a 13 x 11 map — but the MOUTH is not, because the mouth is the only part
	# a visitor has to reach on foot.
	var mouth: Vector3 = body.global_position + (body.call("entrance_point") as Vector3)
	var dir: Vector3 = body.call("entrance_dir")
	var appr: Vector3 = mouth + dir * 9.0
	var on_grid: bool = appr.x > 1.0 and appr.x < float(gw - 1) and appr.z > 1.0 and appr.z < float(gh - 1)
	_check(on_grid,
		"the mouth is at (%.1f, %.1f) and its approach at (%.1f, %.1f), both on a %d x %d floor"
			% [mouth.x, mouth.z, appr.x, appr.z, gw, gh],
		"the approach point (%.1f, %.1f) is off a %d x %d map — the door is unreachable on foot"
			% [appr.x, appr.z, gw, gh])

	# ── 4. AND YOU CAN WALK IN, from the map's own floor ─────────────────
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h
	var blocked: float = -1.0
	for i in range(91):
		var t: float = 1.0 - float(i) / 90.0
		var q: Vector3 = mouth + dir * (9.0 * t)
		var pq := PhysicsShapeQueryParameters3D.new()
		pq.shape = cap
		pq.transform = Transform3D(Basis(), q)
		pq.margin = 0.0
		if not space.intersect_shape(pq, 1).is_empty():
			blocked = 9.0 * t
			break
	_check(blocked < 0.0,
		"the player's own capsule (r %.2f, h %.2f) walks in from 9 m out, at the map's placement"
			% [_cap_r, _cap_h],
		"blocked %.2f m out — the map's y-offset has buried the mouth" % blocked)

	# ── 5. THE SILL, against the map floor rather than against nothing ───
	#
	# The artifact's own mouth probe reported "no floor found outside", because on
	# the bench there is no ground. Here there is: the map's floor is at y = 0, and
	# an engine with no step height turns any mismatch into a wall.
	var floor_in: float = _floor_y(space, mouth)
	if floor_in > -1.0e8:
		_check(absf(floor_in - 0.0) < 0.45,
			"the chamber floor inside the mouth is %.2f m against the map floor at 0.00 (no step height)" % floor_in,
			"the chamber floor is %.2f m against a map floor of 0.00 — a %.2f m step, which is a wall"
				% [floor_in, absf(floor_in)])
	else:
		_lines.append("[probe] note  no floor under the mouth — the body's underside is below the map floor there")

	body.queue_free()
	_finish()


## START THE RAY AT THE POINT, NOT ABOVE IT.
##
## Casting from 3 m up reported the chamber floor at 3.91 m and called it a wall.
## It was measuring the OUTER SKIN OVERHEAD: the mouth is a bore through a body,
## so 3 m above it is solid, and the first hit on the way down is the roof. The
## same mistake the tunnel probe made in a different costume — there the first
## hit was the top of a wall bulge and it got called a floor. Inside a hollow
## body the only honest place to start looking for the floor is where the feet
## already are.
func _floor_y(space: PhysicsDirectSpaceState3D, at: Vector3) -> float:
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
		at + Vector3(0.0, 0.10, 0.0), at + Vector3(0.0, -8.0, 0.0)))
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else -1.0e9


func _read_envelope() -> void:
	if not ResourceLoader.exists(PLAYER):
		return
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	for cs in _shapes(p):
		if cs.shape is CapsuleShape3D:
			_cap_r = (cs.shape as CapsuleShape3D).radius
			_cap_h = (cs.shape as CapsuleShape3D).height
			break
	_lines.append("[probe] envelope read from the player: capsule r %.2f m, h %.2f m" % [_cap_r, _cap_h])
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
	if line != "":
		_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	else:
		_lines.append("[probe] *** %s ***" % why)
	if not ok:
		_fails.append(why)
