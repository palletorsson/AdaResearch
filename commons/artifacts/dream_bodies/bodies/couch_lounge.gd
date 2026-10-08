extends RefCounted

## dream_bodies / couch_lounge — one striped body reclining on a violet-pink chaise.
##
## Reference: scratchpad/refs/jump_b.png (2048x536 panorama), the left third only —
## a body in a fine coral-striped bodysuit sprawled back on a violet-pink velvet
## chaise with one fat rolled arm, grey cushions bunched behind it, and a single
## black patent high-heeled shoe abandoned on the floor at the foot end.
##
## Reproduced, and how:
##   1. The fine stripe — a 256x256 ImageTexture painted in code: 20..26 coral
##      stripes on cream, each stripe's width and tone jittered, the whole set
##      given a slow horizontal wander plus a knit ripple, so it reads as fabric
##      and not as a ruler. Carried on WORLD triplanar so the stripes run
##      unbroken across the whole capsule chain of torso, arms and legs.
##   2. The reclining gesture — an integrated spine: the lean angle is keyed and
##      curved (arch through the small of the back), so the torso rises off the
##      seat at 42..50 deg, propped on the back elbow, head tipped away over the
##      rolled arm. Nothing is mirrored: the two knees draw up to different
##      heights, the free arm drapes over the front edge, the head yaws.
##   3. The chaise cushion — one SurfaceTool superellipsoid (rounded-box sweep,
##      exponent 0.30/0.36) with a dip pressed into its top where the body sits,
##      standing on four short tapered legs with ball feet.
##   4. The fat rolled arm — a CylinderMesh roll sunk into the cushion with
##      SphereMesh end caps and a spiral of shrinking spheres on each end face
##      standing in for the scrolled-over fabric.
##   5. Matte velvet with a faint sheen — a second code-painted texture (8x8
##      value-noise blobs plus a vertical nap streak, near white so albedo_color
##      tints it), roughness 0.82, StandardMaterial3D rim for the edge glow.
##   6. Upholstery — a superellipse welt of 22..30 small spheres run round the
##      cushion's top edge, and 4..7 tufting buttons pressed into the low back.
##   7. Grey draped cushions — 2..3 warped, lumpy superellipsoids (sine warp on
##      the sweep) with elongated fold ridges laid across them, tilted apart.
##   8. The patent shoe — an extruded arched sole profile built with SurfaceTool
##      from a keyed half-width table, a stiletto with a tap, two bowed vamp
##      straps and a TorusMesh ankle strap, all near-black at roughness 0.06
##      with clearcoat 1.0. It stands on the floor beside the chaise, yawed.
##
## Given up: every other body in the photograph (this is one figure, not the
## pile), the face, the hair, the hands past four blunt fingers, the folds and
## creases of the bodysuit itself, the fur throw, and the grey studio backdrop.
##
## AXES (dream-body DNA) — the pose is solved once, as one skeleton, and every
## variant hangs on exactly that pose:
##   repose — what the body ON the chaise is. sprawl (reclining, as built) ·
##     melt (every joint sags to a fifth of its height, the flesh fattens, and
##     the striped suit pours off the seat into flat lobes on the floor) ·
##     swarm (the figure is gone, scattered into ~67 small copies of its own
##     parts strung along the same spine, arms and legs) · cage (the flesh is
##     gone, pale hoops threaded on every bone and three great rings for the
##     skull) · bloom (hands, feet and crown open into petal rosettes, and three
##     more rise on stems out of the cushion).
##   seat — what the furniture under it does. chaise (one, as built) · mirror (a
##     second chaise grows up out of the seat back on a stack of cushions and
##     hangs inverted overhead, legs in the air) · flood (legs and frame drowned
##     in a poured slab that spills across the floor in a glossy skirt) · heels
##     (the four turned wooden legs replaced by a crowd of patent stilettos, the
##     chaise standing on its toes).

const TEX_W: int = 256
const VEL_W: int = 128

# scheme: [velvet, velvet deep, cream, coral, skin, grey cushion, grey cushion 2, wood]
const SCHEMES: Array = [
	["#C97FBE", "#A75FA0", "#F7EEE2", "#DE6E58", "#E6C3A9", "#8F9296", "#A2A5A8", "#4A3630"],
	["#D18BC0", "#AE68A4", "#F4E8DA", "#D9756A", "#DDB79C", "#95989B", "#A8ABAD", "#3F2E2A"],
	["#BE74B6", "#9B5695", "#F8F1E8", "#E5836A", "#EACDB6", "#898C90", "#9DA0A3", "#523C33"],
	["#D593C6", "#B06FA6", "#F2E6D6", "#CE6A5E", "#D8AF94", "#8A8D91", "#9EA1A4", "#463329"],
]


static func describe() -> String:
	return "A body in a fine coral-striped bodysuit reclining on one elbow with knees drawn up, sprawled across a violet-pink velvet chaise with a fat rolled arm, one black patent heel left on the floor."


