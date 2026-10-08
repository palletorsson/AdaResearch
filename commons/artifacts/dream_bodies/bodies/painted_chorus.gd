extends RefCounted

## dream_bodies / painted_chorus — three standing figures whose skin is the paint.
##
## Reference: C:/Users/palle/Documents/FinalMD/m1/0_0268-0000.jpg (4096x1072
## panorama). WHAT IS ACTUALLY IN THAT FILE, said plainly because the brief this
## family was commissioned from described a different picture: it is an underwater
## frieze, not a row of body-painted people. Standing seahorse-like bodies rise in
## a row out of a black ground, each sheathed in ROWS OF PASTEL PLATES — pink,
## cream, cyan, lilac — with a crested, long-eared, almost skull-like head; between
## them a lilac coral branches in marbled swirls and a yellow kelp runs in banded
## verticals. The two readings agree on everything that matters here: vertical
## standing forms in a row, a skin that is nothing but MARK, a head that is a
## SHAPE rather than a face, and a palette of pink, cyan, mint and lilac against
## dark foliage. So the family is built to the brief's ARGUMENT — the mark does not
## decorate the body, it replaces it — with the panorama's own shape language.
##
## Reproduced, and how:
##   1. The chorus — THREE figures, not one, on a single plinth, in a shallow arc
##      with the middle voice tallest and the outer two turned out, so the group
##      reads from every side of the plinth rather than only from the front. That
##      is the reference's own composition: a row, each member painted separately,
##      the row itself the subject.
##   2. The bodies — columnar and abstracted, a Giacometti stood next to a Nana:
##      a 12-link chain of squashed ellipsoids from hip to neck over two straight
##      legs and two arms hung close, with no anatomy beyond the silhouette. There
##      is nothing to see on these bodies except what the paint does to them.
##   3. The paint is GEOMETRY, not albedo. Each value of `mark` rebuilds what a
##      body segment IS — a ridge-crossed column, a stack of hard zebra bands, a
##      swollen marbled surface, a body sheathed in lifted plates, or a body cut
##      into separated discs with air between them. A painted ImageTexture rides
##      on top in world triplanar so one paint job runs unbroken across all three
##      figures, but the texture is the ECHO of the mark, never the whole of it:
##      the evidence is one still photograph, and a still cannot see a setting.
##   4. The heads are MASKS, and the mask is the one dry thing here. Every value
##      of `mask` is a chalk shell or growth standing in front of a painted
##      cranium — the paint runs over the whole head too, and the mask is what
##      stands between it and you.
##   5. A seed is an individual — the palette, the finish, each voice's height,
##      slimness, lean, turn, and every jitter in its marks.
##
## THE MATTE PASSAGE, deliberate and singular: THE MASKS. Every shell, ear, spine,
## muzzle, jaw and frond is one chalk-dry matte material at roughness 0.92, on
## bodies that are latex, patent, candy, wet, pearl, holo or oil slick. A wet body
## only reads wet next to a dry one, and putting the dry thing where the face
## should be is the argument as well as the contrast. The plinth is deliberately
## NOT matte — it is a deep-green wet slab standing in for the reference's dark
## foliage, because two matte passages would be one too many and would turn the
## chalk into a default rather than a decision.
##
## Given up: the frieze (this is three figures, not fourteen), the black ground and
## its kelp, the panorama's illustrative line work, the paint following the body's
## own contours (triplanar is a projection, not a paint job), and any face at all.
##
## AXES — two, and both cut the statue rather than its settings.
##   mark — what the paint has done to the body.
##          "labyrinth" runs meander ridges over the skin, right-angled ribbons
##          extruded along a walk on the torso's own surface · "banded" swaps the
##          column for a stack of hard zebra bands, alternate links swollen 15% and
##          in the second colour, with proud ink collars at the joins · "marbled"
##          pushes every link off-axis and lays swirling lobes over it, so the
##          silhouette undulates · "scaled" sheathes the torso in sixteen lifted
##          plates, the reference's own scale rows · "sliced" is the mark winning
##          outright: the body is cut into flat discs with visible air between
##          them, alternating in three colours, a pattern where a volume was.
##   mask — what stands where a face would be.
##          "skull" is a shell with deep sockets, dark eyes set in them, a
##          projecting muzzle and a hung jaw · "eared" is the panorama's long-eared
##          crest, two chalk tapers rising a quarter-metre · "crested" is the
##          seahorse frill, a fan of nine spines off the crown · "frond" takes the
##          shell away entirely and grows a branching chalk coral out of the neck ·
##          "blank" is the erasure: the same shell with the sockets closed, no
##          feature at all, the mark having swallowed the face.
##
## HOW THE TWO AXES STAY INDEPENDENT. Every random number a voice needs is dealt
## into a fixed-length pool BEFORE either axis is read, and the textures are
## painted from a second generator derived from the seed. So mark and mask cannot
## shift the rng stream between them: seed 7 at mark=sliced is the same three
## individuals as seed 7 at mark=banded, wearing a different paint. Without that,
## a sweep comparing two values of one axis would also be comparing two different
## statues, and every number the critic reported would be measuring the wrong
## thing at the right time.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const TEX: int = 128
const PLINTH_TOP: float = 0.055
const VOICES: int = 3
const N_TORSO: int = 11
const POOL: int = 96

## THE COLUMN LINKS HAVE TO OVERLAP, and by more than looks safe on paper. At 11
## links over 0.60 m the pitch is 60 mm, and the first cut of this family used a
## half-height of 52 mm — under the pitch, so every link stood clear of its
## neighbour and the torso photographed as a stack of loose rings. Nothing in the
## probe can see that: the mesh count, the triangle count, the footing and the
## seed response were all correct, and only the render said the body was beads.
## 86 mm is 1.43x the pitch, which reads as one poured column.
const SEG_RY: float = 0.086
## The one value that WANTS the gap. 20 mm on a 60 mm pitch leaves 40 mm of
## daylight between every disc, which is the whole argument of "sliced".
const SEG_RY_CUT: float = 0.020

