extends RefCounted

## dream_bodies / dotted_colossus — a heroic classical body whose SKIN IS A COSTUME.
##
## Reference: C:/Users/palle/Documents/FinalMD/m1/0_1723-0000.jpg (4096x1072) — a
## garden crowd of colossal marble nudes seen mostly FROM BEHIND: lat spread, deep
## spinal furrow, glutes, curl-heavy heads turned into profile. One of them is
## head-to-foot in a navy zentai carrying enormous lemon polka dots. One wears a
## cape of pale brickwork laid in courses across its back. One is bundled in shaggy
## grey fur. One carries a hard yellow drapery over the shoulder. The BODY is the
## constant and the SURFACE is the variable, and that is the entire joke — so the
## muscle has to be built well enough that swapping its skin is funny rather than
## merely odd.
##
## Reproduced, and how:
##   1. The colossus — a 15-link chain of ellipsoids from pelvis to shoulder keyed
##      hips -> narrow waist -> broad chest, with separate glutes, lats, pecs, abs
##      and traps hung off it, so the silhouette is the V-back of the reference and
##      not a taper. Limbs are chains of overlapping spheres; the joins vanish
##      under whatever the body is wearing.
##   2. Contrapposto built into the chain, not applied to it: the pelvis rides high
##      on the weight side, the shoulder line counter-tilts, the mass shifts over
##      the standing leg and the free leg falls out and forward.
##   3. Painted skins — marble veining, polka dots, running-bond brickwork, pelt
##      streaks and cloth weave, each an ImageTexture drawn pixel by pixel in code
##      from one seeded value-noise table, applied with WORLD triplanar so a single
##      pattern runs unbroken across a hundred separate primitives. Local triplanar
##      cannot do this: every ellipsoid here is a unit sphere under a scale, so its
##      model space is [-1,1] whatever its size and each one would wear a whole tile.
##   4. The costume is also GEOMETRY, because a photograph of a texture is not a
##      photograph of a costume: the dots stand proud as lenses, the brick is real
##      stepped boxes in a running bond, the fur is tufts on the surface normal, and
##      the drapery is a SurfaceTool ribbon with a fold ripple across its width.
##   5. A seed is an individual — stature, shoulder and hip width, muscle bulge,
##      which leg takes the weight, head size and turn, curl count, and the whole
##      colourway of the costume.
##
## THE ONE MATTE PASSAGE is the DRY CHALK FOOTING: the plinth slab, the feet and
## ankles, and (in `fragment`) the sawn faces where the limbs stop. Everything else
## on this body is wet — latex, patent, pearl, glazed brick — and a wet body only
## reads wet next to a dry one. It is also an argument rather than a concession: the
## costume stops at the ankle in every value of `cladding`, so the raw stone the
## figure was cut from is always showing somewhere, and the fragment's cut faces are
## the same chalk as the plinth it stands on.
##
## Given up: the garden and the hedge, the crowd's MIXED wardrobe (see the note on
## `stance` below), the faces — these heads are forms, a skull and a mass of curls,
## the way a Nana or a Giacometti is a form — and the reference's hard directional
## sun, which belongs to the museum's lighting and not to a builder.
##
## AXES — two, and both change the object rather than a setting:
##   cladding — what the body is WEARING, head to ankle. "dots" is the reference's
##              zentai: a navy latex suit, a smooth hood in place of the curls, and
##              lens-shaped dots standing 4 mm proud. "marble" strips it back to the
##              veined stone the joke needs as its baseline. "brick" lays a masonry
##              cape in a running bond over the back and shoulders, glazed, with the
##              curls left showing above it. "fur" swaps the whole body for a pelt
##              and hoods the head in tufts, which is the one value that changes the
##              SILHOUETTE rather than the surface. "drape" hangs a patent cloth
##              ribbon from one shoulder across the back to the opposite hip, with a
##              rolled hem and a knot.
##   stance   — what the statue IS. "contrapposto" is one figure at rest, weight on
##              one leg. "torsion" is the figura serpentinata: hips 16 degrees one
##              way, shoulders 30 the other, one arm crossing up to the far shoulder
##              and one behind the back, the free leg stepped back and across.
##              "fragment" is the museum torso — no head, no arms, legs sawn at
##              mid-thigh — raised on a tall chalk column. "pair" stands two of them
##              back to back on one slab; "frieze" lines up three, which is what the
##              panorama actually is.
##
## WHY EVERY FIGURE IN A GROUP WEARS THE SAME COSTUME. The reference's crowd is
## MIXED — that is where its comedy comes from — and this family does not reproduce
## that, on purpose. `cladding` has to be readable as an axis, and a frieze in which
## only the centre figure is dressed would dilute every cladding pair by two thirds
## in two of the five stance columns. So the group values dress all three and deal
## each one its own colourway instead: three colossi in the same costume is a
## different joke (an army, a chorus line) and it keeps the measurement honest.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const TEX: int = 192
const PLINTH_TOP: float = 0.055
## The fragment's column. Torso canonical span is 0.60..1.40, so a 0.72 top puts the
## sawn thigh at 0.72 and the sawn neck at 1.52 — under the 1.68 m ceiling with the
## base slab on, which is why this number is not simply "as tall as looks right".
const PED_TOP: float = 0.72
## The value-noise table is NG x NG and fbm samples it at 1, 2, 4, 8 grid units, so
## every octave wraps on the same lattice. A non-power-of-two here puts a visible
## seam down the triplanar's X face.
const NG: int = 16

# Deep grounds a zentai may be cut from. Deliberately NOT off the QUEER palette:
# the dots have to shout off something dark, and every QUEER colour is a shout.
const SUIT_GROUND: Array = ["#141B44", "#0C0C16", "#2B0A30", "#08282A", "#3A0A18"]
const STONE_TONES: Array = ["#EDE4D8", "#E9E1D5", "#F2E7DB", "#E4DED4"]
const VEIN_TONES: Array = ["#8E8798", "#7C7A86", "#9A8878", "#6E7C88"]
const BRICK_TONES: Array = ["#CBA189", "#D8B7A1", "#B98C74", "#E1CDB8"]
const PELT_TONES: Array = ["#918F94", "#A8A5A8", "#6F6D76", "#B9B4AE"]

# Chalk: the one dry thing on the statue. Named as a constant because three
# separate passages share it and they must not drift into three near-whites.
const CHALK: Color = Color(0.855, 0.845, 0.815)


static func describe() -> String:
	return ("A heroic classical colossus seen from behind, wearing its skin as a costume: "
		+ "veined marble, a polka-dot zentai, a cape of glazed brickwork, shaggy pelt or "
		+ "patent drapery — alone, twisted, sawn to a torso, doubled or lined up three abreast.")


static func axes() -> Dictionary:
	return {
		"cladding": ["dots", "marble", "brick", "fur", "drape"],
		"stance": ["contrapposto", "torsion", "fragment", "pair", "frieze"],
	}


