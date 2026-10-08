extends RefCounted

## dream_bodies / lilac_quarry — a landscape as a statue: a stack of lilac and
## dove-grey beds with pale bathers leaning on the broken face.
##
## Reference: C:/Users/palle/Documents/FinalMD/m1/0_0290-0000.jpg.
##
## WHAT THE FILE ON DISK ACTUALLY SHOWS, said first because it is not what the
## commission described. The brief said "pale nude figures posed among strata of
## lilac and dove-grey rock, under dark oak canopies, with a blue valley behind".
## The image at that path is a 4096x1072 panorama of pale scaled bird-lizard
## creatures standing among lilac branching coral, yellow ribbon kelp and dark
## green grass on a black ground. No rock, no valley, no figures. The PALETTE is
## the brief's palette exactly — lilac, dove grey, pale cream, one dark green —
## and the argument the brief asks for (the quarry as co-equal subject, bodies as
## abstracted form) is the one built here, so this family takes its colour and its
## dark overhanging canopy from the photograph in front of me and its subject from
## the commission. Anyone re-deriving this from the image alone will not find the
## quarry in it, and should know that before hunting for their own mistake.
##
## Reproduced, and how:
##   1. THE BEDS — 8..11 stacked slabs, each a SurfaceTool prism over an
##      irregular plan outline (20 sides, two sine lobes), tapering slightly
##      upward, each tilted a couple of degrees off its neighbour and the whole
##      stack dipping 4..11 degrees. Flat-shaded (smooth group -1), because a
##      bedding plane with a soft normal is a cushion, not a rock.
##   2. THE SPLIT FACE — every bed's outline is clipped by ONE world-space plane
##      at z = FACE_Z, so the clipped chords of ten separate prisms are coplanar
##      and read as a single quarried wall rather than ten coincidences. Those
##      chord walls are emitted as a SECOND mesh per bed so they can carry their
##      own material: this is the family's one dry passage (see THE MATTE
##      PASSAGE below).
##   3. BEDDING THAT CROSSES THE SEAMS — the laminae are a 160px texture of
##      horizontal bands with grain, hairline joints and stringers, mapped with
##      WORLD triplanar. One image runs through every slab, so a band leaving one
##      bed arrives in the next. Painted seamless in v (the last band is forced
##      to the first band's colour) because a triplanar wrap seam on a 1.1 m
##      stack reads as a crack that is not there.
##   4. ONE MINERAL SEAM — a thin proud ring of neon or candy between two beds,
##      in a colour dealt off the queer palette. It is the only saturated thing
##      in the statue and it is what stops a grey-lilac rock photographing as fog.
##   5. BOULDERS AND SCREE — 8..13 faceted spalls (SphereMesh at 7..9 segments,
##      unevenly scaled) resting on bed tops and at the foot, plus 12..18 rubble
##      chips as small tumbled boxes.
##   6. THE CANOPY — 2..4 dark arms of the reference's overhanging growth, arced
##      over the top bed as tapering rods in near-black green.
##   7. THE BATHERS — sculptural, not anatomical: a body is a chain of ellipsoids
##      over a joint skeleton, a featureless ovoid head, no hands beyond a knob.
##      Pale marble with faint lilac veining, pearl finish.
##   8. THE BODIES LIVE IN THE ROCK'S OWN SPACE. Every bather joint is pushed
##      through the same dip basis and the same strata warp as the rock, so a
##      folded stack carries its bathers up over the crest and a faulted stack
##      drops the one standing on the downthrown side. The two axes are not
##      independent and are not meant to be — that interaction IS the landscape.
##
## Given up: the blue valley receding behind (a statue is walked around, so there
## is no "behind"), the crowd (one or two bodies, not a frieze), faces, and the
## fine imbricated scale pattern the reference's creatures wear, which at statue
## scale would have been noise.
##
## THE MATTE PASSAGE, exactly one, named as the contract asks: THE SPLIT FACES.
## The chord wall of every bed, and the sawn benches when the quarry is working,
## are Gloss.skin("matte") over a painted chalk — dry, floury, conchoidal. Every
## other surface in the statue is wet: pearl or patent laminae, pearl flesh, a
## neon seam, latex canopy, a wet slate plinth. Freshly broken rock is dry and
## weathered rock is not, so the dry passage is also the true one, and a wet body
## leaning on a dry wall is the only way either of them reads.
##
## AXES — two, and both cut the object, not the settings.
##   strata  — what the rock has DONE. `bedded` lies flat and dipping (the
##             reference). `faulted` cuts the stack on a 60-degree plane and drops
##             the far side 13..22 cm with drag folding into the fault, so no bed
##             lines up with itself. `folded` throws the whole stack into an
##             anticline — the crest rises and both limbs fall, about 40 cm of
##             relief on a 110 cm stack. `quarried` bites a stepped rectangular
##             bench out of one quadrant and stands the removed stone beside it as
##             sawn ashlar. `cast` GROWS the whole landscape — beds, boulders and
##             bathers together — as one marched isosurface, so the body does not
##             lean on the rock, it is the same stone as the rock.
##   bathers — who is here. `leaning` is one body standing back against the face.
##             `reclining` is one body lying along a bed, propped on an elbow.
##             `embedded` sinks the leaning body 12 cm into the wall and DELETES
##             every part that ends up inside the stone, so a shoulder, a thigh
##             and half a head emerge from the block. `pair` is the leaning body
##             unchanged plus a reclining one on a lower bed. `strewn` breaks the
##             body into 5..7 fragments lying among the boulders.
##
## WHAT `cast` GROWS, and why it is not just "the same thing, smoother". Every
## other value stacks prisms and lets the tilt hide the joins. `cast` hands the
## SAME data — the same bed centres and radii, the same bather joints out of
## _stand/_recline — to DreamIso as ~24 rounded boxes, capsules and spheres
## smooth-unioned at 7 cm, plus two subtracted spheres where the bench was cut.
## Nothing stacks any more: the bed swells into the bed below it, the boulder
## grows out of the ledge it sits on, and the bather's calf becomes the wall.
## The seam, the chips, the canopy and the plinth stay primitives, so the value
## still has its colour and its dry passage.
##
## A COARSER CELL IS AN AMPUTATION AND IT IS SILENT — dream_iso.mesh_of warns only
## when it emits NOTHING, so a cell that melts the 3.5 cm bather limbs still
## commits thousands of triangles and says nothing. Hence the clamp on opts.cell
## to a measured range, copied from fetish_idol, which learned it the hard way.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX: int = 160
const SIDES: int = 20
## The one plane every bed's chord is clipped against. World z in stack space —
## shared, not per-bed, which is the whole reason the face reads as one wall.
const FACE_Z: float = 0.135
const PLINTH_TOP: float = 0.050
## Marched at 3.8 cm; the clamp ceiling is where the bather's wrist (r 0.020)
## starts to disappear into the cell.
const CELL: float = 0.038
const BLEND: float = 0.070

## Laminae, straight off the panorama: lilac, dove, deep violet, near-white,
## ash grey, one warm ochre seam.
const BED_PAL: Array = ["#B9A7D6", "#CFC9D4", "#8E7FAE", "#E4DCE9", "#A6A2AE", "#C7B79C"]
## Rock is allowed to be wet, never chrome — a mirrored 40 cm slab with nothing
## to reflect photographs as a hole in the statue.
const ROCK_FIN: Array[String] = ["pearl", "wet", "latex", "patent"]


static func describe() -> String:
	return "A quarry as a statue: eight to eleven lilac and dove-grey beds stacked, tilted and split open along one dry chalk face, with a bright mineral seam, spalled boulders, a dark overhanging canopy, and one or two pale marble bathers leaning, lying or half-buried in the stone."


