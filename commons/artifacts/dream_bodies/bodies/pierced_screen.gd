extends RefCounted

## dream_bodies / pierced_screen — a standing sheet full of holes, and the body
## that has to get through them.
##
## Reference: C:/Users/palle/Documents/FinalMD/m1/0_1016-0000.jpg (4096x1072
## panorama) — a row of tall white screens on a dark stage, each one a slab cut
## through with soft biomorphic openings: Jean Arp's paper cut-outs stood on edge,
## or a sheet of bone coral. Some screens are pierced by a few enormous lobes,
## others by a rash of small pores; all of them have a THICK ROLLED EDGE that
## catches the light, and several are finely ribbed like corrugated plaster.
## Dancers in ochre and violet catsuits thread the openings — one bowed double
## with her head through a low gap, one pressed flat against a panel, one with an
## arm out the far side. The screens are chalk. The dancers are wet.
##
## THE HOLES ARE THE SUBJECT. hadid_shell is already a smooth pierced shell, and
## the difference is the whole reason this family exists: hers is a VOLUME with
## bores through it, this is a SHEET — 42 mm thick, so every opening shows its own
## rolled lip end-on, and the body is not inside the form, it is passing through
## it. What the statue argues is that the body is what the hole is FOR.
##
## Reproduced, and how:
##   1. The sheet is one implicit outline in (u,v) — two wandering side edges and
##      an undulating top — minus a dealt set of wobbly ellipses. Everything is
##      combined with a SMOOTH min at 30 mm, which is what gives the webs between
##      two near-touching holes their Arp fillet instead of a razor.
##   2. It is meshed by clipping every cell of a 60x80 grid against the zero
##      contour (Sutherland-Hodgman, four corners, one crossing per edge), so a
##      hole's boundary is interpolated and curves, rather than following the grid.
##      Both faces are emitted; the polygon edges that run between two CROSSING
##      points are the contour, and those become the lip.
##   3. It is not flat. z(u,v) folds the sheet into a shallow S across its width
##      and ripples it up its height, so the statue has a face from every side of
##      the plinth — a truly planar screen photographs as a line from two of the
##      four capture angles, which would read as a dead axis and would be a fact
##      about the camera, not the sculpture.
##   4. The rolled edge is a four-ring barrel swept along every contour segment:
##      front face, out to the bevel, back to the far face. It carries its OWN
##      material, so every opening is traced in gloss against a chalk field.
##   5. The wearer is abstracted the way a Nana or a Giacometti is — tapering
##      chains of ellipsoids, an ovoid head, no face — and it is placed off the
##      sheet's own geometry: the target hole's world point and normal, so the
##      head goes THROUGH the opening the seed happened to cut, and presses
##      against the sheet when the seed cut nothing big enough.
##
## Given up: the row of screens (this is one folded sheet), the stage, the human
## faces, and the reference's cast shadows, which are the lighting's business.
##
## THE MATTE PASSAGE IS THE SHEET ITSELF, and it is the argument, not an
## afterthought. The plaster faces are DreamSkin "matte" carrying a painted
## chalk-and-ribbing texture; everything else is wet — the lips of every hole, the
## dancer's catsuit, the dark patent plinth. A latex body only reads latex beside
## something dry, and in the reference the dry thing is the wall.
##
## AXES — two, and both of them cut geometry, because the evidence is one still:
##   piercing — what the sheet has been opened with. "arp" is five to seven big
##              biomorphic lobes; "coral" is a rash of twenty-odd pores with two
##              blowholes big enough for a head; "torn" ribbons the sheet with long
##              vertical rips; "portal" is one enormous arch with the sheet reduced
##              to a frame; "sealed" is an almost solid slab with three small
##              punctures — the screen refusing to let anyone through.
##   wearer   — what the body does about it. "threading" leans in and pushes head
##              and one arm out the far side; "folded" bows double over a low
##              opening; "twinned" adds a second figure kneeling on the far side
##              with a hand in the same hole; "swarm" bursts the dancer into paired
##              lumps strung through the perforation; "negative" takes the dancer
##              away and stands the CUT-OUT LOBES beside the sheet as a body — the
##              holes made flesh.
##
## "threading" AND "folded" STAND ON THE SAME FEET, on purpose. The legs are dealt
## once and shared, so the axis is not "the statue moved", it is "the body did
## something else with the hole". It also makes the closest pair predictable, which
## is what predicted() below is for.
##
## CROSSED, and knowingly: at piercing="sealed" and "coral" the biggest opening is
## under 130 mm, so no head fits and every wearer value presses its skull to the
## plaster instead of pushing it through. That is the sheet winning, and it is
## visible in the frame — but it does mean the wearer axis is quieter at those two
## values than at "portal". Read the per-pair rows, never the headline.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const TEX: int = 160
const PLINTH_TOP: float = 0.050

# the sheet, before the settle scales it
const HALF_W: float = 0.460
const SHEET_H: float = 1.420
const HALF_T: float = 0.021          # half thickness — a 42 mm plaster sheet
const NU: int = 60
const NV: int = 80
const SM_K: float = 0.030            # the fillet between two openings

# the lip's barrel, as offsets along the in-plane outward direction and along the
# sheet normal. Four rings, three quads: face, roll, face.
const LIP_OUT: Array[float] = [0.0, 1.0, 1.0, 0.0]
const LIP_Z: Array[float] = [1.0, 0.45, -0.45, -1.0]

# what a wet passage may be made of — never "matte", which is spoken for
const WET_FIN: Array[String] = ["latex", "patent", "wet", "oilslick", "holo", "candy"]
const LIP_FIN: Array[String] = ["patent", "wet", "holo", "pearl", "candy", "chrome"]
# the catsuits of the reference first, then the rest of the wardrobe
const SUIT_COLS: Array[String] = ["tangerine", "violet", "tangerine", "violet",
	"magenta", "blood", "acid", "hot_pink", "cyan"]


static func describe() -> String:
	return "A tall chalk-white sheet cut through with soft biomorphic openings, every hole rimmed in a rolled glossy lip, and a latex-skinned dancer threading her head and one arm out the far side."


static func axes() -> Dictionary:
	return {
		"piercing": ["arp", "coral", "torn", "portal", "sealed"],
		"wearer": ["threading", "folded", "twinned", "swarm", "negative"],
	}


