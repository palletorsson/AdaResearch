extends Node3D
class_name FactureBench

## Facture Bench — a SYNTHESIS artifact for the `facture` family. One body, restated
## along a deck in every state of making the family can be said to SHARE, with the
## row emptying as the requirement to share gets stricter.
##
## @identity
## essence: one lathed capsule — the body the word `facture` was coined on — standing
##   up to five times on a single deck, each copy in a different state of its own
##   making: poured, wired, cut into countable planes, opened, and given a wall. The
##   form, the size, the pad and the deck are identical at every station; the only
##   thing that differs is how much of its construction the copy admits.
## desire: to be walked along until the visitor notices that the leftmost body — the
##   one every member of the family agrees about — is the one that admits nothing.
## critical_parameter: `quorum` — how many of the family's five members must declare a
##   term before this bench will stand it. At two, five bodies; at five, one. The
##   vocabulary empties from the right and what is left standing is `cast`.
## triggers: none. Nothing animates, nothing is grabbable, nothing is random, no
##   physics, no _process, no timer. Five source files read once at build time.
## emerges: the word every member shares is the word that requires no implementation.
##   `cast` is the untouched scene in capsule and dome and is one early `return` in
##   both; `section` needs a body with an inside and `shell` needs a body without one,
##   so no member can carry both, and the pool splits exactly along that line.
## needs: the five members' own FACTURES consts, read and not retyped [has]; sphere_mid's
##   own RESOLUTION ladder for the second axis [has]; capsule's WIRE_RADIUS and
##   FALLBACK_ALBEDO [has]; every mark gauged against this bench's own px-per-metre
##   rather than inherited from bodies ten times its size [has]
## relationships: synthesis over the five registry names that declare `facture` —
##   capsule, dome, folded_strip, platonic_grabbables, triangleprofiles. It re-runs
##   none of their axes and replaces none of them. Its second axis is borrowed whole
##   from [[sphere_mid]], the primitives tier's own word for how finely a body is cut.
## truth: facture is not a property an object has. It is a relation between how a thing
##   was made and how closely you are standing — at thirty-two sides, the cut body and
##   the poured body are the same photograph.


# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD, READ AND NOT RETYPED — AND EXHIBITED, NOT SWEPT
# ═══════════════════════════════════════════════════════════════════════════
#
# `facture` is REFUSED as this artifact's varying axis, on the record, and the refusal
# is the design. There is no list to vary: five members declare the word with FOUR
# different vocabularies and the only term all five share is `cast`.
#
#     capsule               cast · facet · armature · section · wear
#     dome                  cast · blank · core · section
#     folded_strip          facet · cast · armature · shell
#     platonic_grabbables   plate · cast · armature
#     triangleprofiles      facet · cast · armature · shell
#
# That is the shape doc/reports/VOCABULARY_SPLIT.md ruled on for `support`: a POOL, not
# a disagreement — each object declaring the states of making it can honestly take. The
# cost, stated there and paid here, is that the word cannot be swept across its family.
#
# WHICH CASE THE FAMILY IS IN — MIXED, read out of the members' CODE and not their prose.
#
#   * A SUBTRACTION. capsule.gd::_armature() walks the edges of the SAME triangle list
#     _facet() shades and draws no faces at all, so every mark it makes is a mark facet
#     already carried and none of facet's skin survives. folded_strip.gd and
#     triangleprofiles.gd do the same. `armature` is `facet` with the skin removed, and
#     `cast` is `facet` with the partition removed: the two are complements inside the
#     third, which is why `facet` is the only value that draws both skin and count.
#   * PARALLEL APPARATUS. `shell` (folded_strip.gd::_prism) extrudes each face into a
#     slab with darker rims; `section` (capsule.gd::_section, dome.gd's SectionCut) cuts
#     the body and fills the cut face. Neither contains the other and neither is on the
#     skin/partition ladder at all.
#
# So the values do NOT nest, and under Law 2 the simultaneity is the object: all of them
# stand at once and something else varies. What varies is HOW MANY MEMBERS HAVE TO AGREE
# before a term is allowed on the deck — which is the pool measured rather than described.
#
# WHY THE FLOOR IS TWO AND NOT ONE. `wear`, `blank`, `core` and `plate` are declared by
# exactly one member each. A term one object uses is that object's own word, not a shared
# vocabulary, and standing it here would be this bench asserting a commons that does not
# exist. quorum runs over every threshold at which sharing is even defined.

