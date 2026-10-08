extends RefCounted

## dream_bodies / lava_bloom — one flowering bough lifted out of a lava forest.
##
## Reference: scratchpad/refs/lava_forest.png (2048x536 panorama) — a hillside of
## black molten rope-like roots and branches, matte and knotted, smothered in
## dense sprays of FLAT rounded petals in saturated yellow, magenta-pink and
## white, with small round sage-green leaves threaded between them.
##
## Reproduced, and how:
##   1. Molten rope wood — a recursive static helper (_grow, 5 levels) walks a
##      chain of 2..5 CapsuleMesh segments per branch whose direction is pushed
##      sideways every step by a perpendicular that ROTATES as it rises, so the
##      limb writhes instead of arcing; squashed knuckle spheres sit on the
##      joints of the lower three levels and each fork thins the wood by a third.
##   2. The knotted black surface — a 128x128 ImageTexture of domain-warped
##      periodic value noise, ridged (1 - |2n-1|) into thin rope highlights, hung
##      on uv1_world_triplanar so one swirl runs unbroken across the whole chain
##      of primitives; matte, roughness 0.92, no clearcoat.
##   3. The root tangle — 4..6 short chains leaving the base outward and down,
##      each clamped to rest ON the plinth, giving the bough the reference's
##      lava-crust footing.
##   4. Blossom sprays — 9..12 clusters at branch tips, each a tiny throat sphere
##      plus 5..8 FLAT petals: ArrayMesh rounded lobes (sine half-width profile,
##      bowed along the length and cupped across it, vertex-colour base-to-tip
##      gradient, double sided), scattered on a small sphere around the tip and
##      tilted at random angles, so the cluster reads as one blob of petals.
##   5. Palette by seed — one of five schemes, each a dominant colour with a
##      minority second (gold/pink, magenta/white, white/magenta, gold/white,
##      pink/gold); 2..3 clusters of the crown take the second colour.
##   6. Round green leaves — 6..10 nodes on the outer branches, each a hair-thin
##      stem carrying two flattened SphereMesh discs splayed apart.
##   7. A gesture — the trunk leans, the crown is weighted to the leaning side,
##      and about a third of the sprays hang downward as the reference's racemes
##      do; the tips that get no blossom stay bare black twigs.
##   8. Fit — a measured horizontal gather, then a uniform scale about the plinth
##      top to a seeded 1.40..1.62 m, then the settle pass.
##
## Given up: the FOREST (this is one bough, not a hillside), the ground mat of
## fallen leaves, the individual five-petalled florets inside each spray, and the
## reference's depth haze.
##
## GLOSS (2026-09-03) — every surface is now dealt through DreamSkin, from a
## THIRD private stream, so the geometry below is drawn exactly as it was and
## only the skin changed. The blossom is WET and the wood is not: petals take
## latex, patent, candy, holographic foil, pearl or wet, the throat behind them
## is neon or candy and glows out of the middle of the spray, the leaves and
## stems are latex, the flood's pour is wet, the cage's armillaries are pearl and
## the coronet blades are patent or holo. The MATTE PASSAGE is the lava crust and
## the plinth: the black rope wood stays roughness 0.92 in three seeds out of
## five (the other two catch the bough still molten — wet, or patent obsidian),
## and the plinth is stone. Flat gold and white are gone, because ACES eats them:
## the five schemes now name colours in DreamSkin.QUEER, so the reference's
## gold/magenta/white reads lemon, hot pink and cream, and two of the five are
## tangerine-violet and lilac-cyan. The wood hexes are pulled 45% toward ink, so
## the crust is blacker and the blossom is the only bright thing on the plinth.
##
## AXES (DNA), both cutting the silhouette, not the palette:
##   bough — what the molten wood IS. writhe (the reference bough) · melt (every
##     limb sags under its own heat, the crown crawls down onto the plinth and
##     flattened puddles spread around the foot) · mirror (a second inverted
##     bough erupts sideways out of the trunk and grows its own crown) ·
##     unravel (each limb comes apart into three thin braided threads and the
##     knuckles are gone) · triune (one root tangle carries three splayed boughs)
##     · fused (the bough GROWN and not assembled — see below).
##   bloom — what the sprays ARE. spray (blobs of flat petals) · flood (the
##     blossom melts into hanging drips and the lower body is swallowed by a
##     solid pour with molten lobes at its rim) · cage (the flesh is gone —
##     every flower is a bone-white armillary of three wire rings round a dark
##     seed, and no leaves are left) · crown (tips shrink to bare buds and the
##     whole crown fuses into one coronet ring of standing blades).
##
## FUSED (bough) — the same _grow walk, laid into a FIELD instead of into the
## tree. Each limb becomes a DreamIso capsule between the same two joints and
## each root the same, smooth-unioned at blend 0.13 and marched at 58 mm: the
## limbs swell into the trunk with a fillet, a fork is a place the field bulged
## rather than two capsules crossing, and the knuckle spheres are gone because
## the fillet IS the knuckle. The skeleton is reduced to fit a field — three
## roots, thirteen branches, segments of one or two — and every radius has a
## floor of 45 mm, because a pour has ONE viscosity: the fused bough grows no
## fine twigs, every limb ends about as thick as it began. Two cut spheres bite
## the trunk at its own recorded level-0 joints: gas voids the pour closed
## around, holes that are not missing pieces but places the field never crossed
## zero. The body is ONE MeshInstance3D in oil slick, wet or patent, so the value
## pays its 40-mesh floor in primitives — the blossom, the leaves, and twenty-two
## crust beads spattered round the foot where the pour hit the plinth, one bead
## in three still wet. Those beads are what carry the leanest pairing,
## fused+cage, over forty meshes on its own. THE MESHER IS NEW: if
## DreamIso.mesh_of hands back null, the same reduced skeleton is drawn as
## capsules and knuckles instead, fat-limbed, and the plinth is never empty.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX_SIZE: int = 128
const PETAL_TEX: int = 64
const PLINTH_TOP: float = 0.055
const MAX_MESH: int = 242
const HALF_SPAN: float = 0.53

# fused: the field's budget, and the pour's one viscosity
const ISO_PARTS: int = 40
const ISO_MIN_R: float = 0.045
const ISO_SWELL: float = 1.12
const ISO_CELL: float = 0.058
const ISO_BLEND: float = 0.13
const ISO_SPATTER: int = 22