## The prediction, as data, so tools/dream_bodies_promote.py carries it into the
## registry instead of anyone retyping it. Named pair, number, arithmetic — and it
## is a LOWER bound, so a sweep that lands UNDER it is the one result that means
## stop and look at the render rather than at the design.
static func predicted() -> Dictionary:
	return {
		"pair": "stance: contrapposto vs torsion (any cladding)",
		"predicted_pct": 6.4,
		"reasoning": ("silhouette budget for one figure, in square metres of projected area: "
			+ "torso 0.24, legs 0.24, arms 0.12, head 0.05 = 0.65 total. Torsion moves the "
			+ "crossing arm to the far shoulder — 0.06 vacated plus 0.06 arrived, but half "
			+ "the arrival lands ON the chest and is not new pixels, so ~0.09; the other arm "
			+ "goes behind the back, ~0.04 net; the head turns 45 deg and repaints ~40% of "
			+ "0.05 = 0.02; the counter-rotated shoulder and hip move the torso edge ~20 mm "
			+ "over 0.6 m = 0.012. Sum 0.162 of 0.65 = 25% of the SILHOUETTE. At framing "
			+ "0.62 a 1.6 m body is about 26% of the frame, so 0.25 x 0.26 = 6.4% of picture. "
			+ "Every other stance pair adds or removes a whole body, a head and two arms, or "
			+ "a 0.72 m column, and every cladding pair repaints the entire surface."),
		"measured_pct": 6.07,
		"outcome": ("RIGHT PAIR, WRONG AXIS, AND THE ARITHMETIC WAS RIGHT TWICE BY ACCIDENT. "
			+ "contrapposto-vs-torsion is the smallest stance pair in all five claddings "
			+ "(6.07 dots, 7.59 fur, 8.49 drape, 9.71 brick, 9.90 marble, mean 8.35), so the "
			+ "pair was named correctly and 6.4 predicted against 6.07 measured is 0.95x — "
			+ "under the prediction, which by the corpus's rule means stop and look. Looking "
			+ "says the two errors cancelled: the subject is 15.1% of frame, not the 26% "
			+ "assumed, and the silhouette share is nearer 40% than the 25% computed. "
			+ "WHAT THE PREDICTION MISSED is that the gallery's minimum is on the OTHER axis "
			+ "— marble-vs-brick at 2.275%, stance=fragment, smallest of all 300 pairs and "
			+ "one of three under the 3% decoration line. The clause 'every cladding pair "
			+ "repaints the entire surface' was the false step. Two causes, and only the "
			+ "second one is real: the cape was built on the +Z hemisphere (the reference is "
			+ "shot from behind) while the sweep camera stands at yaw 0.62 in front, so it "
			+ "now wraps 2.2 rad and over both deltoids — worth 0.1 points, i.e. NOTHING, "
			+ "which is how the standpoint theory was disproved. The real cause is the "
			+ "DENOMINATOR: a cape over the back of a body that is itself 15% of frame is "
			+ "~2% of picture whatever it is made of, and pale brick on pale marble spends "
			+ "little value on top of that. It is faithful to the reference and small in the "
			+ "frame at once, and the frame is not the argument. Kept, and recorded, rather "
			+ "than tuned until the number flattered it."),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var clad: String = String(opts.get("cladding", "dots"))
	var stance: String = String(opts.get("stance", "contrapposto"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- who this colossus is -------------------------------------------------
	var stat: float = rng.randf_range(0.95, 1.04)
	var shw: float = rng.randf_range(0.94, 1.10)
	var hipw: float = rng.randf_range(0.92, 1.06)
	var musc: float = rng.randf_range(0.90, 1.14)
	var head_r: float = rng.randf_range(0.100, 0.114)
	var head_yaw: float = deg_to_rad(rng.randf_range(-34.0, 34.0))
	var wsd: float = 1.0 if rng.randf() < 0.5 else -1.0
	var curl_n: int = rng.randi_range(11, 16)

	# MATTE, on purpose, and the only matte in the file: plinth, feet, sawn faces.
	var mat_chalk: StandardMaterial3D = Gloss.skin("matte", CHALK)

	# --- how the group is arranged -------------------------------------------
	# Each slot is [transform, detail, mirror]. `detail` is the mesh budget this
	# figure may spend; `mirror` flips the weight side so a pair does not read as
	# one statue photographed twice.
	var slots: Array = []
	if stance == "pair":
		var sp: float = rng.randf_range(0.79, 0.85)
		var ya: float = deg_to_rad(rng.randf_range(-22.0, 10.0))
		var yb: float = deg_to_rad(rng.randf_range(154.0, 202.0))
		slots.append([Transform3D(Basis(Vector3.UP, ya) * _diag(Vector3(sp, sp, sp)), Vector3(-0.230, 0.0, -0.060)), 0.55, 1.0])
		slots.append([Transform3D(Basis(Vector3.UP, yb) * _diag(Vector3(sp, sp, sp)), Vector3(0.230, 0.0, 0.060)), 0.55, -1.0])
	elif stance == "frieze":
		# THE SPACING IS SET BY THE WIDEST CLADDING, NOT BY THE NARROWEST. The settle
		# below scales the whole group down to 1.20 m across, so three furred figures
		# at the spacing that suited three dotted ones come out 0.88 m tall — under
		# the 0.9 m floor the probe holds every family to, and squat enough to read as
		# a mistake in a hall. 0.68-0.74 at 0.315 leaves room for the tufts.
		var sf: float = rng.randf_range(0.68, 0.74)
		for k in range(3):
			var off: float = (float(k) - 1.0) * 0.315
			var yk: float = deg_to_rad(rng.randf_range(-30.0, 30.0) + 170.0 * float(k % 2))
			var zk: float = rng.randf_range(-0.075, 0.075)
			slots.append([Transform3D(Basis(Vector3.UP, yk) * _diag(Vector3(sf, sf, sf)), Vector3(off, 0.0, zk)), 0.34, 1.0 if k != 1 else -1.0])
	else:
		slots.append([Transform3D(), 1.0, 1.0])

	# --- build each figure, then move it into its slot -------------------------
	for s_v in slots:
		var slot: Array = s_v
		var i0: int = root.get_child_count()
		var cfg := {
			"stance": stance,
			"clad": clad,
			"d": float(slot[1]),
			"mirror": float(slot[2]),
			"wsd": wsd,
			"stat": stat,
			"shw": shw,
			"hipw": hipw,
			"musc": musc,
			"head_r": head_r,
			"head_yaw": head_yaw,
			"curl_n": curl_n,
			"chalk": mat_chalk,
			# each figure in a group is dealt its OWN colourway, so a chorus line is
			# three people in the same costume rather than one statue three times
			"ward": _wardrobe(clad, rng),
		}
		_figure(root, rng, cfg)
		var tf: Transform3D = slot[0]
		if not tf.is_equal_approx(Transform3D()):
			_xform_range(root, i0, tf)

	# --- stature, then the measured settle ------------------------------------
	_rescale(root, stat, Vector3.ZERO)

	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = (1.68 - PLINTH_TOP) / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_rescale(root, kfit, Vector3.ZERO)
		box = _union_aabb(root)

	var centre: Vector3 = box.position + box.size * 0.5
	_shift(root, Vector3(-centre.x, PLINTH_TOP - box.position.y, -centre.z))
	box = _union_aabb(root)
	if box.position.y < 0.0:
		_shift(root, Vector3(0.0, -box.position.y, 0.0))
		box = _union_aabb(root)

	var slab := BoxMesh.new()
	slab.size = Vector3(minf(1.20, box.size.x + 0.12), PLINTH_TOP, minf(1.20, box.size.z + 0.12))
	var pm: MeshInstance3D = _add(root, slab, mat_chalk)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# one colossus, built into root in canonical space (feet at y = 0)

static func _figure(root: Node3D, rng: RandomNumberGenerator, cfg: Dictionary) -> void:
	var stance: String = String(cfg["stance"])
	var clad: String = String(cfg["clad"])
	var d: float = float(cfg["d"])
	var wsd: float = float(cfg["wsd"]) * float(cfg["mirror"])
	var shw: float = float(cfg["shw"])
	var hipw: float = float(cfg["hipw"])
	var musc: float = float(cfg["musc"])
	var head_r: float = float(cfg["head_r"])
	var head_yaw: float = float(cfg["head_yaw"])
	var curl_n: int = int(cfg["curl_n"])
	var chalk: StandardMaterial3D = cfg["chalk"]
	var ward: Dictionary = cfg["ward"]
	var m_body: StandardMaterial3D = ward["body"]
	var m_hair: StandardMaterial3D = ward["hair"]

	var twist: bool = stance == "torsion"
	var frag: bool = stance == "fragment"
	var lift: float = (PED_TOP - 0.60) if frag else 0.0

	# --- the spine: joints first, meshes later ---------------------------------
	# The spine's stations are the family's spatial contract: the trunk is SWEPT
	# through them, and the brick courses, the dot scatter and every muscle mass are
	# placed against the same rx/rz, so the costume cannot drift off the body.
	var n_seg: int = maxi(int(round(15.0 * d)), 9)
	var y_lo: float = 0.845
	var y_hi: float = 1.318
	# the V-back: wide pelvis, cut waist, broad chest, shoulder shelf
	var rx_keys: Array = [0.150 * hipw, 0.136 * hipw, 0.128, 0.152 * musc, 0.188 * shw, 0.206 * shw]
	var rz_keys: Array = [0.120, 0.110, 0.100, 0.118 * musc, 0.132, 0.113]
	var zo_keys: Array = [0.022, 0.008, -0.006, 0.004, 0.016, 0.024]

	var hip_yaw: float = deg_to_rad(16.0 if twist else 3.0) * wsd
	var sh_yaw: float = deg_to_rad(-30.0 if twist else -5.0) * wsd
	var hip_roll: float = deg_to_rad(-5.0) * wsd
	var sh_roll: float = deg_to_rad(4.0) * wsd

	var t_c: Array[Vector3] = []
	var t_b: Array[Basis] = []
	var t_rx: Array[float] = []
	var t_rz: Array[float] = []
	for i in range(n_seg):
		var t: float = float(i) / float(n_seg - 1)
		var rx: float = _key(rx_keys, t)
		var rz: float = _key(rz_keys, t)
		# the weight shift: pelvis rides over the standing foot, shoulders lag back
		var xo: float = wsd * (0.034 * pow(1.0 - t, 1.5) - 0.020 * pow(t, 1.7))
		var yq: float = lerpf(y_lo, y_hi, t) + lift
		var yaw: float = lerpf(hip_yaw, sh_yaw, smoothstep(0.0, 1.0, t))
		var roll: float = lerpf(hip_roll, sh_roll, t)
		t_c.append(Vector3(xo, yq, _key(zo_keys, t)))
		t_b.append(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, roll))
		t_rx.append(rx)
		t_rz.append(rz)

	var i_hip: int = 0
	var i_waist: int = int(floor(float(n_seg - 1) * 0.34))
	var i_chest: int = int(floor(float(n_seg - 1) * 0.76))
	var i_sh: int = n_seg - 1
	var c_hip: Vector3 = t_c[i_hip]
	var c_waist: Vector3 = t_c[i_waist]
	var c_chest: Vector3 = t_c[i_chest]
	var c_sh: Vector3 = t_c[i_sh]
	var b_sh: Basis = t_b[i_sh]

	# --- the trunk -------------------------------------------------------------
	var segs: int = maxi(int(round(22.0 * clampf(d, 0.34, 1.0))), 10)
	_torso_tube(root, m_body, t_c, t_b, t_rx, t_rz, segs)

	# the reference is a crowd seen from BEHIND, so the glutes and lats are the
	# subject and they are built as their own masses rather than left to the chain
	var limbs: Array = []
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var glute: Vector3 = c_hip + t_b[i_hip] * Vector3(sd * 0.084 * hipw, -0.018, 0.086)
		_ellipsoid(root, m_body, glute, Vector3(0.114 * hipw, 0.104, 0.110) * musc, t_b[i_hip])
		# the lat is a WING, not a blade: at rx 0.072 it stood off the ribs as a
		# separate teardrop instead of spreading into the back it belongs to
		var lat: Vector3 = t_c[i_chest] + t_b[i_chest] * Vector3(sd * 0.124 * shw, -0.034, 0.030)
		_ellipsoid(root, m_body, lat, Vector3(0.094, 0.132 * musc, 0.106), t_b[i_chest] * Basis(Vector3.BACK, -sd * 0.28))
		var pec: Vector3 = t_c[i_chest] + t_b[i_chest] * Vector3(sd * 0.086, 0.008, -0.096)
		_ellipsoid(root, m_body, pec, Vector3(0.098 * musc, 0.066, 0.054), t_b[i_chest])
		# the trapezius sits OUT on the shoulder, not in on the neck: at x 0.078 the
		# two of them met over the spine and swallowed the head into the ribcage
		var trap: Vector3 = c_sh + b_sh * Vector3(sd * 0.104, -0.010, 0.022)
		_ellipsoid(root, m_body, trap, Vector3(0.092, 0.058, 0.088), b_sh)

	# the abdominal ladder — three rows, because two reads as a belly and four as a print
	var ab_rows: int = maxi(int(round(3.0 * d)), 2)
	for r in range(ab_rows):
		var ta: float = lerpf(0.16, 0.60, float(r) / maxf(float(ab_rows - 1), 1.0))
		var ia: int = clampi(int(round(ta * float(n_seg - 1))), 0, n_seg - 1)
		for s_i in range(2):
			var sd2: float = -1.0 if s_i == 0 else 1.0
			var ap: Vector3 = t_c[ia] + t_b[ia] * Vector3(sd2 * 0.042, 0.0, -t_rz[ia] * 0.86)
			_ellipsoid(root, m_body, ap, Vector3(0.048, 0.042, 0.036) * musc, t_b[ia])

	# --- arms ------------------------------------------------------------------
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var sh_p: Vector3 = c_sh + b_sh * Vector3(sd * 0.192 * shw, -0.016, 0.0)
		_ellipsoid(root, m_body, sh_p, Vector3(0.090, 0.086, 0.090) * musc, b_sh)
		if frag:
			# the sawn arm: a deltoid, one segment, and a flat chalk face
			var cut_p: Vector3 = sh_p + Vector3(sd * 0.030, -0.115, -0.010)
			_ellipsoid(root, m_body, cut_p.lerp(sh_p, 0.45), Vector3(0.078, 0.076, 0.078) * musc, Basis())
			_ellipsoid(root, chalk, cut_p, Vector3(0.076, 0.011, 0.076), Basis(Vector3.RIGHT, 0.16))
			continue
		var aj: Array = _arm_joints(sh_p, sd, wsd, twist, c_chest, c_hip)
		var el: Vector3 = aj[0]
		var wr: Vector3 = aj[1]
		var hd: Vector3 = aj[2]
		_limb_tube(root, m_body, [sh_p, el, wr, hd], [0.086 * musc, 0.064, 0.050, 0.042], d, segs)
		_ellipsoid(root, m_body, hd, Vector3(0.048, 0.066, 0.036), _basis_y_to(hd - wr))
		limbs.append([sh_p, el, 0.082 * musc, 0.062])
		limbs.append([el, wr, 0.062, 0.048])

	# --- legs ------------------------------------------------------------------
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var weight: bool = sd == wsd
		var hip_p := Vector3(sd * 0.112 * hipw, (0.850 if weight else 0.840) + lift, 0.006)
		if frag:
			# the sawn thigh: the leg stops mid-femur on a flat chalk face
			var kn_c := Vector3(sd * 0.106 * hipw, PED_TOP + 0.010, -0.006)
			_limb_tube(root, m_body, [hip_p, kn_c], [0.142 * musc * hipw, 0.128 * musc], d, segs)
			_ellipsoid(root, chalk, kn_c + Vector3(0.0, -0.012, 0.0), Vector3(0.124, 0.012, 0.118), Basis())
			continue
		var lj: Array = _leg_joints(sd, weight, wsd, hipw, twist)
		var knee: Vector3 = lj[0]
		var ankle: Vector3 = lj[1]
		var toe: Vector3 = lj[2]
		_limb_tube(root, m_body, [hip_p, knee, ankle], [0.146 * musc * hipw, 0.090, 0.056], d, segs)
		# the calf head, sitting behind the shin — the reference's legs are all calf
		_ellipsoid(root, m_body, knee.lerp(ankle, 0.26) + Vector3(0.0, 0.0, 0.036), Vector3(0.066, 0.104, 0.056) * musc, Basis())
		limbs.append([hip_p, knee, 0.142 * musc * hipw, 0.090])
		limbs.append([knee, ankle, 0.090, 0.056])
		# MATTE, on purpose: the costume stops at the ankle and the raw stone shows.
		# A foot is a HEEL, an instep and a toe — the first gallery had a sphere and a
		# blob, and the pair read as two beads dropped under the shins.
		_ellipsoid(root, chalk, ankle, Vector3(0.054, 0.054, 0.054), Basis())
		var fb: Basis = Basis(Vector3.UP, sd * 0.14)
		_ellipsoid(root, chalk, ankle + fb * Vector3(0.0, -0.030, 0.046), Vector3(0.048, 0.036, 0.052), fb)
		_ellipsoid(root, chalk, toe, Vector3(0.060, 0.036, 0.112), fb)

	# --- head, neck, hair ------------------------------------------------------
	var head_c := Vector3(0.0, 0.0, 0.0)
	var head_b := Basis()
	if frag:
		var neck_c: Vector3 = c_sh + b_sh * Vector3(0.0, 0.062, 0.004)
		_ellipsoid(root, m_body, neck_c, Vector3(0.062, 0.052, 0.060), b_sh)
		_ellipsoid(root, chalk, neck_c + Vector3(0.0, 0.048, 0.0), Vector3(0.062, 0.012, 0.060), Basis(Vector3.RIGHT, -0.10))
	else:
		head_b = Basis(Vector3.UP, head_yaw + (sh_yaw * 1.5 if twist else 0.0)) * Basis(Vector3.BACK, -sh_roll * 1.4)
		# A NECK, not a socket. At 0.070 above the shoulder line the head sat inside
		# the traps and the colossus read as hunched; the reference's heads stand
		# clear on a visible column of neck, which is half of what makes them read
		# as classical rather than as a snowman.
		var neck_c2: Vector3 = c_sh + b_sh * Vector3(0.0, 0.088, 0.004)
		_ellipsoid(root, m_body, neck_c2, Vector3(0.062, 0.072, 0.060), b_sh)
		head_c = neck_c2 + head_b * Vector3(0.0, 0.122, -0.012)
		var hood: bool = clad == "dots" or clad == "fur"
		_ellipsoid(root, m_body, head_c, Vector3(head_r, head_r * 1.20, head_r * 1.14), head_b)
		# a brow shelf, so the head has a front even without a face
		_ellipsoid(root, m_body, head_c + head_b * Vector3(0.0, 0.018, -head_r * 0.94), Vector3(head_r * 0.72, head_r * 0.26, head_r * 0.30), head_b)
		if hood:
			# the zentai and the pelt swallow the head: a smooth crown instead of curls
			_ellipsoid(root, m_body, head_c + head_b * Vector3(0.0, head_r * 0.42, head_r * 0.30),
				Vector3(head_r * 1.02, head_r * 0.86, head_r * 0.90), head_b)
		else:
			# the classical curl mass — the reference's heads are 40% hair
			var n_curl: int = maxi(int(round(float(curl_n) * d)), 4)
			for k in range(n_curl):
				var ca: float = rng.randf_range(0.0, TAU)
				var cb: float = rng.randf_range(0.10, 1.42)
				var cr: float = rng.randf_range(0.034, 0.052)
				var loc := Vector3(sin(ca) * sin(cb), cos(cb) * 0.92 + 0.10, cos(ca) * sin(cb))
				var cp: Vector3 = head_c + head_b * (loc * head_r * 1.04)
				if loc.z < -0.42 and loc.y < 0.42:
					continue    # no curls across the face
				_ellipsoid(root, m_hair, cp, Vector3(cr, cr * 0.86, cr), head_b)

	# --- the costume -----------------------------------------------------------
	_clad(root, rng, clad, d, ward, chalk, t_c, t_b, t_rx, t_rz, limbs, head_c, head_b, head_r,
		c_sh, c_chest, c_hip, b_sh, wsd, frag)

	# --- the fragment's column -------------------------------------------------
	if frag:
		var col := BoxMesh.new()
		col.size = Vector3(0.300, PED_TOP - 0.030, 0.268)
		var cm: MeshInstance3D = _add(root, col, chalk)
		cm.transform = Transform3D(Basis(), Vector3(0.0, (PED_TOP - 0.030) * 0.5, 0.010))
		var cap := BoxMesh.new()
		cap.size = Vector3(0.392, 0.048, 0.352)
		var km: MeshInstance3D = _add(root, cap, chalk)
		km.transform = Transform3D(Basis(), Vector3(0.0, PED_TOP - 0.054, 0.010))


# ---------------------------------------------------------------------------
# joints

## [elbow, wrist, hand]. In torsion the arm on the FREE side crosses up to the far
## shoulder and the weight-side arm goes behind the back, which is the serpentinata
## the reference's turned bodies are quoting.
static func _arm_joints(sh: Vector3, sd: float, wsd: float, twist: bool, chest: Vector3, hip: Vector3) -> Array:
	if not twist:
		var el := sh + Vector3(sd * 0.050, -0.286, -0.024)
		var wr := el + Vector3(sd * 0.028, -0.262, -0.052)
		return [el, wr, wr + Vector3(sd * 0.012, -0.086, -0.020)]
	if sd != wsd:
		# the crossing arm: elbow out and low, hand on the opposite shoulder
		var el2 := sh + Vector3(sd * 0.062, -0.184, -0.128)
		var wr2 := Vector3(-sd * 0.060, chest.y + 0.086, chest.z - 0.150)
		return [el2, wr2, wr2 + Vector3(-sd * 0.088, 0.048, 0.022)]
	# the arm behind the back
	var el3 := sh + Vector3(sd * 0.052, -0.248, 0.062)
	var wr3 := Vector3(sd * 0.096, hip.y + 0.130, hip.z + 0.182)
	return [el3, wr3, wr3 + Vector3(-sd * 0.076, -0.016, 0.014)]


## [knee, ankle, toe].
static func _leg_joints(sd: float, weight: bool, wsd: float, hipw: float, twist: bool) -> Array:
	if weight:
		return [Vector3(sd * 0.104 * hipw, 0.452, -0.014), Vector3(sd * 0.098, 0.098, 0.012),
			Vector3(sd * 0.098, 0.040, -0.044)]
	if twist:
		# the free leg steps back and across, heel lifted
		return [Vector3(sd * 0.088 * hipw, 0.470, 0.086), Vector3(sd * 0.030, 0.118, 0.208),
			Vector3(sd * 0.020, 0.048, 0.264)]
	return [Vector3(sd * 0.148 * hipw, 0.460, -0.070), Vector3(sd * 0.170, 0.100, -0.030),
		Vector3(sd * 0.176, 0.040, -0.088)]


# ---------------------------------------------------------------------------
# the cladding axis — what the body is wearing, as geometry as well as as paint

static func _clad(root: Node3D, rng: RandomNumberGenerator, clad: String, d: float,
		ward: Dictionary, chalk: StandardMaterial3D,
		t_c: Array[Vector3], t_b: Array[Basis], t_rx: Array[float], t_rz: Array[float],
		limbs: Array, head_c: Vector3, head_b: Basis, head_r: float,
		c_sh: Vector3, c_chest: Vector3, c_hip: Vector3, b_sh: Basis,
		wsd: float, frag: bool) -> void:
	var n_seg: int = t_c.size()
	match clad:
		"dots":
			# THE COUNT FALLS AS d SQUARED, not as d. A frieze is three bodies in one
			# 260-mesh budget, so a linear taper would put the group values 80 meshes
			# over the draw-call ceiling with the fur value on top of it.
			var n_dot: int = maxi(int(round(40.0 * d * d)), 8)
			for i in range(n_dot):
				var sp: Array = _pick_surface(rng, t_c, t_b, t_rx, t_rz, limbs, 0.42)
				var p: Vector3 = sp[0]
				var nn: Vector3 = sp[1]
				var r: float = rng.randf_range(0.040, 0.074)
				_ellipsoid(root, ward["mark"], p + nn * r * 0.10, Vector3(r, r * 0.28, r * 1.10), _basis_y_to(nn))
			if not frag:
				# three on the hood, because the reference's dots run over the skull
				for k in range(3):
					var ha: float = rng.randf_range(0.0, TAU)
					var hb: float = rng.randf_range(0.35, 1.15)
					var loc := Vector3(sin(ha) * sin(hb), cos(hb), cos(ha) * sin(hb))
					var hp: Vector3 = head_c + head_b * (loc * head_r * 1.10)
					var hn: Vector3 = (head_b * loc).normalized()
					var hr: float = rng.randf_range(0.030, 0.046)
					_ellipsoid(root, ward["mark"], hp, Vector3(hr, hr * 0.28, hr * 1.08), _basis_y_to(hn))
		"brick":
			# A cape laid in a RUNNING BOND, courses overlapping by a quarter so the
			# stone underneath cannot show through the joints.
			#
			# THE ARC IS 2.2 RADIANS AND NOT THE 1.66 IT WAS BUILT AT, AND THE SWEEP
			# IS WHY. 1.66 puts the masonry on the +Z hemisphere only — the reference
			# is a crowd photographed from BEHIND, so a back-only cape is what the
			# picture shows. The gallery camera is not behind: capture_config_sweep
			# stands at yaw 0.62, a front quarter. From there the cape was mostly on
			# the far side and marble-vs-brick measured 2.18% of frame at
			# stance=fragment — UNDER the corpus's 3% decoration line, and the
			# smallest pair in all 300. Not an inert axis; an axis facing away from
			# the only camera that judges it. The masonry now wraps to the front of
			# the ribs and over both deltoids, which the reference also shows once you
			# look at its near shoulder rather than at its back.
			var wrap: float = rng.randf_range(2.06, 2.32)
			var courses: int = maxi(int(round(8.0 * d)), 3)
			var per: int = maxi(int(round(9.0 * d)), 3)
			var i_lo: int = 1
			var i_hi: int = n_seg - 1
			var span: float = (t_c[i_hi].y - t_c[i_lo].y) / float(courses)
			for k in range(courses):
				var ci: int = int(round(lerpf(float(i_lo), float(i_hi), float(k) / maxf(float(courses - 1), 1.0))))
				var phase: float = 0.5 if k % 2 == 1 else 0.0
				var rx: float = t_rx[ci]
				var rz: float = t_rz[ci]
				for j in range(per):
					var u: float = fposmod((float(j) + phase + 0.5) / float(per), 1.0)
					var ang: float = lerpf(-wrap, wrap, u)
					var loc2 := Vector3(rx * sin(ang), 0.0, rz * cos(ang))
					var nb: Vector3 = (t_b[ci] * Vector3(sin(ang) / rx, 0.0, cos(ang) / rz)).normalized()
					var pb: Vector3 = t_c[ci] + t_b[ci] * loc2 + nb * 0.014
					var bw: float = (2.0 * wrap / float(per)) * maxf(rx, rz) * 1.06
					var bx := BoxMesh.new()
					bx.size = Vector3(bw, span * 1.24, rng.randf_range(0.030, 0.046))
					var bm: MeshInstance3D = _add(root, bx, ward["brick"])
					bm.transform = Transform3D(_basis_z_to(nb), pb)
			# over the shoulders, which is also what stops the cape reading as a bib
			var n_sh: int = maxi(int(round(3.0 * d)), 2)
			var rxs: float = maxf(t_rx[n_seg - 1], 0.001)
			var rzs: float = maxf(t_rz[n_seg - 1], 0.001)
			for s_i in range(2):
				var sd2: float = -1.0 if s_i == 0 else 1.0
				for j2 in range(n_sh):
					var a2: float = lerpf(0.30, 1.98, (float(j2) + 0.5) / float(n_sh)) * sd2
					var n3: Vector3 = (b_sh * Vector3(sin(a2) / rxs, 0.0, cos(a2) / rzs)).normalized()
					var p3: Vector3 = c_sh + b_sh * Vector3(rxs * sin(a2) * 1.22, 0.0, rzs * cos(a2) * 1.08) \
						+ Vector3(0.0, 0.034, 0.0) + n3 * 0.012
					var bx2 := BoxMesh.new()
					bx2.size = Vector3(0.082, 0.054, rng.randf_range(0.030, 0.044))
					var bm2: MeshInstance3D = _add(root, bx2, ward["brick"])
					bm2.transform = Transform3D(_basis_z_to(n3), p3)
		"fur":
			# THE ONE VALUE THAT CHANGES THE SILHOUETTE. Tufts on the surface normal,
			# drooping under their own weight, so the outline goes ragged.
			var n_tuft: int = maxi(int(round(72.0 * d * d)), 14)
			for i in range(n_tuft):
				var sp2: Array = _pick_surface(rng, t_c, t_b, t_rx, t_rz, limbs, 0.30)
				var p2: Vector3 = sp2[0]
				var n2: Vector3 = sp2[1]
				var ln: float = rng.randf_range(0.070, 0.135)
				var dir: Vector3 = (n2 * 1.0 + Vector3.DOWN * rng.randf_range(0.45, 0.95)
					+ Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))).normalized()
				_cone(root, ward["fur"], p2 - n2 * 0.010, p2 + dir * ln, rng.randf_range(0.026, 0.044))
			if not frag:
				for k in range(maxi(int(round(7.0 * d)), 3)):
					var fa: float = rng.randf_range(0.0, TAU)
					var fb: float = rng.randf_range(0.20, 1.25)
					var lc := Vector3(sin(fa) * sin(fb), cos(fb), cos(fa) * sin(fb))
					var fp: Vector3 = head_c + head_b * (lc * head_r * 1.05)
					var fn: Vector3 = (head_b * lc).normalized()
					_cone(root, ward["fur"], fp, fp + (fn + Vector3.DOWN * 0.5).normalized() * rng.randf_range(0.055, 0.095), 0.030)
		"drape":
			# A HEM HAS TO KNOW WHERE THE FLOOR IS. On `fragment` the hip sits 0.12 m
			# up the pedestal, so the tail's canonical -0.47 m lands at y 0.495 —
			# INSIDE the 0.72 m column, and a cloth threaded through solid chalk is
			# the kind of fault that photographs as "a bit odd" rather than as broken.
			_drape(root, rng, ward, d, c_sh, c_chest, c_hip, wsd, (PED_TOP + 0.024) if frag else 0.0)
		_:
			# marble — the baseline the joke needs. Its marks are SUBTRACTIVE: a few
			# chipped edges and a repaired seam, because a nude classical body in this
			# corpus should look excavated rather than freshly cast.
			var n_chip: int = maxi(int(round(6.0 * d)), 3)
			for i in range(n_chip):
				var sp3: Array = _pick_surface(rng, t_c, t_b, t_rx, t_rz, limbs, 0.35)
				var p3: Vector3 = sp3[0]
				var n3: Vector3 = sp3[1]
				var cr: float = rng.randf_range(0.030, 0.062)
				_ellipsoid(root, chalk, p3 - n3 * cr * 0.55, Vector3(cr, cr * 0.42, cr * 0.78), _basis_y_to(n3))


