extends RefCounted

## dream_bodies / mannerist_tumble — the PILE and the DRAPERY MOUND.
##
## Reference: FinalMD/m1/0_2225-0000.jpg (4096x1072 panorama) — porcelain-pale
## bodies with copper curls tumbling across a dark hall of columns, half buried in
## enormous mounds of teal and rose drapery. The cloth is the thing to notice, and
## it is why this family is not another draped figure: the drapery does not HANG,
## it MASSES. Each mound is a solid faceted volume with crisp planar folds, as big
## as the figures and heavier than they are, and the bodies are pressed into it the
## way fruit sets into jelly. Putti float overhead. No body in the picture is
## anatomically explicit — every one is a smooth abstracted form, most of them
## faceless, read as pure volume.
##
## david_drape already owns ONE draped figure, and its cloth is swept sine folds
## over a standing body. This family owns the opposite argument: the HEAP. Four
## bodies and the cloth mountain they are sinking into, on a plinth you walk
## around, with a broken column stump at the back for the hall.
##
## Reproduced, and how:
##   1. The mound is a VOLUME, not a sheet — eight lobes of cloth heaped over a
##      shared centre, each one a faceted lobe built in SurfaceTool from a 7x12
##      polar grid whose radius carries three-to-five fold ridges (a sine in theta
##      whose phase drifts with height, damped to nothing at the poles so the folds
##      do not pinch). Flat-shaded on purpose: the vertices are never welded, so
##      generate_normals gives one normal per triangle and every fold has an edge.
##   2. The bodies tumble INTO it — four abstracted figures at 0.76 m, each a chain
##      of capsules with a plain sphere for a head, laid on their sides and backs
##      at four heights up the heap so limbs come out of the cloth at angles the
##      cloth cannot explain. Poses are dealt (the mannerist arm swings through
##      2.4 rad, the knees bend independently); proportions never are. A body here
##      is a form.
##   3. Copper curls — seven small spheres on a golden-angle spiral over each
##      skull's upper hemisphere, in patent or chrome copper. They are the only
##      warm metal in the piece and the only thing that says which lump is a head.
##   4. Putti overhead — three small bodies with faceted wings, riding the top of a
##      cloth spire that twists up out of the heap, each tied back to it by a wisp
##      of the same cloth. A statue cannot float anything, so the reference's
##      hovering putti became putti CARRIED, which is what a sculptor does with
##      them anyway.
##   5. The hall — one broken column: base block, two drums, the upper one shifted
##      and tilted off the lower. Buried to its waist in the heap.
##   6. Painted marks — the cloth carries a damask lattice with a lozenge at each
##      node, drawn pixel by pixel into a 128x128 ImageTexture and run over every
##      lobe with world triplanar so the pattern crosses facet edges unbroken. The
##      stone carries its own texture: chalk speckle over horizontal bedding.
##   7. A seed is a statue — the two cloth colours, all four finishes, the fold
##      count and depth, every lobe's place and size, the column's angle, all four
##      poses, and which way the spire twists.
##
## THE ONE MATTE PASSAGE is the ARCHITECTURE: the column and the plinth it stands
## on share a single dry chalk material (roughness 0.92, no clearcoat, no rim, no
## emission) and are the only thing in the piece that is not wet. That is not
## thrift, it is the reference's own contrast — the hall behind the pile is dead
## matte paint and the bodies in front of it are glazed. A wet body only reads wet
## next to a dry one, and here the dry thing is the building.
##
## AXES — two, and they cut the two substances the reference is made of:
##   mound — what the CLOTH is. "faceted" is the reference, big planar folded
##           volumes. "quarried" remembers cloth as masonry: every lobe becomes two
##           courses of cut block, offset and turned, so the heap is a rubble pile.
##           "billow" over-inflates it — smooth swollen pillows, no facet anywhere,
##           the mound 14% larger and rounder. "shredded" takes the volume away
##           and leaves the fall: three twisted ribbons per lobe hanging to the
##           floor, so the bodies inside come back into the silhouette. "cast"
##           takes the whole group in ONE MOULD — see below.
##   pile  — what the FLESH does. "heap" is the reference, four bodies tangled at
##           four heights. "cascade" re-anchors the same four down one flank in a
##           falling diagonal, each further over than the last. "spiral" stands
##           three of them in a rising helix around the spire — the figura
##           serpentinata the mannerists actually wanted, which the reference's
##           heap is the collapse of. "fragments" breaks them: every limb keeps its
##           own place but takes its own small rotation, a third of the pieces are
##           gone, and only the heads survive whole. "single" is one body at 1.02 m
##           sprawled across the whole mound, so the pile becomes a nude and the
##           cloth becomes its bed.
##
## WHAT "cast" GROWS. Every other value of `mound` stacks primitives and lets the
## gloss hide the seams. "cast" hands the SAME geometry — the same eight lobes at
## the same centres, the same spire, and every body segment from the same
## _figure_segs, so the two paths cannot drift — to DreamIso as an SDF of about
## fifty parts, marched at 5.2 cm with an 8.5 cm smooth union. Nothing overlaps any
## more: an arm does not lie ON the cloth, it SWELLS out of it, and the whole heap
## comes out as one continuous piece of poured plaster in one colour. The teal and
## the rose leave the picture entirely, which is the point of the value: this is
## what a mould does to a group. The curls, the putti and the column stay
## primitives, because they are what tells you the monolith was ever people.
## If the mesher returns null the value falls back to "faceted" with everything
## still standing — never a bare plinth.
##
## THE TWO AXES ARE INDEPENDENT BY CONSTRUCTION, and it took two random streams to
## make that true. `mound=shredded` draws three ribbons where `faceted` draws one
## lobe, so it consumes a different amount of the generator — and anything dealt
## afterwards off the same stream would have shifted under it, which would mean
## changing the CLOTH axis silently re-posed the BODIES and the critic could not
## read either axis alone. So there are two: `rng` deals the palette, the stone,
## the lobes and the spire; `rng2` (seeded off the same seed, deterministically)
## deals every body, curl and putto. Changing `mound` cannot move a limb; changing
## `pile` cannot move a fold.
##
## Given up: the hall (one column stump stands for it), the perforated tan banner
## hanging in the middle of the panorama, faces, hands with fingers, and cloth
## simulation of any kind — every fold here is an analytic sine or a cut block.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX: int = 128
const PLINTH_TOP: float = 0.055