static func axes() -> Dictionary:
	return {
		"repose": ["sprawl", "melt", "swarm", "cage", "bloom"],
		"seat": ["chaise", "mirror", "flood", "heels"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var repose: String = str(opts.get("repose", "sprawl"))
	var seat_kind: String = str(opts.get("seat", "chaise"))
	var melt_k: float = 1.0 if repose == "melt" else 0.0

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- every individual parameter drawn first, so the geometry is seed-led ---
	var sd: float = 1.0 if rng.randf() < 0.5 else -1.0
	var chaise_l: float = rng.randf_range(1.02, 1.13)
	var chaise_w: float = rng.randf_range(0.40, 0.47)
	var leg_h: float = rng.randf_range(0.155, 0.195)
	var frame_h: float = rng.randf_range(0.055, 0.075)
	var cush_h: float = rng.randf_range(0.160, 0.200)
	var roll_r: float = rng.randf_range(0.150, 0.180)
	var back_h: float = rng.randf_range(0.21, 0.29)
	var back_tilt: float = rng.randf_range(0.10, 0.22)
	var n_welt: int = rng.randi_range(22, 30)
	var n_tuft: int = rng.randi_range(4, 7)
	var n_scroll: int = rng.randi_range(4, 6)
	var n_torso: int = rng.randi_range(8, 11)
	var torso_len: float = rng.randf_range(0.44, 0.49)
	var lean: float = deg_to_rad(rng.randf_range(42.0, 50.0))
	var spine_bend: float = rng.randf_range(0.10, 0.26)
	var torso_z: float = -rng.randf_range(0.04, 0.13)
	var neck_drop: float = rng.randf_range(0.18, 0.32)
	var head_r: float = rng.randf_range(0.100, 0.110)
	var head_yaw: float = rng.randf_range(-0.38, 0.18)
	var knee_a: float = rng.randf_range(0.27, 0.35)
	var knee_b: float = rng.randf_range(0.12, 0.20)
	var reach_a: float = rng.randf_range(0.15, 0.21)
	var reach_b: float = rng.randf_range(0.21, 0.28)
	var prop_drop: float = rng.randf_range(0.085, 0.125)
	var drape_out: float = rng.randf_range(0.09, 0.14)
	var n_pillow: int = rng.randi_range(2, 3)
	var shoe_yaw: float = deg_to_rad(rng.randf_range(-46.0, 46.0))
	var shoe_x: float = rng.randf_range(0.16, 0.36)
	var shoe_z: float = rng.randf_range(0.09, 0.19)
	var stripe_n: int = rng.randi_range(20, 26)
	var stripe_w: float = rng.randf_range(0.24, 0.34)
	var stripe_uv: float = rng.randf_range(5.0, 6.4)
	var pal: int = rng.randi_range(0, SCHEMES.size() - 1)

	var scheme: Array = SCHEMES[pal]
	var col_velvet: Color = _c(scheme, 0)
	var col_velvet_deep: Color = _c(scheme, 1)
	var col_cream: Color = _c(scheme, 2)
	var col_coral: Color = _c(scheme, 3)
	var col_skin: Color = _c(scheme, 4)
	var col_grey_a: Color = _c(scheme, 5)
	var col_grey_b: Color = _c(scheme, 6)
	var col_wood: Color = _c(scheme, 7)

	# --- textures ------------------------------------------------------------
	var stripe_tex: ImageTexture = _stripe_texture(rng, col_cream, col_coral, stripe_n, stripe_w)
	var velvet_tex: ImageTexture = _velvet_texture(rng, 8)

	var mat_suit := StandardMaterial3D.new()
	mat_suit.albedo_color = Color(1.0, 1.0, 1.0)
	mat_suit.albedo_texture = stripe_tex
	mat_suit.uv1_triplanar = true
	mat_suit.uv1_world_triplanar = true
	mat_suit.uv1_triplanar_sharpness = 1.4
	mat_suit.uv1_scale = Vector3(stripe_uv, stripe_uv, stripe_uv)
	mat_suit.roughness = 0.74
	mat_suit.metallic = 0.0

	var mat_velvet := StandardMaterial3D.new()
	mat_velvet.albedo_color = col_velvet
	mat_velvet.albedo_texture = velvet_tex
	mat_velvet.uv1_triplanar = true
	mat_velvet.uv1_world_triplanar = true
	mat_velvet.uv1_scale = Vector3(2.2, 2.2, 2.2)
	mat_velvet.roughness = 0.82
	mat_velvet.rim_enabled = true
	mat_velvet.rim = 0.55
	mat_velvet.rim_tint = 0.30

	var mat_velvet_deep := StandardMaterial3D.new()
	mat_velvet_deep.albedo_color = col_velvet_deep
	mat_velvet_deep.albedo_texture = velvet_tex
	mat_velvet_deep.uv1_triplanar = true
	mat_velvet_deep.uv1_world_triplanar = true
	mat_velvet_deep.uv1_scale = Vector3(2.6, 2.6, 2.6)
	mat_velvet_deep.roughness = 0.86
	mat_velvet_deep.rim_enabled = true
	mat_velvet_deep.rim = 0.40

	var mat_grey_a: StandardMaterial3D = _cloth(col_grey_a, velvet_tex, 0.90, 1.9)
	var mat_grey_b: StandardMaterial3D = _cloth(col_grey_b, velvet_tex, 0.92, 2.4)

	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = col_skin
	mat_skin.roughness = 0.56
	mat_skin.metallic = 0.0
	mat_skin.clearcoat_enabled = true
	mat_skin.clearcoat = 0.18
	mat_skin.clearcoat_roughness = 0.5

	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = col_wood
	mat_wood.roughness = 0.42
	mat_wood.clearcoat_enabled = true
	mat_wood.clearcoat = 0.35

	var mat_patent := StandardMaterial3D.new()
	mat_patent.albedo_color = Color("#0B0B0E")
	mat_patent.roughness = 0.06
	mat_patent.metallic = 0.0
	mat_patent.clearcoat_enabled = true
	mat_patent.clearcoat = 1.0
	mat_patent.clearcoat_roughness = 0.02

	# the three axis materials: bone for the cage, petal for the bloom, and the
	# poured lacquer for the flood. Built always, hung only where they are used.
	var mat_bone := StandardMaterial3D.new()
	mat_bone.albedo_color = Color("#EFE6D3")
	mat_bone.roughness = 0.66
	mat_bone.metallic = 0.0
	mat_bone.rim_enabled = true
	mat_bone.rim = 0.45
	mat_bone.rim_tint = 0.12

	var mat_petal := StandardMaterial3D.new()
	mat_petal.albedo_color = col_coral
	mat_petal.albedo_texture = velvet_tex
	mat_petal.uv1_triplanar = true
	mat_petal.uv1_world_triplanar = true
	mat_petal.uv1_scale = Vector3(3.4, 3.4, 3.4)
	mat_petal.roughness = 0.46
	mat_petal.metallic = 0.0
	mat_petal.rim_enabled = true
	mat_petal.rim = 0.62
	mat_petal.rim_tint = 0.25

	var mat_pour := StandardMaterial3D.new()
	mat_pour.albedo_color = col_velvet_deep.darkened(0.34)
	mat_pour.roughness = 0.10
	mat_pour.metallic = 0.0
	mat_pour.clearcoat_enabled = true
	mat_pour.clearcoat = 0.90
	mat_pour.clearcoat_roughness = 0.04

	# =========================================================================
	# the chaise
	# =========================================================================
	var seat_y: float = leg_h + frame_h + cush_h
	# a melting body presses a far deeper dip into the seat than a reclining one
	var seat_dip: float = cush_h * (0.16 + 0.34 * melt_k)

	var cushion: ArrayMesh = _superblock(
		Vector3(chaise_l * 0.5, cush_h * 0.5, chaise_w * 0.5),
		0.30, 0.36, 26, 14, seat_dip, Vector3.ZERO)
	var cm_seat: MeshInstance3D = _add(root, cushion, mat_velvet)
	cm_seat.transform = Transform3D(Basis(), Vector3(0.0, leg_h + frame_h + cush_h * 0.5, 0.0))

	var frame := BoxMesh.new()
	frame.size = Vector3(chaise_l * 0.95, frame_h, chaise_w * 0.90)
	var fm: MeshInstance3D = _add(root, frame, mat_velvet_deep)
	fm.transform = Transform3D(Basis(), Vector3(0.0, leg_h + frame_h * 0.5, 0.0))

	# what holds the chaise off the floor is the seat axis's business: four
	# turned legs, a crowd of stilettos, or nothing at all under a pour
	if seat_kind == "heels":
		var n_heels: int = rng.randi_range(9, 12)
		for i in range(n_heels):
			var fh: float = float(i) / float(maxi(n_heels - 1, 1))
			var hx: float = lerpf(-chaise_l * 0.44, chaise_l * 0.44, fh) + rng.randf_range(-0.022, 0.022)
			var hz: float = (chaise_w * 0.30) * (1.0 if (i % 2) == 0 else -1.0) + rng.randf_range(-0.030, 0.030)
			var hxf: Transform3D = Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)), Vector3(hx, 0.0, hz))
			_prop_heel(root, hxf, mat_patent, rng.randf_range(0.138, 0.168), leg_h + frame_h * 0.45)
	elif seat_kind != "flood":
		for i in range(4):
			var lx: float = (chaise_l * 0.5 - 0.075) * (1.0 if (i % 2) == 0 else -1.0)
			var lz: float = (chaise_w * 0.5 - 0.065) * (1.0 if i < 2 else -1.0)
			_tapered_cyl(root, Vector3(lx, 0.030, lz), Vector3(lx * 1.03, leg_h + 0.01, lz * 1.03), 0.030, 0.020, mat_wood)
			_ball(root, Vector3(lx, 0.026, lz), 0.026, mat_wood)

	if seat_kind == "flood":
		# the pour: a solid slab where the legs were, its top biting into the
		# underside of the cushion, spilling a glossy skirt across the floor
		var pour_top: float = seat_y - cush_h * 0.26
		var pour: ArrayMesh = _superblock(
			Vector3(chaise_l * 0.54, pour_top * 0.5, chaise_w * 0.66),
			0.42, 0.30, 24, 12, 0.0, Vector3(0.011, 0.006, 0.013))
		var pour_mi: MeshInstance3D = _add(root, pour, mat_pour)
		pour_mi.transform = Transform3D(Basis(), Vector3(0.0, pour_top * 0.5, 0.0))
		for i in range(11):
			var ang_s: float = TAU * float(i) / 11.0 + rng.randf_range(-0.20, 0.20)
			var rad_s: float = rng.randf_range(chaise_l * 0.44, chaise_l * 0.58)
			var lr_s: float = rng.randf_range(0.080, 0.145)
			var lobe := SphereMesh.new()
			lobe.radius = lr_s
			lobe.height = lr_s * 2.0
			lobe.radial_segments = 14
			lobe.rings = 7
			var lobe_mi: MeshInstance3D = _add(root, lobe, mat_pour)
			lobe_mi.transform = Transform3D(
				_scale_basis(Vector3(1.32, 0.10, 1.32)),
				Vector3(cos(ang_s) * rad_s, lr_s * 0.10 + 0.003, sin(ang_s) * rad_s * 0.80))
		for i in range(10):
			var ang_r: float = TAU * float(i) / 10.0
			var wx_r: float = (chaise_l * 0.54 + 0.014) * _sgn_pow(cos(ang_r), 0.5)
			var wz_r: float = (chaise_w * 0.66 + 0.014) * _sgn_pow(sin(ang_r), 0.5)
			_ball(root, Vector3(wx_r, pour_top - 0.012, wz_r), 0.023, mat_pour)

	# the fat rolled arm
	var roll_x: float = sd * (chaise_l * 0.5 - roll_r * 0.78)
	var roll_y: float = seat_y + roll_r * 0.58
	var roll := CylinderMesh.new()
	roll.top_radius = roll_r
	roll.bottom_radius = roll_r
	roll.height = chaise_w * 0.96
	roll.radial_segments = 24
	var rm: MeshInstance3D = _add(root, roll, mat_velvet)
	rm.transform = Transform3D(_basis_y_to(Vector3(0.0, 0.0, 1.0)), Vector3(roll_x, roll_y, 0.0))
	for i in range(2):
		var zs: float = 1.0 if i == 0 else -1.0
		var z_end: float = zs * chaise_w * 0.48
		_ball(root, Vector3(roll_x, roll_y, z_end), roll_r * 0.99, mat_velvet)
		for k in range(n_scroll):
			var fk: float = float(k) / float(n_scroll)
			var ang: float = -sd * zs * (0.55 + fk * 3.5)
			var rad: float = lerpf(roll_r * 0.70, roll_r * 0.15, fk)
			var pr: float = lerpf(0.030, 0.014, fk)
			_ball(root, Vector3(roll_x + cos(ang) * rad, roll_y + sin(ang) * rad, z_end + zs * 0.012), pr, mat_velvet_deep)

	# the low sloping back, tufted
	var back_hl: float = chaise_l * 0.27
	var back_x: float = sd * (chaise_l * 0.5 - back_hl - 0.012)
	var back_z: float = -(chaise_w * 0.5 - 0.055)
	var back_mesh: ArrayMesh = _superblock(Vector3(back_hl, back_h * 0.5, 0.052), 0.30, 0.34, 20, 12, 0.0, Vector3.ZERO)
	var back_basis: Basis = Basis(Vector3.RIGHT, -back_tilt) * Basis(Vector3(0.0, 0.0, 1.0), sd * 0.07)
	var bm: MeshInstance3D = _add(root, back_mesh, mat_velvet)
	bm.transform = Transform3D(back_basis, Vector3(back_x, seat_y + back_h * 0.5 - 0.03, back_z))
	for i in range(n_tuft):
		var ft: float = (float(i) + 0.5) / float(n_tuft)
		var tuft_local: Vector3 = Vector3(lerpf(-back_hl * 0.78, back_hl * 0.78, ft), back_h * (0.10 - 0.22 * absf(ft - 0.5)), 0.050)
		_ball(root, Vector3(back_x, seat_y + back_h * 0.5 - 0.03, back_z) + back_basis * tuft_local, 0.019, mat_velvet_deep)

	# welt piping round the top edge of the seat cushion
	var welt_a: float = chaise_l * 0.5 - 0.012
	var welt_b: float = chaise_w * 0.5 - 0.012
	for i in range(n_welt):
		var fw: float = float(i) / float(n_welt)
		var th: float = fw * TAU
		var wx: float = welt_a * _sgn_pow(cos(th), 0.42)
		var wz: float = welt_b * _sgn_pow(sin(th), 0.42)
		_ball(root, Vector3(wx, seat_y - cush_h * 0.30, wz), 0.013, mat_velvet_deep)

	if seat_kind == "mirror":
		# a second chaise grows out of the seat back on a stack of cushions and
		# hangs upside down over the sleeper, its four legs in the air
		var mirror_y: float = seat_y + 0.40
		var twin_xf: Transform3D = Transform3D(Basis(Vector3(0.0, 0.0, 1.0), PI), Vector3(0.0, mirror_y * 2.0, 0.0))
		_twin_chaise(root, twin_xf, chaise_l, chaise_w, cush_h, leg_h, frame_h, roll_r, sd,
			mat_velvet, mat_velvet_deep, mat_wood)
		for i in range(5):
			var fg: float = (float(i) + 0.5) / 5.0
			var gy: float = lerpf(seat_y + cush_h * 0.20, mirror_y * 2.0 - (leg_h + frame_h + cush_h), fg)
			var gr: float = lerpf(0.175, 0.095, absf(fg - 0.5) * 2.0)
			var grow: ArrayMesh = _superblock(Vector3(gr, 0.052, gr * 0.72), 0.34, 0.40, 18, 10, 0.0,
				Vector3(0.009, 0.005, 0.010))
			var mat_grow: StandardMaterial3D = mat_velvet_deep if (i % 2) == 0 else mat_velvet
			var grow_mi: MeshInstance3D = _add(root, grow, mat_grow)
			grow_mi.transform = Transform3D(Basis(Vector3.UP, float(i) * 0.55), Vector3(-sd * chaise_l * 0.24, gy, -chaise_w * 0.14))

	# =========================================================================
	# grey draped cushions
	# =========================================================================
	for i in range(n_pillow):
		var fp: float = float(i) / float(maxi(n_pillow - 1, 1))
		var px: float = sd * lerpf(chaise_l * 0.5 - roll_r * 2.1, -chaise_l * 0.10, fp) + rng.randf_range(-0.03, 0.03)
		var pz: float = lerpf(-chaise_w * 0.20, chaise_w * 0.10, fp) + rng.randf_range(-0.04, 0.04)
		var pw: float = rng.randf_range(0.150, 0.190)
		var pd: float = rng.randf_range(0.135, 0.175)
		var ph: float = rng.randf_range(0.048, 0.068)
		# a melting room slumps its cushions too: wider, and half the loft
		pw = pw * (1.0 + 0.42 * melt_k)
		pd = pd * (1.0 + 0.42 * melt_k)
		ph = ph * (1.0 - 0.56 * melt_k)
		var pill: ArrayMesh = _superblock(Vector3(pw, ph, pd), 0.48, 0.55, 20, 12, 0.012,
			Vector3(rng.randf_range(0.006, 0.014), rng.randf_range(0.006, 0.013), rng.randf_range(0.006, 0.014)))
		var pb: Basis = Basis(Vector3.UP, rng.randf_range(-0.7, 0.7)) * Basis(Vector3.RIGHT, rng.randf_range(-0.45, 0.15)) * Basis(Vector3(0.0, 0.0, 1.0), rng.randf_range(-0.3, 0.3))
		var p_org: Vector3 = Vector3(px, seat_y + ph * 0.75, pz)
		var mat_pill: StandardMaterial3D = mat_grey_a if (i % 2) == 0 else mat_grey_b
		var pm: MeshInstance3D = _add(root, pill, mat_pill)
		pm.transform = Transform3D(pb, p_org)
		for k in range(3):
			var fr: float = (float(k) + 0.5) / 3.0
			var ridge := SphereMesh.new()
			ridge.radius = 0.030
			ridge.height = 0.060
			# a fold running front-to-back across the pillow face
			var rb: Basis = pb * _scale_basis(Vector3(0.30, 0.28, pd * 25.0))
			var ridge_mi: MeshInstance3D = _add(root, ridge, mat_pill)
			var local_r: Vector3 = Vector3(lerpf(-pw * 0.62, pw * 0.62, fr), ph * 0.66, rng.randf_range(-pd * 0.16, pd * 0.16))
			ridge_mi.transform = Transform3D(rb, p_org + pb * local_r)

	# =========================================================================
	# the reclining body
	#
	# every joint is solved first, as one whole skeleton, and only then drawn —
	# so the swarm, the cage and the bloom all hang on exactly the pose that the
	# sprawl has, and the repose axis argues about FLESH, never about gesture.
	# =========================================================================
	var fat: float = 1.0 + 0.30 * melt_k
	var pelvis: Vector3 = Vector3(sd * 0.015, seat_y + 0.125, -0.010)

	# spine: integrate a curving lean, then normalise to the wanted torso length
	var dirs: Array = []
	for i in range(n_torso):
		var t: float = float(i) / float(n_torso - 1)
		var ang: float = lean + spine_bend * sin(PI * t)
		var d: Vector3 = Vector3(sd * cos(ang), sin(ang), torso_z * (1.0 - t * 0.45))
		d = d.normalized()
		dirs.append(d)
	var step: float = torso_len / float(n_torso - 1)

	var pts: Array = []
	var p: Vector3 = pelvis
	pts.append(p)
	for i in range(1, n_torso):
		var d: Vector3 = dirs[i - 1]
		p = p + d * step
		pts.append(p)

	var torso_keys: Array = [0.118, 0.108, 0.098, 0.093, 0.098, 0.110, 0.120, 0.108]
	var shoulder: Vector3 = pts[n_torso - 1]
	var hip_l: Vector3 = pelvis + Vector3(-sd * 0.020, -0.020, 0.088)
	var hip_r: Vector3 = pelvis + Vector3(-sd * 0.020, -0.020, -0.088)

	# neck and head, tipped back over the rolled arm
	var neck_ang: float = lean - neck_drop
	var neck_dir: Vector3 = Vector3(sd * cos(neck_ang), sin(neck_ang), torso_z * 0.30)
	neck_dir = neck_dir.normalized()
	var head_c: Vector3 = shoulder + neck_dir * (head_r + 0.075)

	# the propping arm (behind, elbow into the cushion)
	var sh_back: Vector3 = shoulder + Vector3(0.0, -0.012, -0.112)
	var elbow_b: Vector3 = Vector3(sh_back.x - sd * 0.030, seat_y + prop_drop, sh_back.z - 0.055)
	var hand_b: Vector3 = Vector3(elbow_b.x + sd * 0.205, seat_y + prop_drop * 0.62, elbow_b.z + 0.030)

	# the free arm, draped over the front edge
	var sh_front: Vector3 = shoulder + Vector3(0.0, -0.012, 0.112)
	var elbow_f: Vector3 = Vector3(sh_front.x - sd * 0.030, sh_front.y - 0.165, sh_front.z + drape_out)
	var hand_f: Vector3 = Vector3(elbow_f.x - sd * 0.075, elbow_f.y - 0.170, elbow_f.z + drape_out * 0.80)

	# the legs, knees drawn up unevenly
	var knee_l: Vector3 = Vector3(hip_l.x - sd * reach_a, hip_l.y + knee_a, hip_l.z + 0.035)
	var ankle_l: Vector3 = Vector3(knee_l.x - sd * reach_b, seat_y + 0.058, knee_l.z + 0.012)
	var knee_r: Vector3 = Vector3(hip_r.x - sd * (reach_a + 0.065), hip_r.y + knee_b, hip_r.z - 0.028)
	var ankle_r: Vector3 = Vector3(knee_r.x - sd * (reach_b + 0.030), seat_y + 0.052, knee_r.z - 0.012)

	# the two feet
	var foot_dir: Vector3 = Vector3(-sd * 0.94, -0.14, 0.31)
	foot_dir = foot_dir.normalized()
	var foot_c: Vector3 = ankle_l + foot_dir * 0.058 + Vector3(0.0, -0.014, 0.0)
	var foot2_dir: Vector3 = Vector3(-sd * 0.90, -0.34, -0.27)
	foot2_dir = foot2_dir.normalized()
	var foot2_tip: Vector3 = ankle_r + foot2_dir * 0.095

	# --- the melt: the whole skeleton sinks toward the seat and slides outward,
	# and whatever already hung below the seat runs on down to the floor -------
	if melt_k > 0.0:
		for i in range(pts.size()):
			var mp: Vector3 = pts[i]
			pts[i] = _melt_p(mp, seat_y, melt_k)
		pelvis = _melt_p(pelvis, seat_y, melt_k)
		shoulder = _melt_p(shoulder, seat_y, melt_k)
		hip_l = _melt_p(hip_l, seat_y, melt_k)
		hip_r = _melt_p(hip_r, seat_y, melt_k)
		head_c = _melt_p(head_c, seat_y, melt_k)
		sh_back = _melt_p(sh_back, seat_y, melt_k)
		elbow_b = _melt_p(elbow_b, seat_y, melt_k)
		hand_b = _melt_p(hand_b, seat_y, melt_k)
		sh_front = _melt_p(sh_front, seat_y, melt_k)
		elbow_f = _melt_p(elbow_f, seat_y, melt_k)
		hand_f = _melt_p(hand_f, seat_y, melt_k)
		knee_l = _melt_p(knee_l, seat_y, melt_k)
		ankle_l = _melt_p(ankle_l, seat_y, melt_k)
		knee_r = _melt_p(knee_r, seat_y, melt_k)
		ankle_r = _melt_p(ankle_r, seat_y, melt_k)
		foot_c = _melt_p(foot_c, seat_y, melt_k)
		foot2_tip = _melt_p(foot2_tip, seat_y, melt_k)

	var spine_dir: Vector3 = _tangent(pts, n_torso - 1)

	# the head turns: the yaw moves the chin and the ears with the skull, so the
	# gesture is in the geometry and not only in one invisible ellipsoid
	var face_dir: Vector3 = Vector3(sd * 0.55, 0.16, 0.81)
	face_dir = (Basis(Vector3.UP, head_yaw) * face_dir).normalized()
	var ear_axis: Vector3 = face_dir.cross(Vector3.UP).normalized()
	var head_basis: Basis = _basis_y_to(neck_dir) * Basis(Vector3.UP, head_yaw * 0.6)

	# the bone list — the same skeleton the flesh hangs on, handed to the swarm
	# and the cage so a scattered body keeps the reclining pose
	var bones: Array = []
	if repose == "swarm" or repose == "cage":
		for i in range(n_torso - 1):
			bones.append([pts[i], pts[i + 1], _profile(torso_keys, float(i) / float(n_torso - 1))])
		bones.append([hip_l, hip_r, 0.082])
		bones.append([shoulder + Vector3(0.0, 0.0, -0.108), shoulder + Vector3(0.0, 0.0, 0.108), 0.062])
		bones.append([shoulder, head_c, 0.045])
		bones.append([sh_back, elbow_b, 0.055])
		bones.append([elbow_b, hand_b, 0.045])
		bones.append([sh_front, elbow_f, 0.052])
		bones.append([elbow_f, hand_f, 0.042])
		bones.append([hip_l, knee_l, 0.078])
		bones.append([knee_l, ankle_l, 0.058])
		bones.append([ankle_l, foot_c, 0.050])
		bones.append([hip_r, knee_r, 0.076])
		bones.append([knee_r, ankle_r, 0.056])
		bones.append([ankle_r, foot2_tip, 0.042])

	if repose == "swarm":
		_swarm_body(root, bones, rng, mat_suit, mat_skin, head_c, head_r)
	elif repose == "cage":
		_cage_body(root, bones, mat_bone, head_c, head_r, neck_dir)
	else:
		# --- the flesh --------------------------------------------------------
		for i in range(n_torso):
			var t: float = float(i) / float(n_torso - 1)
			var q: Vector3 = pts[i]
			var r: float = _profile(torso_keys, t)
			var tang: Vector3 = _tangent(pts, i)
			var seg := SphereMesh.new()
			seg.radius = r * fat
			seg.height = r * fat * 2.0
			var seg_mi: MeshInstance3D = _add(root, seg, mat_suit)
			seg_mi.transform = Transform3D(_basis_y_to(tang) * _scale_basis(Vector3(1.0 + 0.30 * melt_k, 0.86 - 0.44 * melt_k, 1.06 + 0.30 * melt_k)), q)

		# pelvis block and the two hips
		var hip_mesh := SphereMesh.new()
		hip_mesh.radius = 0.125 * fat
		hip_mesh.height = 0.250 * fat
		var hip_mi: MeshInstance3D = _add(root, hip_mesh, mat_suit)
		hip_mi.transform = Transform3D(_basis_y_to(spine_dir) * _scale_basis(Vector3(1.0, 0.78 - 0.40 * melt_k, 1.10)), pelvis + Vector3(0.0, -0.010, 0.0))
		_ball(root, hip_l, 0.082 * fat, mat_suit)
		_ball(root, hip_r, 0.082 * fat, mat_suit)

		# clavicle bar
		_limb(root, shoulder + Vector3(0.0, 0.0, -0.108), shoulder + Vector3(0.0, 0.0, 0.108), 0.062 * fat, mat_suit)

		# the bodysuit runs up into a collar, so the neck is striped and the head is bare
		_limb(root, shoulder + Vector3(0.0, 0.02, 0.0), head_c - neck_dir * (head_r * 0.55), 0.045 * fat, mat_suit)

		var skull := SphereMesh.new()
		skull.radius = head_r
		skull.height = head_r * 2.0
		skull.radial_segments = 28
		skull.rings = 16
		var skull_mi: MeshInstance3D = _add(root, skull, mat_skin)
		skull_mi.transform = Transform3D(head_basis * _scale_basis(Vector3(0.94 + 0.34 * melt_k, 1.06 - 0.52 * melt_k, 0.96 + 0.34 * melt_k)), head_c)
		_ball(root, head_c + face_dir * (head_r * 0.62) + Vector3(0.0, -head_r * 0.52, 0.0), head_r * 0.60, mat_skin)
		for i in range(2):
			var es: float = 1.0 if i == 0 else -1.0
			var ear := SphereMesh.new()
			ear.radius = 0.030
			ear.height = 0.060
			var ear_mi: MeshInstance3D = _add(root, ear, mat_skin)
			ear_mi.transform = Transform3D(_basis_y_to(ear_axis) * _scale_basis(Vector3(0.95, 0.35, 1.15)), head_c + ear_axis * (es * head_r * 0.92) - Vector3(0.0, head_r * 0.10, 0.0))

		# --- the propping arm (behind, elbow into the cushion) ----------------
		_limb(root, sh_back, elbow_b, 0.055 * fat, mat_suit)
		_limb(root, elbow_b, hand_b, 0.045 * fat, mat_suit)
		if repose == "bloom":
			_bloom(root, hand_b, Vector3(sd * 0.86, -0.22, 0.22).normalized(), mat_petal, mat_skin, 0.120, 8)
		else:
			_hand(root, hand_b, Vector3(sd * 0.86, -0.22, 0.22).normalized(), Vector3(0.0, 0.0, 1.0), mat_skin)

		# --- the free arm, draped over the front edge -------------------------
		_limb(root, sh_front, elbow_f, 0.052 * fat, mat_suit)
		_limb(root, elbow_f, hand_f, 0.042 * fat, mat_suit)
		if repose == "bloom":
			_bloom(root, hand_f, Vector3(-sd * 0.20, -0.92, 0.34).normalized(), mat_petal, mat_skin, 0.120, 8)
		else:
			_hand(root, hand_f, Vector3(-sd * 0.20, -0.92, 0.34).normalized(), Vector3(1.0, 0.0, 0.0), mat_skin)

		# --- the legs, knees drawn up unevenly --------------------------------
		_limb(root, hip_l, knee_l, 0.078 * fat, mat_suit)
		_limb(root, knee_l, ankle_l, 0.058 * fat, mat_suit)
		_ball(root, ankle_l, 0.050 * fat, mat_suit)
		_limb(root, hip_r, knee_r, 0.076 * fat, mat_suit)
		_limb(root, knee_r, ankle_r, 0.056 * fat, mat_suit)
		_ball(root, ankle_r, 0.048 * fat, mat_suit)

		# the bare foot (front leg), toes fanned — or opened into a flower
		if repose == "bloom":
			_bloom(root, foot_c, foot_dir, mat_petal, mat_skin, 0.108, 8)
		else:
			var foot_mesh := SphereMesh.new()
			foot_mesh.radius = 0.055
			foot_mesh.height = 0.110
			var foot_mi: MeshInstance3D = _add(root, foot_mesh, mat_skin)
			foot_mi.transform = Transform3D(_basis_y_to(foot_dir) * _scale_basis(Vector3(0.86, 1.35, 0.66)), foot_c)
			var toe_axis: Vector3 = foot_dir.cross(Vector3.UP).normalized()
			for i in range(5):
				var ft: float = (float(i) - 2.0) / 2.0
				var tr: float = lerpf(0.017, 0.011, absf(ft))
				var tp: Vector3 = foot_c + foot_dir * (0.062 - absf(ft) * 0.010) + toe_axis * (ft * 0.026) + Vector3(0.0, -0.014, 0.0)
				_ball(root, tp, tr, mat_skin)

		# the other foot, still inside the bodysuit
		_limb(root, ankle_r, foot2_tip, 0.042 * fat, mat_suit)

		if repose == "bloom":
			# the second foot flowers too, a crown opens off the skull, and the
			# cushion puts up three more on stems: the chaise as a flowerbed
			_bloom(root, foot2_tip + foot2_dir * 0.022, foot2_dir, mat_petal, mat_skin, 0.096, 7)
			_bloom(root, head_c + Vector3(0.0, head_r * 0.82, 0.0), Vector3(0.0, 1.0, 0.0), mat_petal, mat_skin, 0.102, 9)
			for i in range(3):
				var fb: float = float(i) / 2.0
				var bx0: float = sd * lerpf(-chaise_l * 0.38, chaise_l * 0.14, fb)
				var bz0: float = lerpf(chaise_w * 0.30, -chaise_w * 0.24, fb)
				var stem_top: Vector3 = Vector3(bx0 * 0.86, seat_y + 0.215 + float(i) * 0.052, bz0 * 0.70)
				_limb(root, Vector3(bx0, seat_y - 0.020, bz0), stem_top, 0.012, mat_velvet_deep)
				_bloom(root, stem_top, Vector3(0.0, 1.0, 0.0), mat_petal, mat_skin, 0.086, 6)

	if repose == "melt":
		# the suit itself pours off the seat: flat lobes pooling on the floor,
		# and strands still running down over the edge of the cushion
		for i in range(12):
			var ang_p: float = rng.randf_range(0.0, TAU)
			var rad_p: float = rng.randf_range(chaise_w * 0.36, chaise_l * 0.50)
			var lr_p: float = rng.randf_range(0.070, 0.155)
			var lobe_p := SphereMesh.new()
			lobe_p.radius = lr_p
			lobe_p.height = lr_p * 2.0
			lobe_p.radial_segments = 14
			lobe_p.rings = 7
			var mat_lobe: StandardMaterial3D = mat_velvet if (i % 3) == 0 else mat_suit
			var lobe_mi: MeshInstance3D = _add(root, lobe_p, mat_lobe)
			lobe_mi.transform = Transform3D(
				_scale_basis(Vector3(1.28, 0.085, 1.28)),
				Vector3(cos(ang_p) * rad_p, lr_p * 0.085 + 0.004, sin(ang_p) * rad_p * 0.86))
		for i in range(6):
			var ang_d: float = TAU * float(i) / 6.0 + rng.randf_range(-0.25, 0.25)
			var dx: float = cos(ang_d) * chaise_l * 0.44
			var dz: float = sin(ang_d) * chaise_w * 0.52
			_limb(root, Vector3(dx, seat_y - cush_h * 0.40, dz), Vector3(dx * 1.16, 0.022, dz * 1.16), rng.randf_range(0.016, 0.030), mat_suit)

	# =========================================================================
	# the black patent shoe, left on the floor
	# =========================================================================
	var shoe_basis: Basis = Basis(Vector3.UP, shoe_yaw)
	if repose == "melt":
		shoe_basis = shoe_basis * _scale_basis(Vector3(1.28, 0.34, 1.28))
	var shoe_xf: Transform3D = Transform3D(shoe_basis, Vector3(-sd * shoe_x, 0.0, chaise_w * 0.5 + shoe_z))
	_shoe(root, shoe_xf, mat_patent, rng)

	# =========================================================================
	# settle: measure, fit, centre on x/z, stand on y = 0
	# =========================================================================
	var box: AABB = _union_aabb(root)
	var bx: float = maxf(box.size.x, 0.001)
	var by: float = maxf(box.size.y, 0.001)
	var bz: float = maxf(box.size.z, 0.001)
	# 1.20 wide / 1.20 deep / 1.68 tall are the ceilings; 1.12 is the height the
	# statue is flown to when the footprint has the room for it.
	var k: float = minf(minf(1.20 / bx, 1.20 / bz), minf(1.68 / by, 1.12 / by))
	if absf(k - 1.0) > 0.0005:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cmi: MeshInstance3D = ch
			var tf: Transform3D = cmi.transform
			cmi.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), tf.origin * k)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift: Vector3 = Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi2: MeshInstance3D = ch
		cmi2.transform = Transform3D(cmi2.transform.basis, cmi2.transform.origin + shift)


