extends RefCounted

## dream_bodies / nana_gloss — one dancing Nana, glossy, painted, mid-step.
##
## Reference: scratchpad/refs/saint_phalle.png (2048x536 panorama) — a crowd of
## Niki de Saint Phalle Nanas in a palm garden: enormous hips and thighs under a
## tiny round featureless head, thick tapering arms flung out, bodies moulded from
## nothing but overlapping ovoids and finished in a super-gloss white ground that
## carries flat painted pattern — a black maze/meander on the leftmost figure,
## a dark red mosaic of grout-lined cells on the big central back, and elsewhere
## scattered primary blobs, hearts, stripes and black contour marks.
##
## Reproduced, and how:
##   1. Ovoid body — a 26-link chain of squashed SphereMesh ellipsoids from crotch
##      to neck, radii keyed hips(widest) -> waist -> chest -> neck, with separate
##      belly, buttock and hip-shelf ovoids so the silhouette bulges the way the
##      reference does rather than tapering like a torso.
##   2. The dance — contrapposto built into the chain: pelvis rolls one way,
##      shoulders the other, the mass shifts over the standing leg, and the stack
##      twists about Y toward the raised arm. One arm is thrown up above the head,
##      the other flung down and out; one leg is lifted forward and out to the side.
##   3. Thick tapering limbs — every limb is a chain of overlapping spheres
##      (thigh 0.16 m at the hip), so the joins read as one poured glossy volume.
##   4. Small round head — a barely-ovoid sphere on the neck ovoid, no face beyond
##      two painted dots on some seeds, plus a bun at the back of the skull.
##   5. Painted skin — the ground is a 160x160 ImageTexture drawn pixel by pixel
##      in code and chosen by seed: a nested rectangular MEANDER labyrinth, a
##      jittered-Voronoi MOSAIC of dark red cells in white grout, or scattered
##      primary BLOBS with implicit-function hearts and black contour arcs. It is
##      applied with world triplanar so one pattern runs unbroken across the whole
##      chain of primitives, and a second, louder texture (stripes or blobs) is
##      painted onto one arm and one thigh the way the reference paints panels.
##   6. Flat paint that is really geometry — 10..16 primary discs sit proud of the
##      surface by 2 mm, some on a slightly larger black disc for a contour, and
##      one heart (two lobes + a downward PrismMesh) is laid on the belly or hip.
##   7. A seed is an individual — finish, palette, pattern kind and phase, hip
##      width, bust, head size, which arm rises, which leg lifts, lean, twist.
##
## THE FINISH (2026-09-03) — the enamel is dealt, not assumed. The white gloss of
## the reference was one seed's worth of a much louder wardrobe: every body now
## takes its surface from DreamSkin, one of
##
##     latex · patent · candy · wet · pearl · holo · oilslick · chrome
##
## in a colour off the queer palette, and the painted pattern rides on top of it
## as albedo with world triplanar. The pattern's own marks — discs, bosses,
## flowers, threads, the heart — are dealt separately from
## patent · latex · candy · wet · neon, so a body can wear a neon dot on a pearl
## hip. Two passages stay MATTE on purpose, because the contrast is the argument:
## the CAGED armature (the staves the flesh was poured over are dull iron, not
## enamel) and the PLINTH (concrete). Metallic is capped at 0.6 on the body and
## emission at 0.5, because a mirror photographs black and paint on a mirror has
## to stay paint.
##
## Given up: the crowd (this is one figure alone), the palm garden and plinth wall,
## the mirrored/silver figure's crumpled foil surface, the pattern following the
## body's own contours (triplanar is a projection, not a paint job), and the
## painted faces some Nanas carry.
##
## AXES — two, and they cut the statue, not the palette:
##   nana  — what has become of the dancer. "dancing" is the reference; "melting"
##           sags the whole enamel body to two thirds its height, spreads its feet
##           into a pool and hangs drips off her underside; "caged" takes the flesh
##           away and leaves the ribbed hoops and four black staves it was poured
##           over; "swarming" bursts every ovoid into two small copies of itself so
##           the figure is a cloud that still holds her shape around a solid head;
##           "ronde" grows a second, smaller Nana out of her hip, turned to dance
##           back at her, the two fused through a bridge of hip ovoids; "poured"
##           is the whole dancer GROWN as one isosurface — see below.
##   paint — what the flat paint does once it stops being flat. "flat" is the 2 mm
##           discs of the reference; "relief" balloons every mark into a glossy
##           dome and knobs her hands, bun and lifted foot; "blooming" opens each
##           mark into a six-petal flower and ends her hands, bun and raised foot
##           in blooms; "unravelling" pulls the marks out into falling threads and
##           frays both hands, the bun and the lifted foot into loose skeins.
##
## WHAT "poured" GROWS. Every other value assembles her out of overlapping ovoids
## and lets the gloss hide the seams. "poured" builds the SAME field — the same
## chain of 26 joints, the same hip shelves and belly and breasts, the same arm
## and leg joints at the same radii, all of it from _arm_joints / _leg_joints so
## the two paths cannot drift — and hands it to DreamIso as an SDF of 28 parts
## marched at 5.2 cm with a 11.5 cm smooth union. Nothing overlaps any more: the
## thigh SWELLS into the hip with a fillet, the breasts grow out of the chest
## rather than sitting on it, and the head and the neck are one continuous piece
## of poured enamel. Two subtractions: the light under the raised arm, which is
## where the field never crossed zero, and a navel bitten out of the belly. The
## marks are then snapped onto the grown surface by sphere-tracing the field, so
## a disc sits on the fillet and not in the air where the ovoid used to be. She
## keeps her primitive trimmings — bun, hands, toe, nipples, eyes, discs, heart —
## plus seven run-off drips down her underside and the pool she was poured into.
## The grown body is ONE MeshInstance3D, far under the family's floor of 40, so
## the trimmings are what carry the count: 48 at the thinnest (paint "flat", ten
## discs, no contours, no eyes) and about 150 at the loudest (paint
## "unravelling", every tip frayed into skeins). Never a bare plinth.
## If the mesher returns null the value falls back to the "dancing" primitive
## construction with the drips and the pool still on it.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX: int = 160
const PLINTH_TOP: float = 0.055

const K_MAZE: int = 0
const K_MOSAIC: int = 1
const K_BLOBS: int = 2
const K_STRIPES: int = 3

# the enamel a body may be poured in — never "matte", never "neon" over a pattern
const BODY_FIN: Array[String] = ["latex", "patent", "candy", "wet", "pearl", "holo",
	"oilslick", "chrome"]
# what a painted mark is made of — small, so neon can be in the deck
const MARK_FIN: Array[String] = ["patent", "latex", "candy", "wet", "neon"]

# limb radii — shared by the assembled chains and the poured field, so one edit
# moves both
const R_SH: float = 0.090
const R_EL: float = 0.068
const R_WR: float = 0.052
const R_HD: float = 0.046
const R_THIGH: float = 0.164
const R_KNEE_S: float = 0.104
const R_ANKLE_S: float = 0.062
const R_KNEE_L: float = 0.106
const R_ANKLE_L: float = 0.064