# the cast field. 0.052 over a ~1.15 x 1.5 x 1.1 m box is about 13k corners against
# ~50 parts, which measures in the same order as fetish_idol's bench body; finer
# than this and a museum hall pays for it on the main thread while someone walks.
const POUR_CELL: float = 0.052
const POUR_BLEND: float = 0.085

# cloth finishes — never "matte" (the architecture owns matte) and never "neon"
# (a lobe this big at emission 3.2 blooms over the whole frame)
const CLOTH_FIN: Array[String] = ["latex", "patent", "candy", "wet"]
# flesh: porcelain wants nacre or glaze, not a mirror
const FLESH_FIN: Array[String] = ["pearl", "candy", "wet", "latex"]

# the reference's two cloth families, mapped onto the queer palette so they survive
# AgX: a cold one and a warm one, dealt one from each
const COLD: Array[String] = ["cyan", "mint", "violet", "lilac"]
const WARM: Array[String] = ["hot_pink", "blood", "tangerine", "magenta"]

# copper, for the curls — the one warm metal
const COPPER: Color = Color(0.86, 0.42, 0.16)
# WARM IVORY, NOT WHITE. At 0.97 the flesh clipped under AgX at exposure 1.15 and
# every body came out a flat white silhouette with no form in it — the shading has
# to have somewhere to go, and a glaze puts a specular on top of this anyway.
const PORCELAIN: Color = Color(0.90, 0.85, 0.78)
const CHALK: Color = Color(0.82, 0.80, 0.76)

# a standing figure normalised to height 1.0, so the pile can scale one number and
# every body keeps its proportions. Rotation happens about CENTRE, not the feet.
const F_HIP: float = 0.52
const CENTRE: Vector3 = Vector3(0.0, 0.50, 0.0)
const FIG_H: float = 0.76


static func describe() -> String:
	return "A heap of porcelain bodies with copper curls tumbling into a mountain of faceted teal and rose drapery, three putti riding a cloth spire above it and a broken column standing in the dry chalk behind."


static func axes() -> Dictionary:
	return {
		"mound": ["faceted", "quarried", "billow", "shredded", "cast"],
		"pile": ["heap", "cascade", "spiral", "fragments", "single"],
	}