static func axes() -> Dictionary:
	return {
		"strata": ["bedded", "faulted", "folded", "quarried", "cast"],
		"bathers": ["leaning", "reclining", "embedded", "pair", "strewn"],
	}


## The prediction, as data, so tools/dream_bodies_promote.py carries it into the
## registry instead of anyone retyping it. Named pair, number, arithmetic.
static func predicted() -> Dictionary:
	return {
		"pair": "bathers: leaning vs pair, at strata=bedded",
		"predicted_pct": 3.1,
		"reasoning": ("every number is dealt BEFORE the axis branches, so leaning and pair "
			+ "share one rock and one identical standing body and differ by exactly the "
			+ "added reclining figure: 0.58 m long x 0.19 m tall at ~0.70 fill is 0.077 m2 "
			+ "projected, against a statue silhouette of ~0.95 x 1.35 m at ~0.58 fill = "
			+ "0.74 m2, so 10.4% of the SILHOUETTE; the silhouette is about 30% of the "
			+ "frame, so 0.104 x 0.30 = 3.1% of the picture. Quoting 10.4% would be the "
			+ "denominator error fetish_idol already paid for. It is a LOWER bound: a "
			+ "hand estimate has no shadow, no AO and no specular, and the added body is "
			+ "pearl over matte chalk, which is the highest-contrast edge in the statue."),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var strata: String = str(opts.get("strata", "bedded"))
	var bathers: String = str(opts.get("bathers", "leaning"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- THE DEAL: every number for every value, drawn before any branch -------
	# stella_wall's discipline. If the axis branched inside the draw, `leaning`
	# and `pair` would get different rocks from the same seed and the closest-pair
	# prediction above would be measuring two statues instead of one difference.
	var n_bed: int = rng.randi_range(8, 11)
	var dip: float = deg_to_rad(rng.randf_range(4.0, 11.0)) * (1.0 if rng.randf() < 0.5 else -1.0)
	var dip_b := Basis(Vector3.RIGHT, dip) * Basis(Vector3.BACK, deg_to_rad(rng.randf_range(-4.0, 4.0)))

	var beds: Array = []
	var y_cur: float = 0.0
	var cx: float = 0.0
	var cz: float = 0.0
	for i in range(n_bed):
		var t: float = float(i) / float(maxi(n_bed - 1, 1))
		var th: float = rng.randf_range(0.062, 0.168) * lerpf(1.0, 0.78, t)
		# the jitter on top of the taper is what stops the stack reading as a
		# turned column: without it every bed is within a centimetre of the trend
		# line and ten slabs photograph as one wedding cake
		var r0: float = lerpf(rng.randf_range(0.415, 0.470), rng.randf_range(0.255, 0.320), t) \
			+ rng.randf_range(-0.045, 0.045)
		cx += rng.randf_range(-0.028, 0.028)
		cz += rng.randf_range(-0.024, 0.024)
		beds.append({
			"c": Vector3(cx, y_cur, cz),
			"th": th,
			"r0": r0,
			"taper": rng.randf_range(0.925, 0.995),
			"a3": rng.randf_range(0.05, 0.14),
			"p3": rng.randf_range(0.0, TAU),
			"a5": rng.randf_range(0.03, 0.09),
			"p5": rng.randf_range(0.0, TAU),
			"tilt": Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(-2.6, 2.6)))
				* Basis(Vector3.BACK, deg_to_rad(rng.randf_range(-2.6, 2.6))),
		})
		y_cur += th
	var top_y: float = y_cur

	# the strata warp, dealt whole so switching value swaps a rule, not a rock
	var fold_amp: float = rng.randf_range(0.100, 0.160)
	var fold_ph: float = rng.randf_range(-0.5, 0.5)
	var fault_x: float = rng.randf_range(-0.10, 0.10)
	var fault_slope: float = rng.randf_range(0.12, 0.26) * (1.0 if rng.randf() < 0.5 else -1.0)
	var fault_throw: float = rng.randf_range(0.130, 0.215)
	var fault_heave: float = rng.randf_range(0.030, 0.070)
	var bench_i: int = clampi(int(round(float(n_bed) * rng.randf_range(0.32, 0.52))), 2, n_bed - 2)
	var bench_x: float = rng.randf_range(0.055, 0.130)
	var bench_z: float = rng.randf_range(-0.055, 0.035)

	var w := {
		"kind": strata,
		"dip": dip_b,
		"top": top_y,
		"amp": fold_amp,
		"k": PI / 0.50,
		"ph": fold_ph,
		"fx": fault_x,
		"slope": fault_slope,
		"throw": fault_throw,
		"heave": fault_heave,
	}

	# the seam: which join it sits on, how proud, how loud
	var seam_i: int = rng.randi_range(1, maxi(n_bed - 3, 1))
	var seam_h: float = rng.randf_range(0.012, 0.024)
	var seam_grow: float = rng.randf_range(1.010, 1.032)
	# THE SEAM MUST BE SATURATED OR IT IS NOT A SEAM. The palette carries `cream`
	# and `ink`, and the second render drew the vein in cream — a white pinstripe
	# round a pale rock, invisible as an accent and indistinguishable from a
	# lighting seam. Re-dealt until it has some chroma, capped so a pathological
	# stream still terminates.
	var seam_col: Color = Gloss.queer_colour(rng)
	var seam_try: int = 0
	while seam_col.s < 0.45 and seam_try < 8:
		seam_col = Gloss.queer_colour(rng)
		seam_try += 1
	var seam_fin: String = "neon" if rng.randf() < 0.45 else "candy"

	# the loose stone
	var n_boulder: int = rng.randi_range(8, 13)
	var n_chip: int = rng.randi_range(12, 18)
	var n_arm: int = rng.randi_range(2, 4)

	# the bathers — dealt for BOTH, always, whichever value asks for them
	var stand_d := {
		"sc": rng.randf_range(0.74, 0.86),
		"yaw": deg_to_rad(rng.randf_range(-26.0, 26.0)),
		"lean": deg_to_rad(rng.randf_range(5.0, 13.0)),
		"side": 1.0 if rng.randf() < 0.5 else -1.0,
		"knee": rng.randf_range(0.055, 0.105),
		"arm_up": rng.randf() < 0.45,
		"head_tip": deg_to_rad(rng.randf_range(-6.0, 20.0)),
		"x": rng.randf_range(-0.13, 0.13),
	}
	var rec_d := {
		"sc": rng.randf_range(0.70, 0.82),
		"yaw": deg_to_rad(rng.randf_range(-30.0, 30.0)),
		"side": 1.0 if rng.randf() < 0.5 else -1.0,
		"knee": rng.randf_range(0.10, 0.20),
		"prop": rng.randf_range(0.55, 0.95),
		# A LEDGE WITH FOUR BEDS ON TOP OF IT IS NOT A LEDGE, IT IS A SEAM. This
		# read randi_range(1, n_bed - 4) — always a LOW bed, always with the rest
		# of the quarry stacked over it — so the reclining bather was inside the
		# stone in every seed. It rendered as bare rock, and the axis quietly
		# became four values instead of five: the DNA critic caught it as a twin,
		# `leaning == pair` at 0.00%, because adding a buried body to a standing
		# one changes no pixel. Nothing else in the chain could see it — the body
		# was built, materialled, counted and measured; it just could not be
		# looked at. The top third of the stack has open sky above it.
		"bed": rng.randi_range(maxi(n_bed - 3, 1), maxi(n_bed - 1, 1)),
		"x": rng.randf_range(-0.16, 0.16),
	}
	var strew_seed: int = rng.randi_range(1, 1 << 20)

	# --- the wardrobe ---------------------------------------------------------
	var rock_fin: String = ROCK_FIN[rng.randi_range(0, ROCK_FIN.size() - 1)]
	var bed_cols: Array = []
	for i in range(BED_PAL.size()):
		bed_cols.append(Color(str(BED_PAL[i])))
	bed_cols.append(Gloss.queer_colour(rng).lerp(Color(0.80, 0.78, 0.84), 0.55))
	# NEARLY WHITE, AND THAT IS THE POINT. StandardMaterial3D MULTIPLIES
	# albedo_color by albedo_texture, so a lilac tint over lilac laminae is
	# 0.85 x 0.70 with the band-to-band contrast squeezed into what is left: the
	# second render came back as flat pink slabs with the bedding gone, and it
	# read as a fault in the texture, which had not changed. The painted bands
	# carry the colour; the tint only leans it.
	var rock_tint: Color = Color(0.97, 0.95, 0.99).lerp(Gloss.queer_colour(rng), rng.randf_range(0.0, 0.10))

	var tex_bed: ImageTexture = _paint_bedding(rng, bed_cols)
	var mat_rock: StandardMaterial3D = _dress(rock_fin, rock_tint, tex_bed, rng.randf_range(0.78, 1.05), rng)
	# THE ONE MATTE PASSAGE — the dry fracture. Nothing else in the statue is dry.
	var mat_face: StandardMaterial3D = Gloss.skin("matte", Color("#E6E1DA"))
	mat_face.albedo_texture = _paint_chalk(rng)
	mat_face.uv1_triplanar = true
	mat_face.uv1_world_triplanar = true
	mat_face.uv1_scale = Vector3(1.45, 1.45, 1.45)
	var flesh_fin: String = "pearl" if rng.randf() < 0.7 else "candy"
	var mat_flesh: StandardMaterial3D = _dress(flesh_fin, Color("#F3E7D8"),
		_paint_marble(rng, Gloss.queer_colour(rng)), rng.randf_range(1.5, 2.2), rng)
	var mat_seam: StandardMaterial3D = Gloss.skin(seam_fin, seam_col, rng)
	var mat_moss: StandardMaterial3D = Gloss.skin("latex", Color(0.085, 0.185, 0.115), rng)
	# wet slate, NOT matte: the one dry thing here is the fracture, and a second
	# chalky passage would take the contrast the first one is for
	var mat_plinth: StandardMaterial3D = Gloss.skin("wet", Color(0.145, 0.135, 0.165), rng)

	# --- the plan outlines, once, shared by every path ------------------------
	for i in range(n_bed):
		var bed: Dictionary = beds[i]
		var notch := Vector2(0.0, 0.0)
		if strata == "quarried" and i >= bench_i:
			# the bench steps BACK as it rises, which is what makes it read as a
			# working face and not a chip out of a biscuit
			notch = Vector2(maxf(bench_x - 0.030 * float(i - bench_i), 0.030),
				bench_z + 0.028 * float(i - bench_i))
		_outline(bed, FACE_Z, notch)

	# --- the rock -------------------------------------------------------------
	var cast_ok: bool = false
	if strata == "cast":
		cast_ok = _cast(root, mat_rock, beds, w, rng, bathers, stand_d, rec_d,
			strew_seed, n_boulder, bench_i, bench_x, bench_z,
			clampf(float(opts.get("cell", CELL)), CELL, 0.052))
	if not cast_ok:
		for i in range(n_bed):
			_bed_mesh(root, mat_rock, mat_face, beds[i], w)
		_boulders(root, mat_rock, mat_moss, beds, w, rng, n_boulder)
	# the seam rides on the join whatever the rock did, so `cast` keeps its colour
	_seam(root, mat_seam, beds[seam_i], w, seam_h, seam_grow)
	if strata == "quarried":
		_ashlar(root, mat_rock, mat_face, beds, w, rng, bench_i)
	_chips(root, mat_rock, mat_face, beds, w, rng, n_chip)
	_canopy(root, mat_moss, beds, w, rng, n_arm)

	# --- the bathers ----------------------------------------------------------
	if not cast_ok:
		if bathers == "leaning" or bathers == "pair":
			_emit_body(root, mat_flesh, _stand(stand_d), _stand_at(stand_d, 0.0), w, beds, false)
		if bathers == "embedded":
			# 12 cm INTO the wall, and every part that ends up inside the stone is
			# deleted rather than hidden: a shoulder and a thigh coming out of the
			# block, which is the argument, and 40-odd meshes the museum does not
			# have to draw inside a rock nobody can see through.
			_emit_body(root, mat_flesh, _stand(stand_d), _stand_at(stand_d, -0.120), w, beds, true)
		if bathers == "reclining" or bathers == "pair":
			_emit_body(root, mat_flesh, _recline(rec_d), _recline_at(rec_d, beds), w, beds, false)
		if bathers == "strewn":
			_strewn(root, mat_flesh, _stand(stand_d), beds, w, strew_seed)

	# --- stature, then the measured settle ------------------------------------
	# Copied from nana_gloss, deliberately: the contract wants ONE settle in the
	# family and a reinvented one is a new way to sink a statue into the floor.
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
	plinth.size = Vector3(minf(1.20, box.size.x + 0.09), PLINTH_TOP, minf(1.20, box.size.z + 0.09))
	var pm: MeshInstance3D = _add(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# the rock's own space — dip, then whatever the strata axis is doing

static func _warp(p: Vector3, w: Dictionary) -> Vector3:
	var kind: String = String(w.get("kind", "bedded"))
	if kind == "folded":
		var amp: float = float(w["amp"])
		var k: float = float(w["k"])
		# CLAMPED to one half period on purpose. Without the clamp the cosine
		# keeps going and a 1.1 m stack comes back corrugated like a roof sheet —
		# which is a fold nobody has ever seen in a quarry, and worse, it is
		# symmetric, so the value photographs almost the same from every side.
		var arg: float = clampf(p.x * k + float(w["ph"]), -PI, PI)
		var g: float = clampf(p.y / maxf(float(w["top"]), 0.05), 0.0, 1.0)
		var bow: float = amp * cos(arg)
		return Vector3(p.x * (1.0 - 0.10 * g), p.y + bow * (0.30 + 0.95 * g), p.z + bow * 0.22)
	if kind == "faulted":
		var side: float = p.x - (float(w["fx"]) + float(w["slope"]) * p.y)
		if side <= 0.0:
			return p
		# drag: the beds bend INTO the fault over the first 14 cm, so the throw is
		# a hinge and not a butcher's cut through the middle of the statue
		var drag: float = clampf(side / 0.14, 0.0, 1.0)
		return Vector3(p.x + float(w["heave"]) * drag, p.y - float(w["throw"]) * drag,
			p.z + float(w["heave"]) * 0.25 * drag)
	return p


## A point given in stack space, delivered to the world the statue is built in.
static func _map(q: Vector3, w: Dictionary) -> Vector3:
	return _warp((w["dip"] as Basis) * q, w)


## A point given in ONE BED's local frame, delivered the same way.
static func _pt(bed: Dictionary, local: Vector3, w: Dictionary) -> Vector3:
	return _map((bed["tilt"] as Basis) * local + (bed["c"] as Vector3), w)


# ---------------------------------------------------------------------------
# the plan outline: two lobes, one shared chord, an optional bench

## Writes `pts` (Array[Vector2] in the bed's own x/z), `rad` and `face` into the
## bed. The chord is clipped against a plane at WORLD z, not at a per-bed
## fraction of the radius — ten beds each cut at 0.55 r would give ten different
## planes and the face would read as a staircase instead of a wall.
static func _outline(bed: Dictionary, face_z: float, notch: Vector2) -> void:
	var r0: float = float(bed["r0"])
	var cz: float = (bed["c"] as Vector3).z
	var chord: float = face_z - cz
	var pts: Array[Vector2] = []
	var rad: Array[float] = []
	var face: Array[bool] = []
	for i in range(SIDES):
		var a: float = TAU * float(i) / float(SIDES)
		var r: float = r0 * (1.0
			+ float(bed["a3"]) * sin(3.0 * a + float(bed["p3"]))
			+ float(bed["a5"]) * sin(5.0 * a + float(bed["p5"])))
		var on_face: bool = false
		var ca: float = cos(a)
		if ca > 0.32 and chord > 0.02:
			var lim: float = chord / ca
			if lim < r:
				r = lim
				on_face = true
		var p := Vector2(sin(a) * r, ca * r)
		if notch.x > 0.0 and p.x > notch.x and p.y > notch.y:
			# pulled back toward the axis rather than clipped in place, so the
			# outline STAYS star-shaped about its centre — the caps below are a
			# fan from that centre and a re-entrant outline would fold them
			# inside out with no error and no warning.
			var t: float = minf(notch.x / p.x, notch.y / maxf(p.y, 0.001))
			p = p * t
			on_face = true            # a sawn bench is a fresh face: dry
		pts.append(p)
		rad.append(p.length())
		face.append(on_face)
	bed["pts"] = pts
	bed["rad"] = rad
	bed["face"] = face


static func _bed_mesh(root: Node3D, mat_rock: StandardMaterial3D, mat_face: StandardMaterial3D,
		bed: Dictionary, w: Dictionary) -> void:
	var pts: Array = bed["pts"]
	var face: Array = bed["face"]
	var th: float = float(bed["th"])
	var tap: float = float(bed["taper"])
	var n: int = pts.size()

	var lo: Array[Vector3] = []
	var hi: Array[Vector3] = []
	for i in range(n):
		var p: Vector2 = pts[i]
		lo.append(_pt(bed, Vector3(p.x, 0.0, p.y), w))
		hi.append(_pt(bed, Vector3(p.x * tap, th, p.y * tap), w))
	var c_lo: Vector3 = _pt(bed, Vector3.ZERO, w)
	var c_hi: Vector3 = _pt(bed, Vector3(0.0, th, 0.0), w)

	var st_r := SurfaceTool.new()
	st_r.begin(Mesh.PRIMITIVE_TRIANGLES)
	# FLAT, not smooth. A bedding plane with an averaged normal reads as a
	# cushion; the whole point of a slab is that its top is one value.
	st_r.set_smooth_group(-1)
	var st_f := SurfaceTool.new()
	st_f.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_f.set_smooth_group(-1)
	var any_face: bool = false

	for i in range(n):
		var j: int = (i + 1) % n
		_tri3(st_r, c_hi, hi[i], hi[j], Vector3.UP)
		_tri3(st_r, c_lo, lo[j], lo[i], Vector3.DOWN)
		var mp: Vector2 = ((pts[i] as Vector2) + (pts[j] as Vector2)) * 0.5
		var out := Vector3(mp.x, 0.0, mp.y)
		var onrm: Vector3 = Vector3.FORWARD if out.length() < 0.0001 else out.normalized()
		var is_face: bool = bool(face[i]) and bool(face[j])
		if is_face:
			any_face = true
			_tri3(st_f, lo[i], lo[j], hi[j], onrm)
			_tri3(st_f, lo[i], hi[j], hi[i], onrm)
		else:
			_tri3(st_r, lo[i], lo[j], hi[j], onrm)
			_tri3(st_r, lo[i], hi[j], hi[i], onrm)
	st_r.generate_normals()
	_add(root, st_r.commit(), mat_rock)
	if any_face:
		st_f.generate_normals()
		_add(root, st_f.commit(), mat_face)


## The mineral seam — a proud ring at one bed join. Wall only, no caps: it is a
## band of colour round the stack, not another slab.
static func _seam(root: Node3D, mat: StandardMaterial3D, bed: Dictionary, w: Dictionary,
		h: float, grow: float) -> void:
	var pts: Array = bed["pts"]
	var n: int = pts.size()
	var y0: float = float(bed["th"])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in range(n):
		var j: int = (i + 1) % n
		var pi2: Vector2 = pts[i]
		var pj: Vector2 = pts[j]
		var a0: Vector3 = _pt(bed, Vector3(pi2.x * grow, y0, pi2.y * grow), w)
		var a1: Vector3 = _pt(bed, Vector3(pj.x * grow, y0, pj.y * grow), w)
		var b0: Vector3 = _pt(bed, Vector3(pi2.x * grow, y0 + h, pi2.y * grow), w)
		var b1: Vector3 = _pt(bed, Vector3(pj.x * grow, y0 + h, pj.y * grow), w)
		var mp: Vector2 = (pi2 + pj) * 0.5
		var out := Vector3(mp.x, 0.0, mp.y)
		var onrm: Vector3 = Vector3.FORWARD if out.length() < 0.0001 else out.normalized()
		_tri3(st, a0, a1, b1, onrm)
		_tri3(st, a0, b1, b0, onrm)
	st.generate_normals()
	_add(root, st.commit(), mat)


# ---------------------------------------------------------------------------
# the loose stone

static func _boulders(root: Node3D, mat: StandardMaterial3D, mat_moss: StandardMaterial3D,
		beds: Array, w: Dictionary, rng: RandomNumberGenerator, n: int) -> void:
	for i in range(n):
		var bi: int = rng.randi_range(0, beds.size() - 1)
		var bed: Dictionary = beds[bi]
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = _rad_at(bed, a) * rng.randf_range(0.62, 1.05)
		# SMALLER AND FLATTER THAN THE FIRST TRY. At 0.045..0.105 with a near-round
		# scale they photographed as plums, and a green cap on top finished the
		# job — the boulders read as fruit on a cake. A spall off a bedded rock is
		# a flake: wider than it is tall, and small against the bed it fell from.
		var rr: float = rng.randf_range(0.034, 0.076)
		var y: float = float(bed["th"]) + rr * 0.48
		if rng.randf() < 0.34:
			# spalled off and lying at the foot of the wall
			bed = beds[0]
			r = _rad_at(bed, a) * rng.randf_range(1.02, 1.42)
			y = rr * 0.52
		var c: Vector3 = _pt(bed, Vector3(sin(a) * r, y, cos(a) * r), w)
		var sc := Vector3(rr * rng.randf_range(0.95, 1.55), rr * rng.randf_range(0.42, 0.68),
			rr * rng.randf_range(0.95, 1.55))
		var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, rng.randf_range(-0.35, 0.35))
		_facet(root, mat, c, sc, b, rng)
		# the reference's dark growth, but only where it would actually sit: on
		# the flat upward face of a boulder, never underneath one
		if rng.randf() < 0.22:
			_facet(root, mat_moss, c + Vector3(0.0, sc.y * 0.80, 0.0),
				Vector3(sc.x * 0.66, sc.y * 0.30, sc.z * 0.66), b, rng)


## EVERY CHIP HAS TO BE STANDING ON SOMETHING. The first render put them at
## 0.95..1.50 of the bed radius at bed-top height, which for anything over 1.0
## is thin air: four chips hovered a hand's width off the stack, and nothing in
## the probe can see it — they carry material, they are inside the AABB, they
## lift the count. So the two cases are now separate and neither can float: ON a
## bed top means inside its own outline, BESIDE the stack means down on the
## ground at bed 0.
static func _chips(root: Node3D, mat: StandardMaterial3D, mat_face: StandardMaterial3D,
		beds: Array, w: Dictionary, rng: RandomNumberGenerator, n: int) -> void:
	for i in range(n):
		var s: float = rng.randf_range(0.022, 0.058)
		var a: float = rng.randf_range(0.0, TAU)
		var bed: Dictionary = beds[0]
		var r: float = _rad_at(bed, a) * rng.randf_range(1.02, 1.48)
		var y: float = s * 0.42
		if rng.randf() < 0.55:
			bed = beds[rng.randi_range(0, maxi(beds.size() - 3, 0))]
			r = _rad_at(bed, a) * rng.randf_range(0.45, 0.94)
			y = float(bed["th"]) + s * 0.42
		var c: Vector3 = _pt(bed, Vector3(sin(a) * r, y, cos(a) * r), w)
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE
		var mi: MeshInstance3D = _add(root, bm, mat_face if rng.randf() < 0.45 else mat)
		var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, rng.randf_range(-0.9, 0.9)) * Basis(Vector3.BACK, rng.randf_range(-0.9, 0.9))
		mi.transform = Transform3D(b * _diag(Vector3(s * rng.randf_range(0.7, 1.6),
			s * rng.randf_range(0.30, 0.62), s * rng.randf_range(0.7, 1.6))), c)


