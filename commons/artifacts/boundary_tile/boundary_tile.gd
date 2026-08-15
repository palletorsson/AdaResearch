extends Node3D
class_name BoundaryTile

## boundary_tile — one mosaic, four things it is willing to admit about its own seams,
## and the symmetry that decides which of the four is TRUE.
##
## THE FAMILY. Three registry tokens declare an axis called `boundary` and they share
## ONE vocabulary, word for word and in the same order:
##
##   pattern_maker_station   none | edge | cell | lattice   (pattern_maker_station.gd:81)
##   vr_tile_editor          none | edge | cell | lattice   (vr_tile_editor.gd:52)
##   vr_tile_editor_mirror   none | edge | cell | lattice   (the SAME FILE — see below)
##
## THE TWO vr_tile_editor NAMES ARE ONE SCENE. Both registry entries point at
## res://commons/primitives/arrays/vr_tile_editor.tscn, whose root runs vr_tile_editor.gd.
## So this is the corpus's one-scene-many-names pattern for the seventh time — and it goes
## further than usual: `vr_tile_editor_mirror` carries a `config` block of
## {"tile_size": 4, "repeat_mode": 3}, and the shared script's own export defaults are
## tile_size = 4 and repeat_mode = 3. The config restates the defaults. The two names are
## not two objects, and they are not even two configurations. TWO SCRIPTS, THREE TOKENS,
## and all three ship `boundary = "none"`.
##
## THE ARGUMENT, and the code corrected the brief on three of its four glosses.
##
## A tiled pattern is made of copies. `boundary` is what the field is willing to SAY about
## that, and the four values are not one ladder — they answer two different questions:
##
##   none      says nothing. Both members return before building anything.
##   edge      a kerb round the OUTER RIM OF THE WHOLE FIELD. Not the tile border: the
##             carpet's border. Both members' own comments say it admits the floor "is a
##             made object with an end, and still says nothing about repeating". It is the
##             only value on the question "where does this object stop?".
##   cell      ONE unit cell framed and posted, ONCE, at the middle of the field. Not "each
##             unit inside the tile" — a single specimen among its copies.
##   lattice   a batten on every INTERNAL unit boundary. Both members exclude the outer rim
##             deliberately ("The outer edge is left to `edge`, so the two values stay
##             separate claims"), so lattice and edge are DISJOINT sets of marks and
##             lattice does NOT include edge.
##
## So the axis runs: no claim / a claim about the END / a claim about the UNIT, once /
## a claim about the unit, EVERYWHERE. And the claim about the unit is the one that can be
## WRONG, because `_build_boundary` in both members is computed from the field size and the
## repeat count ALONE. It never reads which symmetry laid the tiles down. `symmetry` is
## this bench's second axis and it exists to make that legible:
##
##   plain    RepeatMode.SIMPLE     — the tile translated. The unit IS the tile, so
##                                    `lattice` is exactly right.
##   mirror   RepeatMode.MIRROR_XY  — the tile reflected across every seam. The
##                                    translational unit becomes TWO tiles on a DIAGONAL
##                                    lattice, so `lattice` draws twice too many battens
##                                    and in the wrong orientation.
##   rotate   RepeatMode.ROTATE_90  — quarter-turns cascading down the diagonal. Same true
##                                    unit as mirror, for a reason built into the motif.
##
## AND THE DESIGNED NULL IS THE WHOLE POINT. The motif here is invariant under a half-turn
## and under its main diagonal, and under those two conditions MIRROR AND ROTATE PRODUCE
## THE SAME FLOOR, tessera for tessera, at every one of the four boundary values. Two
## different wallpaper rules, one photograph. The floor does not record which rule made it —
## which is exactly why a batten grid drawn from the tile count cannot be trusted to be
## about the pattern rather than about the grid it was drawn from.
##
## Deterministic: no randf, no noise, no _process, no Timer, no texture that bakes on a
## worker thread. Every vertex is arithmetic on ten constants and a hand-authored 4x4.


