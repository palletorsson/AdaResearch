extends RefCounted

## dream_bodies / bacon_smear — one body torn sideways out of itself.
##
## Reference: FinalMD/m1/0_0329-0000.jpg (4096x1072 panorama) — a rank of soft
## figures crowded shoulder to shoulder in a brown-black room, every one of them
## caught mid-dissolve: pink and mauve flesh dragged sideways into ribbons, a
## sulphur-yellow body blotched over dark plum, pale crazed skin going to bone,
## limbs that stop being limbs and become blur. After Francis Bacon by way of a
## diffusion model. The argument is one sentence: THE BODY CANNOT HOLD STILL.
##
## Reproduced, and how:
##   1. THE SMEAR IS GEOMETRY, NOT A BLURRED TEXTURE. The figure is dealt as 40
##      sample points on twenty-two bones (pelvis, waist, chest, shoulder bar, neck,
##      head, two arms, two legs, belly, buttocks). Each sample is then DRAGGED —
##      p0 stays where the body was, p1 is where the motion took it — and the
##      pair is a STROKE. Nothing else in this file knows about the axis: the
##      stroke list is the one source of truth, and every value of `smear` is a
##      different way of drawing or growing the same forty strokes.
##   2. THINNING AND SHEARING, both measured off the body's own height. The drag
##      is weighted by (y - foot)/(crown - foot)^1.35, so the planted foot barely
##      moves and the head is thrown up to 0.42 m; each stroke's radius runs r0 -> 0.34
##      r0 along its length, and the lozenges flatten vertically as they thin, so
##      the flesh reads as sheared rather than as a row of copies.
##   3. THE SCREAM. The head carries a dark patent cavity half-sunk into its
##      front, a chalk jaw pulled down and forward out of it, five cream teeth
##      across the top of the hole and two erased eye-sockets. It sits on the
##      CHALK head — the face belongs to the body where it was, not to the blur.
##   4. Painted flesh — a 128x128 ImageTexture drawn pixel by pixel: marbled meat,
##      pink veined with fat and going sulphur at the streaks, laid on with world
##      triplanar so one marbling runs unbroken across two hundred primitives. A
##      second, drier texture (chalk stipple with scumble streaks) carries the core.
##   5. Brown-black room — the plinth is dark umber under a film of varnish, which
##      is what Bacon's grounds do: a flat dark plane with a wet sheen on it.
##
## THE ONE MATTE PASSAGE IS THE CORE BODY. Every stroke's first step — step 0, at
## p0, at full radius — is dry chalk plaster: matte 1.0, no clearcoat, a painted
## stipple. Everything dragged off it is wet: latex, patent, candy or a poured
## film, running pink -> sulphur along the smear and ending in a neon rim. So the
## statue is a dry figure with wet meat coming off it, and the wet only reads wet
## because the chalk is standing right next to it. This is also why `still` is not
## a solid body: at `still` the smear is a 3 cm tremble and the wet skin is 0.92
## of the chalk's radius, so the dry figure shows through on one side as a rim —
## the double contour Bacon paints when a head is only vibrating. A single matte
## body with no wet passage would have been the easy reading of "still", and it
## would have thrown away the contrast the whole family is built on.
##
## AXES — two, and they argue against each other:
##   smear — what the motion has already done. "drag" is the reference and the
##           default, the whole figure sheared sideways into ribbons; "still" is
##           the body only trembling in place; "fan" swings the drag round a vertical axis through the
##           pelvis so the arms trace arcs instead of streaks; "shred" replaces
##           every lozenge with a horizontal wafer 1-2 cm thick, so the body is
##           sliced into lamellae with the dark room showing between them; "spill"
##           turns the drag downward and outward and lets the radius GROW, a
##           figure sagging off its own feet into a pool; "cast" grows the same
##           strokes as ONE marched isosurface — see below.
##   hold  — what is trying to hold it still, which is Bacon's own furniture.
##           "open" is the body alone in the dark; "pin" is a single 22 mm chrome
##           rod driven from the plinth through the crown; "rail" is a bowed tube
##           crossing the figure at hip height; "frame" is the space-frame — the
##           twelve-rod glass box he drew round almost every screaming figure;
##           "ring" is the arena, two concentric tubes lying on the floor; "strip"
##           is the vertical strip of light standing behind the shoulder. Not one
##           of them touches the body's geometry, which is the point: the smear
##           happens whatever you build around it.
##
## WHAT "cast" GROWS. Every other value stacks primitives along each stroke and
## lets the gloss hide the seams. "cast" hands the SAME forty strokes to DreamIso
## as capsules — from 30% along the drag to its end, tapering r0 -> 0.34 r0 —
## marched at 3.6 cm with a 5.5 cm smooth union. Nothing overlaps any more: the
## arm's smear swells into the torso's smear with a fillet, and the whole trail
## is one continuous poured mass. The capsules START at 30% so the chalk core is
## not swallowed: the dry figure stays primitives and stands INSIDE the poured
## trail, which is the only way the family's matte passage survives a value that
## is otherwise a single mesh. The grown body is one MeshInstance3D — far under
## the probe's 30-mesh floor — so the chalk core (40 ellipsoids) plus the head
## marks carry the mesh count, measured at 51, and the marched surface carries
## the triangles, measured at 9,430 in the one mesh against a 5,000 floor.
## If the mesher returns null the value falls back to the "drag" construction,
## because a silent empty plinth is the failure mode the corpus has paid for
## twice.
##
## Given up: the crowd (this is one figure, and the reference is a rank of eight),
## the green net behind them, the second and third head, and the reference's own
## scale pattern — a cell-by-cell reptile skin painted on flesh is a different
## family's argument.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const PLINTH_TOP: float = 0.055
const MAX_W: float = 1.20
const MAX_H: float = 1.68