# ---------------------------------------------------------------------------
# the shoe

static func _shoe(root: Node3D, xf: Transform3D, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var ln: float = rng.randf_range(0.150, 0.172)
	var arch: float = rng.randf_range(0.062, 0.082)
	var thick: float = 0.011
	var stations: int = 12
	var sole: ArrayMesh = _sole_mesh(ln, thick, arch, stations)
	var sm: MeshInstance3D = _add(root, sole, mat)
	sm.transform = xf

	var z_toe: float = -ln * 0.56
	var z_heel: float = ln * 0.44
	# stiletto
	var heel_top: Vector3 = Vector3(0.0, arch + thick * 0.4, z_heel - 0.008)
	var heel_bot: Vector3 = Vector3(0.0, 0.008, z_heel + 0.026)
	var d: Vector3 = heel_bot - heel_top
	var hl: float = maxf(d.length(), 0.01)
	var heel := CylinderMesh.new()
	heel.top_radius = 0.017
	heel.bottom_radius = 0.008
	heel.height = hl
	heel.radial_segments = 12
	var hm: MeshInstance3D = _add(root, heel, mat)
	hm.transform = xf * Transform3D(_basis_y_to(-d), (heel_top + heel_bot) * 0.5)
	var tap := CylinderMesh.new()
	tap.top_radius = 0.009
	tap.bottom_radius = 0.008
	tap.height = 0.008
	tap.radial_segments = 10
	var tm: MeshInstance3D = _add(root, tap, mat)
	tm.transform = xf * Transform3D(Basis(), Vector3(heel_bot.x, 0.004, heel_bot.z))

	# toe cap
	var cap := SphereMesh.new()
	cap.radius = 0.030
	cap.height = 0.060
	var cap_mi: MeshInstance3D = _add(root, cap, mat)
	cap_mi.transform = xf * Transform3D(_scale_basis(Vector3(0.72, 0.42, 1.30)), Vector3(0.0, thick + 0.006, z_toe + 0.030))

	# two bowed vamp straps
	for i in range(2):
		var fs: float = 0.30 + float(i) * 0.14
		var zs: float = lerpf(z_toe, z_heel, fs)
		var yb: float = arch * pow(clampf((fs - 0.22) / 0.78, 0.0, 1.0), 1.7) + thick
		var half: float = lerpf(0.036, 0.028, float(i))
		var apex: Vector3 = Vector3(0.0, yb + 0.030, zs)
		for k in range(2):
			var hs: float = 1.0 if k == 0 else -1.0
			var anchor: Vector3 = Vector3(hs * half, yb - 0.002, zs)
			var strap: MeshInstance3D = _limb(root, anchor, apex, 0.008, mat)
			strap.transform = xf * strap.transform

	# ankle strap
	var zk: float = lerpf(z_toe, z_heel, 0.80)
	var yk: float = arch * pow(clampf((0.80 - 0.22) / 0.78, 0.0, 1.0), 1.7) + thick
	var ring := TorusMesh.new()
	ring.inner_radius = 0.028
	ring.outer_radius = 0.036
	ring.rings = 20
	ring.ring_segments = 10
	var ring_mi: MeshInstance3D = _add(root, ring, mat)
	ring_mi.transform = xf * Transform3D(Basis(Vector3.RIGHT, 0.30), Vector3(0.0, yk + 0.042, zk))


static func _sole_mesh(ln: float, thick: float, arch: float, n: int) -> ArrayMesh:
	var wkeys: Array = [0.016, 0.028, 0.036, 0.035, 0.027, 0.020, 0.019, 0.022, 0.026, 0.024, 0.017]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lt: Array = []
	var rt: Array = []
	var lb: Array = []
	var rb: Array = []
	for i in range(n):
		var f: float = float(i) / float(n - 1)
		var z: float = lerpf(-ln * 0.56, ln * 0.44, f)
		var w: float = _profile(wkeys, f)
		var yb: float = arch * pow(clampf((f - 0.22) / 0.78, 0.0, 1.0), 1.7)
		var yt: float = yb + thick + 0.004 * sin(PI * f)
		lt.append(Vector3(-w, yt, z))
		rt.append(Vector3(w, yt, z))
		lb.append(Vector3(-w * 0.92, yb, z))
		rb.append(Vector3(w * 0.92, yb, z))
	for i in range(n - 1):
		_quad_dir(st, lt[i], rt[i], rt[i + 1], lt[i + 1], Vector3.UP)
		_quad_dir(st, lb[i], rb[i], rb[i + 1], lb[i + 1], Vector3.DOWN)
		_quad_dir(st, lt[i], lb[i], lb[i + 1], lt[i + 1], Vector3.LEFT)
		_quad_dir(st, rt[i], rb[i], rb[i + 1], rt[i + 1], Vector3.RIGHT)
	_quad_dir(st, lt[0], rt[0], rb[0], lb[0], Vector3(0.0, 0.0, -1.0))
	_quad_dir(st, lt[n - 1], rt[n - 1], rb[n - 1], lb[n - 1], Vector3(0.0, 0.0, 1.0))
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# the repose axis — melt, swarm, cage, bloom.
#
# All four are handed the SAME solved skeleton the sprawl is drawn from, so what
# changes is the flesh and never the gesture. Nothing here reads a file, nothing
# here draws its own random numbers except from the rng build() already seeded.

static func _melt_p(p: Vector3, seat_y: float, k: float) -> Vector3:
	# One joint, sagged. Everything standing above the seat drops to a fifth of
	# its height; anything that already hung below it runs on down and pools just
	# clear of the floor; and the further a joint is from the seat plane the
	# further it slides outward, so the body spreads as it collapses.
	var above: float = p.y - seat_y
	var y_out: float = seat_y
	if above >= 0.0:
		y_out = seat_y + above * lerpf(1.0, 0.20, k)
	else:
		var below: float = -above
		var run: float = lerpf(below, below * 2.1 + seat_y * 0.30, k)
		y_out = maxf(seat_y - run, 0.028)
	var reach: float = clampf(absf(above) / 0.30, 0.30, 1.0)
	var spread: float = 1.0 + 0.62 * k * reach
	return Vector3(p.x * spread, y_out, p.z * spread)


static func _swarm_body(root: Node3D, bones: Array, rng: RandomNumberGenerator, mat_suit: StandardMaterial3D, mat_skin: StandardMaterial3D, head_c: Vector3, head_r: float) -> void:
	# The figure is gone. Every bone is replaced by a short string of small
	# copies of itself — stubby striped capsules, drifted off the bone's own axis
	# and spun — so the reclining pose survives as a cloud with the flesh taken
	# out of it. The skull goes the same way: a shell of skin-coloured motes.
	for i in range(bones.size()):
		var bone: Array = bones[i]
		var a: Vector3 = bone[0]
		var b: Vector3 = bone[1]
		var r: float = float(bone[2])
		var d: Vector3 = b - a
		var ln: float = maxf(d.length(), 0.004)
		var ax: Vector3 = d / ln
		var side: Vector3 = ax.cross(Vector3.UP)
		if side.length() < 0.001:
			side = Vector3(0.0, 0.0, 1.0)
		side = side.normalized()
		var lift: Vector3 = side.cross(ax).normalized()
		var n: int = clampi(int(ln / 0.055) + 2, 2, 4)
		for m in range(n):
			var f: float = (float(m) + 0.5) / float(n)
			var drift: float = r * 1.85
			var at: Vector3 = a + ax * (ln * f)
			at += side * rng.randf_range(-drift, drift)
			at += lift * rng.randf_range(-drift * 0.85, drift * 0.85)
			at += ax * rng.randf_range(-ln * 0.10, ln * 0.10)
			var cr: float = r * rng.randf_range(0.26, 0.46)
			var cl: float = ln * rng.randf_range(0.14, 0.28)
			var mote := CapsuleMesh.new()
			mote.radius = cr
			mote.height = cl + cr * 2.0
			mote.radial_segments = 10
			mote.rings = 4
			var spin: Basis = Basis(side, rng.randf_range(-0.95, 0.95)) * Basis(lift, rng.randf_range(-0.95, 0.95))
			var mi: MeshInstance3D = _add(root, mote, mat_suit)
			mi.transform = Transform3D(spin * _basis_y_to(ax), at)
	for i in range(8):
		var fh: float = (float(i) + 0.5) / 8.0
		var th: float = TAU * fh * 2.0
		var ph: float = acos(clampf(1.0 - 2.0 * fh, -1.0, 1.0))
		var dirh: Vector3 = Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th))
		var at_h: Vector3 = head_c + dirh * (head_r * rng.randf_range(0.72, 1.36))
		var rr: float = head_r * rng.randf_range(0.24, 0.38)
		var mote_h: MeshInstance3D = _ball(root, at_h, rr, mat_skin)
		mote_h.transform = Transform3D(_basis_y_to(dirh) * _scale_basis(Vector3(1.18, 0.70, 1.18)), at_h)