# [dominant, second, throat, leaf] — keys into DreamSkin.QUEER
const BLOOM_KEYS: Array = [
	["hot_pink", "lemon", "cream", "mint"],
	["magenta", "cream", "lemon", "acid"],
	["lemon", "hot_pink", "cream", "mint"],
	["tangerine", "violet", "lemon", "acid"],
	["lilac", "cyan", "cream", "mint"],
]

const WOOD_HEXES: Array = ["#4A454F", "#433F4A", "#514A57"]

# the crust is the matte passage — but two seeds in five catch it still molten
const WOOD_FINISHES: Array = ["matte", "matte", "matte", "wet", "patent"]
const PETAL_FINISHES: Array = ["latex", "patent", "candy", "holo", "wet", "pearl"]
const THROAT_FINISHES: Array = ["neon", "candy"]
const BLADE_FINISHES: Array = ["patent", "holo"]
const BODY_FINISHES: Array = ["oilslick", "wet", "patent"]


static func axes() -> Dictionary:
	return {
		"bough": ["writhe", "melt", "mirror", "unravel", "triune", "fused"],
		"bloom": ["spray", "flood", "cage", "crown"],
	}


static func describe() -> String:
	return "One bough of the lava forest: a black molten trunk writhing up through five forks, its root tangle crusted on the plinth, smothered near the top in wet-glossed sprays of hot pink, lemon and cream around a throat that glows, with small round latex leaves between them."


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var bough: String = String(opts.get("bough", "writhe"))
	var bloom: String = String(opts.get("bloom", "spray"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# a private stream for the variants, so the default draws exactly as before
	var vrng := RandomNumberGenerator.new()
	vrng.seed = seed + 104729
	# and a third for the gloss, so the SHAPES are drawn exactly as before too
	var grng := RandomNumberGenerator.new()
	grng.seed = seed + 401537

	var keys_row: Array = BLOOM_KEYS[rng.randi_range(0, BLOOM_KEYS.size() - 1)]
	var col_main: Color = Gloss.QUEER[str(keys_row[0])]
	var col_second: Color = Gloss.QUEER[str(keys_row[1])]
	var col_throat: Color = Gloss.QUEER[str(keys_row[2])]
	var col_leaf: Color = Gloss.QUEER[str(keys_row[3])]
	var col_ink: Color = Gloss.QUEER["ink"]
	var col_wood: Color = Color(str(WOOD_HEXES[rng.randi_range(0, WOOD_HEXES.size() - 1)])).lerp(col_ink, 0.45)

	# the three painted textures, drawn from the SHAPE stream in the old order
	var wood_tex: ImageTexture = _wood_texture(rng)
	var leaf_tex: ImageTexture = _soft_texture(rng, 0.0)
	var petal_tex: ImageTexture = _soft_texture(rng, 0.16)

	# --- the gloss, dealt ----------------------------------------------------
	var wood_finish: String = str(WOOD_FINISHES[grng.randi_range(0, WOOD_FINISHES.size() - 1)])
	var petal_finish: String = str(PETAL_FINISHES[grng.randi_range(0, PETAL_FINISHES.size() - 1)])
	var throat_finish: String = str(THROAT_FINISHES[grng.randi_range(0, THROAT_FINISHES.size() - 1)])
	var blade_finish: String = str(BLADE_FINISHES[grng.randi_range(0, BLADE_FINISHES.size() - 1)])
	var body_finish: String = str(BODY_FINISHES[grng.randi_range(0, BODY_FINISHES.size() - 1)])

	# --- materials ----------------------------------------------------------
	# the crust: matte lava rope, or a bough that has not finished cooling
	var mat_wood: StandardMaterial3D = _gloss(wood_finish, col_wood, grng, wood_tex, 0.0)
	mat_wood.uv1_triplanar = true
	mat_wood.uv1_world_triplanar = true
	mat_wood.uv1_scale = Vector3(3.4, 3.4, 3.4)

	var mat_knot: StandardMaterial3D = _gloss(wood_finish, col_wood.darkened(0.18), grng, wood_tex, 0.0)
	mat_knot.uv1_triplanar = true
	mat_knot.uv1_world_triplanar = true
	mat_knot.uv1_scale = Vector3(4.6, 4.6, 4.6)

	var mat_stem: StandardMaterial3D = _gloss("latex", col_leaf.darkened(0.55), grng, null, 0.0)
	var mat_leaf: StandardMaterial3D = _gloss("latex", col_leaf, grng, leaf_tex, 0.0)
	var mat_throat: StandardMaterial3D = _gloss(throat_finish, col_throat, grng, null, 0.0)

	# the plinth stays stone: the other half of the contrast
	var mat_plinth: StandardMaterial3D = _gloss("matte", Color("#C7CAC4"), grng, null, 0.0)
	mat_plinth.roughness = 0.88

	# the two petal skins, one per scheme colour, reused by every cluster
	var mat_petal_main: StandardMaterial3D = _petal_skin(petal_finish, col_main, grng, petal_tex)
	var mat_petal_second: StandardMaterial3D = _petal_skin(petal_finish, col_second, grng, petal_tex)

	# --- materials the axes reach for (built always, they draw no shape rng) -
	var mat_bone: StandardMaterial3D = _gloss("pearl", Color("#DFD6C2"), grng, leaf_tex, 0.0)
	var mat_pour: StandardMaterial3D = _gloss("wet", col_main.darkened(0.12), grng, petal_tex, 0.0)
	var mat_crown: StandardMaterial3D = _petal_skin(blade_finish, col_main, grng, petal_tex)

	# the fused body: black lava under an oil film, or still wet, or gone glassy
	var mat_fused: StandardMaterial3D = _gloss(body_finish, col_wood.lerp(col_main, 0.25), grng, wood_tex, 0.0)
	mat_fused.uv1_triplanar = true
	mat_fused.uv1_world_triplanar = false
	mat_fused.uv1_scale = Vector3(1.8, 1.8, 1.8)

	# --- individual parameters ---------------------------------------------
	var lean_roll: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.13, 0.26)
	var trunk_len: float = rng.randf_range(0.40, 0.48)
	var trunk_rad: float = rng.randf_range(0.066, 0.082)
	var n_roots: int = rng.randi_range(4, 6)
	var target_h: float = rng.randf_range(1.40, 1.62)
	var n_cluster_want: int = rng.randi_range(9, 12)
	var n_leaf_nodes: int = rng.randi_range(6, 10)
	var second_count: int = rng.randi_range(2, 3)

	var ctx: Dictionary = {
		"root": root,
		"rng": rng,
		"count": 0,
		"branches": 0,
		"max_branches": rng.randi_range(23, 27),
		"mat_wood": mat_wood,
		"mat_knot": mat_knot,
		"tips": [],
		"leaf_spots": [],
		"segs": [5, 4, 3, 3, 2],
		"gnarl": rng.randf_range(0.30, 0.46),
		"twist": rng.randf_range(0.55, 1.10),
		"taper": rng.randf_range(0.74, 0.84),
		"up_pull": rng.randf_range(0.16, 0.30),
		"floor_y": PLINTH_TOP,
	}

	# --- axis: bough — how the molten wood behaves --------------------------
	var thread_wood: bool = false
	if bough == "melt":
		ctx["sag"] = 0.175
		ctx["up_pull"] = 0.02
		ctx["taper"] = 0.96
		trunk_rad *= 1.34
	elif bough == "unravel":
		thread_wood = true
		ctx["thread_phase"] = 0.0
		ctx["gnarl"] = float(ctx["gnarl"]) * 1.35
		ctx["taper"] = 0.68
		ctx["max_branches"] = 11
		trunk_rad *= 1.18
	elif bough == "mirror":
		ctx["max_branches"] = 13
	elif bough == "triune":
		ctx["max_branches"] = 9
		trunk_rad *= 0.82
		trunk_len *= 0.90
	elif bough == "fused":
		# a field, not a tree: a shorter walk with fat limbs, and a radius floor,
		# because a pour has one viscosity and cannot taper to a twig
		ctx["segs"] = [2, 2, 1, 1, 1]
		ctx["max_branches"] = 13
		ctx["root_segs"] = 2
		ctx["min_r"] = ISO_MIN_R
		ctx["taper"] = 0.90
		ctx["up_pull"] = 0.22
		trunk_rad *= 1.55
		n_roots = 3

	var lean_dir := Vector3(cos(lean_roll) * lean_amt, 1.0, sin(lean_roll) * lean_amt).normalized()
	var base := Vector3(-lean_dir.x * 0.10, PLINTH_TOP, -lean_dir.z * 0.10)

	# --- root tangle, then the bough ----------------------------------------
	var fused: bool = bough == "fused"
	if fused:
		# the same walk, laid into an SDF instead of into the tree
		ctx["iso"] = true
		ctx["iso_parts"] = []
		ctx["trunk_pts"] = []

	_roots(ctx, base, trunk_rad, n_roots, mat_wood, mat_knot)

	# the roots keep their crust in every variant; only the bough unravels
	if thread_wood:
		ctx["unravel"] = true

	_bough_of(ctx, bough, base, lean_dir, lean_roll, trunk_len, trunk_rad)

	# --- fused: march the field, and check, because the mesher is new -------
	if fused:
		var parts: Array = ctx["iso_parts"]
		# gas voids the pour closed around: holes where the field never crossed
		# zero, bitten out of the trunk's own recorded joints
		var tps: Array = ctx["trunk_pts"]
		for i in range(mini(2, tps.size())):
			var vat: Vector3 = tps[i]
			var voff: Vector3 = _perp(lean_dir, grng.randf_range(0.0, TAU))
			var vrad: float = trunk_rad * grng.randf_range(1.00, 1.25)
			parts.append(Iso.cut(Iso.sphere(vat + voff * (trunk_rad * 1.02), vrad)))
		ctx["iso"] = false
		var iso_mesh: ArrayMesh = Iso.mesh_of(parts, ISO_CELL, ISO_BLEND, 0.05)
		if iso_mesh != null:
			var body_mi: MeshInstance3D = _add(ctx, iso_mesh, mat_fused)
			body_mi.transform = Transform3D(Basis(), Vector3.ZERO)
		else:
			# the field would not mesh: draw the same reduced skeleton in
			# primitives, so the plinth is never empty
			ctx["branches"] = 0
			ctx["tips"] = []
			ctx["leaf_spots"] = []
			_roots(ctx, base, trunk_rad, n_roots, mat_wood, mat_knot)
			_bough_of(ctx, bough, base, lean_dir, lean_roll, trunk_len, trunk_rad)
		# push the tips clear of a surface that is thicker than the skeleton
		var ftips: Array = ctx["tips"]
		for i in range(ftips.size()):
			var ft: Array = ftips[i]
			var fp: Vector3 = ft[0]
			var fd: Vector3 = ft[1]
			ft[0] = fp + fd * (ISO_MIN_R * 1.1)
		# the trimmings: crust beads where the pour hit the plinth
		var sbox: AABB = _union_aabb(root)
		var s_reach: float = maxf(maxf(sbox.size.x, sbox.size.z) * 0.42, 0.16)
		_spatter(ctx, base, ISO_SPATTER, mat_knot, mat_fused, grng, s_reach)

	# --- melt: the heat that came down the limbs pools on the plinth --------
	if bough == "melt":
		var pud_box: AABB = _union_aabb(root)
		var pud_c: Vector3 = base
		var pud_reach: float = maxf(maxf(pud_box.size.x, pud_box.size.z) * 0.46, 0.14)
		for i in range(12):
			if not _can(ctx):
				break
			var pa: float = vrng.randf_range(0.0, TAU)
			var pr: float = vrng.randf_range(0.06, 1.0) * pud_reach
			var ps: float = vrng.randf_range(0.055, 0.135)
			var pud := SphereMesh.new()
			pud.radius = ps
			pud.height = ps * 2.0
			pud.radial_segments = 14
			pud.rings = 7
			var pud_mi: MeshInstance3D = _add(ctx, pud, mat_knot)
			var pud_b := Basis(Vector3(1.30, 0.0, 0.0), Vector3(0.0, 0.17, 0.0), Vector3(0.0, 0.0, 1.30))
			pud_mi.transform = Transform3D(pud_b, Vector3(pud_c.x + cos(pa) * pr, PLINTH_TOP + ps * 0.17, pud_c.z + sin(pa) * pr))

	# --- blossom clusters ---------------------------------------------------
	var tips: Array = ctx["tips"]
	var order: Array = []
	for i in range(tips.size()):
		order.append(i)
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = int(order[i])
		order[i] = order[j]
		order[j] = tmp
	var n_cluster: int = mini(n_cluster_want, order.size())
	if bloom == "cage":
		# the flesh is cheap once it is gone — every tip gets its ghost
		n_cluster = order.size()
	for c in range(n_cluster):
		if not _can(ctx):
			break
		var tip: Array = tips[int(order[c])]
		var t_pos: Vector3 = tip[0]
		var t_dir: Vector3 = tip[1]
		var use_second: bool = c < second_count
		var mat_petal: StandardMaterial3D = mat_petal_second if use_second else mat_petal_main
		if bloom == "flood":
			_drip(ctx, t_pos, mat_petal, mat_throat, vrng)
		elif bloom == "cage":
			_cage(ctx, t_pos, t_dir, mat_bone, mat_knot, vrng)
		elif bloom == "crown":
			_bud(ctx, t_pos, t_dir, mat_petal, vrng)
		else:
			_cluster(ctx, t_pos, t_dir, mat_petal, mat_throat, rng)

	# --- round leaves -------------------------------------------------------
	var spots: Array = ctx["leaf_spots"]
	var sorder: Array = []
	for i in range(spots.size()):
		sorder.append(i)
	for i in range(sorder.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = int(sorder[i])
		sorder[i] = sorder[j]
		sorder[j] = tmp
	var n_leaf: int = mini(n_leaf_nodes, sorder.size())
	if bloom == "cage":
		# nothing soft survives the fossil
		n_leaf = 0
	for c in range(n_leaf):
		if not _can(ctx):
			break
		var spot: Array = spots[int(sorder[c])]
		var s_pos: Vector3 = spot[0]
		var s_dir: Vector3 = spot[1]
		var s_rad: float = float(spot[2])
		var out_v: Vector3 = _perp(s_dir, rng.randf_range(0.0, TAU))
		var stem_d: Vector3 = (out_v * 0.85 + Vector3.UP * rng.randf_range(-0.25, 0.55)).normalized()
		var stem_a: Vector3 = s_pos + out_v * (s_rad * 0.7)
		var stem_b: Vector3 = stem_a + stem_d * rng.randf_range(0.030, 0.058)
		_tapered_cyl(ctx, stem_a, stem_b, 0.0042, 0.0030, mat_stem)
		for k in range(2):
			if not _can(ctx):
				break
			var sgn: float = -1.0 if k == 0 else 1.0
			var side: Vector3 = _perp(stem_d, rng.randf_range(0.0, TAU))
			var lf_d: Vector3 = (stem_d * 0.55 + side * sgn * 0.85).normalized()
			var lr: float = rng.randf_range(0.021, 0.032)
			var disc := SphereMesh.new()
			disc.radius = lr
			disc.height = lr * 2.0
			disc.radial_segments = 12
			disc.rings = 6
			var lm: MeshInstance3D = _add(ctx, disc, mat_leaf)
			var lb: Basis = _basis_y_to(lf_d) * Basis(Vector3(1.06, 0.0, 0.0), Vector3(0.0, 0.11, 0.0), Vector3(0.0, 0.0, 0.92))
			lm.transform = Transform3D(lb, stem_b + lf_d * (lr * 0.75))

	# --- flood: a solid pour swallows the roots and the lower trunk ---------
	if bloom == "flood":
		var fb: AABB = _union_aabb(root)
		var fc: Vector3 = base
		var lake_r: float = maxf(maxf(fb.size.x, fb.size.z) * 0.36, 0.18)
		var lake_h: float = maxf(fb.size.y * 0.44, 0.12)
		var lake := CylinderMesh.new()
		lake.top_radius = lake_r * 0.84
		lake.bottom_radius = lake_r
		lake.height = lake_h
		lake.radial_segments = 30
		lake.rings = 2
		var lake_mi: MeshInstance3D = _add_forced(root, lake, mat_pour)
		lake_mi.transform = Transform3D(Basis(), Vector3(fc.x, PLINTH_TOP + lake_h * 0.5, fc.z))
		for i in range(6):
			if not _can(ctx):
				break
			var la: float = vrng.randf_range(0.0, TAU)
			var lk: float = vrng.randf_range(0.30, 0.62)
			var lob := SphereMesh.new()
			lob.radius = lake_r * lk
			lob.height = lake_r * lk * 2.0
			lob.radial_segments = 16
			lob.rings = 8
			var lob_mi: MeshInstance3D = _add(ctx, lob, mat_pour)
			var lob_b := Basis(Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.44, 0.0), Vector3(0.0, 0.0, 1.0))
			var lob_y: float = PLINTH_TOP + lake_h * vrng.randf_range(0.12, 0.74)
			lob_mi.transform = Transform3D(lob_b, Vector3(fc.x + cos(la) * lake_r * 0.86, lob_y, fc.z + sin(la) * lake_r * 0.86))

	# --- crown: every petal the bough gave up, fused into one coronet -------
	if bloom == "crown":
		var cb: AABB = _union_aabb(root)
		var cc: Vector3 = cb.position + cb.size * 0.5
		var ring_y: float = cb.position.y + cb.size.y * 0.87
		var ring_r: float = maxf(maxf(cb.size.x, cb.size.z) * 0.46, 0.16)
		var tor := TorusMesh.new()
		tor.inner_radius = ring_r * 0.90
		tor.outer_radius = ring_r * 1.02
		tor.rings = 8
		tor.ring_segments = 40
		var tor_mi: MeshInstance3D = _add_forced(root, tor, mat_throat)
		# hang it over where the tips actually are, not over the whole body
		var ring_c := Vector3(cc.x, ring_y, cc.z)
		var t_sum := Vector3.ZERO
		var t_n: int = 0
		for ti in range(tips.size()):
			var tp: Array = tips[ti]
			var tv: Vector3 = tp[0]
			t_sum += tv
			t_n += 1
		if t_n > 0:
			var t_mean: Vector3 = t_sum / float(t_n)
			ring_c = Vector3(t_mean.x, ring_y, t_mean.z)
		tor_mi.transform = Transform3D(Basis(), ring_c)
		var n_blade: int = 16
		for i in range(n_blade):
			if not _can(ctx):
				break
			var ba: float = float(i) / float(n_blade) * TAU + vrng.randf_range(-0.06, 0.06)
			var out_ring := Vector3(cos(ba), 0.0, sin(ba))
			var bl: float = ring_r * vrng.randf_range(0.58, 1.00)
			var bw: float = bl * vrng.randf_range(0.42, 0.70)
			var c_low := Color(0.66, 0.64, 0.62)
			var c_hi := Color(1.0, 0.99, 0.97)
			var blade: ArrayMesh = _petal(bl, bw, bl * 0.16, bw * 0.12, c_low, c_hi)
			var yv: Vector3 = (Vector3.UP * 2.3 + out_ring * vrng.randf_range(0.30, 1.05)).normalized()
			var zv: Vector3 = out_ring - yv * out_ring.dot(yv)
			if zv.length() < 0.001:
				zv = Vector3.FORWARD
			zv = zv.normalized()
			var xv: Vector3 = yv.cross(zv).normalized()
			var blade_mi: MeshInstance3D = _add(ctx, blade, mat_crown)
			blade_mi.transform = Transform3D(Basis(xv, yv, zv), ring_c + out_ring * (ring_r * 0.96))

	# --- fit height, gather the crown in, clamp, centre, plinth, settle -----
	var pivot := Vector3(0.0, PLINTH_TOP, 0.0)
	var box: AABB = _union_aabb(root)
	var k_h: float = (target_h - PLINTH_TOP) / maxf(box.size.y, 0.01)
	_scale_about(root, pivot, k_h)

	box = _union_aabb(root)
	var span: float = maxf(box.size.x, box.size.z)
	if span > HALF_SPAN * 2.0:
		var g: float = (HALF_SPAN * 2.0) / maxf(span, 0.01)
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var o: Vector3 = cm.transform.origin
			cm.transform = Transform3D(cm.transform.basis, Vector3(o.x * g, o.y, o.z * g))
		box = _union_aabb(root)

	var k_x: float = 1.22 / maxf(box.size.x, 0.01)
	var k_z: float = 1.22 / maxf(box.size.z, 0.01)
	var kfit: float = minf(1.0, minf(k_x, k_z))
	if kfit < 1.0:
		_scale_about(root, pivot, kfit)

	box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, PLINTH_TOP - box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)

	box = _union_aabb(root)
	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.22, box.size.x + 0.10), PLINTH_TOP, minf(1.22, box.size.z + 0.10))
	var pm: MeshInstance3D = _add_forced(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))

	# measured settle: nothing below y = 0
	var final_box: AABB = _union_aabb(root)
	if final_box.position.y < 0.0:
		var lift: float = -final_box.position.y
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + Vector3(0.0, lift, 0.0))