## The drapery: one SurfaceTool ribbon from a shoulder, across the back, to the far
## hip, with a fold ripple across its width and a rolled hem of ellipsoids. Built as
## a sheet rather than as a stack of squashed spheres because the reference's cloth
## is HARD — carved drapery, with edges — and a sphere stack has no edge.
static func _drape(root: Node3D, rng: RandomNumberGenerator, ward: Dictionary, d: float,
		c_sh: Vector3, c_chest: Vector3, c_hip: Vector3, wsd: float, y_floor: float) -> void:
	var sd: float = wsd
	var path: Array[Vector3] = [
		c_sh + Vector3(sd * 0.210, 0.055, 0.010),
		c_chest + Vector3(sd * 0.150, 0.020, 0.168),
		c_chest + Vector3(-sd * 0.020, -0.120, 0.196),
		c_hip + Vector3(-sd * 0.170, 0.010, 0.150),
		c_hip + Vector3(-sd * 0.232, -0.230, 0.036),
		c_hip + Vector3(-sd * 0.246, -0.470, -0.010),
	]
	for i in range(path.size()):
		if path[i].y < y_floor:
			path[i] = Vector3(path[i].x, y_floor, path[i].z)
	var wid: Array = [0.150, 0.230, 0.256, 0.238, 0.196, 0.150]
	var rows: int = maxi(int(round(24.0 * d)), 10)
	var cols: int = maxi(int(round(9.0 * d)), 5)
	var folds: float = float(rng.randi_range(2, 4))
	var phase: float = rng.randf_range(0.0, TAU)
	var amp: float = rng.randf_range(0.022, 0.042)

	var grid: Array = []
	for i in range(rows):
		var u: float = float(i) / float(rows - 1)
		var c: Vector3 = _spline(path, u)
		var ahead: Vector3 = _spline(path, minf(u + 0.02, 1.0))
		var behind: Vector3 = _spline(path, maxf(u - 0.02, 0.0))
		var tan: Vector3 = (ahead - behind)
		if tan.length() < 0.0005:
			tan = Vector3.DOWN
		tan = tan.normalized()
		# the sheet lies OUTWARD from the body's own axis, which is why the cross
		# direction is taken against the vertical and not against a fixed world axis
		var out: Vector3 = (c - Vector3(0.0, c.y, 0.0)).normalized()
		if out.length() < 0.5:
			out = Vector3.BACK
		var cross: Vector3 = tan.cross(out).normalized()
		var w: float = _key(wid, u)
		var row: Array[Vector3] = []
		for j in range(cols):
			var v: float = float(j) / float(cols - 1)
			var ripple: float = amp * sin(v * TAU * folds + phase + u * 2.4) * sin(PI * clampf(u * 1.2, 0.0, 1.0))
			row.append(c + cross * ((v - 0.5) * w) + out * (0.020 + ripple))
		grid.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rows - 1):
		var r0: Array = grid[i]
		var r1: Array = grid[i + 1]
		for j in range(cols - 1):
			var a: Vector3 = r0[j]
			var b: Vector3 = r0[j + 1]
			var c2: Vector3 = r1[j + 1]
			var e: Vector3 = r1[j]
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c2)
			st.add_vertex(a)
			st.add_vertex(c2)
			st.add_vertex(e)
	st.generate_normals()
	# CULL DISABLED, not a guessed winding. A cloth has two faces and the museum
	# walks around it; Godot flips NORMAL for back-facing fragments on its own, so
	# both sides shade correctly and no sign error can leave a hole in the drape.
	var cloth: StandardMaterial3D = ward["cloth"]
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add(root, st.commit(), cloth)

	# the rolled hem, and the knot that holds it on the shoulder
	var hem: int = maxi(int(round(14.0 * d)), 5)
	for i in range(hem):
		var u2: float = float(i) / float(hem - 1)
		var cp: Vector3 = _spline(path, u2)
		var out2: Vector3 = (cp - Vector3(0.0, cp.y, 0.0)).normalized()
		var ah: Vector3 = _spline(path, minf(u2 + 0.03, 1.0))
		var bh: Vector3 = _spline(path, maxf(u2 - 0.03, 0.0))
		var tn: Vector3 = (ah - bh).normalized()
		var cr: Vector3 = tn.cross(out2).normalized()
		var w2: float = _key(wid, u2) * 0.5
		for s in [-1.0, 1.0]:
			var sf: float = s
			_ellipsoid(root, cloth, cp + cr * (sf * w2) + out2 * 0.020,
				Vector3(0.020, 0.030, 0.020), _basis_y_to(tn))
	for k in range(3):
		_ellipsoid(root, cloth, path[0] + Vector3(0.0, -0.020 * float(k), 0.012 * float(k)),
			Vector3(0.062 - 0.010 * float(k), 0.048, 0.058), Basis(Vector3.UP, float(k) * 0.7))