static func _cage_body(root: Node3D, bones: Array, mat: StandardMaterial3D, head_c: Vector3, head_r: float, neck_dir: Vector3) -> void:
	# The flesh is off. What is left is an armature: a thin pale rod down the
	# middle of every bone with two to four hoops threaded on it, each hoop cut
	# to the radius the muscle used to have, fattest at mid-bone. The skull is
	# three great rings crossed at right angles, still carried on the neck's tilt.
	for i in range(bones.size()):
		var bone: Array = bones[i]
		var a: Vector3 = bone[0]
		var b: Vector3 = bone[1]
		var r: float = float(bone[2])
		var d: Vector3 = b - a
		var ln: float = maxf(d.length(), 0.004)
		var ax: Vector3 = d / ln
		_limb(root, a, b, maxf(r * 0.16, 0.006), mat)
		var n: int = clampi(int(ln / 0.052) + 2, 2, 4)
		for m in range(n):
			var f: float = (float(m) + 0.5) / float(n)
			var ring_r: float = r * lerpf(1.18, 0.84, absf(f - 0.5) * 2.0)
			var tube: float = maxf(r * 0.13, 0.005)
			var hoop := TorusMesh.new()
			hoop.inner_radius = maxf(ring_r - tube, 0.004)
			hoop.outer_radius = ring_r + tube
			hoop.rings = 16
			hoop.ring_segments = 8
			var mi: MeshInstance3D = _add(root, hoop, mat)
			mi.transform = Transform3D(_basis_y_to(ax), a + ax * (ln * f))
	var skull_r: float = head_r * 1.32
	for i in range(3):
		var ring := TorusMesh.new()
		ring.inner_radius = maxf(skull_r - 0.011, 0.006)
		ring.outer_radius = skull_r + 0.011
		ring.rings = 24
		ring.ring_segments = 8
		var rb: Basis = Basis()
		if i == 1:
			rb = Basis(Vector3.RIGHT, PI * 0.5)
		elif i == 2:
			rb = Basis(Vector3(0.0, 0.0, 1.0), PI * 0.5)
		var mi_r: MeshInstance3D = _add(root, ring, mat)
		mi_r.transform = Transform3D(_basis_y_to(neck_dir) * rb, head_c)