const CAPSULE := preload("res://commons/primitives/capsule/capsule.gd")
const DOME := preload("res://commons/primitives/booleans/dome.gd")
const PLATONIC := preload("res://commons/primitives/platonic_grabbables.gd")

## sphere_mid owns the second axis outright — same tier, same question, its own const.
const SPHERE_MID := preload("res://commons/primitives/godotmeshes/sphere_mid.gd")

## THE TWO MEMBERS THAT ARE READ AS TEXT, AND WHY — this is a decision, not a shortcut.
## folded_strip.gd and triangleprofiles.gd both declare `var drag_points: DragPointSet`.
## DragPointSet is a global class whose own `const DEFAULT_POINT_SCENE` preloads
## grab_sphere_point_with_text.tscn, which ext-resources
## res://addons/godot-xr-tools/objects/pickable.tscn. `/addons/*` is gitignored — the
## repo does not track godot-xr-tools — so preloading either member would put a bench
## that needs no XR at all downstream of code that is not in the repository. This corpus
## has already lost one promotion to logic living inside a gitignored addon. Their
## FACTURES consts are therefore read out of the SOURCE FILE at build time: still
## derived from the code and still fails loudly if the const is renamed, without
## dragging an untracked dependency into the parse chain.
const STRIP_SRC := "res://commons/primitives/folded_strip/folded_strip.gd"
const PROFILES_SRC := "res://commons/primitives/triangleprofiles/triangleprofiles.gd"

const MEMBER_COUNT := 5


# ═══════════════════════════════════════════════════════════════════════════
# THE AXES
# ═══════════════════════════════════════════════════════════════════════════

## AXIS 1 — HOW MANY OF THE FIVE MEMBERS MUST DECLARE A TERM BEFORE IT MAY STAND.
## The deck, the five pads, the body, its size and its position never change. What
## changes is how much of the family's vocabulary is allowed onto the deck.
##
##   two    cast · armature · facet · section · shell — every term more than one member
##          uses. Five bodies. This is the pool as the corpus actually holds it, and it
##          is the widest honest reading of "shared".
##   three  cast · armature · facet. Three bodies; `section` and `shell` go dark,
##          because a solid can be cut open and a sheet can be given a wall and no
##          member's subject is both.
##   four   cast · armature. Two bodies. What is left is a skin and the frame under it.
##   all    cast. One body on a deck of five pads. The only term the whole family
##          agrees about is the one that admits nothing about how the thing was made.
##
## The ladder NESTS strictly — each value's set is a subset of the one before it, by
## construction, since raising a frequency threshold can only remove terms. It is
## therefore declared in its own order and must be swept in it.
@export_enum("two", "three", "four", "all") var quorum: String = "two"

## AXIS 2 — HOW FINELY THE BODY IS CUT. The word and its four values are sphere_mid's,
## character for character, and the four segment counts behind them are read from
## sphere_mid.RESOLUTION at build time rather than retyped: coarse 4, mid 7, fine 16,
## ultra 32. sphere_high asks the identical question under the name `tessellation` with
## the identical numbers and a different value list; `resolution` is taken because four
## tokens declare it against that one.
##
## This is the axis that decides whether the making can be hidden at all. At coarse a
## facet is 49 px wide and every station announces its own construction; at ultra it is
## 6 px and the cut body, the plated body and the poured body converge on one another.
@export_enum("coarse", "mid", "fine", "ultra") var resolution: String = "mid"


