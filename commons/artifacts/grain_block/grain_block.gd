# @identity
# essence: one 1 m block, cut five ways at once, so the family's word for how a solid is
#          divided can be READ ACROSS instead of chosen between
# desire: to stop `grain` being five separate photographs and make it one argument
# critical_parameter: kerf - where the cut's own width is taken from. drawn takes nothing
#          and says everything; inward takes it out of the material; outward takes it out
#          of the room. shut takes nothing and says nothing, and four of the five bays
#          then photograph as one cube.
# triggers: _ready() builds the whole bench standalone; apply_grid_config rebuilds only
#          when a declared value actually moved
# emerges: a ladder that is not a ladder - solid, split and quartered nest, quartered and
#          lattice do not, and shell is a different operation wearing the same word
# needs: cube_scene.gd for the five words, their order and the family's own gauge, read
#        live as FAM.GRAINS / FAM.SPLIT_GAP / FAM.QUARTER_GAP / FAM.LATTICE_GAP /
#        FAM.SHELL_SECTION [present]; no collider, no text, no ground [absent by choice]
# relationships: synthesis over the `grain` family's (a) dialect - cube_scene,
#        prism_block, grabbable_line - and it REFUSES the other three dialects on the
#        record; adopts its word by exhibiting it, as taxonomy_hall and instruction_bench do
# truth: every member of this family claims a constant envelope and pays for its seams out
#        of the material, and two of the three break the claim doing it. The seam is not
#        a property of the division. It is a decision about where the cut's width is
#        stolen from, and nobody in the family has ever stated it.

extends Node3D
class_name GrainBlock

## THE FAMILY'S OWN SCRIPT. The five words, their ORDER, and the gauge this bench
## re-derives are all read out of here at build time. Read as FAM.GRAINS rather than
## through Object.get() (a const is not a property, so get() returns null and this bench
## would silently fall back to a private copy) and rather than through
## get_script_constant_map() (non-static; it cannot be called on the class at all).
## FAM.GRAINS also fails at PARSE time if the const ever disappears, which is a better
## failure mode than either.
const FAM := preload("res://commons/primitives/cubes/cube_scene.gd")


# ═══════════════════════════════════════════════════════════════════════════════
# THE WORD THIS BENCH EXHIBITS, AND WHY IT IS NOT AN AXIS
# ═══════════════════════════════════════════════════════════════════════════════
#
# `grain` carries FOUR different questions across its six declared members:
#
#   (a) solid|split|quartered|lattice|shell   cube_scene, prism_block, grabbable_line
#       HOW A SOLID IS DIVIDED - the direction and scale at which a body gives way.
#   (b) points|beads|stroke|flood             pedagogical_sketchbook
#       HOW A MARK IS LAID DOWN.
#   (c) rows|columns|diagonal|rings           rotate_grid_cubes
#       THE ORDER A GRID IS READ IN.
#   (d) meridian|parallel|even                sphere_low
#       HOW A SPHERE IS TESSELLATED.
#
# This bench takes (a) and says so: it is the only one of the four that is about the
# GRAIN OF A MATERIAL, which is what the word means outside this corpus. The other three
# are mark-making, traversal order and tessellation - three different words wearing one.
#
# IS THE LADDER A LADDER? Read out of the members' code, not their prose:
#
#   solid -> split      NESTS. One cut plane, at y = 0.
#   split -> quartered  NESTS. cube_scene's _build_quartered cuts at x = y = z = 0, and
#                       {y=0} is a subset of that. The two halves ARE unions of the eight.
#   quartered -> lattice DOES NOT NEST. _build_lattice puts twenty-seven 0.30 cubes on a
#                       0.32 pitch, so its cut planes fall at +-0.16 - and {0} is not a
#                       subset of {-0.16, +0.16}. No sub-cube of the eight is a union of
#                       sub-cubes of the twenty-seven. The rungs are FINER but they are
#                       not nested.
#   lattice -> shell    IS NOT A CUT AT ALL. _build_shell adds no sub-cubes; it builds
#                       twelve struts of a different shape, and grabbable_line's
#                       _grain_part_count() returns 0 for shell - the one rung that draws
#                       no body, because for a segment the boundary IS the two endpoints.
#
# So the case is MIXED: two rungs nest, one does not, and the last changes the operation
# from subtraction to structure. A mixed set cannot be swept without demolishing the very
# comparison it exists to make, so THE SIMULTANEITY IS THE OBJECT: all five stand at once
# and what varies is two things the family has never varied.


