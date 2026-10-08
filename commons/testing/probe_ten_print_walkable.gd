extends SceneTree
## GATE — the walkable printed maze in Randomness_10_PRINT_Algorithm, in the REAL museum.
##
## Token at [8,11]:
##   ten_print_structure:180#form:wall#size:1.1#cols:4#rows:3#solid:on#seed:1982#count:12#plate:none
##
## The chapter will say a body can walk into a 10 PRINT field and find out whether the rule
## left it a way through. Every part of that is measured here, in the museum lane, with the
## same capsule the colour-hall probe uses (radius 0.25 m, height 1.6 m, layer 1).
##
##   A  kept           -> the museum stamped it (not slid, not left behind)
##   B  solid          -> the walls carry colliders, and stand about head-high or higher
##   C  floor intact   -> the linked floor still has none (it stays a venue)
##   D  same coin      -> maze cell (c, r) is character r*4+c of a seed-1982 printer
##   E  regions        -> the rule's own partition: pockets, openings, a way through or not
##   E2 corridors      -> every open region has exactly two mouths (nothing forks),
##                        and how many triangles deep each one is
##   I  wrap width     -> the same twelve characters wrapped 3, 4, 6 and 12 to a row
##   F  a body enters  -> capsule sweeps from outside into the first triangle of each opening
##   G  exit reachable -> the museum records no severance; entry reaches exit, passage, pocket
##   H  walk it        -> a capsule walks the rule's way through, segment by segment

const MAZE_TOKEN := "ten_print_structure"
const PRINTER := "res://algorithms/randomness/ten_print/ten_print.tscn"
const K := 0.2928932   # (2 - sqrt 2) / 2: incentre offset of a right isosceles triangle, in cells

var em: Node3D
var seg: Node3D
var walking_y: float = 0.85
var _fails: Array = []
var _finished := false
var _cols: int = 4


func _initialize() -> void:
	run.call_deferred()


func _check(label: String, ok: bool, detail: String = "") -> void:
	var line := "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	print(("  ok    " if ok else "  FAIL  ") + line)
	if not ok:
		_fails.append(line)