# ═══════════════════════════════════════════════════════════════════════════
# THE BODY, THE DECK, AND EVERY MARK GAUGED TO THIS INSTRUMENT
# ═══════════════════════════════════════════════════════════════════════════
#
# THE FAMILY'S OWN MARK NUMBERS DO NOT SURVIVE THIS OBJECT and were re-gauged rather
# than transcribed. folded_strip ships SHELL_THICKNESS 0.06 against a 4 m strip (1.5%)
# and triangleprofiles 0.05 against a 5 m wall (1%). Scaled by the same fraction onto a
# 0.31 m body that is 0.0047 m, which is 1.5 px at this bench's framing — an axis drawn
# at one and a half pixels measures the same as an axis that does nothing.
#
# ONE NUMBER SURVIVED INTACT AND IS TAKEN WHOLE. capsule.gd::WIRE_RADIUS is 0.008 m,
# authored for a 0.25 m-radius capsule. At dna.framing 0.62 this bench renders 313.99 px
# per metre, so a three-sided tube of that radius is 0.016 m across = 5.02 px. That is
# exactly the legibility floor, so the constant is read from capsule and used unchanged,
# and MARK — the thinnest thing this bench is allowed to draw — is defined as its
# diameter and then used TWICE, for the wire and for the shell wall. One number, one
# arithmetic, two readers.
const BODY_R := 0.10
const BODY_H := 0.11                     ## the straight middle; total height 2R + H = 0.31
const SLOT_PITCH := 0.40
const SLOTS := 5
const DECK_MARGIN := 0.19
const DECK_T := 0.05
const DECK_D := 0.40
const PAD_T := 0.008
const PAD_R := 0.115
const PAD_SEGMENTS := 24

## Transcribed from the members, with the citation, because they are literals in a
## function body rather than consts and cannot be read off the class.
const TONE_DARK := 0.72                  ## capsule.gd::_facet
const CUT_LIGHTEN := 0.42                ## capsule.gd::_section
const WIRE_LIGHTEN := 0.35               ## capsule.gd::_armature
const RIM_DARKEN := 0.42                 ## folded_strip.gd::_prism

var _pool: PackedStringArray = PackedStringArray()
var _freq: Dictionary = {}
var _lists: Dictionary = {}
var _built: bool = false
var _base: Color = Color(0.5176471, 0.5254902, 0.47843137, 1.0)
var _mark: float = 0.016


func _ready() -> void:
	_read_dna_meta()
	_read_family()
	_check_family_pool()
	_build()


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the build.
## An unknown word keeps the default; no metadata, no change.
func _read_dna_meta() -> void:
	if has_meta("config_quorum"):
		var q: String = str(get_meta("config_quorum")).strip_edges().to_lower()
		if QUORUM_LEVELS.has(q):
			quorum = q
	if has_meta("config_resolution"):
		var r: String = str(get_meta("config_resolution")).strip_edges().to_lower()
		if SPHERE_MID.RESOLUTION.has(r):
			resolution = r


## Guarded: rebuild only when a value this artifact owns actually CHANGED, and only
## after _ready has built once. force_pad tore down every child on any call at all.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("quorum"):
		var q: String = str(config_data["quorum"]).strip_edges().to_lower()
		if QUORUM_LEVELS.has(q) and q != quorum:
			quorum = q
			dirty = true
	if config_data.has("resolution"):
		var r: String = str(config_data["resolution"]).strip_edges().to_lower()
		if SPHERE_MID.RESOLUTION.has(r) and r != resolution:
			resolution = r
			dirty = true
	if dirty and _built:
		_build()


# ═══════════════════════════════════════════════════════════════════════════
# THE POOL, COMPUTED FROM THE FAMILY RATHER THAN DESCRIBED
# ═══════════════════════════════════════════════════════════════════════════

## Threshold per value name. The keys are this bench's own words (a count of members is
## not a state of making) but the NUMBERS are checked against MEMBER_COUNT below, so a
## sixth member joining the family makes `all` mean six without anything being retyped.
const QUORUM_LEVELS := {"two": 2, "three": 3, "four": 4, "all": MEMBER_COUNT}


func _read_family() -> void:
	_lists = {
		"capsule": _as_strings(CAPSULE.FACTURES),
		"dome": _as_strings(DOME.FACTURES),
		"folded_strip": _factures_from_source(STRIP_SRC),
		"platonic_grabbables": _as_strings(PLATONIC.FACTURES),
		"triangleprofiles": _factures_from_source(PROFILES_SRC),
	}
	# Scan order is the token order above and it is load-bearing: it breaks the frequency
	# tie between `section` (2, first seen in capsule) and `shell` (2, first seen in
	# folded_strip), and therefore fixes which pad each term stands on.
	var order: Array = ["capsule", "dome", "folded_strip", "platonic_grabbables",
		"triangleprofiles"]
	_freq = {}
	var first: Dictionary = {}
	for i in range(order.size()):
		var vals: PackedStringArray = _lists[order[i]]
		for v in vals:
			_freq[v] = int(_freq.get(v, 0)) + 1
			if not first.has(v):
				first[v] = i
	# Sorted as [-frequency, first-seen index, term] so a plain Array.sort() — which
	# compares nested arrays element by element — gives frequency descending, then scan
	# order, then alphabetical. No lambda: a multi-line sort_custom closure over two
	# locals is the kind of thing that parses differently than it reads.
	var keyed: Array = []
	for v in _freq.keys():
		keyed.append([-int(_freq[v]), int(first[v]), str(v)])
	keyed.sort()
	_pool = PackedStringArray()
	for row in keyed:
		_pool.append(str(row[2]))