# ═══════════════════════════════════════════════════════════════════════════════
# AXIS 1 - kerf
# ═══════════════════════════════════════════════════════════════════════════════
#
# A kerf is the width a saw takes out. Every member of this family opens its cuts by a
# constant - cube_scene SPLIT_GAP 0.04, QUARTER_GAP 0.04, LATTICE_GAP 0.02;
# prism_block SPLIT_GAP 0.04, QUARTER_PUSH 0.010, LATTICE_PUSH 0.004; grabbable_line
# PART_GAP_FRACTION 0.28 - and not one of them exposes it or discusses where it comes
# from. Without it, four of the five words are the same photograph.
#
#   inward   the kerf comes out of the PIECES. Cells shrink about their own centres and
#            the 1 m envelope is exactly preserved. This is the family's discipline.
#   shut     no kerf. The cells are separate bodies and they touch, so solid, split,
#            quartered and lattice are four photographs of one cube.
#   drawn    no kerf either - the cut is DEPICTED, a band of exactly the same width laid
#            on every outer face the plane meets. The division as a description.
#   outward  the kerf goes BETWEEN the pieces. Cells keep full size, nothing is removed,
#            and the block grows out of its own unit.
#
# ONE NUMBER, FOUR READINGS: _kerf_width is painted by `drawn`, subtracted by `inward`,
# inserted by `outward`, and is what `shut` sets to zero.
@export_group("Grain bench")
## Where the cut's own width is taken from. `inward` is the family's discipline and the
## default; see the registry's dna.default for why.
@export_enum("inward", "shut", "drawn", "outward") var kerf: String = "inward"

## What the division is reckoned against. `none` is the bare row.
@export_enum("none", "mass", "void", "count") var reckoning: String = "none"

const KERFS: PackedStringArray = ["inward", "shut", "drawn", "outward"]
const RECKONINGS: PackedStringArray = ["none", "mass", "void", "count"]

## The five bays this bench knows how to build. Membership and ORDER come from
## FAM.GRAINS at build time; this list exists only so _check_family_words can complain
## in BOTH directions when the family and the bench stop agreeing.
const BUILDABLE: PackedStringArray = ["solid", "split", "quartered", "lattice", "shell"]


# ── Layout ────────────────────────────────────────────────────────────────────
## Bay centre to bay centre. At the capture standpoint (yaw 0.62) this is 113 px of
## screen separation against a 1 m cube's 114 px silhouette, so the bays just touch at
## `inward` and overlap at `outward` - which is the exploded block failing to fit the
## room it was given, and is left visible rather than padded away.
const BAY_PITCH: float = 1.70

## The gauged minimum feature, in metres, at this bench's own framing (dna.framing 0.60,
## 81.55 px/m). The worst-projecting slot - one normal to Z, read on the +X face - is
## 0.6062 of its own width on screen, so 0.11 m lands at 5.21 px. Below 0.10 m it drops
## under five and the lattice stops being photographable. See dna.framing_why.
const KERF_FLOOR: float = 0.11
const SECTION_FLOOR: float = 0.11

## The register above each bay: four columns by seven rows of cells, so twenty-eight
## places against the family's largest piece count of twenty-seven. A CEILING FIXED
## ACROSS THE WHOLE AXIS, and fixed by the vocabulary rather than by the frame.
const REG_COLS: int = 4
const REG_ROWS: int = 7
const REG_CELL: float = 0.08
const REG_GAP: float = 0.04
const REG_DEPTH: float = 0.08
## Register floor. Fixed, so it does not move when `kerf` grows a block: the tallest
## thing under it is the lattice at outward, 1.22 m.
const REG_Y: float = 1.32