static func _bloom(root: Node3D, at: Vector3, dir: Vector3, mat_petal: StandardMaterial3D, mat_core: StandardMaterial3D, size: float, petals: int) -> void:
	# A limb ends in a flower instead of a hand. The petals are flattened
	# spheroids swept round the limb's own direction and raked outward, each one
	# thin along the flower's axis so it reads as a blade and not as a bead; a
	# squat core sits in the middle with two stamens standing out of it.
	var d: Vector3 = dir.normalized()
	var side: Vector3 = d.cross(Vector3.UP)
	if side.length() < 0.001:
		side = Vector3(1.0, 0.0, 0.0)
	side = side.normalized()
	var lift: Vector3 = side.cross(d).normalized()
	var n: int = maxi(petals, 3)
	for i in range(n):
		var th: float = TAU * float(i) / float(n)
		var radial: Vector3 = (side * cos(th) + lift * sin(th)).normalized()
		var tilt: float = 0.42 + 0.16 * sin(float(i) * 1.7)
		var out_dir: Vector3 = (radial * cos(tilt) + d * sin(tilt)).normalized()
		var px: Vector3 = out_dir.cross(d)
		if px.length() < 0.001:
			px = side
		px = px.normalized()
		var py: Vector3 = out_dir.cross(px).normalized()
		var petal := SphereMesh.new()
		petal.radius = size * 0.5
		petal.height = size
		petal.radial_segments = 12
		petal.rings = 7
		var mi: MeshInstance3D = _add(root, petal, mat_petal)
		mi.transform = Transform3D(
			Basis(px, py, out_dir) * _scale_basis(Vector3(0.46, 0.13, 1.15)),
			at + d * (size * 0.12) + out_dir * (size * 0.52))
	var core_at: Vector3 = at + d * (size * 0.16)
	var core: MeshInstance3D = _ball(root, core_at, size * 0.28, mat_core)
	core.transform = Transform3D(_basis_y_to(d) * _scale_basis(Vector3(1.0, 0.66, 1.0)), core_at)
	for i in range(2):
		var fs: float = float(i) * 2.0 - 1.0
		var base_s: Vector3 = core_at + side * (fs * size * 0.10)
		var tip_s: Vector3 = base_s + (d * 0.90 + side * (fs * 0.36)).normalized() * (size * 0.44)
		_limb(root, base_s, tip_s, maxf(size * 0.045, 0.004), mat_core)