func _as_strings(v) -> PackedStringArray:
	var out := PackedStringArray()
	for s in v:
		out.append(str(s))
	return out


## Read one member's FACTURES const straight out of its source file. Fails loudly and
## specifically; it does not fall back to a copy, because a silent fallback is exactly
## the drift this whole mechanism exists to prevent.
func _factures_from_source(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("facture_bench: cannot open " + path)
		return out
	var src: String = f.get_as_text()
	f.close()
	var re := RegEx.new()
	re.compile("const\\s+FACTURES\\s*:\\s*PackedStringArray\\s*=\\s*\\[([^\\]]*)\\]")
	var m: RegExMatch = re.search(src)
	if m == null:
		push_error("facture_bench: no `const FACTURES` in " + path)
		return out
	var q := RegEx.new()
	q.compile("\"([a-z_]+)\"")
	for hit in q.search_all(m.get_string(1)):
		out.append(hit.get_string(1))
	return out


## Both directions, as Law 1 requires, plus the two places this bench could quietly go
## out of step with the tier it borrows from.
func _check_family_pool() -> void:
	if _lists.size() != MEMBER_COUNT:
		push_error("facture_bench: MEMBER_COUNT says %d, %d member lists read"
			% [MEMBER_COUNT, _lists.size()])
	for tok in _lists.keys():
		var lst: PackedStringArray = _lists[tok]
		if lst.is_empty():
			push_error("facture_bench: member %s declared no factures" % str(tok))
	# A term this bench can draw that no member declares would be an invented word.
	for term in DRAWN:
		if not _freq.has(term):
			push_error("facture_bench: draws `%s`, which no member of the family declares"
				% term)
	# A shared term this bench cannot draw would be a silent hole in the exhibit.
	for term in _pool:
		if int(_freq[term]) >= 2 and not DRAWN.has(term):
			push_error("facture_bench: `%s` is declared by %d members and has no station"
				% [term, int(_freq[term])])
	# The borrowed axis, checked against its owner in both directions.
	for r in ["coarse", "mid", "fine", "ultra"]:
		if not SPHERE_MID.RESOLUTION.has(r):
			push_error("facture_bench: sphere_mid.RESOLUTION has no `%s`" % r)
	for r in SPHERE_MID.RESOLUTION.keys():
		if not ["coarse", "mid", "fine", "ultra"].has(str(r)):
			push_error("facture_bench: sphere_mid.RESOLUTION declares `%s`, which is not in the @export_enum hint on `resolution`" % str(r))


## Every state of making this bench knows how to draw. Not a vocabulary — a capability
## list, checked against the family in both directions above.
const DRAWN := ["cast", "facet", "armature", "section", "shell"]


func standing() -> PackedStringArray:
	var need: int = int(QUORUM_LEVELS.get(quorum, 2))
	var out := PackedStringArray()
	for t in _pool:
		if int(_freq.get(t, 0)) >= need:
			out.append(t)
	return out


# ═══════════════════════════════════════════════════════════════════════════
# THE BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	_base = Color(CAPSULE.FALLBACK_ALBEDO.r, CAPSULE.FALLBACK_ALBEDO.g,
		CAPSULE.FALLBACK_ALBEDO.b, 1.0)
	_mark = CAPSULE.WIRE_RADIUS * 2.0

	var deck_l: float = float(SLOTS - 1) * SLOT_PITCH + 2.0 * DECK_MARGIN
	var deck_col: Color = _base.darkened(0.55)
	var pad_col: Color = _base.darkened(0.32)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(st, Vector3(-deck_l * 0.5, 0.0, -DECK_D * 0.5),
		Vector3(deck_l * 0.5, DECK_T, DECK_D * 0.5), deck_col)
	var x0: float = -float(SLOTS - 1) * SLOT_PITCH * 0.5
	for i in range(SLOTS):
		_disc(st, Vector3(x0 + float(i) * SLOT_PITCH, DECK_T, 0.0), PAD_R, PAD_T, pad_col)
	var deck := MeshInstance3D.new()
	deck.name = "Deck"
	deck.mesh = st.commit()
	deck.material_override = _vertex_mat(false)
	add_child(deck)

	var n: int = int(SPHERE_MID.RESOLUTION.get(resolution, 7))
	var terms: PackedStringArray = standing()
	var body_y: float = DECK_T + PAD_T
	for i in range(terms.size()):
		var mi: MeshInstance3D = _station(terms[i], n,
			Vector3(x0 + float(i) * SLOT_PITCH, body_y, 0.0))
		if mi != null:
			mi.name = "Station%d_%s" % [i, terms[i]]
			add_child(mi)
	_built = true