## The prediction, before the capture, as data — tools/dream_bodies_promote.py
## carries it into the registry as dna.predicted_degeneracy so nobody retypes it.
## It is a LOWER bound: this arithmetic has one light, no shadow and no AO.
static func predicted() -> Dictionary:
	return {
		"pair": "pile: heap vs cascade, at mound=cast",
		"predicted_pct": 2.0,
		"reasoning": ("cloth, spire, column, plinth and the three putti are the same object in "
			+ "both values — call them 72% of the subject's pixels. The four bodies are the "
			+ "other 28%, and about a third of each is inside the mound in both, so ~19% of the "
			+ "subject is body you can see. Re-anchoring them down the flank changes roughly "
			+ "70% of that, counting the ground they leave as well as the ground they take: "
			+ "0.19 x 0.70 = 13% of the subject. The subject is ~30% of the frame at the "
			+ "family's framing 0.62, so ~4% of frame at the four PRIMITIVE mounds. At cast the "
			+ "same move is halved: an 8.5 cm smooth union swallows the gap between a limb and "
			+ "the cloth, so each figure reads as a swelling in one mass and the two "
			+ "arrangements photograph as two lumpy monoliths. 4% x 0.5 = 2.0%."),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var mound: String = str(opts.get("mound", "faceted"))
	var pile: String = str(opts.get("pile", "heap"))

	# TWO STREAMS, ON PURPOSE — see the header. rng is cloth and stone, rng2 is
	# flesh. rng2's seed is derived, not random, so a family member is still one
	# statue per seed.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = seed * 7919 + 131

	# --- the wardrobe, dealt from the cloth stream ---------------------------
	var cold: Color = Gloss.QUEER[COLD[rng.randi_range(0, COLD.size() - 1)]]
	var warm: Color = Gloss.QUEER[WARM[rng.randi_range(0, WARM.size() - 1)]]
	var fin_cloth: String = CLOTH_FIN[rng.randi_range(0, CLOTH_FIN.size() - 1)]
	var fin_flesh: String = FLESH_FIN[rng.randi_range(0, FLESH_FIN.size() - 1)]
	var ink: Color = Color(0.10, 0.09, 0.12)
	# each cloth wears the OTHER one's colour as its lozenge, the way the teal and
	# the rose in the reference keep turning up inside each other's folds
	var damask_on_cold: ImageTexture = _paint_damask(rng, warm, ink)
	var damask_on_warm: ImageTexture = _paint_damask(rng, cold, ink)
	var stone_tex: ImageTexture = _paint_stone(rng)

	var mat_cold: StandardMaterial3D = _cloth_mat(fin_cloth, cold, damask_on_cold, rng)
	var mat_warm: StandardMaterial3D = _cloth_mat(fin_cloth, warm, damask_on_warm, rng)
	var flesh_c: Color = PORCELAIN.lerp(cold, rng.randf_range(0.0, 0.12))
	var mat_flesh: StandardMaterial3D = Gloss.skin(fin_flesh, flesh_c, rng)
	# THE FINISH TINTS ITS OWN ALBEDO AND IT UNDID THE COLOUR ABOVE: "pearl" sets
	# albedo to Color(0.96, 0.94, 0.95).lerp(base, 0.22), which is nacre by design
	# and puts any porcelain within 4% of white. Darkening PORCELAIN could not
	# reach it — 22% of a change is not a change. So the flesh states its own
	# albedo after the finish has had its say, exactly as nana_gloss._dress does.
	mat_flesh.albedo_color = flesh_c
	mat_flesh.metallic = minf(mat_flesh.metallic, 0.45)
	var mat_copper: StandardMaterial3D = Gloss.skin("patent" if rng.randf() < 0.6 else "chrome", COPPER, rng)
	mat_copper.metallic = maxf(mat_copper.metallic, 0.55)

	# THE ONE MATTE PASSAGE: column and plinth, one material, one dry surface.
	var mat_stone: StandardMaterial3D = Gloss.skin("matte", CHALK)
	mat_stone.albedo_texture = stone_tex
	mat_stone.uv1_triplanar = true
	mat_stone.uv1_world_triplanar = true
	mat_stone.uv1_scale = Vector3(1.1, 1.1, 1.1)

	# --- everything dealt BEFORE anything is built ---------------------------
	# The mound consumes a different amount of rng at every value of its axis, so
	# it is built LAST and nothing may be dealt after it.
	var lobes: Array = _mound_lobes(rng, 1.14 if mound == "billow" else 1.0)
	var spire: Array = _spire_lobes(rng)
	var col_a: float = rng.randf_range(2.1, 4.0)
	var bodies: Array = []
	for tf_v in _pile_layout(rng2, pile):
		var lay: Dictionary = tf_v
		var segs: Array = _figure_segs(rng2, lay["tf"], float(lay["k"]))
		if pile == "fragments":
			segs = _shatter(segs, rng2)
		bodies.append(segs)
	var putti: Array = _putti_places(rng2, spire)

	# --- the hall: built first, so the cloth heaps over it -------------------
	_column(root, mat_stone, col_a)

	# --- the cast value: cloth and flesh in one mould ------------------------
	var cast_ok: bool = false
	if mound == "cast":
		var parts: Array = []
		for l_v in lobes:
			var l: Dictionary = l_v
			var lr: Vector3 = l["r"]
			parts.append(Iso.box(l["c"], lr * 0.62, minf(lr.x, lr.z) * 0.52))
		for s_v in spire:
			var sp: Dictionary = s_v
			var sr: Vector3 = sp["r"]
			parts.append(Iso.box(sp["c"], sr * 0.60, minf(sr.x, sr.z) * 0.55))
		for segs_v in bodies:
			for d_v in (segs_v as Array):
				var d: Dictionary = d_v
				if str(d["tag"]) == "toe":
					continue                 # too small to survive a 5.2 cm cell anyway
				parts.append(Iso.capsule(d["a"], d["b"], float(d["r"]) * 0.94, float(d["r2"]) * 0.94))
		var grown: ArrayMesh = Iso.mesh_of(parts, POUR_CELL, POUR_BLEND, 0.05)
		# A NULL HERE IS AN EMPTY PLINTH, and the fallback below is the whole reason
		# this is checked rather than assumed: dream_iso returns null when the field
		# never crossed zero, and says so only in a warning nobody reads in a hall.
		if grown != null:
			_add(root, grown, mat_flesh)
			cast_ok = true

	# --- the cloth -----------------------------------------------------------
	var build_mode: String = "faceted" if mound == "cast" else mound
	if not cast_ok:
		for i in range(lobes.size()):
			var l2: Dictionary = lobes[i]
			var m: StandardMaterial3D = mat_cold if bool(l2["cold"]) else mat_warm
			_cloth_at(root, build_mode, m, l2, rng, 3)
		for i in range(spire.size()):
			var s2: Dictionary = spire[i]
			var m2: StandardMaterial3D = mat_warm if i % 2 == 0 else mat_cold
			_cloth_at(root, build_mode, m2, s2, rng, 2)

	# --- the flesh -----------------------------------------------------------
	var mat_wisp: StandardMaterial3D = mat_flesh if cast_ok else mat_cold
	if not cast_ok:
		for segs_v2 in bodies:
			_build_figure(root, segs_v2, mat_flesh)
	# curls are ALWAYS primitives, cast or not: they sit proud of the surface and
	# they are the only thing that names a lump as a head
	var curl_grow: float = POUR_BLEND * 0.5 if cast_ok else 0.0
	for segs_v3 in bodies:
		_curls(root, mat_copper, segs_v3, rng2, curl_grow)
	for p_v in putti:
		var p: Dictionary = p_v
		_putto(root, mat_flesh, mat_wisp, mat_copper, p, rng2)

	# --- stature, then the measured settle (copied from nana_gloss) ----------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = (1.68 - PLINTH_TOP) / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_rescale(root, kfit)
		box = _union_aabb(root)

	var centre: Vector3 = box.position + box.size * 0.5
	_shift(root, Vector3(-centre.x, PLINTH_TOP - box.position.y, -centre.z))
	box = _union_aabb(root)
	if box.position.y < 0.0:
		_shift(root, Vector3(0.0, -box.position.y, 0.0))
		box = _union_aabb(root)

	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.20, box.size.x + 0.10), PLINTH_TOP, minf(1.20, box.size.z + 0.10))
	var pm: MeshInstance3D = _add(root, plinth, mat_stone)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# THE CLOTH

