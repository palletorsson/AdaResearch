extends Node3D
class_name InteriorBlock

## interior_block — an interior is what a solid KEEPS FROM YOU, and the family keeps it in
## two directions that never meet.
##
## THE FAMILY. Three registry tokens declare an axis called `interior`, in two vocabularies.
## csg_architecture_cavity (boolean_surfaces.json) says none · corner · court · room: one wall,
## then two, three, four returning runs of a 2.6 m wall standing on a slab (gd:53-58, gd:246-
## 290). marchingcubes_flat_landscape (procgen_extra.json) and mc_flat_landscape
## (isosurfaces.json) say caverned · none · undercut · warren — and they are ONE SCENE, both
## entries resolve to Scenes/marchingcubes_flat_landscape.tscn whose script is
## TerrainGeneratorFlat.gd, so the census is three tokens, two scenes, seven words. The
## landscape's word is one float, CAVE_STRENGTHS (gd:177-182): none 0.0, undercut 0.3, caverned
## 0.4, warren 0.8, the k in `density = terrainDensity - caveNoise * k` — how much ridged 3D
## noise is subtracted from a heightfield.
##
## THE ARGUMENT. Read the code and the two vocabularies close the void in ORTHOGONAL
## directions. The wall's ladder is a ladder IN PLAN: corner is two runs at a right angle,
## court three runs open at the back, room four runs — and there is no roof at any rung
## (every run is wall_size.y = 2.6 m tall and nothing is ever laid across them), and the room
## has a doorway cut into its front run because the artifact's own desire is "a habitable
## space the player can walk through" (gd:293-294: only the FRONT run is entered). So a room,
## in this family, is walled all round, open to the sky and entered by a door. The landscape's
## ladder was sized by counting COLUMNS THAT GO SOLID-AIR-SOLID (gd:31-40: "columns whose
## solid/air classification changes more than once down y") — that is, ROOF. What the replica
## called "an inside" was air with rock above it and nothing else. So `room` has four walls
## and no lid; `caverned` has a lid and, as far as the census can say, no walls. Architecture
## withholds sideways and geology withholds from above, and the shared rung `none` — one wall,
## or a heightfield — is the block with nothing withheld in either direction.
##
## Laid on one block the seven words fill a small field — sides closed (of four) x roofed —
## and most of its cells are empty. And ONE cell is empty in a way that matters: not one of the
## seven, in either vocabulary, names a void you cannot reach. The wall's room has a door; the
## landscape's caves are "caves THROUGH the mass"; the replica counted roof, never reach, and
## reach was never measured. The family called this axis `interior` and never once meant the
## sealed pocket — the one thing a solid could actually keep from you. This artifact builds
## the marker for it (a sealed void casts DARK in the `void` reading, a reachable one glows)
## and reports, by flood fill, that on every one of the seven words it never fires.
##
## THE BODY, NOT A GAUGE. One block, 1.0 m, a 20 x 20 x 20 census of 5 cm cells — the same
## object the landscape's replica measured, a grid of solid/air, before marching cubes smooths
## it. Every variant is the same block with a different set of cells carved out, and the mesh
## is the block's face-culled shell: a quad wherever a solid cell meets air or the outside,
## normal from the solid into the air, so the outer hull faces out and every cavity wall faces
## INTO its cavity — a closed surface, watertight by construction, no boolean solver. Cavity
## volumes are held in one band (11.6 - 14.3 % of the block) for the five carved words that
## are not warren, so that what varies is how the void is CLOSED, not how much of it there
## is; warren alone is larger (21.5 %), because the landscape's warren is the one rung it calls
## void-dominated relative to the rest.