func _station(facture: String, n: int, origin: Vector3) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var unshaded: bool = false
	match facture:
		"cast":
			_cast(st, n, origin)
		"facet":
			_facet(st, n, origin)
		"armature":
			_armature(st, n, origin)
			unshaded = true
		"section":
			_section(st, n, origin)
		"shell":
			_shell(st, n, origin)
		_:
			return null
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _vertex_mat(unshaded)
	return mi


# ── the lathe ────────────────────────────────────────────────────────────────
# ONE COPY OF THE ARITHMETIC. The profile is walked at equal ARC LENGTH — not equal
# height and not equal angle — so a row is the same length of skin wherever it lands and
# the facets stay square-ish through the shoulder, where a by-height walk would stack
# every row into the cap. Every station below reads this same grid; none of them
# recomputes it and none of them moves a vertex.

func _profile(n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var arc: float = PI * BODY_R * 0.5
	var total: float = PI * BODY_R + BODY_H
	for k in range(n + 1):
		var s: float = total * float(k) / float(n)
		if s <= arc:
			var phi: float = s / BODY_R
			out.append(Vector2(BODY_R * sin(phi), BODY_R - BODY_R * cos(phi)))
		elif s <= arc + BODY_H:
			out.append(Vector2(BODY_R, BODY_R + (s - arc)))
		else:
			var psi: float = (s - arc - BODY_H) / BODY_R
			out.append(Vector2(BODY_R * cos(psi), BODY_R + BODY_H + BODY_R * sin(psi)))
	return out


func _grid(n: int, origin: Vector3) -> Array:
	var prof: PackedVector2Array = _profile(n)
	var rows: Array = []
	for k in range(prof.size()):
		var row: PackedVector3Array = PackedVector3Array()
		for j in range(n):
			var th: float = TAU * float(j) / float(n)
			row.append(Vector3(origin.x + prof[k].x * cos(th), origin.y + prof[k].y,
				origin.z + prof[k].x * sin(th)))
		rows.append(row)
	return rows


## The analytic outward normal at a point of the capsule surface. Analytic rather than
## averaged: an averaged normal at the shoulder splits the difference between a cap and
## a cylinder and puts a crease exactly where `cast` is claiming there is none.
func _surface_normal(p: Vector3, origin: Vector3) -> Vector3:
	var local: Vector3 = p - origin
	if local.y < BODY_R:
		return (local - Vector3(0.0, BODY_R, 0.0)).normalized()
	if local.y > BODY_R + BODY_H:
		return (local - Vector3(0.0, BODY_R + BODY_H, 0.0)).normalized()
	var flat := Vector3(local.x, 0.0, local.z)
	if flat.length_squared() < 0.000001:
		return Vector3.UP
	return flat.normalized()


# ── the five states of making ────────────────────────────────────────────────

## POURED. One skin, normals taken from the surface itself, no seam and no count. Every
## other station is this body with something admitted.
func _cast(st: SurfaceTool, n: int, origin: Vector3) -> void:
	var rows: Array = _grid(n, origin)
	for k in range(n):
		for j in range(n):
			var j2: int = (j + 1) % n
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][j2]
			var c: Vector3 = rows[k + 1][j2]
			var d: Vector3 = rows[k + 1][j]
			_smooth_tri(st, a, d, c, origin, _base)
			_smooth_tri(st, a, c, b, origin, _base)