# ---------------------------------------------------------------------------
# the seat axis — the stiletto that stands in for a leg, and the twin overhead

static func _prop_heel(root: Node3D, xf: Transform3D, mat: StandardMaterial3D, ln: float, lift: float) -> void:
	# One patent stiletto stood on its toe, holding the chaise up where a turned
	# wooden leg used to. The toe box takes the floor, the sole rakes up to the
	# underside of the frame, and the spike is thrown back into the air.
	var toe := SphereMesh.new()
	toe.radius = ln * 0.20
	toe.height = ln * 0.40
	toe.radial_segments = 14
	toe.rings = 8
	var toe_mi: MeshInstance3D = _add(root, toe, mat)
	toe_mi.transform = xf * Transform3D(_scale_basis(Vector3(0.72, 0.52, 1.26)), Vector3(0.0, ln * 0.105, ln * 0.18))

	var sole_lo: Vector3 = Vector3(0.0, ln * 0.10, ln * 0.10)
	var sole_hi: Vector3 = Vector3(0.0, maxf(lift, ln * 0.34), -ln * 0.10)
	var d: Vector3 = sole_hi - sole_lo
	var sl: float = maxf(d.length(), 0.01)
	var sole := CylinderMesh.new()
	sole.bottom_radius = ln * 0.19
	sole.top_radius = ln * 0.14
	sole.height = sl
	sole.radial_segments = 12
	var sole_mi: MeshInstance3D = _add(root, sole, mat)
	sole_mi.transform = xf * Transform3D(_basis_y_to(d), (sole_lo + sole_hi) * 0.5)

	var spike_a: Vector3 = sole_lo + d * 0.44
	var spike_b: Vector3 = spike_a + Vector3(0.0, ln * 0.28, ln * 0.50)
	var spike_d: Vector3 = spike_b - spike_a
	var spike := CylinderMesh.new()
	spike.bottom_radius = ln * 0.075
	spike.top_radius = ln * 0.030
	spike.height = maxf(spike_d.length(), 0.01)
	spike.radial_segments = 10
	var spike_mi: MeshInstance3D = _add(root, spike, mat)
	spike_mi.transform = xf * Transform3D(_basis_y_to(spike_d), (spike_a + spike_b) * 0.5)

	var strap := TorusMesh.new()
	strap.inner_radius = ln * 0.14
	strap.outer_radius = ln * 0.19
	strap.rings = 16
	strap.ring_segments = 8
	var strap_mi: MeshInstance3D = _add(root, strap, mat)
	strap_mi.transform = xf * Transform3D(_basis_y_to(d) * Basis(Vector3.RIGHT, 0.22), sole_lo + d * 0.62)