# ---------------------------------------------------------------------------
# growth

## The lava-crust footing. Factored out because the fused value walks it twice:
## once into the field, and again as primitives if the mesher hands back null.
static func _roots(ctx: Dictionary, base: Vector3, trunk_rad: float, n_roots: int,
		mat_wood: StandardMaterial3D, mat_knot: StandardMaterial3D) -> void:
	var rng: RandomNumberGenerator = ctx["rng"]
	var n_seg: int = int(ctx.get("root_segs", 3))
	for i in range(n_roots):
		var a: float = float(i) / float(n_roots) * TAU + rng.randf_range(-0.35, 0.35)
		var out_v := Vector3(cos(a), 0.0, sin(a)).normalized()
		var rp: Vector3 = base + out_v * (trunk_rad * 0.55) + Vector3(0.0, trunk_rad * 0.7, 0.0)
		var rd: Vector3 = (out_v * 1.0 + Vector3.DOWN * rng.randf_range(0.30, 0.70)).normalized()
		var rr: float = trunk_rad * rng.randf_range(0.52, 0.74)
		for s in range(n_seg):
			if not _can(ctx):
				break
			var f: float = float(s) / float(n_seg)
			var side: Vector3 = _perp(rd, a * 2.0 + f * 3.0)
			rd = (rd + side * 0.34 + out_v * 0.16).normalized()
			var seg: float = rng.randf_range(0.075, 0.115)
			var nxt: Vector3 = rp + rd * seg
			var r_here: float = lerpf(rr, rr * 0.45, f)
			var y_min: float = PLINTH_TOP + r_here * 0.85
			if nxt.y < y_min:
				nxt = Vector3(nxt.x, y_min, nxt.z)
				rd = Vector3(rd.x, maxf(rd.y, 0.0), rd.z).normalized()
			_limb(ctx, rp, nxt, r_here, mat_wood)
			if s == 0 and _can(ctx):
				_knot(ctx, rp, rd, r_here * 1.35, mat_knot)
			rp = nxt