## COUNTED. The same triangles, each one flat, and every other QUAD a shade darker so
## that the radial segments and the rings both become things you can point at.
##
## THE CHECKER IS BY QUAD AND capsule's IS BY TRIANGLE, which is a deliberate departure
## with a reason. capsule.gd::_facet tones on `face % 2` over the triangle sequence; on a
## strip-ordered lathe that darkens half of each quad rather than the quad, so what it
## draws is a zigzag inside every cell and not the bands its own doc block promises
## ("the five segments and five rings become things you can point at"). At n = 32 that
## zigzag is 3 px of alternating tone and reads as noise. The tone 0.72 is capsule's own.
func _facet(st: SurfaceTool, n: int, origin: Vector3) -> void:
	var rows: Array = _grid(n, origin)
	for k in range(n):
		for j in range(n):
			var j2: int = (j + 1) % n
			var tone: float = TONE_DARK if ((k + j) % 2 == 0) else 1.0
			var col := Color(_base.r * tone, _base.g * tone, _base.b * tone, 1.0)
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][j2]
			var c: Vector3 = rows[k + 1][j2]
			var d: Vector3 = rows[k + 1][j]
			_tri(st, a, d, c, col)
			_tri(st, a, c, b, col)


## WIRED. Every edge of the same tessellation once, as a three-sided tube. The skin is
## not hidden — it is not built, so there is no VisualInstance3D left holding a subtree.
## Tubes and not PRIMITIVE_LINES for capsule's own stated reason: a one-pixel wire
## disappears when a capture is downscaled, and an axis that disappears measures the same
## as an axis that does nothing.
##
## THE TUBE RADIUS IS FIXED ACROSS THE WHOLE RESOLUTION AXIS, and that is Law 5. A gauge
## that rescaled itself per value would be measuring this function instead of the axis.
## The consequence is the argument: at coarse an edge is 49 px and the cage is open; at
## ultra an edge is 6 px against a 5 px tube and the frame closes into a skin.
func _armature(st: SurfaceTool, n: int, origin: Vector3) -> void:
	var rows: Array = _grid(n, origin)
	var wire: Color = _base.lightened(WIRE_LIGHTEN)
	var seen: Dictionary = {}
	for k in range(n):
		for j in range(n):
			var j2: int = (j + 1) % n
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][j2]
			var c: Vector3 = rows[k + 1][j2]
			var d: Vector3 = rows[k + 1][j]
			for pair in [[a, d], [d, c], [c, a], [a, c], [c, b], [b, a]]:
				var key: String = _edge_key(pair[0], pair[1])
				if seen.has(key):
					continue
				seen[key] = true
				_tube(st, pair[0], pair[1], CAPSULE.WIRE_RADIUS, wire)