## Catmull-Rom through the control points, clamped at both ends. A polyline would
## kink the drape at every control point and the kink photographs as a crease that
## no cloth would make.
static func _spline(pts: Array[Vector3], u: float) -> Vector3:
	var n: int = pts.size()
	if n < 2:
		return pts[0]
	var f: float = clampf(u, 0.0, 1.0) * float(n - 1)
	var i: int = mini(int(floor(f)), n - 2)
	var t: float = f - float(i)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[i + 1]
	var p3: Vector3 = pts[mini(i + 2, n - 1)]
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## A point on the dressed surface, with its outward normal: the torso's own ellipse
## or one of the limb capsules. `back_bias` is how often it lands on the +Z half,
## because the reference is a crowd photographed from behind.
static func _pick_surface(rng: RandomNumberGenerator, t_c: Array[Vector3], t_b: Array[Basis],
		t_rx: Array[float], t_rz: Array[float], limbs: Array, back_bias: float) -> Array:
	if limbs.is_empty() or rng.randf() < 0.58:
		var i: int = rng.randi_range(0, t_c.size() - 1)
		var ang: float = rng.randf_range(0.0, TAU)
		if rng.randf() < back_bias:
			ang = rng.randf_range(-1.15, 1.15)
		var rx: float = maxf(t_rx[i], 0.001)
		var rz: float = maxf(t_rz[i], 0.001)
		var loc := Vector3(rx * sin(ang), rng.randf_range(-0.022, 0.022), rz * cos(ang))
		var nrm: Vector3 = (t_b[i] * Vector3(sin(ang) / rx, 0.0, cos(ang) / rz)).normalized()
		return [t_c[i] + t_b[i] * loc, nrm]
	var lm: Array = limbs[rng.randi_range(0, limbs.size() - 1)]
	var a: Vector3 = lm[0]
	var b: Vector3 = lm[1]
	var t: float = rng.randf()
	var r: float = lerpf(float(lm[2]), float(lm[3]), t)
	var axis: Vector3 = (b - a)
	if axis.length() < 0.0005:
		axis = Vector3.UP
	axis = axis.normalized()
	var e1: Vector3 = axis.cross(Vector3.UP)
	if e1.length() < 0.01:
		e1 = axis.cross(Vector3.FORWARD)
	e1 = e1.normalized()
	var e2: Vector3 = axis.cross(e1).normalized()
	var a2: float = rng.randf_range(0.0, TAU)
	var n2: Vector3 = (e1 * cos(a2) + e2 * sin(a2)).normalized()
	return [a.lerp(b, t) + n2 * r, n2]


