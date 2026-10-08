extends RefCounted

## dream_bodies / obi_frieze — the CHORUS. Not one kimono figure but four to six
## of them standing together, cloth built as stiff swung PLANES, hair as one
## lacquer volume, faces powdered chalk.
##
## Reference: C:/Users/palle/Documents/FinalMD/m1/0_1288-0000.jpg (4096x1072
## panorama) — a frieze of kimono figures against clipped bonsai pines. Indigo
## and white floral cloth, one figure in navy polka dots, one in pale outlined
## lotus, wide gold and violet obi sashes with long straps hanging down the
## front, sleeves swung out into stiff flat planes that overlap the neighbour,
## lacquer-black sculpted hair with yellow ornaments, pale powdered faces. The
## figures crowd: they overlap, they face different ways, and no two wear the
## same print.
##
## hokusai_kimono already owns ONE such figure, wave-patterned, caught mid-turn,
## its robe a single SurfaceTool loft. This family owns the crowd, and it argues
## the opposite way about cloth: not a lofted tube but FOLDED CARD. Every scrap
## of silk here is a tapered rectangular PLANK, and the whole grammar is one
## helper — see `_plank`, twelve hand-wound triangles that flare from one end to
## the other. That single primitive builds the skirt, the torso, the front panel,
## the crossed collar, the obi, its straps, its knot, and every sleeve of every
## value below. Its header records what it cost to get there: the primitive-mesh
## version of it measured 41% too big and the settle silently shrank the whole
## frieze to three quarters of its build height.
##
## Reproduced, and how:
##   1. The column — skirt plank flaring from the shoulder width down to a wide
##      hem, torso plank flaring back OUT to square kimono shoulders. Two planks
##      and the silhouette is already a kimono.
##   2. The front opening — two panels of a contrasting solid gloss laid down the
##      front, cut apart at the sash the way an okumi is, and two collar planks
##      crossing over them in a V that stands clear of the throat. The
##      reference's most legible cloth event, and the fussiest block in the file:
##      see the clearance note in _figure.
##   3. The obi — one wide band at the waist in gold or violet, a knot bar and
##      tail at the back, and two long straps hanging down the front to the knee.
##      The straps are what make the sash read as a sash and not a belt.
##   4. Printed cloth, painted in code — four 128x128 ImageTextures dealt per
##      FIGURE, never per family, because in the reference no two women wear the
##      same print: big outlined blossoms, line-drawn lotus leaves on a pale
##      ground, a staggered dot, and an eight-point lattice star. World triplanar,
##      so one bolt runs across every plank of one body without a UV map.
##   5. Lacquer hair as a solid VOLUME — a flattened crown ellipsoid, two side
##      wings, a bun behind, and one gold kanzashi pin, all in patent near-black.
##      Sculpted mass, not strands: that is what the photograph shows.
##   6. A seed is an individual — each figure's print kind, ground, petal colour,
##      finish, sash colour, hair size, yaw and stature are dealt separately, so
##      a chorus is a crowd rather than a repeat.
##
## THE ONE MATTE PASSAGE: the FACE AND NECK, powdered chalk (Gloss "matte",
## roughness 0.92). Everything else on the statue is wet — latex, patent, candy,
## holo, oil slick silk; lacquer hair; a lacquered vermilion plinth. That is the
## reference's own argument, not a rule obeyed: the whole point of the white
## powdered face is that it is the one dry thing above a body of glossy silk, and
## a wet body only reads wet next to a dry one. The plinth is deliberately NOT
## matte here (most families in this corpus make it their dry element) — a
## lacquer tray under lacquer hair, so the chalk stands alone.
##
## Given up: the clipped bonsai pines and the black garden behind them (this is a
## statue, not a diorama), hands and fingers — the furisode swallows them, as it
## nearly does in the photograph — and faces past a chalk ovoid: the reference's
## painted eyes and mouths would make these portraits, and the family wants
## bodies as forms.
##
## AXES — two, and both cut the SILHOUETTE, because the evidence is one still
## photograph and an axis that changes a rate is worthless:
##   chorus — how the crowd stands. "rank" is the reference: five figures in a
##            straight row, shoulders overlapping. "ring" turns six outward on a
##            circle so the statue has no back. "spiral" stacks four climbing and
##            turning, each hem over the head below, and the frieze becomes a
##            twisted column. "cascade" drops the stature along the row so the
##            heads run a diagonal and the hems stay on the ground. "huddle"
##            leans five inward until the heads meet over the centre and the
##            hems splay — a bar, a block, a column, a staircase, an A.
##   sleeve — what the cloth does at the shoulder. "swung" is the reference's
##            stiff plane plus its hanging drop; "furled" takes it away and
##            leaves a plain pillar; "fanned" splays four broad blades across the
##            shoulder wedge; "shredded" fills the SAME wedge with seven narrow
##            strips at ragged lengths; "winged" lifts the planes above the
##            shoulder and folds them back.
##
## PREDICTED CLOSEST PAIR — see predicted(). fanned and shredded are built into
## the same wedge ON PURPOSE, at two densities, so the family carries its own
## closest pair rather than hoping one turns up. Everything else in either axis
## moves whole figures.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const TEX: int = 128
const PLINTH_TOP: float = 0.055