## The body may be poured in anything glossy. Never "matte" (that is the mask's,
## and only the mask's) and never "neon" or "chrome" under a pattern — a lit tube
## drowns the paint and a mirror photographs black.
const BODY_FIN: Array[String] = ["latex", "patent", "candy", "wet", "pearl", "holo", "oilslick"]

## The panorama's palette, by name in DreamSkin.QUEER: pink, cyan, mint, lilac.
const HUES: Array[String] = ["hot_pink", "cyan", "mint", "lilac", "violet", "magenta",
	"acid", "lemon", "tangerine"]

const CHALK: Color = Color(0.914, 0.894, 0.839)
const FOLIAGE: Color = Color(0.055, 0.145, 0.098)

# the column, hip to neck — one set of keys, used by the chain, the ridges, the
# plates and the lobes, so a change to the silhouette moves every mark with it
const Y_LO: float = 0.700
const Y_HI: float = 1.300
const RX_KEYS: Array = [0.150, 0.134, 0.116, 0.126, 0.148, 0.152, 0.070]
const RZ_KEYS: Array = [0.114, 0.102, 0.088, 0.094, 0.104, 0.106, 0.062]
const ZO_KEYS: Array = [0.014, 0.004, -0.010, -0.006, 0.004, 0.010, 0.006]


static func describe() -> String:
	return "Three standing figures on one plinth whose skin is nothing but paint — meander ridges, zebra bands, marbled swirl, lifted plates or sliced discs — each carrying a dry chalk mask where a face would be."


static func axes() -> Dictionary:
	return {
		"mark": ["labyrinth", "banded", "marbled", "scaled", "sliced"],
		"mask": ["skull", "eared", "crested", "frond", "blank"],
	}