## How far a scribed band stands off the face it marks.
const DRAW_PROUD: float = 0.002


# ── Palette, member by member ─────────────────────────────────────────────────
## grabbable_line.gd's line_color. Taken as-is and not averaged out of a shader, because
## it is the one place in this family whose look is a plain StandardMaterial3D albedo.
## A stale compiled shader photographs as a dead axis (gyroid_demo read 0.00% across
## sixteen byte-identical tiles), and a bench whose whole subject is a comparison cannot
## afford a grain it cannot trust to be the same grain in every tile.
const C_BLOCK := Color(0.788, 0.463, 0.996)
## cube_scene.tscn's Grid.gdshader emissionColor - the family's own highlight.
const C_MARK := Color(0.981557, 0.761247, 0.912913)
## balance_puzzle.gd's platform_color - the project's neutral apparatus grey.
const C_APPARATUS := Color(0.3, 0.3, 0.35)
## transform_puzzle_base.gd's ghost_color and ghost_alpha - the project's ghost.
const C_VOID := Color(0.0, 0.8, 1.0)
const VOID_ALPHA: float = 0.25


# ── State ─────────────────────────────────────────────────────────────────────
var _built: bool = false
## ONLY the nodes this script made. Teardown walks this and never get_children(): the
## grid adds label plates, packaging and tag markers to the same parent.
var _owned: Array[Node] = []
## Node-name counter, reset at the top of every build.
var _seq: int = 0

var _unit: float = 1.0
var _kerf_width: float = 0.0
var _section: float = 0.0

var _mat_block: StandardMaterial3D = null
var _mat_mark: StandardMaterial3D = null
var _mat_apparatus: StandardMaterial3D = null
var _mat_void: StandardMaterial3D = null


# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_grid_config_meta()
	_check_family_words()
	_resolve_gauge()
	_make_materials()
	_build()                   # SYNCHRONOUS - children exist when _ready returns
	_built = true


## Called by GridInteractablesComponent (deferred, ahead of framing and auto-grounding)
## and by curation_station, which passes {"emissive": false} one line after re-framing
## labels. That dict names no axis, so it MUST NOT rebuild - a rebuild there throws away
## framing that is never re-applied. This is the force_pad fault and it is guarded here.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_kerf: String = kerf
	var before_reck: String = reckoning
	if config_data.has("kerf"):
		kerf = _pick(str(config_data["kerf"]), KERFS, kerf)
	if config_data.has("reckoning"):
		reckoning = _pick(str(config_data["reckoning"]), RECKONINGS, reckoning)
	if not _built:
		return
	if kerf == before_kerf and reckoning == before_reck:
		return
	_rebuild_now()
	print("[GrainBlock] kerf=%s reckoning=%s" % [kerf, reckoning])


## The grid stamps config_<key> metadata on the artifact ROOT before _ready; a wrapper
## may hold it one or two levels up. Walk a short way and stop.
func _read_grid_config_meta() -> void:
	var n: Node = self
	var hops: int = 0
	while n != null and hops < 4:
		if n.has_meta("config_kerf"):
			kerf = _pick(str(n.get_meta("config_kerf")), KERFS, kerf)
		if n.has_meta("config_reckoning"):
			reckoning = _pick(str(n.get_meta("config_reckoning")), RECKONINGS, reckoning)
		n = n.get_parent()
		hops += 1