## Where the heap's lobes sit, as data. Dealt before anything is built so that a
## change of idiom below cannot move a lobe.
##
## The half-extents are held under 0.57 m deliberately: the settle scales the whole
## statue down if it passes 1.20 m across, and a pile is WIDE — a mound that came
## out 1.5 m across would be shrunk to 1.20 and lose a fifth of its height with it,
## which is how a heap ends up under the probe's 0.9 m floor without any single
## number in this file looking wrong.
static func _mound_lobes(rng: RandomNumberGenerator, big: float) -> Array:
	var out: Array = []
	# two hearts, the mass the rest leans on
	out.append(_lobe(Vector3(-0.04, 0.19, 0.02), Vector3(0.35, 0.20, 0.31) * big, 0.0, true, rng))
	out.append(_lobe(Vector3(0.07, 0.27, -0.05), Vector3(0.28, 0.18, 0.26) * big, 0.4, false, rng))
	var n: int = rng.randi_range(5, 7)
	var spin: float = rng.randf_range(0.0, TAU)
	for i in range(n):
		var a: float = spin + TAU * float(i) / float(n) + rng.randf_range(-0.25, 0.25)
		# WIDE AND LOW, not stacked. The first pass ran d 0.14..0.25 against lobes
		# 0.17..0.23 across, which piles them nearly on one axis: the heap
		# photographed as a totem, and a totem is the one thing this reference is
		# not. Pushing the ring out past the lobe radius makes it spread.
		var d: float = rng.randf_range(0.20, 0.31)
		var y: float = rng.randf_range(0.09, 0.33)
		var r := Vector3(rng.randf_range(0.17, 0.23), rng.randf_range(0.11, 0.17),
			rng.randf_range(0.16, 0.22)) * big
		out.append(_lobe(Vector3(cos(a) * d, y, sin(a) * d), r, a, i % 2 == 0, rng))
	return out


## The spire the putti ride: the same lobe vocabulary, smaller, twisting up out of
## the heap. Four lobes, because three reads as a lump and five costs a putto.
static func _spire_lobes(rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var spin: float = rng.randf_range(0.0, TAU)
	var twist: float = rng.randf_range(1.6, 3.0) * (1.0 if rng.randf() < 0.5 else -1.0)
	for i in range(4):
		var t: float = float(i) / 3.0
		var a: float = spin + twist * t
		var rad: float = lerpf(0.15, 0.05, t)
		var y: float = lerpf(0.40, 0.98, t)
		var rr: float = lerpf(0.205, 0.095, t)
		out.append(_lobe(Vector3(cos(a) * rad, y, sin(a) * rad),
			Vector3(rr, rr * 0.92, rr * 0.88), a, i % 2 == 1, rng))
	return out


static func _lobe(c: Vector3, r: Vector3, yaw: float, cold: bool, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"c": c,
		"r": r,
		"b": Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, rng.randf_range(-0.35, 0.35)),
		"cold": cold,
		# 4..7 ridges at 0.20..0.32 of the radius. The first pass ran 3..5 at
		# 0.13..0.24 and the mound photographed as smooth balls: a fold shallower
		# than about a fifth of the lobe is carried entirely by the shading, and
		# the shading is the first thing a loud texture takes away.
		"folds": rng.randi_range(4, 7),
		"amp": rng.randf_range(0.20, 0.32),
		"phase": rng.randf_range(0.0, TAU),
	}


## ONE lobe of cloth, in whichever idiom the mound axis asked for.
##
## Every value goes through here, so the heap, the spire and the putti's wisps
## cannot drift into different vocabularies — a spire of cut blocks standing over a
## heap of folds is the failure this single door exists to make impossible.
static func _cloth_at(root: Node3D, mode: String, mat: StandardMaterial3D, lobe: Dictionary,
		rng: RandomNumberGenerator, strands: int) -> void:
	var c: Vector3 = lobe["c"]
	var r: Vector3 = lobe["r"]
	var b: Basis = lobe["b"]
	if mode == "quarried":
		# cloth remembered as masonry: two courses, offset and turned
		var box := BoxMesh.new()
		box.size = Vector3(r.x * 1.62, r.y * 1.30, r.z * 1.62)
		var mi: MeshInstance3D = _add(root, box, mat)
		mi.transform = Transform3D(b * Basis(Vector3.UP, rng.randf_range(-0.6, 0.6)), c)
		var box2 := BoxMesh.new()
		box2.size = Vector3(r.x * 1.10, r.y * 0.86, r.z * 1.18)
		var mi2: MeshInstance3D = _add(root, box2, mat)
		mi2.transform = Transform3D(b * Basis(Vector3.UP, rng.randf_range(-1.1, 1.1)),
			c + Vector3(rng.randf_range(-0.05, 0.05), r.y * 1.02, rng.randf_range(-0.05, 0.05)))
		return
	if mode == "billow":
		_ellipsoid(root, mat, c, r * 1.16, b)
		return
	if mode == "shredded":
		var top: Vector3 = c + Vector3(0.0, r.y * 0.55, 0.0)
		for i in range(strands):
			var a: float = rng.randf_range(0.0, TAU)
			var sway: float = rng.randf_range(-0.10, 0.10)
			var pts: Array = []
			for j in range(5):
				var t: float = float(j) / 4.0
				var reach: float = 0.30 + 0.90 * t
				pts.append(Vector3(
					top.x + cos(a) * r.x * reach + sway * sin(t * 3.1),
					maxf(0.05, lerpf(top.y, top.y - r.y * 2.9, t)),
					top.z + sin(a) * r.z * reach + sway * cos(t * 2.4)))
			_strap(root, mat, pts, r.x * 0.34, 0.016, rng.randf_range(-0.6, 0.6), 0.55)
		return
	_fold_lobe(root, mat, c, r, b, int(lobe["folds"]), float(lobe["amp"]), float(lobe["phase"]))


## A faceted lobe of cloth: a polar grid whose radius carries fold ridges.
##
## The vertices are never welded, so SurfaceTool.generate_normals() gives ONE
## normal per triangle and the folds keep their edges. Weld them and the whole
## mound turns into a beanbag — which is exactly what `billow` is for, and it gets
## there with a SphereMesh rather than by smoothing this.
static func _fold_lobe(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3,
		b: Basis, folds: int, amp: float, phase: float) -> void:
	var rings: int = 9
	var segs: int = 14
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid: Array = []
	for i in range(rings + 1):
		var phi: float = PI * float(i) / float(rings)
		var row: Array = []
		for j in range(segs):
			var th: float = TAU * float(j) / float(segs)
			var d := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			# the ridge dies at both poles, or the fold pinches into a spike there
			var ridge: float = 1.0 + amp * sin(float(folds) * th + phase + phi * 1.7) * sin(phi)
			row.append(c + b * Vector3(d.x * r.x * ridge, d.y * r.y, d.z * r.z * ridge))
		grid.append(row)
	for i in range(rings):
		var r0: Array = grid[i]
		var r1: Array = grid[i + 1]
		for j in range(segs):
			var j2: int = (j + 1) % segs
			var p0: Vector3 = r0[j]
			var p1: Vector3 = r0[j2]
			var p2: Vector3 = r1[j2]
			var p3: Vector3 = r1[j]
			var out: Vector3 = ((p0 + p1 + p2 + p3) * 0.25 - c)
			if out.length_squared() < 1.0e-12:
				out = Vector3.UP
			_quad(st, p0, p1, p2, p3, out.normalized())
	st.generate_normals()
	_add(root, st.commit(), mat)


