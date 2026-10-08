extends RefCounted

## dream_bodies / tube_reef — one intertwined column of reef noodles, with eels.
##
## Reference: scratchpad/refs/sea_c.png (2048x536 panorama) — clumps of thick,
## smooth, uniform-diameter tubes rising from a grey coral floor in matt white,
## lemon yellow and magenta, winding around and through one another and hooking
## over at the top; among them, leopard-spotted eels (grey blotches on white)
## rise in S-curves, each ending in a small head with two round eyes and an
## open mouth. This builder takes ONE clump and stands it up as a statue.
##
## Reproduced, and how:
##   1. The noodles — 5..7 SurfaceTool swept tubes (12-sided rings on
##      parallel-transported frames) of constant radius 46..56 mm, each rising
##      from the common base on an arch, twisting around the column with its
##      own phase, twist sign, swirl and radial/vertical wobble, and landing
##      back on the coral. SphereMesh caps close both ends.
##   2. The weave — nothing is collision-checked: opposite twist signs and
##      differing wobble frequencies make the tubes cross and pass through one
##      another, which is what the reference actually shows.
##   3. Hairpin loops over the crown — about half the tubes get a full circle,
##      smoothstep-eased in and out (so the tangent never kinks), blended into
##      the path near the apex in the radial/up plane; it curls inward over the
##      top of the group.
##   4. Free hooked ends — one or two tubes stop just past the apex and hang in
##      mid-air over the others instead of returning to the floor.
##   5. Palette by seed — mostly one body hue, one or two loud ones and usually
##      one hot, all carrying a faint 64px grain. Since 2026-09-03 the hues are
##      dealt from the queer palette and the surfaces are GLOSS (see below).
##   6. One or two EELS — the same swept tube, tapering 52 -> 34 mm, on a rising
##      S path (sway in the tangential angle, drifting outward through the last
##      quarter), wearing a 128px leopard-spot texture painted in code onto the
##      tube's own arclength UVs, with a per-eel uv offset so no two match.
##   7. Eel heads — SphereMesh cranium + CapsuleMesh snout, two SurfaceTool
##      tapered-box jaws with the lower one hinged open 20..34 deg, a dark
##      mouth wedge between them, and two white eyes with dark pupils turned
##      outward.
##   8. The grey coral floor — a flattened SphereMesh mound carrying 46..62
##      nubs, a third of them growing one or two further spheres outward as
##      branches, all on a triplanar mottle texture.
##
## Given up: the black water and its caustic surface, the neighbouring reef
## clumps and branching fan corals, the octopus at the left, and the fine
## porous micro-perforation of the eel skin — a painted spot pattern stands in
## for it, without the holes.
##
## THE GLOSS (2026-09-03, Palle: "add super glossy and queer materials").
## The reference is matt rubber. It is not matt any more. One finish is dealt
## per statue from the seed — latex, patent, oilslick, holo, candy, wet, pearl
## or chrome (DreamSkin) — and every noodle in the clump wears it, so the
## column reads as ONE poured material in three hues instead of a pick-and-mix.
## Hues come from the queer palette: a body hue (cream, lilac, mint, cyan), one
## or two loud (lemon, acid, tangerine) and usually one hot (hot_pink, magenta,
## violet, blood); in about a third of statues that hot noodle is a lit NEON
## tube instead, the one thing in the reef making its own light. The eels wear a
## finish that leaves the albedo texture free — latex, patent, candy, wet or
## pearl — because the leopard rosettes have to survive being made wet, and
## their eyes are wet, their pupils patent, their mouths wet.
##
## Two matte passages are kept ON PURPOSE, and they are the contrast the gloss
## needs: the grey coral bed stays chalk (it is stone, and a wet floor would
## make the noodles look dry), and on "fossil" the rib cage goes bone-matte
## while the core rod inside it stays glossy — the rubber is gone from the cage,
## not from what it held.
##
## AXES (dream-body DNA — two, declared in axes(), read from opts):
##   growth  — what the noodles ARE. arch: the clump as built. melt: the arches
##             sag to a third their height, spread outward and end in flattened
##             puddles, the whole reef standing in one wet pour of its own body
##             hue — the wettest surface in the family. swarm: every
##             noodle severed into a dozen drifting capsule fragments, the
##             column a cloud of its own pieces. fossil: the rubber gone — a
##             thin core rod threaded through 12..15 open rib rings, the cage
##             of the tube that was. bloom: the tubes taper to stems and open
##             into 6..8-petal flowers over the crown. fused: the clump GROWN
##             instead of assembled (2026-09-03) — the same joints and the same
##             radii, fattened 1.8x and handed to DreamIso as capsules, marched
##             out of one field at 50 mm cells with a 130 mm blend. Where two
##             noodles cross they no longer pass through one another: they swell
##             into a single fillet, and the whole clump comes out as ONE skin
##             with the arches as its limbs. Two carved spheres near the crown
##             are the pores — a hole here is not a missing piece, it is a place
##             the field never crossed zero.
##   tenants — who rises among them. eels: 1..2 leopard eels, as built. shoal:
##             5..7 half-size eels ringing the column. hydra: one thick trunk
##             splitting into three necks and three heads. chorus: the bodies
##             erased — 6..8 severed heads hanging in the air at every height.
##
## MESH COUNT on "fused": the grown column is ONE MeshInstance3D where the other
## growths spend 5..7 swept tubes plus caps, so the 40-mesh floor is carried by
## the trimmings the family already has — the coral bed (dome + 46..62 nubs and
## their branches) and whichever tenants rose, never fewer than about 80 in all.
## Two more things the mesher taught this file. The marched mesh carries NO UVs,
## so a texture on it must be triplanar or it samples one texel across the whole
## body (the fused material sets that). And DreamIso is new: if mesh_of() returns
## null the value does NOT stand an empty plinth — every path is kept and swept
## as primitives instead, which is the arch construction exactly.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX: int = 128
const CORAL_TEX: int = 96
const GRAIN_TEX: int = 64

const GREYS: Array = ["#8E9089", "#83857E", "#989A92"]

# the reef's own share of the queer palette, by role
const BODY_HUES: Array = ["cream", "lilac", "mint", "cyan"]
const LOUD_HUES: Array = ["lemon", "acid", "tangerine"]
const HOT_HUES: Array = ["hot_pink", "magenta", "violet", "blood"]

# every finish the clump may be poured in, and the ones an eel may wear (these
# leave albedo_texture free, so the leopard rosettes survive the gloss)
const REEF_FINISHES: Array = ["latex", "patent", "oilslick", "holo", "candy", "wet", "pearl", "chrome"]
const EEL_FINISHES: Array = ["latex", "patent", "candy", "wet", "pearl"]