## Accept a value only if it names something this bench actually builds. An unrecognised
## word is a typo in a map token and must keep the standing value rather than empty the
## bench.
func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## BOTH DIRECTIONS. A word the family declares that this bench has no bay for, and a bay
## this bench can build that the family has dropped, are both errors and both are said.
func _check_family_words() -> void:
	var fam: PackedStringArray = FAM.GRAINS
	for w in fam:
		if not BUILDABLE.has(w):
			push_error("[grain_block] cube_scene.gd declares grain '%s' and this bench has no bay for it" % w)
	for mine in BUILDABLE:
		if not fam.has(mine):
			push_error("[grain_block] this bench builds a '%s' bay that cube_scene.gd no longer declares" % mine)


## The gauge is the family's OWN number wherever the family's number is legible, and this
## bench's floor only where it is not. Today FAM's widest gap is 0.04 against a floor of
## 0.11, so the bench widens - and if cube_scene ever opens past 0.11 the bench follows it
## instead of overruling it. maxf is a call, so this cannot live in a const.
func _resolve_gauge() -> void:
	_unit = FAM.UNIT
	var family_gap: float = maxf(FAM.SPLIT_GAP, maxf(FAM.QUARTER_GAP, FAM.LATTICE_GAP))
	_kerf_width = maxf(KERF_FLOOR, family_gap)
	_section = maxf(SECTION_FLOOR, FAM.SHELL_SECTION)


func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)     # leaves the tree in THIS frame
			c.queue_free()
	_owned.clear()
	_build()


# ═══════════════════════════════════════════════════════════════════════════════
# ONE COPY OF THE ARITHMETIC
# ═══════════════════════════════════════════════════════════════════════════════

## Cells per axis for a divided grain, straight off cube_scene's builders: _build_split
## parts the horizontal mid-plane only, _build_quartered is 2x2x2, _build_lattice is
## 3x3x3. `shell` is not a count and never reaches here.
func _cells(grain: String) -> Vector3i:
	match grain:
		"split":
			return Vector3i(1, 2, 1)
		"quartered":
			return Vector3i(2, 2, 2)
		"lattice":
			return Vector3i(3, 3, 3)
		_:
			return Vector3i(1, 1, 1)


## THE one function. Cell intervals along one axis and that axis's extent, for n cells
## and n-1 interior cuts. Everything reads it: the cells, the scribes, the ghosts, the
## envelope, the material fraction, the register fill and therefore the capture AABB.
##
##   shut / drawn  cells are UNIT/n and touch; nothing is removed.  extent UNIT
##   inward        the kerf comes out of the cells.                 extent UNIT
##   outward       the kerf goes in between them.                   extent UNIT+(n-1)K
##
## Returns [Array of Vector2 intervals, extent].
func _spans(n: int, mode: String) -> Array:
	var out: Array[Vector2] = []
	if n <= 1:
		out.append(Vector2(-_unit * 0.5, _unit * 0.5))
		return [out, _unit]
	var cell: float = _unit / float(n)
	var gap: float = 0.0
	if mode == "inward":
		cell = (_unit - float(n - 1) * _kerf_width) / float(n)
		gap = _kerf_width
	elif mode == "outward":
		gap = _kerf_width
	var ext: float = float(n) * cell + float(n - 1) * gap
	for i in range(n):
		var a: float = -ext * 0.5 + float(i) * (cell + gap)
		out.append(Vector2(a, a + cell))
	return [out, ext]


## The bay's outer box at the current kerf. `shell` is the boundary of the unit and never
## moves; every other grain reads _spans.
func _envelope(grain: String) -> Vector3:
	if grain == "shell":
		return Vector3(_unit, _unit, _unit)
	var c: Vector3i = _cells(grain)
	return Vector3(
		float(_spans(c.x, kerf)[1]),
		float(_spans(c.y, kerf)[1]),
		float(_spans(c.z, kerf)[1]))