## OPENED. A quarter taken out of the body — the wedge facing the standpoint — and both
## cut faces drawn filled, in the drawing convention where a section is a face and not an
## absence. The cut colour is capsule's own base.lightened(0.42).
##
## A QUARTER AND NOT THE FAMILY'S HALF, measured rather than assumed, and it COSTS.
## capsule and dome both remove the near half on one plane. Rendered here at the sweep's
## own camera, that half-body photographs as a flat pale slab standing on its pad: the
## cut face is the entire silhouette, nothing of the outer surface survives to say a body
## was opened, and the tile reads as a cardboard cutout rather than as a section. It is
## also, and this is the interesting part, the NUMERICALLY STRONGER option — measured
## against the `cast` station drawn alone at resolution=mid, the half reads 16.21% focus
## and the quarter 8.93%. The pixel metric prefers the picture that says the wrong thing.
## The quarter keeps three quarters of the outer surface as the frame around the cut and
## is taken at a cost of 7.28 points of station-level separation, on the record.
func _section(st: SurfaceTool, n: int, origin: Vector3) -> void:
	var rows: Array = _grid(n, origin)
	var prof: PackedVector2Array = _profile(n)
	# The kept region — x <= ox OR z <= oz — is not convex, so it is clipped as two
	# convex pieces whose union is exactly it and which share only the plane x = ox.
	for k in range(n):
		for j in range(n):
			var j2: int = (j + 1) % n
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][j2]
			var c: Vector3 = rows[k + 1][j2]
			var d: Vector3 = rows[k + 1][j]
			for tri in [[a, d, c], [a, c, b]]:
				var poly: Array = tri
				_fan(st, _clip(poly, 0, origin.x, true), _base)
				_fan(st, _clip(_clip(poly, 0, origin.x, false), 2, origin.z, true), _base)
	var cut: Color = _base.lightened(CUT_LIGHTEN)
	for k in range(n):
		var r0: float = _gon_radius(prof[k].x, n, 0.0)
		var r1: float = _gon_radius(prof[k + 1].x, n, 0.0)
		var s0: float = _gon_radius(prof[k].x, n, PI * 0.5)
		var s1: float = _gon_radius(prof[k + 1].x, n, PI * 0.5)
		var y0: float = origin.y + prof[k].y
		var y1: float = origin.y + prof[k + 1].y
		_quad_n(st, Vector3(origin.x, y0, origin.z), Vector3(origin.x + r0, y0, origin.z),
			Vector3(origin.x + r1, y1, origin.z), Vector3(origin.x, y1, origin.z),
			cut, Vector3(0.0, 0.0, 1.0))
		_quad_n(st, Vector3(origin.x, y0, origin.z + s0), Vector3(origin.x, y0, origin.z),
			Vector3(origin.x, y1, origin.z), Vector3(origin.x, y1, origin.z + s1),
			cut, Vector3(1.0, 0.0, 0.0))


## WALLED. Every face of the same tessellation extruded into its own slab, rims a darker
## tone, exactly as folded_strip.gd::_prism does it — the moment a described surface
## becomes a made one. Nothing is inset and no gap is invented: on a curved body adjacent
## slabs SPLAY at the crease by (t/2) * |n_a - n_b| = t * sin(PI/n), so the rims open
## themselves where the body turns hardest: 0.0113 m at coarse (3.55 px, the body reads
## as plates), 0.0069 at mid, 0.0031 at fine, 0.0016 at ultra (0.49 px, the wall closes
## back into a skin). The crease does the work; the wall thickness is MARK, the same one
## legibility unit the wire tube is drawn at.
func _shell(st: SurfaceTool, n: int, origin: Vector3) -> void:
	var rows: Array = _grid(n, origin)
	var rim: Color = _base.darkened(RIM_DARKEN)
	for k in range(n):
		for j in range(n):
			var j2: int = (j + 1) % n
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][j2]
			var c: Vector3 = rows[k + 1][j2]
			var d: Vector3 = rows[k + 1][j]
			_prism(st, a, d, c, _mark, _base, rim)
			_prism(st, a, c, b, _mark, _base, rim)


# ═══════════════════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _vertex_mat(unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.82
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() < 0.000000000001:
		return
	n = n.normalized()
	for v in [a, b, c]:
		st.set_normal(n)
		st.set_color(col)
		st.add_vertex(v)


func _smooth_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, origin: Vector3,
		col: Color) -> void:
	if (b - a).cross(c - a).length_squared() < 0.000000000001:
		return
	for v in [a, b, c]:
		st.set_normal(_surface_normal(v, origin))
		st.set_color(col)
		st.add_vertex(v)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		col: Color) -> void:
	_tri(st, p0, p1, p2, col)
	_tri(st, p0, p2, p3, col)


func _quad_n(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		col: Color, nrm: Vector3) -> void:
	for v in [p0, p1, p2, p0, p2, p3]:
		st.set_normal(nrm)
		st.set_color(col)
		st.add_vertex(v)


func _fan(st: SurfaceTool, poly: Array, col: Color) -> void:
	if poly.size() < 3:
		return
	for i in range(1, poly.size() - 1):
		_tri(st, poly[0], poly[i], poly[i + 1], col)


## Sutherland-Hodgman against one axis-aligned plane. `axis` is 0/1/2 for x/y/z.
func _clip(poly: Array, axis: int, plane: float, keep_below: bool) -> Array:
	var out: Array = []
	if poly.is_empty():
		return out
	var m: int = poly.size()
	for i in range(m):
		var cur: Vector3 = poly[i]
		var nxt: Vector3 = poly[(i + 1) % m]
		var cv: float = cur[axis]
		var nv: float = nxt[axis]
		var cin: bool = (cv <= plane) if keep_below else (cv >= plane)
		var nin: bool = (nv <= plane) if keep_below else (nv >= plane)
		if cin:
			out.append(cur)
		if cin != nin:
			var denom: float = nv - cv
			if absf(denom) < 0.000000000001:
				continue
			out.append(cur.lerp(nxt, (plane - cv) / denom))
	return out