## The stone the bench took out, stacked beside the face as sawn blocks. Only
## `quarried` calls this — the value has to give the removed volume somewhere to
## be, or the bite just reads as damage.
static func _ashlar(root: Node3D, mat: StandardMaterial3D, mat_face: StandardMaterial3D,
		beds: Array, w: Dictionary, rng: RandomNumberGenerator, bench_i: int) -> void:
	var bed: Dictionary = beds[0]
	var n: int = rng.randi_range(4, 7)
	var bx: float = _rad_at(bed, 2.0) * rng.randf_range(1.05, 1.28)
	var stack_y: float = 0.0
	for i in range(n):
		var sx: float = rng.randf_range(0.075, 0.130)
		var sy: float = rng.randf_range(0.048, 0.080)
		var sz: float = rng.randf_range(0.075, 0.135)
		if i > 0 and rng.randf() < 0.40:
			stack_y = 0.0
			bx += rng.randf_range(0.10, 0.17)
		var c: Vector3 = _pt(bed, Vector3(sin(2.0) * bx + rng.randf_range(-0.03, 0.03),
			stack_y + sy, cos(2.0) * bx + rng.randf_range(-0.03, 0.03)), w)
		var bm := BoxMesh.new()
		bm.size = Vector3(sx * 2.0, sy * 2.0, sz * 2.0)
		var mi: MeshInstance3D = _add(root, bm, mat_face if i % 2 == 0 else mat)
		mi.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(-0.45, 0.45)), c)
		stack_y += sy * 2.0