## Volume of matter still standing, in units of the whole 1 m block. For a divided grain
## it is the product of the three axes' linear fill; for the shell it is the union of the
## twelve struts, which is exactly the set of points with at least two coordinates inside
## the boundary band: 3p^2(1-p) + p^3 for a band fraction p.
func _material_fraction(grain: String) -> float:
	if grain == "shell":
		var p: float = 2.0 * _section / _unit
		return 3.0 * p * p * (1.0 - p) + p * p * p
	var c: Vector3i = _cells(grain)
	var v: float = 1.0
	for n in [c.x, c.y, c.z]:
		var got: Array = _spans(int(n), kerf)
		var filled: float = 0.0
		for raw in got[0]:
			var iv: Vector2 = raw
			filled += iv.y - iv.x
		v *= filled / _unit
	return v


# ═══════════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════════

func _build() -> void:
	_seq = 0
	var words: PackedStringArray = FAM.GRAINS
	var n: int = words.size()
	for i in range(n):
		var g: String = words[i]
		if not BUILDABLE.has(g):
			continue
		var bay_x: float = (float(i) - float(n - 1) * 0.5) * BAY_PITCH
		_build_bay(g, bay_x)


func _build_bay(grain: String, bay_x: float) -> void:
	var env: Vector3 = _envelope(grain)
	# Every bay's underside sits on y = 0, so the grid's base-to-floor grounding is a
	# no-op and no auto_ground opt-out is needed.
	var origin: Vector3 = Vector3(bay_x, env.y * 0.5, 0.0)

	var pieces: int = 0
	if grain == "shell":
		pieces = _build_shell(origin)
	else:
		pieces = _build_cells(grain, origin)
		if kerf == "drawn":
			_build_scribes(grain, origin)

	match reckoning:
		"void":
			_build_void(grain, origin)
		"mass":
			_build_mass(grain, bay_x)
		"count":
			# COUNT THE THING YOU CLAIM TO COUNT: the register is handed the number of
			# meshes the block actually put in the tree, not a number computed beside it.
			_build_count(pieces, bay_x)


## Every divided grain. Returns how many pieces were made.
func _build_cells(grain: String, origin: Vector3) -> int:
	var c: Vector3i = _cells(grain)
	var ix: Array = _spans(c.x, kerf)[0]
	var iy: Array = _spans(c.y, kerf)[0]
	var iz: Array = _spans(c.z, kerf)[0]
	var made: int = 0
	for a in ix:
		for b in iy:
			for d in iz:
				var va: Vector2 = a
				var vb: Vector2 = b
				var vd: Vector2 = d
				_add_box("Cell%d" % made,
					Vector3(va.y - va.x, vb.y - vb.x, vd.y - vd.x),
					origin + Vector3((va.x + va.y) * 0.5, (vb.x + vb.y) * 0.5, (vd.x + vd.y) * 0.5),
					_mat_block)
				made += 1
	return made


## cube_scene's shell exactly: twelve FULL-LENGTH struts of square section, centre-line
## at UNIT/2 - S/2 so each outer face lands on +-0.5. They overlap at the corners, which
## is what closes the cage, and there are exactly twelve boxes - so `count` counts twelve.
##
## `kerf` does not reach here, and that is the point: a boundary is not a cut, so there is
## no kerf to take from anywhere. See dna.still_note.
func _build_shell(origin: Vector3) -> int:
	var h: float = _unit * 0.5
	var e: float = h - _section * 0.5
	var made: int = 0
	for axis in range(3):
		for a1 in [-e, e]:
			for a2 in [-e, e]:
				var s1: float = a1
				var s2: float = a2
				var size: Vector3 = Vector3(_section, _section, _section)
				var pos: Vector3 = Vector3.ZERO
				match axis:
					0:
						size.x = _unit
						pos.y = s1
						pos.z = s2
					1:
						size.y = _unit
						pos.z = s1
						pos.x = s2
					_:
						size.z = _unit
						pos.x = s1
						pos.y = s2
				_add_box("Strut%d" % made, size, origin + pos, _mat_block)
				made += 1
	return made