## WHAT THE FIELD ADMITS. Four values, the family's own words in the family's own order,
## and every mark below is built with the members' own arithmetic — k = 0.30 cell,
## t = 0.22 cell for the kerb; b = 0.12, t = 0.25, post 0.18 x 0.55 for the frame;
## b = 0.10, t = 0.12 for the battens — all of it lifted from pattern_maker_station.gd:732
## to :774 and vr_tile_editor.gd:449 to :498, which agree to the last coefficient.
##
##   none      nothing is drawn. Both members return before constructing a root. The
##             floor arrives seamless and says nothing, which is what a finished mosaic
##             wants you to believe. DRAWN AREA: 0.
##   edge      a kerb round the whole field, set just inside so it lands on the mosaic
##             rather than floating off it. 0.060 m wide, 0.044 m tall, covering 0.2256 m2
##             = 22.56 percent of the field. It is the ONLY value that changes the
##             SILHOUETTE, because it is the only one that stands at the outline.
##   cell      one unit cell framed by four battens and posted at its four corners. The
##             frame is aligned to a real tile boundary; with five repeats the index the
##             members' code picks is 2 and the frame lands DEAD CENTRE. Posts are
##             0.036 x 0.110 m, and the whole mark covers 0.0267 m2 = 2.67 percent of the
##             field — the smallest mark here, and the one lesson (e) is about.
##   lattice   a batten on all four internal boundaries in each direction, 0.020 m wide and
##             0.024 m tall, covering 0.1536 m2 = 15.36 percent. The outer rim is left to
##             `edge`. THIS IS THE VALUE THAT CAN BE WRONG.
## (One line, deliberately over the column guide: check_dna_declarations.py matches
## `@export_enum(...)` and its `var` on the SAME line, and a wrapped declaration reports
## NO EXPORT — a declared axis the gate cannot verify, which is the whole failure class.)
@export_enum("none", "edge", "cell", "lattice") var boundary: String = "none":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not BOUNDARIES.has(picked):
			return                      ## an unreachable value keeps the standing field
		boundary = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW THE COPIES WERE LAID. Three of the family's ten repeat modes, taken verbatim from
## pattern_tile_puzzle.gd's `_get_tiled_color` (:1252, :1270, :1280) — the function both
## members' carpets are ultimately drawn from.
##
##   plain    SIMPLE. tx = px % n, ty = py % n. Pure translation, nothing else. The tile is
##            the translational unit cell, so `lattice` is a true statement about this
##            floor and `cell` frames a real one.
##   mirror   MIRROR_XY, the kaleidoscope, and THE OPERATION vr_tile_editor_mirror IS NAMED
##            FOR: `if tile_x % 2 == 1: tx = n - 1 - tx` and the same in y. Every seam
##            becomes a reflection axis. The translational unit is now 2 tiles on a
##            diagonal lattice, so `lattice`'s battens outnumber the real joins 2 to 1 in
##            each direction and point the wrong way.
##   rotate   ROTATE_90, and note the idiosyncrasy, which is the source's and not this
##            bench's: the turn count is (px / n + py / n) % 4 — the SUM of the tile
##            indices, so the quarter-turns cascade along the anti-diagonal rather than
##            filling a 2 x 2 block.
@export_enum("plain", "mirror", "rotate") var symmetry: String = "plain":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not SYMMETRIES.has(picked):
			return
		symmetry = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One field, or all four boundaries in a row. NOT PART OF EITHER AXIS, and that is wave