const TEX: int = 128

# The march. CELL 3.6 cm against a body ~1.1 x 1.5 x 0.6 m is about 34x44x18
# cells — under DreamIso's 220k budget with room to spare, so the mesher never
# silently coarsens the cell out from under the fillet.
const CAST_CELL: float = 0.036
const CAST_BLEND: float = 0.055
## Where the poured trail STARTS along each stroke. At 0.0 the pour swallows the
## chalk core and the family loses its one dry passage without erroring.
const CAST_START: float = 0.30

## The wet finishes a smear may be dealt. oilslick, holo and chrome are excluded
## ON PURPOSE: all three set albedo_texture themselves inside Gloss.skin, so the
## painted meat below would be silently overwritten and every body would wear the
## same iridescent sweep instead of its own marbling.
const WET_FIN: Array[String] = ["latex", "patent", "wet", "candy"]

const FLESH: Array = ["#E4657F", "#D8556F", "#EC8095", "#C94C6B", "#E9927F"]
const SULPHUR: Array = ["#E8D338", "#F0E063", "#CDAE22"]
const PLUM: Array = ["#54203A", "#6A2447", "#3A1526"]
const BONE: Array = ["#E6DFCC", "#DED5BE", "#EFE9DA"]
const GROUND: Array = ["#2A1A14", "#31201A", "#221510"]


static func describe() -> String:
	return ("A screaming figure sheared sideways out of itself: a dry chalk body with wet "
		+ "pink-to-sulphur flesh dragged off it in thinning ribbons, inside whatever Bacon "
		+ "frame, rail, ring or strip of light is trying to hold it still.")


static func axes() -> Dictionary:
	return {
		# "drag" LEADS ON PURPOSE: dream_bodies_promote.py takes each generated
		# scene's default from the FIRST value, so the order here decides which
		# statue the museum and any map token actually stand. Listing "still"
		# first would have made the default body the one where nothing has
		# happened yet — the family's argument, defaulted off.
		"smear": ["drag", "still", "fan", "shred", "spill", "cast"],
		"hold": ["open", "pin", "rail", "frame", "ring", "strip"],
	}