## One figure's own height, hem to the top of the hair, before a stand scales it.
## The chorus is then laid out to keep the merged box inside 1.20 x 1.68 without
## the settle having to shrink it much — a frieze that gets scaled to fit is a
## frieze that lands under the probe's 0.9 m floor.
const H: float = 1.52

const K_FLORAL: int = 0
const K_LEAF: int = 1
const K_DOT: int = 2
const K_LATTICE: int = 3

# silk: never "matte" (the face owns that), never "neon" under a print
const CLOTH_FIN: Array[String] = ["latex", "patent", "candy", "wet", "pearl", "holo",
	"oilslick"]
# the sash is brocade — it may mirror, because it is small enough that a dark
# reflection reads as depth rather than as a hole
const SASH_FIN: Array[String] = ["patent", "chrome", "holo", "candy", "oilslick"]

const INDIGOS: Array = ["#16306B", "#1B3F87", "#0E2350", "#22346F", "#1A2E63"]
const PALES: Array = ["#F1F0EA", "#E6EDF2", "#EFE9E0", "#E8E4DC"]
const NAVYS: Array = ["#101A3A", "#16224A", "#0C1430"]
const PETALS: Array = ["#F4F2EC", "#F0C7D6", "#E8829F", "#CFE3E6", "#D9B64C"]
const LEAFY: Array = ["#2E7F86", "#3F8F7A", "#6F94B8", "#8A5FA6"]
const GOLDS: Array = ["#C9A227", "#D9B64C", "#A9812A"]
const VIOLETS: Array = ["#7C4FA0", "#8E5AA8", "#5B2A78"]

const CHALK: Color = Color(0.945, 0.925, 0.900)
const LACQUER: Color = Color(0.070, 0.058, 0.095)
const PLINTH_LACQUER: Color = Color(0.42, 0.075, 0.095)


static func describe() -> String:
	return "A frieze of kimono figures standing together, their silk built as stiff swung planes over wide gold and violet obi, lacquer-black hair above one chalk-matte powdered face each."


static func axes() -> Dictionary:
	return {
		"chorus": ["rank", "ring", "spiral", "cascade", "huddle"],
		"sleeve": ["swung", "furled", "fanned", "shredded", "winged"],
	}