## Distance from the axis to the boundary of a regular n-gon of circumradius `rho` whose
## vertices sit at theta = TAU * j / n, measured in direction `alpha`. Needed because the
## section plane cuts a POLYGON, not a circle: at n = 7 the body reaches 0.1000 m toward
## +x (a vertex) and 0.0924 m toward +z (an edge), and drawing the cut face from the
## smooth profile instead would put a filled plane outside its own body.
func _gon_radius(rho: float, n: int, alpha: float) -> float:
	if rho <= 0.0:
		return 0.0
	var apothem: float = rho * cos(PI / float(n))
	var k: float = round((alpha * float(n) / PI - 1.0) * 0.5)
	var delta: float = alpha - (2.0 * k + 1.0) * PI / float(n)
	return apothem / cos(delta)


func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d: Vector3 = b - a
	if d.length_squared() < 0.0000001:
		return
	var n: Vector3 = d.normalized()
	var seed_up: Vector3 = Vector3.UP
	if absf(n.dot(Vector3.UP)) > 0.9:
		seed_up = Vector3.RIGHT
	var u: Vector3 = n.cross(seed_up).normalized() * r
	var v: Vector3 = n.cross(u).normalized() * r
	var off: Array = []
	for k in range(3):
		var ang: float = TAU * float(k) / 3.0
		off.append(u * cos(ang) + v * sin(ang))
	for k in range(3):
		var o0: Vector3 = off[k]
		var o1: Vector3 = off[(k + 1) % 3]
		_quad(st, a + o0, a + o1, b + o1, b + o0, col)


func _prism(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, t: float, col: Color,
		rim: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() < 0.000000000001:
		return
	n = n.normalized()
	var h: Vector3 = n * (t * 0.5)
	var a0: Vector3 = a + h
	var b0: Vector3 = b + h
	var c0: Vector3 = c + h
	var a1: Vector3 = a - h
	var b1: Vector3 = b - h
	var c1: Vector3 = c - h
	_tri(st, a0, b0, c0, col)
	_tri(st, a1, c1, b1, col)
	_quad(st, a0, b0, b1, a1, rim)
	_quad(st, b0, c0, c1, b1, rim)
	_quad(st, c0, a0, a1, c1, rim)


func _box(st: SurfaceTool, lo: Vector3, hi: Vector3, col: Color) -> void:
	var p: Array = [
		Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z),
		Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z),
		Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z),
		Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z)]
	var faces: Array = [[4, 5, 6, 7], [1, 0, 3, 2], [3, 2, 6, 7], [0, 1, 5, 4],
		[1, 2, 6, 5], [0, 4, 7, 3]]
	for f in faces:
		_quad(st, p[f[0]], p[f[1]], p[f[2]], p[f[3]], col)


func _disc(st: SurfaceTool, centre: Vector3, r: float, t: float, col: Color) -> void:
	for k in range(PAD_SEGMENTS):
		var a0: float = TAU * float(k) / float(PAD_SEGMENTS)
		var a1: float = TAU * float(k + 1) / float(PAD_SEGMENTS)
		var p0 := Vector3(centre.x + r * cos(a0), centre.y + t, centre.z + r * sin(a0))
		var p1 := Vector3(centre.x + r * cos(a1), centre.y + t, centre.z + r * sin(a1))
		_tri(st, Vector3(centre.x, centre.y + t, centre.z), p1, p0, col)
		_quad(st, p0, p1, Vector3(p1.x, centre.y, p1.z), Vector3(p0.x, centre.y, p0.z), col)


func _edge_key(a: Vector3, b: Vector3) -> String:
	var ka: String = "%.4f_%.4f_%.4f" % [a.x, a.y, a.z]
	var kb: String = "%.4f_%.4f_%.4f" % [b.x, b.y, b.z]
	if ka < kb:
		return ka + "|" + kb
	return kb + "|" + ka
