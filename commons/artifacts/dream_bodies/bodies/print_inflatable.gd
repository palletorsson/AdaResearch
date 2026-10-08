extends RefCounted

## dream_bodies / print_inflatable — a heap of colossal printed vinyl limbs.
##
## Reference: C:/Users/palle/Documents/FinalMD/m1/0_0703-0000.jpg (4096x1072
## panorama) — building-sized inflatables piled in a stone colonnade. Fat
## tapering tubes and rounded torsos, tangled over and through one another like
## pool toys the size of a portico, every one of them printed: black-and-white
## harlequin shards on the left figure, dense dark snakeskin scales on the black
## central one, green-and-white swirls on the right, pink-and-yellow stripes on
## the mattress in the corner, and loud multicolour op-art on the rest. Puffy,
## welded, seamed, glossy. This builder takes ONE pile and stands it on a plinth.
##
## Reproduced, and how:
##   1. The members — every limb and every torso lobe is a SurfaceTool tube swept
##      along a cubic Bezier on parallel-transported frames, 14-sided rings over
##      40 stations. Nothing here is a stock primitive except the end caps, the
##      welts and the valves, because a pool toy's whole character is in its
##      cross-section and a SphereMesh cannot be made to bag.
##   2. The pile — two fat spindle lobes cross at the middle (the "rounded
##      torsos" of the reference) and 5..7 limbs erupt from them, each leaving
##      the core at its own azimuth and height, winding 1.6..3.4 radians round
##      the column and landing on the plinth, in mid-air, or over the top of the
##      others. Nothing is collision-checked: they cross and pass through one
##      another, which is what a heap does.
##   3. Welded seams — the radius is modulated per welt bay: it swells by the
##      bulge in the middle of a bay and pinches by the cinch AT the weld, and a
##      TorusMesh welt ring sits proud of the pinch. That sausage-link silhouette
##      is the difference between an inflatable and a sausage of clay.
##   4. Printed skin — the tube carries real UVs (u around, v along arclength),
##      so the print runs round the limb the way a printed panel does rather than
##      being projected onto it. The tile count per member is derived from that
##      member's own mean radius against a target cell size in METRES, and it is
##      forced to an integer so the seam wraps — a fractional tile count leaves a
##      visible cut down the length of every tube.
##   5. Two colourways — the same print kind is painted twice from different
##      palette draws, and one or two limbs wear the second, because the
##      reference is a pile of DIFFERENT toys, not one toy repeated.
##   6. Valves — two chrome nozzles on the core, the only hardware in the piece.
##   7. A seed is a pile — limb count, azimuths, heights, curl, twist sign,
##      radii, welt spacing, finish, both palettes, which limbs burst.
##
## Given up: the colonnade itself (one drum of its plinth stone survives), the
## scale (this is 1.6 m, not 16 m), the crowd of separate figures, and the human
## reading of the limbs — these are abstracted tubes and lobes, a body as form.
##
## THE ONE MATTE PASSAGE is the PLINTH: a low limestone drum, chalk-dry, wearing
## a painted grain and nothing else. Everything above it is latex, patent, wet or
## candy vinyl with a printed albedo and its own print in the emission, so the
## loud colours bloom through AgX instead of flattening. A wet body only reads
## wet next to a dry one, and the stone is the only dry thing here.
##
## AXES — two, and they cut the object, not the settings:
##   pattern   — what is PRINTED on the vinyl. harlequin: irregular black and
##               white shards on a cell grid, with the occasional coloured one.
##               snakeskin: dense rows of overlapping scales, bright at the top
##               edge and dark at the belly, in pale grout. swirl: broad sinuous
##               two-colour bands with a dark keyline where they meet. stripe:
##               wobbling bands in two loud hues with dark seams between them.
##               pucci: amoeboid blobs of four palette colours, ink-contoured,
##               with arcs thrown across the gaps. Five different printed
##               fabrics, not five tints of one.
##   inflation — how much air is in it. taut: the pile as built. overblown: the
##               bays balloon to beads, the welds cinch hard, and the limbs pull
##               toward their own chords and splay — an over-pressured toy loses
##               its curl. slack: the cross-section flattens to an ellipse, the
##               arcs bag downward. deflated: the perimeter is KEPT and the
##               section collapses, so every limb is a wide crumpled ribbon with
##               a rolling three-lobe wrinkle — the vinyl is all still there,
##               there is just nothing in it. bursting: taut everywhere except
##               two limbs whose seam has gone, each ending past the split in
##               flat crumpled skin, a ring of blown-open flaps and three
##               blisters that ballooned just before it let go.
##
## WHY DEFLATION KEEPS THE PERIMETER. The first draft shrank the radius to a
## third, which is what "deflated" sounds like and is wrong on the object: a pool
## toy that loses its air does not lose its skin. Shrinking the radius also
## shrinks the welt rings, and a weld tape that gets smaller when the air goes
## out is the tell that the model is of a sausage and not of a bag. So the
## section flattens (wide 1.30, flat 0.14, near enough constant perimeter) and
## the welts flatten with it.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const TEX: int = 160
const STONE_TEX: int = 64
const PLINTH_TOP: float = 0.060
const SIDES: int = 14
const RINGS: int = 40
## Stations of swept quarter-circle at each end of a member. Five is enough for
## a tip that reads round at arm's length and cheap enough to pay on 9 members.
const CAP_N: int = 5

## The vinyl a pile may be poured in. NO oilslick and NO holo: both of those set
## their own albedo_texture inside DreamSkin, and this family's whole argument is
## the printed albedo — a finish that overwrites the print is a finish that
## deletes one of the two axes.
const BODY_FIN: Array[String] = ["patent", "latex", "wet", "candy"]

## Metres of skin per texture tile, per print kind. This is a PHYSICAL size, not
## a UV number, so a fat torso and a thin limb wear the same size of print.
const CELL_M: Dictionary = {
	"harlequin": 0.42,
	"snakeskin": 0.20,
	"swirl": 0.62,
	"stripe": 0.34,
	"pucci": 0.50,
}