## Named pair, number, arithmetic — BEFORE the capture, so the sweep has
## something it can disagree with. A prediction that agrees is worth nothing.
static func predicted() -> Dictionary:
	return {
		"pair": "sleeve: fanned vs shredded (any chorus)",
		"predicted_pct": 4.5,
		"reasoning": "the two values are built into the SAME shoulder wedge on purpose - +14 to -70 degrees, radius 0.30 to 0.38 - and differ only in how densely it is filled: 4 blades 10.4 cm wide against 7 shreds 4.4 cm wide. Along the wedge's outer arc (0.50 m at r = 0.34) that is 0.416 m covered against 0.308 m, so 83% fill against 62%, a difference of 21% of a wedge whose area is 0.5 * 0.34^2 * 1.47 rad = 0.085 m2. That is 0.018 m2 per side, x2 sides x5 figures = 0.18 m2, of which perhaps 80% lands over background or over a neighbour printed in another colour and so actually changes a pixel: 0.14 m2. TWO denominators follow and both are traps. The frieze's filled silhouette is about 65% of its 1.20 x 1.37 m box = 1.07 m2, so this is 13% of the BODY. And this subject is a dense row rather than one slender figure, so call it 35% of the frame: 13% x 35% = 4.5% of the picture. Note the shape of the claim - every OTHER pair in either axis moves whole limbs or whole figures and should land far above this; if the sweep's peak is near 4.5% something is wrong with the capture, not with the axes.",
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var chorus: String = String(opts.get("chorus", "rank"))
	var sleeve: String = String(opts.get("sleeve", "swung"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- where the crowd stands ----------------------------------------------
	var stands: Array = _stands(chorus, rng)

	# --- and who each of them is ---------------------------------------------
	for st_v in stands:
		var st: Dictionary = st_v
		var i0: int = root.get_child_count()
		_figure(root, rng, _wardrobe(rng, sleeve))
		var s: float = float(st["scale"])
		var pos: Vector3 = st["pos"]
		var tf := Transform3D(
			Basis(Vector3.BACK, float(st["lean"])) * Basis(Vector3.UP, float(st["yaw"]))
				* _diag(Vector3(s, s, s)),
			pos)
		_xform_range(root, i0, tf)

	# --- the measured settle, copied from nana_gloss --------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = (1.68 - PLINTH_TOP) / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_rescale(root, kfit, Vector3.ZERO)
		box = _union_aabb(root)

	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, PLINTH_TOP - box.position.y, -centre.z)
	_shift(root, shift)
	box = _union_aabb(root)
	if box.position.y < 0.0:
		_shift(root, Vector3(0.0, -box.position.y, 0.0))
		box = _union_aabb(root)

	# The tray. Lacquer, NOT matte — the chalk faces are this statue's one dry
	# passage and a matte plinth would halve the contrast they exist to make.
	var slab := BoxMesh.new()
	slab.size = Vector3(minf(1.20, box.size.x + 0.10), PLINTH_TOP,
		minf(1.20, box.size.z + 0.10))
	var pm: MeshInstance3D = _add(root, slab,
		Gloss.skin("patent", PLINTH_LACQUER, rng))
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# THE CHORUS AXIS — five ways for a crowd to stand
#
# Each entry is a stand: where a figure's FEET go, which way it faces, how far it
# leans, and how tall it is. Every value keeps four to six figures, because a
# chorus of one is hokusai_kimono and this family would have no argument left.

static func _stands(chorus: String, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	match chorus:
		"ring":
			# six turned outward on a circle: the frieze with no back, which is
			# the one arrangement a museum visitor can walk all the way around
			var n: int = 6
			var rad: float = 0.250
			var phase: float = rng.randf_range(0.0, TAU)
			for i in range(n):
				var a: float = phase + TAU * float(i) / float(n)
				out.append({
					"pos": Vector3(sin(a) * rad, 0.0, cos(a) * rad),
					# a figure is modelled facing -Z, so facing OUTWARD along
					# (sin a, 0, cos a) needs a yaw of a + PI, not a
					"yaw": a + PI + rng.randf_range(-0.10, 0.10),
					"lean": 0.0,
					"scale": rng.randf_range(0.90, 1.00),
				})
		"spiral":
			# four climbing and turning, each hem falling over the head below
			var n2: int = 4
			for i in range(n2):
				var t: float = float(i)
				var a2: float = 1.34 * t + rng.randf_range(-0.10, 0.10)
				var sc: float = 1.0 - 0.090 * t
				out.append({
					"pos": Vector3(sin(a2) * 0.130, 0.235 * t, cos(a2) * 0.130),
					"yaw": a2 + PI + 0.55,
					"lean": rng.randf_range(-0.05, 0.05),
					"scale": sc,
				})
		"cascade":
			# a row whose stature falls away, so the hems hold the ground and the
			# heads run a diagonal
			var n3: int = 5
			var scs: Array[float] = []
			for i in range(n3):
				scs.append(1.0 - 0.095 * float(i) + rng.randf_range(-0.02, 0.02))
			var xs: Array[float] = []
			var x: float = 0.0
			for i in range(n3):
				if i > 0:
					x += 0.182 * (scs[i - 1] + scs[i]) * 0.5
				xs.append(x)
			var mid: float = (xs[0] + xs[n3 - 1]) * 0.5
			for i in range(n3):
				out.append({
					"pos": Vector3(xs[i] - mid, 0.0, -0.035 * float(i)),
					"yaw": rng.randf_range(-0.20, 0.20) - 0.16,
					"lean": 0.0,
					"scale": scs[i],
				})
		"huddle":
			# five leaning in until the heads meet: the row becomes an A
			var n4: int = 5
			for i in range(n4):
				var xo: float = (float(i) - 2.0) * 0.172
				var lean: float = xo * 0.70
				var zig: float = 0.055 if i % 2 == 0 else -0.055
				out.append({
					# leaning about the foot dips the outer hem corner below the
					# floor; drop the stand by that much so the settle is not
					# left lifting the whole crowd off its own plinth
					"pos": Vector3(xo, -0.108 * absf(sin(lean)), zig),
					"yaw": rng.randf_range(-0.18, 0.18),
					"lean": lean,
					"scale": rng.randf_range(0.94, 1.02),
				})
		_:
			# "rank" — the reference. Five in a straight line, close enough that
			# the sleeves overlap the neighbour, which is what makes it a frieze
			# and not five statues.
			var n5: int = 5
			for i in range(n5):
				out.append({
					"pos": Vector3((float(i) - 2.0) * 0.172, 0.0,
						rng.randf_range(-0.055, 0.055)),
					"yaw": rng.randf_range(-0.26, 0.26),
					"lean": rng.randf_range(-0.035, 0.035),
					"scale": rng.randf_range(0.93, 1.02),
				})
	return out


# ---------------------------------------------------------------------------
# one figure's wardrobe — dealt per FIGURE, so the crowd is a crowd

static func _wardrobe(rng: RandomNumberGenerator, sleeve: String) -> Dictionary:
	var kind: int = rng.randi_range(0, 3)
	var ground: Color
	var ink := Color(0.055, 0.050, 0.070)
	var petal: Color = Color(str(PETALS[rng.randi_range(0, PETALS.size() - 1)]))
	var leafy: Color = Color(str(LEAFY[rng.randi_range(0, LEAFY.size() - 1)]))
	if kind == K_LEAF:
		ground = Color(str(PALES[rng.randi_range(0, PALES.size() - 1)]))
		ink = Color(0.32, 0.40, 0.52)
	elif kind == K_DOT:
		ground = Color(str(NAVYS[rng.randi_range(0, NAVYS.size() - 1)]))
		petal = Color(str(PALES[rng.randi_range(0, PALES.size() - 1)]))
	else:
		ground = Color(str(INDIGOS[rng.randi_range(0, INDIGOS.size() - 1)]))
	# one figure in five wears a colour off the queer palette instead of indigo,
	# the way the reference plants one teal and one violet robe in the row
	if rng.randf() < 0.22:
		var q: Color = Gloss.queer_colour(rng)
		ground = Color(q.r * 0.62, q.g * 0.62, q.b * 0.66)

	var finish: String = CLOTH_FIN[rng.randi_range(0, CLOTH_FIN.size() - 1)]
	var sash_col: Color = Color(str(GOLDS[rng.randi_range(0, GOLDS.size() - 1)]))
	if rng.randf() < 0.45:
		sash_col = Color(str(VIOLETS[rng.randi_range(0, VIOLETS.size() - 1)]))
	var under: Color = leafy if rng.randf() < 0.55 else petal

	var tex: ImageTexture = _make_cloth(kind, rng, ground, ink, petal, leafy)
	return {
		"sleeve": sleeve,
		"cloth": _dress(finish, ground, tex, rng),
		"under": Gloss.skin(finish, under, rng),
		"collar": Gloss.skin("patent", Color(0.96, 0.95, 0.93).lerp(under, 0.18), rng),
		"sash": _sash_mat(sash_col, rng),
		# the one dry passage on the statue
		"chalk": Gloss.skin("matte", CHALK),
		"hair": Gloss.skin("patent", LACQUER, rng),
		"pin": Gloss.skin("chrome", Color(str(GOLDS[rng.randi_range(0, GOLDS.size() - 1)])), rng),
		"hair_r": rng.randf_range(0.066, 0.082),
		"hem": rng.randf_range(0.100, 0.116),
		"turn": rng.randf_range(-0.22, 0.22),
	}


## Printed silk: a DreamSkin finish carrying the code-painted bolt as albedo, in
## world triplanar so the print runs unbroken across a dozen separate planks with
## no UV map anywhere. The two caps are the corpus's own: a body at metallic 1.0
## photographs BLACK with nothing to reflect, and a print under a strong emission
## stops reading as a print.
static func _dress(finish: String, ground: Color, tex: ImageTexture,
		rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, ground, rng)
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.5
	var k: float = rng.randf_range(3.0, 3.8)
	m.uv1_scale = Vector3(k, k, k)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	m.metallic = minf(m.metallic, 0.55)
	m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.45)
	return m


static func _sash_mat(c: Color, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var f: String = SASH_FIN[rng.randi_range(0, SASH_FIN.size() - 1)]
	var m: StandardMaterial3D = Gloss.skin(f, c, rng)
	m.metallic = minf(m.metallic, 0.75)
	return m


# ---------------------------------------------------------------------------
# one figure, built at the origin, facing -Z, hem on y = 0

static func _figure(root: Node3D, rng: RandomNumberGenerator, w: Dictionary) -> void:
	var sleeve: String = String(w["sleeve"])
	var cloth: StandardMaterial3D = w["cloth"]
	var under: StandardMaterial3D = w["under"]
	var collar: StandardMaterial3D = w["collar"]
	var sash: StandardMaterial3D = w["sash"]
	var chalk: StandardMaterial3D = w["chalk"]
	var hair: StandardMaterial3D = w["hair"]
	var pin: StandardMaterial3D = w["pin"]
	var hair_r: float = float(w["hair_r"])
	var hem: float = float(w["hem"])
	var turn: float = float(w["turn"])

	var y_waist: float = 0.500 * H
	var y_sh: float = 0.800 * H
	var y_neck: float = 0.865 * H
	var y_head: float = 0.915 * H
	var y_hair: float = 0.945 * H

	var w_waist: float = 0.070
	var w_sh: float = 0.092
	var d_hem: float = 0.072
	var d_waist: float = 0.052
	var d_sh: float = 0.058

	var up := Vector3.BACK          # the ref that keeps a vertical plank's sheet facing front

	# --- the column: two planks and it is already a kimono --------------------
	_plank(root, cloth, Vector3(0.0, 0.0, 0.010), Vector3(0.0, y_waist + 0.02 * H, 0.0),
		hem, w_waist / hem, d_hem, up)
	_plank(root, cloth, Vector3(0.0, y_waist, 0.0), Vector3(0.0, y_sh + 0.015 * H, -0.004),
		w_waist, w_sh / w_waist, d_waist, up)

	# --- the front opening: the reference's most legible cloth event ----------
	#
	# EVERY z HERE IS A CLEARANCE, NOT A STYLE CHOICE, and they are the reason
	# this block is the fussiest in the file. The column flares in THICKNESS as
	# well as width — the torso plank is 0.052 deep at the waist and 0.068 at the
	# shoulder — so a panel laid at a constant depth is proud at one end and
	# swallowed at the other. Buried is the dangerous half: it costs nothing, it
	# throws nothing, the mesh count is unchanged, and the statue photographs with
	# no front opening at all. fetish_idol lost its collar inside its own chest
	# exactly this way. So each layer is placed to clear the FRONT FACE of what is
	# behind it at BOTH of its ends: body -> panel -> collar -> obi -> straps, each
	# a few millimetres further out than the last.
	#
	# The panel is also cut in two at the sash rather than run through it. A
	# kimono's okumi is interrupted by the obi, and a single panel long enough to
	# span the waist would have to sit in front of the sash to avoid slicing it.
	_plank(root, under,
		Vector3(0.008, 0.045 * H, -(d_hem * 1.00)),
		Vector3(0.008, y_waist + 0.005 * H, -(d_waist * 1.05)),
		0.055, 0.80, 0.009, up)
	_plank(root, under,
		Vector3(0.008, y_waist + 0.105 * H, -(d_waist * 1.10)),
		Vector3(0.008, y_sh - 0.010, -(d_sh * 1.10)),
		0.050, 0.86, 0.009, up)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		# The collar stands OFF the throat, which is not a compromise — a kimono
		# collar does, and it is what lets the chalk neck read behind it. It stops
		# just above the sash rather than under it, so the two never overlap.
		_plank(root, collar,
			Vector3(sd * 0.010, y_neck - 0.018, -(d_sh * 1.35)),
			Vector3(sd * 0.056, y_waist + 0.118 * H, -(d_waist * 1.60)),
			0.021, 0.85, 0.012, up)

	# --- the obi: a band, a knot at the back, two straps down the front -------
	_plank(root, sash, Vector3(0.0, y_waist - 0.012 * H, 0.0),
		Vector3(0.0, y_waist + 0.100 * H, -0.002),
		w_waist * 1.20, 1.02, d_waist * 1.45, up)
	# The knot bar runs along X, so its `ref` still has to be BACK: ref crossed
	# with the axis is what picks the WIDE direction, and passing UP here would
	# have quietly turned the bow through 90 degrees into a shelf sticking out of
	# the small of the back — correct geometry, wrong object, and nothing in the
	# pipeline would have objected.
	_plank(root, sash,
		Vector3(-0.056, y_waist + 0.055 * H, d_waist * 1.30),
		Vector3(0.056, y_waist + 0.055 * H, d_waist * 1.30),
		0.044, 0.94, 0.014, up)
	_plank(root, sash,
		Vector3(0.0, y_waist + 0.045 * H, d_waist * 1.34),
		Vector3(0.010, y_waist - 0.120 * H, d_waist * 1.12),
		0.030, 0.70, 0.010, up)
	for s_j in range(2):
		var sj: float = -1.0 if s_j == 0 else 1.0
		# the straps hang FREE of the skirt, 3 cm proud of it, which is what they
		# do in the photograph and what stops them reading as painted stripes
		_plank(root, sash,
			Vector3(sj * 0.024, y_waist + 0.020 * H, -(d_waist * 1.95)),
			Vector3(sj * 0.034, 0.110 * H, -(d_hem * 1.30)),
			0.019, 0.80, 0.007, up)

	# --- sleeves: the axis --------------------------------------------------
	for s_k in range(2):
		var sk: float = -1.0 if s_k == 0 else 1.0
		_sleeve(root, cloth, under, sleeve, Vector3(sk * w_sh * 0.94, y_sh, -0.004), sk, rng)

	# --- neck, face, hair ----------------------------------------------------
	# CHALK, and only here. See the header: the one dry passage on the statue.
	_rod(root, chalk, Vector3(0.0, y_sh - 0.010, 0.004), Vector3(0.0, y_neck + 0.012, -0.004), 0.022)
	var head_b: Basis = Basis(Vector3.UP, turn)
	_ellipsoid(root, chalk, Vector3(0.0, y_head, -0.006), Vector3(0.052, 0.061, 0.055), head_b)

	_ellipsoid(root, hair, Vector3(0.0, y_hair, 0.012),
		Vector3(hair_r, hair_r * 0.86, hair_r * 1.04), head_b)
	for s_l in range(2):
		var sl: float = -1.0 if s_l == 0 else 1.0
		_ellipsoid(root, hair, Vector3(sl * hair_r * 0.82, y_head + 0.014, 0.008),
			Vector3(hair_r * 0.42, hair_r * 0.62, hair_r * 0.66), head_b)
	_ellipsoid(root, hair, Vector3(0.0, y_hair + 0.036, 0.058),
		Vector3(hair_r * 0.60, hair_r * 0.48, hair_r * 0.52), head_b)
	_rod(root, pin, Vector3(0.014, y_hair + 0.022, 0.030),
		Vector3(0.088, y_hair + 0.062, 0.020), 0.0055)


# ---------------------------------------------------------------------------
# THE SLEEVE AXIS
#
# `ref` is Vector3.BACK for every plank here, which is the whole trick: with the
# arm running out and down in the XY plane, back-cross-axis puts the plank's WIDE
# axis in that same plane and its thin axis along Z. So a sleeve is a sheet facing
# the viewer, not a tube — which is what the photograph shows and what a
# BoxMesh scaled by a general basis cannot taper into.
#
# "fanned" and "shredded" are deliberately built into the SAME wedge — 14 degrees
# above horizontal to 74 below, radius 0.30 to 0.44 — and differ only in blade
# width and count. That is the family's own predicted closest pair; see
# predicted(). Every other pair in either axis moves a whole limb of cloth.

static func _sleeve(root: Node3D, cloth: StandardMaterial3D, under: StandardMaterial3D,
		sleeve: String, sh: Vector3, side: float, rng: RandomNumberGenerator) -> void:
	var up := Vector3.BACK
	match sleeve:
		"furled":
			# the cloth taken away: a plain pillar, arms bound to the column
			_plank(root, cloth,
				sh + Vector3(side * 0.016, -0.014, 0.0),
				sh + Vector3(side * 0.038, -0.480, 0.006),
				0.030, 0.86, 0.020, up)
		"fanned":
			for k in range(4):
				var t: float = float(k) / 3.0
				var a: float = deg_to_rad(lerpf(14.0, -70.0, t))
				var dir := Vector3(side * cos(a), sin(a), -0.05)
				var ln: float = lerpf(0.30, 0.38, t)
				_plank(root, cloth, sh + dir * 0.022, sh + dir * ln, 0.052, 0.84, 0.007, up)
		"shredded":
			for k in range(7):
				var t2: float = float(k) / 6.0
				var a2: float = deg_to_rad(lerpf(16.0, -74.0, t2) + rng.randf_range(-3.5, 3.5))
				var dir2 := Vector3(side * cos(a2), sin(a2), -0.05)
				var ln2: float = rng.randf_range(0.24, 0.40)
				var m: StandardMaterial3D = under if (k % 3) == 1 else cloth
				_plank(root, m, sh + dir2 * 0.020, sh + dir2 * ln2, 0.022, 0.62, 0.005, up)
		"winged":
			_plank(root, cloth,
				sh + Vector3(side * 0.020, 0.000, 0.004),
				sh + Vector3(side * 0.200, 0.190, 0.052),
				0.085, 0.80, 0.008, up)
			_plank(root, cloth,
				sh + Vector3(side * 0.192, 0.172, 0.050),
				sh + Vector3(side * 0.262, -0.100, 0.018),
				0.070, 0.74, 0.008, up)
		_:
			# "swung" — the reference: one stiff plane out from the shoulder and
			# the furisode's long drop hanging off its outer end
			_plank(root, cloth,
				sh + Vector3(side * 0.010, -0.010, 0.0),
				sh + Vector3(side * 0.178, -0.150, -0.014),
				0.098, 0.90, 0.008, up)
			_plank(root, cloth,
				sh + Vector3(side * 0.172, -0.222, -0.012),
				sh + Vector3(side * 0.152, -0.560, 0.000),
				0.076, 0.78, 0.008, up)


# ---------------------------------------------------------------------------
# geometry helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


## A frame with Y along `axis` and X in the plane that `ref` is normal to. The
## fallbacks matter: ref parallel to axis gives a zero cross product and a basis
## of NaNs, which shows up as a mesh that has simply vanished from the frame.
static func _orient(axis: Vector3, ref: Vector3) -> Basis:
	var y: Vector3 = axis.normalized()
	var x: Vector3 = ref.cross(y)
	if x.length() < 0.0001:
		x = Vector3.RIGHT.cross(y)
	if x.length() < 0.0001:
		x = Vector3.FORWARD.cross(y)
	x = x.normalized()
	var z: Vector3 = x.cross(y)
	return Basis(x, y, z)


## THE FAMILY'S ONE PRIMITIVE: a tapered rectangular sheet of cloth from `a` to
## `b`, `hw` half-wide across the sheet, `ht` half-thick through it, narrowing to
## `taper` of both at b. Eight corners, six quads, twelve triangles.
##
## IT WAS A PRIMITIVE MESH FIRST AND THE SETTLE ATE THE STATUE. A BoxMesh cannot
## taper — a linear map takes parallel edges to parallel edges, and a kimono
## flares — so the first version used a 4-segment CylinderMesh (a square section
## with independent top and bottom radii) turned 45 degrees so the section was
## axis-aligned, then scaled. It rendered correctly and it measured WRONG:
## AABB.merge in the settle reads mesh.get_aabb(), and a 4-segment cylinder's own
## box is the [-r, r] SQUARE that circumscribes its diamond section. Turn that
## box 45 degrees and it grows by sqrt(2) in both cross-section axes — so every
## plank reported itself 41% too wide and too thick, the merged box came out
## 1.54 m across, and the settle shrank the whole frieze by 0.78 to fit 1.20.
## probe_dream_bodies measured the result at 1.16 m tall where the build asks for
## 1.42, and reported PASS: nothing was broken, the statue was just quietly a
## quarter smaller than every neighbour on the hall floor.
##
## So the cloth is wound by hand. SurfaceTool gives exact corners, an exact AABB,
## flat per-face normals (stiffened silk is not smooth), and 12 triangles instead
## of 16.
static func _plank(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3,
		hw: float, taper: float, ht: float, ref: Vector3) -> MeshInstance3D:
	var v: Vector3 = b - a
	if v.length() < 0.0005:
		return null
	var bs: Basis = _orient(v, ref)
	var ax: Vector3 = bs.x
	var az: Vector3 = bs.z
	var t: float = maxf(taper, 0.02)
	var hw2: float = hw * t
	var ht2: float = ht * t
	# two rings of four, each cyclic about the plank's axis
	var q0: Vector3 = a + ax * hw + az * ht
	var q1: Vector3 = a - ax * hw + az * ht
	var q2: Vector3 = a - ax * hw - az * ht
	var q3: Vector3 = a + ax * hw - az * ht
	var q4: Vector3 = b + ax * hw2 + az * ht2
	var q5: Vector3 = b - ax * hw2 + az * ht2
	var q6: Vector3 = b - ax * hw2 - az * ht2
	var q7: Vector3 = b + ax * hw2 - az * ht2
	var mid: Vector3 = (a + b) * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_face(st, q3, q2, q1, q0, mid)
	_face(st, q4, q5, q6, q7, mid)
	_face(st, q0, q1, q5, q4, mid)
	_face(st, q1, q2, q6, q5, mid)
	_face(st, q2, q3, q7, q6, mid)
	_face(st, q3, q0, q4, q7, mid)
	return _add(root, st.commit(), mat)


## One quad of cloth, its corners given cyclically. The outward direction is not
## guessed from the argument order — it is taken from the quad's own plane and
## then pointed away from the plank's centre, which is a fact the geometry knows
## and a comment cannot get wrong.
static func _face(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		mid: Vector3) -> void:
	var n: Vector3 = (p1 - p0).cross(p2 - p0)
	if n.length_squared() < 1.0e-14:
		return
	n = n.normalized()
	if n.dot((p0 + p1 + p2 + p3) * 0.25 - mid) < 0.0:
		n = -n
	_tri(st, p0, p1, p2, n)
	_tri(st, p0, p2, p3, n)


## GODOT WINDS FRONT FACES CLOCKWISE: the face normal it derives from a triangle
## is (a - c) x (a - b), the NEGATIVE of the textbook cross product. Written the
## textbook way every plank in the frieze comes out inside out — which a render
## that draws back faces will not show you, and a render that does not will show
## as a body full of holes. So the order is decided by asking, not by remembering.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var second: Vector3 = b
	var third: Vector3 = c
	if (a - c).cross(a - b).dot(n) < 0.0:
		second = c
		third = b
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(second)
	st.set_normal(n)
	st.add_vertex(third)


static func _ellipsoid(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3,
		b: Basis) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 18
	sph.rings = 10
	var mi: MeshInstance3D = _add(root, sph, mat)
	# Basis.scaled() is diag * B in the PARENT frame, which on a sphere cancels
	# the rotation outright. The squash has to happen in the ellipsoid's own frame.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _rod(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3,
		r: float) -> MeshInstance3D:
	var v: Vector3 = b - a
	var l: float = v.length()
	if l < 0.0005:
		return null
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = l
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_orient(v, Vector3.BACK), (a + b) * 0.5)
	return mi


static func _xform_range(root: Node3D, i0: int, tf: Transform3D) -> void:
	var kids: Array = root.get_children()
	for i in range(i0, kids.size()):
		var ch: Node = kids[i]
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = tf * cm.transform


static func _rescale(root: Node3D, k: float, pivot: Vector3) -> void:
	if absf(k - 1.0) < 0.0001:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)),
			pivot + (tf.origin - pivot) * k)


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