## The dark overhanging growth of the panorama, arced over the top bed.
static func _canopy(root: Node3D, mat: StandardMaterial3D, beds: Array, w: Dictionary,
		rng: RandomNumberGenerator, n: int) -> void:
	var bed: Dictionary = beds[beds.size() - 1]
	for i in range(n):
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = _rad_at(bed, a) * rng.randf_range(0.55, 0.92)
		var root_p := Vector3(sin(a) * r, float(bed["th"]), cos(a) * r)
		var reach: float = rng.randf_range(0.20, 0.34)
		var rise: float = rng.randf_range(0.13, 0.26)
		var out := Vector3(sin(a + rng.randf_range(-0.8, 0.8)), 0.0, cos(a + rng.randf_range(-0.8, 0.8))).normalized()
		# A FULL sin arch, and it OVERHANGS. The first render used sin(t*PI*0.85),
		# which stops the arm three quarters of the way up and leaves it pointing
		# at the sky with a ball on the end — four of those and the statue wore
		# antennae. sin(t*PI) brings the tip back down past the rim, and the
		# quadratic droop carries it below the bed it grew from, which is what
		# makes a canopy a canopy rather than a crown.
		var segs: int = rng.randi_range(4, 6)
		var prev: Vector3 = _pt(bed, root_p, w)
		var rr: float = rng.randf_range(0.026, 0.038)
		for j in range(segs):
			var t: float = float(j + 1) / float(segs)
			# parenthesised: GDScript only continues an expression across lines
			# INSIDE brackets, so a bare leading `+` is a parse error
			var q: Vector3 = (root_p + out * reach * t
				+ Vector3(0.0, rise * sin(t * PI) - 0.14 * t * t, 0.0))
			var nxt: Vector3 = _pt(bed, q, w)
			_rod(root, mat, prev, nxt, rr * (1.0 - 0.16 * float(j)))
			# a flat pad hung off the underside of the arm. Without them a bare
			# tapering rod on a rock is not a canopy, it is an antenna, which is
			# exactly how the first two arms photographed.
			if j >= 1 and rng.randf() < 0.75:
				var pad: Vector3 = prev.lerp(nxt, 0.6) + Vector3(0.0, -rr * 1.4, 0.0)
				_facet(root, mat, pad, Vector3(rr * rng.randf_range(2.2, 3.4), rr * 0.42,
					rr * rng.randf_range(1.6, 2.6)),
					Basis(Vector3.UP, rng.randf_range(0.0, TAU)), rng)
			prev = nxt
		if rng.randf() < 0.35:
			_facet(root, mat, prev, Vector3(rr * 1.1, rr * 0.9, rr * 1.1), Basis(), rng)