## kerf=drawn. The cut is not taken; it is DEPICTED - a band of exactly the kerf width,
## laid on every outer face the cut plane meets and standing DRAW_PROUD off it.
##
## The UNDERSIDE is not marked. A scribe is a line drawn by someone about to cut, on a
## face they can see; it also keeps the lowest geometry at y = 0 at every value of the
## axis, so the artifact's base does not move by 2 mm between tiles.
func _build_scribes(grain: String, origin: Vector3) -> void:
	var c: Vector3i = _cells(grain)
	var counts: Array[int] = [c.x, c.y, c.z]
	var h: float = _unit * 0.5
	var made: int = 0
	for axis in range(3):
		if counts[axis] <= 1:
			continue
		var step: float = _unit / float(counts[axis])
		for k in range(1, counts[axis]):
			var plane: float = -h + float(k) * step
			for face in range(3):
				if face == axis:
					continue
				for sgn in [-1.0, 1.0]:
					var s: float = sgn
					if face == 1 and s < 0.0:
						continue
					var third: int = 3 - axis - face
					var size: Array[float] = [0.0, 0.0, 0.0]
					var pos: Array[float] = [0.0, 0.0, 0.0]
					size[axis] = _kerf_width
					pos[axis] = plane
					size[face] = DRAW_PROUD
					pos[face] = s * (h + DRAW_PROUD * 0.5)
					size[third] = _unit
					pos[third] = 0.0
					_add_box("Scribe%d" % made,
						Vector3(size[0], size[1], size[2]),
						origin + Vector3(pos[0], pos[1], pos[2]),
						_mat_mark)
					made += 1


# ═══════════════════════════════════════════════════════════════════════════════
# THE RECKONINGS - what the division is reckoned against
# ═══════════════════════════════════════════════════════════════════════════════

## reckoning=void. What the division took out, put back translucent, IN PLACE.
##
## Disjoint by construction, so no two ghosts stack on one another and no ghost stands in
## front of a piece it comments on: the complement of a product grid is
## (gapX x all x all) + (cellX x gapY x all) + (cellX x cellY x gapZ), and the complement
## of the twelve struts is the set of points with AT MOST ONE coordinate in the boundary
## band - a core box plus six face slabs.
func _build_void(grain: String, origin: Vector3) -> void:
	var made: int = 0
	if grain == "shell":
		var h: float = _unit * 0.5
		var core: Vector2 = Vector2(-h + _section, h - _section)
		var bands: Array[Vector2] = [Vector2(-h, -h + _section), Vector2(h - _section, h)]
		_add_ghost("Void%d" % made, core, core, core, origin)
		made += 1
		for axis in range(3):
			for raw in bands:
				var band: Vector2 = raw
				var slab: Array[Vector2] = [core, core, core]
				slab[axis] = band
				_add_ghost("Void%d" % made, slab[0], slab[1], slab[2], origin)
				made += 1
		return

	var c: Vector3i = _cells(grain)
	var cells: Array = []
	var gaps: Array = []
	var full: Array[Vector2] = []
	for n in [c.x, c.y, c.z]:
		var got: Array = _spans(int(n), kerf)
		var iv: Array = got[0]
		var ext: float = got[1]
		cells.append(iv)
		full.append(Vector2(-ext * 0.5, ext * 0.5))
		var g: Array[Vector2] = []
		for i in range(iv.size() - 1):
			var a: Vector2 = iv[i]
			var b: Vector2 = iv[i + 1]
			if b.x - a.y > 0.000001:
				g.append(Vector2(a.y, b.x))
		gaps.append(g)

	for gx in gaps[0]:
		_add_ghost("Void%d" % made, gx, full[1], full[2], origin)
		made += 1
	for cx in cells[0]:
		for gy in gaps[1]:
			_add_ghost("Void%d" % made, cx, gy, full[2], origin)
			made += 1
	for cx2 in cells[0]:
		for cy in cells[1]:
			for gz in gaps[2]:
				_add_ghost("Void%d" % made, cx2, cy, gz, origin)
				made += 1