func _sweep(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.6
	q.shape = cap
	q.collision_mask = 1
	a.y = walking_y
	b.y = walking_y
	q.transform.origin = a
	q.motion = b - a
	var space := seg.get_world_3d().direct_space_state
	return space.intersect_shape(q, 1).is_empty() and space.cast_motion(q)[0] > 0.999


# --- the rule's topology: each cell is split by its diagonal into two triangles --------
# forward: slab (c,r)->(c+1,r+1). Triangles: FR touches far(r) + right(c+1); NL touches left(c) + near(r+1)
# backward: slab (c,r+1)->(c+1,r). Triangles: FL touches far + left; NR touches right + near
func _tri(cells: Dictionary, c: int, r: int, edge: String) -> int:
	var fwd: bool = cells.get(Vector2i(c, r), false)
	var t: int
	if fwd:
		t = 0 if edge in ["far", "right"] else 1
	else:
		t = 0 if edge in ["far", "left"] else 1
	return (r * _cols + c) * 2 + t


func _regions(cells: Dictionary, cols: int, rows: int) -> Dictionary:
	_cols = cols
	var parent: Array = []
	for i in cols * rows * 2:
		parent.append(i)
	var find := func(x: int) -> int:
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x
	var join := func(a: int, b: int) -> void:
		parent[find.call(a)] = find.call(b)
	for r in rows:
		for c in cols:
			if c + 1 < cols:
				join.call(_tri(cells, c, r, "right"), _tri(cells, c + 1, r, "left"))
			if r + 1 < rows:
				join.call(_tri(cells, c, r, "near"), _tri(cells, c, r + 1, "far"))
	var sides: Dictionary = {}   # root -> {far, near, left, right}
	var mouths: Dictionary = {}  # root -> how many boundary cell-edges open into it
	for r in rows:
		for c in cols:
			var pairs: Array = []
			if r == 0: pairs.append(["far", _tri(cells, c, r, "far")])
			if r == rows - 1: pairs.append(["near", _tri(cells, c, r, "near")])
			if c == 0: pairs.append(["left", _tri(cells, c, r, "left")])
			if c == cols - 1: pairs.append(["right", _tri(cells, c, r, "right")])
			for p in pairs:
				var root: int = find.call(p[1])
				if not sides.has(root):
					sides[root] = {}
				sides[root][p[0]] = true
				mouths[root] = int(mouths.get(root, 0)) + 1
	var roots: Dictionary = {}
	for i in cols * rows * 2:
		roots[find.call(i)] = true
	var closed := 0
	var through := false
	var far_near := false
	for root in roots.keys():
		if not sides.has(root):
			closed += 1
		else:
			var s: Dictionary = sides[root]
			if (s.has("far") and s.has("near")) or (s.has("left") and s.has("right")):
				through = true
			if s.has("far") and s.has("near"):
				far_near = true
	var mouth_counts: Array = []
	for root in mouths.keys():
		mouth_counts.append(int(mouths[root]))
	mouth_counts.sort()
	# how many triangles each OPEN region holds: how deep a body can go into it
	var tri_count: Dictionary = {}
	for i in cols * rows * 2:
		var rt: int = find.call(i)
		tri_count[rt] = int(tri_count.get(rt, 0)) + 1
	var open_sizes: Array = []
	for root in sides.keys():
		open_sizes.append(int(tri_count.get(root, 0)))
	open_sizes.sort()
	return {"regions": roots.size(), "open": sides.size(), "closed": closed, "through": through,
		"far_near": far_near, "mouths": mouth_counts, "open_sizes": open_sizes}


func run() -> void:
	var out := "user://ten_print_walkable/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var ctl := out + "control.json"
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "randomness", "dollhouse": 0, "grid_pack": 1}))
	f.close()
	em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", ctl)
	em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", ctl + ".unused-hand")
	em.set("start_chapter", "randomness")
	em.set("start_map", "Randomness_10_PRINT_Algorithm")
	root.add_child(em)
	current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == "Randomness_10_PRINT_Algorithm":
			seg = rec.node
	if seg == null:
		_check("the hall is built", false)
		_end()
		return
	for i in 40:
		await physics_frame

	var maze: Node3D = null
	var floor_: Node3D = null
	for n in seg.get_children():
		if n.get_script() != null and "form" in n and str(n.get("form")) in ["wall", "floor"]:
			if str(n.form) == "wall":
				maze = n
			else:
				floor_ = n

	# --- A ---
	_check("A the museum kept the walkable maze", maze != null,
		"found" if maze else "absent — slid, left behind, or taken out for severing the walk")
	if maze == null:
		_end()
		return
	var mp: Vector3 = seg.to_local(maze.global_position)
	print("       origin x %.2f z %.2f (planned 11.5, 12.5)" % [mp.x, mp.z])

	# --- B ---
	var shapes: Array = maze.find_children("*", "CollisionShape3D", true, false)
	var tallest := 0.0
	for s in shapes:
		var sh: Shape3D = (s as CollisionShape3D).shape
		if sh is BoxShape3D:
			tallest = maxf(tallest, (sh as BoxShape3D).size.y)
	_check("B the maze walls are solid and taller than a body", shapes.size() > 0 and tallest >= 1.8,
		"%d collision shapes, tallest %.2f m" % [shapes.size(), tallest])

	# --- C ---
	var floor_shapes := floor_.find_children("*", "CollisionShape3D", true, false).size() if floor_ else -1
	_check("C the linked floor is still a venue", floor_ != null and floor_shapes == 0,
		"%d collision shapes on the floor" % floor_shapes)

	# --- D: the same coin ---
	var cells: Dictionary = maze.get_cells()
	var dims: Vector2i = maze.get_dims()
	var COLS: int = dims.x
	var ROWS: int = dims.y
	print("       maze %d x %d cells" % [COLS, ROWS])
	var printer: Node3D = load(PRINTER).instantiate()
	printer.apply_grid_config({"seed": 1982})
	seg.add_child(printer)
	await process_frame
	var agree := 0
	for r in ROWS:
		for c in COLS:
			if bool(cells.get(Vector2i(c, r), false)) == printer.coin_is_forward(r * COLS + c):
				agree += 1
	printer.queue_free()
	_check("D the maze is the printer's own first characters", cells.size() == COLS * ROWS and agree == COLS * ROWS,
		"%d cells, %d of %d agree with coin i = r*cols+c" % [cells.size(), agree, COLS * ROWS])

	# --- E: what the rule made of the ground ---
	var reg: Dictionary = _regions(cells, COLS, ROWS)
	var picture := ""
	for r in ROWS:
		var row := ""
		for c in COLS:
			row += "\\" if cells.get(Vector2i(c, r), false) else "/"
		picture += "         " + row + "\n"
	print(picture.rstrip("\n"))
	_check("E the rule partitions the ground", reg.regions >= 2,
		"%d regions: %d open to the outside, %d closed pockets; a way through: %s" %
			[reg.regions, reg.open, reg.closed, str(reg.through)])

	# --- E2: nothing forks. Every triangle between the slabs opens on exactly
	#         two cell edges, so a region is a chain: an open one has exactly two mouths on
	#         the boundary, a closed one is a loop. Counted, not assumed. ---
	var two_each := true
	for m in reg.mouths:
		if int(m) != 2:
			two_each = false
	_check("E2 every open region has exactly two mouths: nothing forks",
		two_each and reg.mouths.size() == reg.open,
		"mouths per open region %s; boundary edges %d; triangles per open region %s" %
			[str(reg.mouths), 2 * (COLS + ROWS), str(reg.open_sizes)])

	# --- I: the same twelve characters, wrapped differently. The pocket and the passage
	#        belong to the coin AND the line width. A way through here means far edge to
	#        near edge, as the chapter uses it. Informational rows, one assertion: the
	#        four-wide wrap rebuilt from the coin alone reproduces E. ---
	var wrap_rows: Array = []
	var four_ok := false
	for spec in [[3, 12], [4, 12], [6, 12], [12, 12], [4, 16]]:
		var w: int = spec[0]
		var n: int = spec[1]
		var h: int = int(ceil(float(n) / float(w)))
		var wc_cells: Dictionary = {}
		for i in n:
			wc_cells[Vector2i(i % w, i / w)] = printer.coin_is_forward(i)
		var rg: Dictionary = _regions(wc_cells, w, h)
		# far-to-near only, the chapter's sense of a way through
		var fn: bool = rg.far_near
		wrap_rows.append("%d chars, %d to a row: %d regions, %d closed, far-to-near %s" % [n, w, rg.regions, rg.closed, str(fn)])
		if w == 4 and n == 12:
			four_ok = rg.regions == reg.regions and rg.closed == reg.closed
	for line_w in wrap_rows:
		print("         " + line_w)
	_check("I the four-wide wrap rebuilt from the coin alone reproduces E", four_ok, "; ".join(wrap_rows))

	# --- F: a body can get in ---
	var ray := PhysicsRayQueryParameters3D.create(seg.to_global(Vector3(4.5, 20, 7.0)), seg.to_global(Vector3(4.5, -5, 7.0)), 1)
	var hit := seg.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		walking_y = hit.position.y + 0.85
	var size := 1.1
	var entries := 0
	var tried := 0
	for c in COLS:
		for side in ["far", "near"]:
			var r := 0 if side == "far" else ROWS - 1
			var fwd: bool = cells.get(Vector2i(c, r), false)
			var inc: Vector2
			if side == "far":
				inc = Vector2(c + 1 - K, r + K) if fwd else Vector2(c + K, r + K)
				var out_p := Vector2(inc.x, -0.8)
				tried += 1
				if _sweep(maze.to_global(Vector3(out_p.x * size, 0, out_p.y * size)), maze.to_global(Vector3(inc.x * size, 0, inc.y * size))):
					entries += 1
			else:
				inc = Vector2(c + K, r + 1 - K) if fwd else Vector2(c + 1 - K, r + 1 - K)
				var out_n := Vector2(inc.x, ROWS + 0.8)
				tried += 1
				if _sweep(maze.to_global(Vector3(out_n.x * size, 0, out_n.y * size)), maze.to_global(Vector3(inc.x * size, 0, inc.y * size))):
					entries += 1
	_check("F a body can step into the maze from outside", entries > 0,
		"%d of %d edge openings admit a 0.5 m body" % [entries, tried])

	# --- the museum's own walk map around the hall: what it thinks is walkable now ---
	var wc: Dictionary = em.get("_walk_cells")
	var sev: Array = em.get("_seg_severed")
	var sealed: Dictionary = {}
	for e in sev:
		for c2 in e.cells:
			sealed[Vector2i(int(c2[0]), int(c2[1]))] = str(e.token)
	var origin_w: Vector3 = seg.global_position
	print("       museum walk map, world cells (x across, z down), S = sealed by a body, # = walkable, . = not:")
	for zz in range(int(origin_w.z) + 2, int(origin_w.z) + 22):
		var line := ""
		for xx in range(int(origin_w.x) - 2, int(origin_w.x) + 16):
			var k := Vector2i(xx, zz)
			line += "S" if sealed.has(k) else ("#" if wc.has(k) else ".")
		print("       z%4d %s" % [zz, line])
	print("       (columns start at world x %d; segment origin world %s)" % [int(origin_w.x) - 2, str(origin_w)])

	# --- G: the museum's own verdicts, not a straight line. A straight capsule sweep is not a
	#        route test: an earlier version of this check failed on some other collider in
	#        the line while the route itself was fine. ---
	var mine: Array = []
	for e in sev:
		if str(e.token) == "ten_print_structure":
			mine.append(e)
	_check("G the museum records no severance against the maze", mine.is_empty(),
		"%d severance record(s) for ten_print_structure" % mine.size())
	var reach := func(a: Vector2i, b: Vector2i) -> bool:
		if not wc.has(a) or not wc.has(b):
			return false
		var seen: Dictionary = {a: true}
		var q: Array = [a]
		while not q.is_empty():
			var k: Vector2i = q.pop_front()
			if k == b:
				return true
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n2: Vector2i = k + d
				if wc.has(n2) and not seen.has(n2):
					seen[n2] = true
					q.append(n2)
		return false
	var entry := Vector2i(4, 0)
	var exit_cell := Vector2i(6, 7)
	var passage := Vector2i(7, 15)
	var pocket := Vector2i(8, 3)
	_check("G entry reaches the exit on the museum walk map", reach.call(entry, exit_cell),
		"%s -> %s" % [str(entry), str(exit_cell)])
	_check("G entry reaches the passage out", reach.call(entry, passage),
		"%s -> %s" % [str(entry), str(passage)])
	_check("G the pocket by the science screen is not stranded", reach.call(entry, pocket),
		"%s -> %s" % [str(entry), str(pocket)])

	# --- H: walk the way through, with a body, not with topology. The route is found over
	#        triangles and then swept waypoint by waypoint: outside -> edge midpoint ->
	#        triangle incentre -> shared-edge midpoint -> ... -> outside. ---
	var route: Array = _through_route(cells, COLS, ROWS)
	if route.is_empty():
		_check("H the rule gives a way through to walk", false, "no side-to-side route in the rule")
	else:
		var ok_all := true
		var segs := 0
		var first_bad := ""
		for i in range(route.size() - 1):
			var a2: Vector2 = route[i]
			var b2: Vector2 = route[i + 1]
			segs += 1
			if not _sweep(maze.to_global(Vector3(a2.x * 1.1, 0, a2.y * 1.1)), maze.to_global(Vector3(b2.x * 1.1, 0, b2.y * 1.1))):
				ok_all = false
				if first_bad == "":
					first_bad = "%s -> %s" % [str(a2), str(b2)]
		_check("H a 0.5 m body walks the way through, end to end", ok_all,
			"%d segments via %d triangles%s" % [segs, (route.size() - 3) / 2, "" if ok_all else "; first blocked " + first_bad])

	_end()