# ---------------------------------------------------------------------------
# the bathers — joints first, meshes later, so the stacked path and the marched
# path cannot mean two different bodies

## A standing bather leaning back: local frame has the feet at y = 0 and the
## SHOULDER BLADES at z = 0, so placing it is "put the back on the wall".
static func _stand(d: Dictionary) -> Dictionary:
	var s: float = float(d["sc"])
	var side: float = float(d["side"])
	var kn: float = float(d["knee"])
	var lean: float = float(d["lean"])
	# the lean is baked into the joint z rather than applied as a rotation: a
	# rotation about the feet would lift the heels off the ground
	var pelvis := Vector3(side * 0.018 * s, 0.500 * s, (0.085 + sin(lean) * 0.20) * s)
	var chest := Vector3(-side * 0.012 * s, 0.700 * s, (0.078 + sin(lean) * 0.06) * s)
	var neck := Vector3(0.0, 0.790 * s, 0.070 * s)
	var head := neck + Vector3(0.0, 0.062 * s, -sin(float(d["head_tip"])) * 0.055 * s)
	var limbs: Array = []
	# THE COUNTS ARE AN OVERLAP CONDITION, NOT A DETAIL SETTING. The first render
	# gave a bead necklace, not a body: the thigh ran 0.25 m at n = 5, so the
	# spheres sat 62 mm apart with a 45 mm radius and every join showed. A chain
	# only reads as one poured limb when the spacing is under the radius, so each
	# count here is length/radius rounded up, and a limb that gets longer needs a
	# bigger n, not a bigger sphere.
	limbs.append({"a": pelvis, "b": chest, "r0": 0.092 * s, "r1": 0.082 * s, "n": 7})
	limbs.append({"a": chest, "b": neck, "r0": 0.082 * s, "r1": 0.042 * s, "n": 4})
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		var hip: Vector3 = pelvis + Vector3(sd * 0.052 * s, -0.020 * s, -0.010 * s)
		var bend: float = kn if sd == side else kn * 0.28
		var knee: Vector3 = Vector3(sd * 0.058 * s, 0.262 * s, (0.075 + bend) * s)
		var ankle: Vector3 = Vector3(sd * 0.055 * s, 0.036 * s, (0.052 + bend * 0.30) * s)
		limbs.append({"a": hip, "b": knee, "r0": 0.062 * s, "r1": 0.041 * s, "n": 7})
		limbs.append({"a": knee, "b": ankle, "r0": 0.041 * s, "r1": 0.028 * s, "n": 6})
		var sh: Vector3 = chest + Vector3(sd * 0.090 * s, 0.024 * s, 0.0)
		var up: bool = bool(d["arm_up"]) and sd == side
		var elb: Vector3 = sh + (Vector3(sd * 0.048 * s, 0.075 * s, -0.030 * s) if up
			else Vector3(sd * 0.040 * s, -0.150 * s, 0.012 * s))
		var wri: Vector3 = elb + (Vector3(sd * 0.010 * s, 0.115 * s, 0.028 * s) if up
			else Vector3(sd * 0.028 * s, -0.145 * s, 0.048 * s))
		limbs.append({"a": sh, "b": elb, "r0": 0.043 * s, "r1": 0.033 * s, "n": 6})
		limbs.append({"a": elb, "b": wri, "r0": 0.033 * s, "r1": 0.024 * s, "n": 6})
	return {
		"limbs": limbs,
		"head": {"c": head, "r": Vector3(0.052 * s, 0.062 * s, 0.055 * s)},
		"knobs": [
			{"c": Vector3(side * 0.055 * s, 0.014 * s, (0.052 + kn * 0.30) * s + 0.030 * s), "r": 0.030 * s},
			{"c": Vector3(-side * 0.055 * s, 0.014 * s, (0.052 + kn * 0.28 * 0.30) * s + 0.030 * s), "r": 0.030 * s},
		],
	}