## The bough itself, by axis value. fused takes the plain trunk: the merging is
## in the field, not in the walk.
static func _bough_of(ctx: Dictionary, bough: String, base: Vector3, lean_dir: Vector3,
		lean_roll: float, trunk_len: float, trunk_rad: float) -> void:
	var rng: RandomNumberGenerator = ctx["rng"]
	if bough == "triune":
		for t in range(3):
			ctx["max_branches"] = 9 + t * 8
			var ta: float = lean_roll + float(t) * TAU / 3.0
			var td := Vector3(cos(ta) * 0.34, 1.0, sin(ta) * 0.34).normalized()
			_grow(ctx, base, td, trunk_len * (0.84 + 0.11 * float(t)), trunk_rad, 0, 4, ta)
	else:
		_grow(ctx, base, lean_dir, trunk_len, trunk_rad, 0, 4, rng.randf_range(0.0, TAU))
		if bough == "mirror":
			# a second body growing out of the first: it leaves the trunk the
			# other way and hangs before the up-pull hauls its own crown back up
			ctx["max_branches"] = 26
			var mbase: Vector3 = base + lean_dir * (trunk_len * 0.52)
			var mdir := Vector3(-lean_dir.x * 4.0, -0.50, -lean_dir.z * 4.0).normalized()
			_grow(ctx, mbase, mdir, trunk_len * 0.94, trunk_rad * 0.80, 0, 4, lean_roll + PI)