## WHICH INTERIOR — the union of both vocabularies, in order of increasing closure around the
## void, counted on the block (faces of six that the void is closed on; roofed = solid above):
##   none      csg's shipped single run and the landscape's k 0.0 heightfield: nothing carved.
##             8000 solid cells, void 0. Nothing withheld, from any side.
##   corner    csg gd:54 "two runs meeting at a right angle — shelter, a claim on space, no
##             inside". The top-left-front octant removed, 1000 cells (12.5 %): floor + two
##             walls (the +x mass and the back), open on -x, +z and above. Closed 3 of 6.
##   court     csg gd:55 "three runs, open at the back — enclosure felt before it is closed".
##             A 10 x 10 x 10 yard cut down from the top face, open toward the camera at +z
##             (the run nearest the camera is built first — csg's own lesson, gd:264-273):
##             floor + three walls, open on one side and above. 1000 cells. Closed 4 of 6.
##   room      csg gd:56 "four runs, the doorway in the front one: the first rung on which
##             the player is INSIDE and the void is bounded". A 10 x 10 x 10 pit closed on all
##             four sides, open to the sky, with a 4-wide 7-tall doorway through the 5-cell
##             front wall at floor level. 1140 cells (14.25 %). Closed 5 of 6 — the door is a
##             hole in a wall, not a missing wall. Only 140 of its 1140 cells (the doorway) are
##             roofed: a room in this family is a plan, not a lid.
##   undercut  the landscape's k 0.3, gd:54-62 "the first rung where the ground stops being
##             single-valued in y" — one overhang. A recess at the base of the front face, 14
##             wide, 6 tall, 11 deep, 924 cells (11.55 %), with 12 cells of block above it
##             and 2 below: floor + roof + three walls, open on the front only. Closed 5 of 6,
##             and 100 % roofed — the first rung with a lid.
##   caverned  the landscape's SHIPPED k 0.4, gd:42-46 "caves through the mass". A 10 x 10 x
##             10 chamber in the middle of the block, reached by a 4 x 4 mouth through the
##             front face at chamber-floor level. 1080 cells (13.5 %). Closed 6 of 6 but for
##             the mouth; the mouth is 16 of the front face's 400 cells.
##   warren    the landscape's k 0.8, gd:63-67 "void-dominated relative to the rest ... the
##             caves reach far below the surface band". Five chambers — a hub where the
##             cave's chamber was, two deep ones at one cell above the base, two high — linked
##             by four tunnels, entered by the SAME 4 x 4 mouth as caverned. 1720 cells
##             (21.5 %), reaching from cell 1 to cell 18 of 20 in y. Closed 6 of 6 but for the
##             one mouth. Every cell reachable: a warren is connected, that is the word.
@export_enum("none", "corner", "court", "room", "undercut", "caverned", "warren") var interior: String = "none":
	set(v):
		interior = v
		if is_inside_tree():
			_rebuild()

## WHAT IS READ OF THE BLOCK.
##   solid     the block from outside, whole. What the solid shows you is its openings and
##             nothing else — so caverned and warren are the SAME PICTURE (one mouth, the rest
##             inside), none differs from either by sixteen cells of mouth, and room, court,
##             corner and undercut show what they are because they are open where you stand.
##   section   the block cut through the middle on x — the +x half taken away, so the cut face
##             looks toward the camera — with the cut material filled dark (poche) where the
##             saw went through solid, and the cavities left in the body colour where it went
##             through air. The removed half is drawn as its twelve edges. The reading in
##             which the field is visible: walls or lid, door or mouth.
##   void      the hollow cast as its own body — the air cells inside the hull, meshed the same
##             way, glowing where a flood fill from outside can reach them and DARK where it
##             cannot — with the block itself absent but for its twelve edges. On none there is
##             nothing to cast, and the frame is the empty hull.
@export_enum("solid", "section", "void") var reading: String = "section":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

## One block or all seven in a row at LADDER_PITCH. NOT PART OF THE AXIS — a value that shows
## every rung at once, declared inside the ladder axis, makes capture_config_sweep union the
## AABB of the row with every single rung and photograph the singles as specks. The registry
## fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