# the fused field: cell, fillet, and how much fatter a grown noodle is than a
# swept one (0.05 cells across a 0.09 m radius is ~3.6 samples, which is the
# thinnest a marched tube can be without breaking into beads)
const FUSE_CELL: float = 0.050
const FUSE_BLEND: float = 0.130
const FUSE_FAT: float = 1.80
const FUSE_PARTS: int = 36


static func describe() -> String:
	return "A column of thick high-gloss noodles winding through one another and hooking over at the top, poured in one wet finish and three queer hues, with leopard-spotted eels rising among them from a bed of matt grey coral."


static func axes() -> Dictionary:
	return {
		"growth": ["arch", "melt", "swarm", "fossil", "bloom", "fused"],
		"tenants": ["eels", "shoal", "hydra", "chorus"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var growth: String = String(opts.get("growth", "arch"))
	var tenants: String = String(opts.get("tenants", "eels"))
	var melt: bool = growth == "melt"
	var swarm: bool = growth == "swarm"
	var fossil: bool = growth == "fossil"
	var bloom: bool = growth == "bloom"
	var fused: bool = growth == "fused"
	# every multiplier is exactly 1.0 / 0.0 on the default, so "arch" reproduces
	# today's statue draw for draw
	var h_mul: float = 0.30 if melt else 1.0
	var spread: float = 0.85 if melt else 0.0
	var fat: float = 1.34 if melt else 1.0

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- palette -------------------------------------------------------------
	# one finish for the whole clump, three hues by role: the statue is ONE
	# poured material, not a pick-and-mix of surfaces
	var s_grey: String = GREYS[rng.randi_range(0, GREYS.size() - 1)]
	var col_coral := Color(s_grey)
	var finish: String = String(REEF_FINISHES[rng.randi_range(0, REEF_FINISHES.size() - 1)])
	var col_body: Color = _pick_hue(BODY_HUES, rng)
	var col_loud: Color = _pick_hue(LOUD_HUES, rng)
	var col_hot: Color = _pick_hue(HOT_HUES, rng)
	# a third of the time the single hot noodle is a lit tube instead
	var fin_hot: String = "neon" if rng.randf() < 0.32 else finish

	var tex_grain: ImageTexture = _grain_texture(rng)
	var tex_coral: ImageTexture = _coral_texture(rng)
	var tex_spot: ImageTexture = _spot_texture(rng)

	# built once per role and duplicated per noodle — a sweep texture costs 192x192
	# painted pixels and the clump would otherwise repaint it seven times
	var role_mats: Array = [
		_gloss(finish, col_body, rng, tex_grain, 3.0),
		_gloss(finish, col_loud, rng, tex_grain, 3.0),
		_gloss(fin_hot, col_hot, rng, tex_grain, 3.0),
	]

	var mat_coral: StandardMaterial3D = _matte(col_coral, 0.94)
	mat_coral.albedo_texture = tex_coral
	mat_coral.uv1_triplanar = true
	mat_coral.uv1_scale = Vector3(7.0, 7.0, 7.0)
	var mat_coral_dark: StandardMaterial3D = _matte(col_coral.darkened(0.22), 0.96)
	mat_coral_dark.albedo_texture = tex_coral
	mat_coral_dark.uv1_triplanar = true
	mat_coral_dark.uv1_scale = Vector3(5.0, 5.0, 5.0)
	var mat_coral_pale: StandardMaterial3D = _matte(col_coral.lightened(0.16), 0.92)
	mat_coral_pale.albedo_texture = tex_coral
	mat_coral_pale.uv1_triplanar = true
	mat_coral_pale.uv1_scale = Vector3(9.0, 9.0, 9.0)

	# a mouth is wet, an eye is wet, a pupil is patent — no argument for matte here
	var mat_mouth: StandardMaterial3D = Gloss.skin("wet", Color("#7E2A46"), rng)
	var mat_eye: StandardMaterial3D = Gloss.skin("wet", Color("#F6F4EE"), rng)
	var mat_pupil: StandardMaterial3D = Gloss.skin("patent", Color("#141118"), rng)

	# --- individual parameters -----------------------------------------------
	var n_tubes: int = rng.randi_range(5, 7)
	var n_eels: int = 1 if rng.randf() < 0.35 else 2
	var base_y: float = 0.075
	var col_r: float = rng.randf_range(0.30, 0.36)
	var arch_h0: float = rng.randf_range(1.30, 1.40)
	var tube_r: float = rng.randf_range(0.046, 0.056)
	var lean_a: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.02, 0.07)
	var lean_x: float = cos(lean_a) * lean_amt
	var lean_z: float = sin(lean_a) * lean_amt
	var spin: float = rng.randf_range(0.0, TAU)

	# colour roles: 0 white, 1 yellow, 2 magenta — shuffled with our own rng
	var order: Array = []
	for i in range(n_tubes):
		order.append(i)
	for i in range(n_tubes - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	var roles: Array = []
	for _i in range(n_tubes):
		roles.append(0)
	var take: int = 0
	var n_yellow: int = rng.randi_range(1, 2)
	for _k in range(n_yellow):
		if take < n_tubes - 1:
			roles[order[take]] = 1
			take += 1
	if rng.randf() < 0.85 and take < n_tubes - 1:
		roles[order[take]] = 2
		take += 1

	# which tubes end free in the air rather than returning to the floor
	var n_hooks: int = rng.randi_range(1, 2)
	var hooked: Array = []
	for _i in range(n_tubes):
		hooked.append(false)
	for k in range(n_hooks):
		var hi: int = order[(n_tubes - 1 - k) % n_tubes]
		hooked[hi] = true

	# --- the noodles ---------------------------------------------------------
	var steps: int = 88
	# "fused" collects the field instead of committing meshes; iso_paths keeps
	# every path so the primitive construction is still available as a fallback
	var iso_parts: Array = []
	var iso_paths: Array = []
	for ti in range(n_tubes):
		var ph: float = spin + TAU * float(ti) / float(n_tubes) + rng.randf_range(-0.26, 0.26)
		var twist: float = rng.randf_range(1.5, 3.0) * (1.0 if rng.randf() < 0.55 else -1.0)
		var swirl: float = rng.randf_range(0.16, 0.44)
		var swirl_ph: float = rng.randf_range(0.0, TAU)
		var arch_h: float = arch_h0 * rng.randf_range(0.90, 1.04)
		var arch_pw: float = rng.randf_range(0.80, 1.05)
		var r_here: float = col_r * rng.randf_range(0.86, 1.08)
		var wob_amp: float = rng.randf_range(0.030, 0.072)
		var wob_f: float = 2.0 if rng.randf() < 0.5 else 3.0
		var wob_ph: float = rng.randf_range(0.0, TAU)
		var ywob: float = rng.randf_range(0.028, 0.070)
		var ywob_f: float = 3.0 if rng.randf() < 0.5 else 4.0
		var ywob_ph: float = rng.randf_range(0.0, TAU)
		var has_loop: bool = rng.randf() < 0.55
		var loop_r: float = rng.randf_range(0.060, 0.090)
		var loop_u: float = rng.randf_range(0.42, 0.60)
		var loop_w: float = rng.randf_range(0.10, 0.16)
		var u_top: float = 1.0
		if hooked[ti]:
			u_top = rng.randf_range(0.66, 0.86)

		var pts: Array = []
		var radii: Array = []
		for i in range(steps + 1):
			var u: float = u_top * float(i) / float(steps)
			var sn: float = maxf(sin(PI * u), 0.0)
			var ang: float = ph + twist * u + swirl * sin(TAU * u + swirl_ph)
			var rad: float = r_here * (1.0 + spread * sn) * (0.26 + 0.74 * pow(sn, 0.62)) + wob_amp * sin(wob_f * PI * u + wob_ph)
			rad = maxf(rad, 0.03)
			var yy: float = base_y + arch_h * h_mul * pow(sn, arch_pw) + ywob * sn * sin(ywob_f * PI * u + ywob_ph)
			var p := Vector3(rad * cos(ang) + lean_x * sn, yy, rad * sin(ang) + lean_z * sn)
			if has_loop and u > loop_u - loop_w and u < loop_u + loop_w:
				var sl: float = (u - (loop_u - loop_w)) / (2.0 * loop_w)
				var se: float = sl * sl * (3.0 - 2.0 * sl)
				var e_out: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
				p += e_out * (loop_r * (cos(TAU * se) - 1.0))
				p += Vector3(0.0, loop_r * sin(TAU * se), 0.0)
			pts.append(p)
			var rr_here: float = tube_r * fat
			if bloom:
				# a stem, not a noodle — it has to thin out before it can flower
				var tt: float = clampf(u / maxf(u_top, 0.0001), 0.0, 1.0)
				rr_here = tube_r * lerpf(1.10, 0.40, pow(tt, 1.5))
			radii.append(rr_here)

		var role: int = roles[ti]
		var mat_role: StandardMaterial3D = role_mats[role]
		var mat_tube: StandardMaterial3D = mat_role.duplicate() as StandardMaterial3D
		# a triplanar sweep already varies across the body; only the flat grain
		# needs its own offset per noodle or the repetition reads as a print
		if not mat_tube.uv1_triplanar:
			mat_tube.uv1_offset = Vector3(rng.randf(), rng.randf(), 0.0)

		if swarm:
			_swarm_tube(root, pts, radii, mat_tube, rng)
		elif fossil:
			_fossil_tube(root, pts, radii, mat_tube, rng)
		elif fused:
			# the field, not the mesh: the SAME joints and the same radii, fattened
			# and resampled into a handful of capsules. Where two noodles cross,
			# the smooth union swells them into one another instead of letting
			# them pass through — which is the whole argument of this value.
			var segs_f: int = clampi(int(float(FUSE_PARTS) / float(n_tubes)), 4, 7)
			for k in range(segs_f):
				var i0: int = int(round(float(k) * float(steps) / float(segs_f)))
				var i1: int = int(round(float(k + 1) * float(steps) / float(segs_f)))
				i1 = mini(i1, steps)
				var qa: Vector3 = pts[i0]
				var qb: Vector3 = pts[i1]
				iso_parts.append(Iso.capsule(qa, qb, float(radii[i0]) * FUSE_FAT, float(radii[i1]) * FUSE_FAT))
			iso_paths.append({"pts": pts, "radii": radii, "mat": mat_tube})
		else:
			var body: ArrayMesh = _tube_mesh(pts, radii, 12, 2.0)
			var bm: MeshInstance3D = _add(root, body, mat_tube)
			bm.transform = Transform3D()
			var foot: Vector3 = pts[0]
			var crest: Vector3 = pts[pts.size() - 1]
			_ball(root, foot, tube_r, mat_tube)
			_ball(root, crest, tube_r, mat_tube)
			if melt:
				_puddle(root, foot, tube_r, mat_tube, rng)
				if not hooked[ti]:
					_puddle(root, crest, tube_r, mat_tube, rng)
			elif bloom:
				_flower(root, pts, mat_tube, rng)

	# --- fused: one field, one skin ------------------------------------------
	if fused:
		# two pores bored through the mass. A hole here is not a missing piece —
		# it is a place the field never crossed zero, and the smooth subtraction
		# gives it a lip rather than a razor edge
		for _k in range(2):
			var pa: float = rng.randf_range(0.0, TAU)
			var pr: float = col_r * rng.randf_range(0.25, 0.85)
			var py: float = base_y + arch_h0 * rng.randf_range(0.28, 0.78)
			var pore := Vector3(cos(pa) * pr, py, sin(pa) * pr)
			iso_parts.append(Iso.cut(Iso.sphere(pore, rng.randf_range(0.055, 0.090))))
		var mat_fused: StandardMaterial3D = (role_mats[0] as StandardMaterial3D).duplicate() as StandardMaterial3D
		# the marched mesh has NO UVs — a flat texture would sample one texel over
		# the whole body, so the grain goes on triplanar or not at all
		if not mat_fused.uv1_triplanar:
			mat_fused.albedo_texture = tex_grain
			mat_fused.uv1_triplanar = true
			mat_fused.uv1_scale = Vector3(5.0, 5.0, 5.0)
		var grown: ArrayMesh = Iso.mesh_of(iso_parts, FUSE_CELL, FUSE_BLEND, 0.05)
		if grown != null:
			var gmi: MeshInstance3D = _add(root, grown, mat_fused)
			gmi.transform = Transform3D()
		else:
			push_warning("[tube_reef] the field yielded nothing from %d part(s) — swept tubes instead" % iso_parts.size())
			# THE MESHER IS NEW. If the field yielded nothing, the reef is built
			# the way every other growth value builds it — the same paths, swept
			# as primitives — rather than leaving an empty plinth
			for rec_v in iso_paths:
				var rec: Dictionary = rec_v
				var rpts: Array = rec["pts"]
				var rradii: Array = rec["radii"]
				var rmat: StandardMaterial3D = rec["mat"]
				var rbody: ArrayMesh = _tube_mesh(rpts, rradii, 12, 2.0)
				var rmi: MeshInstance3D = _add(root, rbody, rmat)
				rmi.transform = Transform3D()
				var rfoot: Vector3 = rpts[0]
				var rcrest: Vector3 = rpts[rpts.size() - 1]
				_ball(root, rfoot, tube_r, rmat)
				_ball(root, rcrest, tube_r, rmat)

	# --- the pour the melted reef stands in ----------------------------------
	if melt:
		# the wettest thing in the statue: a reef standing in its own melt
		var mat_pool: StandardMaterial3D = Gloss.skin("wet", col_body.lightened(0.06), rng)
		mat_pool.albedo_texture = tex_grain
		mat_pool.uv1_scale = Vector3(4.0, 4.0, 1.0)
		var pool := SphereMesh.new()
		pool.radius = 0.5
		pool.height = 1.0
		pool.radial_segments = 30
		pool.rings = 12
		var pool_r: float = col_r * 1.75
		var pool_h: float = 0.085
		var pmi: MeshInstance3D = _add(root, pool, mat_pool)
		pmi.transform = Transform3D(Basis().scaled(Vector3(pool_r * 2.0, pool_h * 2.0, pool_r * 2.0)), Vector3(0.0, pool_h, 0.0))

	# --- axis: tenants -------------------------------------------------------
	var n_bodies: int = n_eels
	var eel_h: float = 1.0
	var eel_g: float = 1.0
	var eel_out: float = 1.0
	var necks: int = 1
	if tenants == "shoal":
		n_bodies = rng.randi_range(5, 7)
		eel_h = 0.46
		eel_g = 0.60
		eel_out = 1.45
	elif tenants == "hydra":
		n_bodies = 1
		eel_h = 0.88
		eel_g = 1.45
		eel_out = 0.70
		necks = 3
	elif tenants == "chorus":
		n_bodies = 0

	# --- the eels ------------------------------------------------------------
	for _ei in range(n_bodies):
		var ph_e: float = spin + rng.randf_range(0.0, TAU)
		var h_e: float = rng.randf_range(1.06, 1.32) * eel_h
		var r_e: float = col_r * rng.randf_range(0.78, 1.02) * eel_out
		var sway: float = rng.randf_range(0.55, 1.05) * (1.0 if rng.randf() < 0.5 else -1.0)
		var swim_f: float = 1.6 if rng.randf() < 0.5 else 2.2
		var drift: float = rng.randf_range(-0.5, 0.5)
		var head_out: float = rng.randf_range(0.08, 0.17) * eel_g
		var r_base: float = rng.randf_range(0.048, 0.055) * eel_g
		var r_neck: float = rng.randf_range(0.030, 0.037) * eel_g
		var e_steps: int = 72

		var epts: Array = []
		var eradii: Array = []
		for i in range(e_steps + 1):
			var u: float = float(i) / float(e_steps)
			var ang: float = ph_e + sway * sin(PI * u * swim_f) + drift * u
			var out_t: float = clampf((u - 0.70) / 0.30, 0.0, 1.0)
			var rad: float = r_e * (0.20 + 0.80 * pow(u, 0.58)) + head_out * out_t * out_t
			var yy: float = base_y + h_e * pow(u, 0.94)
			epts.append(Vector3(rad * cos(ang), yy, rad * sin(ang)))
			eradii.append(lerpf(r_base, r_neck, pow(u, 0.85)))

		# the spotted material is only ever worn by the swept tube, whose UVs are
		# built from arclength; a SphereMesh cap would stretch ONE spot over the
		# whole ball, so the cap wears the plain skin.
		# The eel's finish is drawn from the subset that leaves albedo_texture
		# free — a sweep would paint over the rosettes, and the rosettes are the
		# eel. The colour is any hue in the palette: a wet magenta leopard.
		var eel_fin: String = String(EEL_FINISHES[rng.randi_range(0, EEL_FINISHES.size() - 1)])
		var eel_col: Color = Gloss.queer_colour(rng)
		var mat_skin: StandardMaterial3D = _gloss(eel_fin, eel_col, rng, tex_spot, 1.0)
		var mat_plain: StandardMaterial3D = Gloss.skin(eel_fin, eel_col, rng)
		var look: Dictionary = {"finish": eel_fin, "col": eel_col, "tex": tex_spot, "uv": mat_skin.uv1_offset}
		var eel: ArrayMesh = _tube_mesh(epts, eradii, 12, 2.0)
		var em: MeshInstance3D = _add(root, eel, mat_skin)
		em.transform = Transform3D()
		var e_foot: Vector3 = epts[0]
		_ball(root, e_foot, r_base, mat_plain)

		var tip: Vector3 = epts[epts.size() - 1]
		var tang: Vector3 = _tangent(epts, epts.size() - 1)
		var pitch: float = rng.randf_range(-0.12, 0.36)
		var fwd: Vector3 = (tang + Vector3(0.0, pitch, 0.0)).normalized()
		var gape: float = deg_to_rad(rng.randf_range(20.0, 34.0))
		if necks <= 1:
			_eel_head(root, tip, fwd, r_neck * 1.32, gape, look, mat_mouth, mat_eye, mat_pupil, rng)
		else:
			# the trunk splits: three necks fanned around the last tangent
			var side: Vector3 = fwd.cross(Vector3.UP)
			if side.length() < 0.001:
				side = Vector3.RIGHT
			side = side.normalized()
			var up2: Vector3 = side.cross(fwd).normalized()
			for k in range(necks):
				var aa: float = TAU * float(k) / float(necks) + 0.4
				var fan: float = deg_to_rad(rng.randf_range(26.0, 48.0))
				var dir_n: Vector3 = (fwd * cos(fan) + (side * cos(aa) + up2 * sin(aa)) * sin(fan)).normalized()
				var nlen: float = rng.randf_range(0.17, 0.32)
				var curl: float = rng.randf_range(-0.6, 0.6)
				var npts: Array = []
				var nradii: Array = []
				for i in range(15):
					var u2: float = float(i) / 14.0
					var bend: Vector3 = (side * curl + Vector3.UP * 0.55) * (nlen * 0.45 * u2 * u2)
					npts.append(tip + dir_n * (nlen * u2) + bend)
					nradii.append(lerpf(r_neck * 1.04, r_neck * 0.78, u2))
				var neck_mesh: ArrayMesh = _tube_mesh(npts, nradii, 10, 2.0)
				var nmi: MeshInstance3D = _add(root, neck_mesh, mat_skin)
				nmi.transform = Transform3D()
				var ntip: Vector3 = npts[npts.size() - 1]
				var ntan: Vector3 = _tangent(npts, npts.size() - 1)
				_eel_head(root, ntip, ntan, r_neck * 1.18, deg_to_rad(rng.randf_range(16.0, 42.0)), look, mat_mouth, mat_eye, mat_pupil, rng)

	# --- the chorus: heads with the bodies erased ----------------------------
	if tenants == "chorus":
		# one finish and one hue for the whole chorus — they are the same erased
		# animal, so a stump and a head that do not match would read as two eels
		var fin_c: String = String(EEL_FINISHES[rng.randi_range(0, EEL_FINISHES.size() - 1)])
		var col_c: Color = Gloss.queer_colour(rng)
		var mat_skin_c: StandardMaterial3D = _gloss(fin_c, col_c, rng, tex_spot, 1.0)
		var look_c: Dictionary = {"finish": fin_c, "col": col_c, "tex": tex_spot, "uv": mat_skin_c.uv1_offset}
		var n_heads: int = rng.randi_range(6, 8)
		for k in range(n_heads):
			var ang_h: float = spin + TAU * float(k) / float(n_heads) + rng.randf_range(-0.34, 0.34)
			var rr_h: float = col_r * rng.randf_range(0.48, 1.34)
			var hy: float = base_y + rng.randf_range(0.14, 1.32)
			var rh_h: float = rng.randf_range(0.050, 0.088)
			var out_v := Vector3(cos(ang_h), 0.0, sin(ang_h))
			var ph_h: Vector3 = out_v * rr_h + Vector3(0.0, hy, 0.0)
			var f_h: Vector3 = (out_v * rng.randf_range(0.5, 1.0) + Vector3(0.0, rng.randf_range(-0.30, 0.80), 0.0)).normalized()
			# the severed neck, cut clean
			var stump := CylinderMesh.new()
			stump.top_radius = rh_h * 0.70
			stump.bottom_radius = rh_h * 0.62
			stump.height = rh_h * 0.90
			stump.radial_segments = 14
			stump.rings = 1
			var smi: MeshInstance3D = _add(root, stump, mat_skin_c)
			smi.transform = Transform3D(_basis_y_to(-f_h), ph_h - f_h * (rh_h * 0.80))
			_eel_head(root, ph_h, f_h, rh_h, deg_to_rad(rng.randf_range(14.0, 46.0)), look_c, mat_mouth, mat_eye, mat_pupil, rng)

	# --- the coral floor -----------------------------------------------------
	var dome_rx: float = 0.44
	var dome_h: float = 0.055
	var dome := SphereMesh.new()
	dome.radius = dome_rx
	dome.height = dome_h * 2.0
	dome.radial_segments = 30
	dome.rings = 10
	var dm: MeshInstance3D = _add(root, dome, mat_coral_dark)
	dm.transform = Transform3D(Basis(), Vector3(0.0, dome_h, 0.0))

	var n_nubs: int = rng.randi_range(46, 62)
	# the contract caps the statue at 260 MeshInstance3D, and the heavy growths
	# (a swarm of fragments, a fossil cage, a chorus of heads) eat the room the
	# bed would otherwise take — so the coral is measured, never assumed. Each
	# nub can spawn up to three meshes, hence the divisor; on "arch" there is
	# always room for all 62 and this clamp never bites.
	var room: int = 246 - root.get_child_count()
	n_nubs = mini(n_nubs, maxi(14, int(float(room) / 3.0)))
	for _k in range(n_nubs):
		var ang: float = rng.randf_range(0.0, TAU)
		var rr: float = 0.50 * sqrt(rng.randf_range(0.015, 1.0))
		var nr: float = rng.randf_range(0.016, 0.044)
		var q: float = clampf(rr / dome_rx, 0.0, 1.0)
		var sy: float = dome_h * sqrt(maxf(1.0 - q * q, 0.0))
		var cy: float = maxf(dome_h + sy - nr * 0.35, nr)
		var pos := Vector3(cos(ang) * rr, cy, sin(ang) * rr)
		var mat_n: StandardMaterial3D = mat_coral
		var pick: float = rng.randf()
		if pick < 0.28:
			mat_n = mat_coral_pale
		elif pick > 0.86:
			mat_n = mat_coral_dark
		_ball(root, pos, nr, mat_n)
		if rng.randf() < 0.36:
			var lean_d: Vector3 = Vector3(cos(ang) * 0.4, 1.0, sin(ang) * 0.4).normalized()
			var p2: Vector3 = pos + lean_d * (nr * 1.05)
			_ball(root, p2, nr * 0.74, mat_n)
			if rng.randf() < 0.45:
				var p3: Vector3 = p2 + lean_d * (nr * 0.80)
				_ball(root, p3, nr * 0.54, mat_n)

	# --- fit, centre, settle -------------------------------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.01)
	var kz: float = 1.20 / maxf(box.size.z, 0.01)
	var ky: float = 1.66 / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, 0.0, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)
	# SETTLE: measured, never assumed — nothing may hang under the plinth top
	box = _union_aabb(root)
	if box.position.y < 0.0:
		var lift: float = -box.position.y
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis, tf.origin + Vector3(0.0, lift, 0.0))