static func _grow(ctx: Dictionary, base: Vector3, dir: Vector3, ln: float, rad: float, level: int, max_level: int, phase: float) -> void:
	var rng: RandomNumberGenerator = ctx["rng"]
	ctx["branches"] = int(ctx["branches"]) + 1
	var segs: Array = ctx["segs"]
	var n_seg: int = int(segs[mini(level, segs.size() - 1)])
	var d: Vector3 = dir.normalized()
	var p: Vector3 = base
	var seg_len: float = ln / float(n_seg)
	var gnarl: float = float(ctx["gnarl"])
	var twist: float = float(ctx["twist"])
	var taper: float = float(ctx["taper"])
	var up_pull: float = float(ctx["up_pull"])
	var floor_y: float = float(ctx["floor_y"])
	# melt: a downward drag that compounds with depth, so the crown sags hardest
	var sag: float = float(ctx.get("sag", 0.0)) * float(level + 1)
	var threads: bool = bool(ctx.get("unravel", false))

	for s in range(n_seg):
		if not _can(ctx):
			return
		var f: float = float(s) / float(n_seg)
		var ang: float = phase + f * twist * TAU
		var side: Vector3 = _perp(d, ang)
		var pull: float = up_pull * (1.0 - float(level) / float(max_level + 2))
		d = (d + side * gnarl + Vector3.UP * pull - Vector3.UP * sag).normalized()
		var r_here: float = lerpf(rad, rad * taper, f)
		var nxt: Vector3 = p + d * seg_len
		if nxt.y < floor_y + r_here:
			nxt = Vector3(nxt.x, floor_y + r_here, nxt.z)
			d = (nxt - p).normalized()
		_limb(ctx, p, nxt, r_here, ctx["mat_wood"])
		if level <= 2 and s % 2 == 1 and not threads and _can(ctx):
			_knot(ctx, nxt, d, r_here * 1.34, ctx["mat_knot"])
		if bool(ctx.get("iso", false)) and level == 0:
			# the trunk's own joints, so the gas voids are bitten where the wood
			# actually is and not where a straight line guessed it would be
			var tps: Array = ctx["trunk_pts"]
			tps.append(nxt)
		if level >= 2 and rng.randf() < 0.55:
			var spots: Array = ctx["leaf_spots"]
			spots.append([nxt, d, maxf(r_here, float(ctx.get("min_r", 0.0)))])
		p = nxt

	var rad_end: float = rad * taper
	var tips: Array = ctx["tips"]
	if level >= max_level or int(ctx["branches"]) >= int(ctx["max_branches"]):
		tips.append([p, d, rad_end])
		return

	# levels 0..2 always fork, so the crown always carries at least eight tips
	var n_child: int = 2
	if level == 0:
		n_child = 3 if rng.randf() < 0.35 else 2
	elif level == 3:
		n_child = 2 if rng.randf() < 0.75 else 1

	var roll: float = rng.randf_range(0.0, TAU)
	var fork: float = deg_to_rad(rng.randf_range(20.0, 38.0)) * (1.0 if n_child > 1 else 0.45)
	for c in range(n_child):
		if int(ctx["branches"]) >= int(ctx["max_branches"]):
			tips.append([p, d, rad_end])
			return
		var a2: float = fork * rng.randf_range(0.72, 1.28)
		var ax: Vector3 = _perp(d, roll + float(c) * TAU / float(n_child))
		var cd: Vector3 = (d * cos(a2) + ax * sin(a2)).normalized()
		cd = (cd + Vector3.UP * 0.14).normalized()
		var c_len: float = ln * rng.randf_range(0.62, 0.80)
		var c_rad: float = rad_end * rng.randf_range(0.60, 0.74)
		_grow(ctx, p, cd, c_len, c_rad, level + 1, max_level, rng.randf_range(0.0, TAU))