const INTERIORS: PackedStringArray = ["none", "corner", "court", "room", "undercut", "caverned", "warren"]
const READINGS: PackedStringArray = ["solid", "section", "void"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## The census grid: N cells a side, SIZE metres. 20 keeps the build well under a frame and
## keeps every number in the glosses above exact; the block stands on y = 0.
const N: int = 20
## The section's cut plane, in cells: the +x half [HALF, N) is taken away. N >> 1 rather than
## N / 2 only to keep the integer-division warning out of a const.
const HALF: int = N >> 1
const SIZE: float = 1.0
const CELL: float = SIZE / float(N)
const LADDER_PITCH: float = 1.30
const EDGE_R: float = 0.004

## THE CARVES, in cells, half-open [i0, i1) x [j0, j1) x [k0, k1): i is x (right), j is y
## (up), k is z (toward the camera). Each entry is a union of boxes cut OUT of the solid.
const CARVES: Dictionary = {
	"none": [],
	"corner": [[0, 10, 10, 20, 10, 20]],
	"court": [[5, 15, 10, 20, 10, 20]],
	"room": [[5, 15, 10, 20, 5, 15], [8, 12, 10, 17, 15, 20]],
	"undercut": [[3, 17, 2, 8, 9, 20]],
	"caverned": [[5, 15, 4, 14, 5, 15], [8, 12, 4, 8, 15, 20]],
	"warren": [
		[6, 14, 4, 10, 9, 15],     # hub, where the cave's chamber was
		[8, 12, 4, 8, 15, 20],     # the mouth — the same box as caverned's
		[1, 10, 1, 6, 1, 8],       # deep, back-left, one cell above the base
		[6, 9, 4, 6, 7, 10],       # tunnel: hub <-> deep back-left
		[8, 17, 11, 18, 2, 9],     # high, back-right
		[9, 12, 8, 12, 6, 10],     # tunnel: hub <-> high back-right
		[12, 19, 1, 5, 12, 19],    # deep, front-right, one cell above the base
		[11, 14, 3, 6, 12, 15],    # tunnel: hub <-> deep front-right
		[1, 8, 12, 19, 11, 18],    # high, front-left
		[5, 8, 9, 13, 12, 15],     # tunnel: hub <-> high front-left
	],
}

## The wall's own colour, csg_architecture_cavity gd:104 wall_color, byte for byte.
const BODY: Color = Color(0.80, 0.76, 0.70)
## Section fill where the cut went through solid.
const POCHE: Color = Color(0.34, 0.29, 0.27)
## The void as a body: reachable glows, sealed does not.
const VOID_REACH: Color = Color(1.00, 0.72, 0.30)
const VOID_SEALED: Color = Color(0.16, 0.16, 0.19)
const RAIL: Color = Color(0.30, 0.31, 0.36)

var _built: Array[Node3D] = []
## The census of the last build, keyed by interior word: void, void_pct, reachable, sealed,
## roofed, open_top, sides_open, faces. What the readings show, as numbers.
var census: Dictionary = {}


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("interior"):
		interior = _pick(str(config_data["interior"]), INTERIORS, interior)
	if config_data.has("reading"):
		reading = _pick(str(config_data["reading"]), READINGS, reading)
	_rebuild()


func get_census() -> Dictionary:
	return census


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	census.clear()
	var names: Array = []
	if layout == "ladder":
		for w in INTERIORS:
			names.append(w)
	else:
		names.append(_pick(interior, INTERIORS, "none"))
	var count: int = names.size()
	for idx in range(count):
		var holder := Node3D.new()
		holder.name = str(names[idx])
		holder.position = Vector3((float(idx) - float(count - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, str(names[idx]))


# ── the census ──────────────────────────────────────────────────────────────────────────

func _idx(i: int, j: int, k: int) -> int:
	return (i * N + j) * N + k


## The block with one word's boxes carved out. 1 = solid, 0 = air.
func _solid_grid(word: String) -> PackedByteArray:
	var g := PackedByteArray()
	g.resize(N * N * N)
	g.fill(1)
	var boxes: Array = CARVES.get(word, []) as Array
	for b in boxes:
		var bx: Array = b as Array
		for i in range(int(bx[0]), int(bx[1])):
			for j in range(int(bx[2]), int(bx[3])):
				for k in range(int(bx[4]), int(bx[5])):
					g[_idx(i, j, k)] = 0
	return g


## Air cells a flood fill from outside the block can reach, through faces. 1 = reachable.
@warning_ignore("integer_division")
func _reach_grid(g: PackedByteArray) -> PackedByteArray:
	var r := PackedByteArray()
	r.resize(N * N * N)
	r.fill(0)
	var queue := PackedInt32Array()
	for i in range(N):
		for j in range(N):
			for k in range(N):
				var edge: bool = i == 0 or i == N - 1 or j == 0 or j == N - 1 or k == 0 or k == N - 1
				if edge and g[_idx(i, j, k)] == 0:
					r[_idx(i, j, k)] = 1
					queue.append(_idx(i, j, k))
	var head: int = 0
	while head < queue.size():
		var c: int = queue[head]
		head += 1
		var k: int = c % N
		var j: int = (c / N) % N
		var i: int = c / (N * N)
		var nb: Array = [[i + 1, j, k], [i - 1, j, k], [i, j + 1, k], [i, j - 1, k], [i, j, k + 1], [i, j, k - 1]]
		for p in nb:
			var a: int = int(p[0])
			var b: int = int(p[1])
			var d: int = int(p[2])
			if a < 0 or a >= N or b < 0 or b >= N or d < 0 or d >= N:
				continue
			var q: int = _idx(a, b, d)
			if g[q] == 0 and r[q] == 0:
				r[q] = 1
				queue.append(q)
	return r


func _take_census(g: PackedByteArray, r: PackedByteArray) -> Dictionary:
	var void_n: int = 0
	var reach_n: int = 0
	var roofed: int = 0
	var faces: Dictionary = {"+x": 0, "-x": 0, "+y": 0, "-y": 0, "+z": 0, "-z": 0}
	for i in range(N):
		for k in range(N):
			var solid_above: bool = false
			for j in range(N - 1, -1, -1):
				var c: int = _idx(i, j, k)
				if g[c] == 1:
					solid_above = true
					continue
				void_n += 1
				if r[c] == 1:
					reach_n += 1
				if solid_above:
					roofed += 1
				if i == N - 1:
					faces["+x"] = int(faces["+x"]) + 1
				if i == 0:
					faces["-x"] = int(faces["-x"]) + 1
				if j == N - 1:
					faces["+y"] = int(faces["+y"]) + 1
				if j == 0:
					faces["-y"] = int(faces["-y"]) + 1
				if k == N - 1:
					faces["+z"] = int(faces["+z"]) + 1
				if k == 0:
					faces["-z"] = int(faces["-z"]) + 1
	var sides_open: int = 0
	for f in ["+x", "-x", "+z", "-z"]:
		if int(faces[f]) > 0:
			sides_open += 1
	return {
		"void": void_n,
		"void_pct": 100.0 * float(void_n) / float(N * N * N),
		"reachable": reach_n,
		"sealed": void_n - reach_n,
		"roofed": roofed,
		"open_top": int(faces["+y"]) > 0,
		"sides_open": sides_open,
		"faces": faces,
	}


# ── the body ────────────────────────────────────────────────────────────────────────────

func _build_variant(holder: Node3D, word: String) -> void:
	var g: PackedByteArray = _solid_grid(word)
	var r: PackedByteArray = _reach_grid(g)
	census[word] = _take_census(g, r)
	var rd: String = _pick(reading, READINGS, "section")
	match rd:
		"solid":
			_add_shell(holder, g, g, false, BODY, 0.0, "Block")
		"section":
			var kept := PackedByteArray()
			kept.resize(N * N * N)
			for i in range(N):
				for j in range(N):
					for k in range(N):
						var c: int = _idx(i, j, k)
						kept[c] = g[c] if i < HALF else 0
			_add_shell(holder, kept, g, true, BODY, 0.0, "Block")
			_add_hull_edges(holder)
		_:
			# void: the air, cast. Reachable and sealed are never face-adjacent (the fill
			# would have joined them), so each is its own closed shell.
			var reach := PackedByteArray()
			var sealed := PackedByteArray()
			reach.resize(N * N * N)
			sealed.resize(N * N * N)
			var any_reach: bool = false
			var any_sealed: bool = false
			for c in range(N * N * N):
				var is_air: bool = g[c] == 0
				reach[c] = 1 if (is_air and r[c] == 1) else 0
				sealed[c] = 1 if (is_air and r[c] == 0) else 0
				any_reach = any_reach or reach[c] == 1
				any_sealed = any_sealed or sealed[c] == 1
			if any_reach:
				_add_shell(holder, reach, reach, false, VOID_REACH, 0.6, "VoidReachable")
			if any_sealed:
				_add_shell(holder, sealed, sealed, false, VOID_SEALED, 0.0, "VoidSealed")
			_add_hull_edges(holder)


## The face-culled shell of a cell set: one quad wherever a material cell meets a non-material
## cell or the outside, normal pointing out of the material. `full` is the uncut solid; when
## `section` is set, a +x face at the cut plane whose neighbour was solid in `full` is the saw
## going through material and is filled POCHE on its own surface, while a +x face there whose
## neighbour was air is a real cavity wall and stays in the body colour.
func _add_shell(holder: Node3D, material: PackedByteArray, full: PackedByteArray, section: bool,
		colour: Color, emit: float, label: String) -> void:
	var st_body := SurfaceTool.new()
	st_body.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_cut := SurfaceTool.new()
	st_cut.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body_faces: int = 0
	var cut_faces: int = 0
	var dirs: Array = [
		[Vector3i(1, 0, 0), Vector3.RIGHT], [Vector3i(-1, 0, 0), Vector3.LEFT],
		[Vector3i(0, 1, 0), Vector3.UP], [Vector3i(0, -1, 0), Vector3.DOWN],
		[Vector3i(0, 0, 1), Vector3.BACK], [Vector3i(0, 0, -1), Vector3.FORWARD],
	]
	for i in range(N):
		for j in range(N):
			for k in range(N):
				if material[_idx(i, j, k)] == 0:
					continue
				for d in dirs:
					var step: Vector3i = d[0]
					var nrm: Vector3 = d[1]
					var a: int = i + step.x
					var b: int = j + step.y
					var c: int = k + step.z
					var outside: bool = a < 0 or a >= N or b < 0 or b >= N or c < 0 or c >= N
					if not outside and material[_idx(a, b, c)] == 1:
						continue
					var at_cut: bool = section and step.x == 1 and i == HALF - 1 and not outside
					var is_cut: bool = at_cut and full[_idx(a, b, c)] == 1
					if is_cut:
						_quad(st_cut, i, j, k, nrm)
						cut_faces += 1
					else:
						_quad(st_body, i, j, k, nrm)
						body_faces += 1
	if body_faces > 0:
		var mi := MeshInstance3D.new()
		mi.name = label
		mi.mesh = st_body.commit()
		mi.material_override = _mat(colour, emit)
		holder.add_child(mi)
	if cut_faces > 0:
		var mc := MeshInstance3D.new()
		mc.name = label + "Cut"
		mc.mesh = st_cut.commit()
		mc.material_override = _mat(POCHE, 0.0)
		holder.add_child(mc)


## One face of cell (i, j, k) on the side `nrm`, wound clockwise as seen from outside (Godot's
## front face) with the normal set explicitly on every vertex; culling is off regardless.
func _quad(st: SurfaceTool, i: int, j: int, k: int, nrm: Vector3) -> void:
	var lo := Vector3((float(i) / float(N) - 0.5) * SIZE, float(j) / float(N) * SIZE,
			(float(k) / float(N) - 0.5) * SIZE)
	var hi: Vector3 = lo + Vector3(CELL, CELL, CELL)
	var centre: Vector3 = (lo + hi) * 0.5 + nrm * (CELL * 0.5)
	# Two tangents with u x v = nrm, so p0, p1, p2, p3 below runs counter-clockwise as seen
	# from +nrm. Checked by hand: BACK x RIGHT = UP, RIGHT x BACK = DOWN, UP x BACK = RIGHT,
	# BACK x UP = LEFT, RIGHT x UP = BACK, UP x RIGHT = FORWARD.
	var u: Vector3 = Vector3.RIGHT
	var v: Vector3 = Vector3.UP
	if nrm.y > 0.5:
		u = Vector3.BACK
		v = Vector3.RIGHT
	elif nrm.y < -0.5:
		u = Vector3.RIGHT
		v = Vector3.BACK
	elif nrm.x > 0.5:
		u = Vector3.UP
		v = Vector3.BACK
	elif nrm.x < -0.5:
		u = Vector3.BACK
		v = Vector3.UP
	elif nrm.z > 0.5:
		u = Vector3.RIGHT
		v = Vector3.UP
	else:
		u = Vector3.UP
		v = Vector3.RIGHT
	var h: float = CELL * 0.5
	var p0: Vector3 = centre - u * h - v * h
	var p1: Vector3 = centre + u * h - v * h
	var p2: Vector3 = centre + u * h + v * h
	var p3: Vector3 = centre - u * h + v * h
	# Clockwise from +nrm: p0, p3, p2, then p0, p2, p1.
	var order: Array = [p0, p3, p2, p0, p2, p1]
	for idx in range(order.size()):
		var p: Vector3 = order[idx]
		st.set_normal(nrm)
		st.add_vertex(p)


## The hull as its twelve edges: the block that is absent (void) or cut away (section).
func _add_hull_edges(holder: Node3D) -> void:
	var hs: float = SIZE * 0.5
	var ys: Array = [0.0, SIZE]
	var ss: Array = [-hs, hs]
	var n: int = 0
	for y in ys:
		for s in ss:
			# Along x at (y, z = s) and along z at (x = s, y).
			holder.add_child(_edge(Vector3(0.0, float(y), float(s)), Vector3(SIZE + EDGE_R * 2.0, EDGE_R * 2.0, EDGE_R * 2.0), "Edge%d" % n))
			n += 1
			holder.add_child(_edge(Vector3(float(s), float(y), 0.0), Vector3(EDGE_R * 2.0, EDGE_R * 2.0, SIZE + EDGE_R * 2.0), "Edge%d" % n))
			n += 1
	for sx in ss:
		for sz in ss:
			holder.add_child(_edge(Vector3(float(sx), hs, float(sz)), Vector3(EDGE_R * 2.0, SIZE + EDGE_R * 2.0, EDGE_R * 2.0), "Edge%d" % n))
			n += 1


func _edge(at: Vector3, size: Vector3, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	mi.material_override = _mat(RAIL, 0.0)
	return mi


func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	m.metallic = 0.05
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