static func describe() -> String:
	return "A pile of colossal inflated vinyl limbs tangled over a limestone drum, welded in bays and printed all over in harlequin shards, snakeskin, swirls, stripes or op-art blobs."


static func axes() -> Dictionary:
	return {
		"pattern": ["harlequin", "snakeskin", "swirl", "stripe", "pucci"],
		"inflation": ["taut", "overblown", "slack", "deflated", "bursting"],
	}


## The prediction, as data, so tools/dream_bodies_promote.py carries it into the
## registry rather than anyone retyping it. Named pair, number, arithmetic.
static func predicted() -> Dictionary:
	return {
		"pair": "inflation: taut vs bursting (any pattern)",
		"predicted_pct": 2.6,
		"reasoning": ("bursting is the only value that is a LOCAL edit — every other one "
			+ "re-sections all eight members, so taut's nearest neighbour has to be it. "
			+ "The pile is one core mass plus six limbs; the limbs carry about 58% of the "
			+ "subject's pixels, so ~9.7% each. Two limbs burst, and only past their split "
			+ "at t~0.48, so 2 x 0.55 x 9.7 = 10.7% of the subject is touched. The collapsed "
			+ "ribbon still covers ~30% of the taut tube's width, so ~0.7 of that band "
			+ "actually turns into background: 7.5% of the subject. A dream body at framing "
			+ "0.62 is ~30% of the frame, so 7.5% x 0.30 = 2.2%, plus ~0.4% for the sixteen "
			+ "blown-open flaps and six blisters that are new pixels. Call it 2.6% of frame, "
			+ "and it is a LOWER bound: a Python-grade estimate has no shadows, no AO and no "
			+ "specular, and the corpus has never seen one over-predict."),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var pattern: String = String(opts.get("pattern", "harlequin"))
	var inflation: String = String(opts.get("inflation", "taut"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var air: Dictionary = _air(inflation)
	var cell_m: float = float(CELL_M.get(pattern, 0.42))

	# --- the wardrobe, dealt from this seed -----------------------------------
	var finish: String = BODY_FIN[rng.randi_range(0, BODY_FIN.size() - 1)]
	# 0.028, NOT 0.055. Measured off the first capture: an ink at 0.055 under the
	# hall's ambient, through AgX at exposure 1.15, photographs as a mid-grey
	# shard on a blown-white ground — the print was legible and had no bite. The
	# vinyl's own clearcoat carries the highlight; the albedo has to stay dark.
	var ink := Color(0.028, 0.026, 0.034)
	if rng.randf() < 0.28:
		# a coloured "black" — the reference's harlequin figure is not quite black
		var q: Color = Gloss.queer_colour(rng)
		ink = Color(q.r * 0.16, q.g * 0.14, q.b * 0.21)
	var chalk := Color(0.965, 0.955, 0.938)

	var tex_a: ImageTexture = _print_tex(pattern, rng, ink, chalk)
	var tex_b: ImageTexture = _print_tex(pattern, rng, ink, chalk)
	var mat_a: StandardMaterial3D = _dress(finish, tex_a, rng)
	var mat_b: StandardMaterial3D = _dress(finish, tex_b, rng)

	# WELD TAPE, NOT A HOOP. A saturated ring on a printed tube reads as a hula
	# hoop someone left on the sculpture; the tape has to be darker than the
	# print it crosses, so a coloured one is dragged most of the way to the ink.
	var welt_c: Color = ink
	if rng.randf() < 0.34:
		welt_c = Gloss.queer_colour(rng).lerp(ink, 0.45)
	var mat_welt: StandardMaterial3D = Gloss.skin(finish, welt_c, rng)
	mat_welt.metallic = minf(mat_welt.metallic, 0.50)
	mat_welt.emission_energy_multiplier = minf(mat_welt.emission_energy_multiplier, 0.35)

	var mat_valve: StandardMaterial3D = Gloss.skin("chrome", Gloss.QUEER["lemon"], rng)

	# MATTE, on purpose, and the only dry thing in the piece: one drum of the
	# colonnade's own stone, under a heap of wet vinyl.
	var mat_stone: StandardMaterial3D = Gloss.skin("matte", Color(0.815, 0.795, 0.745))
	mat_stone.albedo_texture = _stone_tex(rng)
	mat_stone.uv1_triplanar = true
	mat_stone.uv1_world_triplanar = true
	mat_stone.uv1_scale = Vector3(2.4, 2.4, 2.4)

	# --- who this pile is -----------------------------------------------------
	var n_limb: int = rng.randi_range(5, 7)
	var spin: float = 1.0 if rng.randf() < 0.5 else -1.0
	var base_r: float = rng.randf_range(0.116, 0.140)
	var lean: float = rng.randf_range(-0.07, 0.07)
	var a_off: float = rng.randf_range(0.0, TAU)

	# --- the core: two fat spindles crossing ----------------------------------
	var core_a: Array = _bez(
		Vector3(lean * 0.5, 0.235, rng.randf_range(-0.05, 0.05)),
		Vector3(lean - rng.randf_range(0.06, 0.14), 0.55, rng.randf_range(0.04, 0.14)),
		Vector3(lean + rng.randf_range(0.06, 0.16), 0.86, rng.randf_range(-0.14, -0.04)),
		Vector3(lean * 0.5, 1.150, rng.randf_range(-0.05, 0.05)), RINGS, air)
	var core_ar: float = rng.randf_range(0.190, 0.218)
	_member(root, mat_a, mat_welt, core_a, _spindle(RINGS, core_ar, 0.34),
		air, 4, cell_m, -1.0, rng)

	var b_yaw: float = rng.randf_range(0.7, 1.5) * spin
	var core_b: Array = _bez(
		Vector3(cos(b_yaw) * -0.22, 0.520, sin(b_yaw) * -0.20),
		Vector3(cos(b_yaw) * -0.06, 0.640, sin(b_yaw) * -0.02),
		Vector3(cos(b_yaw) * 0.10, 0.840, sin(b_yaw) * 0.04),
		Vector3(cos(b_yaw) * 0.26, 0.965, sin(b_yaw) * 0.16), RINGS, air)
	var core_br: float = rng.randf_range(0.150, 0.180)
	_member(root, mat_b, mat_welt, core_b, _spindle(RINGS, core_br, 0.36),
		air, 4, cell_m, -1.0, rng)

	# --- the limbs ------------------------------------------------------------
	# which two seams have gone. Dealt BEFORE the loop and from the same rng as
	# everything else, so "bursting" is the same two limbs on the same seed
	# whatever else changes — a split that wandered between captures would make
	# the axis unreadable against itself.
	var burst_i: Array[int] = []
	if bool(air["burst"]):
		var i0: int = rng.randi_range(0, n_limb - 1)
		var i1: int = (i0 + rng.randi_range(1, n_limb - 1)) % n_limb
		burst_i.append(i0)
		burst_i.append(i1)

	var alt_limb: int = rng.randi_range(0, n_limb - 1)
	for i in range(n_limb):
		var a0: float = a_off + TAU * float(i) / float(n_limb) + rng.randf_range(-0.24, 0.24)
		var y0: float = rng.randf_range(0.34, 1.02)
		var out_d := Vector3(cos(a0), 0.0, sin(a0))
		var tan_d := Vector3(-sin(a0), 0.0, cos(a0)) * spin

		var turn: float = rng.randf_range(1.6, 3.4) * spin
		var a3: float = a0 + turn
		# THE PILE HAS TO TANGLE. At 0.26..0.44 the limbs hugged the core and the
		# statue photographed as one lumpy figure; the reference is emphatically a
		# heap of things crossing over one another. 0.50 is the ceiling: past it
		# the settle starts fitting on width and the statue loses height.
		var end_r: float = rng.randf_range(0.30, 0.50)
		# where the limb finishes: on the stone, in the air over the pile, or
		# hooked across the middle at chest height
		var roll: float = rng.randf()
		var y3: float = rng.randf_range(0.40, 0.92)
		if roll < 0.38:
			y3 = rng.randf_range(0.030, 0.115)
		elif roll < 0.68:
			y3 = rng.randf_range(1.14, 1.44)

		var p0: Vector3 = Vector3(cos(a0) * 0.085, y0, sin(a0) * 0.085)
		var p3 := Vector3(cos(a3) * end_r, y3, sin(a3) * end_r)
		var p1: Vector3 = p0 + out_d * rng.randf_range(0.32, 0.54) \
			+ Vector3.UP * rng.randf_range(-0.12, 0.30) + tan_d * rng.randf_range(0.14, 0.42)
		var p2: Vector3 = p3 + Vector3(cos(a3), 0.0, sin(a3)) * rng.randf_range(0.14, 0.36) \
			+ Vector3.UP * rng.randf_range(-0.10, 0.34) - tan_d * rng.randf_range(0.06, 0.28)

		var pts: Array = _bez(p0, p1, p2, p3, RINGS, air)
		var n_welt: int = rng.randi_range(6, 8)
		var split: float = -1.0
		if burst_i.has(i):
			split = rng.randf_range(0.42, 0.55)
		var mat_l: StandardMaterial3D = mat_b if i == alt_limb else mat_a
		_member(root, mat_l, mat_welt, pts, _taper(RINGS, base_r), air,
			n_welt, cell_m, split, rng)

	# --- the valves — the only hardware ---------------------------------------
	for v in range(2):
		var vt: float = rng.randf_range(0.30, 0.72)
		var vi: int = clampi(int(round(vt * float(RINGS - 1))), 1, RINGS - 2)
		var src: Array = core_a if v == 0 else core_b
		var srad: float = core_ar if v == 0 else core_br
		var va: float = rng.randf_range(0.0, TAU)
		var tg: Vector3 = _tangent(src, vi)
		var nv: Vector3 = Vector3.UP - tg * Vector3.UP.dot(tg)
		if nv.length() < 0.001:
			nv = Vector3.RIGHT - tg * Vector3.RIGHT.dot(tg)
		nv = nv.normalized()
		var bv: Vector3 = tg.cross(nv).normalized()
		var dir: Vector3 = (nv * cos(va) + bv * sin(va)).normalized()
		var base_p: Vector3 = src[vi] + dir * (srad * 0.72)
		_rod(root, mat_valve, base_p, base_p + dir * 0.062, 0.026)
		_disc(root, mat_valve, base_p + dir * 0.068, dir, 0.034, 0.014)

	# --- the measured settle, copied from nana_gloss --------------------------
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

	# the drum: a fragment of the colonnade's plinth, and the family's one dry
	# surface. Radius is clamped so the stone can never widen the statue past the
	# 1.20 m the settle above just fitted the body into.
	var drum := CylinderMesh.new()
	drum.top_radius = minf(0.60, maxf(box.size.x, box.size.z) * 0.50 + 0.055)
	drum.bottom_radius = drum.top_radius * 1.035
	drum.height = PLINTH_TOP
	drum.radial_segments = 26
	drum.rings = 1
	var dm: MeshInstance3D = _add(root, drum, mat_stone)
	dm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# the inflation axis — how much air, and what that does to a section

## Everything the air decides, in one place. `k` scales the radius, `bulge` and
## `cinch` shape a welt bay, `wide`/`flat` are the cross-section's two half-axes,
## `crimp` is the amplitude of a rolling three-lobe wrinkle, `sag`, `straight`
## and `splay` reshape the PATH, and `burst` opens two seams.
static func _air(inflation: String) -> Dictionary:
	match inflation:
		"overblown":
			return {"k": 1.13, "bulge": 0.190, "cinch": 0.240, "wide": 1.00, "flat": 1.00,
				"crimp": 0.00, "lobes": 0, "sag": -0.05, "straight": 0.45, "splay": 1.10,
				"burst": false}
		"slack":
			return {"k": 0.95, "bulge": 0.030, "cinch": 0.150, "wide": 1.10, "flat": 0.60,
				"crimp": 0.06, "lobes": 2, "sag": 0.16, "straight": -0.10, "splay": 1.00,
				"burst": false}
		"deflated":
			return {"k": 0.92, "bulge": 0.020, "cinch": 0.080, "wide": 1.30, "flat": 0.14,
				"crimp": 0.30, "lobes": 3, "sag": 0.30, "straight": -0.16, "splay": 0.96,
				"burst": false}
		"bursting":
			return {"k": 1.00, "bulge": 0.060, "cinch": 0.120, "wide": 1.00, "flat": 0.98,
				"crimp": 0.00, "lobes": 0, "sag": 0.00, "straight": 0.00, "splay": 1.00,
				"burst": true}
		_:
			return {"k": 1.00, "bulge": 0.045, "cinch": 0.110, "wide": 1.00, "flat": 0.98,
				"crimp": 0.00, "lobes": 0, "sag": 0.00, "straight": 0.00, "splay": 1.00,
				"burst": false}


# ---------------------------------------------------------------------------
# one inflated member: skin, welts, caps, and whatever the seam did

static func _member(root: Node3D, mat: StandardMaterial3D,
		welt: StandardMaterial3D, pts: Array, base: Array, air: Dictionary,
		n_welt: int, cell_m: float, split: float, rng: RandomNumberGenerator) -> void:
	var n: int = pts.size()

	var k: float = float(air["k"])
	var bulge: float = float(air["bulge"])
	var cinch: float = float(air["cinch"])
	var w0: float = float(air["wide"])
	var f0: float = float(air["flat"])
	var c0: float = float(air["crimp"])
	# ONE lobe count for the whole tube, decided before the loop. The wrinkle's
	# amplitude is per-ring (it ramps in past a gone seam and is zero before it),
	# but its ORDER cannot be: a lobe count that changed along the length would
	# make the ring at the change discontinuous and tear the skin open.
	var lobes: int = int(air["lobes"])
	if split >= 0.0:
		lobes = 3

	var radii: Array = []
	var wide: Array = []
	var flat: Array = []
	var crimp: Array = []
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var ph: float = t * float(n_welt)
		var f: float = ph - floor(ph)
		# the bay: swollen in the middle, pinched at the weld. cos^4 keeps the
		# pinch tight to the seam instead of sucking in the whole bay.
		var pinch: float = 0.5 + 0.5 * cos(TAU * f)
		var m: float = 1.0 + bulge * sin(PI * f) - cinch * pow(pinch, 4.0)
		var r: float = float(base[i]) * k * m
		var ww: float = w0
		var ff: float = f0
		var cc: float = c0
		if split >= 0.0 and t > split:
			# past a gone seam there is no air at all: the tube keeps its skin and
			# loses its section over 14% of its length
			var g: float = clampf((t - split) / 0.14, 0.0, 1.0)
			r = r * lerpf(1.0, 0.30, g)
			ww = lerpf(w0, 1.28, g)
			ff = lerpf(f0, 0.16, g)
			cc = lerpf(c0, 0.34, g)
		radii.append(r)
		wide.append(ww)
		flat.append(ff)
		crimp.append(cc)

	var mean_r: float = 0.0
	for i in range(n):
		mean_r += float(radii[i])
	mean_r = maxf(mean_r / float(n), 0.001)
	# INTEGER tiles around: a fractional count leaves the u seam mismatched and
	# draws a hard line down the length of every tube
	var tiles: int = maxi(2, int(round(TAU * mean_r / maxf(cell_m, 0.05))))

	# --- the rounded ends, swept as more of the SAME tube ---------------------
	# The first draft capped each end with a SphereMesh and it was the one thing
	# in the render that plainly did not belong: a sphere's UVs run 0..1 over the
	# whole ball and pinch to nothing at the poles, so every tip came out a
	# confetti ball stuck on the end of a boldly printed tube. Swept, the print
	# runs off the end continuously and there is no seam left to mismatch.
	var epts: Array = []
	var er: Array = []
	var ew: Array = []
	var ef: Array = []
	var ec: Array = []
	var t0: Vector3 = _tangent(pts, 0)
	var t1: Vector3 = _tangent(pts, n - 1)
	for q in range(CAP_N):
		var a: float = (PI * 0.5) * float(CAP_N - q) / float(CAP_N)
		epts.append((pts[0] as Vector3) - t0 * (float(radii[0]) * sin(a)))
		# never let a ring reach zero: a degenerate ring gives generate_normals a
		# zero-area triangle fan and the tip shades black
		er.append(float(radii[0]) * maxf(cos(a), 0.10))
		ew.append(wide[0])
		ef.append(flat[0])
		ec.append(crimp[0])
	for i in range(n):
		epts.append(pts[i])
		er.append(radii[i])
		ew.append(wide[i])
		ef.append(flat[i])
		ec.append(crimp[i])
	for q in range(CAP_N):
		var a2: float = (PI * 0.5) * float(q + 1) / float(CAP_N)
		epts.append((pts[n - 1] as Vector3) + t1 * (float(radii[n - 1]) * sin(a2)))
		er.append(float(radii[n - 1]) * maxf(cos(a2), 0.10))
		ew.append(wide[n - 1])
		ef.append(flat[n - 1])
		ec.append(crimp[n - 1])

	var fr: Array = _frames(epts)
	var tans: Array = fr[0]
	var nrms: Array = fr[1]
	var bins: Array = fr[2]

	_add(root, _tube_mesh(epts, nrms, bins, er, ew, ef, ec, lobes, SIDES,
		float(tiles), cell_m), mat)

	# --- the welded welts -----------------------------------------------------
	for j in range(1, n_welt):
		var tj: float = float(j) / float(n_welt)
		if split >= 0.0 and tj > split:
			continue
		var ib: int = clampi(int(round(tj * float(n - 1))), 0, n - 1)
		var i2: int = ib + CAP_N
		# the tape is built off the UNCINCHED radius so it sits IN the pinch and
		# stands proud of it by exactly the cinch. The first draft used 1.03 and
		# a thick torus, and the welts photographed as hula hoops floating clear
		# of the skin instead of as a weld.
		var rw: float = float(base[ib]) * k * 0.995
		_welt(root, welt, epts[i2], tans[i2], nrms[i2], bins[i2], rw,
			float(ew[i2]), float(ef[i2]))

	# --- what a gone seam leaves ----------------------------------------------
	if split < 0.0:
		return
	# the frames are indexed over the EXTENDED array now, so every lookup into
	# them has to carry the cap offset — an un-offset index here would fan the
	# flaps around a ring five stations up the tube from the split
	var isp: int = clampi(int(round(split * float(n - 1))), 1, n - 2)
	var cs: Vector3 = pts[isp]
	var tg: Vector3 = tans[isp + CAP_N]
	var nv: Vector3 = nrms[isp + CAP_N]
	var bv: Vector3 = bins[isp + CAP_N]
	var rs: float = float(base[isp]) * k
	var spin0: float = rng.randf_range(0.0, TAU)
	for q in range(8):
		var a: float = spin0 + TAU * float(q) / 8.0 + rng.randf_range(-0.12, 0.12)
		var out_d: Vector3 = (nv * cos(a) + bv * sin(a)).normalized()
		var lay: Vector3 = (out_d * 0.78 + tg * rng.randf_range(0.42, 0.78)).normalized()
		var fl: float = rng.randf_range(0.9, 1.35)
		var fb: Basis = _basis_y_to(lay)
		var fmi: MeshInstance3D = _add(root, _ball_mesh(), mat)
		fmi.transform = Transform3D(fb * _diag(Vector3(rs * 0.55, rs * 1.30 * fl, rs * 0.11)),
			cs + out_d * (rs * 0.95) + lay * (rs * 0.95 * fl))
	# and the three that ballooned just before it went
	for q in range(3):
		var i3: int = clampi(isp - rng.randi_range(2, 5), 1, n - 2)
		var a3: float = rng.randf_range(0.0, TAU)
		var d3: Vector3 = ((nrms[i3 + CAP_N] as Vector3) * cos(a3)
			+ (bins[i3 + CAP_N] as Vector3) * sin(a3)).normalized()
		var rb: float = float(base[i3]) * k * rng.randf_range(0.42, 0.62)
		var bmi: MeshInstance3D = _add(root, _ball_mesh(), mat)
		bmi.transform = Transform3D(_basis_y_to(d3) * _diag(Vector3(rb, rb * 1.20, rb)),
			pts[i3] + d3 * (float(base[i3]) * k * 0.80))


# ---------------------------------------------------------------------------
# radius profiles

## A limb: full at the weld into the core, 56% at the rounded tip.
static func _taper(n: int, r: float) -> Array:
	var out: Array = []
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		out.append(r * (1.0 - 0.44 * pow(t, 1.35)))
	return out


## A torso lobe: an ovoid, fattest in the middle. `tip` is what is left at each
## end, and it has to stay well clear of zero or the end cap degenerates and the
## spindle photographs as a needle.
static func _spindle(n: int, r: float, tip: float) -> Array:
	var out: Array = []
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		out.append(r * (tip + (1.0 - tip) * pow(sin(PI * t), 0.62)))
	return out


# ---------------------------------------------------------------------------
# paths

static func _bez(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: int,
		air: Dictionary) -> Array:
	var straight: float = float(air["straight"])
	var sag: float = float(air["sag"])
	var splay: float = float(air["splay"])
	var out: Array = []
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var u: float = 1.0 - t
		var p: Vector3 = p0 * (u * u * u) + p1 * (3.0 * u * u * t) \
			+ p2 * (3.0 * u * t * t) + p3 * (t * t * t)
		# the air decides how much of the curl survives. A NEGATIVE straight is
		# an extrapolation away from the chord, which is what a slack limb does:
		# it bags further out than the taut one did.
		var chord: Vector3 = p0.lerp(p3, t)
		p = p.lerp(chord, straight)
		p.y -= sag * sin(PI * t) * 0.55
		p.x *= splay
		p.z *= splay
		out.append(p)
	return out


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var v: Vector3 = b - a
	if v.length() < 0.00001:
		return Vector3.UP
	return v.normalized()


## Parallel-transported frames, so the tube does not spin about its own axis and
## the welts land in the same plane as the ring they sit on. Without ONE shared
## frame set, a flattened section and its weld tape rotate against each other and
## the ring cuts through the skin.
static func _frames(pts: Array) -> Array:
	var n: int = pts.size()
	var tans: Array = []
	var nrms: Array = []
	var bins: Array = []
	var prev := Vector3.ZERO
	for i in range(n):
		var tg: Vector3 = _tangent(pts, i)
		var nv := Vector3.ZERO
		if i == 0:
			var sv := Vector3.UP
			if absf(tg.dot(sv)) > 0.9:
				sv = Vector3.RIGHT
			nv = sv - tg * sv.dot(tg)
		else:
			nv = prev - tg * prev.dot(tg)
			if nv.length() < 0.0001:
				var sv2 := Vector3.UP
				if absf(tg.dot(sv2)) > 0.9:
					sv2 = Vector3.RIGHT
				nv = sv2 - tg * sv2.dot(tg)
		nv = nv.normalized()
		prev = nv
		tans.append(tg)
		nrms.append(nv)
		bins.append(tg.cross(nv).normalized())
	return [tans, nrms, bins]


# ---------------------------------------------------------------------------
# the swept skin

static func _tube_mesh(pts: Array, nrms: Array, bins: Array, radii: Array,
		wide: Array, flat: Array, crimp: Array, lobes: int, sides: int,
		tiles: float, cell_m: float) -> ArrayMesh:
	var n: int = pts.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# v ADVANCES IN METRES OF SKIN, not in fractions of the member's length: one
	# tile of print is cell_m of arclength wherever you are on the tube. The
	# first draft normalised v by the member's MEAN radius, which is a constant,
	# so on a spindle — fat in the middle, thin at both ends — the print came out
	# stretched lengthways at the ends and squat in the middle. u still has to be
	# an integer count around, so only the around-scale tapers now.
	var arc: Array = []
	var acc: float = 0.0
	for i in range(n):
		if i > 0:
			var q0: Vector3 = pts[i]
			var q1: Vector3 = pts[i - 1]
			acc += (q0 - q1).length()
		arc.append(acc)
	var v_scale: float = 1.0 / maxf(cell_m, 0.05)

	# rings carry exactly `sides` vertices and the seam re-uses index 0, so the
	# two seam corners are bit-identical and generate_normals() welds them — a
	# seam pair differing by one float bit shades as a hard line down the tube
	var rings: Array = []
	for i in range(n):
		var row: Array = []
		var r: float = float(radii[i])
		var pc: Vector3 = pts[i]
		var nv: Vector3 = nrms[i]
		var bv: Vector3 = bins[i]
		var ww: float = float(wide[i])
		var ff: float = float(flat[i])
		var cc: float = float(crimp[i])
		# the wrinkle rolls along the tube, which is what stops a crumpled ribbon
		# reading as an extruded gear
		var phase: float = float(i) * 0.85
		for j in range(sides):
			var a: float = TAU * float(j) / float(sides)
			var rl: float = r
			if lobes > 0 and cc > 0.0:
				rl = r * (1.0 + cc * cos(float(lobes) * a + phase))
			row.append(pc + nv * (cos(a) * rl * ww) + bv * (sin(a) * rl * ff))
		rings.append(row)

	for i in range(n - 1):
		var v0: float = float(arc[i]) * v_scale
		var v1: float = float(arc[i + 1]) * v_scale
		var row0: Array = rings[i]
		var row1: Array = rings[i + 1]
		for j in range(sides):
			var jn: int = (j + 1) % sides
			var u0: float = tiles * float(j) / float(sides)
			var u1: float = tiles * float(j + 1) / float(sides)
			var pa: Vector3 = row0[j]
			var pb: Vector3 = row0[jn]
			var pc2: Vector3 = row1[jn]
			var pd: Vector3 = row1[j]
			st.set_uv(Vector2(u0, v0))
			st.add_vertex(pa)
			st.set_uv(Vector2(u1, v1))
			st.add_vertex(pc2)
			st.set_uv(Vector2(u1, v0))
			st.add_vertex(pb)
			st.set_uv(Vector2(u0, v0))
			st.add_vertex(pa)
			st.set_uv(Vector2(u0, v1))
			st.add_vertex(pd)
			st.set_uv(Vector2(u1, v1))
			st.add_vertex(pc2)

	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# fittings

static func _welt(root: Node3D, mat: StandardMaterial3D, at: Vector3, tg: Vector3,
		nv: Vector3, bv: Vector3, r: float, wide: float, flat: float) -> void:
	var tor := TorusMesh.new()
	tor.outer_radius = 1.0
	tor.inner_radius = 0.93
	tor.rings = 20
	tor.ring_segments = 6
	var mi: MeshInstance3D = _add(root, tor, mat)
	# TorusMesh rings about its own Y, so Basis(n, t, b) puts the ring in the
	# tube's cross-section plane and the two half-axes squash it with the section
	mi.transform = Transform3D(Basis(nv, tg, bv)
		* _diag(Vector3(r * wide, r * 0.92, r * flat)), at)


static func _rod(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r: float) -> void:
	var v: Vector3 = b - a
	var l: float = v.length()
	if l < 0.0005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r * 1.18
	cyl.height = l
	cyl.radial_segments = 14
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(v), (a + b) * 0.5)


static func _disc(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3,
		r: float, th: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = th
	cyl.radial_segments = 16
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(nrm), p)


static func _ball_mesh() -> SphereMesh:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 18
	sph.rings = 10
	return sph


# ---------------------------------------------------------------------------
# the pattern axis — every pixel drawn in code

static func _print_tex(kind: String, rng: RandomNumberGenerator, ink: Color,
		chalk: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	match kind:
		"snakeskin":
			_paint_snakeskin(img, rng, ink, chalk)
		"swirl":
			_paint_swirl(img, rng, ink, chalk)
		"stripe":
			_paint_stripe(img, rng, ink, chalk)
		"pucci":
			_paint_pucci(img, rng, ink, chalk)
		_:
			_paint_harlequin(img, rng, ink, chalk)
	return ImageTexture.create_from_image(img)


static func _put(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _fill(img: Image, c: Color) -> void:
	for y in range(TEX):
		for x in range(TEX):
			img.set_pixel(x, y, c)


## Harlequin: irregular two-tone shards. Each grid cell is cut by 2..4 random
## half-planes and a pixel takes the ink when it is on the positive side of an
## ODD number of them, which gives triangles and wedges rather than the regular
## diamonds a diagonal split would. Shards are cut by the cell border, and the
## texture's own edge IS a cell border, so the tile wraps.
static func _paint_harlequin(img: Image, rng: RandomNumberGenerator, ink: Color,
		chalk: Color) -> void:
	# FOUR CELLS AND THREE CUTS, not five and four. At the tighter setting the
	# shards came out about 4 cm on the body and the whole print read as noise at
	# walking distance; the reference's shards are the size of a door.
	var cells: int = 4
	var cs: float = float(TEX) / float(cells)
	var accent: Color = Gloss.queer_colour(rng)
	var angs: Array = []
	var offs: Array = []
	var acc: Array = []
	var solid: Array = []
	for i in range(cells * cells):
		var k: int = rng.randi_range(2, 3)
		var av: Array = []
		var ov: Array = []
		for j in range(k):
			av.append(rng.randf_range(0.0, PI))
			ov.append(rng.randf_range(-0.30, 0.30))
		angs.append(av)
		offs.append(ov)
		acc.append(rng.randf() < 0.26)
		# the reference keeps a few big flat panels among the shards
		solid.append(0 if rng.randf() > 0.16 else (1 if rng.randf() < 0.5 else 2))
	for y in range(TEX):
		var cy: int = clampi(int(float(y) / cs), 0, cells - 1)
		for x in range(TEX):
			var cx: int = clampi(int(float(x) / cs), 0, cells - 1)
			var idx: int = cy * cells + cx
			var sol: int = int(solid[idx])
			if sol == 1:
				img.set_pixel(x, y, ink)
				continue
			if sol == 2:
				img.set_pixel(x, y, chalk)
				continue
			var u: float = (float(x) - float(cx) * cs) / cs - 0.5
			var v: float = (float(y) - float(cy) * cs) / cs - 0.5
			var s: int = 0
			var av2: Array = angs[idx]
			var ov2: Array = offs[idx]
			for j in range(av2.size()):
				var a: float = float(av2[j])
				if u * cos(a) + v * sin(a) > float(ov2[j]):
					s += 1
			var c: Color = ink if (s % 2) == 1 else chalk
			# the reference's harlequin figure is black and white AND carries pops
			# of pink and yellow, so the accent takes a whole shard of either
			# parity rather than only the ink ones
			if bool(acc[idx]) and s == 1:
				c = accent
			elif bool(acc[idx]) and s == 2:
				c = accent.lerp(chalk, 0.45)
			img.set_pixel(x, y, c)


## Snakeskin: staggered rows of overlapping scales, bright along the top edge and
## dark at the belly, on pale grout. The scale is an ellipse with a light rim;
## the vertical shade inside it is what makes the rows read as overlapping rather
## than as a grid of beads.
static func _paint_snakeskin(img: Image, rng: RandomNumberGenerator, ink: Color,
		chalk: Color) -> void:
	var q: Color = Gloss.queer_colour(rng)
	var dark := Color(lerpf(ink.r, q.r, 0.34), lerpf(ink.g, q.g, 0.34), lerpf(ink.b, q.b, 0.34))
	var pale: Color = chalk.lerp(q, 0.18)
	var cols: int = 12
	var rows: int = 20
	var cw: float = float(TEX) / float(cols)
	var chh: float = float(TEX) / float(rows)
	var tint: Array = []
	for i in range(cols * rows):
		tint.append(rng.randf_range(0.74, 1.30))
	for y in range(TEX):
		var fyr: float = float(y) / chh
		var ry: int = int(floor(fyr))
		var v: float = fyr - float(ry) - 0.5
		var ox: float = 0.5 * float(posmod(ry, 2))
		for x in range(TEX):
			var fx: float = float(x) / cw + ox
			var rx: int = int(floor(fx))
			var u: float = fx - float(rx) - 0.5
			var d: float = sqrt((u / 0.46) * (u / 0.46) + (v / 0.54) * (v / 0.54))
			if d > 1.0:
				img.set_pixel(x, y, pale)
			elif d > 0.86:
				img.set_pixel(x, y, pale.lerp(dark, 0.28))
			else:
				var idx: int = posmod(ry, rows) * cols + posmod(rx, cols)
				var sh: float = lerpf(1.55, 0.58, clampf(v + 0.5, 0.0, 1.0)) * float(tint[idx])
				img.set_pixel(x, y, Color(clampf(dark.r * sh, 0.0, 1.0),
					clampf(dark.g * sh, 0.0, 1.0), clampf(dark.b * sh, 0.0, 1.0)))


## Swirl: broad sinuous two-colour bands with a dark keyline where they meet.
## Every frequency is an INTEGER multiple of TAU/TEX, which is the only reason
## the tile wraps — a fractional one puts a seam down every limb.
static func _paint_swirl(img: Image, rng: RandomNumberGenerator, ink: Color,
		chalk: Color) -> void:
	var hue: Color = Gloss.queer_colour(rng)
	var pale: Color = chalk if rng.randf() < 0.72 else chalk.lerp(Gloss.queer_colour(rng), 0.35)
	var f1: float = float(rng.randi_range(1, 2)) * TAU / float(TEX)
	var f2: float = float(rng.randi_range(1, 2)) * TAU / float(TEX)
	var f3: float = float(rng.randi_range(2, 3)) * TAU / float(TEX)
	var p1: float = rng.randf_range(0.0, TAU)
	var p2: float = rng.randf_range(0.0, TAU)
	var amp: float = rng.randf_range(1.8, 2.9)
	for y in range(TEX):
		var fy: float = float(y)
		for x in range(TEX):
			var fx: float = float(x)
			var w: float = sin(fx * f1 + amp * sin(fy * f3 + p1)) \
				+ 0.75 * sin(fy * f2 + 1.9 * sin(fx * f3 + p2))
			var c: Color = hue if w > 0.0 else pale
			if absf(w) < 0.11:
				c = ink
			img.set_pixel(x, y, c)


## Stripe: wobbling bands in two loud hues with dark seams. The wobble frequency
## is an integer too, for the same reason as the swirl.
static func _paint_stripe(img: Image, rng: RandomNumberGenerator, ink: Color,
		chalk: Color) -> void:
	var bands: int = rng.randi_range(6, 9)
	var c1: Color = Gloss.queer_colour(rng)
	var c2: Color = Gloss.queer_colour(rng)
	var tries: int = 0
	while c2.is_equal_approx(c1) and tries < 6:
		c2 = Gloss.queer_colour(rng)
		tries += 1
	var band_c: Array[Color] = []
	for i in range(bands):
		var r: float = rng.randf()
		if r < 0.16:
			band_c.append(chalk)
		elif i % 2 == 0:
			band_c.append(c1)
		else:
			band_c.append(c2)
	var bw: float = float(TEX) / float(bands)
	var amp: float = rng.randf_range(3.0, 12.0)
	var freq: float = float(rng.randi_range(1, 3)) * TAU / float(TEX)
	for y in range(TEX):
		var wob: float = amp * sin(float(y) * freq)
		for x in range(TEX):
			var u: float = float(x) + wob
			var bi: int = posmod(int(floor(u / bw)), bands)
			var frac: float = u / bw - floor(u / bw)
			var c: Color = band_c[bi]
			if frac < 0.05 or frac > 0.95:
				c = ink
			img.set_pixel(x, y, c)


## Pucci: amoeboid blobs of four palette colours on chalk, each ink-contoured,
## with arcs thrown across the gaps.
static func _paint_pucci(img: Image, rng: RandomNumberGenerator, ink: Color,
		chalk: Color) -> void:
	_fill(img, chalk)
	var pal: Array[Color] = []
	for i in range(4):
		pal.append(Gloss.queer_colour(rng))
	var n: int = rng.randi_range(13, 19)
	for i in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var rr: float = rng.randf_range(11.0, 26.0)
		var w1: float = rng.randf_range(0.18, 0.42)
		var w2: float = rng.randf_range(0.10, 0.28)
		var q1: float = rng.randf_range(0.0, TAU)
		var q2: float = rng.randf_range(0.0, TAU)
		_amoeba(img, cx, cy, rr + 2.8, w1, w2, q1, q2, ink)
		_amoeba(img, cx, cy, rr, w1, w2, q1, q2, pal[rng.randi_range(0, pal.size() - 1)])
	for i in range(rng.randi_range(4, 8)):
		var ax: float = rng.randf_range(0.0, float(TEX))
		var ay: float = rng.randf_range(0.0, float(TEX))
		var ar: float = rng.randf_range(13.0, 32.0)
		var a0: float = rng.randf_range(0.0, TAU)
		_arc(img, ax, ay, ar, rng.randf_range(1.6, 3.4), a0, a0 + rng.randf_range(1.1, 3.4), ink)


static func _amoeba(img: Image, cx: float, cy: float, r: float, w1: float, w2: float,
		q1: float, q2: float, c: Color) -> void:
	var rad: int = int(ceil(r * (1.0 + w1 + w2))) + 2
	for y in range(-rad, rad + 1):
		for x in range(-rad, rad + 1):
			var dx: float = float(x)
			var dy: float = float(y)
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 0.0001:
				_put(img, int(cx) + x, int(cy) + y, c)
				continue
			var th: float = atan2(dy, dx)
			var rr: float = r * (1.0 + w1 * sin(3.0 * th + q1) + w2 * sin(5.0 * th + q2))
			if d <= rr:
				_put(img, int(cx) + x, int(cy) + y, c)


static func _arc(img: Image, cx: float, cy: float, r: float, th: float, a0: float,
		a1: float, c: Color) -> void:
	var steps: int = int(ceil((a1 - a0) * r * 2.2)) + 6
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var a: float = lerpf(a0, a1, t)
		var bx: float = cx + cos(a) * r
		var by: float = cy + sin(a) * r
		var ti: int = int(ceil(th))
		for y in range(-ti, ti + 1):
			for x in range(-ti, ti + 1):
				if float(x * x + y * y) <= th * th:
					_put(img, int(bx) + x, int(by) + y, c)


## Dry limestone grain — the only texture in this file that is not a print.
static func _stone_tex(rng: RandomNumberGenerator) -> ImageTexture:
	# SPECKLE, NOT A WAVE. The first draft grained the stone with a sine of a
	# sine, and tiled at 2.4 it photographed as a woven chevron mat — a pattern,
	# competing with the print, which is the one thing the dry passage must not
	# do. Limestone is grit and the odd darker inclusion, and nothing else.
	var img: Image = Image.create(STONE_TEX, STONE_TEX, false, Image.FORMAT_RGB8)
	for y in range(STONE_TEX):
		for x in range(STONE_TEX):
			var v: float = clampf(0.90 + 0.10 * rng.randf() - 0.06 * rng.randf(), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v * 0.985, v * 0.935))
	for i in range(26):
		var cx: int = rng.randi_range(0, STONE_TEX - 1)
		var cy: int = rng.randi_range(0, STONE_TEX - 1)
		var rr: int = rng.randi_range(1, 3)
		var d: float = rng.randf_range(0.68, 0.86)
		for y in range(-rr, rr + 1):
			for x in range(-rr, rr + 1):
				if x * x + y * y > rr * rr:
					continue
				var px: int = posmod(cx + x, STONE_TEX)
				var py: int = posmod(cy + y, STONE_TEX)
				var c: Color = img.get_pixel(px, py)
				img.set_pixel(px, py, Color(c.r * d, c.g * d, c.b * d))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# materials — vinyl, with the print in the albedo AND the emission

## The print rides on a DreamSkin gloss. Two caps are deliberate and are the
## corpus's own lessons: a body at metallic 1.0 photographs black in a bare
## capture, and a print under a strong emission stops reading as print. But the
## print IS the emission texture, so the loud hues bloom through AgX instead of
## being compressed toward orange-grey the way a flat saturated albedo is.
static func _dress(finish: String, tex: ImageTexture,
		rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, Color(0.97, 0.96, 0.95), rng)
	# albedo_color MULTIPLIES albedo_texture, so it stays near white or the print
	# loses the colours it was painted in
	m.albedo_color = Color(0.99, 0.98, 0.97)
	m.albedo_texture = tex
	# the tube's own UVs already carry the tiling, in metres of skin per tile
	m.uv1_scale = Vector3.ONE
	m.metallic = minf(m.metallic, 0.45)
	# RIM LIFTS EVERY DARK TEXEL. DreamSkin's vinyls run rim 0.55..0.9, which on a
	# fat pale tube washes the print's ink to mid-grey right where the surface
	# turns away — exactly where a big inflatable shows most of its area.
	if m.rim_enabled:
		m.rim = minf(m.rim, 0.30)
	if m.emission_enabled:
		m.emission = Color(1.0, 1.0, 1.0)
		m.emission_texture = tex
		m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.30)
	return m


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


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	return Basis(ax, acos(clampf(dot_up, -1.0, 1.0)))


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