const POUR_CELL: float = 0.052
const POUR_BLEND: float = 0.115

# bold flat primaries, straight off the reference
const PRIMARIES: Array = [
	"#1B4FCF", "#F2C500", "#D9262C", "#1E9E4A", "#101010", "#C81E78", "#22B3C4",
]
const MOSAIC_BASES: Array = ["#5A122E", "#4A1030", "#5E1620", "#241A46"]


static func describe() -> String:
	return "A dancing Nana with enormous hips and a tiny round head, one arm thrown up and one leg lifted, her latex-and-oilslick body painted with maze lines, mosaic cells and primary blobs."


static func axes() -> Dictionary:
	return {
		"nana": ["dancing", "melting", "caged", "swarming", "ronde", "poured"],
		"paint": ["flat", "relief", "blooming", "unravelling"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var nana: String = String(opts.get("nana", "dancing"))
	var paint: String = String(opts.get("paint", "flat"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- who this one is -----------------------------------------------------
	var kind: int = rng.randi_range(0, 2)
	var alt_kind: int = K_STRIPES
	if kind == K_BLOBS and rng.randf() < 0.5:
		alt_kind = K_MAZE
	elif kind != K_BLOBS and rng.randf() < 0.42:
		alt_kind = K_BLOBS
	var body_k: float = rng.randf_range(0.94, 1.02)
	var hip_w: float = rng.randf_range(0.96, 1.13)
	var bust: float = rng.randf_range(0.90, 1.16)
	var head_r: float = rng.randf_range(0.098, 0.118)
	var raise_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var hand_lift: float = rng.randf_range(0.95, 1.03)
	var arm_drop: float = rng.randf_range(0.94, 1.06)
	var twist_m: float = deg_to_rad(rng.randf_range(4.0, 12.0))
	var hip_roll_m: float = deg_to_rad(rng.randf_range(3.0, 7.0))
	var sh_roll_m: float = deg_to_rad(rng.randf_range(-9.0, -3.0))
	var leg_out: float = rng.randf_range(0.24, 0.31)
	var leg_fwd: float = rng.randf_range(0.36, 0.46)
	var n_dot: int = rng.randi_range(10, 16)
	var has_eyes: bool = rng.randf() < 0.5
	var head_yaw: float = deg_to_rad(rng.randf_range(-16.0, 16.0))

	# --- the wardrobe: one finish, one palette, dealt from this seed ----------
	var finish: String = BODY_FIN[rng.randi_range(0, BODY_FIN.size() - 1)]
	var main: Color = Gloss.queer_colour(rng)
	var accent: Color = Gloss.queer_colour(rng)
	var ground: Color = Color(1.0, 1.0, 1.0).lerp(main, rng.randf_range(0.0, 0.42))
	var pal: Array = []
	for i in range(PRIMARIES.size()):
		pal.append(Color(str(PRIMARIES[i])))
	pal.append(main)
	pal.append(accent)
	pal.append(Gloss.queer_colour(rng))
	var ink: Color = Color(0.055, 0.050, 0.055)
	if rng.randf() < 0.30:
		ink = accent

	# --- painted skins -------------------------------------------------------
	var tex_main: ImageTexture = _make_tex(kind, rng, pal, ink)
	var tex_alt: ImageTexture = _make_tex(alt_kind, rng, pal, ink)
	var mat_skin: StandardMaterial3D = _dress(finish, ground, tex_main, _tex_uv(kind), rng)
	var mat_alt: StandardMaterial3D = _dress(finish, ground, tex_alt, _tex_uv(alt_kind), rng)
	var mat_black: StandardMaterial3D = Gloss.skin("patent", Color(0.06, 0.05, 0.09), rng)
	var flats: Array[StandardMaterial3D] = []
	for i in range(pal.size()):
		flats.append(_mark_mat(pal[i], rng))
	# MATTE, on purpose: the armature was never enamel
	var mat_stave: StandardMaterial3D = Gloss.skin("matte", Color(0.10, 0.09, 0.11))
	# MATTE, on purpose: concrete under a wet body
	var mat_plinth: StandardMaterial3D = Gloss.skin("matte", Color("#C8CBC4"))

	# which limbs wear the loud panel
	var alt_arm: float = 1.0 if rng.randf() < 0.5 else -1.0
	var alt_leg: float = 1.0 if rng.randf() < 0.5 else -1.0

	# --- how much figure the mesh budget buys at this axis value --------------
	var detail: float = 1.0
	if nana == "melting":
		detail = 0.92
	elif nana == "caged":
		detail = 0.78
	elif nana == "swarming":
		detail = 0.52
	elif nana == "ronde":
		detail = 0.46

	var dots: int = n_dot
	if paint == "blooming" or paint == "unravelling":
		dots = clampi(int(round(float(n_dot) * 0.52)), 4, 8)
	elif paint == "relief":
		dots = clampi(int(round(float(n_dot) * 0.85)), 6, 14)
	if nana == "ronde":
		dots = clampi(int(round(float(dots) * 0.45)), 2, 4)

	var cfg := {
		"nana": nana,
		"paint": paint,
		"detail": detail,
		"dots": dots,
		"mat_skin": mat_skin,
		"mat_alt": mat_alt,
		"mat_black": mat_black,
		"mat_stave": mat_stave,
		"flats": flats,
		"hip_w": hip_w,
		"bust": bust,
		"head_r": head_r,
		"raise_side": raise_side,
		"mirror": 1.0,
		"hand_lift": hand_lift,
		"arm_drop": arm_drop,
		"twist_m": twist_m,
		"hip_roll_m": hip_roll_m,
		"sh_roll_m": sh_roll_m,
		"leg_out": leg_out,
		"leg_fwd": leg_fwd,
		"has_eyes": has_eyes,
		"head_yaw": head_yaw,
		"alt_arm": alt_arm,
		"alt_leg": alt_leg,
	}
	_figure(root, rng, cfg)

	# --- the second dancer, grown out of her hip ------------------------------
	if nana == "ronde":
		var i0: int = root.get_child_count()
		var cfg2: Dictionary = cfg.duplicate()
		cfg2["detail"] = 0.40
		cfg2["mirror"] = -1.0
		cfg2["dots"] = maxi(dots - 1, 2)
		_figure(root, rng, cfg2)
		var yaw2: float = deg_to_rad(rng.randf_range(126.0, 168.0)) * raise_side
		var sc2: float = rng.randf_range(0.76, 0.88)
		var tf2 := Transform3D(Basis(Vector3.UP, yaw2) * _diag(Vector3(sc2, sc2, sc2)), Vector3(raise_side * 0.36, 0.13, 0.11))
		_xform_range(root, i0, tf2)
		for j in range(3):
			var u: float = float(j) / 2.0
			var pj: Vector3 = Vector3(raise_side * 0.19, 0.70, 0.02).lerp(Vector3(raise_side * 0.36, 0.72, 0.11), u)
			_ellipsoid(root, mat_skin, pj, Vector3(0.152, 0.132, 0.142), Basis())

	# --- the enamel gives up ---------------------------------------------------
	if nana == "melting":
		var top: float = _union_aabb(root).end.y
		_melt(root, 0, top)
		_drips(root, mat_skin, rng)
		_puddle(root, mat_skin, flats[2], rng)

	# --- the pool she was poured into ------------------------------------------
	if nana == "poured":
		_puddle(root, mat_skin, flats[2], rng)

	# --- stature, then the measured settle -----------------------------------
	_rescale(root, body_k, Vector3.ZERO)

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

	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.20, box.size.x + 0.10), PLINTH_TOP, minf(1.20, box.size.z + 0.10))
	var pm: MeshInstance3D = _add(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# one Nana — the whole dancer, built into root at world scale

static func _figure(root: Node3D, rng: RandomNumberGenerator, cfg: Dictionary) -> void:
	var nana: String = String(cfg["nana"])
	var paint: String = String(cfg["paint"])
	var d: float = float(cfg["detail"])
	var dots: int = int(cfg["dots"])
	var mat_skin: StandardMaterial3D = cfg["mat_skin"]
	var mat_alt: StandardMaterial3D = cfg["mat_alt"]
	var mat_black: StandardMaterial3D = cfg["mat_black"]
	var mat_stave: StandardMaterial3D = cfg["mat_stave"]
	var flats: Array = cfg["flats"]
	var core_mat: StandardMaterial3D = flats[1]
	var hip_w: float = float(cfg["hip_w"])
	var bust: float = float(cfg["bust"])
	var head_r: float = float(cfg["head_r"])
	var raise_side: float = float(cfg["raise_side"]) * float(cfg["mirror"])
	var hand_lift: float = float(cfg["hand_lift"])
	var arm_drop: float = float(cfg["arm_drop"])
	var twist: float = float(cfg["twist_m"]) * raise_side
	var hip_roll: float = float(cfg["hip_roll_m"]) * raise_side
	var sh_roll: float = float(cfg["sh_roll_m"]) * raise_side
	var leg_out: float = float(cfg["leg_out"])
	var leg_fwd: float = float(cfg["leg_fwd"])
	var has_eyes: bool = bool(cfg["has_eyes"])
	var head_yaw: float = float(cfg["head_yaw"])
	var alt_arm: float = float(cfg["alt_arm"])
	var alt_leg: float = float(cfg["alt_leg"])

	# "poured" asks for the field; if it cannot be marched the body falls back to
	# the assembled dancer, which is what `solid` is for.
	var want_pour: bool = nana == "poured"
	var solid: String = "dancing" if want_pour else nana

	# --- the ovoid chain, crotch to neck — joints first, meshes later ---------
	var n_seg: int = maxi(int(round(26.0 * d)), 12)
	var seg_ry: float = 0.056 / clampf(d, 0.34, 1.0)
	var y_lo: float = 0.60
	var y_hi: float = 1.30
	var rx_keys: Array = [0.195, 0.300 * hip_w, 0.326 * hip_w, 0.246, 0.222, 0.240, 0.204, 0.088]
	var rz_keys: Array = [0.170, 0.236 * hip_w, 0.252 * hip_w, 0.208, 0.196, 0.206, 0.176, 0.082]
	var zo_keys: Array = [0.022, 0.040, 0.030, -0.006, -0.032, -0.020, 0.000, 0.006]

	var t_c: Array[Vector3] = []
	var t_b: Array[Basis] = []
	var t_rx: Array[float] = []
	var t_rz: Array[float] = []
	var t_rp: Array[float] = []
	for i in range(n_seg):
		var t: float = float(i) / float(n_seg - 1)
		var rx: float = _key(rx_keys, t)
		var rz: float = _key(rz_keys, t)
		var zo: float = _key(zo_keys, t)
		var xo: float = raise_side * (0.032 * pow(1.0 - t, 1.6) - 0.024 * pow(t, 1.8))
		var yq: float = lerpf(y_lo, y_hi, t)
		var roll_a: float = lerpf(hip_roll, sh_roll, t)
		var bs: Basis = Basis(Vector3.UP, twist * t) * Basis(Vector3.BACK, roll_a)
		t_c.append(Vector3(xo, yq, zo))
		t_b.append(bs)
		t_rx.append(rx)
		t_rz.append(rz)
		t_rp.append((rx + rz) * 0.5)

	# --- the landmarks every path shares -------------------------------------
	var i_belly: int = int(floor(float(n_seg - 1) * 0.34))
	var c_belly: Vector3 = t_c[i_belly]
	var i_hip: int = int(floor(float(n_seg - 1) * 0.14))
	var c_hip: Vector3 = t_c[i_hip]
	var i_bust: int = int(floor(float(n_seg - 1) * 0.72))
	var c_bust: Vector3 = t_c[i_bust]
	var i_sh: int = int(floor(float(n_seg - 1) * 0.90))
	var c_sh: Vector3 = t_c[i_sh]
	var c_neck: Vector3 = t_c[n_seg - 1]
	var head_c: Vector3 = c_neck + Vector3(raise_side * 0.006, 0.118, -0.012)
	var head_b: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.BACK, sh_roll * 0.8)
	var bun_c: Vector3 = head_c + head_b * Vector3(0.0, 0.052, 0.082)
	var bun_n: Vector3 = (head_b * Vector3(0.0, 0.42, 1.0)).normalized()
	var br: float = 0.112 * bust
	var bp: Array[Vector3] = []
	var arm_j: Array = []
	var leg_j: Array = []
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		bp.append(c_bust + Vector3(sd * 0.118, -0.012, -0.128))
		arm_j.append(_arm_joints(c_sh + Vector3(sd * 0.186, 0.006, 0.004), sd, sd == raise_side, hand_lift, arm_drop))
		leg_j.append(_leg_joints(sd, sd == raise_side, hip_w, leg_out, leg_fwd))

	# --- the poured body: one field, marched ---------------------------------
	var pour_parts: Array = []
	var poured: bool = false
	if want_pour:
		var rings: int = 7
		for k in range(rings):
			var ia: int = int(round(float(k) / float(rings) * float(n_seg - 1)))
			var ib: int = int(round(float(k + 1) / float(rings) * float(n_seg - 1)))
			pour_parts.append(Iso.capsule(t_c[ia], t_c[ib], t_rp[ia] * 0.90, t_rp[ib] * 0.90))
		pour_parts.append(Iso.sphere(c_belly + Vector3(0.0, -0.01, -0.070), 0.152))
		for s_i in range(2):
			var sd: float = -1.0 if s_i == 0 else 1.0
			pour_parts.append(Iso.sphere(c_hip + Vector3(sd * 0.130 * hip_w, 0.012, 0.130), 0.150))
			pour_parts.append(Iso.sphere(c_hip + Vector3(sd * 0.196 * hip_w, -0.030, 0.010), 0.128))
			pour_parts.append(Iso.sphere(bp[s_i], br * 0.92))
			var aj: Array = arm_j[s_i]
			var a0: Vector3 = aj[0]
			var a1: Vector3 = aj[1]
			var a2: Vector3 = aj[2]
			var a3: Vector3 = aj[3]
			pour_parts.append(Iso.capsule(a0, a1, R_SH * 0.94, R_EL * 0.94))
			pour_parts.append(Iso.capsule(a1, a2, R_EL * 0.94, R_WR * 0.94))
			pour_parts.append(Iso.capsule(a2, a3, R_WR * 0.94, R_HD * 0.94))
			var lj: Array = leg_j[s_i]
			var l0: Vector3 = lj[0]
			var l1: Vector3 = lj[1]
			var l2: Vector3 = lj[2]
			var l3: Vector3 = lj[3]
			var kr: float = R_KNEE_S if sd == raise_side else R_KNEE_L
			var ar: float = R_ANKLE_S if sd == raise_side else R_ANKLE_L
			pour_parts.append(Iso.capsule(l0, l1, R_THIGH * hip_w * 0.92, kr * 0.94))
			pour_parts.append(Iso.capsule(l1, l2, kr * 0.94, ar * 0.94))
			if sd == raise_side:
				pour_parts.append(Iso.box(l3, Vector3(0.070, 0.048, 0.104), 0.030))
		pour_parts.append(Iso.sphere(head_c, head_r))
		# the light under the raised arm — where the field never crossed zero
		pour_parts.append(Iso.cut(Iso.sphere(c_sh + Vector3(raise_side * 0.190, -0.030, -0.010), rng.randf_range(0.098, 0.126))))
		# a navel, bitten out of the belly's front
		pour_parts.append(Iso.cut(Iso.sphere(c_belly + Vector3(rng.randf_range(-0.03, 0.03), -0.02, -0.257), 0.075)))
		# THE MESHER IS NEW: check it, and fall back to the ovoids if it gave nothing
		var grown: ArrayMesh = Iso.mesh_of(pour_parts, POUR_CELL, POUR_BLEND, 0.05)
		if grown != null:
			_add(root, grown, mat_skin)
			poured = true

	# --- the assembled body — everything the field did not already grow -------
	if not poured:
		for i in range(n_seg):
			_part(root, solid, mat_skin, t_c[i], Vector3(t_rx[i], seg_ry, t_rz[i]), t_b[i], rng)

	# the staves the flesh was poured over, once the flesh is gone
	if nana == "caged":
		var step_i: int = maxi(int(round(3.0 * d)), 2)
		for s in range(4):
			var sa: float = TAU * float(s) / 4.0
			var have: bool = false
			var prev := Vector3.ZERO
			var i2: int = 0
			while i2 < n_seg:
				var pt: Vector3 = t_c[i2] + t_b[i2] * Vector3(t_rx[i2] * sin(sa), 0.0, t_rz[i2] * cos(sa))
				if have:
					_rod(root, mat_stave, prev, pt, 0.010)
				prev = pt
				have = true
				i2 += step_i

	# belly, buttocks, hip shelves — the bulges the chain alone will not give
	if not poured:
		_part(root, solid, mat_skin, c_belly + Vector3(0.0, -0.01, -0.070), Vector3(0.196, 0.150, 0.176), Basis(), rng)
		for s_i in range(2):
			var sd: float = -1.0 if s_i == 0 else 1.0
			_part(root, solid, mat_skin, c_hip + Vector3(sd * 0.130 * hip_w, 0.012, 0.130), Vector3(0.185, 0.160, 0.180), Basis(), rng)
			_part(root, solid, mat_skin, c_hip + Vector3(sd * 0.196 * hip_w, -0.030, 0.010), Vector3(0.140, 0.145, 0.170), Basis(), rng)

	# breasts — the volume may be grown, the nipple is always a mark
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		if not poured:
			_part(root, solid, mat_skin, bp[s_i], Vector3(br, br * 0.96, br * 1.06), Basis(), rng)
		_ellipsoid(root, mat_black, bp[s_i] + Vector3(sd * 0.012, 0.004, -br * 0.92), Vector3(0.026, 0.026, 0.020), Basis())

	# --- head — always solid, it is the thing the family is recognised by ------
	if not poured:
		_ellipsoid(root, mat_skin, head_c, Vector3(head_r, head_r * 1.07, head_r * 1.02), head_b)
	_tip(root, mat_skin, core_mat, paint, bun_c, Vector3(0.046, 0.044, 0.044), Basis(), bun_n, d, rng)
	if has_eyes:
		for s_i in range(2):
			var sd: float = -1.0 if s_i == 0 else 1.0
			var ep: Vector3 = head_c + head_b * Vector3(sd * head_r * 0.40, head_r * 0.20, -head_r * 0.92)
			_ellipsoid(root, mat_black, ep, Vector3(0.019, 0.024, 0.010), head_b)

	# --- arms ----------------------------------------------------------------
	var a_up: int = maxi(int(round(8.0 * d)), 3)
	var a_fo: int = maxi(int(round(7.0 * d)), 3)
	var a_wr: int = maxi(int(round(4.0 * d)), 2)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var mat_arm: StandardMaterial3D = mat_alt if sd == alt_arm else mat_skin
		var aj: Array = arm_j[s_i]
		var sh: Vector3 = aj[0]
		var el: Vector3 = aj[1]
		var wr: Vector3 = aj[2]
		var hd: Vector3 = aj[3]
		var hn: Vector3 = aj[4]
		var tip_c: Vector3 = aj[5]
		if not poured:
			_chain(root, mat_arm, sh, el, R_SH, R_EL, a_up, solid, rng)
			_chain(root, mat_arm, el, wr, R_EL, R_WR, a_fo, solid, rng)
			_chain(root, mat_arm, wr, hd, R_WR, R_HD, a_wr, solid, rng)
		var tip_r: Vector3 = Vector3(0.056, 0.060, 0.044) if sd == raise_side else Vector3(0.058, 0.064, 0.044)
		var tip_b: Basis = Basis(Vector3.BACK, -sd * 0.25) if sd == raise_side else Basis(Vector3.BACK, sd * 0.30)
		_tip(root, mat_arm, core_mat, paint, tip_c, tip_r, tip_b, hn, d, rng)

	# --- legs ----------------------------------------------------------------
	var l_th: int = maxi(int(round(9.0 * d)), 3)
	var l_sh: int = maxi(int(round(8.0 * d)), 3)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var mat_leg: StandardMaterial3D = mat_alt if sd == alt_leg else mat_skin
		var lj: Array = leg_j[s_i]
		var hip_p: Vector3 = lj[0]
		var knee: Vector3 = lj[1]
		var ankle: Vector3 = lj[2]
		var foot: Vector3 = lj[3]
		if sd == raise_side:
			if not poured:
				_chain(root, mat_leg, hip_p, knee, R_THIGH * hip_w, R_KNEE_S, l_th, solid, rng)
				_chain(root, mat_leg, knee, ankle, R_KNEE_S, R_ANKLE_S, l_sh, solid, rng)
				_part(root, solid, mat_leg, foot, Vector3(0.078, 0.056, 0.118), Basis(Vector3.UP, sd * 0.16), rng)
		else:
			if not poured:
				_chain(root, mat_leg, hip_p, knee, R_THIGH * hip_w, R_KNEE_L, l_th, solid, rng)
				_chain(root, mat_leg, knee, ankle, R_KNEE_L, R_ANKLE_L, l_sh, solid, rng)
			var tn: Vector3 = Vector3(0.0, -0.30, -1.0).normalized()
			_tip(root, mat_leg, core_mat, paint, foot, Vector3(0.070, 0.052, 0.086), Basis(Vector3.RIGHT, -0.45), tn, d, rng)

	# --- flat paint that is really geometry ----------------------------------
	for _di in range(dots):
		var iq: int = rng.randi_range(2, n_seg - 4)
		var ang: float = rng.randf_range(-2.55, 2.55)
		var rx2: float = t_rp[iq] if poured else t_rx[iq]
		var rz2: float = t_rp[iq] if poured else t_rz[iq]
		var bs2: Basis = t_b[iq]
		var loc := Vector3(rx2 * sin(ang), 0.0, rz2 * cos(ang))
		var nrm: Vector3 = (bs2 * Vector3(sin(ang) / rx2, 0.0, cos(ang) / rz2)).normalized()
		var pos: Vector3 = t_c[iq] + bs2 * loc + Vector3(0.0, rng.randf_range(-0.020, 0.020), 0.0)
		if poured:
			var sn: Array = _snap(pour_parts, pos, nrm)
			pos = sn[0]
			nrm = sn[1]
		var rr: float = rng.randf_range(0.042, 0.086)
		var col_i: int = rng.randi_range(0, flats.size() - 1)
		var fm: StandardMaterial3D = flats[col_i]
		if paint == "relief":
			if rng.randf() < 0.42:
				_disc(root, mat_black, pos + nrm * 0.001, nrm, rr * 1.30, 0.012)
			_boss(root, fm, pos, nrm, rr * 1.12)
		elif paint == "blooming":
			_flower(root, fm, core_mat, pos, nrm, rr * 1.45, d, rng)
		elif paint == "unravelling":
			_thread(root, fm, pos, nrm, rr * 2.1, rng)
		else:
			if rng.randf() < 0.42:
				_disc(root, mat_black, pos + nrm * 0.001, nrm, rr * 1.24, 0.010)
			_disc(root, fm, pos + nrm * 0.004, nrm, rr, 0.011)

	# one heart, laid on the belly or a hip
	var i_heart: int = i_belly if rng.randf() < 0.6 else i_hip + 2
	i_heart = clampi(i_heart, 2, n_seg - 4)
	var face_back: float = 0.0 if rng.randf() < 0.7 else PI
	var ha: float = rng.randf_range(-0.9, 0.9) + face_back
	var hrx: float = t_rp[i_heart] if poured else t_rx[i_heart]
	var hrz: float = t_rp[i_heart] if poured else t_rz[i_heart]
	var hbs: Basis = t_b[i_heart]
	var hnrm: Vector3 = (hbs * Vector3(sin(ha) / hrx, 0.0, cos(ha) / hrz)).normalized()
	var hpos: Vector3 = t_c[i_heart] + hbs * Vector3(hrx * sin(ha), 0.0, hrz * cos(ha))
	if poured:
		var hsn: Array = _snap(pour_parts, hpos, hnrm)
		hpos = hsn[0]
		hnrm = hsn[1]
	var heart_mat: StandardMaterial3D = flats[2] if rng.randf() < 0.6 else flats[0]
	var hs: float = rng.randf_range(0.115, 0.165)
	var hth: float = 0.058 if paint == "relief" else 0.014
	_heart(root, heart_mat, hpos + hnrm * 0.004, hnrm, hs, hth)

	# --- what ran off her underside while she set ----------------------------
	if want_pour:
		var low_i: int = 0 if raise_side > 0.0 else 1
		var arm_lo: Array = arm_j[low_i]
		var leg_lo: Array = leg_j[low_i]
		var hand_lo: Vector3 = arm_lo[3]
		var toe_lo: Vector3 = leg_lo[3]
		var anchors: Array[Vector3] = []
		anchors.append(c_belly + Vector3(0.0, -0.20, -0.10))
		for s_i in range(2):
			var sd: float = -1.0 if s_i == 0 else 1.0
			anchors.append(c_hip + Vector3(sd * 0.196 * hip_w, -0.175, 0.010))
			anchors.append(bp[s_i] + Vector3(0.0, -br * 1.05, -0.020))
		anchors.append(hand_lo + Vector3(0.0, -0.060, 0.0))
		anchors.append(toe_lo + Vector3(0.0, -0.050, 0.0))
		_pour_drips(root, mat_skin, anchors, rng)


# ---------------------------------------------------------------------------
# joints — ONE source, so the assembled chains and the poured field agree

static func _arm_joints(sh: Vector3, sd: float, up: bool, hand_lift: float, arm_drop: float) -> Array:
	if up:
		var el := sh + Vector3(sd * 0.150, 0.100 * hand_lift, -0.040)
		var wr := el + Vector3(sd * 0.075, 0.110 * hand_lift, 0.030)
		var hd := wr + Vector3(sd * 0.024, 0.040 * hand_lift, 0.006)
		var hn: Vector3 = Vector3(sd * 0.42, 1.0, 0.10).normalized()
		return [sh, el, wr, hd, hn, hd + Vector3(sd * 0.006, 0.028, 0.0)]
	var el2 := sh + Vector3(sd * 0.160, -0.155 * arm_drop, -0.052)
	var wr2 := el2 + Vector3(sd * 0.078, -0.150 * arm_drop, 0.028)
	var hd2 := wr2 + Vector3(sd * 0.026, -0.072 * arm_drop, -0.008)
	var hn2: Vector3 = Vector3(sd * 0.36, -1.0, -0.14).normalized()
	return [sh, el2, wr2, hd2, hn2, hd2 + Vector3(sd * 0.010, -0.032, -0.004)]


static func _leg_joints(sd: float, standing: bool, hip_w: float, leg_out: float, leg_fwd: float) -> Array:
	var hip_p := Vector3(sd * 0.168 * hip_w, 0.690, 0.020)
	if standing:
		return [hip_p, Vector3(sd * 0.152, 0.372, -0.008), Vector3(sd * 0.142, 0.104, 0.014),
			Vector3(sd * 0.142, 0.056, -0.046)]
	return [hip_p, Vector3(sd * leg_out, 0.548, -leg_fwd * 0.52),
		Vector3(sd * (leg_out + 0.030), 0.362, -leg_fwd),
		Vector3(sd * (leg_out + 0.036), 0.310, -leg_fwd - 0.086)]


# ---------------------------------------------------------------------------
# the poured value — the field's own surface, and what ran off it

## Sphere-trace a mark down onto the grown surface, then take the true normal
## from the field's gradient. Without this a disc placed on the ovoid's radius
## floats wherever the smooth union swelled the body outward.
static func _snap(parts: Array, p: Vector3, nrm: Vector3) -> Array:
	var q: Vector3 = p
	for i in range(4):
		var dv: float = Iso.field(parts, q, POUR_BLEND)
		q = q - nrm * clampf(dv, -0.12, 0.12)
	var e: float = 0.012
	var gx: float = Iso.field(parts, q + Vector3(e, 0.0, 0.0), POUR_BLEND) - Iso.field(parts, q - Vector3(e, 0.0, 0.0), POUR_BLEND)
	var gy: float = Iso.field(parts, q + Vector3(0.0, e, 0.0), POUR_BLEND) - Iso.field(parts, q - Vector3(0.0, e, 0.0), POUR_BLEND)
	var gz: float = Iso.field(parts, q + Vector3(0.0, 0.0, e), POUR_BLEND) - Iso.field(parts, q - Vector3(0.0, 0.0, e), POUR_BLEND)
	var g := Vector3(gx, gy, gz)
	var n2: Vector3 = nrm if g.length() < 0.00001 else g.normalized()
	if n2.dot(nrm) < 0.0:
		n2 = -n2
	return [q, n2]


static func _pour_drips(root: Node3D, mat: StandardMaterial3D, anchors: Array, rng: RandomNumberGenerator) -> void:
	for a_v in anchors:
		var a: Vector3 = a_v
		var r0: float = rng.randf_range(0.026, 0.044)
		var pv: Vector3 = a
		for j in range(3):
			var rr: float = r0 * (1.0 - 0.22 * float(j))
			pv = Vector3(pv.x, pv.y - rr * 1.25, pv.z)
			_ellipsoid(root, mat, pv, Vector3(rr, rr * 1.35, rr), Basis())


# ---------------------------------------------------------------------------
# the nana axis — what a body part IS

static func _part(root: Node3D, mode: String, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis, rng: RandomNumberGenerator) -> void:
	if mode == "caged":
		_hoop(root, mat, c, r, b)
		return
	if mode == "swarming" and rng != null:
		var a0: float = rng.randf_range(0.0, TAU)
		var br := Vector3(r.x * 0.36, maxf(r.y, minf(r.x, r.z)) * 0.42, r.z * 0.36)
		for k in range(2):
			var a2: float = a0 + PI * float(k)
			var push: float = rng.randf_range(0.92, 1.74)
			var off := Vector3(sin(a2) * r.x * 0.60 * push, rng.randf_range(-0.40, 0.40) * r.y, cos(a2) * r.z * 0.60 * push)
			_ellipsoid(root, mat, c + b * off, br, b)
		return
	_ellipsoid(root, mat, c, r, b)


static func _hoop(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis) -> void:
	var tor := TorusMesh.new()
	tor.outer_radius = 1.0
	tor.inner_radius = 0.84
	tor.rings = 20
	tor.ring_segments = 6
	var yr: float = maxf(maxf(r.x, r.z) * 0.55, 0.10)
	var mi: MeshInstance3D = _add(root, tor, mat)
	mi.transform = Transform3D(b * _diag(Vector3(r.x, yr, r.z)), c)


# ---------------------------------------------------------------------------
# the paint axis — what a mark and a limb-end DO

static func _boss(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3, r: float) -> void:
	var fb: Basis = _basis_y_to(nrm)
	_ellipsoid(root, mat, p + nrm * r * 0.30, Vector3(r, r * 1.38, r), fb)


static func _flower(root: Node3D, mat: StandardMaterial3D, core: StandardMaterial3D, p: Vector3, nrm: Vector3, r: float, d: float, rng: RandomNumberGenerator) -> void:
	var fb: Basis = _basis_y_to(nrm)
	var petals: int = clampi(int(round(6.0 * d)), 4, 6)
	var spin: float = rng.randf_range(0.0, TAU)
	for k in range(petals):
		var a: float = spin + TAU * float(k) / float(petals)
		var rot := Basis(Vector3.UP, a)
		var pc: Vector3 = p + fb * (rot * Vector3(r * 0.72, r * 0.30, 0.0))
		var pb: Basis = fb * rot * Basis(Vector3.BACK, -0.62)
		_ellipsoid(root, mat, pc, Vector3(r * 0.54, r * 0.15, r * 0.34), pb)
	_ellipsoid(root, core, p + nrm * r * 0.34, Vector3(r * 0.30, r * 0.30, r * 0.30), fb)


static func _thread(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3, len_t: float, rng: RandomNumberGenerator) -> void:
	var axis: Vector3 = nrm.normalized()
	var dir: Vector3 = axis
	var tan: Vector3 = dir.cross(Vector3.UP)
	if tan.length() < 0.001:
		tan = dir.cross(Vector3.FORWARD)
	tan = tan.normalized()
	var seg: float = maxf(len_t, 0.03) * 0.55
	var pv: Vector3 = p
	var rt: float = 0.009
	for k in range(4):
		var nx: Vector3 = pv + dir * seg
		_rod(root, mat, pv, nx, rt * (1.0 - 0.16 * float(k)))
		pv = nx
		dir = (dir * 0.55 + tan * 0.75 + Vector3.DOWN * 0.35).normalized()
		tan = tan.rotated(axis, rng.randf_range(0.7, 1.5))
		seg = seg * 0.88


static func _tip(root: Node3D, mat: StandardMaterial3D, core: StandardMaterial3D, paint: String, c: Vector3, r: Vector3, b: Basis, nrm: Vector3, d: float, rng: RandomNumberGenerator) -> void:
	if paint == "blooming":
		_flower(root, mat, core, c, nrm, maxf(r.x, r.z) * 2.4, d, rng)
		return
	if paint == "unravelling":
		var n_thr: int = maxi(int(round(4.5 * d)), 2)
		for k in range(n_thr):
			var jd: Vector3 = (nrm * 1.2 + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))).normalized()
			_thread(root, mat, c, jd, maxf(r.x, r.z) * 2.4, rng)
		return
	_ellipsoid(root, mat, c, r, b)
	if paint == "relief":
		var lift: float = maxf(r.x, r.y)
		_ellipsoid(root, mat, c + nrm * lift * 1.05, r * 0.62, b)
		_ellipsoid(root, core, c + nrm * lift * 1.72, r * 0.38, b)


