extends Node3D
class_name MotionPrimitive

## motion_primitive — a point in motion makes a line; a line in motion makes a plane; a
## plane in motion makes a body. Not four kinds of thing. ONE operation — sweep the
## generator along a direction — applied 0, 1, 2 and 3 times.
##
## Klee opens the Pedagogical Sketchbook with exactly this, and the grant this project
## was written under (doc/VR_VR_PT_2023.md) says the whole work is that book "in drag,
## in VR". The corpus already teaches the four rungs and teaches them as four OBJECTS,
## one per artifact, with nothing in the code that says they are the same move:
##
##   point              a grabbable sphere that prints its own (x,y,z). Its own @identity
##                      says it: "a point is position without extension", and
##                      "relationships: the seed of the whole primitives sequence — a line
##                      joins two points, a triangle closes three, a cube stacks eight".
##                      The relation is stated in a COMMENT. No code performs it.
##   line_builder_3d    N grabbable handles with a tube threaded through them
##                      (interactive_line.gd is the script the .tscn actually carries).
##                      Its truth line: "a line is a decision to connect points — the
##                      points are given, the connection is authored". A line here is an
##                      INTERPOLATION over samples, not a trace of a moving point.
##   parasol_triangle   the first surface. "A triangle is three points IN AN ORDER, and
##                      that order is the only thing that gives a flat sheet a front and
##                      a back." A plane arrives already closed, already sided.
##   invariants_demo    the transforms themselves, as buttons: TRANSLATE, ROTATE, SCALE,
##                      SHEAR, PROJECT applied to a figure that never leaves a trail. It
##                      asks what SURVIVES a move. Nobody has asked what a move LEAVES.
##
## So the family owns both halves of Klee's sentence and has never joined them. This
## bench joins them: the generator is drawn, it is swept, and the swept set is left
## standing WITH its generator still on it. The line carries the point that made it, the
## plane carries the line, the body carries the plane. That, and not the four shapes, is
## the claim — and it is the reason the ancestors are drawn in a different colour from
## the mark: an object CHANGES COLOUR here when it stops being the mark and becomes the
## generator of the next one.
##
## THE DISAGREEMENT AVAILABLE, and it is a real one: a swept solid is not how anybody
## builds a cube, and the reduction is a story rather than a construction — the corpus's
## own cube stacks eight points and its own triangle closes three, neither by sweeping.
## The place that costs something is `rank = point`, where the sweep has not happened and
## all three sweep values render THE SAME FRAME to the byte. If you think the four rungs
## are four things, that cell is free; if you think they are one operation counted, that
## cell is the operation at count zero, and it has to look like nothing.
##
## Deterministic: no randf, no noise, no _process, no Timer. Every vertex is arithmetic on
## P0 and three transform families, so two builds of one value are the same mesh.


## HOW MANY TIMES THE SWEEP HAS BEEN APPLIED. 0, 1, 2, 3.
##
## THESE ARE THIS ARTIFACT'S OWN WORDS AND NOT A MEMBER'S. No source declares an axis for
## dimension — point has `frame`/`attach`, parasol_triangle has `sidedness`/`convention`,
## line_builder_3d has `slack`, invariants_demo has `figure`/`pose`. `rank` is therefore
## SYNTHESIS-INTRODUCED, which is a weaker warrant than a derived axis and is recorded as
## such in the registry note. What is derived is only that the four rungs exist as four
## artifacts; naming their relation as one countable operation is the argument this bench
## is making, not a fact it inherited.
##
##   point   the generator itself, standing where it starts. The sweep has not run. This
##           is the default because it is the state every other rung is a history of.
##   line    the point swept once. The bead stays on the mark it made.
##   plane   the line swept again — a different direction, or the same thing would only
##           get longer. The line stays, in generator colour, at station 0.
##   body    the plane swept a third time. The plane stays, inset and standing proud of
##           the face it generated, with the line on its edge and the bead on its corner.
@export_enum("point", "line", "plane", "body") var rank: String = "point":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not RANKS.has(picked):
			return                      ## an unreachable value keeps the current figure
		rank = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW THE GENERATOR MOVES. Three of invariants_demo's six `pose` words, taken because it