# ---------------------------------------------------------------------------
# the wardrobe — one finish, one palette, one painted skin, dealt from the seed

static func _wardrobe(clad: String, rng: RandomNumberGenerator) -> Dictionary:
	var stone: Color = Color(str(STONE_TONES[rng.randi_range(0, STONE_TONES.size() - 1)]))
	var vein: Color = Color(str(VEIN_TONES[rng.randi_range(0, VEIN_TONES.size() - 1)]))
	var out := {}
	match clad:
		"dots":
			var ground: Color = Color(str(SUIT_GROUND[rng.randi_range(0, SUIT_GROUND.size() - 1)]))
			var dot: Color = Gloss.queer_colour(rng)
			if rng.randf() < 0.45:
				dot = Gloss.QUEER["lemon"]      # the reference's own yellow, most of the time
			out["body"] = _dress("latex", ground, _tex_dots(rng, ground, dot), 1.72, rng)
			out["hair"] = out["body"]
			out["mark"] = Gloss.skin("patent", dot, rng)
		"brick":
			var bt: Color = Color(str(BRICK_TONES[rng.randi_range(0, BRICK_TONES.size() - 1)]))
			var mortar: Color = Color(0.90, 0.88, 0.84).lerp(bt, 0.24)
			out["body"] = _dress("pearl", stone, _tex_marble(rng, stone, vein), 0.86, rng)
			out["hair"] = Gloss.skin("pearl", stone.lerp(vein, 0.24), rng)
			# WET, not matte: a glazed brick. The one dry passage in this file is the
			# chalk footing, and a second matte surface would spend it.
			out["brick"] = _dress("wet", bt, _tex_brick(rng, bt, mortar), 1.62, rng)
		"fur":
			var pt: Color = Color(str(PELT_TONES[rng.randi_range(0, PELT_TONES.size() - 1)]))
			if rng.randf() < 0.30:
				pt = pt.lerp(Gloss.queer_colour(rng), 0.42)
			# A DARK PELT PHOTOGRAPHS BLACK, which is the corpus's oldest trap wearing
			# fur: the dark tone crossed with "ink" put the middle figure of a frieze
			# in as a silhouette with three highlights on it. The tufts carry their
			# own shadowing, so the ground has to keep some value of its own.
			var lum: float = maxf(pt.r, maxf(pt.g, pt.b))
			if lum < 0.34:
				pt = pt.lerp(Color(0.62, 0.60, 0.63), (0.34 - lum) * 2.2)
			out["body"] = _dress("pearl", pt, _tex_pelt(rng, pt), 3.90, rng)
			out["hair"] = out["body"]
			out["fur"] = _dress("pearl", pt.lightened(0.10), _tex_pelt(rng, pt), 5.40, rng)
		"drape":
			var cl: Color = Gloss.queer_colour(rng)
			if rng.randf() < 0.50:
				cl = Gloss.QUEER["lemon"]
			out["body"] = _dress("pearl", stone, _tex_marble(rng, stone, vein), 0.86, rng)
			out["hair"] = Gloss.skin("pearl", stone.lerp(vein, 0.24), rng)
			out["cloth"] = _dress("patent", cl, _tex_cloth(rng, cl), 2.60, rng)
		_:
			out["body"] = _dress("pearl", stone, _tex_marble(rng, stone, vein), 0.86, rng)
			out["hair"] = Gloss.skin("pearl", stone.lerp(vein, 0.30), rng)
	return out