# ---------------------------------------------------------------------------
# the melt — a post-pass over everything already standing

static func _melt(root: Node3D, i0: int, y_top: float) -> void:
	var kids: Array = root.get_children()
	var yt: float = maxf(y_top, 0.001)
	for i in range(i0, kids.size()):
		var ch: Node = kids[i]
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		var h: float = clampf(tf.origin.y / yt, 0.0, 1.0)
		var sy: float = lerpf(0.30, 0.66, h)
		var sxz: float = lerpf(1.42, 1.04, h)
		var spread: float = lerpf(1.26, 1.00, h)
		var ny: float = tf.origin.y * lerpf(0.40, 0.62, h)
		var np := Vector3(tf.origin.x * spread, ny, tf.origin.z * spread)
		cm.transform = Transform3D(_diag(Vector3(sxz, sy, sxz)) * tf.basis, np)


static func _drips(root: Node3D, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var kids: Array = root.get_children()
	if kids.size() < 8:
		return
	for k in range(5):
		var idx: int = rng.randi_range(0, kids.size() - 1)
		var ch: Node = kids[idx]
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var p: Vector3 = cm.transform.origin
		if p.y < 0.26 or p.y > 0.74:
			continue
		var r0: float = rng.randf_range(0.028, 0.050)
		var pv: Vector3 = p
		for j in range(3):
			var rr: float = r0 * (1.0 - 0.24 * float(j))
			var nyv: float = pv.y - rr * 1.30
			if nyv - rr < 0.03:
				break
			pv = Vector3(pv.x, nyv, pv.z)
			_ellipsoid(root, mat, pv, Vector3(rr, rr * 1.32, rr), Basis())


static func _puddle(root: Node3D, mat: StandardMaterial3D, accent: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var n: int = 6
	for i in range(n):
		var a: float = rng.randf_range(0.0, TAU)
		var dd: float = rng.randf_range(0.0, 0.15)
		var rr: float = rng.randf_range(0.21, 0.38)
		var ry: float = rng.randf_range(0.018, 0.034)
		var m: StandardMaterial3D = accent if i >= n - 2 else mat
		var sq: float = rng.randf_range(0.80, 1.20)
		_ellipsoid(root, m, Vector3(cos(a) * dd, ry * 0.85, sin(a) * dd), Vector3(rr, ry, rr * sq), Basis(Vector3.UP, a))


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
	sph.radial_segments = 22
	sph.rings = 12
	var mi: MeshInstance3D = _add(root, sph, mat)
	# NOTE Basis.scaled() is diag * B (parent frame), which on a sphere cancels the
	# rotation outright. The squash has to happen in the ellipsoid's OWN frame.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _chain(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r0: float, r1: float, n: int, mode: String = "dancing", rng: RandomNumberGenerator = null) -> void:
	var steps: int = maxi(n, 2)
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var p: Vector3 = a.lerp(b, t)
		var r: float = lerpf(r0, r1, t)
		_part(root, mode, mat, p, Vector3(r, r, r), Basis(), rng)


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


static func _disc(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3, r: float, th: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = th
	cyl.radial_segments = 20
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(nrm), p)


static func _heart(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3, s: float, th: float = 0.014) -> void:
	var zc: Vector3 = nrm.normalized()
	var yc: Vector3 = Vector3.UP - zc * Vector3.UP.dot(zc)
	if yc.length() < 0.001:
		yc = Vector3.FORWARD - zc * Vector3.FORWARD.dot(zc)
	yc = yc.normalized()
	var xc: Vector3 = yc.cross(zc).normalized()
	var hb := Basis(xc, yc, zc)
	for sgn in [-1.0, 1.0]:
		var sf: float = sgn
		var lobe: Vector3 = p + hb * Vector3(sf * s * 0.29, s * 0.30, 0.0)
		var sph := SphereMesh.new()
		sph.radius = 1.0
		sph.height = 2.0
		sph.radial_segments = 18
		sph.rings = 10
		var mi: MeshInstance3D = _add(root, sph, mat)
		mi.transform = Transform3D(hb * _diag(Vector3(s * 0.36, s * 0.34, th)), lobe)
	var pr := PrismMesh.new()
	pr.size = Vector3(s * 1.16, s * 0.86, th * 2.0)
	var pmi: MeshInstance3D = _add(root, pr, mat)
	pmi.transform = Transform3D(hb * Basis(Vector3.BACK, PI), p + hb * Vector3(0.0, s * 0.02, 0.0))


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


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
	var a: float = float(keys[i])
	var b: float = float(keys[i + 1])
	return lerpf(a, b, sm)


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


# ---------------------------------------------------------------------------
# materials — the enamel comes from DreamSkin, the pattern is painted on top

## A painted body: a DreamSkin finish, with the code-drawn pattern as its albedo
## in world triplanar so one image runs unbroken across every primitive. The two
## caps are deliberate — a body at metallic 1.0 photographs black in a bare
## capture, and paint under a strong emission stops reading as paint.
static func _dress(finish: String, ground: Color, tex: ImageTexture, uv: float, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, ground, rng)
	m.albedo_color = ground
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.6
	m.uv1_scale = Vector3(uv, uv, uv)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	m.metallic = minf(m.metallic, 0.60)
	m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.50)
	return m


## A flat mark: small enough to wear neon without eating the frame.
static func _mark_mat(c: Color, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var f: String = MARK_FIN[rng.randi_range(0, MARK_FIN.size() - 1)]
	var m: StandardMaterial3D = Gloss.skin(f, c, rng)
	m.metallic = minf(m.metallic, 0.50)
	return m


static func _tex_uv(kind: int) -> float:
	if kind == K_MOSAIC:
		return 1.85
	if kind == K_BLOBS:
		return 1.15
	if kind == K_STRIPES:
		return 1.30
	return 1.50


# ---------------------------------------------------------------------------
# painted skins — every pixel drawn in code

static func _make_tex(kind: int, rng: RandomNumberGenerator, pal: Array, ink: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	if kind == K_MOSAIC:
		var base: Color = Color(str(MOSAIC_BASES[rng.randi_range(0, MOSAIC_BASES.size() - 1)]))
		if rng.randf() < 0.35:
			var q: Color = Gloss.queer_colour(rng)
			base = Color(q.r * 0.55, q.g * 0.55, q.b * 0.55)
		_paint_mosaic(img, rng, base)
	elif kind == K_BLOBS:
		_paint_blobs(img, rng, pal, ink)
	elif kind == K_STRIPES:
		_paint_stripes(img, rng, pal, ink)
	else:
		_paint_maze(img, rng, ink)
	return ImageTexture.create_from_image(img)


static func _put(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _fill(img: Image, c: Color) -> void:
	for y in range(TEX):
		for x in range(TEX):
			img.set_pixel(x, y, c)


# --- maze / meander ---------------------------------------------------------

static func _rot_put(img: Image, ox: int, oy: int, s: int, rot: int, x: int, y: int, c: Color) -> void:
	var rx: int = x
	var ry: int = y
	if rot == 1:
		rx = s - 1 - y
		ry = x
	elif rot == 2:
		rx = s - 1 - x
		ry = s - 1 - y
	elif rot == 3:
		rx = y
		ry = s - 1 - x
	_put(img, ox + rx, oy + ry, c)


static func _cell_bar(img: Image, ox: int, oy: int, s: int, rot: int, x0: int, y0: int, x1: int, y1: int, th: int, c: Color) -> void:
	var xa: int = mini(x0, x1)
	var xb: int = maxi(x0, x1) + th
	var ya: int = mini(y0, y1)
	var yb: int = maxi(y0, y1) + th
	for y in range(ya, yb):
		for x in range(xa, xb):
			if x < 0 or y < 0 or x >= s or y >= s:
				continue
			_rot_put(img, ox, oy, s, rot, x, y, c)


static func _paint_maze(img: Image, rng: RandomNumberGenerator, ink: Color) -> void:
	_fill(img, Color(0.965, 0.960, 0.950))
	var s: int = 32
	var cells: int = TEX / s
	var th: int = 3
	var gap: int = 6
	for cy in range(cells):
		for cx in range(cells):
			var ox: int = cx * s
			var oy: int = cy * s
			var rot: int = rng.randi_range(0, 3)
			var rings: int = rng.randi_range(2, 3)
			for j in range(rings):
				var d: int = 1 + j * (th + gap)
				var e: int = s - 1 - d - th
				if e - d < th * 2:
					break
				if j % 2 == 0:
					_cell_bar(img, ox, oy, s, rot, d, d, d, e, th, ink)
					_cell_bar(img, ox, oy, s, rot, d, d, e, d, th, ink)
					_cell_bar(img, ox, oy, s, rot, e, d, e, maxi(d, e - gap), th, ink)
				else:
					_cell_bar(img, ox, oy, s, rot, e, d, e, e, th, ink)
					_cell_bar(img, ox, oy, s, rot, d, e, e, e, th, ink)
					_cell_bar(img, ox, oy, s, rot, d, mini(e, d + gap), d, e, th, ink)
			# the seam line between cells, so the labyrinth reads continuous
			if rng.randf() < 0.7:
				_cell_bar(img, ox, oy, s, rot, 0, s - th, s - th, s - th, th, ink)


# --- mosaic -----------------------------------------------------------------

static func _paint_mosaic(img: Image, rng: RandomNumberGenerator, base: Color) -> void:
	var cols: int = 13
	var rows: int = 16
	var cw: float = float(TEX) / float(cols)
	var chh: float = float(TEX) / float(rows)
	var jx: Array = []
	var jy: Array = []
	var tint: Array = []
	for i in range(cols * rows):
		jx.append(rng.randf_range(-0.30, 0.30))
		jy.append(rng.randf_range(-0.22, 0.22))
		tint.append(rng.randf_range(0.78, 1.22))
	var grout := Color(0.955, 0.950, 0.945)
	for y in range(TEX):
		for x in range(TEX):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var c0: int = int(floor(px / cw))
			var r0: int = int(floor(py / chh))
			var d1: float = 1.0e9
			var d2: float = 1.0e9
			var best: int = 0
			for rr in range(r0 - 1, r0 + 2):
				var rw: int = posmod(rr, rows)
				for cc in range(c0 - 1, c0 + 2):
					var cwp: int = posmod(cc, cols)
					var idx: int = rw * cols + cwp
					var gx: float = (float(cc) + 0.5 + float(jx[idx])) * cw
					var gy: float = (float(rr) + 0.5 + float(jy[idx])) * chh
					var dx: float = px - gx
					var dy: float = (py - gy) * 1.10
					var dd: float = dx * dx + dy * dy
					if dd < d1:
						d2 = d1
						d1 = dd
						best = idx
					elif dd < d2:
						d2 = dd
			var edge: float = sqrt(maxf(d2, 0.0)) - sqrt(maxf(d1, 0.0))
			if edge < 2.6:
				img.set_pixel(x, y, grout)
			else:
				var k: float = float(tint[best])
				var shade: float = clampf(k * (0.90 + 0.16 * clampf(edge / 7.0, 0.0, 1.0)), 0.45, 1.45)
				img.set_pixel(x, y, Color(clampf(base.r * shade, 0.0, 1.0), clampf(base.g * shade, 0.0, 1.0), clampf(base.b * shade, 0.0, 1.0)))


# --- blobs, hearts, contour marks -------------------------------------------

static func _blob(img: Image, cx: float, cy: float, a: float, b: float, ang: float, c: Color) -> void:
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var rad: int = int(ceil(maxf(a, b))) + 2
	for y in range(-rad, rad + 1):
		for x in range(-rad, rad + 1):
			var dx: float = float(x)
			var dy: float = float(y)
			var u: float = (dx * ca + dy * sa) / maxf(a, 0.5)
			var v: float = (-dx * sa + dy * ca) / maxf(b, 0.5)
			if u * u + v * v <= 1.0:
				_put(img, int(round(cx)) + x, int(round(cy)) + y, c)


static func _heart_px(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	var rad: int = int(ceil(r * 1.40)) + 2
	for y in range(-rad, rad + 1):
		for x in range(-rad, rad + 1):
			var xf: float = float(x) / r
			var yf: float = -float(y) / r
			var q: float = xf * xf + yf * yf - 1.0
			if q * q * q - xf * xf * (yf * yf * yf) <= 0.0:
				_put(img, int(round(cx)) + x, int(round(cy)) + y, c)


static func _ring(img: Image, cx: float, cy: float, r: float, th: float, a0: float, a1: float, c: Color) -> void:
	var steps: int = int(ceil((a1 - a0) * r * 2.2)) + 6
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var ang: float = lerpf(a0, a1, t)
		var bx: float = cx + cos(ang) * r
		var by: float = cy + sin(ang) * r
		var ti: int = int(ceil(th))
		for y in range(-ti, ti + 1):
			for x in range(-ti, ti + 1):
				if float(x * x + y * y) <= th * th:
					_put(img, int(round(bx)) + x, int(round(by)) + y, c)


static func _paint_blobs(img: Image, rng: RandomNumberGenerator, pal: Array, ink: Color) -> void:
	_fill(img, Color(0.968, 0.964, 0.955))
	var n: int = rng.randi_range(16, 22)
	for i in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var c: Color = pal[rng.randi_range(0, pal.size() - 1)]
		var a: float = rng.randf_range(9.0, 24.0)
		var b: float = a * rng.randf_range(0.45, 1.0)
		var ang: float = rng.randf_range(0.0, PI)
		if rng.randf() < 0.35:
			_blob(img, cx, cy, a + 2.5, b + 2.5, ang, ink)
		_blob(img, cx, cy, a, b, ang, c)
	var n_h: int = rng.randi_range(2, 4)
	for i in range(n_h):
		var hx: float = rng.randf_range(0.0, float(TEX))
		var hy: float = rng.randf_range(0.0, float(TEX))
		var hr: float = rng.randf_range(10.0, 18.0)
		var hc: Color = pal[2] if rng.randf() < 0.5 else pal[pal.size() - 3]
		_heart_px(img, hx, hy, hr + 2.0, ink)
		_heart_px(img, hx, hy, hr, hc)
	var n_a: int = rng.randi_range(3, 6)
	for i in range(n_a):
		var ax: float = rng.randf_range(0.0, float(TEX))
		var ay: float = rng.randf_range(0.0, float(TEX))
		var ar: float = rng.randf_range(14.0, 34.0)
		var a0: float = rng.randf_range(0.0, TAU)
		_ring(img, ax, ay, ar, rng.randf_range(1.6, 3.2), a0, a0 + rng.randf_range(1.2, 3.4), ink)


# --- stripes ----------------------------------------------------------------

static func _paint_stripes(img: Image, rng: RandomNumberGenerator, pal: Array, ink: Color) -> void:
	var bands: int = rng.randi_range(5, 8)
	var band_c: Array[Color] = []
	for i in range(bands):
		if rng.randf() < 0.34:
			band_c.append(Color(0.968, 0.964, 0.955))
		else:
			band_c.append(pal[rng.randi_range(0, pal.size() - 1)])
	var bw: float = float(TEX) / float(bands)
	var amp: float = rng.randf_range(3.0, 13.0)
	var freq: float = float(rng.randi_range(1, 3)) * TAU / float(TEX)
	for y in range(TEX):
		var wob: float = amp * sin(float(y) * freq)
		for x in range(TEX):
			var u: float = float(x) + wob
			var bi: int = posmod(int(floor(u / bw)), bands)
			var frac: float = u / bw - floor(u / bw)
			var c: Color = band_c[bi]
			if frac < 0.055 or frac > 0.945:
				c = ink
			img.set_pixel(x, y, c)