# ---------------------------------------------------------------------------
# the eel head

static func _eel_head(root: Node3D, p: Vector3, fwd: Vector3, rh: float, gape: float, look: Dictionary, mat_mouth: StandardMaterial3D, mat_eye: StandardMaterial3D, mat_pupil: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# `look` carries the eel's finish, hue, spot texture and uv offset rather than
	# a built material: a head made by duplicating the body's material would
	# inherit the body's uv scale and stretch one rosette over the whole cranium
	var fin: String = String(look.get("finish", "wet"))
	var col_e: Color = look.get("col", Color(1.0, 1.0, 1.0))
	var tex_e: Texture2D = look.get("tex", null)
	var uv_e: Vector3 = look.get("uv", Vector3.ZERO)
	var f: Vector3 = fwd.normalized()
	var up_ref := Vector3.UP
	if absf(f.dot(up_ref)) > 0.95:
		up_ref = Vector3(0.0, 0.0, -1.0)
	var uh: Vector3 = (up_ref - f * f.dot(up_ref)).normalized()
	var rt: Vector3 = f.cross(uh).normalized()
	var hb := Basis(rt, uh, -f)

	# the sphere/capsule of the head carry the primitives' own UVs — one tile
	# over the whole ball — so the spots need scaling down to body size here
	var mat_head: StandardMaterial3D = Gloss.skin(fin, col_e, rng)
	if tex_e != null and mat_head.albedo_texture == null:
		mat_head.albedo_texture = tex_e
		mat_head.uv1_scale = Vector3(2.6, 2.6, 1.0)
		mat_head.uv1_offset = uv_e
	# the jaw wedges are SurfaceTool boxes with no UVs at all — plain skin
	var mat_jaw: StandardMaterial3D = Gloss.skin(fin, col_e.lightened(0.06), rng)

	var cranium := SphereMesh.new()
	cranium.radius = rh
	cranium.height = rh * 2.0
	cranium.radial_segments = 20
	cranium.rings = 12
	var cm: MeshInstance3D = _add(root, cranium, mat_head)
	cm.transform = Transform3D(hb, p)

	var snout := CapsuleMesh.new()
	snout.radius = rh * 0.72
	snout.height = rh * 2.2
	snout.radial_segments = 16
	var sm: MeshInstance3D = _add(root, snout, mat_head)
	sm.transform = Transform3D(_basis_y_to(f), p + f * (rh * 0.72))

	var anchor: Vector3 = p + f * (rh * 0.45)
	var jaw_l: float = rh * 1.45
	var upper: ArrayMesh = _tapered_box(rh * 1.46, rh * 0.72, rh * 0.90, rh * 0.30, jaw_l, -rh * 0.06)
	var um: MeshInstance3D = _add(root, upper, mat_jaw)
	um.transform = Transform3D(hb, anchor + hb * Vector3(0.0, -rh * 0.08, 0.0))

	var hinge: Vector3 = anchor + hb * Vector3(0.0, -rh * 0.44, 0.0)
	var jb: Basis = hb * Basis(Vector3.RIGHT, -gape)
	var lower: ArrayMesh = _tapered_box(rh * 1.32, rh * 0.48, rh * 0.80, rh * 0.24, jaw_l * 0.94, 0.0)
	var lm: MeshInstance3D = _add(root, lower, mat_jaw)
	lm.transform = Transform3D(jb, hinge)

	var mb: Basis = hb * Basis(Vector3.RIGHT, -gape * 0.5)
	var gum := BoxMesh.new()
	gum.size = Vector3(rh * 1.02, rh * 0.30, jaw_l * 0.86)
	var gm: MeshInstance3D = _add(root, gum, mat_mouth)
	gm.transform = Transform3D(mb, hinge + (mb * Vector3(0.0, rh * 0.10, -jaw_l * 0.42)))

	for si in range(2):
		var sgn: float = -1.0 if si == 0 else 1.0
		var eye_c: Vector3 = p + hb * Vector3(sgn * rh * 0.66, rh * 0.34, -rh * 0.28)
		var eye := SphereMesh.new()
		eye.radius = rh * 0.33
		eye.height = rh * 0.66
		eye.radial_segments = 14
		eye.rings = 8
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(Basis(), eye_c)
		var out_d: Vector3 = (rt * (sgn * 0.6) + uh * 0.18 + f * 0.55).normalized()
		var pup := SphereMesh.new()
		pup.radius = rh * 0.175
		pup.height = rh * 0.35
		pup.radial_segments = 12
		pup.rings = 8
		var pm: MeshInstance3D = _add(root, pup, mat_pupil)
		pm.transform = Transform3D(Basis(), eye_c + out_d * (rh * 0.25))


# ---------------------------------------------------------------------------
# the growth axis: what happens to one noodle

static func _swarm_tube(root: Node3D, pts: Array, radii: Array, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# the noodle severed along its own path — the arch survives as a dotted line
	var n: int = pts.size()
	var segs: int = rng.randi_range(12, 16)
	for k in range(segs):
		var t0: float = (float(k) + rng.randf_range(0.04, 0.24)) / float(segs)
		var t1: float = (float(k) + rng.randf_range(0.60, 0.92)) / float(segs)
		var i0: int = clampi(int(t0 * float(n - 1)), 0, n - 2)
		var i1: int = clampi(int(t1 * float(n - 1)), i0 + 1, n - 1)
		var a: Vector3 = pts[i0]
		var b: Vector3 = pts[i1]
		var d: Vector3 = b - a
		var ln: float = d.length()
		if ln < 0.004:
			continue
		var r: float = float(radii[i0]) * rng.randf_range(0.80, 1.60)
		var cap := CapsuleMesh.new()
		cap.radius = r
		cap.height = maxf(ln, r * 2.06)
		cap.radial_segments = 10
		cap.rings = 4
		var off_dir := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.5, 1.0), rng.randf_range(-1.0, 1.0))
		if off_dir.length() > 0.0001:
			off_dir = off_dir.normalized()
		var pos_s: Vector3 = (a + b) * 0.5 + off_dir * (r * rng.randf_range(0.3, 2.4))
		pos_s.y = maxf(pos_s.y, r * 1.15)
		var mi: MeshInstance3D = _add(root, cap, mat)
		mi.transform = Transform3D(_basis_y_to(d.normalized()), pos_s)


