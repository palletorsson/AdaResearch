extends RefCounted

## dream_bodies / crystal_suit — one hooded figure encrusted in crystal, standing
## among leaning iridescent sheets.
##
## Reference: C:/Users/palle/Documents/FinalMD/m1/0_0280-0000.jpg — a frieze of
## standing bodies whose ENTIRE skin is thousands of small rounded grains. Not a
## pattern painted on a body: the body IS the grains, packed like roe or gravel,
## and the light is caught per grain rather than per limb. The colour does not
## scatter, it runs in ZONES — one figure is lavender through the shoulders and
## ochre down the trailing limb, another pale mint against a dark ground threaded
## with green filaments. The bodies are columnar, faceless, hooded at the top,
## with limbs flung out that taper into more grains.
##
## Reproduced, and how:
##   1. The crust is REAL GEOMETRY, never a texture. Every grain is a solid of 10
##      to 18 triangles with its own facets, its own spin and its own colour, so
##      it catches a highlight the way the reference's pebbles do. A texture
##      cannot do that: it has one normal per surface and the whole body flips
##      from lit to unlit together.
##   2. One anchor per ~4.2 cm of skin, taken on the union surface of the body's
##      own shells (see _anchors) — so the grains sit ON the figure, follow its
##      normals, and never grow inward through it.
##   3. Colour ZONES, not noise: the palette index is a function of height and
##      azimuth, so a shoulder is magenta and a hem is gold, exactly as the
##      reference bands its bodies.
##   4. About 8% of grains are dealt into a SECOND crust wearing neon, which is
##      what makes the surface glitter rather than merely shine.
##   5. The sheets: a few enormous curved panels in holo, oil slick or chrome,
##      leaning like petals. They are slabs, not planes — a single-sided sheet
##      vanishes from behind under the default CULL_BACK and reads as a hole.
##
## THE FIGURE FACES THE CAMERA, ON PURPOSE. It is authored with its front at -Z,
## the way its neighbours are, and then turned by PI + 0.62 so that -Z lands on
## (sin 0.62, 0, cos 0.62) — the azimuth capture_config_sweep.gd puts its camera
## on (YAW 0.62, PITCH -0.26; dir = (sin y cos p, -sin p, cos y cos p), camera at
## centre + dir). Without that turn the canonical standpoint photographs the back
## of the hood, and this family's whole argument — the dry blind head inside a
## jewelled cowl — is on the far side. THE PANELS KEEP A GAP ON THE SAME AZIMUTH
## for the same reason: the corpus's own trap is furniture standing in front of
## the subject, and a sheet 0.4 m wide at 0.45 m radius would hide the crust the
## other axis is trying to argue.
##
## THE ONE MATTE PASSAGE IS THE BLIND HEAD. Everything on this statue is wet —
## latex under-suit, candy grains, neon sparks, foil sheets — except the head,
## which is dry chalk plaster, faceless, and carries no crust at all. It sits in
## the mouth of the hood as the single dull thing in the frame, and the crust
## only reads as crystal because there is something beside it that is powder.
## The bare zone that keeps grains off it also strips the cowl's INNER surface,
## so the hood is jewelled outside and chalk-dry within.
##
## Given up: the frieze (this is one figure, not a row), the reference's green
## filament ground, its tentacular limbs (the arms here are spread and blunt —
## a body as a form, not an anatomy), and the scallop-fan ridges on two of its
## figures.
##
## AXES — two, and both cut the object rather than tune it:
##   crust  — what habit the crystal grows in. Every value is dealt onto the SAME
##            anchors with the SAME colours, so the axis is the mineral and
##            nothing else. "gravel" is the reference's packed roe; "spire" grows
##            hexagonal prisms with pyramid tips out along the normal, a
##            bristling quartz hedgehog; "shard" lays flat plates tangent and
##            overlapping like mica or roof tiles; "bloom" gathers grains into
##            radiating desert-rose rosettes on a dusted body; "geode" strips the
##            body back to its dark suit except for five to seven broken pockets
##            where prisms crowd, longest at the middle, ringed with rim plates.
##   panels — what the sheets do. "leaning" is three big petals standing on the
##            plinth and leaning in; "shell" is five rising close behind and
##            curling forward over the shoulders, a niche; "fallen" drops them
##            flat on the plinth in a crumpled ring and leaves the body standing
##            clear; "wings" grows two out of the shoulder blades; "grove" stands
##            nine narrow blades of unequal height around her like reeds.
##
## Both axes change the SILHOUETTE and the marks in a single still, which is the
## only kind of change a photograph can be evidence of.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const PLINTH_TOP: float = 0.055
## The canonical sweep camera's azimuth. Derived, not chosen — see the header.
const FRONT_YAW: float = 0.62
## One anchor per this much skin. 0.042 puts ~2,500 grains on a 1.6 m body:
## dense enough to read as an encrustation, cheap enough to build on the main
## thread while someone is walking through the hall.
const STEP: float = 0.042
## Grains a single shell may contribute. The cap is a guard against the hem —
## the widest shell wants ~380 samples and every one of them costs a test against
## every other shell.
const GRAINS_PER_SHELL: int = 420

## What a grain may be made of. No "chrome" and no "oilslick": both carry a
## painted albedo texture, and a texture on a 2 cm facet is one flat colour
## chosen at random — the vertex colour is what has to speak here.
const CRUST_FIN: Array[String] = ["patent", "wet", "candy", "latex", "pearl"]
## What a sheet is made of. These three DO want their painted sweep: a 1.4 m
## panel is where an iridescent band has room to run.
const PANEL_FIN: Array[String] = ["holo", "oilslick", "chrome"]