## is the one member whose axis is about motion at all:
##   TAKEN     translate, rotate, scale
##   LEFT      none, shear, project — see the registry `declines` for why, and `project`
##             is left on the file's own authority: invariants_demo gd:356 says "PROJECT
##             is a READ, not a transform ... It leaves the vertices untouched."
##
##   translate  straight, constant direction. Segment, then parallelogram, then prism —
##              at STEP the three moves are +X, +Y, -Z, so this rung ladder is the cube.
##   rotate     the generator turns about an axis. Arc, then a fan of that arc, then a
##              horn. The three axes are Z, Y, X about three different centres, because
##              three rotations about ONE centre keep everything on one sphere and the
##              third sweep would gain no volume at all.
##   scale      the generator moves toward a centre and SHRINKS as it goes, so every rung
##              tapers: a ray-chunk, a wedge, a converging solid. The three centres differ
##              for the same reason — scaling twice about one centre only slides the
##              figure further along its own rays and stays one-dimensional.
@export_enum("translate", "rotate", "scale") var sweep: String = "translate":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not SWEEPS.has(picked):
			return
		sweep = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One rung, or all four in a row. NOT PART OF EITHER AXIS. capture_config_sweep unions
## the AABB across a spec's variants, so an all-rungs value declared inside `rank` would
## frame every single against four and a half metres and photograph the bead as a speck —
## which is wave 13's lesson, and the extent trap here is the worst in the corpus (the
## drawn figure runs 0.156 m at `point` and 0.650 m at `body`). The registry fixture pins
## `single`; the stage does the rest.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const RANKS: PackedStringArray = ["point", "line", "plane", "body"]
const SWEEPS: PackedStringArray = ["translate", "rotate", "scale"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the stage, and it is the whole answer to the extent trap ───────────────────────────
## A point is 0.156 m across and a body is 0.650 m across, so an AABB fitted to the FIGURE
## would move by a factor of four across the sheet and the `point` tile would photograph
## as a speck in an empty frame. The plate, the four pins and the four top rails are drawn
## IDENTICALLY in all twelve variants and are the largest thing in the scene, so the union
## AABB is 0.96 x 1.00 x 0.96 in every cell, by construction, and the camera never moves.
## The stage is also the reason a `point` tile is legible at all: it reads as a room with
## one bead in it rather than as a blank.
const STAGE_HALF: float = 0.48
const STAGE_H: float = 1.00
const PLATE_T: float = 0.024
const PIN: float = 0.032

# ── the figure ─────────────────────────────────────────────────────────────────────────
## THE ONE POINT ALL TWELVE VARIANTS SHARE. It is the same bead at the same place under
## every sweep, which is what makes `rank = point` a null across the whole sweep axis
## rather than three nearly-equal frames.
const P0: Vector3 = Vector3(-0.26, 0.20, 0.26)
## Stations per sweep. 13 samples, 12 spans.
const N: int = 12
## How far the generator's start point travels, per application. Measured on the built
## geometry: translate 0.5600 / 0.5600 / 0.5600, scale 0.5600 / 0.5600 / 0.5600, rotate
## 0.5595 / 0.5595 / 0.4754 (the third rotation is 0.85 of a full step because a full one
## carries the fan through the stage wall — the shortfall is recorded rather than hidden).
const STEP: float = 0.56

const TRA_DIR: PackedVector3Array = [
	Vector3(STEP, 0.0, 0.0), Vector3(0.0, STEP, 0.0), Vector3(0.0, 0.0, -STEP)]

const ROT_AXIS: PackedVector3Array = [
	Vector3(0.0, 0.0, 1.0), Vector3(0.0, 1.0, 0.0), Vector3(1.0, 0.0, 0.0)]
const ROT_CENTRE: PackedVector3Array = [
	Vector3(0.05, 0.24, 0.26), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.46, -0.10)]