## A solid ribbon along a path — four faces and two caps, so it reads from behind
## as well as in front. A single-sided sheet would vanish from half the walk-around,
## which is the whole difference between a hanging strip and a hole in the statue.
static func _strap(root: Node3D, mat: StandardMaterial3D, pts: Array, hw: float,
		ht: float, roll: float, taper: float) -> void:
	if pts.size() < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		var tan: Vector3 = Vector3.UP
		if i == 0:
			tan = (pts[1] as Vector3) - p
		elif i == pts.size() - 1:
			tan = p - (pts[i - 1] as Vector3)
		else:
			tan = (pts[i + 1] as Vector3) - (pts[i - 1] as Vector3)
		if tan.length_squared() < 1.0e-10:
			tan = Vector3.UP
		var fb: Basis = _basis_y_to(tan) * Basis(Vector3.UP, roll * float(i))
		var t: float = float(i) / float(pts.size() - 1)
		var w: float = hw * lerpf(1.0, taper, t)
		var h: float = ht * lerpf(1.0, taper, t)
		rings.append([
			p + fb * Vector3(w, 0.0, h), p + fb * Vector3(-w, 0.0, h),
			p + fb * Vector3(-w, 0.0, -h), p + fb * Vector3(w, 0.0, -h)])
	for i in range(rings.size() - 1):
		var a: Array = rings[i]
		var b: Array = rings[i + 1]
		var axis: Vector3 = ((pts[i] as Vector3) + (pts[i + 1] as Vector3)) * 0.5
		for k in range(4):
			var k2: int = (k + 1) % 4
			var q0: Vector3 = a[k]
			var q1: Vector3 = a[k2]
			var q2: Vector3 = b[k2]
			var q3: Vector3 = b[k]
			var out: Vector3 = ((q0 + q1 + q2 + q3) * 0.25 - axis)
			if out.length_squared() < 1.0e-12:
				out = Vector3.UP
			_quad(st, q0, q1, q2, q3, out.normalized())
	var first: Array = rings[0]
	var last: Array = rings[rings.size() - 1]
	var n0: Vector3 = ((pts[0] as Vector3) - (pts[1] as Vector3)).normalized()
	var n1: Vector3 = ((pts[pts.size() - 1] as Vector3) - (pts[pts.size() - 2] as Vector3)).normalized()
	_quad(st, first[0], first[1], first[2], first[3], n0)
	_quad(st, last[0], last[1], last[2], last[3], n1)
	st.generate_normals()
	_add(root, st.commit(), mat)


## Two triangles, both wound so they face `outward`.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	_tri(st, a, b, c, outward)
	_tri(st, a, c, d, outward)


## One triangle, wound so its face points where the surface actually faces.
##
## GODOT WINDS FRONT FACES CLOCKWISE, and SurfaceTool.generate_normals() takes
## Plane(a, b, c).normal, which Godot builds as (a - c) x (a - b) — the NEGATIVE of
## the textbook (b - a) x (c - a). Written the textbook way every lobe in the heap
## comes out inside out: lit from within, silhouette intact, and completely wrong in
## a way no screenshot names. So the order is CHECKED against the outward direction
## rather than guessed per quad.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var n: Vector3 = (a - c).cross(a - b)
	if n.length_squared() < 1.0e-16:
		return                                   # degenerate at the poles, contributes nothing
	if n.dot(outward) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


# ---------------------------------------------------------------------------
# THE FLESH

## Where the bodies go, and how big. Every value returns transforms whose ORIGIN is
## the body's own centre (see CENTRE) — a tumbling figure has to turn about its
## middle, not about the soles of feet that are nowhere near the ground.
static func _pile_layout(rng: RandomNumberGenerator, pile: String) -> Array:
	var out: Array = []
	if pile == "single":
		out.append({"tf": _tf(Vector3(0.0, 0.48, -0.02), rng.randf_range(-0.6, 0.6),
			rng.randf_range(1.30, 1.62), rng.randf_range(-0.5, 0.5)), "k": FIG_H * 1.34})
		return out
	if pile == "spiral":
		# the figura serpentinata the mannerists wanted, of which the heap is the
		# collapse: three bodies climbing the spire, each a third of a turn on
		var spin: float = rng.randf_range(0.0, TAU)
		for i in range(3):
			var t: float = float(i) / 2.0
			var a: float = spin + TAU * float(i) / 3.0
			var rad: float = lerpf(0.24, 0.13, t)
			out.append({"tf": _tf(Vector3(cos(a) * rad, lerpf(0.44, 0.92, t), sin(a) * rad),
				a + rng.randf_range(-0.3, 0.3), rng.randf_range(0.30, 0.85),
				rng.randf_range(-0.8, 0.8)), "k": FIG_H * 0.92})
		return out
	if pile == "cascade":
		# one falling diagonal down a single flank, each further over and further
		# head-down than the last
		var dir: float = rng.randf_range(0.0, TAU)
		for i in range(4):
			var t2: float = float(i) / 3.0
			var d: float = lerpf(0.05, 0.30, t2)
			out.append({"tf": _tf(
				Vector3(cos(dir) * d, lerpf(0.74, 0.20, t2), sin(dir) * d),
				dir + rng.randf_range(-0.35, 0.35) + PI * 0.5,
				lerpf(0.55, 2.35, t2) + rng.randf_range(-0.15, 0.15),
				rng.randf_range(-0.6, 0.6)), "k": FIG_H * 0.97})
		return out
	# heap (and the bodies fragments is made of): four, tangled, at four heights.
	# HALF BURIED IS THE WHOLE IMAGE, so the seats sit low and near the axis — set
	# them out at the mound's own radius and the bodies lie in front of the cloth
	# instead of in it, which is a group portrait rather than a pile.
	var yaw0: float = rng.randf_range(0.0, TAU)
	var seats: Array = [
		[Vector3(0.01, 0.24, -0.04), 1.62], [Vector3(-0.15, 0.36, 0.10), 1.30],
		[Vector3(0.16, 0.33, 0.08), 1.44], [Vector3(-0.02, 0.54, -0.01), 1.05]]
	for i in range(seats.size()):
		var s: Array = seats[i]
		out.append({"tf": _tf(s[0], yaw0 + TAU * float(i) / 4.0 + rng.randf_range(-0.4, 0.4),
			float(s[1]) + rng.randf_range(-0.2, 0.2), rng.randf_range(-0.7, 0.7)),
			"k": FIG_H})
	return out