static func describe() -> String:
	return "A hooded faceless figure crusted in thousands of small crystals — packed gravel, quartz spires, mica plates, desert roses or broken geode pockets — standing among enormous leaning sheets of iridescent foil."


static func axes() -> Dictionary:
	return {
		"crust": ["gravel", "spire", "shard", "bloom", "geode"],
		"panels": ["leaning", "shell", "fallen", "wings", "grove"],
	}


## The prediction, as data, so tools/dream_bodies_promote.py carries it into the
## registry rather than anyone retyping it. Named pair, number, arithmetic.
static func predicted() -> Dictionary:
	return {
		"pair": "crust: gravel vs shard (at any one panels value)",
		"predicted_pct": 9.5,
		"reasoning": ("gravel and shard are the two habits that HUG the body — both are "
			+ "dealt onto identical anchors in identical colours over an identical core, "
			+ "so neither the silhouette nor the hue moves and only the grain's own shape "
			+ "changes. Arithmetic: the body is ~30% of frame at framing 0.62; the crust "
			+ "covers ~0.8 of it, so ~24% of frame is grain; a grain is ~4-5 px, and "
			+ "re-shaping a facet moves its highlight and its two shadow edges but not its "
			+ "interior colour, so call it 40% of crust pixels over threshold. "
			+ "0.30 x 0.80 x 0.40 = 9.6%, round to 9.5%. It is a LOWER bound: this "
			+ "arithmetic has no shadows, no AO and no antialiasing in it, and every "
			+ "prediction in the corpus has under-shot by 1.5x to 7x. A measurement BELOW "
			+ "9.5% means the plates and the pebbles are not reaching the surface, not "
			+ "that the axis is quiet."),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var crust: String = String(opts.get("crust", "gravel"))
	var panels: String = String(opts.get("panels", "leaning"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- WHO THIS ONE IS, DEALT BEFORE EITHER AXIS IS READ --------------------
	# The order matters and is the reason the prediction above means anything:
	# proportions, palette, shells and anchors all come off the seed before a
	# single `if crust ==` is reached, so two values of one axis are two crusts
	# on ONE body rather than two different statues.
	var hem_w: float = rng.randf_range(0.92, 1.10)
	# THE ARM SPAN AND EVERY PANEL RADIUS BELOW ARE A HEIGHT BUDGET, not a taste.
	# The settle fits the union into 1.20 m across before it fits it into 1.68 m
	# tall, so a wide statue is a SHORT one: the first cut of this family measured
	# 1.20 across and 1.23 tall, three quarters of a metre of head-room thrown away
	# and a third of the crust's pixels with it. The probe passed it — 1.23 clears
	# the 0.9 floor — which is why the number to watch is the pair, not the pass.
	var span: float = rng.randf_range(0.355, 0.425)
	var head_r: float = rng.randf_range(0.098, 0.115)
	var hood_rise: float = rng.randf_range(0.135, 0.180)
	var arm_lift: float = rng.randf_range(0.05, 0.17)
	var twist: float = deg_to_rad(rng.randf_range(-11.0, 11.0))
	var hue_shift: float = rng.randf_range(0.0, 3.0)
	var zone_k: float = rng.randf_range(2.3, 3.6)

	var pal: Array[Color] = []
	pal.append(Gloss.queer_colour(rng))
	pal.append(Gloss.queer_colour(rng))
	pal.append(Gloss.queer_colour(rng))
	var spark_c: Color = Gloss.queer_colour(rng)
	var crust_fin: String = CRUST_FIN[rng.randi_range(0, CRUST_FIN.size() - 1)]
	var panel_fin: String = PANEL_FIN[rng.randi_range(0, PANEL_FIN.size() - 1)]

	# --- the wardrobe --------------------------------------------------------
	var mat_suit: StandardMaterial3D = Gloss.skin("latex", pal[0].darkened(0.72), rng)
	# MATTE, on purpose, and the only one: the blind head. See the header.
	var mat_chalk: StandardMaterial3D = Gloss.skin("matte", Color(0.87, 0.85, 0.80))
	var mat_crust: StandardMaterial3D = _crust_mat(crust_fin, pal[0], rng)
	var mat_spark: StandardMaterial3D = _crust_mat("neon", spark_c, rng)
	var mat_plinth: StandardMaterial3D = Gloss.skin("pearl", Color(0.70, 0.72, 0.78), rng)

	# --- the body, as shells; the crust is grown on the SAME list -------------
	var shells: Array = _shells(rng, hem_w, span, head_r, hood_rise, arm_lift, twist)
	var head_c: Vector3 = shells[_head_index(shells)]["c"]
	# The bare zone. It keeps the crust off the chalk head AND off the cowl's
	# inner face, which no inside-test would have caught: the lining of the hood
	# is not inside anything, so without this the crystals grow into the skull.
	var bare: Array = [{"c": head_c + Vector3(0.0, 0.010, -0.020), "r": head_r + 0.085}]

	for s_v in shells:
		var s: Dictionary = s_v
		var mat: StandardMaterial3D = mat_chalk if bool(s.get("chalk", false)) else mat_suit
		_ellipsoid(root, mat, s["c"], s["r"], s["b"])

	var anchors: Array = _anchors(shells, bare, rng, pal, hue_shift, zone_k)

	# --- the crust: two SurfaceTools, one wet and one lit ---------------------
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sp := SurfaceTool.new()
	sp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_spark: int = _grow(st, sp, anchors, crust, rng)

	var crust_mesh: ArrayMesh = st.commit()
	if crust_mesh != null and crust_mesh.get_surface_count() > 0:
		_add(root, crust_mesh, mat_crust)
	if n_spark > 0:
		var spark_mesh: ArrayMesh = sp.commit()
		if spark_mesh != null and spark_mesh.get_surface_count() > 0:
			_add(root, spark_mesh, mat_spark)

	# --- the sheets ----------------------------------------------------------
	var specs: Array = _panel_specs(panels, rng)
	for i in range(specs.size()):
		var spec: Dictionary = specs[i]
		var pc: Color = pal[i % pal.size()]
		_panel(root, Gloss.skin(panel_fin, pc, rng), spec)

	# --- turn the figure to the standpoint that photographs it ---------------
	# -Z -> (sin 0.62, 0, cos 0.62). A Y rotation sends (0,0,-1) to
	# (-sin t, 0, -cos t), so t = PI + 0.62.
	_yaw_all(root, PI + FRONT_YAW)

	# --- the measured settle -------------------------------------------------
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

	var slab := BoxMesh.new()
	slab.size = Vector3(minf(1.20, box.size.x + 0.10), PLINTH_TOP, minf(1.20, box.size.z + 0.10))
	var pm: MeshInstance3D = _add(root, slab, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# the body — ONE list of shells, which is both what is drawn and what is crusted

static func _shells(rng: RandomNumberGenerator, hem_w: float, span: float,
		head_r: float, hood_rise: float, arm_lift: float, twist: float) -> Array:
	var out: Array = []

	# the robe, hem to shoulder: a bell narrowing into a column
	var ys: Array = [0.105, 0.245, 0.385, 0.520, 0.650, 0.775, 0.890, 1.000, 1.105, 1.195]
	var rx: Array = [0.300, 0.278, 0.250, 0.222, 0.205, 0.190, 0.168, 0.172, 0.188, 0.196]
	var ry: Array = [0.115, 0.125, 0.125, 0.120, 0.115, 0.110, 0.105, 0.105, 0.100, 0.092]
	var rz: Array = [0.275, 0.255, 0.230, 0.205, 0.190, 0.170, 0.150, 0.152, 0.160, 0.158]
	var zo: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.012, -0.014, -0.006]
	for i in range(ys.size()):
		# the hem widens with hem_w, the ribcage does not — a figure gets a skirt,
		# not a uniformly fat body
		var k: float = lerpf(hem_w, 1.0, clampf(float(i) / 6.0, 0.0, 1.0))
		out.append(_shell(Vector3(0.0, float(ys[i]), float(zo[i])),
			Vector3(float(rx[i]) * k, float(ry[i]), float(rz[i]) * k)))

	# shoulders
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		out.append(_shell(Vector3(sd * 0.185, 1.215, 0.0), Vector3(0.098, 0.092, 0.104)))

	# neck
	out.append(_shell(Vector3(0.0, 1.272, -0.008), Vector3(0.072, 0.070, 0.072)))

	# THE HEAD — chalk, and no crust on it. The family's one dry passage.
	var head_c := Vector3(0.0, 1.378, -0.020)
	var hd: Dictionary = _shell(head_c, Vector3(head_r, head_r * 1.14, head_r))
	hd["chalk"] = true
	hd["bare"] = true
	out.append(hd)

	# arms, spread and blunt — no hands, the reference has none either
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var a0 := Vector3(sd * 0.205, 1.222, 0.0)
		var a1 := Vector3(sd * span, 1.222 + arm_lift, -0.030)
		for k2 in range(5):
			var t: float = float(k2) / 4.0
			var c: Vector3 = a0.lerp(a1, t) + Vector3(0.0, 0.035 * sin(PI * t), 0.0)
			var r: float = lerpf(0.086, 0.041, t)
			out.append(_shell(c, Vector3(r, r, r)))

	# the cowl: a horseshoe round the head, open at the front
	out.append(_shell(head_c + Vector3(0.0, 0.055, 0.150), Vector3(0.150, 0.135, 0.098)))
	for s_i in range(2):
		var sd2: float = -1.0 if s_i == 0 else 1.0
		out.append(_shell(head_c + Vector3(sd2 * 0.148, 0.030, 0.045), Vector3(0.072, 0.148, 0.118)))
	out.append(_shell(head_c + Vector3(0.0, hood_rise, 0.028), Vector3(0.140, 0.088, 0.132)))
	out.append(_shell(head_c + Vector3(0.0, 0.108, -0.078), Vector3(0.118, 0.058, 0.062)))

	# THE TWIST, applied as a pass over everything above the waist. A figure
	# whose shoulders and hood sit square to its hips is a mannequin; this is
	# what stops the two arms and the cowl from being one mirrored diagram.
	for s_v in out:
		var s: Dictionary = s_v
		var c2: Vector3 = s["c"]
		var t2: float = clampf((c2.y - 0.95) / 0.45, 0.0, 1.0)
		if t2 <= 0.0:
			continue
		var ang: float = twist * t2
		var b := Basis(Vector3.UP, ang)
		s["c"] = b * c2
		s["b"] = b
	return out


static func _shell(c: Vector3, r: Vector3) -> Dictionary:
	return {"c": c, "r": r, "b": Basis(), "rmax": maxf(r.x, maxf(r.y, r.z))}


static func _head_index(shells: Array) -> int:
	for i in range(shells.size()):
		if bool((shells[i] as Dictionary).get("bare", false)):
			return i
	return 0


# ---------------------------------------------------------------------------
# the anchors — where a grain may stand
#
# Sampled on each shell with a Fibonacci lattice (even coverage, no pole
# crowding, deterministic), then rejected if the point lies inside ANY other
# shell. That is what makes the result the surface of the UNION rather than a
# heap of overlapping crusts: a grain in the armpit would otherwise be buried in
# the ribcage and pay for triangles nobody can see.

static func _anchors(shells: Array, bare: Array, rng: RandomNumberGenerator,
		pal: Array[Color], hue_shift: float, zone_k: float) -> Array:
	var out: Array = []
	for i in range(shells.size()):
		var s: Dictionary = shells[i]
		if bool(s.get("bare", false)):
			continue
		var c: Vector3 = s["c"]
		var r: Vector3 = s["r"]
		var b: Basis = s["b"]
		var rm: float = (r.x + r.y + r.z) / 3.0
		var area: float = 4.0 * PI * rm * rm
		var n: int = clampi(int(round(area / (STEP * STEP * 0.95))), 10, GRAINS_PER_SHELL)
		var spin: float = rng.randf() * TAU
		for k in range(n):
			var u: Vector3 = _fib_dir(k, n, spin)
			var p: Vector3 = c + b * Vector3(u.x * r.x, u.y * r.y, u.z * r.z)
			if _inside_any(shells, i, p):
				continue
			if _in_bare(bare, p):
				continue
			var nrm: Vector3 = (b * Vector3(u.x / r.x, u.y / r.y, u.z / r.z)).normalized()
			# COLOUR IN ZONES, NOT NOISE. Height plus a slow azimuthal swing, so a
			# shoulder is one hue and a hem another — the reference bands its
			# bodies, and a per-grain random colour photographs as grey mush.
			var zone: float = p.y * zone_k + sin(atan2(p.x, p.z) * 2.0) * 0.55 + hue_shift
			var ci: int = floori(zone) % pal.size()
			if ci < 0:
				ci += pal.size()
			var col: Color = pal[ci].lerp(Color(1.0, 1.0, 1.0), rng.randf() * 0.24)
			out.append({
				"p": p,
				"n": nrm,
				"c": col,
				"spin": rng.randf() * TAU,
				"k": rng.randf(),
				"spark": rng.randf() < 0.08,
			})
	return out


static func _fib_dir(k: int, n: int, spin: float) -> Vector3:
	var y: float = 1.0 - 2.0 * (float(k) + 0.5) / float(n)
	var r: float = sqrt(maxf(0.0, 1.0 - y * y))
	var th: float = spin + float(k) * 2.39996323
	return Vector3(cos(th) * r, y, sin(th) * r)


static func _inside_any(shells: Array, skip: int, p: Vector3) -> bool:
	for j in range(shells.size()):
		if j == skip:
			continue
		var s: Dictionary = shells[j]
		var c: Vector3 = s["c"]
		var rmax: float = s["rmax"]
		var d: Vector3 = p - c
		if d.length_squared() > rmax * rmax:
			continue                      # cheap reject first; most tests end here
		var q: Vector3 = (s["b"] as Basis).transposed() * d
		var r: Vector3 = s["r"]
		var e: float = (q.x / r.x) * (q.x / r.x) + (q.y / r.y) * (q.y / r.y) + (q.z / r.z) * (q.z / r.z)
		# 0.985, not 1.0: a point exactly on a seam belongs to both shells, and
		# culling it leaves a bald ring at every joint.
		if e < 0.985:
			return true
	return false


static func _in_bare(bare: Array, p: Vector3) -> bool:
	for z_v in bare:
		var z: Dictionary = z_v
		if p.distance_to(z["c"] as Vector3) < float(z["r"]):
			return true
	return false


# ---------------------------------------------------------------------------
# the crust axis — what grows at an anchor

static func _grow(st: SurfaceTool, sp: SurfaceTool, anchors: Array, crust: String,
		rng: RandomNumberGenerator) -> int:
	var n_spark: int = 0

	# geode picks its pockets first, spread apart, so five sockets do not land in
	# one shoulder
	var pockets: Array[Vector3] = []
	var pr: float = 0.22
	if crust == "geode" and not anchors.is_empty():
		var want: int = rng.randi_range(5, 7)
		var guard: int = 0
		while pockets.size() < want and guard < 500:
			guard += 1
			var a: Dictionary = anchors[rng.randi_range(0, anchors.size() - 1)]
			var p0: Vector3 = a["p"]
			if p0.y < 0.28:
				continue
			var ok: bool = true
			for q_v in pockets:
				var q: Vector3 = q_v
				if p0.distance_to(q) < 0.30:
					ok = false
					break
			if ok:
				pockets.append(p0)

	for a_v in anchors:
		var a: Dictionary = a_v
		var p: Vector3 = a["p"]
		var nrm: Vector3 = a["n"]
		var col: Color = a["c"]
		var spin: float = float(a["spin"])
		var k: float = float(a["k"])
		var target: SurfaceTool = sp if bool(a["spark"]) else st
		if bool(a["spark"]):
			n_spark += 1

		match crust:
			"spire":
				if k < 0.55:
					var ln: float = lerpf(0.030, 0.085, k / 0.55)
					var lean: Vector3 = Vector3(rng.randf_range(-0.22, 0.22),
						rng.randf_range(-0.22, 0.22), rng.randf_range(-0.22, 0.22))
					_grain_prism(target, p, nrm, ln, rng.randf_range(0.008, 0.015), spin, col, lean)
				else:
					_grain_octa(target, p, nrm, rng.randf_range(0.009, 0.016),
						rng.randf_range(0.008, 0.016), spin, col, rng)
			"shard":
				_grain_plate(target, p, nrm, spin, rng.randf_range(0.014, 0.026),
					rng.randf_range(0.018, 0.034), rng.randf_range(0.0028, 0.0055),
					rng.randf_range(0.45, 1.05), col)
			"bloom":
				if k < 0.055:
					_rosette(target, p, nrm, spin, col, rng)
				else:
					_grain_octa(target, p, nrm, rng.randf_range(0.006, 0.011),
						rng.randf_range(0.005, 0.010), spin, col, rng)
			"geode":
				var d: float = 1.0e9
				for q_v2 in pockets:
					var q2: Vector3 = q_v2
					d = minf(d, p.distance_to(q2))
				if d < pr:
					var t: float = d / pr
					_grain_prism(target, p, nrm, lerpf(0.078, 0.018, t) * rng.randf_range(0.75, 1.25),
						rng.randf_range(0.008, 0.014), spin, col,
						Vector3(rng.randf_range(-0.18, 0.18), rng.randf_range(-0.18, 0.18),
							rng.randf_range(-0.18, 0.18)))
				elif d < pr * 1.22:
					_grain_plate(target, p, nrm, spin, rng.randf_range(0.010, 0.018),
						rng.randf_range(0.012, 0.022), 0.003, rng.randf_range(0.5, 1.1), col)
				elif k < 0.32:
					_grain_octa(target, p, nrm, rng.randf_range(0.004, 0.008),
						rng.randf_range(0.003, 0.007), spin, col, rng)
			_:
				# "gravel" — the reference's packed roe, and the default
				_grain_octa(target, p, nrm, rng.randf_range(0.013, 0.023),
					rng.randf_range(0.010, 0.021), spin, col, rng)
	return n_spark


## A pebble: a low irregular bipyramid, radius jittered per vertex so no two
## catch the light the same way. 10 triangles.
static func _grain_octa(st: SurfaceTool, p: Vector3, nrm: Vector3, rad: float,
		h: float, spin: float, col: Color, rng: RandomNumberGenerator) -> void:
	var fb: Basis = _frame(nrm, spin)
	var k: int = 5
	var apex: Vector3 = p + nrm * h
	var base: Vector3 = p - nrm * (h * 0.60)
	var ring: Array[Vector3] = []
	for i in range(k):
		var ang: float = TAU * float(i) / float(k)
		var rr: float = rad * rng.randf_range(0.70, 1.20)
		ring.append(p + fb * Vector3(cos(ang) * rr, 0.0, sin(ang) * rr))
	for i in range(k):
		var q0: Vector3 = ring[i]
		var q1: Vector3 = ring[(i + 1) % k]
		_tri(st, q0, q1, apex, col, ((q0 + q1 + apex) / 3.0 - p).normalized())
		_tri(st, q0, q1, base, col, ((q0 + q1 + base) / 3.0 - p).normalized())


## A quartz prism: six sides and a pyramid tip, leaning a little off the normal
## so a field of them is a thicket and not a lawn. 18 triangles.
static func _grain_prism(st: SurfaceTool, p: Vector3, nrm: Vector3, ln: float,
		rad: float, spin: float, col: Color, lean: Vector3) -> void:
	var dir: Vector3 = (nrm + lean).normalized()
	var fb: Basis = _frame(dir, spin)
	var k: int = 6
	var b0: Vector3 = p - dir * (rad * 0.7)
	var t0: Vector3 = p + dir * ln
	var apex: Vector3 = t0 + dir * (rad * 1.45)
	var lo: Array[Vector3] = []
	var hi: Array[Vector3] = []
	for i in range(k):
		var ang: float = TAU * float(i) / float(k)
		var off := Vector3(cos(ang), 0.0, sin(ang))
		lo.append(b0 + fb * (off * rad))
		hi.append(t0 + fb * (off * rad * 0.84))
	for i in range(k):
		var j: int = (i + 1) % k
		var out_h: Vector3 = ((lo[i] + lo[j] + hi[i] + hi[j]) / 4.0 - p).normalized()
		_tri(st, lo[i], lo[j], hi[j], col, out_h)
		_tri(st, lo[i], hi[j], hi[i], col, out_h)
		_tri(st, hi[i], hi[j], apex, col, ((hi[i] + hi[j] + apex) / 3.0 - t0).normalized())


## A mica plate, lying near-tangent and tilted. A closed slab of 12 triangles —
## a single quad would be invisible from behind under CULL_BACK.
static func _grain_plate(st: SurfaceTool, p: Vector3, nrm: Vector3, spin: float,
		w: float, ln: float, th: float, tilt: float, col: Color) -> void:
	var fb: Basis = _frame(nrm, spin)
	# tilt the plate off the surface about its own width axis, so plates overlap
	# like roof tiles rather than tiling flat
	var pb: Basis = fb * Basis(Vector3.RIGHT, tilt)
	var c: Vector3 = p + nrm * (th * 1.2)
	_box(st, c, pb, Vector3(w, th, ln), col)


## A desert rose: blades radiating from one point, each tilted up out of the
## surface. 7 blades x 12 = 84 triangles, which is why only ~5% of anchors get one.
static func _rosette(st: SurfaceTool, p: Vector3, nrm: Vector3, spin: float,
		col: Color, rng: RandomNumberGenerator) -> void:
	var fb: Basis = _frame(nrm, spin)
	var k: int = rng.randi_range(6, 8)
	for i in range(k):
		var ang: float = TAU * float(i) / float(k) + rng.randf_range(-0.14, 0.14)
		var d0: Vector3 = fb * Vector3(cos(ang), 0.0, sin(ang))
		var dir: Vector3 = (d0 + nrm * rng.randf_range(0.35, 0.85)).normalized()
		var wid: Vector3 = nrm.cross(dir)
		if wid.length_squared() < 1.0e-8:
			wid = fb * Vector3.RIGHT
		wid = wid.normalized()
		var thin: Vector3 = dir.cross(wid).normalized()
		var bb := Basis(wid, thin, dir)
		var ln: float = rng.randf_range(0.020, 0.040)
		_box(st, p + dir * (ln * 0.85), bb,
			Vector3(rng.randf_range(0.008, 0.016), rng.randf_range(0.0022, 0.0042), ln), col)


# ---------------------------------------------------------------------------
# the panels axis — where the sheets are and what they do

static func _panel_specs(panels: String, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	match panels:
		"shell":
			# five rising close behind, curling forward over the shoulders
			for i in range(5):
				var a: float = 1.15 + float(i) * (3.98 / 4.0) + rng.randf_range(-0.10, 0.10)
				var d: Vector3 = _out(a)
				out.append(_spec(d * rng.randf_range(0.30, 0.37) + Vector3(0.0, 0.015, 0.0),
					d * rng.randf_range(0.15, 0.22) + Vector3(0.0, rng.randf_range(1.30, 1.52), -0.12),
					_lat(a), 0.11, rng.randf_range(0.24, 0.34), d * rng.randf_range(0.07, 0.13),
					rng.randf_range(0.55, 0.90), rng.randf_range(-0.7, 0.7), 0.014))
		"fallen":
			# collapsed on the plinth, the body standing clear above them
			for i in range(4):
				var a2: float = 1.40 + float(i) * 1.17 + rng.randf_range(-0.16, 0.16)
				var d2: Vector3 = _out(a2)
				out.append(_spec(d2 * 0.16 + Vector3(0.0, 0.030, 0.0),
					d2 * rng.randf_range(0.38, 0.47) + Vector3(0.0, rng.randf_range(0.02, 0.10), 0.0),
					_lat(a2), 0.12, rng.randf_range(0.24, 0.34),
					Vector3(0.0, rng.randf_range(0.10, 0.20), 0.0),
					rng.randf_range(0.5, 1.0), rng.randf_range(-1.2, 1.2), 0.014))
		"wings":
			# grown out of the shoulder blades, not off the ground
			for s_i in range(2):
				var sd: float = -1.0 if s_i == 0 else 1.0
				# lat is UP here, so a wing's WIDTH grows the statue's height, not its
				# span — which is why the tips sit lower than the leaning panels'
				out.append(_spec(Vector3(sd * 0.15, 1.06, 0.085),
					Vector3(sd * rng.randf_range(0.38, 0.46), rng.randf_range(1.28, 1.42),
						rng.randf_range(0.20, 0.32)),
					Vector3(0.0, 1.0, 0.0),
					0.10, rng.randf_range(0.20, 0.27),
					Vector3(sd * 0.10, 0.06, 0.08),
					rng.randf_range(0.45, 0.80), sd * rng.randf_range(0.4, 0.9), 0.014))
		"grove":
			# nine reeds of unequal height
			for i in range(9):
				var a3: float = 0.95 + float(i) * (4.38 / 8.0) + rng.randf_range(-0.12, 0.12)
				var d3: Vector3 = _out(a3)
				var foot: Vector3 = d3 * rng.randf_range(0.30, 0.44) + Vector3(0.0, 0.015, 0.0)
				out.append(_spec(foot,
					foot * 0.86 + Vector3(0.0, rng.randf_range(0.50, 1.40), 0.0),
					_lat(a3), 0.055, rng.randf_range(0.075, 0.150),
					d3 * rng.randf_range(0.03, 0.08),
					rng.randf_range(0.15, 0.40), rng.randf_range(-1.6, 1.6), 0.012))
		_:
			# "leaning" — three petals standing on the plinth, tips leaning in
			for i in range(3):
				var a4: float = 2.05 + float(i) * 1.09 + rng.randf_range(-0.18, 0.18)
				var d4: Vector3 = _out(a4)
				out.append(_spec(d4 * rng.randf_range(0.36, 0.43) + Vector3(0.0, 0.015, 0.0),
					d4 * rng.randf_range(0.20, 0.28) + Vector3(0.0, rng.randf_range(1.15, 1.42), 0.0),
					_lat(a4), 0.14, rng.randf_range(0.26, 0.36),
					d4 * rng.randf_range(0.05, 0.11),
					rng.randf_range(0.35, 0.70), rng.randf_range(-0.8, 0.8), 0.016))
	return out


## Azimuth measured from the FRONT, so 0 is the standpoint the camera stands on
## and every value above keeps its panels out of that arc. -Z is the front here
## because the whole statue is turned at the end of build().
static func _out(a: float) -> Vector3:
	return Vector3(sin(a), 0.0, -cos(a))


static func _lat(a: float) -> Vector3:
	return Vector3(cos(a), 0.0, sin(a))


static func _spec(foot: Vector3, tip: Vector3, lat: Vector3, w_base: float, w_mid: float,
		bow: Vector3, curl: float, twist: float, th: float) -> Dictionary:
	return {"foot": foot, "tip": tip, "lat": lat, "w_base": w_base, "w_mid": w_mid,
		"bow": bow, "curl": curl, "twist": twist, "th": th}


## One sheet: a ruled surface bowed along its spine, curled across its width and
## twisted as it rises, given a thickness so it is a SLAB. Smooth-shaded from the
## grid's own differences — a flat-shaded petal reads as folded paper.
static func _panel(root: Node3D, mat: StandardMaterial3D, spec: Dictionary) -> void:
	var foot: Vector3 = spec["foot"]
	var tip: Vector3 = spec["tip"]
	var bow: Vector3 = spec["bow"]
	var lat0: Vector3 = spec["lat"]
	var w_base: float = float(spec["w_base"])
	var w_mid: float = float(spec["w_mid"])
	var curl: float = float(spec["curl"])
	var twist: float = float(spec["twist"])
	var th: float = float(spec["th"])
	var n_i: int = 15
	var n_j: int = 7

	var spine: Array[Vector3] = []
	for i in range(n_i):
		var t: float = float(i) / float(n_i - 1)
		spine.append(foot.lerp(tip, t) + bow * (4.0 * t * (1.0 - t)))

	var grid: Array = []
	var refs: Array[Vector3] = []
	for i in range(n_i):
		var t2: float = float(i) / float(n_i - 1)
		var tg: Vector3 = _tangent(spine, i)
		var lat_i: Vector3 = lat0 - tg * lat0.dot(tg)
		if lat_i.length_squared() < 1.0e-8:
			lat_i = tg.cross(Vector3.UP)
			if lat_i.length_squared() < 1.0e-8:
				lat_i = Vector3.RIGHT
		lat_i = lat_i.normalized().rotated(tg, twist * t2)
		var nr: Vector3 = tg.cross(lat_i).normalized()
		refs.append(nr)
		var hw: float = w_base + (w_mid - w_base) * sin(PI * clampf(t2 * 0.92 + 0.08, 0.0, 1.0))
		var row: Array[Vector3] = []
		for j in range(n_j):
			var u: float = float(j) / float(n_j - 1) * 2.0 - 1.0
			row.append(spine[i] + lat_i * (hw * u) + nr * (curl * hw * (u * u - 0.34)))
		grid.append(row)

	# normals from the grid's own differences, signed against the analytic one
	var nrm: Array = []
	for i in range(n_i):
		var rn: Array[Vector3] = []
		for j in range(n_j):
			var du: Vector3 = _at(grid, i, mini(j + 1, n_j - 1)) - _at(grid, i, maxi(j - 1, 0))
			var dv: Vector3 = _at(grid, mini(i + 1, n_i - 1), j) - _at(grid, maxi(i - 1, 0), j)
			var v: Vector3 = dv.cross(du)
			if v.length_squared() < 1.0e-12:
				v = refs[i]
			v = v.normalized()
			if v.dot(refs[i]) < 0.0:
				v = -v
			rn.append(v)
		nrm.append(rn)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := Color(1.0, 1.0, 1.0)
	var h: float = th * 0.5
	for i in range(n_i - 1):
		for j in range(n_j - 1):
			var p00: Vector3 = _at(grid, i, j)
			var p10: Vector3 = _at(grid, i + 1, j)
			var p11: Vector3 = _at(grid, i + 1, j + 1)
			var p01: Vector3 = _at(grid, i, j + 1)
			var n00: Vector3 = _at(nrm, i, j)
			var n10: Vector3 = _at(nrm, i + 1, j)
			var n11: Vector3 = _at(nrm, i + 1, j + 1)
			var n01: Vector3 = _at(nrm, i, j + 1)
			_tri_sm(st, p00 + n00 * h, n00, p10 + n10 * h, n10, p11 + n11 * h, n11, col)
			_tri_sm(st, p00 + n00 * h, n00, p11 + n11 * h, n11, p01 + n01 * h, n01, col)
			_tri_sm(st, p00 - n00 * h, -n00, p11 - n11 * h, -n11, p10 - n10 * h, -n10, col)
			_tri_sm(st, p00 - n00 * h, -n00, p01 - n01 * h, -n01, p11 - n11 * h, -n11, col)

	# the four rims, so the slab is closed and the edge catches its own highlight
	for i in range(n_i - 1):
		for s_i in range(2):
			var j2: int = 0 if s_i == 0 else n_j - 1
			var a0: Vector3 = _at(grid, i, j2)
			var b0: Vector3 = _at(grid, i + 1, j2)
			var na: Vector3 = _at(nrm, i, j2)
			var nb: Vector3 = _at(nrm, i + 1, j2)
			# away from the OPPOSITE edge — which is already correctly signed for
			# both sides, so no sgn is needed and an unused one would be a lie
			var hint: Vector3 = ((a0 + b0) * 0.5 - (_at(grid, i, n_j - 1 - j2) + _at(grid, i + 1, n_j - 1 - j2)) * 0.5).normalized()
			_tri(st, a0 + na * h, b0 + nb * h, b0 - nb * h, col, hint)
			_tri(st, a0 + na * h, b0 - nb * h, a0 - na * h, col, hint)
	for j in range(n_j - 1):
		for s_i2 in range(2):
			var i2: int = 0 if s_i2 == 0 else n_i - 1
			var a1: Vector3 = _at(grid, i2, j)
			var b1: Vector3 = _at(grid, i2, j + 1)
			var na1: Vector3 = _at(nrm, i2, j)
			var nb1: Vector3 = _at(nrm, i2, j + 1)
			var other: int = n_i - 1 - i2
			var hint2: Vector3 = ((a1 + b1) * 0.5 - (_at(grid, other, j) + _at(grid, other, j + 1)) * 0.5).normalized()
			_tri(st, a1 + na1 * h, b1 + nb1 * h, b1 - nb1 * h, col, hint2)
			_tri(st, a1 + na1 * h, b1 - nb1 * h, a1 - na1 * h, col, hint2)

	var mesh: ArrayMesh = st.commit()
	if mesh != null and mesh.get_surface_count() > 0:
		_add(root, mesh, mat)


static func _at(g: Array, i: int, j: int) -> Vector3:
	var row: Array = g[i]
	return row[j]


static func _tangent(spine: Array, i: int) -> Vector3:
	var n: int = spine.size()
	var a: Vector3 = spine[maxi(i - 1, 0)]
	var b: Vector3 = spine[mini(i + 1, n - 1)]
	var v: Vector3 = b - a
	if v.length_squared() < 1.0e-12:
		return Vector3.UP
	return v.normalized()


# ---------------------------------------------------------------------------
# emitters
#
# THE WINDING IS CHECKED, NOT GUESSED. Godot winds front faces CLOCKWISE, and
# SurfaceTool's own plane normal is (a - c) x (a - b) — the NEGATIVE of the
# textbook (b - a) x (c - a). Written the textbook way every facet on this body
# faces inward: perfectly consistent, perfectly inside out, and invisible in any
# render that draws back faces. So each triangle is handed the direction it is
# supposed to point and swaps two corners if it disagrees.

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color,
		out_hint: Vector3) -> void:
	var n: Vector3 = (a - c).cross(a - b)
	if n.length_squared() < 1.0e-16:
		return                                   # degenerate, contributes nothing
	n = n.normalized()
	var p1: Vector3 = b
	var p2: Vector3 = c
	if n.dot(out_hint) < 0.0:
		p1 = c
		p2 = b
		n = -n
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(a)
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(p1)
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(p2)


## The same, with per-vertex normals — for the sheets, which have to be smooth.
static func _tri_sm(st: SurfaceTool, a: Vector3, na: Vector3, b: Vector3, nb: Vector3,
		c: Vector3, nc: Vector3, col: Color) -> void:
	var fn: Vector3 = (a - c).cross(a - b)
	if fn.length_squared() < 1.0e-16:
		return
	var want: Vector3 = na + nb + nc
	var flip: bool = fn.normalized().dot(want) < 0.0
	st.set_color(col)
	st.set_normal(na)
	st.add_vertex(a)
	st.set_color(col)
	st.set_normal(nc if flip else nb)
	st.add_vertex(c if flip else b)
	st.set_color(col)
	st.set_normal(nb if flip else nc)
	st.add_vertex(b if flip else c)


## A closed box in an arbitrary frame: 12 triangles, every face pointing out.
static func _box(st: SurfaceTool, c: Vector3, b: Basis, half: Vector3, col: Color) -> void:
	var v: Array[Vector3] = []
	for i in range(8):
		var sx: float = -1.0 if (i & 1) == 0 else 1.0
		var sy: float = -1.0 if (i & 2) == 0 else 1.0
		var sz: float = -1.0 if (i & 4) == 0 else 1.0
		v.append(c + b * Vector3(sx * half.x, sy * half.y, sz * half.z))
	var faces: Array = [
		[0, 2, 6, 4, -1, 0, 0], [1, 5, 7, 3, 1, 0, 0],
		[0, 4, 5, 1, 0, -1, 0], [2, 3, 7, 6, 0, 1, 0],
		[0, 1, 3, 2, 0, 0, -1], [4, 5, 7, 6, 0, 0, 1],
	]
	for f_v in faces:
		var f: Array = f_v
		var hint: Vector3 = b * Vector3(float(f[4]), float(f[5]), float(f[6]))
		var q0: Vector3 = v[int(f[0])]
		var q1: Vector3 = v[int(f[1])]
		var q2: Vector3 = v[int(f[2])]
		var q3: Vector3 = v[int(f[3])]
		_tri(st, q0, q1, q2, col, hint)
		_tri(st, q0, q2, q3, col, hint)


static func _frame(n: Vector3, spin: float) -> Basis:
	var y: Vector3 = n.normalized()
	var x: Vector3 = Vector3.UP.cross(y)
	if x.length_squared() < 1.0e-8:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	var z: Vector3 = x.cross(y)
	return Basis(x, y, z).rotated(y, spin)


# ---------------------------------------------------------------------------
# materials

## A crust material: the finish comes from the shared library, but the COLOUR
## comes off the vertices, because one mesh carries every grain and the whole
## point of the reference is that the colour runs in zones across it. Emission is
## pulled back to a wash: at the library's own energy the glow is one hue over
## the entire body and the zones stop reading.
static func _crust_mat(finish: String, base: Color, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, base, rng)
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.albedo_texture = null
	m.vertex_color_use_as_albedo = true
	if m.emission_enabled:
		m.emission = base
		m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 1.1 if finish == "neon" else 0.22)
	return m


# ---------------------------------------------------------------------------
# geometry helpers and the settle — copied from the neighbouring builders on
# purpose, so one family's idea of "standing on the floor" is every family's

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
	# NOTE Basis.scaled() is diag * B (parent frame), which on a sphere cancels
	# the rotation outright. The squash has to happen in the shell's OWN frame.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _yaw_all(root: Node3D, ang: float) -> void:
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