static func _fossil_tube(root: Node3D, pts: Array, radii: Array, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# the rubber gone: a thin core threaded through open ribs, the tube's cage.
	# THE CAGE IS THE FAMILY'S MATTE PASSAGE — bone, chalk, the thing left when
	# the wet is gone — while the core rod keeps the body's own gloss, so the
	# value argues an absence instead of just looking dusty
	var n: int = pts.size()
	var chalk: Color = Color(0.93, 0.92, 0.88).lerp(mat.albedo_color, 0.18)
	var mat_bone: StandardMaterial3D = _matte(chalk, 0.95)
	var core_radii: Array = []
	for i in range(n):
		core_radii.append(float(radii[i]) * 0.20)
	var core: ArrayMesh = _tube_mesh(pts, core_radii, 8, 2.0)
	var cmi: MeshInstance3D = _add(root, core, mat)
	cmi.transform = Transform3D()
	var ribs: int = rng.randi_range(12, 15)
	for k in range(ribs):
		var t: float = (float(k) + 0.5) / float(ribs)
		var idx: int = clampi(int(t * float(n - 1)), 0, n - 1)
		var ctr: Vector3 = pts[idx]
		var fb: Basis = _basis_y_to(_tangent(pts, idx))
		var r_ring: float = float(radii[idx]) * rng.randf_range(1.05, 1.62)
		var r_rod: float = float(radii[idx]) * rng.randf_range(0.13, 0.21)
		var rib: ArrayMesh = _rib_mesh(ctr, fb.x, fb.z, r_ring, r_rod)
		var rmi: MeshInstance3D = _add(root, rib, mat_bone)
		rmi.transform = Transform3D()


static func _rib_mesh(ctr: Vector3, nv: Vector3, bv: Vector3, ring_r: float, rod_r: float) -> ArrayMesh:
	# one rib: the swept tube run round a closed circle in the frame's own plane
	var pts: Array = []
	var radii: Array = []
	var segs: int = 14
	for i in range(segs + 1):
		var a: float = TAU * float(i) / float(segs)
		pts.append(ctr + nv * (cos(a) * ring_r) + bv * (sin(a) * ring_r))
		radii.append(rod_r)
	return _tube_mesh(pts, radii, 6, 1.0)


static func _puddle(root: Node3D, at: Vector3, r: float, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# the end of a melted noodle: two or three flattened lobes lying on the floor
	var lobes: int = rng.randi_range(2, 3)
	for k in range(lobes):
		var rr: float = r * rng.randf_range(1.8, 3.5) * (1.0 - 0.18 * float(k))
		var fl: float = rng.randf_range(0.16, 0.32)
		var off := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
		if off.length() > 0.0001:
			off = off.normalized() * (r * rng.randf_range(0.0, 1.7))
		var sph := SphereMesh.new()
		sph.radius = 0.5
		sph.height = 1.0
		sph.radial_segments = 20
		sph.rings = 10
		var mi: MeshInstance3D = _add(root, sph, mat)
		var pb: Basis = Basis().scaled(Vector3(rr * 2.0, rr * fl * 2.0, rr * 2.0))
		mi.transform = Transform3D(pb, Vector3(at.x, rr * fl, at.z) + off)


static func _flower(root: Node3D, pts: Array, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# the stem opens: petals fanned around the last tangent, a dark disc between
	var tip: Vector3 = pts[pts.size() - 1]
	var tg: Vector3 = _tangent(pts, pts.size() - 1)
	var fb: Basis = _basis_y_to(tg)
	var n_pet: int = rng.randi_range(6, 8)
	var pet_len: float = rng.randf_range(0.11, 0.17)
	var pet_w: float = pet_len * rng.randf_range(0.30, 0.48)
	var flare: float = deg_to_rad(rng.randf_range(46.0, 80.0))
	# the petals wear the stem's own gloss, one shade up; a triplanar sweep keeps
	# its own scale or the band would repeat six times inside one petal
	var mat_pet: StandardMaterial3D = mat.duplicate() as StandardMaterial3D
	mat_pet.albedo_color = mat.albedo_color.lightened(0.10)
	if not mat_pet.uv1_triplanar:
		mat_pet.uv1_scale = Vector3(2.0, 2.0, 1.0)
	for k in range(n_pet):
		var a: float = TAU * float(k) / float(n_pet) + rng.randf_range(-0.10, 0.10)
		var dir_l: Vector3 = (fb * Vector3(cos(a) * sin(flare), cos(flare), sin(a) * sin(flare))).normalized()
		var pet := SphereMesh.new()
		pet.radius = 0.5
		pet.height = 1.0
		pet.radial_segments = 12
		pet.rings = 7
		var pmi: MeshInstance3D = _add(root, pet, mat_pet)
		var pb: Basis = _basis_y_to(dir_l) * Basis().scaled(Vector3(pet_w, pet_len * 2.0, pet_w * 0.34))
		pmi.transform = Transform3D(pb, tip + dir_l * (pet_len * 0.62))
	var core := SphereMesh.new()
	core.radius = 0.5
	core.height = 1.0
	core.radial_segments = 14
	core.rings = 8
	# the seed head stays dry — a matte disc is what makes the petals look wet
	var mat_core: StandardMaterial3D = _matte(Color("#2C2A26"), 0.72)
	var kmi: MeshInstance3D = _add(root, core, mat_core)
	kmi.transform = Transform3D(fb * Basis().scaled(Vector3(pet_w * 1.5, pet_w * 0.62, pet_w * 1.5)), tip + tg * (pet_w * 0.20))


# ---------------------------------------------------------------------------
# swept tube

static func _tube_mesh(pts: Array, radii: Array, sides: int, tiles_around: float) -> ArrayMesh:
	var n: int = pts.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# parallel-transported frames so the tube never spins on its own axis
	var nrms: Array = []
	var bins: Array = []
	var prev_n := Vector3.ZERO
	for i in range(n):
		var tg: Vector3 = _tangent(pts, i)
		var nv := Vector3.ZERO
		if i == 0:
			var sv := Vector3.UP
			if absf(tg.dot(sv)) > 0.9:
				sv = Vector3.RIGHT
			nv = sv - tg * sv.dot(tg)
		else:
			nv = prev_n - tg * prev_n.dot(tg)
			if nv.length() < 0.0001:
				var sv2 := Vector3.UP
				if absf(tg.dot(sv2)) > 0.9:
					sv2 = Vector3.RIGHT
				nv = sv2 - tg * sv2.dot(tg)
		nv = nv.normalized()
		prev_n = nv
		nrms.append(nv)
		bins.append(tg.cross(nv).normalized())

	# arclength for the v coordinate, mean radius for an isotropic pattern
	var arc: Array = []
	var acc: float = 0.0
	var rsum: float = 0.0
	for i in range(n):
		if i > 0:
			var q0: Vector3 = pts[i]
			var q1: Vector3 = pts[i - 1]
			acc += (q0 - q1).length()
		arc.append(acc)
		rsum += float(radii[i])
	var mean_r: float = maxf(rsum / float(n), 0.001)
	var v_scale: float = tiles_around / (TAU * mean_r)

	# rings carry exactly `sides` vertices; the seam re-uses index 0 so the two
	# seam corners are bit-identical and generate_normals() welds them (a seam
	# pair that differs by one float bit shades as a hard line down the tube)
	var rings: Array = []
	for i in range(n):
		var row: Array = []
		var r: float = radii[i]
		var pc: Vector3 = pts[i]
		var nv2: Vector3 = nrms[i]
		var bv: Vector3 = bins[i]
		for j in range(sides):
			var a: float = TAU * float(j) / float(sides)
			row.append(pc + nv2 * (cos(a) * r) + bv * (sin(a) * r))
		rings.append(row)

	for i in range(n - 1):
		var v0: float = float(arc[i]) * v_scale
		var v1: float = float(arc[i + 1]) * v_scale
		var row0: Array = rings[i]
		var row1: Array = rings[i + 1]
		for j in range(sides):
			var jn: int = (j + 1) % sides
			var u0: float = tiles_around * float(j) / float(sides)
			var u1: float = tiles_around * float(j + 1) / float(sides)
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
# small helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ball(root: Node3D, at: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 16
	sph.rings = 9
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(Basis(), at)
	return mi


static func _matte(c: Color, rough: float) -> StandardMaterial3D:
	# kept, and still used — the coral bed, the fossil cage and the flower's seed
	# head are the passages this family needs dry
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.metallic_specular = 0.32
	return m


## One hue from the shared queer palette, by name.
static func _hue(nm: String) -> Color:
	var c: Color = Gloss.QUEER.get(nm, Color(1.0, 1.0, 1.0))
	return c


static func _pick_hue(names: Array, rng: RandomNumberGenerator) -> Color:
	var nm: String = String(names[rng.randi_range(0, names.size() - 1)])
	return _hue(nm)


## A DreamSkin finish, with this family's grain or spots laid into it where the
## finish left the albedo texture free. oilslick, holo and chrome paint their own
## sweep and set triplanar — those are left alone, because overwriting the sweep
## would take the iridescence out of exactly the finishes that have it.
static func _gloss(finish: String, col: Color, rng: RandomNumberGenerator, tex: Texture2D, tiles: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, col, rng)
	if tex != null and m.albedo_texture == null:
		m.albedo_texture = tex
		m.uv1_scale = Vector3(tiles, tiles, 1.0)
		m.uv1_offset = Vector3(rng.randf(), rng.randf(), 0.0)
	return m


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.00001:
		return Vector3.UP
	return d.normalized()


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


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	# emit a quad whose Godot front face points away from `inside`
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c + d) * 0.25
	if n_front.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
		st.add_vertex(a)
		st.add_vertex(d)
		st.add_vertex(c)


static func _tapered_box(w0: float, h0: float, w1: float, h1: float, ln: float, drop: float) -> ArrayMesh:
	# back face at z = 0 (w0 x h0), front face at z = -ln (w1 x h1), front lowered by `drop`
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var hw0: float = w0 * 0.5
	var hh0: float = h0 * 0.5
	var hw1: float = w1 * 0.5
	var hh1: float = h1 * 0.5
	var b0 := Vector3(-hw0, hh0, 0.0)
	var b1 := Vector3(hw0, hh0, 0.0)
	var b2 := Vector3(hw0, -hh0, 0.0)
	var b3 := Vector3(-hw0, -hh0, 0.0)
	var f0 := Vector3(-hw1, hh1 + drop, -ln)
	var f1 := Vector3(hw1, hh1 + drop, -ln)
	var f2 := Vector3(hw1, -hh1 + drop, -ln)
	var f3 := Vector3(-hw1, -hh1 + drop, -ln)
	var inside := Vector3(0.0, drop * 0.5, -ln * 0.5)
	_quad_out(st, b0, b1, b2, b3, inside)
	_quad_out(st, f0, f1, f2, f3, inside)
	_quad_out(st, b0, b1, f1, f0, inside)
	_quad_out(st, b3, b2, f2, f3, inside)
	_quad_out(st, b1, b2, f2, f1, inside)
	_quad_out(st, b0, b3, f3, f0, inside)
	st.generate_normals()
	return st.commit()


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var local: AABB = cm.mesh.get_aabb()
		var wb: AABB = cm.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box


# ---------------------------------------------------------------------------
# textures painted in code

static func _blob(img: Image, cx: int, cy: int, rr: float, rim: float, core: float) -> void:
	var ri: int = int(ceil(rr)) + 1
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var dd: float = sqrt(float(dx * dx + dy * dy)) / maxf(rr, 0.5)
			if dd > 1.0:
				continue
			var edge: float = clampf((1.0 - dd) / 0.20, 0.0, 1.0)
			var inner: float = clampf((0.62 - dd) / 0.28, 0.0, 1.0)
			var g: float = lerpf(rim, core, inner)
			var px: int = posmod(cx + dx, TEX)
			var py: int = posmod(cy + dy, TEX)
			var was: Color = img.get_pixel(px, py)
			var nr: float = lerpf(was.r, g, edge)
			var ng: float = lerpf(was.g, g * 1.005, edge)
			var nb: float = lerpf(was.b, g * 0.99, edge)
			img.set_pixel(px, py, Color(nr, ng, nb))


static func _spot_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# leopard skin: grey rosettes on off-white, seamless by wrapped rasterising
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x) / float(TEX)
			var fy: float = float(y) / float(TEX)
			var m: float = 0.955 + 0.030 * sin(fx * TAU * 3.0 + 1.1) * sin(fy * TAU * 2.0)
			img.set_pixel(x, y, Color(m, m * 0.995, m * 0.975))
	var n_spots: int = rng.randi_range(19, 25)
	for _k in range(n_spots):
		var cx: int = rng.randi_range(0, TEX - 1)
		var cy: int = rng.randi_range(0, TEX - 1)
		var rr: float = rng.randf_range(7.5, 12.0)
		var rim: float = rng.randf_range(0.34, 0.44)
		var core: float = rng.randf_range(0.54, 0.64)
		_blob(img, cx, cy, rr, rim, core)
		var lobes: int = rng.randi_range(1, 2)
		for _l in range(lobes):
			var ox: int = cx + rng.randi_range(-9, 9)
			var oy: int = cy + rng.randi_range(-9, 9)
			_blob(img, ox, oy, rr * rng.randf_range(0.55, 0.85), rim, core)
	var n_dots: int = rng.randi_range(34, 52)
	for _k in range(n_dots):
		var dx2: int = rng.randi_range(0, TEX - 1)
		var dy2: int = rng.randi_range(0, TEX - 1)
		_blob(img, dx2, dy2, rng.randf_range(1.6, 3.2), 0.52, 0.58)
	return ImageTexture.create_from_image(img)


static func _grain_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# near-white matt grain, so albedo_color carries the colour
	var img: Image = Image.create(GRAIN_TEX, GRAIN_TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	for y in range(GRAIN_TEX):
		for x in range(GRAIN_TEX):
			var fx: float = float(x) / float(GRAIN_TEX)
			var fy: float = float(y) / float(GRAIN_TEX)
			var blot: float = 0.020 * sin(fx * TAU * 2.0 + ph1) * sin(fy * TAU * 3.0 + ph2)
			var speck: float = rng.randf_range(-0.022, 0.010)
			var v: float = clampf(0.985 + blot + speck, 0.86, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)


static func _coral_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# pitted grey rubble, triplanar over the mound and its nubs
	var img: Image = Image.create(CORAL_TEX, CORAL_TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	for y in range(CORAL_TEX):
		for x in range(CORAL_TEX):
			var fx: float = float(x) / float(CORAL_TEX)
			var fy: float = float(y) / float(CORAL_TEX)
			var a: float = sin(fx * TAU * 4.0 + ph1) * sin(fy * TAU * 3.0 + ph2)
			var b: float = sin((fx + fy) * TAU * 7.0 + ph3)
			var v: float = 0.90 + 0.10 * a + 0.05 * b + rng.randf_range(-0.05, 0.05)
			# pits: a scatter of darker cells
			if rng.randf() < 0.05:
				v -= rng.randf_range(0.12, 0.26)
			v = clampf(v, 0.48, 1.0)
			img.set_pixel(x, y, Color(v, v * 1.005, v * 0.985))
	return ImageTexture.create_from_image(img)