## A reclining bather: local frame lies along x, resting surface at y = 0.
static func _recline(d: Dictionary) -> Dictionary:
	var s: float = float(d["sc"])
	var side: float = float(d["side"])
	var kn: float = float(d["knee"])
	var prop: float = float(d["prop"])
	var pelvis := Vector3(-0.010 * s, 0.088 * s, 0.0)
	var chest := Vector3(0.190 * s, (0.098 + 0.075 * prop) * s, side * 0.020 * s)
	var neck := Vector3(0.278 * s, (0.108 + 0.130 * prop) * s, side * 0.028 * s)
	var head := neck + Vector3(0.052 * s, 0.032 * s, side * 0.010 * s)
	var limbs: Array = []
	limbs.append({"a": pelvis, "b": chest, "r0": 0.090 * s, "r1": 0.080 * s, "n": 7})
	limbs.append({"a": chest, "b": neck, "r0": 0.080 * s, "r1": 0.042 * s, "n": 4})
	for k in range(2):
		var sd: float = -1.0 if k == 0 else 1.0
		var hip: Vector3 = pelvis + Vector3(-0.014 * s, 0.006 * s, sd * 0.050 * s)
		var draw: float = kn if sd == side else kn * 0.42
		var knee := Vector3((-0.170 - draw * 0.30) * s, (0.070 + draw) * s, sd * 0.062 * s)
		var ankle := Vector3((-0.300 + draw * 0.55) * s, 0.038 * s, sd * 0.058 * s)
		limbs.append({"a": hip, "b": knee, "r0": 0.060 * s, "r1": 0.040 * s, "n": 7})
		limbs.append({"a": knee, "b": ankle, "r0": 0.040 * s, "r1": 0.027 * s, "n": 6})
		var sh: Vector3 = chest + Vector3(0.024 * s, 0.018 * s, sd * 0.082 * s)
		# the propping arm goes DOWN to the rock; the other lies across the body
		var elb: Vector3 = sh + (Vector3(-0.060 * s, -0.070 * s, sd * 0.020 * s) if sd == side
			else Vector3(-0.075 * s, -0.045 * s, -sd * 0.030 * s))
		var wri: Vector3 = elb + (Vector3(0.048 * s, -0.062 * s, sd * 0.012 * s) if sd == side
			else Vector3(-0.095 * s, -0.020 * s, -sd * 0.010 * s))
		limbs.append({"a": sh, "b": elb, "r0": 0.040 * s, "r1": 0.030 * s, "n": 5})
		limbs.append({"a": elb, "b": wri, "r0": 0.030 * s, "r1": 0.022 * s, "n": 5})
	return {
		"limbs": limbs,
		"head": {"c": head, "r": Vector3(0.055 * s, 0.052 * s, 0.052 * s)},
		"knobs": [],
	}


## Where the standing bather goes, in STACK space: back on the face plane, moved
## `into` metres through it (negative = into the stone).
static func _stand_at(d: Dictionary, into: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, float(d["yaw"])),
		Vector3(float(d["x"]), 0.0, FACE_Z + 0.012 + into))


static func _recline_at(d: Dictionary, beds: Array) -> Transform3D:
	var bi: int = clampi(int(d["bed"]), 0, beds.size() - 1)
	var bed: Dictionary = beds[bi]
	var y: float = (bed["c"] as Vector3).y + float(bed["th"])
	var cxz: Vector3 = bed["c"]
	# ON THE FRONT LIP, not at the bed's middle. A body lying at the centre of a
	# 0.30 m bed is half a metre back from the quarry face and reads as nothing
	# from the front, which is the standpoint every capture and every visitor
	# uses. Two thirds of the way out puts it where a bather would actually lie.
	var fwd: float = float(bed.get("r0", 0.30)) * 0.62
	return Transform3D(Basis(Vector3.UP, float(d["yaw"])),
		Vector3(cxz.x + float(d["x"]), y, cxz.z + fwd))


## One bather into the tree. Every joint is pushed through the same dip and warp
## as the rock, which is what makes `folded` carry its bathers over the crest.
## `carve` drops the parts that end up inside the stone.
static func _emit_body(root: Node3D, mat: StandardMaterial3D, body: Dictionary,
		place: Transform3D, w: Dictionary, beds: Array, carve: bool) -> void:
	var limbs: Array = body["limbs"]
	for l_v in limbs:
		var l: Dictionary = l_v
		var a: Vector3 = place * (l["a"] as Vector3)
		var b: Vector3 = place * (l["b"] as Vector3)
		var n: int = int(l["n"])
		for i in range(n):
			var t: float = float(i) / float(maxi(n - 1, 1))
			var q: Vector3 = a.lerp(b, t)
			if carve and _inside(beds, q):
				continue
			var r: float = lerpf(float(l["r0"]), float(l["r1"]), t)
			_ball(root, mat, _map(q, w), Vector3(r, r, r), Basis())
	var head: Dictionary = body["head"]
	var hc: Vector3 = place * (head["c"] as Vector3)
	if not (carve and _inside(beds, hc)):
		_ball(root, mat, _map(hc, w), head["r"], Basis(Vector3.UP, place.basis.get_euler().y))
	var knobs: Array = body["knobs"]
	for k_v in knobs:
		var k: Dictionary = k_v
		var kc: Vector3 = place * (k["c"] as Vector3)
		if carve and _inside(beds, kc):
			continue
		var kr: float = float(k["r"])
		_ball(root, mat, _map(kc, w), Vector3(kr * 1.25, kr * 0.72, kr * 1.55), Basis())