## The prediction, named BEFORE the capture, as data so the promote tool can carry
## it into the registry. It is a LOWER bound: a hand estimate has one light, no
## shadow and no antialiasing, and the corpus has it under-predicting a real render
## by 1.5x to 7x. A number that comes back BELOW this one means stop and look.
static func predicted() -> Dictionary:
	return {
		"pair": "mask: skull vs blank (any mark)",
		"predicted_pct": 1.25,
		"reasoning": ("skull and blank are the SAME chalk shell at the same size on the same "
			+ "painted cranium; only three things differ and all three are small. Per head: "
			+ "two dark eyes of 0.038 x 0.032 m in sockets the shell already carries "
			+ "(3.0e-3 m2 with their shading), a muzzle 0.085 m long and 0.042 m across "
			+ "(3.6e-3 m2), a jaw 0.064 x 0.032 m (2.1e-3 m2) = 8.6e-3 m2 — and there are "
			+ "three heads, so 2.6e-2 m2 changes. The chorus silhouette is three figures "
			+ "about 1.45 m tall and 0.19 m mean width at roughly 0.75 fill, so 0.62 m2. "
			+ "That is 4.2% of the BODY — and the body is about 30% of the frame at "
			+ "framing 0.62, so 4.2% x 0.30 = 1.25% of the PICTURE. Mind the denominator: "
			+ "fetish_idol quoted a silhouette share as a frame share and was 2.2x out on a "
			+ "render that was fine. Only the muzzle and jaw reach the silhouette; the eyes "
			+ "are a value change inside it, which a difference metric counts and a "
			+ "silhouette metric would not. The `mark` axis has no pair anywhere near this "
			+ "tight — its closest is labyrinth vs marbled, both relief over the whole "
			+ "column, and even that repaints 100% of the skin and re-cuts every link, so "
			+ "read the per-pair rows and never the headline peak."),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var mark: String = str(opts.get("mark", "labyrinth"))
	var mask: String = str(opts.get("mask", "skull"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the wardrobe, dealt once for the whole chorus -----------------------
	var finish: String = BODY_FIN[rng.randi_range(0, BODY_FIN.size() - 1)]
	var pal: Array[Color] = []
	var used: Array[String] = []
	while pal.size() < 4:
		var key: String = HUES[rng.randi_range(0, HUES.size() - 1)]
		if used.has(key) and used.size() < HUES.size():
			continue
		used.append(key)
		var c: Color = Gloss.QUEER[key]
		pal.append(c)
	var ink: Color = Color(0.055, 0.048, 0.068)

	# THE MATTE PASSAGE — the only dry thing on the plinth, and it is the faces.
	# Cull disabled because a mask is a SHELL: from behind the chorus you look into
	# the back of it, which is what a mask is, and a culled shell would leave a
	# hole where the head is.
	var mat_chalk: StandardMaterial3D = Gloss.skin("matte", CHALK)
	mat_chalk.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_ink: StandardMaterial3D = Gloss.skin("patent", ink, rng)
	# NOT matte, on purpose: a second dry passage would make the chalk a default
	# instead of a decision. Deep green, standing in for the reference's foliage.
	var mat_plinth: StandardMaterial3D = Gloss.skin("wet", FOLIAGE, rng)

	# --- one shell and one plate for the whole chorus ------------------------
	# Both are shared Mesh resources instanced three times: the probe counts
	# triangles per INSTANCE, so sharing costs nothing in the measurement and
	# saves two SurfaceTool builds per statue.
	var shell: ArrayMesh = null
	if mask != "frond":
		var sock: float = 0.0
		if mask == "skull":
			sock = 0.032
		elif mask != "blank":
			sock = 0.014
		shell = _mask_shell(sock)
	var plate: ArrayMesh = null
	if mark == "scaled":
		plate = _plate_mesh()

	# --- the three voices ----------------------------------------------------
	var x_slot: Array = [-0.335, 0.005, 0.340]
	var z_slot: Array = [0.052, -0.062, 0.044]
	var h_slot: Array = [0.945, 1.060, 0.905]
	var yaw_slot: Array = [-16.0, 6.0, 20.0]
	for v in range(VOICES):
		# every random this voice will ever need, drawn BEFORE either axis is
		# read — see the header note on independence
		var pool: Array[float] = []
		for i in range(POOL):
			pool.append(rng.randf())
		var slim: float = lerpf(0.90, 1.10, pool[0])
		var hue_a: Color = pal[v % pal.size()]
		var hue_b: Color = pal[(v + 1 + int(pool[1] * 2.0)) % pal.size()]
		var trio: Array[Color] = [hue_a, hue_b, pal[(v + 2) % pal.size()]]

		var trng := RandomNumberGenerator.new()
		trng.seed = seed * 7919 + v * 131 + 17
		var tex: ImageTexture = _paint_mark(mark, trng, trio, ink)
		var mat_body: StandardMaterial3D = _dress(finish, hue_a, tex, rng)
		var mat_band: StandardMaterial3D = _dress(finish, hue_b, tex, rng)
		var mat_plate: StandardMaterial3D = _dress(finish, hue_b, tex, rng)
		mat_plate.cull_mode = BaseMaterial3D.CULL_DISABLED

		var mats := {
			"body": mat_body,
			"band": mat_band,
			"plate": mat_plate,
			"ink": mat_ink,
			"chalk": mat_chalk,
		}
		var i0: int = root.get_child_count()
		_voice(root, mark, mask, mats, shell, plate, pool, slim)
		var k: float = lerpf(0.96, 1.05, pool[2]) * float(h_slot[v])
		var yaw: float = deg_to_rad(float(yaw_slot[v]) + lerpf(-7.0, 7.0, pool[3]))
		var tilt: float = deg_to_rad(lerpf(-3.0, 3.0, pool[4]))
		var tf := Transform3D(
			Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, tilt) * _diag(Vector3(k, k, k)),
			Vector3(float(x_slot[v]) + lerpf(-0.018, 0.018, pool[5]), 0.0,
				float(z_slot[v]) + lerpf(-0.020, 0.020, pool[6])))
		_xform_range(root, i0, tf)

	# --- stature, then the measured settle -----------------------------------
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
# one voice — a whole figure, built into root in its own upright frame

static func _voice(root: Node3D, mark: String, mask: String, mats: Dictionary,
		shell: ArrayMesh, plate: ArrayMesh, pool: Array[float], slim: float) -> void:
	var mat_body: StandardMaterial3D = mats["body"]
	var mat_band: StandardMaterial3D = mats["band"]
	var mat_plate: StandardMaterial3D = mats["plate"]
	var mat_ink: StandardMaterial3D = mats["ink"]
	var mat_chalk: StandardMaterial3D = mats["chalk"]

	# --- the column ----------------------------------------------------------
	var t_c: Array[Vector3] = []
	var t_rx: Array[float] = []
	var t_rz: Array[float] = []
	for i in range(N_TORSO):
		var t: float = float(i) / float(N_TORSO - 1)
		t_rx.append(_key(RX_KEYS, t) * slim)
		t_rz.append(_key(RZ_KEYS, t) * slim)
		t_c.append(Vector3(0.0, lerpf(Y_LO, Y_HI, t), _key(ZO_KEYS, t)))

	var seg_ry: float = SEG_RY_CUT if mark == "sliced" else SEG_RY
	for i in range(N_TORSO):
		_part(root, mark, i, mat_body, mat_band, t_c[i],
			Vector3(t_rx[i], seg_ry, t_rz[i]), pool, 8 + i)

	# --- legs, arms, the blocks that make a shoulder a shoulder ---------------
	#
	# A LIMB IS A TAPERED ROD, NOT A CHAIN OF SPHERES. The first cut hung four
	# sphere links on a 0.35 m thigh — a 0.116 m pitch under a 0.06 m radius — and
	# photographed as beads on an invisible string. Making the chain dense enough
	# to close costs about eight links a limb, which is 96 meshes a voice and puts
	# the loudest axis pair over the 260-mesh budget. One rod closes it exactly,
	# for one mesh, and the joint sphere at each end fills the notch where two rods
	# meet at an angle. The mark still reaches the limbs: see _limb.
	var lr: float = 0.062 * slim
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var hip_p := Vector3(sd * lr, 0.716, 0.006)
		var knee := Vector3(sd * (lr + 0.008), 0.372, 0.012)
		var ankle := Vector3(sd * (lr + 0.010), 0.066, -0.004)
		_limb(root, mark, mat_body, mat_band, hip_p, knee, 0.074 * slim, 0.054, pool, 24 + s_i * 4)
		_limb(root, mark, mat_body, mat_band, knee, ankle, 0.054, 0.044, pool, 26 + s_i * 4)
		_part(root, mark, s_i, mat_body, mat_band, knee, Vector3(0.056, 0.056, 0.056), pool, 32 + s_i)
		_part(root, mark, s_i + 1, mat_body, mat_band, ankle, Vector3(0.046, 0.046, 0.046), pool, 34 + s_i)
		_part(root, mark, s_i, mat_body, mat_band,
			Vector3(sd * (lr + 0.010), 0.034, -0.048), Vector3(0.054, 0.034, 0.090),
			pool, 36 + s_i)

		# the arm hangs OUTSIDE the shoulder bar, not through it
		var sh := Vector3(sd * 0.168 * slim, 1.178, 0.0)
		var elb := Vector3(sd * (0.178 * slim), 0.942, 0.016)
		var wr := Vector3(sd * (0.168 * slim), 0.712, -0.020)
		_limb(root, mark, mat_body, mat_band, sh, elb, 0.056 * slim, 0.043, pool, 40 + s_i * 4)
		_limb(root, mark, mat_body, mat_band, elb, wr, 0.043, 0.034, pool, 42 + s_i * 4)
		_part(root, mark, s_i, mat_body, mat_band, sh, Vector3(0.058, 0.058, 0.058), pool, 48 + s_i)
		_part(root, mark, s_i + 1, mat_body, mat_band, elb, Vector3(0.045, 0.045, 0.045), pool, 50 + s_i)
		_part(root, mark, s_i, mat_body, mat_band, wr, Vector3(0.036, 0.036, 0.036), pool, 52 + s_i)

	_part(root, mark, 1, mat_body, mat_band, Vector3(0.0, 0.732, 0.006),
		Vector3(0.152 * slim, 0.090, 0.112 * slim), pool, 60)
	_part(root, mark, 0, mat_body, mat_band, Vector3(0.0, 1.180, 0.0),
		Vector3(0.150 * slim, 0.068, 0.094 * slim), pool, 61)
	_ellipsoid(root, mat_body, Vector3(0.0, 1.286, -0.006), Vector3(0.046, 0.062, 0.046), Basis())
	# THE CRANIUM IS PAINTED, like the rest — the mark runs over the head too — and
	# it is smaller than the mask that stands in front of it, but only by about
	# 16 mm. Both ends of that gap were measured on a render: at 6 mm the mask read
	# as a pale smear on the side of a pink ball, and at 30 mm the shell's rim
	# cleared the skull entirely and hung in the air beside the head like a dropped
	# plate. 16 mm is a mask WORN.
	var head_c := Vector3(0.0, 1.368, -0.010)
	_ellipsoid(root, mat_body, head_c, Vector3(0.082, 0.094, 0.080), Basis())

	# --- the mark's own geometry ---------------------------------------------
	if mark == "labyrinth":
		# A DRAWN LINE, NOT TAPE. The first cut ran these 32 mm wide and 14 mm proud
		# on a torso 150 mm across — a fifth of the body's width per ridge, eleven of
		# them — and the render was a black tangle with no labyrinth legible in it.
		# 18 mm wide and 8 mm proud reads as a line that was PAINTED on.
		for r_i in range(11):
			var path: Array = _meander(pool, 2 + r_i * 5, t_c, t_rx, t_rz)
			_ribbon(root, mat_ink, path[0], path[1], 0.009, 0.008, 0.005)
	elif mark == "banded":
		# the ink collar at each swap, so the zebra edge is hard rather than a
		# gradient between two glosses
		for c_i in range(5):
			var idx: int = 1 + c_i * 2
			_collar(root, mat_ink, t_c[idx], t_rx[idx] * 1.20, t_rz[idx] * 1.20, 0.011)
	elif mark == "marbled":
		for l_i in range(10):
			var iu: float = lerpf(0.6, float(N_TORSO) - 1.6, _p(pool, 12 + l_i * 3))
			var ang: float = _p(pool, 13 + l_i * 3) * TAU
			var sp: Array = _surf(t_c, t_rx, t_rz, iu, ang)
			var pp: Vector3 = sp[0]
			var nn: Vector3 = sp[1]
			var spin: float = lerpf(-1.1, 1.1, _p(pool, 14 + l_i * 3))
			var b: Basis = _basis_y_to(nn) * Basis(Vector3.UP, spin)
			_ellipsoid(root, mat_band, pp + nn * 0.012, Vector3(0.058, 0.028, 0.030), b)
	elif mark == "scaled" and plate != null:
		for p_i in range(14):
			var iu2: float = lerpf(0.4, float(N_TORSO) - 1.4, float(p_i % 7) / 6.0)
			var ang2: float = (float(p_i) * 2.399963) + _p(pool, 16 + p_i) * 0.5
			var sp2: Array = _surf(t_c, t_rx, t_rz, iu2, ang2)
			var pp2: Vector3 = sp2[0]
			var nn2: Vector3 = sp2[1]
			var sc: float = lerpf(0.072, 0.104, _p(pool, 32 + p_i))
			var pb: Basis = _basis_y_to(nn2) * Basis(Vector3.RIGHT, -PI * 0.5)
			var mi: MeshInstance3D = _add(root, plate, mat_plate)
			mi.transform = Transform3D(pb * _diag(Vector3(sc, sc, sc)), pp2 - nn2 * 0.012)

	# --- the mask ------------------------------------------------------------
	if mask == "frond":
		_frond(root, mat_chalk, head_c + Vector3(0.0, 0.056, -0.010), pool)
	else:
		var mi2: MeshInstance3D = _add(root, shell, mat_chalk)
		mi2.transform = Transform3D(Basis(), head_c + Vector3(0.0, 0.004, -0.016))
		if mask == "skull":
			# the dark eyes sit IN the hollows the shell already carries — the
			# socket floor at this depth is z = -0.0745 off the head centre, so
			# -0.062 puts the eye just proud of it and it reads as a filled socket
			for e_i in range(2):
				var sd2: float = -1.0 if e_i == 0 else 1.0
				_ellipsoid(root, mat_ink, head_c + Vector3(sd2 * 0.049, 0.017, -0.062),
					Vector3(0.019, 0.016, 0.014), Basis())
			# the muzzle, projecting: the one part of "skull" that reaches the
			# silhouette, and most of the 1.0% the prediction is spending
			_rod(root, mat_chalk, head_c + Vector3(0.0, -0.026, -0.062),
				head_c + Vector3(0.0, -0.044, -0.145), 0.027, 0.015)
			_ellipsoid(root, mat_chalk, head_c + Vector3(0.0, -0.072, -0.096),
				Vector3(0.032, 0.016, 0.042), Basis(Vector3.RIGHT, 0.22))
		elif mask == "eared":
			for e_i in range(2):
				var sd3: float = -1.0 if e_i == 0 else 1.0
				var base: Vector3 = head_c + Vector3(sd3 * 0.050, 0.086, -0.014)
				var tip: Vector3 = base + Vector3(sd3 * lerpf(0.035, 0.085, _p(pool, 70 + e_i)),
					lerpf(0.200, 0.255, _p(pool, 72 + e_i)), -0.030)
				_rod(root, mat_chalk, base, tip, 0.032, 0.007)
		elif mask == "crested":
			for s_i2 in range(9):
				var u: float = float(s_i2) / 8.0
				var ang3: float = lerpf(-1.15, 1.15, u)
				var base2: Vector3 = head_c + Vector3(sin(ang3) * 0.058, 0.092,
					-0.024 - cos(ang3) * 0.032)
				var ln: float = lerpf(0.090, 0.175, sin(u * PI)) * lerpf(0.85, 1.15, _p(pool, 74 + s_i2))
				var tip2: Vector3 = base2 + Vector3(sin(ang3) * ln * 0.55, ln,
					-cos(ang3) * ln * 0.30 - 0.010)
				_rod(root, mat_chalk, base2, tip2, 0.012, 0.003)


# ---------------------------------------------------------------------------
# the mark axis — what one link of a body IS

static func _part(root: Node3D, mark: String, idx: int, ma: StandardMaterial3D,
		mb: StandardMaterial3D, c: Vector3, r: Vector3, pool: Array[float], po: int) -> void:
	if mark == "banded":
		var odd: bool = (idx % 2) == 1
		var k: float = 1.16 if odd else 0.95
		_ellipsoid(root, mb if odd else ma, c, Vector3(r.x * k, r.y, r.z * k), Basis())
		return
	if mark == "sliced":
		_disc(root, mb if (idx % 3) == 1 else ma, c, Vector3(r.x * 1.05, r.y, r.z * 1.05))
		return
	if mark == "marbled":
		var a: float = _p(pool, po) * TAU
		var push: float = lerpf(0.10, 0.32, _p(pool, po + 1))
		var off := Vector3(sin(a) * r.x * push, 0.0, cos(a) * r.z * push)
		_ellipsoid(root, ma, c + off, Vector3(r.x * 1.04, r.y * 1.12, r.z * 1.04),
			Basis(Vector3.UP, a * 0.35))
		return
	_ellipsoid(root, ma, c, r, Basis())


## One limb segment. Solid by default — a single tapered rod, which is the only
## shape that closes a 0.35 m span for one mesh — and dressed by the two values of
## `mark` that have something to say about a limb. If the mark stopped at the
## torso the axis would die at the hip, and half of every silhouette would be
## carrying no argument at all.
static func _limb(root: Node3D, mark: String, ma: StandardMaterial3D, mb: StandardMaterial3D,
		a: Vector3, b: Vector3, r0: float, r1: float, pool: Array[float], po: int) -> void:
	if mark == "sliced":
		for i in range(4):
			var t: float = float(i) / 3.0
			var p: Vector3 = a.lerp(b, t)
			var r: float = lerpf(r0, r1, t)
			var d: MeshInstance3D = _add(root, _disc_mesh(),
				mb if (i % 3) == 1 else ma)
			d.transform = Transform3D(_basis_y_to(b - a) * _diag(Vector3(r * 1.10, 0.017, r * 1.10)), p)
		return
	_rod(root, ma, a, b, r0, r1)
	if mark == "banded":
		for i in range(2):
			var t2: float = lerpf(0.30, 0.72, float(i))
			var p2: Vector3 = a.lerp(b, t2)
			var r2: float = lerpf(r0, r1, t2)
			_ellipsoid(root, mb, p2, Vector3(r2 * 1.26, r2 * 0.40, r2 * 1.26),
				_basis_y_to(b - a))


# ---------------------------------------------------------------------------
# the mask axis — the chalk

## The shell: a front half-ellipsoid with a brow ridge and two socket hollows,
## built as a grid and wound outward from a point inside the cranium. `sock` is
## the ONLY thing that changes between skull, eared/crested and blank, which is
## why the prediction above can name the difference so exactly.
static func _mask_shell(sock: float) -> ArrayMesh:
	var nu: int = 16
	var nv: int = 13
	var rx: float = 0.098
	var ry: float = 0.116
	var rz: float = 0.098
	var grid: Array = []
	for j in range(nv + 1):
		var row: Array[Vector3] = []
		var vv: float = float(j) / float(nv)
		var th: float = lerpf(0.10, 0.97, vv) * PI
		for i in range(nu + 1):
			var uu: float = float(i) / float(nu)
			var ph: float = lerpf(-1.32, 1.32, uu)
			var p := Vector3(rx * sin(th) * sin(ph), ry * cos(th), -rz * sin(th) * cos(ph))
			# +Z is INTO the head: the face looks down -Z, so a brow pushes -Z out
			# and a socket pushes +Z in
			var brow: float = exp(-pow((vv - 0.28) / 0.10, 2.0))
			p.z -= 0.011 * brow
			var du: float = uu - 0.5
			for s_i in range(2):
				var sd: float = -1.0 if s_i == 0 else 1.0
				var dd: float = pow((du - sd * 0.19) / 0.110, 2.0) + pow((vv - 0.42) / 0.115, 2.0)
				p.z += sock * exp(-dd)
			row.append(p)
		grid.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var inside := Vector3(0.0, 0.0, 0.055)
	for j in range(nv):
		var r0: Array = grid[j]
		var r1: Array = grid[j + 1]
		for i in range(nu):
			_quad_out(st, r0[i], r0[i + 1], r1[i + 1], r1[i], inside)
	st.generate_normals()
	return st.commit()


## The head as vegetation: a branching chalk coral out of the neck, straight off
## the panorama's lilac fronds. Ten rods and four tips, so the count matches the
## other mask values closely enough that the axis is a shape change and not a
## budget change.
static func _frond(root: Node3D, mat: StandardMaterial3D, base: Vector3, pool: Array[float]) -> void:
	var top: Vector3 = base + Vector3(0.0, 0.088, -0.006)
	_rod(root, mat, base, top, 0.030, 0.020)
	for b_i in range(3):
		var a: float = TAU * float(b_i) / 3.0 + _p(pool, 80) * 1.4
		var out: float = lerpf(0.052, 0.086, _p(pool, 81 + b_i))
		var mid: Vector3 = top + Vector3(sin(a) * out, lerpf(0.070, 0.110, _p(pool, 84 + b_i)),
			cos(a) * out)
		_rod(root, mat, top, mid, 0.019, 0.013)
		for c_i in range(2):
			var a2: float = a + (0.7 if c_i == 0 else -0.7)
			var out2: float = lerpf(0.038, 0.064, _p(pool, 87 + b_i * 2 + c_i))
			var tip: Vector3 = mid + Vector3(sin(a2) * out2,
				lerpf(0.052, 0.090, _p(pool, 90 + b_i)), cos(a2) * out2)
			_rod(root, mat, mid, tip, 0.012, 0.007)
			if b_i == 0:
				_ellipsoid(root, mat, tip + Vector3(0.0, 0.008, 0.0),
					Vector3(0.015, 0.018, 0.015), Basis())
	_ellipsoid(root, mat, top + Vector3(0.0, 0.008, 0.0), Vector3(0.028, 0.022, 0.028), Basis())
	_ellipsoid(root, mat, base + Vector3(0.0, 0.010, 0.0), Vector3(0.036, 0.026, 0.034), Basis())


# ---------------------------------------------------------------------------
# the labyrinth: a right-angled walk on the column's own surface, extruded

## Where the surface is at (segment index, angle round it), plus the true outward
## normal of the ellipse — not the sphere normal, which on a 0.15 x 0.09 section
## would lay every ridge crooked.
static func _surf(t_c: Array[Vector3], t_rx: Array[float], t_rz: Array[float],
		iu: float, a: float) -> Array:
	var n: int = t_c.size()
	var ic: float = clampf(iu, 0.0, float(n - 1))
	var i0: int = int(floor(ic))
	var i1: int = mini(i0 + 1, n - 1)
	var f: float = ic - float(i0)
	var c: Vector3 = t_c[i0].lerp(t_c[i1], f)
	var rx: float = lerpf(t_rx[i0], t_rx[i1], f)
	var rz: float = lerpf(t_rz[i0], t_rz[i1], f)
	var p: Vector3 = c + Vector3(rx * sin(a), 0.0, rz * cos(a))
	var nv: Vector3 = Vector3(sin(a) / maxf(rx, 0.001), 0.0, cos(a) / maxf(rz, 0.001)).normalized()
	return [p, nv]


## One meander: alternate a move AROUND the body with a move UP it, turning at
## right angles, which is what makes it read as a labyrinth rather than a scribble.
static func _meander(pool: Array[float], base: int, t_c: Array[Vector3],
		t_rx: Array[float], t_rz: Array[float]) -> Array:
	var n: int = t_c.size()
	var iu: float = lerpf(0.8, float(n) - 2.2, _p(pool, base))
	var a: float = _p(pool, base + 1) * TAU
	var da: float = 0.62 * (1.0 if _p(pool, base + 2) < 0.5 else -1.0)
	var di: float = lerpf(1.3, 2.1, _p(pool, base + 3))
	var pts: Array[Vector3] = []
	var nrms: Array[Vector3] = []
	var sp0: Array = _surf(t_c, t_rx, t_rz, iu, a)
	pts.append(sp0[0])
	nrms.append(sp0[1])
	for step in range(6):
		var horiz: bool = (step % 2) == 0
		var subs: int = 4 if horiz else 2
		for s in range(subs):
			var u: float = float(s + 1) / float(subs)
			var ii: float = iu
			var aa: float = a
			if horiz:
				aa = a + da * u
			else:
				ii = iu + di * u
			var sp: Array = _surf(t_c, t_rx, t_rz, ii, aa)
			pts.append(sp[0])
			nrms.append(sp[1])
		if horiz:
			a += da
		else:
			iu = clampf(iu + di, 0.4, float(n) - 1.4)
			# the turn: the next run round the body goes the other way, which is
			# the meander's whole grammar
			da = -da * lerpf(0.72, 1.18, _p(pool, base + 4))
	return [pts, nrms]


## Extrude a rectangular ribbon along a polyline that lies on the body, lifted off
## the surface so it reads as a ridge rather than a decal.
static func _ribbon(root: Node3D, mat: StandardMaterial3D, pts_v: Array, nrms_v: Array,
		w: float, th: float, lift: float) -> void:
	var pts: Array = pts_v
	var nrms: Array = nrms_v
	var n: int = pts.size()
	if n < 3:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var rings: Array = []
	var axis: Array[Vector3] = []
	for i in range(n):
		var p: Vector3 = pts[i]
		var nv: Vector3 = (nrms[i] as Vector3).normalized()
		var tg: Vector3
		if i == 0:
			tg = (pts[1] as Vector3) - p
		elif i == n - 1:
			tg = p - (pts[n - 2] as Vector3)
		else:
			tg = (pts[i + 1] as Vector3) - (pts[i - 1] as Vector3)
		if tg.length() < 0.000001:
			tg = Vector3.UP
		tg = tg.normalized()
		var side: Vector3 = tg.cross(nv)
		if side.length() < 0.000001:
			side = tg.cross(Vector3.UP)
		side = side.normalized()
		var nn: Vector3 = side.cross(tg).normalized()
		if nn.dot(nv) < 0.0:
			nn = -nn
		var b: Vector3 = p + nn * lift
		axis.append(b + nn * th * 0.5)
		rings.append([b - side * w, b + side * w, b + side * w + nn * th, b - side * w + nn * th])
	for i in range(n - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var mid: Vector3 = (axis[i] + axis[i + 1]) * 0.5
		for k in range(4):
			var k2: int = (k + 1) % 4
			_quad_out(st, r0[k], r0[k2], r1[k2], r1[k], mid)
	var c0: Array = rings[0]
	_quad_out(st, c0[0], c0[1], c0[2], c0[3], axis[1])
	var c1: Array = rings[n - 1]
	_quad_out(st, c1[0], c1[1], c1[2], c1[3], axis[n - 2])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh != null:
		_add(root, mesh, mat)


## One scale: a petal-shaped tab, widest at its hinge, cupped and lifted at the
## tip. Built once and instanced sixteen times per voice.
static func _plate_mesh() -> ArrayMesh:
	var nu: int = 8
	var nv: int = 5
	var grid: Array = []
	for j in range(nv + 1):
		var row: Array[Vector3] = []
		var vv: float = float(j) / float(nv)
		var hw: float = 0.5 * pow(sin(PI * (0.5 + 0.5 * vv)), 0.55)
		var z: float = 0.06 + 0.42 * vv * vv
		for i in range(nu + 1):
			var uu: float = float(i) / float(nu) * 2.0 - 1.0
			row.append(Vector3(uu * hw, vv, z + 0.14 * (1.0 - uu * uu)))
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	# the hinge sits against the body, so "inside" is behind the plate
	var inside := Vector3(0.0, 0.4, -0.6)
	for j in range(nv):
		var r0: Array = grid[j]
		var r1: Array = grid[j + 1]
		for i in range(nu):
			_quad_out(st, r0[i], r0[i + 1], r1[i + 1], r1[i], inside)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# painted skins — every pixel drawn in code, from a generator of its own so the
# texture cannot shift the figure's rng stream between axis values

static func _paint_mark(mark: String, r: RandomNumberGenerator, trio: Array[Color],
		ink: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	if mark == "banded":
		_paint_bands(img, r, trio, ink)
	elif mark == "marbled":
		_paint_marble(img, r, trio)
	elif mark == "scaled":
		_paint_scales(img, r, trio, ink)
	elif mark == "sliced":
		_paint_blocks(img, r, trio, ink)
	else:
		_paint_maze(img, r, trio, ink)
	return ImageTexture.create_from_image(img)


static func _put(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _bar(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			_put(img, x, y, c)


## A meander: nested open rectangles, the gap turned by cell, over a pale ground.
static func _paint_maze(img: Image, r: RandomNumberGenerator, trio: Array[Color], ink: Color) -> void:
	var ground: Color = Color(0.955, 0.945, 0.925).lerp(trio[0], 0.30)
	_bar(img, 0, 0, TEX, TEX, ground)
	var s: int = 32
	var cells: int = TEX / s
	var th: int = 3
	var gap: int = 6
	for cy in range(cells):
		for cx in range(cells):
			var ox: int = cx * s
			var oy: int = cy * s
			var side: int = r.randi_range(0, 3)
			var rings: int = r.randi_range(2, 3)
			var c: Color = ink if r.randf() < 0.78 else trio[2]
			for j in range(rings):
				var d: int = 2 + j * (th + gap)
				var e: int = s - 2 - d - th
				if e - d < th * 2:
					break
				# three sides of a square plus a stub — the open corner is what
				# makes a meander a meander rather than a set of frames
				_bar(img, ox + d, oy + d, ox + e + th, oy + d + th, c)
				if side != 1:
					_bar(img, ox + d, oy + d, ox + d + th, oy + e + th, c)
				if side != 2:
					_bar(img, ox + e, oy + d, ox + e + th, oy + e + th, c)
				if side != 3:
					_bar(img, ox + d, oy + e, ox + e + th, oy + e + th, c)


## Zebra: hard vertical bands with a wobble, each edged in ink.
static func _paint_bands(img: Image, r: RandomNumberGenerator, trio: Array[Color], ink: Color) -> void:
	var bands: int = r.randi_range(6, 10)
	var band_c: Array[Color] = []
	for i in range(bands):
		if r.randf() < 0.40:
			band_c.append(Color(0.962, 0.952, 0.930))
		else:
			band_c.append(trio[r.randi_range(0, trio.size() - 1)])
	var bw: float = float(TEX) / float(bands)
	var amp: float = r.randf_range(3.0, 12.0)
	var freq: float = float(r.randi_range(1, 3)) * TAU / float(TEX)
	for y in range(TEX):
		var wob: float = amp * sin(float(y) * freq)
		for x in range(TEX):
			var u: float = float(x) + wob
			var q: float = u / bw
			var bi: int = posmod(int(floor(q)), bands)
			var frac: float = q - floor(q)
			var c: Color = band_c[bi]
			if frac < 0.055 or frac > 0.945:
				c = ink
			img.set_pixel(x, y, c)


## Marbling: a domain-warped sweep through three hues with pale veins at every
## boundary. Integer frequencies only, because triplanar wraps this round a limb
## and a visible seam reads as a crack.
static func _paint_marble(img: Image, r: RandomNumberGenerator, trio: Array[Color]) -> void:
	var f1: float = float(r.randi_range(2, 4))
	var f2: float = float(r.randi_range(1, 3))
	var amp: float = r.randf_range(0.7, 1.7)
	var ph: float = r.randf() * TAU
	var vein: Color = Color(0.965, 0.955, 0.940)
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var wx: float = sin(u * TAU * 2.0 + ph) * amp + sin(v * TAU * 3.0 + ph * 0.5) * amp * 0.7
			var t: float = 0.5 + 0.5 * sin(u * TAU * f1 + v * TAU * f2 + wx)
			var k: float = t * 3.0
			var i0: int = int(floor(k)) % 3
			var i1: int = (i0 + 1) % 3
			var kk: float = k - floor(k)
			var c: Color = trio[i0].lerp(trio[i1], smoothstep(0.0, 1.0, kk))
			if kk < 0.045 or kk > 0.955:
				c = vein
			img.set_pixel(x, y, c)


## Scale rows: offset ranks of scallops, each outlined, each rank a shade apart.
static func _paint_scales(img: Image, r: RandomNumberGenerator, trio: Array[Color], ink: Color) -> void:
	var rows: int = r.randi_range(8, 12)
	var cols: int = r.randi_range(7, 10)
	for y in range(TEX):
		var ry: float = float(y) / float(TEX) * float(rows)
		var jr: int = int(floor(ry))
		var fy: float = ry - float(jr)
		var off: float = 0.5 if (jr % 2) == 1 else 0.0
		for x in range(TEX):
			var rx: float = float(x) / float(TEX) * float(cols) + off
			var jc: int = int(floor(rx))
			var fx: float = rx - float(jc)
			var dx: float = (fx - 0.5) * 2.0
			var d: float = sqrt(dx * dx * 0.86 + pow((fy - 0.10) * 1.75, 2.0))
			var c: Color = trio[posmod(jr * 3 + jc, trio.size())]
			var shade: float = lerpf(1.14, 0.80, clampf(d, 0.0, 1.0))
			c = Color(clampf(c.r * shade, 0.0, 1.0), clampf(c.g * shade, 0.0, 1.0),
				clampf(c.b * shade, 0.0, 1.0))
			if d > 0.93 and d < 1.05:
				c = ink
			img.set_pixel(x, y, c)


## Flat blocks: the pattern that has stopped pretending to be a surface at all.
static func _paint_blocks(img: Image, r: RandomNumberGenerator, trio: Array[Color], ink: Color) -> void:
	var n: int = r.randi_range(7, 12)
	var pick: Array[int] = []
	for i in range(n):
		pick.append(r.randi_range(0, trio.size() - 1))
	var bh: float = float(TEX) / float(n)
	for y in range(TEX):
		var q: float = float(y) / bh
		var bi: int = posmod(int(floor(q)), n)
		var frac: float = q - floor(q)
		var c: Color = trio[pick[bi]]
		if frac < 0.06:
			c = ink
		for x in range(TEX):
			img.set_pixel(x, y, c)


# ---------------------------------------------------------------------------
# materials

## A painted body: a DreamSkin finish carrying the code-drawn pattern as albedo in
## world triplanar, so one paint job runs unbroken across every primitive and
## across all three figures. Metallic and emission are capped for the reason the
## corpus already recorded — a mirror photographs black, and paint under a strong
## emission stops reading as paint.
static func _dress(finish: String, ground: Color, tex: ImageTexture,
		rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, ground, rng)
	m.albedo_color = Color(1.0, 1.0, 1.0).lerp(ground, 0.45)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.6
	m.uv1_scale = Vector3(1.35, 1.35, 1.35)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	m.metallic = minf(m.metallic, 0.60)
	m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.50)
	# A FINISH THAT BRINGS ITS OWN TEXTURE WILL DROWN THE PAINT, and it does it in
	# the one channel that overwriting albedo does not touch. DreamSkin's "holo" and
	# "oilslick" set emission_texture to their own iridescent sweep; replacing only
	# albedo_texture left that sweep glowing over the top, and the first render of
	# this family came back as three pink-and-violet blobs with no maze, no bands
	# and no scales visible anywhere on them. The paint has to own both channels.
	if m.emission_texture != null:
		m.emission_texture = tex
	return m


# ---------------------------------------------------------------------------
# geometry helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ellipsoid(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3,
		b: Basis) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 20
	sph.rings = 11
	var mi: MeshInstance3D = _add(root, sph, mat)
	# NOTE Basis.scaled() is diag * B in the PARENT frame, which on a sphere cancels
	# the rotation outright. The squash has to happen in the ellipsoid's own frame.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


## A unit cylinder: radius 1, half-height 1, so it takes the same _diag() scale as
## a sphere does and a "sliced" disc is a drop-in for an ellipsoid link.
static func _disc_mesh() -> CylinderMesh:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 2.0
	cyl.radial_segments = 22
	cyl.rings = 1
	return cyl


static func _disc(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3) -> void:
	var mi: MeshInstance3D = _add(root, _disc_mesh(), mat)
	mi.transform = Transform3D(_diag(r), c)


## A tapered rod between two points. Used for ears, spines, fronds and the muzzle.
static func _rod(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3,
		r0: float, r1: float) -> void:
	var v: Vector3 = b - a
	var l: float = v.length()
	if l < 0.0005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r1
	cyl.bottom_radius = r0
	cyl.height = l
	cyl.radial_segments = 10
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(v), (a + b) * 0.5)


## A flat ring clamped round the column — the hard edge of a zebra band.
static func _collar(root: Node3D, mat: StandardMaterial3D, c: Vector3, rx: float,
		rz: float, th: float) -> void:
	var tor := TorusMesh.new()
	tor.outer_radius = 1.0
	tor.inner_radius = 1.0 - clampf(th / maxf(rx, 0.001), 0.05, 0.9)
	tor.rings = 20
	tor.ring_segments = 6
	var mi: MeshInstance3D = _add(root, tor, mat)
	mi.transform = Transform3D(_diag(Vector3(rx, maxf(rx, rz) * 0.30, rz)), c)


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


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	_tri_out(st, a, b, c, inside)
	_tri_out(st, a, c, d, inside)


## Emit one triangle wound so its face points AWAY from `inside`.
##
## GODOT WINDS FRONT FACES CLOCKWISE, and generate_normals() takes
## Plane(a, b, c).normal, which Godot builds as (a - c) x (a - b) — the negative of
## the textbook (b-a) x (c-a). Written the textbook way every ribbon, plate and
## mask in this file would be inside out: perfectly consistent, and invisible in
## any render that draws back faces.
static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var nf: Vector3 = (a - c).cross(a - b)
	if nf.length_squared() < 1.0e-16:
		return
	var cen: Vector3 = (a + b + c) / 3.0
	if nf.dot(cen - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


static func _p(pool: Array[float], i: int) -> float:
	return pool[posmod(i, pool.size())]


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