# ---------------------------------------------------------------------------
# the bolt of cloth — every pixel drawn in code, one per figure

static func _make_cloth(kind: int, rng: RandomNumberGenerator, ground: Color, ink: Color,
		petal: Color, leafy: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	if kind == K_LEAF:
		_paint_leaf(img, rng, ground, ink, leafy)
	elif kind == K_DOT:
		_paint_dot(img, rng, ground, petal, ink)
	elif kind == K_LATTICE:
		_paint_lattice(img, rng, ground, petal, ink)
	else:
		_paint_floral(img, rng, ground, petal, leafy, ink)
	return ImageTexture.create_from_image(img)


## Wrapping write. Every stamp below runs off the edge and has to come back on
## the other side, or the print carries a seam down every plank.
static func _put(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _disc_px(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	var ri: int = int(ceil(r)) + 1
	var x0: int = int(round(cx))
	var y0: int = int(round(cy))
	for y in range(-ri, ri + 1):
		for x in range(-ri, ri + 1):
			if float(x * x + y * y) <= r * r:
				_put(img, x0 + x, y0 + y, c)


static func _line_px(img: Image, x0: float, y0: float, x1: float, y1: float, th: float,
		c: Color) -> void:
	var dx: float = x1 - x0
	var dy: float = y1 - y0
	var n: int = int(ceil(maxf(absf(dx), absf(dy)))) + 1
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		_disc_px(img, x0 + dx * t, y0 + dy * t, th, c)


static func _paint_floral(img: Image, rng: RandomNumberGenerator, ground: Color,
		petal: Color, leafy: Color, ink: Color) -> void:
	img.fill(ground)
	var n: int = rng.randi_range(5, 7)
	for i in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var r: float = rng.randf_range(11.0, 17.0)
		var pets: int = rng.randi_range(5, 6)
		var spin: float = rng.randf_range(0.0, TAU)
		var pc: Color = petal if rng.randf() < 0.74 else leafy
		# outline first, then the petal on top — the reference's blossoms are all
		# drawn with a contour, which is what stops them dissolving into the ground
		for pass_i in range(2):
			var grow: float = 1.8 if pass_i == 0 else 0.0
			var col: Color = ink if pass_i == 0 else pc
			for k in range(pets):
				var a: float = spin + TAU * float(k) / float(pets)
				_disc_px(img, cx + cos(a) * r * 0.60, cy + sin(a) * r * 0.60,
					r * 0.48 + grow, col)
		_disc_px(img, cx, cy, r * 0.28 + 1.6, ink)
		_disc_px(img, cx, cy, r * 0.28, leafy)
	for i in range(rng.randi_range(7, 13)):
		var bx: float = rng.randf_range(0.0, float(TEX))
		var by: float = rng.randf_range(0.0, float(TEX))
		var br: float = rng.randf_range(2.0, 4.2)
		_disc_px(img, bx, by, br + 1.2, ink)
		_disc_px(img, bx, by, br, petal)


static func _paint_leaf(img: Image, rng: RandomNumberGenerator, ground: Color, ink: Color,
		leafy: Color) -> void:
	img.fill(ground)
	var n: int = rng.randi_range(7, 10)
	for i in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(0.0, PI)
		var lr: float = rng.randf_range(13.0, 22.0)
		var lw: float = lr * rng.randf_range(0.34, 0.52)
		var dir := Vector2(cos(ang), sin(ang))
		var per := Vector2(-dir.y, dir.x)
		var steps: int = 14
		var pa := Vector2.ZERO
		var pb := Vector2.ZERO
		var filled: bool = rng.randf() < 0.30
		for k in range(steps + 1):
			var t: float = -1.0 + 2.0 * float(k) / float(steps)
			var half: float = lw * (1.0 - t * t)
			var base := Vector2(cx, cy) + dir * (lr * t)
			var qa: Vector2 = base + per * half
			var qb: Vector2 = base - per * half
			if filled:
				_line_px(img, qa.x, qa.y, qb.x, qb.y, 1.0, leafy)
			if k > 0:
				_line_px(img, pa.x, pa.y, qa.x, qa.y, 1.3, ink)
				_line_px(img, pb.x, pb.y, qb.x, qb.y, 1.3, ink)
			pa = qa
			pb = qb
		_line_px(img, cx - dir.x * lr * 0.9, cy - dir.y * lr * 0.9,
			cx + dir.x * lr * 0.9, cy + dir.y * lr * 0.9, 1.0, ink)


static func _paint_dot(img: Image, rng: RandomNumberGenerator, ground: Color, dot: Color,
		ink: Color) -> void:
	img.fill(ground)
	# 8 x 8 cells of 16 px, staggered — it divides TEX exactly, so it tiles
	var cell: int = 16
	var cells: int = TEX / cell
	var r: float = rng.randf_range(2.6, 4.0)
	for gy in range(cells):
		for gx in range(cells):
			var ox: float = float(gx) * float(cell) + float(cell) * 0.5
			var oy: float = float(gy) * float(cell) + float(cell) * 0.5
			if gy % 2 == 1:
				ox += float(cell) * 0.5
			_disc_px(img, ox, oy, r, dot)
			if rng.randf() < 0.18:
				_disc_px(img, ox, oy, r * 0.42, ink)


static func _paint_lattice(img: Image, rng: RandomNumberGenerator, ground: Color,
		line: Color, ink: Color) -> void:
	img.fill(ground)
	# 4 x 4 cells of 32 px: an eight-point star in each, so the print is
	# geometric where the florals are organic. 32 divides 128, so it tiles.
	var cell: int = 32
	var cells: int = TEX / cell
	var th: float = rng.randf_range(1.0, 1.7)
	for gy in range(cells):
		for gx in range(cells):
			var ox: float = float(gx) * float(cell)
			var oy: float = float(gy) * float(cell)
			var c: float = float(cell)
			var mx: float = ox + c * 0.5
			var my: float = oy + c * 0.5
			# the cell's own frame
			_line_px(img, ox, oy, ox + c, oy, th, ink)
			_line_px(img, ox, oy, ox, oy + c, th, ink)
			# eight spokes: four to the corners, four to the edge midpoints
			_line_px(img, mx, my, ox, oy, th, line)
			_line_px(img, mx, my, ox + c, oy, th, line)
			_line_px(img, mx, my, ox, oy + c, th, line)
			_line_px(img, mx, my, ox + c, oy + c, th, line)
			_line_px(img, mx, my, mx, oy, th, ink)
			_line_px(img, mx, my, mx, oy + c, th, ink)
			_line_px(img, mx, my, ox, my, th, ink)
			_line_px(img, mx, my, ox + c, my, th, ink)