## The body broken up and left among the boulders. Its own generator, so the
## fragments do not eat the draws the other values spend on a whole figure.
static func _strewn(root: Node3D, mat: StandardMaterial3D, body: Dictionary,
		beds: Array, w: Dictionary, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var limbs: Array = body["limbs"]
	var n_frag: int = rng.randi_range(5, 7)
	for f in range(n_frag):
		var l: Dictionary = limbs[rng.randi_range(0, limbs.size() - 1)]
		var bi: int = rng.randi_range(0, maxi(beds.size() - 3, 0))
		var bed: Dictionary = beds[bi]
		var ang: float = rng.randf_range(0.0, TAU)
		var r: float = _rad_at(bed, ang) * rng.randf_range(0.55, 1.30)
		var base := Vector3(sin(ang) * r, float(bed["th"]), cos(ang) * r)
		var lie := Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.BACK, rng.randf_range(1.2, 1.9))
		var span: Vector3 = (l["b"] as Vector3) - (l["a"] as Vector3)
		var keep: int = mini(int(l["n"]), rng.randi_range(2, 3))
		for i in range(keep):
			var t: float = float(i) / float(maxi(keep - 1, 1))
			var rr: float = lerpf(float(l["r0"]), float(l["r1"]), t)
			var q: Vector3 = base + lie * (span * t * 0.85) + Vector3(0.0, rr * 0.75, 0.0)
			_ball(root, mat, _map(q, w), Vector3(rr, rr, rr), Basis())
	# a head is always among them: it is what makes the pile read as a body
	var hr: Vector3 = (body["head"] as Dictionary)["r"]
	var hb: Dictionary = beds[rng.randi_range(0, maxi(beds.size() - 3, 0))]
	var ha: float = rng.randf_range(0.0, TAU)
	var hrr: float = _rad_at(hb, ha) * rng.randf_range(0.60, 1.20)
	_ball(root, mat, _map(Vector3(sin(ha) * hrr, float(hb["th"]) + hr.y * 0.85, cos(ha) * hrr), w),
		hr, Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, 1.1))


## Is this stack-space point inside the rock? Nominal — the test runs BEFORE the
## dip and the warp, because a warp is a bijection on the whole space and moves
## the point and the bed it is in by the same amount. Testing after the warp
## would need the inverse, which `faulted` does not have at the fault plane.
static func _inside(beds: Array, q: Vector3) -> bool:
	for b_v in beds:
		var bed: Dictionary = b_v
		var c: Vector3 = bed["c"]
		if q.y < c.y - 0.01 or q.y > c.y + float(bed["th"]) + 0.01:
			continue
		var l: Vector3 = (bed["tilt"] as Basis).transposed() * (q - c)
		var a: float = atan2(l.x, l.z)
		if Vector2(l.x, l.z).length() < _rad_at(bed, a) * 0.98:
			return true
	return false


## The outline radius at an angle, interpolated between the two stored samples.
static func _rad_at(bed: Dictionary, a: float) -> float:
	var rad: Array = bed["rad"]
	var n: int = rad.size()
	var f: float = fposmod(a, TAU) / TAU * float(n)
	var i: int = int(floor(f)) % n
	var j: int = (i + 1) % n
	return lerpf(float(rad[i]), float(rad[j]), f - floor(f))


# ---------------------------------------------------------------------------
# `cast` — the whole landscape as one field

## Returns true when a surface came back. On null the caller falls through to the
## stacked construction, so the value degrades to a bedded quarry rather than to
## a bare plinth — the failure dream_iso's own warning exists to make audible.
static func _cast(root: Node3D, mat: StandardMaterial3D, beds: Array, w: Dictionary,
		rng: RandomNumberGenerator, bathers: String, stand_d: Dictionary, rec_d: Dictionary,
		strew_seed: int, n_boulder: int, bench_i: int, bench_x: float, bench_z: float,
		cell: float) -> bool:
	var parts: Array = []
	# the beds, as rounded slabs — the field is sampled in WARPED space, so a cast
	# fold or fault would need an inverse warp per sample; it does not have one,
	# so `cast` is deliberately the value where the stack is only dipped
	for b_v in beds:
		var bed: Dictionary = b_v
		var c: Vector3 = (w["dip"] as Basis) * ((bed["c"] as Vector3) + Vector3(0.0, float(bed["th"]) * 0.5, 0.0))
		var r: float = float(bed["r0"]) * 0.74
		parts.append(Iso.box(c, Vector3(r, float(bed["th"]) * 0.55, r * 0.86), 0.045))
	# a handful of the boulders, fused into the ledges they sit on
	for i in range(mini(n_boulder, 5)):
		var bed2: Dictionary = beds[rng.randi_range(0, beds.size() - 1)]
		var a: float = rng.randf_range(0.0, TAU)
		var rr: float = rng.randf_range(0.055, 0.100)
		var q := Vector3(sin(a) * _rad_at(bed2, a) * 0.80, float(bed2["th"]) + rr * 0.5,
			cos(a) * _rad_at(bed2, a) * 0.80)
		parts.append(Iso.sphere(_map((bed2["tilt"] as Basis) * q + (bed2["c"] as Vector3), {"dip": w["dip"]}), rr))
	# the bather, as the same joints every other value uses
	var body: Dictionary = _stand(stand_d)
	var place: Transform3D = _stand_at(stand_d, -0.055)
	if bathers == "reclining" or bathers == "strewn":
		body = _recline(rec_d)
		place = _recline_at(rec_d, beds)
	elif bathers == "embedded":
		place = _stand_at(stand_d, -0.135)
	var limbs: Array = body["limbs"]
	for l_v in limbs:
		var l: Dictionary = l_v
		parts.append(Iso.capsule(_map(place * (l["a"] as Vector3), {"dip": w["dip"]}),
			_map(place * (l["b"] as Vector3), {"dip": w["dip"]}),
			float(l["r0"]) * 0.92, float(l["r1"]) * 0.92))
	var head: Dictionary = body["head"]
	var hr: Vector3 = head["r"]
	parts.append(Iso.sphere(_map(place * (head["c"] as Vector3), {"dip": w["dip"]}), hr.x))
	if bathers == "pair":
		var body2: Dictionary = _recline(rec_d)
		var pl2: Transform3D = _recline_at(rec_d, beds)
		var lm2: Array = body2["limbs"]
		for i in range(mini(lm2.size(), 6)):
			var l2: Dictionary = lm2[i]
			parts.append(Iso.capsule(_map(pl2 * (l2["a"] as Vector3), {"dip": w["dip"]}),
				_map(pl2 * (l2["b"] as Vector3), {"dip": w["dip"]}),
				float(l2["r0"]) * 0.92, float(l2["r1"]) * 0.92))
	# the bench, bitten out of the poured mass instead of clipped out of a plan
	var top_bed: Dictionary = beds[clampi(bench_i, 0, beds.size() - 1)]
	var bc: Vector3 = top_bed["c"]
	parts.append(Iso.cut(Iso.sphere((w["dip"] as Basis) * (bc + Vector3(bench_x + 0.20, float(top_bed["th"]), bench_z + 0.20)), 0.26)))
	var mesh: ArrayMesh = Iso.mesh_of(parts, cell, BLEND, 0.055)
	if mesh == null:
		push_warning("[lilac_quarry] the field yielded no landscape; falling back to the stacked beds")
		return false
	_add(root, mesh, mat)
	return true


# ---------------------------------------------------------------------------
# painted skins — every pixel drawn in code