static func _tf(pos: Vector3, yaw: float, pitch: float, roll: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, roll), pos)


## One abstracted body, as world-space segments.
##
## The POSE is dealt — the mannerist arm swings through 2.4 rad, the knees bend
## independently — and the PROPORTIONS never are. A body here is a form: no face,
## no fingers, no genitals, nothing but the volume, which is what the reference's
## bodies are too.
static func _figure_segs(rng: RandomNumberGenerator, tf: Transform3D, k: float) -> Array:
	var s: Array = []
	var lean: float = rng.randf_range(-0.03, 0.04)
	var pel := Vector3(0.0, F_HIP, 0.0)
	var chest := Vector3(lean * 0.5, 0.72, rng.randf_range(-0.03, 0.03))
	var neck := Vector3(lean, 0.855, chest.z * 1.25)
	var head := Vector3(lean * 1.2, 0.945, neck.z * 1.15)
	# THE TORSO CARRIES THE BODY, and in the first pass it did not: at 0.092 against
	# a 0.064 thigh the figures photographed as balloon animals, all limb. A
	# sculptural body is mass with limbs coming off it, so the trunk went to 0.108
	# and the hands and feet came down — a blob on a stick reads as a stick.
	_seg(s, pel, chest, 0.108, 0.098, "torso")
	_seg(s, chest, neck, 0.098, 0.055, "torso")
	_seg(s, Vector3(lean - 0.105, 0.822, 0.0), Vector3(lean + 0.105, 0.822, 0.0), 0.056, 0.056, "torso")
	s.append({"a": head, "b": head, "r": 0.070, "r2": 0.070, "tag": "head"})
	for i in range(2):
		var sd: float = -1.0 if i == 0 else 1.0
		var sh := Vector3(lean + sd * 0.112, 0.818, 0.0)
		var swing: float = rng.randf_range(-0.9, 2.4)
		var el: Vector3 = sh + Vector3(sd * rng.randf_range(0.10, 0.24),
			-0.17 * cos(swing), -0.11 * sin(swing) - 0.02)
		var wr: Vector3 = el + Vector3(sd * rng.randf_range(0.01, 0.16),
			0.20 * sin(swing - 0.45), -0.15 * cos(swing))
		_seg(s, sh, el, 0.046, 0.034, "limb")
		_seg(s, el, wr, 0.034, 0.024, "limb")
		s.append({"a": wr, "b": wr, "r": 0.029, "r2": 0.029, "tag": "toe"})
		var hp := Vector3(sd * 0.078, F_HIP, 0.0)
		var bend: float = rng.randf_range(0.20, 1.20)
		var kn: Vector3 = hp + Vector3(sd * rng.randf_range(-0.02, 0.10),
			-0.23 * cos(bend * 0.75), -0.21 * sin(bend))
		var an: Vector3 = kn + Vector3(sd * rng.randf_range(-0.03, 0.07),
			-0.24 * cos(bend * 0.30), 0.13 * sin(bend * 1.3))
		_seg(s, hp, kn, 0.070, 0.046, "limb")
		_seg(s, kn, an, 0.046, 0.030, "limb")
		s.append({"a": an + Vector3(0.0, -0.02, -0.035), "b": an + Vector3(0.0, -0.02, -0.035),
			"r": 0.033, "r2": 0.033, "tag": "toe"})
	var out: Array = []
	for d_v in s:
		var d: Dictionary = d_v
		out.append({
			"a": tf * (((d["a"] as Vector3) - CENTRE) * k),
			"b": tf * (((d["b"] as Vector3) - CENTRE) * k),
			"r": float(d["r"]) * k,
			"r2": float(d["r2"]) * k,
			"tag": str(d["tag"]),
		})
	return out


static func _seg(s: Array, a: Vector3, b: Vector3, r: float, r2: float, tag: String) -> void:
	s.append({"a": a, "b": b, "r": r, "r2": r2, "tag": tag})