static func _twin_chaise(root: Node3D, xf: Transform3D, chaise_l: float, chaise_w: float, cush_h: float, leg_h: float, frame_h: float, roll_r: float, sd: float, mat_v: StandardMaterial3D, mat_vd: StandardMaterial3D, mat_w: StandardMaterial3D) -> void:
	# The same chaise a second time, built in the SAME local frame the first one
	# stands in — cushion, frame, four turned legs on ball feet, the fat rolled
	# arm, the low back. The caller's transform is what turns it over and hangs
	# it in the air, so the twin is the first one's own geometry seen upside down.
	var seat_top: float = leg_h + frame_h + cush_h

	var cushion: ArrayMesh = _superblock(
		Vector3(chaise_l * 0.5, cush_h * 0.5, chaise_w * 0.5),
		0.30, 0.36, 22, 12, cush_h * 0.10, Vector3.ZERO)
	var cm: MeshInstance3D = _add(root, cushion, mat_v)
	cm.transform = xf * Transform3D(Basis(), Vector3(0.0, leg_h + frame_h + cush_h * 0.5, 0.0))

	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(chaise_l * 0.95, frame_h, chaise_w * 0.90)
	var fm: MeshInstance3D = _add(root, frame_mesh, mat_vd)
	fm.transform = xf * Transform3D(Basis(), Vector3(0.0, leg_h + frame_h * 0.5, 0.0))

	for i in range(4):
		var lx: float = (chaise_l * 0.5 - 0.075) * (1.0 if (i % 2) == 0 else -1.0)
		var lz: float = (chaise_w * 0.5 - 0.065) * (1.0 if i < 2 else -1.0)
		var la: Vector3 = Vector3(lx, 0.030, lz)
		var lb: Vector3 = Vector3(lx * 1.03, leg_h + 0.01, lz * 1.03)
		var dl: Vector3 = lb - la
		var cyl := CylinderMesh.new()
		cyl.bottom_radius = 0.030
		cyl.top_radius = 0.020
		cyl.height = maxf(dl.length(), 0.01)
		cyl.radial_segments = 12
		var lm: MeshInstance3D = _add(root, cyl, mat_w)
		lm.transform = xf * Transform3D(_basis_y_to(dl), (la + lb) * 0.5)
		var foot := SphereMesh.new()
		foot.radius = 0.026
		foot.height = 0.052
		foot.radial_segments = 14
		foot.rings = 8
		var foot_mi: MeshInstance3D = _add(root, foot, mat_w)
		foot_mi.transform = xf * Transform3D(Basis(), Vector3(lx, 0.026, lz))

	var roll_x: float = sd * (chaise_l * 0.5 - roll_r * 0.78)
	var roll_y: float = seat_top + roll_r * 0.58
	var roll := CylinderMesh.new()
	roll.top_radius = roll_r
	roll.bottom_radius = roll_r
	roll.height = chaise_w * 0.96
	roll.radial_segments = 20
	var rm: MeshInstance3D = _add(root, roll, mat_v)
	rm.transform = xf * Transform3D(_basis_y_to(Vector3(0.0, 0.0, 1.0)), Vector3(roll_x, roll_y, 0.0))
	for i in range(2):
		var zs: float = 1.0 if i == 0 else -1.0
		var cap := SphereMesh.new()
		cap.radius = roll_r * 0.99
		cap.height = roll_r * 1.98
		cap.radial_segments = 18
		cap.rings = 10
		var cap_mi: MeshInstance3D = _add(root, cap, mat_v)
		cap_mi.transform = xf * Transform3D(Basis(), Vector3(roll_x, roll_y, zs * chaise_w * 0.48))

	var back_hl: float = chaise_l * 0.27
	var back_mesh: ArrayMesh = _superblock(Vector3(back_hl, 0.115, 0.050), 0.30, 0.34, 18, 10, 0.0, Vector3.ZERO)
	var bm: MeshInstance3D = _add(root, back_mesh, mat_v)
	bm.transform = xf * Transform3D(
		Basis(Vector3.RIGHT, -0.16),
		Vector3(sd * (chaise_l * 0.5 - back_hl - 0.012), seat_top + 0.085, -(chaise_w * 0.5 - 0.055)))