## The laminae. Bands run along the image's v, so under world triplanar the
## vertical faces get horizontal bedding and the sawn tops get the banding of a
## cut section, which is what a quarry floor actually looks like.
##
## SEAMLESS IN V ON PURPOSE: the last band is forced back to the first band's
## colour. Triplanar wraps the tile every 1/uv1_scale metres, and an unmatched
## wrap on a 1.1 m stack draws a hard horizontal line across every slab at the
## same height — which reads as a bedding plane that is not there, and would have
## been blamed on the geometry.
static func _paint_bedding(rng: RandomNumberGenerator, cols: Array) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var band_of := PackedInt32Array()
	band_of.resize(TEX)
	var edge := PackedFloat32Array()
	edge.resize(TEX)
	var picks: Array[Color] = []
	var y: int = 0
	var idx: int = 0
	while y < TEX:
		var h: int = rng.randi_range(5, 26)
		picks.append(cols[rng.randi_range(0, cols.size() - 1)])
		for k in range(h):
			if y + k >= TEX:
				break
			band_of[y + k] = idx
			edge[y + k] = minf(float(k), float(h - 1 - k)) / maxf(float(h) * 0.5, 1.0)
		y += h
		idx += 1
	if picks.size() > 1:
		picks[picks.size() - 1] = picks[0]
	for py in range(TEX):
		var bi: int = clampi(band_of[py], 0, picks.size() - 1)
		var base: Color = picks[bi]
		for px in range(TEX):
			var u: float = float(px) / float(TEX)
			var v: float = float(py) / float(TEX)
			# grain: integer frequencies, so the tile wraps in both directions
			var g: float = 0.90 + 0.10 * sin(u * TAU * 7.0 + v * TAU * 3.0 + float(bi))
			g *= 0.92 + 0.14 * clampf(edge[py], 0.0, 1.0)
			# STRINGERS, AND WHY THEY ARE NOT A THRESHOLD ANY MORE. They were
			# `if absf(sin(u*TAU*3 + v*TAU*19)) > 0.988: g *= 1.22` — two integer
			# frequencies crossing, thresholded, which is not a streak, it is a
			# LATTICE. The first render came back with a regular dotted grid over
			# every slab and the rock read as printed gift wrap. A smooth
			# multiply of the same field gives the pale streaks along the bedding
			# without ever quantising into dots.
			g *= 1.0 + 0.075 * sin(u * TAU * 3.0 + v * TAU * 11.0) * sin(v * TAU * 2.0)
			img.set_pixel(px, py, Color(clampf(base.r * g, 0.0, 1.0), clampf(base.g * g, 0.0, 1.0),
				clampf(base.b * g, 0.0, 1.0)))
	# hairline joints, crossing the beds at a steep angle
	var n_joint: int = rng.randi_range(3, 6)
	for j in range(n_joint):
		var x0: float = rng.randf_range(0.0, float(TEX))
		var sl: float = rng.randf_range(-0.32, 0.32)
		var ink: Color = Color(0.22, 0.19, 0.27)
		for py2 in range(TEX):
			var xx: int = int(round(x0 + sl * float(py2) + 2.0 * sin(float(py2) * 0.11)))
			# two pixels at 0.42: one at 0.32 disappeared entirely once the tint
			# stopped washing the texture out, and a bed with no joints in it is
			# a slab of soap
			for t in range(2):
				var p0: Color = img.get_pixel(posmod(xx + t, TEX), py2)
				img.set_pixel(posmod(xx + t, TEX), py2, p0.lerp(ink, 0.42))
	return ImageTexture.create_from_image(img)


## The dry face: chalk dust with darker flecks and a few conchoidal arcs, which
## is what a fresh fracture in a fine bed looks like from a metre away.
static func _paint_chalk(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for py in range(TEX):
		for px in range(TEX):
			var u: float = float(px) / float(TEX)
			var v: float = float(py) / float(TEX)
			var n: float = 0.5 + 0.5 * sin(u * TAU * 11.0 + sin(v * TAU * 5.0) * 2.1)
			n = n * 0.35 + 0.65 * rng.randf()
			var g: float = 0.86 + 0.14 * n
			img.set_pixel(px, py, Color(clampf(0.93 * g, 0.0, 1.0), clampf(0.905 * g, 0.0, 1.0),
				clampf(0.875 * g, 0.0, 1.0)))
	var n_arc: int = rng.randi_range(3, 6)
	for a in range(n_arc):
		var cxp: float = rng.randf_range(0.0, float(TEX))
		var cyp: float = rng.randf_range(0.0, float(TEX))
		var r0: float = rng.randf_range(9.0, 34.0)
		var a0: float = rng.randf_range(0.0, TAU)
		var a1: float = a0 + rng.randf_range(1.1, 3.0)
		var steps: int = int(ceil((a1 - a0) * r0 * 2.0)) + 8
		for i in range(steps):
			var t: float = float(i) / float(steps - 1)
			var ang: float = lerpf(a0, a1, t)
			var xx: int = posmod(int(round(cxp + cos(ang) * r0)), TEX)
			var yy: int = posmod(int(round(cyp + sin(ang) * r0)), TEX)
			var p: Color = img.get_pixel(xx, yy)
			img.set_pixel(xx, yy, p.lerp(Color(1.0, 0.99, 0.97), 0.5))
	return ImageTexture.create_from_image(img)


## The bathers: pale marble with faint veins in the rock's own lilac, so the
## bodies read as cut from the same quarry and not imported into it.
static func _paint_marble(rng: RandomNumberGenerator, vein: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph: float = rng.randf_range(0.0, TAU)
	var fx: int = rng.randi_range(2, 4)
	var fy: int = rng.randi_range(1, 3)
	var warp: float = rng.randf_range(0.9, 2.2)
	var vc: Color = vein.lerp(Color(0.62, 0.56, 0.70), 0.45)
	for py in range(TEX):
		for px in range(TEX):
			var u: float = float(px) / float(TEX)
			var v: float = float(py) / float(TEX)
			var t: float = sin(u * TAU * float(fx) + ph
				+ warp * sin(v * TAU * float(fy) + ph * 0.5))
			var k: float = clampf(1.0 - absf(t) * 5.2, 0.0, 1.0)
			var g: float = 0.965 + 0.035 * sin(u * TAU * 13.0 + v * TAU * 9.0)
			var base := Color(0.953 * g, 0.906 * g, 0.845 * g)
			img.set_pixel(px, py, base.lerp(vc, k * 0.55))
	return ImageTexture.create_from_image(img)


## A finish from DreamSkin with a code-drawn pattern as its albedo, world
## triplanar so one image runs unbroken across ten separate prisms. The two caps
## are the corpus's: a body at metallic 1.0 photographs black in a bare capture,
## and a strong emission stops paint reading as paint.
static func _dress(finish: String, tint: Color, tex: ImageTexture, uv: float,
		rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, tint, rng)
	m.albedo_color = tint
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.5
	m.uv1_scale = Vector3(uv, uv, uv)
	m.metallic = minf(m.metallic, 0.55)
	m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.40)
	return m


# ---------------------------------------------------------------------------
# geometry helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


## Smooth: the bathers.
static func _ball(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis) -> void:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 18
	sph.rings = 9
	var mi: MeshInstance3D = _add(root, sph, mat)
	# Basis.scaled() is diag * B in the PARENT frame, which on a sphere cancels
	# the rotation outright; the squash has to happen in the ball's own frame.
	mi.transform = Transform3D(b * _diag(r), c)


## Faceted: the boulders. Few segments on purpose — a rock is not a marble.
static func _facet(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis,
		rng: RandomNumberGenerator) -> void:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = rng.randi_range(6, 8)
	sph.rings = rng.randi_range(3, 4)
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(b * _diag(r), c)


static func _rod(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r: float) -> void:
	var v: Vector3 = b - a
	var l: float = v.length()
	if l < 0.0006:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r * 0.72
	cyl.bottom_radius = r
	cyl.height = l
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(v), (a + b) * 0.5)


## Emit one triangle, wound so its face points at `want`.
##
## GODOT WINDS FRONT FACES CLOCKWISE, and generate_normals() takes
## Plane(a, b, c).normal, which Godot builds as (a - c) x (a - b) — the NEGATIVE
## of the usual (b - a) x (c - a). Written the textbook way this file would have
## turned every slab inside out: perfectly consistent, and invisible in any
## render that draws back faces. Asking the intended normal instead cannot be off
## by a sign, which is dream_iso's own fix to the same trap.
static func _tri3(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, want: Vector3) -> void:
	var n: Vector3 = (a - c).cross(a - b)
	if n.length_squared() < 1.0e-16:
		return
	if n.dot(want) < 0.0:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)


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