## reckoning=mass. The register filled with MATTER.
##
## THE CEILING IS THE WHOLE REGISTER AT EVERY VALUE OF EVERY AXIS - one whole 1 m block
## of material - so nothing here is normalised to the frame or to the row. The dark part
## is what a whole unit would have been; the bright part is what still stands.
func _build_mass(grain: String, bay_x: float) -> void:
	var f: float = clampf(_material_fraction(grain), 0.0, 1.0)
	var w: float = _reg_width()
	var hgt: float = _reg_height()
	var bright: float = hgt * f
	if bright > 0.000001:
		_add_box("MassFill", Vector3(w, bright, REG_DEPTH),
			Vector3(bay_x, REG_Y + bright * 0.5, 0.0), _mat_block)
	var dark: float = hgt - bright
	if dark > 0.000001:
		_add_box("MassCeiling", Vector3(w, dark, REG_DEPTH),
			Vector3(bay_x, REG_Y + bright + dark * 0.5, 0.0), _mat_apparatus)


## reckoning=count. The SAME register filled with PIECES, one cell each, row-major from
## the bottom left. Capacity REG_COLS x REG_ROWS = 28 against the family's largest count
## of 27, which is a constant of the vocabulary and not of the frame.
func _build_count(pieces: int, bay_x: float) -> void:
	var cap: int = REG_COLS * REG_ROWS
	var n: int = pieces
	if n > cap:
		push_warning("[grain_block] register holds %d and the block is in %d pieces" % [cap, n])
		n = cap
	var pitch: float = REG_CELL + REG_GAP
	for i in range(n):
		var col: int = i % REG_COLS
		var row: int = int(float(i - col) / float(REG_COLS))
		_add_box("Piece%d" % i, Vector3(REG_CELL, REG_CELL, REG_DEPTH),
			Vector3(bay_x + (float(col) - float(REG_COLS - 1) * 0.5) * pitch,
				REG_Y + REG_CELL * 0.5 + float(row) * pitch, 0.0), _mat_block)


func _reg_width() -> float:
	return float(REG_COLS) * REG_CELL + float(REG_COLS - 1) * REG_GAP


func _reg_height() -> float:
	return float(REG_ROWS) * REG_CELL + float(REG_ROWS - 1) * REG_GAP


# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

## Every mesh in the file goes through here, so everything lands in _owned and every
## sibling gets a unique name - five bays each numbering their own pieces from zero would
## otherwise leave Godot to disambiguate them.
func _add_box(part: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "%s_%d" % [part, _seq]
	_seq += 1
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	_owned.append(mi)
	return mi


func _add_ghost(part: String, ix: Vector2, iy: Vector2, iz: Vector2, origin: Vector3) -> void:
	var size: Vector3 = Vector3(ix.y - ix.x, iy.y - iy.x, iz.y - iz.x)
	if size.x <= 0.000001 or size.y <= 0.000001 or size.z <= 0.000001:
		return
	var pos: Vector3 = origin + Vector3((ix.x + ix.y) * 0.5, (iy.x + iy.y) * 0.5, (iz.x + iz.y) * 0.5)
	var mi: MeshInstance3D = _add_box(part, size, pos, _mat_void)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _make_materials() -> void:
	_mat_block = StandardMaterial3D.new()
	_mat_block.albedo_color = C_BLOCK
	_mat_block.roughness = 0.55
	_mat_block.metallic = 0.0

	_mat_mark = StandardMaterial3D.new()
	_mat_mark.albedo_color = C_MARK
	_mat_mark.roughness = 0.35
	_mat_mark.metallic = 0.0

	_mat_apparatus = StandardMaterial3D.new()
	_mat_apparatus.albedo_color = C_APPARATUS
	_mat_apparatus.roughness = 0.85
	_mat_apparatus.metallic = 0.0

	_mat_void = StandardMaterial3D.new()
	_mat_void.albedo_color = Color(C_VOID.r, C_VOID.g, C_VOID.b, VOID_ALPHA)
	_mat_void.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_void.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_void.cull_mode = BaseMaterial3D.CULL_BACK