## Angles are not round numbers because they are DERIVED: each is STEP divided by the
## radius the generator actually turns on, so a rotation moves the point the same distance
## a translation does. r = 0.31257, 0.31443, 0.23300.
const ROT_ANGLE: PackedFloat32Array = [-1.7916, -1.7810, -2.0402]

const SCA_CENTRE: PackedVector3Array = [
	Vector3(0.42, 0.90, -0.42), Vector3(-0.42, 0.90, -0.30), Vector3(0.30, 0.06, 0.42)]
## Every factor is BELOW 1 and every centre is inside the stage, which is not a taste: for
## s in (0,1] the image of a point is a convex combination of the centre and the point, so
## the whole scale figure is inside the convex hull of P0 and the three centres, and cannot
## leave the box whatever the sheet does. Growing outward has no such guarantee and put
## three trial geometries through the stage wall.
const SCA_END: PackedFloat32Array = [0.5292, 0.2598, 0.3564]

# ── how thick a mark is ────────────────────────────────────────────────────────────────
const BEAD_R: float = 0.078
const TUBE_R: float = 0.040        ## a line while it is the mark
const GEN_TUBE_R: float = 0.036    ## the same line once it is the generator
const RIB_R: float = 0.014         ## the generator at an intermediate station
const SHEET_T: float = 0.020
const GEN_SHEET_T: float = 0.014
const SHELL_T: float = 0.004
## How far a generator stands off the set it is about to sweep out. Without it the warm
## plane z-fights the cool face it generated and the tile is a flicker of two materials.
const PROUD: float = 0.010
## Which stations get a rib. Not every station: 13 ribs on a 0.65 m sheet is a texture,
## and the reading is "the generator was here, and here, and here".
const RIBS: PackedInt32Array = [3, 6, 9, 12]

const LADDER_PITCH: float = 1.15
## Iterated rather than written as a literal array, so no loop variable is untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