## A dressed surface: a DreamSkin finish carrying a code-drawn pattern as albedo in
## WORLD triplanar, so one image runs unbroken over a hundred primitives. Metallic is
## capped because a mirror photographs black in a bare capture, and emission because
## a pattern under a strong glow stops reading as a pattern.
static func _dress(finish: String, base: Color, tex: ImageTexture, uv: float, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, base, rng)
	m.albedo_color = base
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.5
	m.uv1_scale = Vector3(uv, uv, uv)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	m.metallic = minf(m.metallic, 0.55)
	m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.45)
	return m


# ---------------------------------------------------------------------------
# painted skins — every pixel drawn in code, every tile seamless

## One value-noise table, sampled at 1, 2, 4, 8 grid units. The frequencies are
## powers of two and the lookup wraps with posmod, so the fbm tiles and the triplanar
## has no seam down its X face.
static func _noise_table(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var t := PackedFloat32Array()
	t.resize(NG * NG)
	for i in range(NG * NG):
		t[i] = rng.randf()
	return t


static func _samp(t: PackedFloat32Array, x: float, y: float) -> float:
	var x0: int = int(floor(x))
	var y0: int = int(floor(y))
	var u: float = x - float(x0)
	var v: float = y - float(y0)
	u = u * u * (3.0 - 2.0 * u)
	v = v * v * (3.0 - 2.0 * v)
	var a: float = t[posmod(y0, NG) * NG + posmod(x0, NG)]
	var b: float = t[posmod(y0, NG) * NG + posmod(x0 + 1, NG)]
	var c: float = t[posmod(y0 + 1, NG) * NG + posmod(x0, NG)]
	var e: float = t[posmod(y0 + 1, NG) * NG + posmod(x0 + 1, NG)]
	return lerpf(lerpf(a, b, u), lerpf(c, e, u), v)


static func _fbm(t: PackedFloat32Array, u: float, v: float, oct: int) -> float:
	var s: float = 0.0
	var amp: float = 0.5
	var f: float = 1.0
	for i in range(oct):
		s += amp * _samp(t, u * float(NG) * f, v * float(NG) * f)
		amp *= 0.5
		f *= 2.0
	return s


static func _tex_marble(rng: RandomNumberGenerator, stone: Color, vein: Color) -> ImageTexture:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var tab: PackedFloat32Array = _noise_table(rng)
	var tab2: PackedFloat32Array = _noise_table(rng)
	var fx: float = float(rng.randi_range(2, 4))
	var fy: float = float(rng.randi_range(1, 2))
	var turb: float = rng.randf_range(3.4, 6.6)
	var sharp: float = rng.randf_range(9.0, 18.0)
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var n: float = _fbm(tab, u, v, 4)
			var s: float = sin(TAU * (u * fx + v * fy) + n * turb)
			var k: float = pow(1.0 - absf(s), sharp)
			var mottle: float = 0.94 + 0.10 * _fbm(tab2, u, v, 3)
			var c: Color = Color(stone.r * mottle, stone.g * mottle, stone.b * mottle).lerp(vein, clampf(k * 0.92, 0.0, 1.0))
			img.set_pixel(x, y, Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## The zentai. Rows must be EVEN or the half-cell stagger does not meet itself at the
## tile edge and the suit grows a seam straight down the spine.
static func _tex_dots(rng: RandomNumberGenerator, ground: Color, dot: Color) -> ImageTexture:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var cols: int = 6
	var rows: int = 8
	var cw: float = float(TEX) / float(cols)
	var ch: float = float(TEX) / float(rows)
	var rad: float = cw * rng.randf_range(0.33, 0.40)
	var squash: float = rng.randf_range(1.02, 1.24)     # the reference's dots are ovals
	var tab: PackedFloat32Array = _noise_table(rng)
	for y in range(TEX):
		var py: float = float(y) + 0.5
		var r0: int = int(floor(py / ch))
		for x in range(TEX):
			var px: float = float(x) + 0.5
			var c0: int = int(floor(px / cw))
			var best: float = 1.0e9
			for rr in range(r0 - 1, r0 + 2):
				var off: float = 0.5 if posmod(rr, 2) == 1 else 0.0
				for cc in range(c0 - 1, c0 + 2):
					var gx: float = (float(cc) + 0.5 + off) * cw
					var gy: float = (float(rr) + 0.5) * ch
					var dx: float = px - gx
					var dy: float = (py - gy) / squash
					best = minf(best, dx * dx + dy * dy)
			var dd: float = sqrt(best)
			var sheen: float = 0.92 + 0.14 * _fbm(tab, float(x) / float(TEX), float(y) / float(TEX), 2)
			var c: Color = ground if dd > rad else dot
			img.set_pixel(x, y, Color(clampf(c.r * sheen, 0.0, 1.0), clampf(c.g * sheen, 0.0, 1.0), clampf(c.b * sheen, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _tex_brick(rng: RandomNumberGenerator, brick: Color, mortar: Color) -> ImageTexture:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var courses: int = 8
	var per: int = 5
	var chh: float = float(TEX) / float(courses)
	var bw: float = float(TEX) / float(per)
	var joint: float = rng.randf_range(2.2, 3.6)
	var tab: PackedFloat32Array = _noise_table(rng)
	var tint := PackedFloat32Array()
	tint.resize(courses * per)
	for i in range(courses * per):
		tint[i] = rng.randf_range(0.80, 1.18)
	for y in range(TEX):
		var row: int = int(floor(float(y) / chh))
		var yin: float = float(y) - float(row) * chh
		var off2: float = 0.5 * bw if posmod(row, 2) == 1 else 0.0
		for x in range(TEX):
			var ux: float = fposmod(float(x) - off2, float(TEX))
			var col: int = int(floor(ux / bw))
			var xin: float = ux - float(col) * bw
			var c: Color
			if yin < joint or xin < joint:
				c = mortar
			else:
				var k: float = tint[posmod(row, courses) * per + posmod(col, per)]
				var g: float = 0.94 + 0.12 * _fbm(tab, float(x) / float(TEX), float(y) / float(TEX), 3)
				c = Color(brick.r * k * g, brick.g * k * g, brick.b * k * g)
			img.set_pixel(x, y, Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _tex_pelt(rng: RandomNumberGenerator, base: Color) -> ImageTexture:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var tab: PackedFloat32Array = _noise_table(rng)
	var tab2: PackedFloat32Array = _noise_table(rng)
	var freq: float = float(rng.randi_range(9, 17))
	var wob: float = rng.randf_range(1.4, 3.4)
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var drift: float = _fbm(tab, u, v, 3) * wob
			var hair: float = 0.5 + 0.5 * sin(TAU * u * freq + drift * 4.0)
			var clump: float = _fbm(tab2, u, v, 2)
			var k: float = clampf(0.60 + 0.44 * hair * (0.55 + 0.7 * clump), 0.25, 1.35)
			img.set_pixel(x, y, Color(clampf(base.r * k, 0.0, 1.0), clampf(base.g * k, 0.0, 1.0), clampf(base.b * k, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _tex_cloth(rng: RandomNumberGenerator, base: Color) -> ImageTexture:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var tab: PackedFloat32Array = _noise_table(rng)
	var wf: float = float(rng.randi_range(20, 34))
	var band: float = float(rng.randi_range(2, 4))
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var weave: float = 0.96 + 0.055 * (sin(TAU * u * wf) * sin(TAU * v * wf))
			var fold: float = 0.86 + 0.22 * (0.5 + 0.5 * sin(TAU * v * band + _fbm(tab, u, v, 3) * 3.0))
			var k: float = clampf(weave * fold, 0.30, 1.30)
			img.set_pixel(x, y, Color(clampf(base.r * k, 0.0, 1.0), clampf(base.g * k, 0.0, 1.0), clampf(base.b * k, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# geometry helpers — copied from bodies/nana_gloss.gd, which is where the corpus
# keeps its settle pass; a second implementation of one rule always drifts

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


## Emit one triangle wound so its face points along `ref`.
##
## Godot winds front faces CLOCKWISE and SurfaceTool.generate_normals() takes
## Plane(a, b, c).normal, which Godot builds as (a - c) x (a - b) — the NEGATIVE of
## the textbook (b-a) x (c-a). Written the textbook way every triangle below would
## face inward: correct geometry, inside-out shading, and invisible in any render
## that draws back faces. So the order is CHOSEN against a known outward direction
## rather than reasoned about once and hoped for.
static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ref: Vector3) -> void:
	if (a - c).cross(a - b).dot(ref) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


## A swept surface through a run of elliptical rings, closed with a fan at each end.
##
## WHY THE TRUNK AND THE LIMBS ARE NOT STACKS OF SPHERES. They were, for two
## galleries, and both photographed CORRUGATED — a hard ribbed band at every joint,
## like a stack of tyres. The arithmetic that says it should be fine measures the
## wrong quantity: two ellipsoids of half-height ry at pitch p leave a scallop only
## rz * (1 - sqrt(1 - (p/2/ry)^2)) deep, which at ry 0.115 over a 0.034 pitch is
## 1.2 mm on a 130 mm back and reads as "invisible". But a highlight does not see
## depth, it sees SLOPE, and the slope at that same seam is rx*(p/2)/ry^2 = 0.246,
## a 13.8-degree normal swing that reverses at every station. Smoothing it by
## fattening the ellipsoids needs ry >= 0.25 m — taller than the torso. A stack of
## primitives cannot be a smooth body, so the body is swept instead, and the marks,
## the muscles and the costume stay primitives on top of it.
static func _tube(root: Node3D, mat: StandardMaterial3D, cen: Array[Vector3], bas: Array[Basis],
		rx: Array[float], rz: Array[float], segs: int) -> void:
	var n: int = cen.size()
	if n < 2:
		return
	var s: int = maxi(segs, 8)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in range(n):
		var row: Array[Vector3] = []
		for j in range(s):
			var a: float = TAU * float(j) / float(s)
			row.append(cen[i] + bas[i] * Vector3(rx[i] * sin(a), 0.0, rz[i] * cos(a)))
		rings.append(row)
	for i in range(n - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var axis: Vector3 = (cen[i] + cen[i + 1]) * 0.5
		for j in range(s):
			var k: int = (j + 1) % s
			var p0: Vector3 = r0[j]
			var p1: Vector3 = r0[k]
			var p2: Vector3 = r1[k]
			var p3: Vector3 = r1[j]
			var ref: Vector3 = (p0 + p1 + p2 + p3) * 0.25 - axis
			_tri_out(st, p0, p1, p2, ref)
			_tri_out(st, p0, p2, p3, ref)
	# Fan both ends shut. An open tube is not a hole you notice on a lit render — it
	# is a hole you notice from ONE angle, once the statue is in a hall and someone
	# walks round the far side of it.
	var f0: Array = rings[0]
	var o0: Vector3 = cen[0] - cen[1]
	var fn: Array = rings[n - 1]
	var on: Vector3 = cen[n - 1] - cen[n - 2]
	for j in range(s):
		var k2: int = (j + 1) % s
		_tri_out(st, cen[0], f0[j], f0[k2], o0)
		_tri_out(st, cen[n - 1], fn[j], fn[k2], on)
	st.generate_normals()
	_add(root, st.commit(), mat)


## A limb: one swept tube along a Catmull-Rom through its joints, so the elbow and
## the knee BEND rather than mitre.
##
## THE FRAMES ARE PARALLEL-TRANSPORTED, NOT BUILT INDEPENDENTLY, and skipping that
## tore every leg open at the knee. _basis_y_to() only promises that its Y lands on
## the direction given — the AZIMUTH it picks is whatever UP.cross(d) happens to be,
## and near the vertical that swings wildly for a degree of tilt. A circular ring
## does not care: the SURFACE is identical whatever azimuth it is drawn at. The
## TRIANGULATION cares completely, because ring i vertex j then joins ring i+1
## vertex j at a different angle round the tube, and the quads spiral across the
## limb as long twisted bands. It photographed as a thigh sawn off above a
## separately-capped shin — a break in a mesh that has no break in it. So each frame
## is the previous one rotated by the minimum arc onto the new tangent.
static func _limb_tube(root: Node3D, mat: StandardMaterial3D, joints: Array[Vector3],
		radii: Array, d: float, segs: int) -> void:
	var n: int = maxi(int(round(13.0 * clampf(d, 0.34, 1.0))), 6)
	var cen: Array[Vector3] = []
	var bas: Array[Basis] = []
	var rr: Array[float] = []
	var frame := Basis()
	for i in range(n):
		var u: float = float(i) / float(n - 1)
		var ahead: Vector3 = _spline(joints, minf(u + 0.03, 1.0))
		var behind: Vector3 = _spline(joints, maxf(u - 0.03, 0.0))
		var dir: Vector3 = ahead - behind
		if dir.length() < 0.0005:
			dir = Vector3.DOWN
		dir = dir.normalized()
		if i == 0:
			frame = _basis_y_to(dir)
		else:
			var prev: Vector3 = frame.y.normalized()
			var ax: Vector3 = prev.cross(dir)
			if ax.length() > 0.000001:
				frame = Basis(ax.normalized(), acos(clampf(prev.dot(dir), -1.0, 1.0))) * frame
		cen.append(_spline(joints, u))
		bas.append(frame)
		rr.append(_key(radii, u))
	_tube(root, mat, cen, bas, rr, rr, segs)


## The trunk as ONE swept surface with domed ends. The domes are buried in the
## glutes and the traps, so they cost nothing and close the shape.
static func _torso_tube(root: Node3D, mat: StandardMaterial3D, t_c: Array[Vector3],
		t_b: Array[Basis], t_rx: Array[float], t_rz: Array[float], segs: int) -> void:
	var n: int = t_c.size()
	if n < 2:
		return
	var along: Array = [0.80, 0.58, 0.30]
	var wide: Array = [0.30, 0.64, 0.88]
	var cen: Array[Vector3] = []
	var bas: Array[Basis] = []
	var arx: Array[float] = []
	var arz: Array[float] = []
	var d0: Vector3 = (t_c[0] - t_c[1]).normalized()
	var l0: float = (t_rx[0] + t_rz[0]) * 0.5
	for k in range(along.size()):
		cen.append(t_c[0] + d0 * (l0 * float(along[k])))
		bas.append(t_b[0])
		arx.append(t_rx[0] * float(wide[k]))
		arz.append(t_rz[0] * float(wide[k]))
	for i in range(n):
		cen.append(t_c[i])
		bas.append(t_b[i])
		arx.append(t_rx[i])
		arz.append(t_rz[i])
	var d1: Vector3 = (t_c[n - 1] - t_c[n - 2]).normalized()
	var l1: float = (t_rx[n - 1] + t_rz[n - 1]) * 0.5
	for k in range(along.size() - 1, -1, -1):
		cen.append(t_c[n - 1] + d1 * (l1 * float(along[k])))
		bas.append(t_b[n - 1])
		arx.append(t_rx[n - 1] * float(wide[k]))
		arz.append(t_rz[n - 1] * float(wide[k]))
	_tube(root, mat, cen, bas, arx, arz, segs)


static func _cone(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r: float) -> void:
	var v: Vector3 = b - a
	var l: float = v.length()
	if l < 0.0008:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = r
	cyl.height = l
	cyl.radial_segments = 5
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


## A frame with +Z along `dir` and +Y as upright as it can be — what a brick needs,
## since a brick has a face and a course line and _basis_y_to would spin it.
static func _basis_z_to(dir: Vector3) -> Basis:
	var z: Vector3 = dir.normalized()
	var y: Vector3 = Vector3.UP - z * Vector3.UP.dot(z)
	if y.length() < 0.001:
		y = Vector3.FORWARD - z * Vector3.FORWARD.dot(z)
	y = y.normalized()
	return Basis(y.cross(z).normalized(), y, z)


static func _key(keys: Array, t: float) -> float:
	var n: int = keys.size() - 1
	if n <= 0:
		return float(keys[0])
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		return float(keys[n])
	var u: float = f - float(i)
	var sm: float = u * u * (3.0 - 2.0 * u)
	return lerpf(float(keys[i]), float(keys[i + 1]), sm)


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
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), pivot + (tf.origin - pivot) * k)


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