## 13's lesson paid forward: capture_config_sweep unions the AABB across a spec's variants,
## so an all-boundaries value declared inside `boundary` would frame every single cell
## against five metres and photograph a 20 mm batten as a hairline. The registry fixture
## pins `single`. `ladder` is a design view, not a map placement.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const BOUNDARIES: PackedStringArray = ["none", "edge", "cell", "lattice"]
const SYMMETRIES: PackedStringArray = ["plain", "mirror", "rotate"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the field, and it is the same 1.00 x 1.00 m square in all twelve cells ─────────────
## SIDE is the whole footprint. Nothing — not the kerb, not the posts — reaches past it:
## the kerb's outer face lands exactly on +-SIDE/2 by the members' own `e = side/2 - k/2`.
## MEASURED EXTENTS, x by y by z in metres, of the twelve variants:
##   boundary=none      1.000 x 0.064 x 1.000
##   boundary=lattice   1.000 x 0.089 x 1.000
##   boundary=edge      1.000 x 0.109 x 1.000
##   boundary=cell      1.000 x 0.175 x 1.000   (the four posts, and the tallest thing here)
## Identical in x and z in every cell and in every symmetry, because `symmetry` moves
## colours and heights inside a fixed grid and never moves the grid. The union AABB the
## sweep frames on is therefore 1.000 x 0.175 x 1.000 in all twelve, diagonal 1.425 m.
const SIDE: float = 1.00
## FIVE REPEATS, AND THIS IS A DEVIATION FROM THE MEMBERS, DECLARED. pattern_maker_station
## ships carpet_repeats = 10 over a 4 m carpet and vr_tile_editor ships (8, 8) over 3 m, so
## both draw a cell about 0.4 m across. A 1 m bench at ten repeats would give a 0.1 m cell,
## and the family's mark arithmetic is all cell-relative: `cell`'s frame would then cover
## 0.68 percent of the field and land near the critic's blank floor, which is lesson (e).
## At five repeats the marks keep the members' exact proportions AGAINST THE CELL and come
## out twice as heavy against the FIELD. Five is also odd, which is why `cell` lands dead
## centre instead of the members' deliberate off-centre dodge.
const REPS: int = 5
## The motif is 4 x 4, the tile_size both members ship.
const TILE_N: int = 4
const NCELL: int = REPS * TILE_N
const PLATE_T: float = 0.018
## Grout: each tessera is 86 percent of its cell, so the dark bed shows between them. The
## gap is 0.007 m on a 0.050 m cell.
const GROUT: float = 0.86

# ── the motif ──────────────────────────────────────────────────────────────────────────
## FOUR-BY-FOUR, HAND-AUTHORED, AND CHOSEN FOR TWO PROPERTIES THAT ARE THE EXPERIMENT.
##
## (1) It is invariant under a HALF-TURN and under its MAIN DIAGONAL, and not under a
##     horizontal or vertical mirror. Those two invariances are exactly what makes
##     MIRROR_XY and ROTATE_90 produce the SAME FIELD: wherever mirror applies a flip,
##     rotate applies a quarter-turn, and the two land on the same tessera. Checked cell by
##     cell for all 25 tiles in a Python replica: identical, 400 of 400.
## (2) It is a graded diagonal ribbon — 3 on the diagonal, 1 beside it, 0 next, 2 in the
##     off corners — so under `plain` the ribbons run UNBROKEN from one side of the field
##     to the other and there is no visible seam anywhere, while under `mirror` they fold
##     into chevrons and every fold IS a seam. That is the axis's whole claim, drawn: at
##     `boundary=none` the plain floor genuinely hides its repeat, and the mirrored floor
##     genuinely cannot. 192 of 400 tesserae change between plain and mirror.
##
## READ AS MOTIF[y][x], which is the members' `_grid_data[ty][tx]` order. Plain nested
## arrays rather than PackedInt32Array, because a `const` needs a constant expression and a
## packed-array constructor inside an Array literal is not one.
const MOTIF: Array = [
	[3, 1, 0, 2],
	[1, 3, 1, 0],
	[0, 1, 3, 1],
	[2, 0, 1, 3],
]

# ── colour and relief ──────────────────────────────────────────────────────────────────
## THE PALETTE IS THE FAMILY'S, VERBATIM: PatternMakerStation.PALETTE[0..3], the Italian
## textile set that PatternTilePuzzle and ArrayCarpet also carry.
const C_TESSERA: Array[Color] = [
	Color(0.95, 0.92, 0.85),   ## 0 cream   pattern_maker_station.gd:30
	Color(0.80, 0.20, 0.15),   ## 1 red     pattern_maker_station.gd:31
	Color(0.15, 0.25, 0.50),   ## 2 navy    pattern_maker_station.gd:32
	Color(0.70, 0.55, 0.20),   ## 3 gold    pattern_maker_station.gd:33
]
## RELIEF, NOT TEXTURE, and the heights are this bench's. The members' carpets are an
## ImageTexture on a QuadMesh — a picture of a mosaic. This is real geometry, one box per
## tessera, because a boundary mark that is laid ON a floor has to have a floor to be laid
## on. The heights also carry the pattern a SECOND time, which is the colour-trap guard:
## red (Rec.709 0.324) and navy (0.247) sit within 0.077 of each other in luminance and
## would be greyscale near-twins on a flat carpet. Here they differ by 0.012 m of height,
## so the shading separates them whatever the critic measures.
const TESSERA_H: PackedFloat32Array = [0.008, 0.028, 0.016, 0.046]
## The bed the tesserae sit in. This colour is not a member's; it is the dark ground that
## makes the grout read, and it is declared as this bench's own.
const C_BED: Color = Color(0.19, 0.20, 0.23)
## THE MARKS' STONE, VERBATIM: pattern_maker_station.gd:715 and vr_tile_editor.gd:432 set
## the identical StandardMaterial3D — albedo (0.87, 0.85, 0.79), roughness 0.55,
## metallic 0.05. Two files, one material, not a coincidence.
const C_STONE: Color = Color(0.87, 0.85, 0.79)
const STONE_ROUGH: float = 0.55
const STONE_METAL: float = 0.05

## WHERE THE MARKS SIT. The members lay their boundary 1 mm over a FLAT carpet quad. This
## field is not flat — it has 0.046 m of relief — so a batten laid at the bed's height
## would be buried by its own floor. It is seated on the highest tessera instead, which is
## where a stone batten laid across an uneven mosaic actually comes to rest.
const MARK_LIFT: float = 0.001

const LADDER_PITCH: float = 1.30
## Iterated rather than written inline, so no loop variable is untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

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
	if config_data.has("boundary"):
		boundary = str(config_data["boundary"])
	if config_data.has("symmetry"):
		symmetry = str(config_data["symmetry"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _cell_size() -> float:
	return SIDE / float(REPS)


func _tessera_size() -> float:
	return SIDE / float(NCELL)


func _mark_base() -> float:
	var tallest: float = 0.0
	for h in TESSERA_H:
		tallest = maxf(tallest, float(h))
	return PLATE_T + tallest + MARK_LIFT


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = BOUNDARIES.duplicate()
	else:
		names.append(_pick(boundary, BOUNDARIES, "none"))
	var sym: String = _pick(symmetry, SYMMETRIES, "plain")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_bed(holder)
		_build_field(holder, sym)
		_build_marks(holder, names[i])


# ── the pattern ────────────────────────────────────────────────────────────────────────

## WHICH TESSERA OF THE MOTIF SHOWS AT GLOBAL (px, py). Transcribed from
## pattern_tile_puzzle.gd `_get_tiled_color`, branch for branch, including the integer
## divisions — the source does `var tile_x = px / tile_size` and so does this.
func _tile_value(sym: String, px: int, py: int) -> int:
	var ti: int = px / TILE_N
	var tj: int = py / TILE_N
	var tx: int = px % TILE_N
	var ty: int = py % TILE_N
	if sym == "mirror":
		if ti % 2 == 1:
			tx = TILE_N - 1 - tx
		if tj % 2 == 1:
			ty = TILE_N - 1 - ty
	elif sym == "rotate":
		var turns: int = (ti + tj) % 4
		for _r in range(turns):
			var ntx: int = TILE_N - 1 - ty
			var nty: int = tx
			tx = ntx
			ty = nty
	var row: Array = MOTIF[ty]
	return int(row[tx])


func _build_bed(holder: Node3D) -> void:
	var bed := SurfaceTool.new()
	bed.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(bed, Vector3(0.0, PLATE_T * 0.5, 0.0), Vector3(SIDE, PLATE_T, SIDE))
	_commit(holder, "Bed", bed, C_BED, 0.95, 0.0)


## One merged mesh per palette entry — four MeshInstance3D for four hundred tesserae,
## rather than four hundred nodes. The capture AABB counts MeshInstance3D, and these four
## plus the bed already span the full 1.00 x 1.00, so nothing here needs a sizing anchor.
func _build_field(holder: Node3D, sym: String) -> void:
	var tools: Array[SurfaceTool] = []
	for c in range(C_TESSERA.size()):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(st)
	var u: float = _tessera_size()
	var face: float = u * GROUT
	for py in range(NCELL):
		var z: float = -SIDE * 0.5 + (float(py) + 0.5) * u
		for px in range(NCELL):
			var x: float = -SIDE * 0.5 + (float(px) + 0.5) * u
			var v: int = _tile_value(sym, px, py)
			var h: float = float(TESSERA_H[v])
			_add_box(tools[v], Vector3(x, PLATE_T + h * 0.5, z), Vector3(face, h, face))
	for c in range(C_TESSERA.size()):
		_commit(holder, "Tesserae_%d" % c, tools[c], C_TESSERA[c], 0.80, 0.0)


# ── the marks ──────────────────────────────────────────────────────────────────────────
## EVERY COEFFICIENT BELOW IS THE MEMBERS', AND NOT ONE OF THEM READS `symmetry` — which
## is the finding, not an omission. pattern_maker_station's `_build_boundary` takes
## carpet_world_size and carpet_repeats; vr_tile_editor's takes carpet_size and
## carpet_repeats. Neither has any way to know whether the floor beneath was translated,
## reflected or turned, so the same battens are drawn over all three. This bench reproduces
## that faithfully: the mark geometry in `edge`, `cell` and `lattice` is bit-identical
## across plain, mirror and rotate.

func _build_marks(holder: Node3D, which: String) -> void:
	if which == "none":
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell: float = _cell_size()
	var base: float = _mark_base()
	match which:
		"edge":
			_marks_kerb(st, cell, base)
		"cell":
			_marks_cell(st, cell, base)
		"lattice":
			_marks_lattice(st, cell, base)
		_:
			pass
	_commit(holder, "Boundary", st, C_STONE, STONE_ROUGH, STONE_METAL)


## EDGE — a kerb round the whole field, set just inside so it lands on the mosaic rather
## than floating off it. pattern_maker_station.gd:732, vr_tile_editor.gd:449.
func _marks_kerb(st: SurfaceTool, cell: float, base: float) -> void:
	var k: float = cell * 0.30
	var t: float = cell * 0.22
	var e: float = SIDE * 0.5 - k * 0.5
	for s in SIGNS:
		_add_box(st, Vector3(0.0, base + t * 0.5, s * e), Vector3(SIDE, t, k))
		_add_box(st, Vector3(s * e, base + t * 0.5, 0.0), Vector3(k, t, SIDE))


## CELL — ONE unit cell framed and posted, aligned to a real tile boundary. The members
## compute the index as reps / 2 and offset by half a cell precisely so an EVEN repeat
## count does not put the frame on a join; at REPS = 5 that arithmetic returns index 2 and
## the frame lands on the exact centre of the field. pattern_maker_station.gd:746,
## vr_tile_editor.gd:463.
func _marks_cell(st: SurfaceTool, cell: float, base: float) -> void:
	var i0: int = REPS / 2
	var c: float = -SIDE * 0.5 + (float(i0) + 0.5) * cell
	var b: float = cell * 0.12
	var t: float = cell * 0.25
	var half: float = cell * 0.5
	for s in SIGNS:
		_add_box(st, Vector3(c, base + t * 0.5, c + s * half), Vector3(cell + b, t, b))
		_add_box(st, Vector3(c + s * half, base + t * 0.5, c), Vector3(b, t, cell + b))
	var p: float = cell * 0.18
	var ph: float = cell * 0.55
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(st, Vector3(c + sx * half, base + ph * 0.5, c + sz * half),
				Vector3(p, ph, p))


## LATTICE — a batten on every INTERNAL unit boundary. `range(1, REPS)` is the members'
## own bound and it is what keeps the outer rim out of this value, so `edge` and `lattice`
## remain separate claims rather than one accumulating decoration.
## pattern_maker_station.gd:768, vr_tile_editor.gd:488.
func _marks_lattice(st: SurfaceTool, cell: float, base: float) -> void:
	var b: float = cell * 0.10
	var t: float = cell * 0.12
	for i in range(1, REPS):
		var p: float = -SIDE * 0.5 + float(i) * cell
		_add_box(st, Vector3(p, base + t * 0.5, 0.0), Vector3(b, t, SIDE))
		_add_box(st, Vector3(0.0, base + t * 0.5, p), Vector3(SIDE, t, b))


# ── mesh primitives ────────────────────────────────────────────────────────────────────

## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at)
	_quad(st, p[5], p[4], p[7], p[6], at)
	_quad(st, p[3], p[2], p[6], p[7], at)
	_quad(st, p[4], p[5], p[1], p[0], at)
	_quad(st, p[1], p[5], p[6], p[2], at)
	_quad(st, p[4], p[0], p[3], p[7], at)


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if it
## points back at `inside`. Belt and braces: every material here is CULL_DISABLED as well,
## because four hundred boxes is four hundred chances for one inverted quad to photograph
## as a black speck that reads exactly like a missing tessera.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c + d) * 0.25
	if n.dot(mid - inside) < 0.0:
		n = -n
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for vtx in tri:
		st.set_normal(n)
		st.add_vertex(vtx)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh
## with no surfaces, it is an error in the log — which is exactly the `boundary = none`
## path, so the guard is load-bearing rather than defensive.
func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		rough: float, metal: float) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = m
	holder.add_child(mi)