static func _cluster(ctx: Dictionary, centre: Vector3, out_dir: Vector3, mat_petal: StandardMaterial3D, mat_throat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var c_rad: float = rng.randf_range(0.048, 0.076)
	var droop: float = -0.55 if rng.randf() < 0.34 else 0.22
	var n_pet: int = rng.randi_range(5, 8)

	var throat := SphereMesh.new()
	throat.radius = c_rad * 0.30
	throat.height = c_rad * 0.60
	throat.radial_segments = 10
	throat.rings = 6
	var tm: MeshInstance3D = _add(ctx, throat, mat_throat)
	tm.transform = Transform3D(Basis(), centre)

	for i in range(n_pet):
		if not _can(ctx):
			return
		var u: Vector3 = _rand_dir(rng)
		var bias: Vector3 = (u + out_dir * 0.55 + Vector3.UP * droop).normalized()
		var off: Vector3 = bias * (c_rad * rng.randf_range(0.20, 1.0))
		var pdir: Vector3 = (bias * 0.72 + _rand_dir(rng) * 0.48).normalized()
		var nrm: Vector3 = _perp(pdir, rng.randf_range(0.0, TAU))
		var bx: Vector3 = pdir.cross(nrm).normalized()
		var pl: float = c_rad * rng.randf_range(0.72, 1.10)
		var pw: float = pl * rng.randf_range(0.62, 0.92)
		var shade: float = rng.randf_range(0.80, 1.0)
		var c_low := Color(0.70 * shade, 0.68 * shade, 0.66 * shade)
		var c_hi := Color(1.0 * shade, 0.99 * shade, 0.97 * shade)
		var mesh: ArrayMesh = _petal(pl, pw, pl * rng.randf_range(0.10, 0.22), pw * rng.randf_range(0.06, 0.18), c_low, c_hi)
		var mi: MeshInstance3D = _add(ctx, mesh, mat_petal)
		mi.transform = Transform3D(Basis(bx, pdir, nrm), centre + off)


# ---------------------------------------------------------------------------
# mesh helpers

static func _can(ctx: Dictionary) -> bool:
	if bool(ctx.get("iso", false)):
		# in the field the budget is PARTS, not meshes: the march samples a grid,
		# so a walk that keeps growing costs the whole grid again
		var parts: Array = ctx["iso_parts"]
		return parts.size() < ISO_PARTS
	return int(ctx["count"]) < MAX_MESH


static func _add(ctx: Dictionary, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	ctx["count"] = int(ctx["count"]) + 1
	return _add_forced(ctx["root"], mesh, mat)


static func _add_forced(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _limb(ctx: Dictionary, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	# the pour's floor: below it the march cannot resolve a limb anyway
	var rr: float = maxf(r, float(ctx.get("min_r", 0.0)))
	if bool(ctx.get("iso", false)):
		# no mesh — the limb becomes a capsule in the field, and the smooth union
		# swells it into whatever it meets
		var parts: Array = ctx["iso_parts"]
		parts.append(Iso.capsule(a, b, rr * ISO_SWELL, rr * ISO_SWELL))
		return null
	if bool(ctx.get("unravel", false)):
		return _threads(ctx, a, b, rr, mat)
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var cap := CapsuleMesh.new()
	cap.radius = rr
	cap.height = ln + rr * 2.0
	cap.radial_segments = 10
	cap.rings = 3
	var mi: MeshInstance3D = _add(ctx, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _threads(ctx: Dictionary, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	# the limb comes apart: three thin strands round where the rope used to be,
	# each ending one third of a turn on from where it started, so consecutive
	# segments braid instead of lining up
	var d: Vector3 = b - a
	var ph: float = float(ctx.get("thread_phase", 0.0))
	ctx["thread_phase"] = ph + 1.05
	var tr: float = maxf(r * 0.26, 0.0035)
	var off: float = r * 0.88
	var last: MeshInstance3D = null
	for k in range(3):
		if not _can(ctx):
			break
		var ang: float = ph + float(k) * TAU / 3.0
		var pa: Vector3 = a + _perp(d, ang) * off
		var pb: Vector3 = b + _perp(d, ang + 1.05) * off
		var dd: Vector3 = pb - pa
		var ln: float = maxf(dd.length(), 0.006)
		var cap := CapsuleMesh.new()
		cap.radius = tr
		cap.height = ln + tr * 2.0
		cap.radial_segments = 6
		cap.rings = 2
		var mi: MeshInstance3D = _add(ctx, cap, mat)
		mi.transform = Transform3D(_basis_y_to(dd), (pa + pb) * 0.5)
		last = mi
	return last


static func _drip(ctx: Dictionary, at: Vector3, mat_petal: StandardMaterial3D, mat_throat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# flood: the spray has run — a chain of stretching beads falls off the tip
	var n: int = rng.randi_range(4, 6)
	var r0: float = rng.randf_range(0.030, 0.054)
	var sway := Vector3(rng.randf_range(-0.018, 0.018), 0.0, rng.randf_range(-0.018, 0.018))
	var p: Vector3 = at
	for i in range(n):
		if not _can(ctx):
			return
		var f: float = float(i) / float(n)
		var r: float = lerpf(r0, r0 * 0.22, f)
		var bead := SphereMesh.new()
		bead.radius = r
		bead.height = r * 2.0 * (1.0 + f * 1.7)
		bead.radial_segments = 12
		bead.rings = 7
		var m: StandardMaterial3D = mat_throat if i == 0 else mat_petal
		var mi: MeshInstance3D = _add(ctx, bead, m)
		mi.transform = Transform3D(Basis(), p)
		p = p + Vector3(0.0, -(r * 1.55), 0.0) + sway


static func _cage(ctx: Dictionary, centre: Vector3, out_dir: Vector3, mat_bone: StandardMaterial3D, mat_seed: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# fossil: the petals are gone and the armature they hung on is left standing
	var c_rad: float = rng.randf_range(0.052, 0.084)
	var pip := SphereMesh.new()
	pip.radius = c_rad * 0.20
	pip.height = c_rad * 0.40
	pip.radial_segments = 8
	pip.rings = 5
	var pip_mi: MeshInstance3D = _add(ctx, pip, mat_seed)
	pip_mi.transform = Transform3D(Basis(), centre)
	for i in range(3):
		if not _can(ctx):
			return
		var rr: float = c_rad * (0.62 + 0.19 * float(i))
		var hoop := TorusMesh.new()
		hoop.inner_radius = rr * 0.91
		hoop.outer_radius = rr
		hoop.rings = 6
		hoop.ring_segments = 22
		var mi: MeshInstance3D = _add(ctx, hoop, mat_bone)
		var ax: Vector3 = _perp(out_dir, float(i) * TAU / 3.0 + rng.randf_range(-0.30, 0.30))
		mi.transform = Transform3D(_basis_y_to(ax), centre)


static func _spatter(ctx: Dictionary, at: Vector3, n: int, mat_crust: StandardMaterial3D,
		mat_wet: StandardMaterial3D, rng: RandomNumberGenerator, reach: float) -> void:
	# fused's trimmings: the pour hit the plinth and threw crust. One bead in
	# three is still wet, which is what keeps the foot from reading as gravel.
	for i in range(n):
		if not _can(ctx):
			return
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = reach * sqrt(rng.randf_range(0.10, 1.0))
		var s: float = rng.randf_range(0.018, 0.046)
		var bead := SphereMesh.new()
		bead.radius = s
		bead.height = s * 2.0
		bead.radial_segments = 10
		bead.rings = 5
		var m: StandardMaterial3D = mat_wet if i % 3 == 0 else mat_crust
		var mi: MeshInstance3D = _add(ctx, bead, m)
		var bs := Basis(Vector3(1.35, 0.0, 0.0), Vector3(0.0, 0.24, 0.0), Vector3(0.0, 0.0, 1.35))
		mi.transform = Transform3D(bs, Vector3(at.x + cos(a) * r, PLINTH_TOP + s * 0.24, at.z + sin(a) * r))


static func _bud(ctx: Dictionary, at: Vector3, out_dir: Vector3, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# crown: the tip keeps only what never opened
	var r: float = rng.randf_range(0.013, 0.026)
	var bud := SphereMesh.new()
	bud.radius = r
	bud.height = r * 2.7
	bud.radial_segments = 10
	bud.rings = 6
	var mi: MeshInstance3D = _add(ctx, bud, mat)
	mi.transform = Transform3D(_basis_y_to(out_dir), at + out_dir * (r * 0.7))


static func _tapered_cyl(ctx: Dictionary, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi: MeshInstance3D = _add(ctx, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _knot(ctx: Dictionary, at: Vector3, d: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	if bool(ctx.get("iso", false)):
		# no knuckles in a grown body: the fillet IS the knuckle
		return null
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 10
	sph.rings = 6
	var mi: MeshInstance3D = _add(ctx, sph, mat)
	var kb: Basis = _basis_y_to(d) * Basis(Vector3(1.16, 0.0, 0.0), Vector3(0.0, 0.70, 0.0), Vector3(0.0, 0.0, 0.94))
	mi.transform = Transform3D(kb, at)
	return mi


static func _petal(ln: float, wd: float, bow: float, cup: float, c_low: Color, c_hi: Color) -> ArrayMesh:
	# a flat rounded lobe: base at the origin, growing along +Y, face normal +Z
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu: int = 6
	var nv: int = 4
	var grid: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / float(nu)
		var shape: float = sin(PI * clampf(u * 0.90 + 0.10, 0.0, 1.0))
		var hw: float = wd * 0.5 * pow(shape, 0.55)
		var row: Array = []
		for j in range(nv + 1):
			var vv: float = float(j) / float(nv) * 2.0 - 1.0
			var x: float = vv * hw
			var y: float = u * ln
			var z: float = bow * sin(PI * u * 0.85) + cup * (vv * vv)
			row.append(Vector3(x, y, z))
		grid.append(row)
	for i in range(nu):
		var u0: float = float(i) / float(nu)
		var u1: float = float(i + 1) / float(nu)
		var c0: Color = c_low.lerp(c_hi, u0)
		var c1: Color = c_low.lerp(c_hi, u1)
		var row0: Array = grid[i]
		var row1: Array = grid[i + 1]
		for j in range(nv):
			var v0: float = float(j) / float(nv)
			var v1: float = float(j + 1) / float(nv)
			var p00: Vector3 = row0[j]
			var p01: Vector3 = row0[j + 1]
			var p10: Vector3 = row1[j]
			var p11: Vector3 = row1[j + 1]
			st.set_color(c0)
			st.set_uv(Vector2(v0, u0))
			st.add_vertex(p00)
			st.set_color(c1)
			st.set_uv(Vector2(v0, u1))
			st.add_vertex(p10)
			st.set_color(c1)
			st.set_uv(Vector2(v1, u1))
			st.add_vertex(p11)
			st.set_color(c0)
			st.set_uv(Vector2(v0, u0))
			st.add_vertex(p00)
			st.set_color(c1)
			st.set_uv(Vector2(v1, u1))
			st.add_vertex(p11)
			st.set_color(c0)
			st.set_uv(Vector2(v1, u0))
			st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


static func _perp(d: Vector3, ang: float) -> Vector3:
	if d.length() < 0.00001:
		return Vector3.RIGHT
	var dn: Vector3 = d.normalized()
	var ref: Vector3 = Vector3.UP if absf(dn.y) < 0.9 else Vector3.RIGHT
	var e1: Vector3 = ref.cross(dn)
	if e1.length() < 0.0001:
		e1 = Vector3.FORWARD.cross(dn)
	if e1.length() < 0.0001:
		return Vector3.RIGHT
	e1 = e1.normalized()
	var e2: Vector3 = dn.cross(e1).normalized()
	var out_v: Vector3 = e1 * cos(ang) + e2 * sin(ang)
	if out_v.length() < 0.0001:
		return e1
	return out_v.normalized()


static func _rand_dir(rng: RandomNumberGenerator) -> Vector3:
	var z: float = rng.randf_range(-1.0, 1.0)
	var a: float = rng.randf_range(0.0, TAU)
	var r: float = sqrt(maxf(1.0 - z * z, 0.0))
	return Vector3(r * cos(a), z, r * sin(a))


static func _basis_y_to(dir: Vector3) -> Basis:
	if dir.length() < 0.00001:
		return Basis()
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _scale_about(root: Node3D, pivot: Vector3, k: float) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), pivot + (tf.origin - pivot) * k)


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
# the gloss

## One DreamSkin finish, with the family's own painted texture kept underneath
## when the finish did not bring its own. `tile` only bites on the finishes that
## turn triplanar on (oil slick, holo, chrome): their default tile is metres
## wide, which on a petal is one flat colour.
static func _gloss(finish: String, base: Color, rng: RandomNumberGenerator,
		tex: ImageTexture, tile: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, base, rng)
	if tex != null and m.albedo_texture == null:
		m.albedo_texture = tex
	if tile > 0.0 and m.uv1_triplanar:
		m.uv1_scale = Vector3(tile, tile, tile)
	return m


## A petal or a blade: gloss, plus the two things the flat lobes need — the
## base-to-tip vertex gradient, and both faces, because a petal has no back.
static func _petal_skin(finish: String, base: Color, rng: RandomNumberGenerator,
		tex: ImageTexture) -> StandardMaterial3D:
	var m: StandardMaterial3D = _gloss(finish, base, rng, tex, 9.0)
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ---------------------------------------------------------------------------
# textures painted in code

static func _lattice(rng: RandomNumberGenerator, n: int) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(n * n)
	for i in range(n * n):
		a[i] = rng.randf()
	return a


static func _vnoise(lat: PackedFloat32Array, n: int, x: float, y: float) -> float:
	var xi: int = int(floor(x))
	var yi: int = int(floor(y))
	var fx: float = x - float(xi)
	var fy: float = y - float(yi)
	var sx: float = fx * fx * (3.0 - 2.0 * fx)
	var sy: float = fy * fy * (3.0 - 2.0 * fy)
	var x0: int = posmod(xi, n)
	var x1: int = posmod(xi + 1, n)
	var y0: int = posmod(yi, n)
	var y1: int = posmod(yi + 1, n)
	var v00: float = lat[y0 * n + x0]
	var v10: float = lat[y0 * n + x1]
	var v01: float = lat[y1 * n + x0]
	var v11: float = lat[y1 * n + x1]
	var ta: float = lerpf(v00, v10, sx)
	var tb: float = lerpf(v01, v11, sx)
	return lerpf(ta, tb, sy)


static func _fbm(lat: PackedFloat32Array, n: int, x: float, y: float, oct: int) -> float:
	var v: float = 0.0
	var amp: float = 0.5
	var fr: float = 1.0
	var norm: float = 0.0
	for o in range(oct):
		v += amp * _vnoise(lat, n, x * fr, y * fr)
		norm += amp
		amp *= 0.5
		fr *= 2.0
	return v / maxf(norm, 0.0001)


static func _wood_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# domain-warped periodic value noise, ridged into molten rope highlights;
	# the warp field is periodic too, so the whole thing still tiles
	var n: int = 8
	var lat_a: PackedFloat32Array = _lattice(rng, n)
	var lat_b: PackedFloat32Array = _lattice(rng, n)
	var lat_c: PackedFloat32Array = _lattice(rng, n)
	var warp: float = rng.randf_range(0.9, 1.5)
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var u: float = float(x) / float(TEX_SIZE) * float(n)
			var v: float = float(y) / float(TEX_SIZE) * float(n)
			var wx: float = _fbm(lat_b, n, u, v, 2) - 0.5
			var wy: float = _fbm(lat_c, n, u, v, 2) - 0.5
			var s: float = _fbm(lat_a, n, u + wx * warp * 2.0, v + wy * warp * 2.0, 3)
			var ridge: float = 1.0 - absf(s * 2.0 - 1.0)
			var g: float = 0.34 + 0.62 * pow(clampf(ridge, 0.0, 1.0), 1.7)
			var cool: float = 0.03 * (s - 0.5)
			img.set_pixel(x, y, Color(clampf(g - cool, 0.0, 1.0), clampf(g - cool * 0.4, 0.0, 1.0), clampf(g + cool, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _soft_texture(rng: RandomNumberGenerator, base_dark: float) -> ImageTexture:
	# near-white mottle so albedo_color carries the hue; v runs along the petal
	var n: int = 4
	var lat: PackedFloat32Array = _lattice(rng, n)
	var img: Image = Image.create(PETAL_TEX, PETAL_TEX, false, Image.FORMAT_RGB8)
	for y in range(PETAL_TEX):
		for x in range(PETAL_TEX):
			var u: float = float(x) / float(PETAL_TEX)
			var v: float = float(y) / float(PETAL_TEX)
			var m: float = _fbm(lat, n, u * float(n), v * float(n), 3)
			var g: float = 0.90 + 0.12 * m
			var dark: float = lerpf(1.0 - base_dark, 1.0, clampf(v * 2.4, 0.0, 1.0))
			g = clampf(g * dark, 0.0, 1.0)
			img.set_pixel(x, y, Color(g, g * 0.998, g * 0.99))
	return ImageTexture.create_from_image(img)