# ---------------------------------------------------------------------------
# shape helpers

static func _superblock(ext: Vector3, e1: float, e2: float, su: int, sv: int, sag: float, warp: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid: Array = []
	for j in range(sv + 1):
		var fv: float = float(j) / float(sv)
		var v: float = -PI * 0.5 + fv * PI
		var row: Array = []
		for i in range(su + 1):
			var fu: float = float(i) / float(su)
			var u: float = -PI + fu * TAU
			var cv: float = _sgn_pow(cos(v), e1)
			var yv: float = _sgn_pow(sin(v), e1)
			var cu: float = _sgn_pow(cos(u), e2)
			var zu: float = _sgn_pow(sin(u), e2)
			var q: Vector3 = Vector3(ext.x * cv * cu, ext.y * yv, ext.z * cv * zu)
			if yv > 0.0 and sag > 0.0:
				var rad: float = Vector2(q.x / maxf(ext.x, 0.001), q.z / maxf(ext.z, 0.001)).length()
				var dip: float = sag * yv * clampf(1.0 - rad, 0.0, 1.0)
				q.y -= dip
			if warp.length() > 0.0:
				var fade: float = 1.0 - absf(yv) * 0.6
				q += Vector3(warp.x * sin(u * 3.0 + v), warp.y * sin(v * 4.0), warp.z * cos(u * 2.0 - v)) * fade
			row.append(q)
		grid.append(row)
	for j in range(sv):
		var row0: Array = grid[j]
		var row1: Array = grid[j + 1]
		for i in range(su):
			_quad_out(st, row0[i], row0[i + 1], row1[i + 1], row1[i], Vector3.ZERO)
	st.generate_normals()
	return st.commit()


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	var centroid: Vector3 = (a + b + c + d) * 0.25
	_quad_dir(st, a, b, c, d, centroid - inside)


static func _quad_dir(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	# at a sweep pole a == b, so the first triangle is degenerate and carries no
	# winding: take the reading off the second triangle instead
	if nf.length_squared() < 1.0e-12:
		nf = (d - a).cross(c - a)
	if nf.dot(outward) >= 0.0:
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


static func _c(scheme: Array, i: int) -> Color:
	var code: String = scheme[i]
	return Color(code)


static func _sgn_pow(v: float, e: float) -> float:
	var a: float = absf(v)
	var q: float = pow(a, e)
	return q if v >= 0.0 else -q


static func _profile(keys: Array, t: float) -> float:
	var n: int = keys.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		return float(keys[n])
	var u: float = f - float(i)
	var va: float = float(keys[i])
	var vb: float = float(keys[i + 1])
	return lerpf(va, vb, u)


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.0001:
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


static func _scale_basis(v: Vector3) -> Basis:
	return Basis(Vector3(v.x, 0.0, 0.0), Vector3(0.0, v.y, 0.0), Vector3(0.0, 0.0, v.z))


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
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(Basis(), at)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _tapered_cyl(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 12
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _hand(root: Node3D, at: Vector3, point_dir: Vector3, fan_axis: Vector3, mat: StandardMaterial3D) -> void:
	var d: Vector3 = point_dir.normalized()
	var ax: Vector3 = fan_axis - d * fan_axis.dot(d)
	if ax.length() < 0.001:
		ax = Vector3(0.0, 0.0, 1.0)
	ax = ax.normalized()
	var palm := SphereMesh.new()
	palm.radius = 0.042
	palm.height = 0.084
	var pm: MeshInstance3D = _add(root, palm, mat)
	pm.transform = Transform3D(_basis_y_to(d) * _scale_basis(Vector3(0.95, 1.05, 0.55)), at)
	for i in range(4):
		var fi: float = (float(i) - 1.5) / 1.5
		var fl: float = lerpf(0.062, 0.046, absf(fi))
		var base: Vector3 = at + d * 0.030 + ax * (fi * 0.021)
		var tip: Vector3 = base + (d * 0.92 + ax * (fi * 0.30)).normalized() * fl
		_limb(root, base, tip, 0.011, mat)


# ---------------------------------------------------------------------------
# code-painted surfaces

static func _stripe_texture(rng: RandomNumberGenerator, cream: Color, coral: Color, periods: int, width_f: float) -> ImageTexture:
	var img: Image = Image.create(TEX_W, TEX_W, false, Image.FORMAT_RGB8)
	var per: float = float(TEX_W) / float(periods)
	var jw: Array = []
	var jt: Array = []
	for i in range(periods):
		jw.append(rng.randf_range(0.78, 1.24))
		jt.append(rng.randf_range(0.88, 1.10))
	var grain: Array = []
	for i in range(97):
		grain.append(rng.randf_range(-0.020, 0.020))
	for y in range(TEX_W):
		var fy: float = float(y)
		var knit: float = 1.0 - 0.038 * absf(sin(fy * PI / 3.0))
		var wander: float = 1.4 * sin(fy * 0.085) + 0.6 * sin(fy * 0.031 + 1.7)
		for x in range(TEX_W):
			var fx: float = float(x) + wander
			var cell: float = fx / per
			var idx: int = posmod(int(floor(cell)), periods)
			var u: float = cell - floor(cell)
			var half: float = 0.5 * width_f * float(jw[idx])
			var dist: float = absf(u - 0.5)
			var edge: float = clampf((half - dist) / 0.055, 0.0, 1.0)
			var tone: float = float(jt[idx])
			var gr: float = float(grain[posmod(x * 7 + y * 31, 97)])
			var rr: float = lerpf(cream.r, clampf(coral.r * tone, 0.0, 1.0), edge) * knit + gr
			var gg: float = lerpf(cream.g, clampf(coral.g * tone, 0.0, 1.0), edge) * knit + gr
			var bb: float = lerpf(cream.b, clampf(coral.b * tone, 0.0, 1.0), edge) * knit + gr
			img.set_pixel(x, y, Color(clampf(rr, 0.0, 1.0), clampf(gg, 0.0, 1.0), clampf(bb, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _velvet_texture(rng: RandomNumberGenerator, cells: int) -> ImageTexture:
	var img: Image = Image.create(VEL_W, VEL_W, false, Image.FORMAT_RGB8)
	var grid: Array = []
	for i in range(cells * cells):
		grid.append(rng.randf())
	var cw: float = float(VEL_W) / float(cells)
	for y in range(VEL_W):
		var gy: float = float(y) / cw
		var y0: int = int(floor(gy))
		var ty: float = gy - float(y0)
		var sy: float = ty * ty * (3.0 - 2.0 * ty)
		for x in range(VEL_W):
			var gx: float = float(x) / cw
			var x0: int = int(floor(gx))
			var tx: float = gx - float(x0)
			var sx: float = tx * tx * (3.0 - 2.0 * tx)
			var i00: float = float(grid[posmod(y0, cells) * cells + posmod(x0, cells)])
			var i10: float = float(grid[posmod(y0, cells) * cells + posmod(x0 + 1, cells)])
			var i01: float = float(grid[posmod(y0 + 1, cells) * cells + posmod(x0, cells)])
			var i11: float = float(grid[posmod(y0 + 1, cells) * cells + posmod(x0 + 1, cells)])
			var a: float = lerpf(i00, i10, sx)
			var b: float = lerpf(i01, i11, sx)
			var n: float = lerpf(a, b, sy)
			var nap: float = 0.022 * sin(float(x) * 0.62 + n * 5.0)
			var val: float = clampf(0.84 + 0.15 * n + nap, 0.0, 1.0)
			img.set_pixel(x, y, Color(val, val * 0.995, val))
	return ImageTexture.create_from_image(img)


static func _cloth(c: Color, tex: ImageTexture, rough: float, uv: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(uv, uv, uv)
	m.roughness = rough
	m.metallic = 0.0
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.2
	return m


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi: MeshInstance3D = ch
		if cmi.mesh == null:
			continue
		var local: AABB = cmi.mesh.get_aabb()
		var wb: AABB = cmi.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