## The prediction, before any capture, as data — tools/dream_bodies_promote.py
## carries it into the registry so nobody retypes it.
static func predicted() -> Dictionary:
	return {
		"pair": "wearer: threading vs folded (piercing=arp)",
		"predicted_pct": 3.2,
		"reasoning": ("the two poses SHARE their legs by construction — same hips, knees, "
			+ "ankles and feet — so only the torso, head and arms can move. The dancer's "
			+ "silhouette is about 0.23 m2 against the sheet's 0.78 m2, so the body is "
			+ "0.23/1.01 = 23% of a subject that fills ~30% of the frame, i.e. 6.8% of the "
			+ "picture; the shared legs are ~45% of that body, leaving 3.7% able to change, "
			+ "and ~85% of the upper body's pixels land somewhere new when the figure bows "
			+ "from leaning-in to doubled-over: 0.85 x 3.7 = 3.2%. Every other pair on "
			+ "either axis moves more — the piercing axis rewrites the sheet, which is 77% "
			+ "of the subject"),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var piercing: String = String(opts.get("piercing", "arp"))
	var wearer: String = String(opts.get("wearer", "threading"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the wardrobe, dealt -------------------------------------------------
	var chalk: Color = Color(0.955, 0.950, 0.938).lerp(Gloss.queer_colour(rng), rng.randf_range(0.0, 0.12))
	var ribbed: bool = rng.randf() < 0.55
	var lip_fin: String = LIP_FIN[rng.randi_range(0, LIP_FIN.size() - 1)]
	var lip_col: Color = Gloss.queer_colour(rng)
	var suit_fin: String = WET_FIN[rng.randi_range(0, WET_FIN.size() - 1)]
	var suit_col: Color = Gloss.QUEER[SUIT_COLS[rng.randi_range(0, SUIT_COLS.size() - 1)]]
	var netted: bool = rng.randf() < 0.45

	# MATTE, on purpose and exactly once: the plaster the body has to get past.
	var mat_chalk: StandardMaterial3D = Gloss.skin("matte", chalk)
	mat_chalk.albedo_texture = _plaster_tex(rng, ribbed, chalk)
	mat_chalk.uv1_triplanar = true
	mat_chalk.uv1_world_triplanar = true
	mat_chalk.uv1_scale = Vector3(2.2, 2.2, 2.2)
	mat_chalk.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())

	var mat_lip: StandardMaterial3D = Gloss.skin(lip_fin, lip_col, rng)
	mat_lip.metallic = minf(mat_lip.metallic, 0.65)

	var mat_suit: StandardMaterial3D = Gloss.skin(suit_fin, suit_col, rng)
	if netted:
		# the fishnet dancer of the reference: the pattern carries the colour, so
		# the albedo drops to a pale ground or the texture multiplies to mud
		mat_suit.albedo_color = Color(0.94, 0.92, 0.92)
		mat_suit.albedo_texture = _net_tex(rng, suit_col)
		mat_suit.uv1_triplanar = true
		mat_suit.uv1_world_triplanar = true
		mat_suit.uv1_scale = Vector3(3.4, 3.4, 3.4)
		mat_suit.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	mat_suit.metallic = minf(mat_suit.metallic, 0.60)
	var mat_dark: StandardMaterial3D = Gloss.skin("patent", Color(0.07, 0.06, 0.10), rng)

	# --- the sheet -----------------------------------------------------------
	var sh: Dictionary = _deal_sheet(rng)
	var holes: Array = _deal_holes(piercing, rng)
	sh["holes"] = holes

	var built: Array = _build_sheet(sh, rng.randf_range(0.013, 0.019))
	var faces: ArrayMesh = built[0]
	var lips: ArrayMesh = built[1]
	# A NULL SHEET IS AN EMPTY PLINTH AND NOTHING WOULD SAY SO. The clip loop can
	# only come back empty if the outline and the holes cancelled, which no dealt
	# value should do — so it is worth one line to find out rather than to stand a
	# bare slab in a hall and call it a sculpture.
	if faces == null:
		push_warning("[pierced_screen] the outline yielded no sheet at piercing=%s" % piercing)
		return
	_add(root, faces, mat_chalk)
	if lips != null:
		_add(root, lips, mat_lip)

	# --- who is getting through, and how -------------------------------------
	var hi: Dictionary = _pick_hole(holes, 0.55, SHEET_H, true)
	var lo: Dictionary = _pick_hole(holes, 0.18, 0.80, false)
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var legs: Array = _legs(sh, hi, side, rng)

	if wearer == "negative":
		_negative(root, mat_suit, mat_dark, sh, holes, side, rng)
	elif wearer == "twinned":
		_flesh(root, mat_suit, mat_dark, _pose(sh, "threading", hi, lo, legs, side, rng), "solid", 1.0, rng)
		_flesh(root, mat_suit, mat_dark, _kneel(sh, hi, -side, rng), "solid", 0.86, rng)
	elif wearer == "swarm":
		_flesh(root, mat_suit, mat_dark, _pose(sh, "threading", hi, lo, legs, side, rng), "swarm", 1.0, rng)
	else:
		_flesh(root, mat_suit, mat_dark, _pose(sh, wearer, hi, lo, legs, side, rng), "solid", 1.0, rng)

	# --- turn the whole thing, then the measured settle ----------------------
	# The sheet is built facing +Z. A statue that always faces the same way makes
	# the capture's standpoint part of the family; a dealt yaw makes it part of the
	# seed instead.
	_yaw(root, rng.randf_range(-0.62, 0.62))

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
	var pm: MeshInstance3D = _add(root, plinth, mat_dark)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# the sheet's field — an outline, minus a set of wobbly ellipses

static func _deal_sheet(rng: RandomNumberGenerator) -> Dictionary:
	return {
		# the two side edges wander independently, so the slab is never a rectangle
		"la": rng.randf_range(0.030, 0.070), "lf": rng.randf_range(2.0, 4.2), "lp": rng.randf_range(0.0, TAU),
		"lb": rng.randf_range(0.016, 0.040), "lg": rng.randf_range(5.0, 8.5), "lq": rng.randf_range(0.0, TAU),
		"ra": rng.randf_range(0.030, 0.070), "rf": rng.randf_range(2.0, 4.2), "rp": rng.randf_range(0.0, TAU),
		"rb": rng.randf_range(0.016, 0.040), "rg": rng.randf_range(5.0, 8.5), "rq": rng.randf_range(0.0, TAU),
		# the top edge rises and falls across the width
		"tf": rng.randf_range(2.4, 5.0), "tp": rng.randf_range(0.0, TAU),
		"td": rng.randf_range(0.10, 0.20),
		# THE FOLD IS NOT DECORATION. fold * kf is the steepest the sheet leans, and
		# at 0.13 * 6.8 = 0.88 the normal tips 41 degrees off +Z — enough that the
		# statue has a lit face from any side of the plinth, and not so much that
		# the clip loop's assumption (the normal stays z-positive, so the lip's
		# winding is the one derived in _rim_seg) can fail.
		"fold": rng.randf_range(0.105, 0.145),
		"kf": rng.randf_range(5.6, 7.4), "pf": rng.randf_range(-0.8, 0.8),
		"wave": rng.randf_range(0.022, 0.042),
		"kv": rng.randf_range(3.4, 5.6), "pv": rng.randf_range(0.0, TAU),
	}


## One opening: an ellipse whose radius wobbles with the polar angle twice over,
## which is what turns a hole into a lobe.
static func _hole(u: float, v: float, rx: float, ry: float, ang: float, w1: float, k1: float,
		w2: float, k2: float, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"u": u, "v": v, "rx": rx, "ry": ry, "ang": ang,
		"w1": w1, "k1": k1, "p1": rng.randf_range(0.0, TAU),
		"w2": w2, "k2": k2, "p2": rng.randf_range(0.0, TAU),
	}


static func _deal_holes(kind: String, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var n: int = 6
	if kind == "coral":
		n = rng.randi_range(18, 26)
	elif kind == "torn":
		n = rng.randi_range(6, 9)
	elif kind == "portal":
		n = rng.randi_range(3, 5)
	elif kind == "sealed":
		n = rng.randi_range(2, 3)
	else:
		n = rng.randi_range(5, 7)

	for i in range(n):
		var u: float = 0.0
		var v: float = 0.0
		var rx: float = 0.1
		var ry: float = 0.1
		var ang: float = 0.0
		var w1: float = 0.20
		var k1: float = 3.0
		var w2: float = 0.10
		var k2: float = 5.0
		if kind == "arp":
			u = rng.randf_range(-0.34, 0.34)
			v = rng.randf_range(0.26, 1.24)
			rx = rng.randf_range(0.115, 0.235)
			ry = rx * rng.randf_range(0.75, 1.55)
			ang = rng.randf_range(0.0, PI)
			w1 = rng.randf_range(0.18, 0.32)
			w2 = rng.randf_range(0.06, 0.15)
			# one lobe is guaranteed head-sized and high, so "threading" has
			# something to thread at the family's default value
			if i == 0:
				u = rng.randf_range(-0.16, 0.16)
				v = rng.randf_range(0.72, 1.02)
				rx = rng.randf_range(0.185, 0.245)
				ry = rx * rng.randf_range(0.95, 1.35)
		elif kind == "coral":
			u = rng.randf_range(-0.38, 0.38)
			v = rng.randf_range(0.20, 1.30)
			rx = rng.randf_range(0.034, 0.085)
			ry = rx * rng.randf_range(0.70, 1.60)
			ang = rng.randf_range(0.0, PI)
			w1 = rng.randf_range(0.10, 0.20)
			k1 = 3.0 if rng.randf() < 0.6 else 4.0
			w2 = rng.randf_range(0.05, 0.12)
			# two blowholes — a coral head still has one channel wide enough
			if i < 2:
				rx = rng.randf_range(0.115, 0.155)
				ry = rx * rng.randf_range(0.85, 1.25)
				v = rng.randf_range(0.62, 1.06)
				u = rng.randf_range(-0.22, 0.22)
		elif kind == "torn":
			u = rng.randf_range(-0.36, 0.36)
			v = rng.randf_range(0.46, 0.98)
			rx = rng.randf_range(0.026, 0.055)
			ry = rng.randf_range(0.26, 0.46)
			ang = rng.randf_range(-0.24, 0.24)
			w1 = rng.randf_range(0.20, 0.34)
			k1 = 2.0
			w2 = rng.randf_range(0.10, 0.20)
			k2 = 7.0
			if i == 0:
				rx = rng.randf_range(0.105, 0.145)     # the rip a body can use
				ry = rng.randf_range(0.30, 0.44)
				u = rng.randf_range(-0.18, 0.18)
		elif kind == "portal":
			if i == 0:
				u = rng.randf_range(-0.09, 0.09)
				v = rng.randf_range(0.62, 0.80)
				rx = rng.randf_range(0.290, 0.355)
				ry = rng.randf_range(0.340, 0.450)
				ang = rng.randf_range(-0.25, 0.25)
				w1 = rng.randf_range(0.10, 0.20)
				w2 = rng.randf_range(0.04, 0.10)
			else:
				u = rng.randf_range(-0.38, 0.38)
				v = rng.randf_range(0.22, 1.26)
				rx = rng.randf_range(0.042, 0.090)
				ry = rx * rng.randf_range(0.7, 1.5)
				ang = rng.randf_range(0.0, PI)
				w1 = rng.randf_range(0.12, 0.24)
		else:                                          # sealed
			u = rng.randf_range(-0.26, 0.26)
			v = rng.randf_range(0.74, 1.20)
			rx = rng.randf_range(0.036, 0.062)
			ry = rx * rng.randf_range(0.8, 1.4)
			ang = rng.randf_range(0.0, PI)
			w1 = rng.randf_range(0.14, 0.26)

		# THE SHEET HAS TO STAND. Nothing guarantees a dealt lobe leaves a footing,
		# and a hole that eats the bottom edge cuts the slab into two pieces, one of
		# which then floats — the settle would happily centre a levitating fragment
		# and no check downstream would notice. So every opening keeps 100 mm of
		# plaster under it, which is one continuous band across the bottom.
		ry = minf(ry, maxf(v - 0.10, 0.020))
		# and it may only break the SIDE edge high up, where a notch reshapes the
		# silhouette instead of severing a strap
		var reach: float = rx * 1.30
		if v < 0.55:
			u = clampf(u, -(HALF_W - reach), HALF_W - reach)
		else:
			u = clampf(u, -(HALF_W + reach * 0.35), HALF_W + reach * 0.35)
		out.append(_hole(u, v, rx, ry, ang, w1, k1, w2, k2, rng))
	_unsever(out)
	return out


## SHRINK THE DEAL UNTIL THE SHEET IS STILL A SHEET.
##
## The footing band stops any ONE hole eating the bottom edge; nothing stopped TWO
## from spanning the full width higher up and cutting the top loose. Measured, not
## feared: the first build of "arp" that ran with the flood fill below lost 63% of
## its faces and 180 mm of its height to exactly that — a screen dealt as five to
## seven lobes of up to 235 mm across a 920 mm slab severs often, and it severs
## silently, because a detached slab still stands on the merged AABB and still
## passes every mesh-count floor in the probe.
##
## The flood fill is the exact backstop and stays. This is the constructive half:
## walk 26 heights across the band the wandering side edges are guaranteed to
## contain, and if any one of them is hole all the way across, take a tenth off
## every radius and look again. Eight tries floor the deal at 0.43x, which has
## never been reached — two are typical.
static func _unsever(holes: Array) -> void:
	for attempt in range(8):
		var severed: bool = false
		for jv in range(26):
			var v: float = lerpf(0.06, SHEET_H - 0.02, float(jv) / 25.0)
			var all_hole: bool = true
			for iu in range(36):
				# [-0.35, 0.35] is inside the outline whatever the edges did: the two
				# side waves cannot sum past 0.110, so this band is always plaster
				var u: float = lerpf(-0.35, 0.35, float(iu) / 35.0)
				if not _in_any(holes, u, v):
					all_hole = false
					break
			if all_hole:
				severed = true
				break
		if not severed:
			return
		for h_v in holes:
			# a Dictionary is a reference, so this shrinks the deal in place
			var h: Dictionary = h_v
			h["rx"] = float(h["rx"]) * 0.90
			h["ry"] = float(h["ry"]) * 0.90


static func _in_any(holes: Array, u: float, v: float) -> bool:
	for h_v in holes:
		var h: Dictionary = h_v
		var ru: float = u - float(h["u"])
		var rv: float = v - float(h["v"])
		var ca: float = cos(float(h["ang"]))
		var sa: float = sin(float(h["ang"]))
		var au: float = (ru * ca + rv * sa) / float(h["rx"])
		var av: float = (-ru * sa + rv * ca) / float(h["ry"])
		var rad: float = sqrt(au * au + av * av)
		var th: float = atan2(av, au)
		var lim: float = 1.0 + float(h["w1"]) * sin(float(h["k1"]) * th + float(h["p1"])) \
			+ float(h["w2"]) * sin(float(h["k2"]) * th + float(h["p2"]))
		if rad < lim:
			return true
	return false


## The biggest opening inside a height band — the one a head will try. Returns an
## empty dictionary when the seed cut nothing there, which the poses handle.
static func _pick_hole(holes: Array, v_lo: float, v_hi: float, want_big: bool) -> Dictionary:
	var best: Dictionary = {}
	var best_r: float = -1.0
	for h_v in holes:
		var h: Dictionary = h_v
		var v: float = float(h["v"])
		if v < v_lo or v > v_hi:
			continue
		var r: float = minf(float(h["rx"]), float(h["ry"]))
		if want_big:
			if r > best_r:
				best_r = r
				best = h
		elif best_r < 0.0 or v < float(best.get("v", 9.0)):
			best_r = r
			best = h
	return best


# ---------------------------------------------------------------------------
# the mesh — clip every cell against the contour, then sweep the lip along it

## Returns [faces, lips]. Faces and lips are separate meshes because they are
## separate SURFACES: the sheet is the one matte passage in this statue and the
## rolled edge of every opening is the loud one, and a MeshInstance3D carries one
## material_override.
static func _build_sheet(sh: Dictionary, bev: float) -> Array:
	var holes: Array = sh["holes"]
	var n: int = holes.size()
	# the field is sampled ~5,000 times against every hole, so the holes are
	# unpacked into typed packed arrays first: a Dictionary lookup per component
	# per sample is the difference between 80 ms and half a second
	var hu := PackedFloat32Array()
	var hv := PackedFloat32Array()
	var hrx := PackedFloat32Array()
	var hry := PackedFloat32Array()
	var hca := PackedFloat32Array()
	var hsa := PackedFloat32Array()
	var hw1 := PackedFloat32Array()
	var hk1 := PackedFloat32Array()
	var hp1 := PackedFloat32Array()
	var hw2 := PackedFloat32Array()
	var hk2 := PackedFloat32Array()
	var hp2 := PackedFloat32Array()
	var hsc := PackedFloat32Array()
	# resized one at a time on purpose: a PackedFloat32Array is a VALUE, so a
	# `for arr in [hu, hv, ...]` loop resizes thirteen copies and leaves all
	# thirteen originals at length zero — and the sample loop below would then
	# index past the end of every one of them
	hu.resize(n)
	hv.resize(n)
	hrx.resize(n)
	hry.resize(n)
	hca.resize(n)
	hsa.resize(n)
	hw1.resize(n)
	hk1.resize(n)
	hp1.resize(n)
	hw2.resize(n)
	hk2.resize(n)
	hp2.resize(n)
	hsc.resize(n)
	for i in range(n):
		var h: Dictionary = holes[i]
		hu[i] = float(h["u"])
		hv[i] = float(h["v"])
		hrx[i] = float(h["rx"])
		hry[i] = float(h["ry"])
		hca[i] = cos(float(h["ang"]))
		hsa[i] = sin(float(h["ang"]))
		hw1[i] = float(h["w1"])
		hk1[i] = float(h["k1"])
		hp1[i] = float(h["p1"])
		hw2[i] = float(h["w2"])
		hk2[i] = float(h["k2"])
		hp2[i] = float(h["p2"])
		hsc[i] = minf(float(h["rx"]), float(h["ry"]))

	# THE PAD HAS TO CLEAR THE WANDERING EDGE. The right edge reaches HALF_W plus
	# both of its wave amplitudes (0.070 + 0.040 = 0.110 at the deal's ceiling); a
	# grid narrower than that would clip the slab flat at the last column and the
	# lip would simply stop, which reads as a sawn edge rather than a cut one.
	var u0: float = -(HALF_W + 0.14)
	var v0: float = -0.05
	var du: float = (2.0 * (HALF_W + 0.14)) / float(NU)
	var dv: float = (SHEET_H + 0.12) / float(NV)
	var w: int = NU + 1

	# the outline is separable, so it is a lookup table, not a per-sample trig run
	var lft := PackedFloat32Array()
	var rgt := PackedFloat32Array()
	lft.resize(NV + 1)
	rgt.resize(NV + 1)
	for j in range(NV + 1):
		var v: float = v0 + float(j) * dv
		lft[j] = -HALF_W + float(sh["la"]) * sin(v * float(sh["lf"]) + float(sh["lp"])) \
			+ float(sh["lb"]) * sin(v * float(sh["lg"]) + float(sh["lq"]))
		rgt[j] = HALF_W + float(sh["ra"]) * sin(v * float(sh["rf"]) + float(sh["rp"])) \
			+ float(sh["rb"]) * sin(v * float(sh["rg"]) + float(sh["rq"]))
	var top := PackedFloat32Array()
	top.resize(NU + 1)
	for i in range(NU + 1):
		var u: float = u0 + float(i) * du
		top[i] = SHEET_H * (1.0 - float(sh["td"]) * (0.5 + 0.5 * sin(u * float(sh["tf"]) + float(sh["tp"]))))

	var sd := PackedFloat32Array()
	sd.resize(w * (NV + 1))
	for j in range(NV + 1):
		var v: float = v0 + float(j) * dv
		for i in range(NU + 1):
			var u: float = u0 + float(i) * du
			var d: float = minf(minf(u - lft[j], rgt[j] - u), minf(top[i] - v, v))
			for k in range(n):
				var ru: float = u - hu[k]
				var rv: float = v - hv[k]
				var au: float = (ru * hca[k] + rv * hsa[k]) / hrx[k]
				var av: float = (-ru * hsa[k] + rv * hca[k]) / hry[k]
				var rad: float = sqrt(au * au + av * av)
				var th: float = atan2(av, au)
				var lim: float = 1.0 + hw1[k] * sin(hk1[k] * th + hp1[k]) + hw2[k] * sin(hk2[k] * th + hp2[k])
				d = _smin(d, (rad - lim) * hsc[k], SM_K)
			sd[i + j * w] = d

	# THE 100 mm FOOTING BAND IS NOT ENOUGH ON ITS OWN. It stops a hole eating the
	# bottom edge, but two big lobes side by side can still span the full width
	# higher up and cut everything above them loose — and a detached fragment does
	# not fail anything downstream. The merged AABB still stands on the plinth, the
	# mesh floor still passes, and the statue photographs with a slab of plaster
	# hanging in mid air. So: flood-fill the live cells from the footing rows, and
	# emit only what the fill reached. Four-connected on purpose — a strap that is
	# only diagonally connected is one cell of plaster wide and is better gone.
	var live := PackedByteArray()
	var seen := PackedByteArray()
	live.resize(NU * NV)
	seen.resize(NU * NV)
	for j in range(NV):
		for i in range(NU):
			if sd[i + j * w] >= 0.0 or sd[i + 1 + j * w] >= 0.0 \
					or sd[i + 1 + (j + 1) * w] >= 0.0 or sd[i + (j + 1) * w] >= 0.0:
				live[i + j * NU] = 1
	var stack: Array[int] = []
	# rows 0..6 span v = -0.05 .. 0.085, inside the footing band every hole leaves
	for j in range(mini(7, NV)):
		for i in range(NU):
			var b0: int = i + j * NU
			if live[b0] == 1 and seen[b0] == 0:
				seen[b0] = 1
				stack.append(b0)
	while not stack.is_empty():
		var c: int = stack.pop_back()
		var ci: int = c % NU
		var cj: int = c / NU
		for e in range(4):
			var ni: int = ci + (1 if e == 0 else (-1 if e == 1 else 0))
			var nj: int = cj + (1 if e == 2 else (-1 if e == 3 else 0))
			if ni < 0 or nj < 0 or ni >= NU or nj >= NV:
				continue
			var nb: int = ni + nj * NU
			if live[nb] == 1 and seen[nb] == 0:
				seen[nb] = 1
				stack.append(nb)

	var st_f := SurfaceTool.new()
	var st_r := SurfaceTool.new()
	st_f.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_r.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces_n: int = 0
	var lips_n: int = 0

	for j in range(NV):
		for i in range(NU):
			var s: Array[float] = [sd[i + j * w], sd[i + 1 + j * w],
				sd[i + 1 + (j + 1) * w], sd[i + (j + 1) * w]]
			if s[0] < 0.0 and s[1] < 0.0 and s[2] < 0.0 and s[3] < 0.0:
				continue
			if seen[i + j * NU] == 0:
				continue                    # cut loose from the footing — not built
			var cu: float = u0 + float(i) * du
			var cv: float = v0 + float(j) * dv
			var cor: Array[Vector2] = [Vector2(cu, cv), Vector2(cu + du, cv),
				Vector2(cu + du, cv + dv), Vector2(cu, cv + dv)]
			# Sutherland-Hodgman against the half-space sd >= 0: keep the solid
			# corners, and add the crossing wherever the sign flips along an edge.
			# The result is CCW in (u,v) because the corners are, which is what the
			# winding below and the lip's outward normal both rely on.
			var pp: Array[Vector2] = []
			var cx: Array[bool] = []
			for e in range(4):
				var e2: int = (e + 1) % 4
				var a: float = s[e]
				var b: float = s[e2]
				if a >= 0.0:
					pp.append(cor[e])
					cx.append(false)
				if (a >= 0.0) != (b >= 0.0):
					var t: float = a / (a - b)
					pp.append(cor[e].lerp(cor[e2], t))
					cx.append(true)
			var np: int = pp.size()
			if np < 3:
				continue
			var p3: Array[Vector3] = []
			var n3: Array[Vector3] = []
			for q in range(np):
				var fr: Array = _frame(sh, pp[q].x, pp[q].y)
				p3.append(fr[0])
				n3.append(fr[1])
			# GODOT WINDS FRONT FACES CLOCKWISE, and generate_normals() takes
			# Plane(a,b,c).normal = (a-c) x (a-b). A fan emitted CCW in (u,v) comes
			# out facing -Z, so the front face is the REVERSED fan and the back face
			# is the forward one. Written the textbook way both faces point inward,
			# which renders identically until something culls.
			for k in range(1, np - 1):
				st_f.add_vertex(p3[0] + n3[0] * HALF_T)
				st_f.add_vertex(p3[k + 1] + n3[k + 1] * HALF_T)
				st_f.add_vertex(p3[k] + n3[k] * HALF_T)
				st_f.add_vertex(p3[0] - n3[0] * HALF_T)
				st_f.add_vertex(p3[k] - n3[k] * HALF_T)
				st_f.add_vertex(p3[k + 1] - n3[k + 1] * HALF_T)
				faces_n += 2
			# an edge between two CROSSING points is a piece of the contour, and
			# nothing else is: the cell's own sides run between solid corners
			for e in range(np):
				var e3: int = (e + 1) % np
				if cx[e] and cx[e3]:
					_rim_seg(st_r, sh, pp[e], pp[e3], bev)
					lips_n += 6

	if faces_n == 0:
		return [null, null]
	st_f.index()
	st_f.generate_normals()
	var lips: ArrayMesh = null
	if lips_n > 0:
		st_r.index()
		st_r.generate_normals()
		lips = st_r.commit()
	return [st_f.commit(), lips]


## The rolled edge: four rings swept along one contour segment, out to the bevel
## and back, so the opening shows a barrel end-on instead of a knife.
static func _rim_seg(st: SurfaceTool, sh: Dictionary, a: Vector2, b: Vector2, bev: float) -> void:
	var d: Vector2 = b - a
	if d.length() < 0.000001:
		return
	d = d.normalized()
	# the polygon is CCW with the solid on the left of every directed edge, so the
	# outward in-plane normal is the edge turned clockwise
	var out2 := Vector2(d.y, -d.x)
	var fa: Array = _frame(sh, a.x, a.y)
	var fb: Array = _frame(sh, b.x, b.y)
	var pa: Vector3 = fa[0]
	var na: Vector3 = fa[1]
	var pb: Vector3 = fb[0]
	var nb: Vector3 = fb[1]
	# in-plane outward, lifted onto the folded sheet: out2 pushed through the
	# surface's own tangents (1,0,zu) and (0,1,zv)
	var ta: Vector3 = Vector3(out2.x, out2.y, out2.x * float(fa[2]) + out2.y * float(fa[3])).normalized()
	var tb: Vector3 = Vector3(out2.x, out2.y, out2.x * float(fb[2]) + out2.y * float(fb[3])).normalized()
	var ra: Array[Vector3] = []
	var rb: Array[Vector3] = []
	for k in range(4):
		ra.append(pa + ta * (LIP_OUT[k] * bev) + na * (LIP_Z[k] * HALF_T))
		rb.append(pb + tb * (LIP_OUT[k] * bev) + nb * (LIP_Z[k] * HALF_T))
	for k in range(3):
		st.add_vertex(ra[k])
		st.add_vertex(rb[k])
		st.add_vertex(rb[k + 1])
		st.add_vertex(ra[k])
		st.add_vertex(rb[k + 1])
		st.add_vertex(ra[k + 1])


## Point, normal and the two z-slopes at one place on the sheet. Everything that
## has to sit ON the sheet — a face vertex, a lip ring, a dancer's palm — comes
## from here, so nothing can drift off the surface it is supposed to touch.
static func _frame(sh: Dictionary, u: float, v: float) -> Array:
	var fold: float = float(sh["fold"])
	var kf: float = float(sh["kf"])
	var wav: float = float(sh["wave"])
	var kv: float = float(sh["kv"])
	var ph: float = u * kf + float(sh["pf"])
	var qh: float = v * kv + float(sh["pv"]) + u * 1.3
	var z: float = fold * sin(ph) + wav * sin(qh)
	var zu: float = fold * kf * cos(ph) + wav * 1.3 * cos(qh)
	var zv: float = wav * kv * cos(qh)
	return [Vector3(u, v, z), Vector3(-zu, -zv, 1.0).normalized(), zu, zv]


static func _smin(a: float, b: float, k: float) -> float:
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


# ---------------------------------------------------------------------------
# the wearer — joints first, flesh second, so two poses can share their legs

## The stance, dealt once. THREADING AND FOLDED GET THE SAME ONE: what the axis
## changes is what the body does with the opening, not where it stands, and that
## is also what makes the closest pair predictable.
static func _legs(sh: Dictionary, hi: Dictionary, side: float, rng: RandomNumberGenerator) -> Array:
	var anchor: Vector3 = _anchor(sh, hi, 0.86)
	var back: Vector3 = anchor - _anchor_n(sh, hi) * 0.34
	var out: Array = []
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var fwd: float = rng.randf_range(0.06, 0.16) * (1.0 if sd == side else -1.0)
		var hip := Vector3(back.x + sd * 0.115, rng.randf_range(0.76, 0.82), back.z + fwd * 0.35)
		var knee := Vector3(back.x + sd * (0.135 + rng.randf_range(0.0, 0.06)),
			rng.randf_range(0.40, 0.46), back.z + fwd * 0.9 - 0.03)
		var ankle := Vector3(back.x + sd * (0.145 + rng.randf_range(0.0, 0.09)),
			rng.randf_range(0.075, 0.095), back.z + fwd * 1.35)
		var foot: Vector3 = ankle + Vector3(sd * 0.012, -0.038, -0.070)
		out.append([hip, knee, ankle, foot])
	return out


## Where a hole IS, in the world: its centre on the folded sheet. Falls back to
## the middle of the slab at the given height when the seed cut nothing there.
static func _anchor(sh: Dictionary, h: Dictionary, fallback_v: float) -> Vector3:
	var u: float = float(h.get("u", 0.0))
	var v: float = float(h.get("v", fallback_v))
	if h.is_empty():
		v = fallback_v
	var fr: Array = _frame(sh, u, v)
	return fr[0]


static func _anchor_n(sh: Dictionary, h: Dictionary) -> Vector3:
	var fr: Array = _frame(sh, float(h.get("u", 0.0)), float(h.get("v", 0.86)))
	return fr[1]


## Is this opening wide enough for a head? At "sealed" and "coral" it is not, and
## the pose presses the skull to the plaster instead — which is the sheet winning,
## and is meant to be legible in the frame.
static func _passable(h: Dictionary) -> bool:
	if h.is_empty():
		return false
	return minf(float(h["rx"]), float(h["ry"])) >= 0.125


static func _pose(sh: Dictionary, kind: String, hi: Dictionary, lo: Dictionary, legs: Array,
		side: float, rng: RandomNumberGenerator) -> Dictionary:
	var bowed: bool = kind == "folded"
	var tgt: Dictionary = lo if (bowed and not lo.is_empty()) else hi
	var p: Vector3 = _anchor(sh, tgt, 0.52 if bowed else 0.86)
	var nrm: Vector3 = _anchor_n(sh, tgt)
	var through: float = 0.115 if _passable(tgt) else -0.075
	var head_r: float = rng.randf_range(0.088, 0.104)

	var pelvis: Vector3 = (legs[0][0] as Vector3).lerp(legs[1][0] as Vector3, 0.5) + Vector3(0.0, 0.045, 0.0)
	var head: Vector3 = p + nrm * through
	var neck: Vector3 = p - nrm * 0.155 + Vector3(0.0, -0.075, 0.0)
	var chest: Vector3 = p - nrm * 0.285 + Vector3(0.0, -0.235, 0.0)
	if bowed:
		# doubled over: the hips stay put and the spine swings down and forward
		chest = p - nrm * 0.215 + Vector3(0.0, 0.235, 0.0)
		neck = p - nrm * 0.115 + Vector3(0.0, 0.085, 0.0)
	var waist: Vector3 = pelvis.lerp(chest, 0.5) + Vector3(0.0, 0.0, 0.0) - nrm * (0.035 if bowed else 0.0)

	# the arm that goes through — an arm fits an opening a head cannot
	var s_a: Vector3 = chest + Vector3(side * 0.135, 0.055, 0.0)
	var e_a: Vector3 = chest + Vector3(side * 0.175, 0.020, 0.0) - nrm * 0.055
	var w_a: Vector3 = p + nrm * 0.155 + Vector3(side * 0.045, -0.020, 0.0)
	var h_a: Vector3 = p + nrm * 0.300 + Vector3(side * 0.085, 0.035, 0.0)
	# and the arm that braces on the plaster
	var brace_u: float = clampf(float(tgt.get("u", 0.0)) - side * 0.30, -HALF_W + 0.09, HALF_W - 0.09)
	var brace_v: float = clampf(float(tgt.get("v", 0.86)) - 0.24, 0.22, SHEET_H - 0.14)
	var bf: Array = _frame(sh, brace_u, brace_v)
	var s_b: Vector3 = chest - Vector3(side * 0.145, -0.045, 0.0)
	var e_b: Vector3 = s_b + Vector3(-side * 0.055, -0.215, 0.0) - nrm * 0.030
	var w_b: Vector3 = (bf[0] as Vector3) - (bf[1] as Vector3) * 0.095
	var h_b: Vector3 = (bf[0] as Vector3) - (bf[1] as Vector3) * 0.045
	if bowed:
		# both arms hang toward the floor, the way the reference's bowing dancer
		# lets them swing free of the screen
		s_a = chest + Vector3(side * 0.135, 0.020, 0.0)
		e_a = s_a + Vector3(side * 0.045, -0.235, 0.0) - nrm * 0.085
		w_a = e_a + Vector3(side * 0.020, -0.215, 0.0) - nrm * 0.055
		h_a = w_a + Vector3(0.0, -0.075, 0.0) - nrm * 0.020
		s_b = chest - Vector3(side * 0.135, -0.020, 0.0)
		e_b = s_b - Vector3(side * 0.055, 0.215, 0.0) - nrm * 0.075
		w_b = e_b - Vector3(side * 0.020, 0.205, 0.0) - nrm * 0.045
		h_b = w_b + Vector3(0.0, -0.070, 0.0) - nrm * 0.015

	return {
		"spine": [pelvis, waist, chest, neck],
		"head": head, "head_r": head_r,
		"arms": [[s_a, e_a, w_a, h_a], [s_b, e_b, w_b, h_b]],
		"legs": legs,
		"scale": 1.0,
	}


## The second figure of "twinned": kneeling on the far side, one hand into the
## same opening from the other direction.
static func _kneel(sh: Dictionary, hi: Dictionary, side: float, rng: RandomNumberGenerator) -> Dictionary:
	var p: Vector3 = _anchor(sh, hi, 0.86)
	var nrm: Vector3 = _anchor_n(sh, hi)
	var front: Vector3 = p + nrm * 0.42
	var pelvis := Vector3(front.x + side * 0.05, rng.randf_range(0.40, 0.46), front.z + 0.04)
	var chest := Vector3(front.x + side * 0.02, pelvis.y + 0.30, front.z - 0.055)
	var neck := Vector3(front.x, chest.y + 0.115, front.z - 0.085)
	var head: Vector3 = neck + Vector3(0.0, 0.085, 0.0) - nrm * 0.045
	var waist: Vector3 = pelvis.lerp(chest, 0.5)
	var s_a := chest + Vector3(side * 0.125, 0.035, 0.0)
	var e_a := s_a + Vector3(side * 0.045, 0.045, 0.0) - nrm * 0.145
	var w_a: Vector3 = p + nrm * 0.135 + Vector3(side * 0.020, -0.010, 0.0)
	var h_a: Vector3 = p + nrm * 0.030
	var s_b := chest - Vector3(side * 0.125, -0.020, 0.0)
	var e_b := s_b + Vector3(-side * 0.045, -0.185, 0.0) + nrm * 0.055
	var w_b := e_b + Vector3(-side * 0.020, -0.150, 0.0) + nrm * 0.075
	var h_b: Vector3 = w_b + Vector3(0.0, -0.045, 0.0) + nrm * 0.030
	# knees down, shins folded back under the hips
	var legs: Array = []
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var hip := Vector3(pelvis.x + sd * 0.095, pelvis.y - 0.015, pelvis.z)
		var knee := Vector3(pelvis.x + sd * 0.115, 0.115, pelvis.z + 0.185)
		var ankle := Vector3(pelvis.x + sd * 0.110, 0.075, pelvis.z - 0.105)
		var foot: Vector3 = ankle + Vector3(0.0, -0.030, -0.075)
		legs.append([hip, knee, ankle, foot])
	return {
		"spine": [pelvis, waist, chest, neck],
		"head": head, "head_r": rng.randf_range(0.086, 0.100),
		"arms": [[s_a, e_a, w_a, h_a], [s_b, e_b, w_b, h_b]],
		"legs": legs,
		"scale": 1.0,
	}


## Joints to flesh. `mode` is "solid" or "swarm"; `k` scales every radius, which
## is how the twin reads as a smaller person rather than a nearer one.
static func _flesh(root: Node3D, mat: StandardMaterial3D, dark: StandardMaterial3D,
		pose: Dictionary, mode: String, k: float, rng: RandomNumberGenerator) -> void:
	var spine: Array = pose["spine"]
	var arms: Array = pose["arms"]
	var legs: Array = pose["legs"]
	var sr: Array[float] = [0.104, 0.086, 0.112, 0.056]
	for i in range(3):
		_chain(root, mat, spine[i], spine[i + 1], sr[i] * k, sr[i + 1] * k, 5, mode, rng)
	var hr: float = float(pose["head_r"]) * k
	_ell(root, mat, pose["head"], Vector3(hr, hr * 1.12, hr * 0.98), Basis(), mode, rng)
	for a_v in arms:
		var a: Array = a_v
		_chain(root, mat, a[0], a[1], 0.058 * k, 0.046 * k, 5, mode, rng)
		_chain(root, mat, a[1], a[2], 0.046 * k, 0.036 * k, 5, mode, rng)
		_chain(root, mat, a[2], a[3], 0.036 * k, 0.029 * k, 3, mode, rng)
		# the hand is always solid: it is the part that is inside a hole, and a
		# swarmed hand reads as debris rather than as a reaching person
		_ell(root, mat, a[3], Vector3(0.046, 0.052, 0.032) * k, Basis(), "solid", rng)
	for l_v in legs:
		var l: Array = l_v
		_chain(root, mat, l[0], l[1], 0.088 * k, 0.062 * k, 6, mode, rng)
		_chain(root, mat, l[1], l[2], 0.062 * k, 0.040 * k, 6, mode, rng)
		_ell(root, dark, l[3], Vector3(0.052, 0.036, 0.086) * k, Basis(), "solid", rng)


## "negative" — no dancer. The lobes that were CUT OUT of the sheet are stacked
## into a figure standing beside it: the holes, made flesh. Every lobe keeps its
## own radii and angle, flattened to a slice, so the column is literally the
## sheet's missing material re-assembled and can be read against the openings it
## came from.
static func _negative(root: Node3D, mat: StandardMaterial3D, dark: StandardMaterial3D,
		sh: Dictionary, holes: Array, side: float, rng: RandomNumberGenerator) -> void:
	var lobes: Array = []
	for h_v in holes:
		lobes.append(h_v)
	# A SEALED SHEET ONLY GAVE UP TWO LOBES and two lumps is not a body. Nor would
	# the probe's mesh floor catch it: 2 lobes + 1 join + a head + the sheet's two
	# meshes + the plinth is 7 parts, which clears nothing on the parts arm and
	# rides entirely on the sheet being one big surface. Sixteen is the floor
	# because 16 lobes + 15 joins + a head + 3 is 35, clear of the 30-mesh arm on
	# its own — and it is honest either way: the same cut-outs, re-cast at other
	# sizes, which is what a plaster shop does with an offcut.
	var guard: int = 0
	while lobes.size() < 16 and guard < 60:
		var src: Dictionary = holes[guard % holes.size()]
		var cp: Dictionary = src.duplicate()
		cp["rx"] = float(src["rx"]) * rng.randf_range(0.62, 1.45)
		cp["ry"] = float(src["ry"]) * rng.randf_range(0.62, 1.45)
		cp["ang"] = rng.randf_range(0.0, PI)
		lobes.append(cp)
		guard += 1

	var total: float = 0.0
	for l_v in lobes:
		total += float((l_v as Dictionary)["ry"]) * 1.55
	var fit: float = clampf(1.18 / maxf(total, 0.001), 0.35, 1.0)
	var base_u: float = (HALF_W + 0.20) * side
	var fr: Array = _frame(sh, clampf(base_u, -HALF_W, HALF_W), 0.70)
	var base_z: float = (fr[0] as Vector3).z + rng.randf_range(-0.05, 0.10)
	var lean: float = rng.randf_range(-0.10, 0.10)
	var y: float = 0.03
	var prev := Vector3(base_u, 0.0, base_z)
	for i in range(lobes.size()):
		var l: Dictionary = lobes[i]
		var rx: float = float(l["rx"]) * fit * 1.25
		var ry: float = float(l["ry"]) * fit * 1.55
		var t: float = float(i) / float(maxi(lobes.size() - 1, 1))
		var c := Vector3(base_u + lean * t + rng.randf_range(-0.035, 0.035),
			y + ry * 0.5, base_z + rng.randf_range(-0.045, 0.045) + sin(t * 3.1) * 0.06)
		var b := Basis(Vector3.UP, rng.randf_range(-0.55, 0.55)) * Basis(Vector3.BACK, float(l["ang"]) * 0.35)
		_ell(root, mat, c, Vector3(maxf(rx, 0.030), maxf(ry * 0.5, 0.030), 0.032), b, "solid", rng)
		if i > 0:
			# the joins, so the column reads as one body and not as a shelf of parts
			_ell(root, dark, prev.lerp(c, 0.5), Vector3(0.030, 0.034, 0.028), Basis(), "solid", rng)
		prev = c
		y += ry
	# and a head, because a stack of cut-outs with a skull on it is a figure
	_ell(root, mat, Vector3(base_u + lean, y + 0.085, base_z), Vector3(0.082, 0.094, 0.078), Basis(), "solid", rng)


# ---------------------------------------------------------------------------
# geometry helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ell(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis,
		mode: String, rng: RandomNumberGenerator) -> void:
	if mode == "swarm" and rng != null:
		# the body strung through the perforation: every part becomes two smaller
		# ones pushed apart THROUGH the sheet, which is the only direction where a
		# scattered dancer still reads as one who went through the holes
		var a0: float = rng.randf_range(0.0, TAU)
		var br := Vector3(r.x * 0.56, r.y * 0.56, r.z * 0.56)
		for k in range(2):
			var a: float = a0 + PI * float(k)
			var push: float = rng.randf_range(0.85, 1.60)
			var off := Vector3(sin(a) * r.x * 0.45 * push, rng.randf_range(-0.5, 0.5) * r.y,
				cos(a) * maxf(r.z, 0.05) * 1.55 * push)
			# a swarmed part is half the size, so it can carry half the segments for
			# the same silhouette error — without this the value costs 139 meshes at
			# 288 triangles each and the statue lands at 55,000, three times the
			# heaviest primitive body in the corpus
			_sphere(root, mat, c + b * off, br, b, 12, 7)
		return
	_sphere(root, mat, c, r, b, 16, 9)


static func _sphere(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis,
		segs: int, rings: int) -> void:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	# 16x9 rather than the stock 64x32: seventy of these carry the dancer, and at
	# the default resolution she alone would cost 90,000 triangles in a hall the
	# museum builds on the main thread while somebody is walking through it
	sph.radial_segments = segs
	sph.rings = rings
	var mi: MeshInstance3D = _add(root, sph, mat)
	# Basis.scaled() is diag * B in the PARENT frame, which on a sphere cancels the
	# rotation outright — the squash has to happen in the ellipsoid's own frame.
	mi.transform = Transform3D(b * _diag(r), c)


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _chain(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3,
		r0: float, r1: float, n: int, mode: String, rng: RandomNumberGenerator) -> void:
	var steps: int = maxi(n, 2)
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var p: Vector3 = a.lerp(b, t)
		var r: float = lerpf(r0, r1, t)
		_ell(root, mat, p, Vector3(r, r, r), Basis(), mode, rng)


static func _yaw(root: Node3D, ang: float) -> void:
	var b := Basis(Vector3.UP, ang)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(b, Vector3.ZERO) * cm.transform


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


# ---------------------------------------------------------------------------
# painted skins — every pixel drawn in code, nothing from disk

## Plaster: a chalk ground, optional fine horizontal ribbing (several screens in
## the reference are corrugated), and a speckle so a matte white does not read as
## a flat fill under AgX.
static func _plaster_tex(rng: RandomNumberGenerator, ribbed: bool, base: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var period: float = rng.randf_range(4.0, 7.0)
	var depth: float = rng.randf_range(0.055, 0.105)
	var phase: float = rng.randf_range(0.0, TAU)
	for y in range(TEX):
		var rib: float = 0.0
		if ribbed:
			rib = depth * (0.5 + 0.5 * sin(float(y) / period * TAU + phase))
		for x in range(TEX):
			# a slow blotch, so the wall has weather rather than noise
			var blotch: float = 0.024 * sin(float(x) * 0.061 + float(y) * 0.037)
			var grain: float = rng.randf_range(-0.020, 0.020)
			var s: float = clampf(1.0 - rib + blotch + grain, 0.35, 1.0)
			img.set_pixel(x, y, Color(clampf(base.r * s, 0.0, 1.0), clampf(base.g * s, 0.0, 1.0),
				clampf(base.b * s, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## Fishnet: the mesh bodysuit one of the reference's dancers wears. Two diagonal
## line families, so the cells are diamonds and not squares.
static func _net_tex(rng: RandomNumberGenerator, col: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var p: float = float(rng.randi_range(11, 18))
	var thick: float = rng.randf_range(0.22, 0.34)
	var thread: Color = Color(col.r * 0.22, col.g * 0.22, col.b * 0.26)
	var skin: Color = col.lerp(Color(1.0, 0.96, 0.92), 0.30)
	for y in range(TEX):
		for x in range(TEX):
			var a: float = absf(sin(float(x + y) * PI / p))
			var b: float = absf(sin(float(x - y) * PI / p))
			img.set_pixel(x, y, thread if (a < thick or b < thick) else skin)
	return ImageTexture.create_from_image(img)