# ── colour carries the argument ────────────────────────────────────────────────────────
## The swept set is COOL and every ancestor still standing is WARM. So the same tube is
## cyan at rank=line, where it is the mark, and amber at rank=plane, where it is the
## generator. Nothing about the geometry changes between those two tiles; the ROLE does.
const C_PLATE: Color = Color(0.20, 0.21, 0.24)
const C_STAGE: Color = Color(0.42, 0.43, 0.47)
const C_SWEPT: Color = Color(0.42, 0.86, 1.00)
const C_GEN: Color = Color(0.98, 0.84, 0.38)
const C_BEAD: Color = Color(1.00, 0.98, 0.92)
const C_RIB: Color = Color(0.62, 0.50, 0.24)
const E_SWEPT: Color = Color(0.16, 0.42, 0.58)
const E_GEN: Color = Color(0.52, 0.42, 0.14)

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("rank"):
		rank = str(config_data["rank"])
	if config_data.has("sweep"):
		sweep = str(config_data["sweep"])
	_bulk = false
	_rebuild()


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
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = RANKS.duplicate()
	else:
		names.append(_pick(rank, RANKS, "point"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Rank_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_figure(holder, names[i])


# ── the operation ──────────────────────────────────────────────────────────────────────

## THE WHOLE ARGUMENT IN SIX LINES. One transform family per step, selected by `sweep`;
## the rank is just how many of them have been applied. Rotation and scaling share the
## same conjugation — move the centre to the origin, act, move it back — so the three
## values differ in what B is and in nothing else.
func _xform(step: int, t: float) -> Transform3D:
	if sweep == "rotate":
		var axis: Vector3 = ROT_AXIS[step]
		var rc: Vector3 = ROT_CENTRE[step]
		var rb: Basis = Basis(axis, ROT_ANGLE[step] * t)
		return Transform3D(rb, rc - rb * rc)
	if sweep == "scale":
		var sc: Vector3 = SCA_CENTRE[step]
		var f: float = 1.0 + (SCA_END[step] - 1.0) * t
		var sb: Basis = Basis.IDENTITY.scaled(Vector3(f, f, f))
		return Transform3D(sb, sc - sb * sc)
	return Transform3D(Basis.IDENTITY, TRA_DIR[step] * t)


## The point after one sweep: the trail of P0. rank=line is this and nothing else.
func _level1() -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for i in range(N + 1):
		out.append(_xform(0, float(i) / float(N)) * P0)
	return out


## The line after a second sweep: grid[i][j], i along the line, j along the new direction.
func _level2(a1: PackedVector3Array) -> Array:
	var out: Array = []
	for i in range(a1.size()):
		var row: PackedVector3Array = PackedVector3Array()
		for j in range(N + 1):
			row.append(_xform(1, float(j) / float(N)) * a1[i])
		out.append(row)
	return out


## The plane after a third sweep: cube[i][j] is a PackedVector3Array over k.
func _level3(a2: Array) -> Array:
	var out: Array = []
	for i in range(a2.size()):
		var plane_row: Array = []
		var src: PackedVector3Array = a2[i]
		for j in range(src.size()):
			var col: PackedVector3Array = PackedVector3Array()
			for k in range(N + 1):
				col.append(_xform(2, float(k) / float(N)) * src[j])
			plane_row.append(col)
		out.append(plane_row)
	return out


## Lift a generator clear of the set it is about to sweep out, against the direction that
## sweep will take it. Generic, so it works for a rotation and a scaling too.
func _proud(pts: PackedVector3Array, step: int) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	var t: Transform3D = _xform(step, 0.02)
	for p in pts:
		var d: Vector3 = t * p - p
		if d.length() < 0.000001:
			out.append(p)
		else:
			out.append(p - d.normalized() * PROUD)
	return out


func _proud_grid(grid: Array, step: int) -> Array:
	var out: Array = []
	for i in range(grid.size()):
		var row: PackedVector3Array = grid[i]
		out.append(_proud(row, step))
	return out


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(STAGE_HALF * 2.0, PLATE_T, STAGE_HALF * 2.0))
	_commit(holder, "Plate", plate, C_PLATE, Color.BLACK)

	var cage := SurfaceTool.new()
	cage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var off: float = STAGE_HALF - PIN * 0.5
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(cage, Vector3(sx * off, STAGE_H * 0.5, sz * off),
				Vector3(PIN, STAGE_H, PIN))
	for sz in SIGNS:
		_add_box(cage, Vector3(0.0, STAGE_H - PIN * 0.5, sz * off),
			Vector3(STAGE_HALF * 2.0 - PIN * 2.0, PIN, PIN))
	for sx in SIGNS:
		_add_box(cage, Vector3(sx * off, STAGE_H - PIN * 0.5, 0.0),
			Vector3(PIN, PIN, STAGE_HALF * 2.0 - PIN * 2.0))
	_commit(holder, "Cage", cage, C_STAGE, Color.BLACK)


func _build_figure(holder: Node3D, which: String) -> void:
	var swept := SurfaceTool.new()
	swept.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gen := SurfaceTool.new()
	gen.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ribs := SurfaceTool.new()
	ribs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bead := SurfaceTool.new()
	bead.begin(Mesh.PRIMITIVE_TRIANGLES)

	# The bead is drawn under every rank. It is the generator's generator, all the way
	# down, and at rank=point it is the entire artifact.
	_add_sphere(bead, P0, BEAD_R, 10, 14)
	var has_swept: bool = which != "point"
	var has_gen: bool = which == "plane" or which == "body"
	var has_ribs: bool = has_swept

	if which != "point":
		var a1: PackedVector3Array = _level1()
		if which == "line":
			_add_tube(swept, a1, TUBE_R, 8)
			for r in RIBS:
				_add_sphere(ribs, a1[r], RIB_R * 1.6, 6, 10)
		else:
			var a2: Array = _level2(a1)
			if which == "plane":
				_add_sheet(swept, a2, SHEET_T)
				for r in RIBS:
					_add_tube(ribs, _column(a2, r), RIB_R, 6)
			else:
				var a3: Array = _level3(a2)
				_add_shell(swept, a3)
				for r in RIBS:
					_add_tube(ribs, _loop(_slice_k(a3, r)), RIB_R, 6)
				# INSET, and that is not decoration. Drawn flush the generator plane is
				# the whole front face and the body photographs as a warm slab with the
				# swept set hidden behind its own generator — the corpus's "the artifact's
				# own furniture is IN FRONT of its marks" fault, caught in the replica.
				_add_sheet(gen, _proud_grid(_inset(a2, 2), 2), GEN_SHEET_T)
			_add_tube(gen, _proud(a1, 1), GEN_TUBE_R, 8)

	# Only non-empty tools are committed. SurfaceTool.commit() on a tool that was begun
	# and never given a vertex is not a mesh with no surfaces, it is an error in the log,
	# and at rank=point three of these four are empty by design.
	if has_swept:
		_commit(holder, "Swept", swept, C_SWEPT, E_SWEPT)
	if has_gen:
		_commit(holder, "Generator", gen, C_GEN, E_GEN)
	if has_ribs:
		_commit(holder, "Stations", ribs, C_RIB, Color.BLACK)
	_commit(holder, "Point", bead, C_BEAD, Color.BLACK)


func _column(grid: Array, j: int) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for i in range(grid.size()):
		var row: PackedVector3Array = grid[i]
		out.append(row[j])
	return out


func _slice_k(cube: Array, k: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		var row: PackedVector3Array = PackedVector3Array()
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			row.append(col[k])
		out.append(row)
	return out


func _slice_j(cube: Array, j: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		out.append(plane_row[j])
	return out


func _slice_i(cube: Array, i: int) -> Array:
	var out: Array = []
	var plane_row: Array = cube[i]
	for j in range(plane_row.size()):
		out.append(plane_row[j])
	return out


func _inset(grid: Array, m: int) -> Array:
	var out: Array = []
	for i in range(m, grid.size() - m):
		var row: PackedVector3Array = grid[i]
		var cut: PackedVector3Array = PackedVector3Array()
		for j in range(m, row.size() - m):
			cut.append(row[j])
		out.append(cut)
	return out


## The rim of a grid, once round. Used for the station marks on a body: at rank=body the
## generator is a plane, so "the generator was here" is that plane's outline.
func _loop(grid: Array) -> PackedVector3Array:
	var ni: int = grid.size()
	var first: PackedVector3Array = grid[0]
	var last: PackedVector3Array = grid[ni - 1]
	var nj: int = first.size()
	var out: PackedVector3Array = PackedVector3Array()
	for i in range(ni):
		var row_a: PackedVector3Array = grid[i]
		out.append(row_a[0])
	for j in range(1, nj):
		out.append(last[j])
	for i in range(ni - 2, -1, -1):
		var row_b: PackedVector3Array = grid[i]
		out.append(row_b[nj - 1])
	for j in range(nj - 2, -1, -1):
		out.append(first[j])
	return out


# ── mesh primitives ────────────────────────────────────────────────────────────────────

func _add_sheet(st: SurfaceTool, grid: Array, thick: float) -> void:
	var ni: int = grid.size()
	if ni < 2:
		return
	var probe: PackedVector3Array = grid[0]
	var nj: int = probe.size()
	if nj < 2:
		return
	var top: Array = []
	var bot: Array = []
	for i in range(ni):
		var rt: PackedVector3Array = PackedVector3Array()
		var rb: PackedVector3Array = PackedVector3Array()
		var row: PackedVector3Array = grid[i]
		for j in range(nj):
			var n: Vector3 = _grid_normal(grid, i, j, ni, nj)
			rt.append(row[j] + n * (thick * 0.5))
			rb.append(row[j] - n * (thick * 0.5))
		top.append(rt)
		bot.append(rb)
	for i in range(ni - 1):
		var t0: PackedVector3Array = top[i]
		var t1: PackedVector3Array = top[i + 1]
		var b0: PackedVector3Array = bot[i]
		var b1: PackedVector3Array = bot[i + 1]
		for j in range(nj - 1):
			_quad(st, t0[j], t1[j], t1[j + 1], t0[j + 1])
			_quad(st, b0[j], b0[j + 1], b1[j + 1], b1[j])


func _grid_normal(grid: Array, i: int, j: int, ni: int, nj: int) -> Vector3:
	var up_row: PackedVector3Array = grid[mini(i + 1, ni - 1)]
	var dn_row: PackedVector3Array = grid[maxi(i - 1, 0)]
	var here: PackedVector3Array = grid[i]
	var du: Vector3 = up_row[j] - dn_row[j]
	var dv: Vector3 = here[mini(j + 1, nj - 1)] - here[maxi(j - 1, 0)]
	var n: Vector3 = du.cross(dv)
	if n.length() < 0.000001:
		return Vector3(0.0, 0.0, 1.0)
	return n.normalized()


## A body is drawn as the six boundary sheets of the (i, j, k) grid — the faces of the
## parameter cube carried into space. Under `translate` that is a cube; under `rotate` and
## `scale` it is whatever the transforms make of it, which is the point.
func _add_shell(st: SurfaceTool, cube: Array) -> void:
	var ni: int = cube.size()
	var plane_row: Array = cube[0]
	var nj: int = plane_row.size()
	var col: PackedVector3Array = plane_row[0]
	var nk: int = col.size()
	_add_sheet(st, _slice_k(cube, 0), SHELL_T)
	_add_sheet(st, _slice_k(cube, nk - 1), SHELL_T)
	_add_sheet(st, _slice_j(cube, 0), SHELL_T)
	_add_sheet(st, _slice_j(cube, nj - 1), SHELL_T)
	_add_sheet(st, _slice_i(cube, 0), SHELL_T)
	_add_sheet(st, _slice_i(cube, ni - 1), SHELL_T)


func _add_tube(st: SurfaceTool, path: PackedVector3Array, r: float, sides: int) -> void:
	var n: int = path.size()
	if n < 2:
		return
	var rings: Array = []
	for i in range(n):
		var d: Vector3 = Vector3(1.0, 0.0, 0.0)
		if i == 0:
			d = path[1] - path[0]
		elif i == n - 1:
			d = path[n - 1] - path[n - 2]
		else:
			d = path[i + 1] - path[i - 1]
		if d.length() < 0.000001:
			d = Vector3(1.0, 0.0, 0.0)
		d = d.normalized()
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		if absf(d.dot(up)) > 0.9:
			up = Vector3(1.0, 0.0, 0.0)
		var right: Vector3 = d.cross(up).normalized()
		var fwd: Vector3 = right.cross(d).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for s in range(sides):
			var a: float = TAU * float(s) / float(sides)
			ring.append(path[i] + (right * cos(a) + fwd * sin(a)) * r)
		rings.append(ring)
	for i in range(n - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for s in range(sides):
			var t: int = (s + 1) % sides
			_quad(st, r0[s], r1[s], r1[t], r0[t])


func _add_sphere(st: SurfaceTool, centre: Vector3, r: float, rings: int, segs: int) -> void:
	var pts: Array = []
	for i in range(rings + 1):
		var th: float = PI * float(i) / float(rings)
		var ring: PackedVector3Array = PackedVector3Array()
		for j in range(segs):
			var ph: float = TAU * float(j) / float(segs)
			ring.append(centre + Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)) * r)
		pts.append(ring)
	for i in range(rings):
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j in range(segs):
			var k: int = (j + 1) % segs
			_quad(st, r0[j], r1[j], r1[k], r0[k])


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3])
	_quad(st, p[5], p[4], p[7], p[6])
	_quad(st, p[3], p[2], p[6], p[7])
	_quad(st, p[4], p[5], p[1], p[0])
	_quad(st, p[1], p[5], p[6], p[2])
	_quad(st, p[4], p[0], p[3], p[7])


## Two triangles wound a -> b -> c -> d with the normal taken from the winding, and every
## material is CULL_DISABLED besides: a swept surface has no honest inside, and wave 13's
## lesson is that a sheet photographed from behind is indistinguishable from a sheet that
## was never built.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emission: Color) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emission)
	holder.add_child(mi)


func _mat(c: Color, emission: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.55
	return m