func _end() -> void:
	_finished = true
	if _fails.is_empty():
		print("\nprobe_ten_print_walkable: ALL CHECKS PASS")
		quit(0)
	else:
		print("\nprobe_ten_print_walkable: %d FAILED" % _fails.size())
		for x in _fails:
			print("  FAIL  %s" % x)
		quit(1)

## A side-to-side route over the triangles, as waypoints in cell units (x = col, y = row).
func _incentre(cells: Dictionary, c: int, r: int, t: int) -> Vector2:
	var fwd: bool = cells.get(Vector2i(c, r), false)
	if fwd:
		return Vector2(c + 1 - K, r + K) if t == 0 else Vector2(c + K, r + 1 - K)
	return Vector2(c + K, r + K) if t == 0 else Vector2(c + 1 - K, r + 1 - K)


func _edges(cells: Dictionary, c: int, r: int, t: int) -> Array:
	var fwd: bool = cells.get(Vector2i(c, r), false)
	if fwd:
		return ["far", "right"] if t == 0 else ["near", "left"]
	return ["far", "left"] if t == 0 else ["right", "near"]


func _through_route(cells: Dictionary, cols: int, rows: int) -> Array:
	for pair in [["far", "near"], ["left", "right"]]:
		var start_side: String = pair[0]
		var goal_side: String = pair[1]
		var prev: Dictionary = {}
		var q: Array = []
		for r in rows:
			for c in cols:
				for t in 2:
					var key := Vector3i(c, r, t)
					var e: Array = _edges(cells, c, r, t)
					var on_start := (start_side == "far" and r == 0 and "far" in e) or (start_side == "left" and c == 0 and "left" in e)
					if on_start:
						prev[key] = null
						q.append(key)
		while not q.is_empty():
			var k: Vector3i = q.pop_front()
			var e2: Array = _edges(cells, k.x, k.y, k.z)
			var at_goal := (goal_side == "near" and k.y == rows - 1 and "near" in e2) or (goal_side == "right" and k.x == cols - 1 and "right" in e2)
			if at_goal:
				var chain: Array = []
				var cur = k
				while cur != null:
					chain.push_front(cur)
					cur = prev[cur]
				var pts: Array = []
				var f0: Vector3i = chain[0]
				var ic0: Vector2 = _incentre(cells, f0.x, f0.y, f0.z)
				pts.append(Vector2(ic0.x, -0.8) if start_side == "far" else Vector2(-0.8, ic0.y))
				pts.append(Vector2(ic0.x, 0.0) if start_side == "far" else Vector2(0.0, ic0.y))
				for i in chain.size():
					var a: Vector3i = chain[i]
					pts.append(_incentre(cells, a.x, a.y, a.z))
					if i + 1 < chain.size():
						var b: Vector3i = chain[i + 1]
						if b.x != a.x:
							pts.append(Vector2(maxi(a.x, b.x), a.y + 0.5))
						elif b.y != a.y:
							pts.append(Vector2(a.x + 0.5, maxi(a.y, b.y)))
				var lk: Vector3i = chain[chain.size() - 1]
				var icl: Vector2 = _incentre(cells, lk.x, lk.y, lk.z)
				pts.append(Vector2(icl.x, float(rows)) if goal_side == "near" else Vector2(float(cols), icl.y))
				pts.append(Vector2(icl.x, rows + 0.8) if goal_side == "near" else Vector2(cols + 0.8, icl.y))
				print("       way through: %s -> %s via %d triangles" % [start_side, goal_side, chain.size()])
				return pts
			var nbrs: Array = []
			for edge in e2:
				if edge == "right" and k.x + 1 < cols:
					nbrs.append(Vector3i(k.x + 1, k.y, 0 if not cells.get(Vector2i(k.x + 1, k.y), false) else 1))
				elif edge == "left" and k.x - 1 >= 0:
					nbrs.append(Vector3i(k.x - 1, k.y, 0 if cells.get(Vector2i(k.x - 1, k.y), false) else 1))
				elif edge == "near" and k.y + 1 < rows:
					nbrs.append(Vector3i(k.x, k.y + 1, 0))
				elif edge == "far" and k.y - 1 >= 0:
					nbrs.append(Vector3i(k.x, k.y - 1, 1))
			for nb in nbrs:
				if not prev.has(nb):
					prev[nb] = k
					q.append(nb)
	return []