## PREDICTED BEFORE THE CAPTURE, and a LOWER bound — a hand estimate has one flat
## light and no shadow, so the corpus's four scored predictions all came in 1.5x
## to 6.7x under the real render. If a sweep lands BELOW this number, something is
## broken; that is the only reading this function is for.
static func predicted() -> Dictionary:
	return {
		"pair": "hold: open vs pin (at any smear)",
		"predicted_pct": 0.8,
		"reasoning": ("pin is ONE rod, 22 mm across and ~1.50 m tall: 0.033 m2 of picture "
			+ "plane. It is driven through the chalk core, so roughly 55% of its run is "
			+ "behind the torso and thighs — 0.015 m2 visible. The silhouette of a smeared "
			+ "body is ~0.55 m2 and the corpus's measured subject share is ~30% of frame, "
			+ "so the frame is ~1.83 m2 of that plane: 0.015 / 1.83 = 0.8%. Every other "
			+ "hold value paints 2x to 20x more — frame is 15.2 m of rod (~0.28 m2), ring "
			+ "2.1 m of projected tube (~0.15 m2), strip a 0.09 x 1.5 m emissive plank that "
			+ "also blooms. The body is fitted into a 1.06 m box BEFORE any furniture is "
			+ "placed and every hold value is then sized inside the 14 cm left over, so the "
			+ "final settle scale is identical across all six and no pair can be inflated by "
			+ "the figure being re-photographed at a new size."),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var smear: String = String(opts.get("smear", "drag"))
	var hold: String = String(opts.get("hold", "open"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- who this one is ------------------------------------------------------
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var leg_k: float = rng.randf_range(0.94, 1.06)
	var torso_k: float = rng.randf_range(0.94, 1.08)
	var hip_w: float = rng.randf_range(0.92, 1.10)
	var arm_k: float = rng.randf_range(0.92, 1.08)
	var lean: float = rng.randf_range(-0.055, 0.055)
	var head_r: float = rng.randf_range(0.092, 0.104)
	var head_dx: float = rng.randf_range(-0.030, 0.030)
	var head_yaw: float = deg_to_rad(rng.randf_range(-26.0, 26.0))
	var span: float = rng.randf_range(0.31, 0.38)
	var fan_ang: float = deg_to_rad(rng.randf_range(48.0, 74.0))

	# --- the wardrobe ---------------------------------------------------------
	var flesh: Color = Color(str(FLESH[rng.randi_range(0, FLESH.size() - 1)]))
	var sulphur: Color = Color(str(SULPHUR[rng.randi_range(0, SULPHUR.size() - 1)]))
	var plum: Color = Color(str(PLUM[rng.randi_range(0, PLUM.size() - 1)]))
	var bone: Color = Color(str(BONE[rng.randi_range(0, BONE.size() - 1)]))
	var ground: Color = Color(str(GROUND[rng.randi_range(0, GROUND.size() - 1)]))
	# where the smear ENDS in colour: sulphur is the reference's own choice, plum
	# is the room reclaiming the flesh. Dealt, so a seed is an individual.
	var far: Color = sulphur if rng.randf() < 0.62 else plum
	var finish: String = WET_FIN[rng.randi_range(0, WET_FIN.size() - 1)]

	var tex_meat: ImageTexture = _meat_texture(rng, flesh, sulphur, bone)
	var tex_chalk: ImageTexture = _chalk_texture(rng, bone)

	# THE ONE MATTE PASSAGE — the body where it was, in dry plaster.
	var mat_chalk: StandardMaterial3D = Gloss.skin("matte", bone)
	mat_chalk.albedo_texture = tex_chalk
	mat_chalk.uv1_triplanar = true
	mat_chalk.uv1_world_triplanar = true
	mat_chalk.uv1_scale = Vector3(1.15, 1.15, 1.15)
	mat_chalk.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	mat_chalk.roughness = 1.0

	# --- how many steps a smear is drawn in, and how far it thins --------------
	var steps: int = 5
	var thin: float = 0.34
	var kmul: float = 1.0
	if smear == "still":
		# a tremble, not a drag — so the body needs its own density back or it is
		# 40 lonely spheres and reads as a bead necklace, not a figure
		steps = 2
		thin = 0.92
		kmul = 1.5
	elif smear == "spill":
		thin = 1.10          # a sag POOLS: it gets fatter as it falls, not thinner

	var mats: Array = []
	for i in range(maxi(steps - 1, 1)):
		var u: float = 1.0 if steps < 3 else float(i) / float(steps - 2)
		var col: Color = flesh.lerp(far, pow(u, 0.75))
		var f: String = finish
		# the last step is the edge the body has thinned to — a lit rim, so the
		# smear ends in light rather than in a hard stop
		if i == steps - 2 and steps > 2:
			f = "neon"
		var m: StandardMaterial3D = Gloss.skin(f, col, rng)
		if f == "neon":
			m.emission_energy_multiplier = 1.35
		m.albedo_texture = tex_meat
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 1.5
		m.uv1_scale = Vector3(0.85, 0.85, 0.85)
		m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
		m.metallic = minf(m.metallic, 0.55)
		mats.append(m)

	# --- the figure's landmarks ----------------------------------------------
	var hip_y: float = 0.80 * leg_k
	var waist_y: float = hip_y + 0.16 * torso_k
	var chest_y: float = waist_y + 0.15 * torso_k
	var sh_y: float = chest_y + 0.10 * torso_k
	var head_y: float = sh_y + 0.13 * torso_k
	var crown_y: float = head_y + head_r * 1.30

	var hip_c := Vector3(0.0, hip_y, 0.0)
	var waist := Vector3(lean * 0.30, waist_y, 0.012)
	var chest := Vector3(lean * 0.65, chest_y, -0.010)
	var sh_c := Vector3(lean, sh_y, -0.014)
	var head_c := Vector3(lean + head_dx, head_y, -0.020)
	var head_b := Basis(Vector3.UP, head_yaw)

	var cfg := {
		"side": side,
		"span": span,
		"fan_ang": fan_ang,
		"foot_y": 0.0,
		"crown_y": crown_y,
		"pivot": hip_c,
		"steps": steps,
		"thin": thin,
	}

	# --- the bones, then the samples, then the strokes -------------------------
	var bones: Array = []
	_bone(bones, hip_c, waist, 0.155 * hip_w, 0.122, 3, 1.0)
	_bone(bones, waist, chest, 0.122, 0.146, 3, 1.0)
	_bone(bones, chest, sh_c, 0.132, 0.076, 2, 1.0)
	_bone(bones, sh_c + Vector3(-0.156, -0.010, 0.0), sh_c + Vector3(0.156, -0.010, 0.0), 0.086, 0.086, 3, 1.0)
	_bone(bones, sh_c + Vector3(0.0, 0.020, 0.0), head_c - Vector3(0.0, head_r * 0.70, 0.0), 0.056, 0.062, 2, 1.15)
	# the head: two samples, so the smear can pull the skull into a wedge
	_bone(bones, head_c, head_c, head_r, head_r, 1, 1.22)
	_bone(bones, head_c + head_b * Vector3(0.0, head_r * 0.52, 0.020), head_c + head_b * Vector3(0.0, head_r * 0.52, 0.020), head_r * 0.74, head_r * 0.74, 1, 1.28)
	_bone(bones, waist + Vector3(0.0, -0.030, -0.062), waist + Vector3(0.0, -0.030, -0.062), 0.126, 0.126, 1, 1.0)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var planted: bool = sd != side
		var g_arm: float = 1.45 if sd == side else 0.85
		var g_leg: float = 0.16 if planted else 0.55
		# THE ARMS HANG CLOSE. At the wider span they were first written to
		# (shoulder 0.170, elbow 0.120, wrist 0.088) the RESTING body was already
		# 0.91 m across, the drag took it to 1.20 exactly, and the probe reported
		# the statue sitting on the settle's cap — every value of `hold` would then
		# have re-fitted the whole figure. A hanging arm is also simply what the
		# reference does: nothing in it reaches out.
		var sh: Vector3 = sh_c + Vector3(sd * 0.156, -0.010, 0.0)
		var elb: Vector3 = sh + Vector3(sd * 0.104, -0.205 * arm_k, -0.055)
		var wri: Vector3 = elb + Vector3(sd * 0.076, -0.195 * arm_k, 0.030)
		var hnd: Vector3 = wri + Vector3(sd * 0.026, -0.060, 0.008)
		_bone(bones, sh, elb, 0.062, 0.050, 2, g_arm)
		_bone(bones, elb, wri, 0.050, 0.040, 2, g_arm)
		_bone(bones, hnd, hnd, 0.046, 0.046, 1, g_arm)
		var back: float = 0.0 if planted else 0.070
		var hipj := Vector3(sd * 0.108 * hip_w, hip_y - 0.020, 0.0)
		var knee := Vector3(sd * 0.100, hip_y * 0.50, back * 0.5)
		var ank := Vector3(sd * 0.092, 0.085, back)
		var foot: Vector3 = ank + Vector3(0.0, -0.048, -0.062)
		_bone(bones, hipj, knee, 0.106 * hip_w, 0.074, 3, g_leg)
		_bone(bones, knee, ank, 0.074, 0.050, 2, g_leg)
		_bone(bones, foot, foot, 0.054, 0.054, 1, 0.05)
		_bone(bones, Vector3(sd * 0.095 * hip_w, hip_y + 0.020, 0.086), Vector3(sd * 0.095 * hip_w, hip_y + 0.020, 0.086), 0.105, 0.105, 1, 0.85)

	var strokes: Array = _strokes(bones, smear, kmul, cfg)

	# --- the body -------------------------------------------------------------
	var poured: bool = false
	if smear == "cast":
		var parts: Array = []
		for st_v in strokes:
			var st: Dictionary = st_v
			var p0: Vector3 = st["p"]
			var p1: Vector3 = st["q"]
			var r0: float = float(st["r"])
			var a: Vector3 = p0.lerp(p1, CAST_START)
			parts.append(Iso.capsule(a, p1, r0 * lerpf(1.0, thin, CAST_START) * 0.92, r0 * thin * 0.92))
		# THE MESHER CAN COME BACK EMPTY AND SAY NOTHING TO THE CALLER — tube_reef
		# lost a whole hall to exactly that, so the null is checked and the value
		# degrades to the primitive smear rather than to a bare plinth.
		var grown: ArrayMesh = Iso.mesh_of(parts, CAST_CELL, CAST_BLEND, 0.05)
		if grown != null:
			var pour_mat: StandardMaterial3D = Gloss.skin(finish, flesh.lerp(far, 0.55), rng)
			pour_mat.albedo_texture = tex_meat
			pour_mat.uv1_triplanar = true
			pour_mat.uv1_world_triplanar = true
			pour_mat.uv1_triplanar_sharpness = 1.5
			pour_mat.uv1_scale = Vector3(0.85, 0.85, 0.85)
			pour_mat.metallic = minf(pour_mat.metallic, 0.55)
			_add(root, grown, pour_mat)
			poured = true
			# the dry core, still primitives, still standing inside the pour
			for st_v2 in strokes:
				var st2: Dictionary = st_v2
				_ellipsoid(root, mat_chalk, st2["p"], Vector3(float(st2["r"]), float(st2["r"]), float(st2["r"])), Basis())

	if not poured:
		var draw: String = "drag" if smear == "cast" else smear
		for st_v3 in strokes:
			_render(root, draw, st_v3, mats, mat_chalk, cfg)

	# --- the scream, on the chalk head ----------------------------------------
	_scream(root, head_c, head_r, head_b, mat_chalk, rng)

	# --- what is trying to hold it still --------------------------------------
	#
	# THE BODY IS FITTED BEFORE THE FURNITURE, AND THAT IS THE WHOLE POINT.
	# The settle below caps the merged AABB at 1.20 m; the first build of this
	# family landed on 1.20 exactly, so a frame or a ring would have pushed the
	# box over and shrunk the entire statue — and open-vs-frame would then have
	# differed in every pixel of the body for a reason that has nothing to do
	# with `hold`. So the body alone is fitted into a box 14 cm narrower first.
	# `bk` is a function of `smear` only. Every hold value is then sized from a
	# box that is already final, and the fit below is a no-op: the axis can only
	# add furniture, never re-photograph the figure.
	var body: AABB = _union_aabb(root)
	var room: float = MAX_W - 0.14
	var bk: float = minf(1.0, minf(room / maxf(body.size.x, 0.001), room / maxf(body.size.z, 0.001)))
	bk = minf(bk, (MAX_H - PLINTH_TOP - 0.04) / maxf(body.size.y, 0.001))
	if bk < 1.0:
		_rescale(root, bk)
		body = _union_aabb(root)
	_hold(root, hold, body, hip_c * bk, side, sulphur, rng)

	# --- the measured settle: fit, centre, stand on y = 0 ----------------------
	var box: AABB = _union_aabb(root)
	var kx: float = MAX_W / maxf(box.size.x, 0.001)
	var kz: float = MAX_W / maxf(box.size.z, 0.001)
	var ky: float = (MAX_H - PLINTH_TOP) / maxf(box.size.y, 0.001)
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

	# the room's floor: dark umber under varnish, NOT matte — the chalk core is
	# this statue's one dry passage and a second one would spend the contrast
	var mat_ground: StandardMaterial3D = Gloss.skin("wet", ground, rng)
	var slab := BoxMesh.new()
	slab.size = Vector3(minf(MAX_W, box.size.x + 0.09), PLINTH_TOP, minf(MAX_W, box.size.z + 0.09))
	var pm: MeshInstance3D = _add(root, slab, mat_ground)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# the strokes — ONE source of truth, so no value of `smear` can drift from another

static func _bone(out: Array, a: Vector3, b: Vector3, r0: float, r1: float, k: int, grip: float) -> void:
	out.append({"a": a, "b": b, "r0": r0, "r1": r1, "k": k, "grip": grip})


## Every bone subdivided into samples, then every sample dragged. A zero-length
## bone is forced to ONE sample: at kmul 1.5 a hand or a foot would otherwise
## emit two or three ellipsoids at the same point, which costs draw calls, adds
## nothing to the picture, and pushes the family toward the 260-mesh budget.
static func _strokes(bones: Array, mode: String, kmul: float, cfg: Dictionary) -> Array:
	var out: Array = []
	for bn_v in bones:
		var bn: Dictionary = bn_v
		var a: Vector3 = bn["a"]
		var b: Vector3 = bn["b"]
		var grip: float = float(bn["grip"])
		var k: int = maxi(1, int(round(float(int(bn["k"])) * kmul)))
		if (b - a).length() < 0.001:
			k = 1
		for i in range(k):
			var t: float = 0.0 if k < 2 else float(i) / float(k - 1)
			var p: Vector3 = a.lerp(b, t)
			var r: float = lerpf(float(bn["r0"]), float(bn["r1"]), t)
			out.append({"p": p, "q": _drag(mode, p, grip, cfg), "r": r})
	return out


## Where the motion took this point. The weight is the body's OWN height, not a
## constant: a drag that moved the foot as far as the head would read as the
## whole statue sliding, and the shear is the entire argument.
static func _drag(mode: String, p: Vector3, grip: float, cfg: Dictionary) -> Vector3:
	var lo: float = float(cfg["foot_y"])
	var hi: float = float(cfg["crown_y"])
	var w: float = pow(clampf((p.y - lo) / maxf(hi - lo, 0.001), 0.0, 1.0), 1.35) * grip
	var side: float = float(cfg["side"])
	var span: float = float(cfg["span"])
	var pivot: Vector3 = cfg["pivot"]
	match mode:
		"still":
			return p + Vector3(side * 0.030, 0.012, -0.014) * w
		"fan":
			var ang: float = float(cfg["fan_ang"]) * w * side
			var rel: Vector3 = p - pivot
			return pivot + Basis(Vector3.UP, ang) * rel + Vector3(0.0, -0.045 * w, 0.0)
		"spill":
			var away := Vector3(p.x - pivot.x, 0.0, p.z - pivot.z)
			if away.length() < 0.02:
				away = Vector3(side, 0.0, 0.35)
			return p + away.normalized() * (span * 0.62 * w) + Vector3(0.0, -span * 1.30 * w, 0.0)
		_:
			# drag, shred, cast — one translation, sheared by height
			return p + Vector3(side * span, -span * 0.24, -span * 0.30) * w


## One stroke drawn as flesh. Step 0 is the dry chalk core at full radius; every
## later step is wet, thinner, flatter and further along the drag.
static func _render(root: Node3D, mode: String, st_v: Variant, mats: Array,
		chalk: StandardMaterial3D, cfg: Dictionary) -> void:
	var st: Dictionary = st_v
	var steps: int = int(cfg["steps"])
	var thin: float = float(cfg["thin"])
	var p0: Vector3 = st["p"]
	var p1: Vector3 = st["q"]
	var r0: float = float(st["r"])
	var d: Vector3 = p1 - p0
	var dl: float = d.length()
	# a stroke that did not move still needs an orientation, or _basis_x_to gets a
	# zero vector and hands back a basis with a NaN column
	var dir: Vector3 = Vector3(float(cfg["side"]), 0.0, 0.0) if dl < 0.0005 else d / dl
	var bx: Basis = _basis_x_to(dir)
	var seg: float = dl / float(maxi(steps - 1, 1))
	for i in range(steps):
		var u: float = 0.0 if steps < 2 else float(i) / float(steps - 1)
		var pos: Vector3 = p0 + d * u
		var rad: float = r0 * lerpf(1.0, thin, u)
		var mat: StandardMaterial3D = chalk if i == 0 else mats[mini(i - 1, mats.size() - 1)]
		if mode == "shred":
			var th: float = lerpf(0.021, 0.009, u)
			_ellipsoid(root, mat, pos, Vector3(maxf(seg * 0.70, rad * 1.10), th, rad * 1.30), bx)
		else:
			var elong: float = maxf(seg * 0.66, rad * 1.02)
			_ellipsoid(root, mat, pos, Vector3(elong, rad * lerpf(1.0, 0.70, u), rad), bx)


# ---------------------------------------------------------------------------
# the scream

static func _scream(root: Node3D, hc: Vector3, hr: float, hb: Basis,
		chalk: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var dark: StandardMaterial3D = Gloss.skin("patent", Color(0.055, 0.030, 0.045), rng)
	var teeth: StandardMaterial3D = Gloss.skin("candy", Color(0.95, 0.92, 0.84), rng)
	var open: float = rng.randf_range(0.90, 1.25)

	# the cavity, half sunk into the face so it reads as a hole and not a bead
	var mouth: Vector3 = hc + hb * Vector3(0.0, -hr * 0.26 * open, -hr * 0.80)
	_ellipsoid(root, dark, mouth, Vector3(hr * 0.34, hr * 0.44 * open, hr * 0.32), hb)
	# the jaw, dragged down and out of it — chalk, because the face belongs to the
	# body where it WAS
	_ellipsoid(root, chalk, hc + hb * Vector3(0.0, -hr * (0.66 + 0.16 * open), -hr * 0.50),
		Vector3(hr * 0.44, hr * 0.30, hr * 0.42), hb * Basis(Vector3.RIGHT, 0.30))
	for k in range(5):
		var f: float = (float(k) - 2.0) / 2.0
		var tp: Vector3 = mouth + hb * Vector3(f * hr * 0.24, hr * 0.36 * open, -hr * 0.10)
		var tb := BoxMesh.new()
		tb.size = Vector3(hr * 0.11, hr * 0.15, hr * 0.09)
		var tm: MeshInstance3D = _add(root, tb, teeth)
		tm.transform = Transform3D(hb, tp)
	# the eyes, erased: two dark smudges rather than eyeballs
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		_ellipsoid(root, dark, hc + hb * Vector3(sd * hr * 0.38, hr * 0.24, -hr * 0.86),
			Vector3(hr * 0.20, hr * 0.12, hr * 0.07), hb)


# ---------------------------------------------------------------------------
# the hold axis — Bacon's furniture, and none of it touches the body
#
# EVERY VALUE IS SIZED FROM THE BODY'S MEASURED AABB AND KEPT INSIDE IT IN Y, so
# the settle's fit scale is the same at all six values. If the frame or the ring
# pushed the merged box past 1.20 m the whole statue would be re-fitted and the
# axis would "bite" for the boring reason that every pixel moved.

static func _hold(root: Node3D, mode: String, bb: AABB, pivot: Vector3, side: float,
		glow_col: Color, rng: RandomNumberGenerator) -> void:
	if mode == "open":
		return
	var chrome: StandardMaterial3D = Gloss.skin("chrome", Color(0.86, 0.84, 0.90), rng)
	var cx: float = bb.position.x + bb.size.x * 0.5
	var cz: float = bb.position.z + bb.size.z * 0.5
	var top: float = bb.end.y
	match mode:
		"pin":
			var px: float = pivot.x + rng.randf_range(-0.02, 0.02)
			var pz: float = pivot.z + rng.randf_range(-0.02, 0.02)
			_rod(root, chrome, Vector3(px, -0.004, pz), Vector3(px, top + 0.014, pz), 0.011)
		"rail":
			var hy: float = lerpf(bb.position.y, top, 0.56)
			var a := Vector3(cx - 0.50, hy - 0.03, cz + 0.24)
			var b := Vector3(cx + 0.54, hy + 0.02, cz - 0.10)
			var c := Vector3(cx + 0.02, hy + 0.11, cz - 0.32)
			var prev: Vector3 = a
			for i in range(1, 13):
				var t: float = float(i) / 12.0
				var q: Vector3 = a.lerp(c, t).lerp(c.lerp(b, t), t)
				_rod(root, chrome, prev, q, 0.023)
				prev = q
		"frame":
			var hw: float = minf(bb.size.x * 0.5 + 0.045, 0.575)
			var hd: float = minf(bb.size.z * 0.5 + 0.045, 0.575)
			var y0: float = -0.004
			var y1: float = top + 0.030
			for s_i in range(4):
				var sx: float = -1.0 if s_i < 2 else 1.0
				var sz: float = -1.0 if (s_i % 2) == 0 else 1.0
				var fx: float = cx + sx * hw
				var fz: float = cz + sz * hd
				_rod(root, chrome, Vector3(fx, y0, fz), Vector3(fx, y1, fz), 0.012)
			for s_j in range(2):
				var yy: float = y0 if s_j == 0 else y1
				_rod(root, chrome, Vector3(cx - hw, yy, cz - hd), Vector3(cx + hw, yy, cz - hd), 0.012)
				_rod(root, chrome, Vector3(cx - hw, yy, cz + hd), Vector3(cx + hw, yy, cz + hd), 0.012)
				_rod(root, chrome, Vector3(cx - hw, yy, cz - hd), Vector3(cx - hw, yy, cz + hd), 0.012)
				_rod(root, chrome, Vector3(cx + hw, yy, cz - hd), Vector3(cx + hw, yy, cz + hd), 0.012)
		"ring":
			var rr: float = minf(maxf(bb.size.x, bb.size.z) * 0.5 + 0.035, 0.545)
			for k in range(2):
				var maj: float = rr * (1.0 - 0.26 * float(k))
				var tor := TorusMesh.new()
				tor.outer_radius = maj + 0.021
				tor.inner_radius = maxf(maj - 0.021, 0.01)
				tor.rings = 40
				tor.ring_segments = 8
				var tm: MeshInstance3D = _add(root, tor, chrome)
				tm.transform = Transform3D(Basis(), Vector3(cx, 0.016, cz))
		"strip":
			# THE VERTICAL STRIP OF LIGHT, kept narrow and pulled down to neon 1.6:
			# at Gloss's stock 3.2 with the museum's glow on, a plank this size
			# blooms over the figure it is meant to stand behind.
			var lit: StandardMaterial3D = Gloss.skin("neon", Color(0.99, 0.95, 0.78).lerp(glow_col, 0.45), rng)
			lit.emission_energy_multiplier = 1.6
			var pl := BoxMesh.new()
			pl.size = Vector3(0.090, maxf(top * 0.96, 0.4), 0.042)
			var sm: MeshInstance3D = _add(root, pl, lit)
			sm.transform = Transform3D(Basis(), Vector3(cx + side * 0.26, top * 0.48, bb.end.z + 0.082))
			var pl2 := BoxMesh.new()
			pl2.size = Vector3(0.034, maxf(top * 0.70, 0.3), 0.038)
			var sm2: MeshInstance3D = _add(root, pl2, lit)
			sm2.transform = Transform3D(Basis(), Vector3(cx + side * 0.40, top * 0.36, bb.end.z + 0.070))


# ---------------------------------------------------------------------------
# painted textures — code only, no image ever loaded from disk

## Marbled meat: pink flesh veined with fat, running sulphur where the muscle
## opens. Frequencies in u are INTEGER so the tile wraps: triplanar carries this
## round a limb, and a visible seam reads as a crack in the body.
static func _meat_texture(rng: RandomNumberGenerator, flesh: Color, sulphur: Color,
		bone: Color) -> ImageTexture:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph: float = rng.randf() * TAU
	var tilt: float = rng.randf_range(0.7, 1.9)
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var grain: float = 0.5 + 0.5 * sin(u * TAU * 3.0 + sin(v * TAU * 2.0 + ph) * 2.1)
			var c: Color = flesh.lerp(sulphur, smoothstep(0.52, 0.96, grain) * 0.78)
			# the fat: thin bright veins where a second, faster band crosses zero
			var vein: float = absf(sin(u * TAU * 7.0 + v * TAU * tilt * 4.0 + ph * 1.7))
			if vein < 0.10:
				c = c.lerp(bone, (1.0 - vein / 0.10) * 0.72)
			# a dark bruise under the marbling, so the flesh has depth in a still
			var bruise: float = 0.5 + 0.5 * sin(u * TAU * 2.0 - v * TAU * 3.0 + ph * 0.6)
			c = c.lerp(Color(0.24, 0.07, 0.14), smoothstep(0.80, 1.0, bruise) * 0.34)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Dry plaster: near-white with a stipple and a few scumble streaks. Without a
## texture the matte core photographs as a flat grey silhouette and stops reading
## as chalk at all — which is the passage the whole family's wetness leans on.
static func _chalk_texture(rng: RandomNumberGenerator, bone: Color) -> ImageTexture:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph: float = rng.randf() * TAU
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var scum: float = 0.5 + 0.5 * sin(u * TAU * 5.0 + v * TAU * 2.0 + ph)
			var k: float = 0.86 + 0.14 * scum
			k *= 0.96 + 0.04 * rng.randf()
			var c: Color = bone * k
			img.set_pixel(x, y, Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# geometry helpers

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
	sph.radial_segments = 18
	sph.rings = 10
	var mi: MeshInstance3D = _add(root, sph, mat)
	# NOTE Basis.scaled() is diag * B in the PARENT frame, which on a sphere
	# cancels the rotation outright — the lozenge would come out round and the
	# smear would read as a row of beads. The squash happens in the stroke's own
	# frame, so b comes first.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _rod(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r: float) -> void:
	var v: Vector3 = b - a
	var l: float = v.length()
	if l < 0.0005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = l
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(v), (a + b) * 0.5)


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	return Basis(ax, acos(clampf(dot_up, -1.0, 1.0)))


static func _basis_x_to(dir: Vector3) -> Basis:
	var xb: Vector3 = dir.normalized()
	var up: Vector3 = Vector3.UP
	if absf(xb.dot(up)) > 0.995:
		up = Vector3.FORWARD
	var zb: Vector3 = xb.cross(up).normalized()
	var yb: Vector3 = zb.cross(xb).normalized()
	return Basis(xb, yb, zb)


static func _rescale(root: Node3D, k: float) -> void:
	if absf(k - 1.0) < 0.0001:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis.scaled(Vector3(k, k, k)), cm.transform.origin * k)


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