## The `fragments` value: a third of the pieces are gone and every survivor takes
## its own small turn about its own middle. Heads are exempt — a fragment pile with
## no head reads as rubble rather than as a body, and the curls need somewhere to
## sit.
static func _shatter(segs: Array, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for d_v in segs:
		var d: Dictionary = d_v
		var head: bool = str(d["tag"]) == "head"
		if not head and rng.randf() < 0.34:
			continue
		var a: Vector3 = d["a"]
		var b: Vector3 = d["b"]
		var c: Vector3 = (a + b) * 0.5
		var ax := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		# Basis(axis, angle) needs a UNIT axis and three randf can land on nothing
		if ax.length() < 0.001:
			ax = Vector3.UP
		var rot := Basis(ax.normalized(), rng.randf_range(-0.75, 0.75))
		var off := Vector3(rng.randf_range(-0.07, 0.07), rng.randf_range(-0.05, 0.05),
			rng.randf_range(-0.07, 0.07))
		out.append({
			"a": c + rot * (a - c) + off, "b": c + rot * (b - c) + off,
			"r": d["r"], "r2": d["r2"], "tag": d["tag"],
		})
	return out


## A CapsuleMesh has ONE radius, so a limb drawn as a single capsule is a tube, and
## four bodies of tubes photograph as balloon animals — which is what the first
## capture showed. A tapered segment is therefore drawn as TWO capsules, each at
## the radius of its own half, which costs ten meshes a body and buys the one thing
## that separates a thigh from a pipe.
static func _build_figure(root: Node3D, segs: Array, mat: StandardMaterial3D) -> void:
	for d_v in segs:
		var d: Dictionary = d_v
		var a: Vector3 = d["a"]
		var b: Vector3 = d["b"]
		var r0: float = float(d["r"])
		var r1: float = float(d["r2"])
		if (b - a).length() < 0.005:
			var r: float = (r0 + r1) * 0.5
			_ellipsoid(root, mat, a, Vector3(r, r * 1.06, r * 0.98), Basis())
			continue
		if absf(r0 - r1) < 0.004:
			_cap(root, mat, a, b, (r0 + r1) * 0.5)
			continue
		var mid: Vector3 = a.lerp(b, 0.5)
		_cap(root, mat, a, mid, lerpf(r0, r1, 0.28))
		_cap(root, mat, mid, b, lerpf(r0, r1, 0.76))


## Copper curls: a golden-angle spiral over the upper hemisphere of every head.
## `grow` pushes them out by half the cast blend, because the smooth union swells
## a marched head past the radius the segment declared and a curl set on the bare
## radius would sink inside it.
static func _curls(root: Node3D, mat: StandardMaterial3D, segs: Array,
		rng: RandomNumberGenerator, grow: float) -> void:
	for d_v in segs:
		var d: Dictionary = d_v
		if str(d["tag"]) != "head":
			continue
		var c: Vector3 = d["a"]
		var r: float = float(d["r"])
		var spin: float = rng.randf_range(0.0, TAU)
		for i in range(7):
			var t: float = (float(i) + 0.5) / 7.0
			var phi: float = acos(clampf(1.0 - t * 1.15, -1.0, 1.0))
			var th: float = spin + float(i) * 2.399963
			var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var cr: float = r * rng.randf_range(0.30, 0.42)
			_ellipsoid(root, mat, c + dir * (r * 0.88 + grow + cr * 0.35),
				Vector3(cr, cr * 0.86, cr), Basis(Vector3.UP, th))


## Where the putti ride. They are TIED to the spire by a wisp of cloth, because a
## statue cannot float anything — the reference's hovering putti become putti
## carried, which is what a sculptor does with them anyway.
static func _putti_places(rng: RandomNumberGenerator, spire: Array) -> Array:
	var out: Array = []
	var top: Dictionary = spire[spire.size() - 1]
	var tc: Vector3 = top["c"]
	var spin: float = rng.randf_range(0.0, TAU)
	for i in range(3):
		var a: float = spin + TAU * float(i) / 3.0
		var rad: float = rng.randf_range(0.15, 0.21)
		var y: float = tc.y + rng.randf_range(-0.12, 0.10)
		out.append({
			"c": Vector3(tc.x + cos(a) * rad, y, tc.z + sin(a) * rad),
			"anchor": Vector3(tc.x, tc.y - 0.02, tc.z),
			"yaw": a + PI + rng.randf_range(-0.5, 0.5),
			"k": rng.randf_range(0.90, 1.12),
		})
	return out


static func _putto(root: Node3D, flesh: StandardMaterial3D, cloth: StandardMaterial3D,
		copper: StandardMaterial3D, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var c: Vector3 = p["c"]
	var k: float = float(p["k"])
	var b := Basis(Vector3.UP, float(p["yaw"])) * Basis(Vector3.RIGHT, rng.randf_range(-0.4, 0.4))
	_ellipsoid(root, flesh, c, Vector3(0.062, 0.070, 0.058) * k, b)
	var hc: Vector3 = c + b * Vector3(0.0, 0.088 * k, -0.006 * k)
	_ellipsoid(root, flesh, hc, Vector3(0.050, 0.052, 0.048) * k, b)
	for i in range(2):
		var sd: float = -1.0 if i == 0 else 1.0
		var sh: Vector3 = c + b * Vector3(sd * 0.052 * k, 0.036 * k, 0.0)
		var hd: Vector3 = sh + b * Vector3(sd * rng.randf_range(0.05, 0.10) * k,
			rng.randf_range(-0.02, 0.08) * k, rng.randf_range(-0.07, 0.02) * k)
		_cap(root, flesh, sh, hd, 0.020 * k)
		var hp: Vector3 = c + b * Vector3(sd * 0.032 * k, -0.055 * k, 0.0)
		var ft: Vector3 = hp + b * Vector3(sd * rng.randf_range(0.01, 0.06) * k,
			rng.randf_range(-0.09, -0.04) * k, rng.randf_range(-0.02, 0.06) * k)
		_cap(root, flesh, hp, ft, 0.024 * k)
		# a wing: a faceted plate, swept back and up. Wide and short — the first
		# pass ran it long and narrow and three putti sprouted six green blades.
		var pts: Array = []
		for j in range(4):
			var t: float = float(j) / 3.0
			pts.append(c + b * Vector3(sd * (0.04 + 0.075 * t) * k, (0.03 + 0.095 * t) * k,
				(0.03 + 0.075 * t) * k))
		_strap(root, cloth, pts, 0.074 * k, 0.008 * k, 0.0, 0.40)
	# the wisp that ties it back to the spire — three rungs, so it curves
	var an: Vector3 = p["anchor"]
	var wisp: Array = [an, an.lerp(c, 0.5) + Vector3(0.0, -0.05, 0.0), c + b * Vector3(0.0, -0.03, 0.0)]
	_strap(root, cloth, wisp, 0.030, 0.012, 0.5, 0.7)
	var spin: float = rng.randf_range(0.0, TAU)
	for i in range(4):
		var th: float = spin + float(i) * 2.399963
		var dir := Vector3(sin(0.9) * cos(th), cos(0.9), sin(0.9) * sin(th))
		var cr: float = 0.019 * k
		_ellipsoid(root, copper, hc + dir * (0.050 * k), Vector3(cr, cr * 0.86, cr), Basis())


# ---------------------------------------------------------------------------
# THE HALL — the one dry passage

## A broken column: base block, two drums, the upper one shifted and tilted off the
## lower. Buried to its waist in the heap. Fourteen radial segments, so it reads as
## a turned drum rather than as a cylinder.
static func _column(root: Node3D, mat: StandardMaterial3D, a: float) -> void:
	var d: float = 0.34
	var c := Vector3(cos(a) * d, 0.0, sin(a) * d)
	var base := BoxMesh.new()
	base.size = Vector3(0.30, 0.070, 0.30)
	var bm: MeshInstance3D = _add(root, base, mat)
	bm.transform = Transform3D(Basis(Vector3.UP, a * 0.5), c + Vector3(0.0, 0.035, 0.0))
	var d1 := CylinderMesh.new()
	d1.top_radius = 0.125
	d1.bottom_radius = 0.135
	d1.height = 0.34
	d1.radial_segments = 14
	d1.rings = 1
	var m1: MeshInstance3D = _add(root, d1, mat)
	m1.transform = Transform3D(Basis(), c + Vector3(0.0, 0.24, 0.0))
	var d2 := CylinderMesh.new()
	d2.top_radius = 0.108
	d2.bottom_radius = 0.122
	d2.height = 0.28
	d2.radial_segments = 14
	d2.rings = 1
	var m2: MeshInstance3D = _add(root, d2, mat)
	m2.transform = Transform3D(Basis(Vector3.BACK, 0.16) * Basis(Vector3.UP, 0.4),
		c + Vector3(0.03, 0.55, -0.02))


# ---------------------------------------------------------------------------
# materials and painted marks

## Cloth: a DreamSkin finish carrying the damask as albedo in world triplanar, so
## one pattern runs unbroken across eight separate lobes. Both caps are the corpus's
## own: a lobe at metallic 1.0 photographs black in a bare capture, and paint under
## a strong emission stops reading as paint.
static func _cloth_mat(finish: String, base: Color, tex: ImageTexture, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, base, rng)
	m.albedo_color = base
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.5
	m.uv1_scale = Vector3(5.0, 5.0, 5.0)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	m.metallic = minf(m.metallic, 0.60)
	m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.50)
	return m


## A damask: an ogee lattice with a lozenge at every node, plus a fine weave the
## flat facets can catch. The reference's cloth is plain — the pattern is here
## because a faceted volume has no silhouette left to carry a mark, so the mark has
## to live on the surface.
##
## IT IS DRAWN IN TONES OF THE CLOTH'S OWN COLOUR, NOT IN INK, AND THAT COST A
## CAPTURE. The first version put a near-black thread at |lattice| < 0.085 and a
## contrasting lozenge at every node, at uv1_scale 1.6 — which on a 0.4 m lobe is
## about four repeats across the whole mound. The heap photographed as a stack of
## beach balls printed with a cell diagram, and the folds under it could not be
## seen at all, because a mark with more contrast than the shading wins. So the
## lattice is now a shade of the cloth, the ink is a THREAD at a tenth of the
## width, and the scale is fine enough to read as weave rather than as pattern.
static func _paint_damask(rng: RandomNumberGenerator, motif: Color, ink: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var reps: float = float(rng.randi_range(2, 3))
	var ground: Color = Color(0.97, 0.96, 0.95)
	var thread: Color = ground.lerp(ink, 0.30)
	var node: Color = ground.lerp(motif, 0.34)
	for y in range(TEX):
		for x in range(TEX):
			var u: float = float(x) / float(TEX) * reps
			var v: float = float(y) / float(TEX) * reps
			var lat: float = sin(PI * u * 2.0) * sin(PI * v * 2.0)
			var d: float = absf(lat)
			var c: Color = ground
			if d < 0.025:
				c = thread                   # the lattice thread, one pixel of it
			elif d > 0.90:
				c = node if lat > 0.0 else ground.lerp(motif, 0.18)
			# a weave, so a flat facet is not a flat colour
			var g: float = 0.965 + 0.035 * sin(float(x) * 1.9 + sin(float(y) * 0.31) * 2.2)
			img.set_pixel(x, y, Color(clampf(c.r * g, 0.0, 1.0), clampf(c.g * g, 0.0, 1.0),
				clampf(c.b * g, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## Limestone: horizontal bedding, chalk speckle, one darker seam. Dry on purpose —
## this is the passage the wet ones are measured against.
static func _paint_stone(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var seam: int = rng.randi_range(20, TEX - 20)
	for y in range(TEX):
		var bed: float = 0.055 * sin(float(y) * 0.27) + 0.03 * sin(float(y) * 0.061)
		var near: float = clampf(1.0 - absf(float(y - seam)) / 7.0, 0.0, 1.0)
		for x in range(TEX):
			var speck: float = rng.randf_range(-0.045, 0.045)
			var v: float = clampf(0.90 + bed + speck - near * 0.22, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v * 0.995, v * 0.975))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# geometry helpers (the neighbours' idiom — nana_gloss.gd, david_drape.gd)

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ellipsoid(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 20
	sph.rings = 11
	var mi: MeshInstance3D = _add(root, sph, mat)
	# NOTE Basis.scaled() is diag * B (parent frame), which on a sphere cancels the
	# rotation outright. The squash has to happen in the ellipsoid's OWN frame.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _cap(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r: float) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.008)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	cap.rings = 5
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var axv: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(axv, ang)


static func _rescale(root: Node3D, k: float) -> void:
	if absf(k - 1.0) < 0.0001:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), tf.origin * k)


static func _shift(root: Node3D, v: Vector3) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + v)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var wb: AABB = cm.transform * cm.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
