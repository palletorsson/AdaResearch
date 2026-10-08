extends RefCounted

## dream_bodies / horse_hybrid — one hunter from the baroque tapestry: pale marble
## nude, animal head, heavy cloak.
##
## Reference: scratchpad/refs/tapestry_david.png (2048x536 panorama) — a baroque
## hunt in which every rider and hound wears an ANIMAL HEAD on a smooth pale nude
## body: horse heads, wolf and greyhound heads in grey and cream, the figures
## draped in weighty cloaks of deep blue, teal and rose that fall in big angular
## folds and sweep out behind. I build ONE standing figure from the middle band —
## the striding, reaching nude with the long grey muzzle and the cloak over one
## shoulder.
##
## Reproduced, and how:
##   1. The smooth pale nude — an 11-sphere spine integrated from a keyed lean
##      angle (pelvis tipped into the stride, waist straightening, chest opening
##      again), every sphere flattened front-to-back and widened across by a
##      per-height ellipse scale so the silhouette reads as a torso and not a
##      string of beads; pecs, obliques, glutes, deltoids, collarbones and
##      shoulder blades hung on that spine as smaller spheres.
##   2. Marble skin — a 128x128 ImageTexture drawn in code (three seamless sine
##      ridge layers folded into thin grey veins over a bone ground), carried on
##      albedo_texture with WORLD triplanar so the veining runs unbroken across
##      the whole chain of capsules and spheres rather than restarting per part.
##   3. The striding, reaching pose — one leg forward with the foot flat, the
##      other extended back with the heel lifted and only the toe pad down; the
##      arm OPPOSITE the lead leg reaches forward and up, the other trails back
##      and low toward the cloak; shoulders twisted against the hips.
##   4. The horse head — a SurfaceTool swept tube for the muzzle: 11 elliptical
##      rings marching forward off the skull, drooping on a t^2 curve, pinching
##      behind the nostrils and flaring again at the tip, closed with a fan and
##      capped by a soft nose sphere with two dark nostrils; skull sphere, poll,
##      cheeks, a hinged jaw and chin, a dark lip line.
##   5. Two upright leaf ears — SurfaceTool grids (9 x 7) whose width follows a
##      sine lobe, sin(PI * (0.10 + 0.88t)^0.62), so the base has width and the
##      tip nearly closes; cupped by a cross-section bulge and curled forward on
##      a t^2 spine, with a smaller darker leaf inside each. Set on the poll,
##      splayed outward and pitched by seed, one cocked against the other.
##   6. Lateral dark eyes — set high on the SIDES of the skull the way a horse
##      carries them, each with a pale brow ridge cone over it.
##   7. The heavy cloak — two SurfaceTool sheets (26 x 14 quads) hung from an
##      arc that runs over one shoulder and around the back: each column drops,
##      flares outward and sweeps backward with depth, and is pushed in and out
##      along the body radius by a TRIANGLE wave — a triangle, not a sine, so the
##      creases come to sharp angular ridges. 4-8 folds, drifting phase with
##      depth so the folds lean; the hem length is modulated per column so the
##      lower edge is irregular. The outer sheet carries the seed's saturated
##      hue (deep blue, teal or rose), a second sheet 16 mm inside carries the
##      contrasting lining, both matte and double-sided, both vertex-shaded from
##      the fold wave so the creases read even in flat light. A gathered roll of
##      spheres sits over the shoulder to give the cloth its weight.
##   8. Mane — 7 to 12 short capsules along the crest from the poll down the neck.
##
## Given up: the horse the rider sits on, the second and third figures, the
## spear, the harness and bridle straps, the landscape, and any cloth that
## actually wraps a limb — the cloak hangs free from the shoulder arc rather
## than being tucked under the trailing arm.
##
## AXES (DNA):
##   beast — what the animal in the figure DOES to the body: horse (one head, as
##     built) · hydra (three horse heads on branching necks, splayed over the
##     shoulders) · reliquary (the flesh gone — bare toothed skull, hoops caging
##     the muzzle, the torso shrunk to a ribbed bone cage, no mane) · blossom
##     (the muzzle and both hands open into whorls of petals instead of nose and
##     fingers) · swarm (no single head at all: thirty small muzzled skulls
##     orbiting where it was and spilling down the shoulders).
##   cloak — what the cloth DOES: folds (two angular-folded sheets, as built) ·
##     flood (the cloth pours off the shoulder and sets SOLID, a poured cone
##     that swallows the figure from the waist down and puddles on the ground) ·
##     unravelling (the sheets gone to thirty-four hanging threads, air where the
##     cloth was) · shattered (the cloak burst into forty-five thin plates
##     hovering apart along their own surface normals).

const TEX_SIZE: int = 128
const PLINTH_TOP: float = 0.05

# [cloak outer, cloak lining, cloak shadow]
const CLOAKS: Array = [
	["#1B3A7C", "#B24C6E", "#101F49"],
	["#2A8A8C", "#1A4C63", "#12464A"],
	["#B8506F", "#25407F", "#6C2B45"],
	["#22508F", "#2A8A8C", "#122C58"],
	["#187C7E", "#C4677F", "#0D4446"],
	["#8E2F55", "#1B3A7C", "#511A31"],
]
# [head pale, head shade]
const HEADS: Array = [
	["#B6B1A9", "#8B857C"],
	["#D9D2C2", "#A79E8C"],
	["#C7C3BC", "#959088"],
	["#E2DCCC", "#B3A996"],
]
const BODY_TONES: Array = ["#EDE6DA", "#F1EBE1", "#E7DFD2"]


static func describe() -> String:
	return "A striding marble-pale nude with a long grey horse head and a heavy angular-folded cloak thrown over one shoulder, taken from a baroque hunt tapestry."


static func axes() -> Dictionary:
	return {
		"beast": ["horse", "hydra", "reliquary", "blossom", "swarm"],
		"cloak": ["folds", "flood", "unravelling", "shattered"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var beast: String = String(opts.get("beast", "horse"))
	var cloak_mode: String = String(opts.get("cloak", "folds"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# a SECOND stream for the variant-only draws, so the default path's use of
	# rng stays exactly where it was and the two axes stay independent
	var vrng := RandomNumberGenerator.new()
	vrng.seed = seed ^ 0x51AF

	# --- palette -------------------------------------------------------------
	var cloak_set: Array = CLOAKS[rng.randi_range(0, CLOAKS.size() - 1)]
	var head_set: Array = HEADS[rng.randi_range(0, HEADS.size() - 1)]
	var col_cloak: Color = _hex(cloak_set, 0)
	var col_lining: Color = _hex(cloak_set, 1)
	var col_cloak_dark: Color = _hex(cloak_set, 2)
	var col_head: Color = _hex(head_set, 0)
	var col_head_dark: Color = _hex(head_set, 1)
	var col_body: Color = _hex(BODY_TONES, rng.randi_range(0, BODY_TONES.size() - 1))

	var marble: ImageTexture = _marble_texture(rng)
	var weave: ImageTexture = _weave_texture(rng)

	var mat_body: StandardMaterial3D = _stone(col_body, 0.42)
	mat_body.albedo_texture = marble
	mat_body.uv1_triplanar = true
	mat_body.uv1_world_triplanar = true
	mat_body.uv1_scale = Vector3(0.75, 0.75, 0.75)

	var mat_head: StandardMaterial3D = _stone(col_head, 0.48)
	mat_head.albedo_texture = marble
	mat_head.uv1_triplanar = true
	mat_head.uv1_world_triplanar = true
	mat_head.uv1_scale = Vector3(1.1, 1.1, 1.1)

	var mat_head_dark: StandardMaterial3D = _stone(col_head_dark, 0.55)
	# the ears are open shells — they must be visible from both sides
	var mat_ear: StandardMaterial3D = mat_head.duplicate() as StandardMaterial3D
	mat_ear.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_ear_in: StandardMaterial3D = mat_head_dark.duplicate() as StandardMaterial3D
	mat_ear_in.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_dark: StandardMaterial3D = _stone(Color("#241E1B"), 0.22)
	var mat_roll: StandardMaterial3D = _stone(col_cloak.darkened(0.10), 0.88)
	mat_roll.clearcoat_enabled = false
	mat_roll.albedo_texture = weave
	mat_roll.uv1_triplanar = true
	mat_roll.uv1_world_triplanar = true
	mat_roll.uv1_scale = Vector3(2.4, 2.4, 2.4)
	var mat_plinth: StandardMaterial3D = _stone(Color("#C6C8C2"), 0.86)
	mat_plinth.clearcoat_enabled = false
	# petals (beast=blossom) — open shells, so both faces must draw
	var mat_petal: StandardMaterial3D = _stone(col_lining.lightened(0.18), 0.58)
	mat_petal.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_core: StandardMaterial3D = _stone(col_cloak.lightened(0.42), 0.70)

	# --- individual parameters (these reach the GEOMETRY) --------------------
	var body_k: float = rng.randf_range(0.94, 1.06)
	var tall_k: float = rng.randf_range(0.97, 1.02)
	var lead: float = 1.0 if rng.randf() < 0.5 else -1.0          # side of the forward leg
	var reach_side: float = -lead                                  # contrapposto
	var cloak_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lean_a: float = rng.randf_range(0.16, 0.28)
	var lean_b: float = rng.randf_range(0.02, 0.10)
	var lean_c: float = rng.randf_range(0.10, 0.22)
	var twist: float = rng.randf_range(-0.22, 0.22)
	var stride: float = rng.randf_range(0.13, 0.21)
	var neck_lean: float = rng.randf_range(0.20, 0.38)
	var head_yaw: float = deg_to_rad(rng.randf_range(-34.0, 34.0))
	var head_pitch: float = deg_to_rad(rng.randf_range(-16.0, 5.0))
	var head_roll: float = deg_to_rad(rng.randf_range(-9.0, 9.0))
	var muzzle_len: float = rng.randf_range(0.235, 0.300) * body_k
	var muzzle_droop: float = rng.randf_range(0.030, 0.062)
	var ear_len: float = rng.randf_range(0.105, 0.135)
	var ear_out: float = deg_to_rad(rng.randf_range(15.0, 34.0))
	var ear_pitch: float = deg_to_rad(rng.randf_range(-16.0, 10.0))
	var ear_split: float = rng.randf_range(-0.10, 0.10)             # one ear cocked
	var reach_up: float = rng.randf_range(0.06, 0.16)
	var reach_out: float = rng.randf_range(0.05, 0.13)
	var trail_back: float = rng.randf_range(0.10, 0.20)
	var n_mane: int = rng.randi_range(7, 12)
	var n_spine: int = 11
	# axis "beast": the reliquary has lost its flesh — every soft radius shrinks
	var flesh: float = 0.70 if beast == "reliquary" else 1.0
	var show_mane: bool = (beast != "reliquary" and beast != "swarm")

	var y_pelvis: float = 0.84 * tall_k
	var y_neck: float = 1.22 * tall_k
	var y_foot: float = PLINTH_TOP

	# --- spine ---------------------------------------------------------------
	var dirs: Array = []
	var rise: float = 0.0
	for i in range(1, n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var a: float = _key3(t, lean_a, lean_b, lean_c)
		var sway: float = twist * 0.30 * sin(PI * t)
		var d: Vector3 = Vector3(sway, cos(a), -sin(a)).normalized()
		dirs.append(d)
		rise += d.y
	var step: float = (y_neck - y_pelvis) / maxf(rise, 0.1)

	var pts: Array = []
	var p := Vector3(0.0, y_pelvis, 0.02)
	pts.append(p)
	for i in range(1, n_spine):
		var d: Vector3 = dirs[i - 1]
		p = p + d * step
		pts.append(p)

	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var q: Vector3 = pts[i]
		var r: float = _torso_r(t) * body_k * flesh
		var tang: Vector3 = _tangent(pts, i)
		var wide: float = lerpf(1.24, 1.42, _ss(t * 1.25))
		var deep: float = lerpf(0.84, 0.74, _ss(t))
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 2.0
		var mi: MeshInstance3D = _add(root, sph, mat_body)
		mi.transform = Transform3D(_basis_y_to(tang).scaled(Vector3(wide, 1.0, deep)), q)

	var p_hip: Vector3 = pts[0]
	var p_top: Vector3 = pts[n_spine - 1]
	var i_chest: int = int(floor(float(n_spine - 1) * 0.74))
	var p_chest: Vector3 = pts[i_chest]
	var front_top: Vector3 = _front_of(pts, n_spine - 1)
	var front_chest: Vector3 = _front_of(pts, i_chest)

	# pecs, obliques, glutes, collarbones, shoulder blades — or, once the flesh
	# is gone, the hoops of a rib cage standing proud of the shrunken spine
	if beast == "reliquary":
		for i in range(2, n_spine - 1):
			var t: float = float(i) / float(n_spine - 1)
			var rib_r: float = _torso_r(t) * body_k * lerpf(1.30, 1.48, _ss(t * 1.25))
			_hoop(root, pts[i], _tangent(pts, i), rib_r, 0.014 * body_k, mat_body)
		_limb(root, p_hip + front_chest * 0.045, p_top + front_top * 0.045, 0.022 * body_k, mat_body)
	else:
		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			_ball(root, p_chest + Vector3(sd * 0.085, 0.012, 0.0) + front_chest * 0.075, 0.062 * body_k, Vector3(1.25, 0.80, 0.72), mat_body)
			_ball(root, pts[4] + Vector3(sd * 0.088, 0.0, 0.0), 0.058 * body_k, Vector3(0.95, 1.30, 0.80), mat_body)
			_ball(root, p_hip + Vector3(sd * 0.078, -0.035, 0.055), 0.082 * body_k, Vector3(1.05, 0.95, 0.90), mat_body)
			_ball(root, p_top + Vector3(sd * 0.105, -0.028, 0.0) + front_top * 0.055, 0.036 * body_k, Vector3(1.55, 0.55, 0.60), mat_body)
			_ball(root, p_chest + Vector3(sd * 0.098, 0.048, 0.0) - front_chest * 0.055, 0.055 * body_k, Vector3(1.10, 1.15, 0.45), mat_body)
		_ball(root, p_chest + front_chest * 0.085 + Vector3(0.0, -0.030, 0.0), 0.040 * body_k, Vector3(0.60, 1.30, 0.55), mat_body)

	# --- legs ----------------------------------------------------------------
	var hw: float = 0.082 * body_k
	var toes: Array = []
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var is_lead: bool = (sd == lead)
		var hip := p_hip + Vector3(sd * hw, -0.045, 0.01)
		var knee: Vector3
		var ankle: Vector3
		var toe: Vector3
		if is_lead:
			knee = hip + Vector3(sd * 0.012, -0.235 * body_k, -stride * 0.72)
			ankle = knee + Vector3(sd * 0.004, -0.255 * body_k, -stride * 0.16)
			ankle = Vector3(ankle.x, y_foot + 0.058, ankle.z)
			toe = ankle + Vector3(sd * 0.004, -0.020, -0.135)
		else:
			knee = hip + Vector3(sd * 0.022, -0.245 * body_k, stride * 0.52)
			ankle = knee + Vector3(sd * 0.006, -0.230 * body_k, stride * 0.86)
			ankle = Vector3(ankle.x, y_foot + 0.105, ankle.z)
			toe = ankle + Vector3(sd * 0.004, -0.078, -0.105)
		toes.append(toe)
		_limb(root, hip, knee, 0.072 * body_k * flesh, mat_body)
		_ball(root, knee, 0.055 * body_k * flesh, Vector3(1.0, 0.90, 1.0), mat_body)
		_limb(root, knee, ankle, 0.055 * body_k * flesh, mat_body)
		_ball(root, ankle, 0.044 * body_k * flesh, Vector3(1.0, 1.0, 1.0), mat_body)
		_limb(root, ankle, toe, 0.043 * body_k * flesh, mat_body)
		var pad := BoxMesh.new()
		pad.size = Vector3(0.078, 0.030, 0.062)
		var pmi: MeshInstance3D = _add(root, pad, mat_body)
		pmi.transform = Transform3D(Basis(), toe + Vector3(0.0, -0.012, -0.018))

	# --- arms ----------------------------------------------------------------
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var reaching: bool = (sd == reach_side)
		var shoulder := p_top + Vector3(sd * 0.155 * body_k, -0.035, 0.0)
		var elbow: Vector3
		var wrist: Vector3
		var fwd: Vector3
		if reaching:
			elbow = shoulder + Vector3(sd * (0.075 + reach_out), -0.150 * body_k, -0.130)
			wrist = elbow + Vector3(sd * 0.020, reach_up, -0.180)
			fwd = Vector3(sd * 0.10, reach_up * 0.9, -0.30).normalized()
		else:
			elbow = shoulder + Vector3(sd * 0.105, -0.195 * body_k, trail_back * 0.42)
			wrist = elbow + Vector3(sd * 0.012, -0.185 * body_k, trail_back)
			fwd = Vector3(sd * 0.05, -0.62, 0.55).normalized()
		_limb(root, shoulder, elbow, 0.049 * body_k * flesh, mat_body)
		_ball(root, elbow, 0.042 * body_k * flesh, Vector3(1.0, 0.92, 1.0), mat_body)
		_limb(root, elbow, wrist, 0.040 * body_k * flesh, mat_body)
		_ball(root, wrist, 0.034 * body_k * flesh, Vector3(1.0, 0.85, 1.0), mat_body)
		var curl: float = 0.35 if reaching else 0.85
		if beast == "blossom":
			# the limb ends in a flower instead of a hand
			_bloom(root, wrist + fwd * (0.038 * body_k), fwd, 0.082 * body_k, [5, 4], mat_petal, mat_core)
		else:
			_hand(root, wrist, fwd, Vector3(sd, 0.0, 0.0), 0.032 * body_k, curl, mat_body)

	# --- neck ----------------------------------------------------------------
	var neck_dir: Vector3 = Vector3(twist * 0.18, cos(neck_lean), -sin(neck_lean)).normalized()
	var n_neck: int = 4
	for i in range(n_neck):
		var t: float = float(i) / float(n_neck - 1)
		var q: Vector3 = p_top + neck_dir * (0.045 + 0.038 * float(i))
		var r: float = lerpf(0.068, 0.052, t) * body_k * flesh
		var mat_seg: StandardMaterial3D = mat_body
		if t > 0.55:
			mat_seg = mat_head
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 2.0
		var mi: MeshInstance3D = _add(root, sph, mat_seg)
		mi.transform = Transform3D(_basis_y_to(neck_dir).scaled(Vector3(1.06, 1.0, 0.88)), q)

	# --- head (axis: beast) --------------------------------------------------
	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_pitch) * Basis(Vector3.FORWARD, head_roll)
	var h_org: Vector3 = p_top + neck_dir * (0.045 + 0.038 * float(n_neck - 1) + 0.062)
	var rh: float = 0.082 * body_k

	if beast == "reliquary":
		# the flesh is gone: a bare toothed skull inside hoops of bone
		_bone_head(root, h_org, hb, rh, mat_head, mat_dark, mat_head_dark, muzzle_len, muzzle_droop, ear_len * body_k)
	elif beast == "swarm":
		# the head does not resolve: thirty small muzzled skulls where it was
		_swarm_head(root, h_org, rh, mat_head, mat_dark, vrng, 30)
	elif beast == "hydra":
		# three heads — the first shrunk to make room, two more on branched necks
		_horse_head(root, h_org, hb, rh * 0.82, mat_head, mat_ear, mat_ear_in, mat_dark,
			muzzle_len * 0.82, muzzle_droop * 0.82, ear_len * 0.82, ear_out, ear_pitch, ear_split, body_k, "flesh")
		for side_i in range(2):
			var sd: float = -1.0 if side_i == 0 else 1.0
			var branch: Vector3 = (neck_dir + Vector3(sd * 1.05, 0.14, 0.12)).normalized()
			var b_org: Vector3 = p_top + neck_dir * 0.030
			for i in range(4):
				var tb: float = float(i) / 3.0
				var qb: Vector3 = b_org + branch * (0.048 + 0.060 * float(i))
				var rb: float = lerpf(0.058, 0.040, tb) * body_k
				var sphb := SphereMesh.new()
				sphb.radius = rb
				sphb.height = rb * 2.0
				var mib: MeshInstance3D = _add(root, sphb, mat_head)
				mib.transform = Transform3D(_basis_y_to(branch).scaled(Vector3(1.05, 1.0, 0.88)), qb)
			var ho: Vector3 = b_org + branch * (0.048 + 0.060 * 3.0 + 0.058)
			var hb2: Basis = Basis(Vector3.UP, head_yaw + sd * 0.85) * Basis(Vector3.RIGHT, head_pitch - 0.16) * Basis(Vector3.FORWARD, head_roll + sd * 0.28)
			_horse_head(root, ho, hb2, rh * 0.64, mat_head, mat_ear, mat_ear_in, mat_dark,
				muzzle_len * 0.64, muzzle_droop * 0.64, ear_len * 0.64, ear_out, ear_pitch, ear_split, body_k, "flesh")
	elif beast == "blossom":
		# the muzzle opens: petals where the nose and lip were
		var nose_b: Vector3 = _horse_head(root, h_org, hb, rh, mat_head, mat_ear, mat_ear_in, mat_dark,
			muzzle_len * 0.88, muzzle_droop, ear_len, ear_out, ear_pitch, ear_split, body_k, "bloom")
		var bl_dir: Vector3 = (hb * Vector3(0.0, -0.18, -1.0)).normalized()
		_bloom(root, nose_b, bl_dir, rh * 1.60, [7, 6, 5], mat_petal, mat_core)
	else:
		_horse_head(root, h_org, hb, rh, mat_head, mat_ear, mat_ear_in, mat_dark,
			muzzle_len, muzzle_droop, ear_len, ear_out, ear_pitch, ear_split, body_k, "flesh")

	# mane along the crest
	var crest_top: Vector3 = h_org + hb * Vector3(0.0, rh * 0.55, rh * 0.85)
	var crest_bot: Vector3 = p_top + Vector3(0.0, 0.02, 0.055)
	# the draws happen either way — a skull and a swarm keep the rng stream in
	# step with the default so the two axes never contaminate each other
	for i in range(n_mane):
		var t: float = float(i) / float(n_mane - 1)
		var base_p: Vector3 = crest_top.lerp(crest_bot, t) + Vector3(rng.randf_range(-0.010, 0.010), 0.0, 0.012)
		var md: Vector3 = Vector3(rng.randf_range(-0.28, 0.28), -0.55 - rng.randf_range(0.0, 0.35), 0.80).normalized()
		var ml: float = rng.randf_range(0.050, 0.092)
		if show_mane:
			_tapered_cyl(root, base_p, base_p + md * ml, 0.017 * body_k, 0.005, mat_head_dark)

	# --- cloak ---------------------------------------------------------------
	var sh_y: float = p_top.y - 0.020
	var c_t := Vector3(p_top.x * 0.85, sh_y, p_top.z * 0.85 + 0.015)
	var a0: float = rng.randf_range(-0.80, -0.45)
	var a1: float = rng.randf_range(3.05, 3.55)
	var u_sh: float = rng.randf_range(0.26, 0.38)
	var folds: float = float(rng.randi_range(4, 8))
	var fold_amp: float = rng.randf_range(0.034, 0.058)
	var fold_twist: float = rng.randf_range(-1.10, 1.10)
	var fold_phase: float = rng.randf_range(0.0, 1.0)
	var flare: float = rng.randf_range(0.12, 0.18)
	var sweep: float = rng.randf_range(0.13, 0.20)
	var l_front: float = rng.randf_range(0.38, 0.50)
	var l_back: float = rng.randf_range(0.72, 0.90)
	var hem_n: float = float(rng.randi_range(3, 6))
	var hem_ph: float = rng.randf_range(0.0, 1.0)
	var lift: float = rng.randf_range(0.045, 0.085)
	var hem_floor: float = y_foot + 0.025

	var crx: float = 0.205 * body_k
	var crz: float = 0.145 * body_k

	if cloak_mode == "flood":
		# the cloth pours off the shoulder and SETS: a solid poured cone that
		# swallows the figure from the waist down and spreads on the ground
		var a_hi: float = atan2(0.42, cloak_side)
		var pour_y: float = hem_floor - 0.048
		var pour: ArrayMesh = _pour_mesh(p_hip.x * 0.5, p_hip.z + 0.02,
			y_pelvis - 0.03, sh_y + 0.020, a_hi,
			0.19 * body_k, 0.45 * body_k, pour_y,
			folds, fold_amp * 1.75, fold_phase, col_cloak, col_cloak_dark)
		var mat_pour: StandardMaterial3D = _cloth(weave, Color(1.0, 1.0, 1.0), true)
		var pom: MeshInstance3D = _add(root, pour, mat_pour)
		pom.transform = Transform3D(Basis(), Vector3.ZERO)
		var puddle := CylinderMesh.new()
		puddle.top_radius = 0.45 * body_k * 1.06
		puddle.bottom_radius = 0.45 * body_k * 1.20
		puddle.height = 0.042
		puddle.radial_segments = 30
		var pdm: MeshInstance3D = _add(root, puddle, mat_roll)
		pdm.transform = Transform3D(Basis(), Vector3(p_hip.x * 0.5, pour_y + 0.021, p_hip.z + 0.02))
	elif cloak_mode == "unravelling":
		# the sheets have gone to thread — air where the cloth was
		var mat_thr_a: StandardMaterial3D = _cloth(weave, col_cloak, false)
		mat_thr_a.cull_mode = BaseMaterial3D.CULL_BACK
		var mat_thr_b: StandardMaterial3D = _cloth(weave, col_lining, false)
		mat_thr_b.cull_mode = BaseMaterial3D.CULL_BACK
		var n_thread: int = 34
		for i in range(n_thread):
			var u: float = float(i) / float(n_thread - 1)
			var q0: Vector3 = _cloak_p(c_t, cloak_side, crx, crz, a0, a1, u_sh, lift,
				l_front, l_back, flare, sweep, folds, fold_amp, fold_twist, fold_phase,
				hem_n, hem_ph, 0.010, hem_floor, u, 0.04)
			var q1: Vector3 = _cloak_p(c_t, cloak_side, crx, crz, a0, a1, u_sh, lift,
				l_front, l_back, flare, sweep, folds, fold_amp, fold_twist, fold_phase,
				hem_n, hem_ph, 0.010, hem_floor, u, 0.58)
			var q2: Vector3 = _cloak_p(c_t, cloak_side, crx, crz, a0, a1, u_sh, lift,
				l_front, l_back, flare, sweep, folds, fold_amp, fold_twist, fold_phase,
				hem_n, hem_ph, 0.010, hem_floor, u, 1.0)
			q1 += Vector3(vrng.randf_range(-0.024, 0.024), vrng.randf_range(-0.020, 0.010), vrng.randf_range(-0.024, 0.024))
			q2 += Vector3(vrng.randf_range(-0.065, 0.065), vrng.randf_range(-0.050, 0.030), vrng.randf_range(-0.065, 0.065))
			q2.y = maxf(q2.y, hem_floor - 0.020)
			var mt: StandardMaterial3D = mat_thr_b if (i % 3) == 0 else mat_thr_a
			_tapered_cyl(root, q0, q1, 0.0098 * body_k, 0.0070 * body_k, mt)
			_tapered_cyl(root, q1, q2, 0.0070 * body_k, 0.0026 * body_k, mt)
	elif cloak_mode == "shattered":
		# the cloak burst: every patch pushed off along its own surface normal
		var mat_shd_a: StandardMaterial3D = _cloth(weave, col_cloak, false)
		var mat_shd_b: StandardMaterial3D = _cloth(weave, col_lining, false)
		var nu_s: int = 9
		var nv_s: int = 5
		for iu in range(nu_s):
			for iv in range(nv_s):
				var u: float = (float(iu) + 0.5) / float(nu_s)
				var v: float = (float(iv) + 0.5) / float(nv_s)
				var du_h: float = 0.5 / float(nu_s)
				var dv_h: float = 0.5 / float(nv_s)
				var pc: Vector3 = _cloak_p(c_t, cloak_side, crx, crz, a0, a1, u_sh, lift,
					l_front, l_back, flare, sweep, folds, fold_amp, fold_twist, fold_phase,
					hem_n, hem_ph, 0.010, hem_floor, u, v)
				var pu: Vector3 = _cloak_p(c_t, cloak_side, crx, crz, a0, a1, u_sh, lift,
					l_front, l_back, flare, sweep, folds, fold_amp, fold_twist, fold_phase,
					hem_n, hem_ph, 0.010, hem_floor, minf(u + du_h, 1.0), v)
				var pv: Vector3 = _cloak_p(c_t, cloak_side, crx, crz, a0, a1, u_sh, lift,
					l_front, l_back, flare, sweep, folds, fold_amp, fold_twist, fold_phase,
					hem_n, hem_ph, 0.010, hem_floor, u, minf(v + dv_h, 1.0))
				var du: Vector3 = pu - pc
				var dv: Vector3 = pv - pc
				var nrm: Vector3 = du.cross(dv)
				if nrm.length() < 0.00001:
					nrm = Vector3.FORWARD
				nrm = nrm.normalized()
				if nrm.dot(pc - c_t) < 0.0:
					nrm = -nrm
				var ex: Vector3 = du
				if ex.length() < 0.00001:
					ex = Vector3.RIGHT
				ex = ex.normalized()
				var ey: Vector3 = nrm.cross(ex).normalized()
				ex = ey.cross(nrm).normalized()
				var burst: float = (0.022 + 0.180 * pow(v, 1.15)) * (0.50 + 0.90 * u)
				var pos: Vector3 = pc + nrm * burst
				pos += Vector3(vrng.randf_range(-0.020, 0.020), vrng.randf_range(-0.034, 0.034), vrng.randf_range(-0.020, 0.020))
				pos.y = maxf(pos.y, hem_floor - 0.020)
				var plate := BoxMesh.new()
				plate.size = Vector3(maxf(du.length() * 1.70, 0.030), maxf(dv.length() * 1.70, 0.030), 0.011)
				var mtb: StandardMaterial3D = mat_shd_b if ((iu + iv) % 3) == 0 else mat_shd_a
				var bm: MeshInstance3D = _add(root, plate, mtb)
				var ax: Vector3 = Vector3(vrng.randf_range(-1.0, 1.0), vrng.randf_range(-1.0, 1.0), vrng.randf_range(-1.0, 1.0))
				if ax.length() < 0.001:
					ax = Vector3.UP
				bm.transform = Transform3D(Basis(ex, ey, nrm) * Basis(ax.normalized(), vrng.randf_range(-0.38, 0.38)), pos)
	else:
		var outer: ArrayMesh = _cloak_sheet(c_t, cloak_side, crx, crz,
			a0, a1, u_sh, lift, l_front, l_back, flare, sweep,
			folds, fold_amp, fold_twist, fold_phase, hem_n, hem_ph, 0.016, hem_floor,
			col_cloak, col_cloak_dark)
		var mat_outer: StandardMaterial3D = _cloth(weave, Color(1.0, 1.0, 1.0), true)
		var om: MeshInstance3D = _add(root, outer, mat_outer)
		om.transform = Transform3D(Basis(), Vector3.ZERO)

		var lining: ArrayMesh = _cloak_sheet(c_t, cloak_side, crx, crz,
			a0, a1, u_sh, lift, l_front * 0.985, l_back * 0.985, flare, sweep,
			folds, fold_amp, fold_twist, fold_phase, hem_n, hem_ph, -0.002, hem_floor + 0.008,
			col_lining, col_lining.darkened(0.45))
		var mat_lining: StandardMaterial3D = mat_outer.duplicate() as StandardMaterial3D
		var lnm: MeshInstance3D = _add(root, lining, mat_lining)
		lnm.transform = Transform3D(Basis(), Vector3.ZERO)

	# gathered roll of cloth over the shoulder, and a knot at the chest
	var n_roll: int = rng.randi_range(4, 6)
	for i in range(n_roll):
		var t: float = float(i) / float(n_roll - 1)
		var a: float = lerpf(a0 + 0.55, a0 + 2.05, t)
		var yr: float = sh_y + lift * exp(-pow((t * 0.55 + 0.08 - u_sh) / 0.30, 2.0)) + 0.020
		var rp := Vector3(c_t.x + sin(a) * cloak_side * (0.205 * body_k + 0.022), yr, c_t.z - cos(a) * (0.145 * body_k + 0.022))
		_ball(root, rp, rng.randf_range(0.040, 0.056) * body_k, Vector3(1.0, 0.86, 1.0), mat_roll)
	var knot_a: float = a0 + 0.18
	var knot_p := Vector3(c_t.x + sin(knot_a) * cloak_side * 0.195 * body_k, sh_y - 0.055, c_t.z - cos(knot_a) * 0.150 * body_k)
	_ball(root, knot_p, 0.048 * body_k, Vector3(1.1, 0.85, 0.90), mat_roll)
	_ball(root, knot_p + Vector3(0.0, -0.052, 0.010), 0.036 * body_k, Vector3(0.95, 1.15, 0.85), mat_roll)

	# --- plinth, sized and centred on the FEET, not on the cloak -------------
	var t_a: Vector3 = toes[0]
	var t_b: Vector3 = toes[1]
	var feet_c: Vector3 = (t_a + t_b) * 0.5
	var span_z: float = absf(t_a.z - t_b.z) + 0.17
	var span_x: float = absf(t_a.x - t_b.x) + 0.26
	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.05, span_x), PLINTH_TOP, minf(1.05, span_z))
	var plm: MeshInstance3D = _add(root, plinth, mat_plinth)
	plm.transform = Transform3D(Basis(), Vector3(feet_c.x * 0.6, PLINTH_TOP * 0.5, feet_c.z))

	# --- settle: measure, fit, centre, stand on the floor --------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = 1.68 / maxf(box.size.y, 0.001)
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
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# profiles

static func _key3(t: float, a0: float, a1: float, a2: float) -> float:
	var keys: Array = [a0, a1, a2]
	var f: float = t * 2.0
	var i: int = int(floor(f))
	if i >= 2:
		return a2
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _torso_r(t: float) -> float:
	var keys: Array = [0.128, 0.116, 0.102, 0.098, 0.108, 0.122, 0.118]
	var f: float = t * 6.0
	var i: int = int(floor(f))
	if i >= 6:
		return keys[6]
	var u: float = f - float(i)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, u)


static func _ss(x: float) -> float:
	var u: float = clampf(x, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


static func _tri(x: float) -> float:
	var f: float = x - floor(x)
	return 1.0 - 4.0 * absf(f - 0.5)


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.0001:
		return Vector3.UP
	return d.normalized()


static func _front_of(pts: Array, i: int) -> Vector3:
	var tang: Vector3 = _tangent(pts, i)
	var f := Vector3(0.0, tang.z, -tang.y)
	if f.length() < 0.0001:
		return Vector3.FORWARD
	return f.normalized()


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


# ---------------------------------------------------------------------------
# primitive helpers

static func _hex(pool: Array, i: int) -> Color:
	var code: String = pool[i]
	return Color(code)


static func _stone(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.22
	m.clearcoat_roughness = 0.45
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ball(root: Node3D, at: Vector3, r: float, sc: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(Basis().scaled(sc), at)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
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
	cyl.radial_segments = 10
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _cone(root: Node3D, base_p: Vector3, dir: Vector3, h: float, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = 0.0
	cyl.height = h
	cyl.radial_segments = 10
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), base_p + d * (h * 0.5))
	return mi


static func _hand(root: Node3D, wrist: Vector3, fwd: Vector3, side: Vector3, r: float, curl: float, mat: StandardMaterial3D) -> void:
	var f: Vector3 = fwd.normalized()
	var s: Vector3 = side - f * side.dot(f)
	if s.length() < 0.0001:
		s = Vector3.RIGHT
	s = s.normalized()
	var up: Vector3 = s.cross(f).normalized()
	var palm_c: Vector3 = wrist + f * (r * 1.8)
	var pb := BoxMesh.new()
	pb.size = Vector3(r * 2.2, r * 0.95, r * 3.2)
	var pm: MeshInstance3D = _add(root, pb, mat)
	pm.transform = Transform3D(Basis(s, up, -f), palm_c)
	for k in range(4):
		var fk: float = float(k) - 1.5
		var d: Vector3 = (f + s * (fk * 0.17) - up * curl).normalized()
		var a: Vector3 = palm_c + f * (r * 1.5) + s * (fk * r * 0.60)
		_limb(root, a, a + d * (r * 2.5), r * 0.29, mat)
	var td: Vector3 = (f * 0.55 - s * 0.85 - up * (curl * 0.55)).normalized()
	var ta: Vector3 = palm_c - s * (r * 0.95) + f * (r * 0.15)
	_limb(root, ta, ta + td * (r * 2.0), r * 0.33, mat)


static func _cloth(tex: ImageTexture, col: Color, vertex_col: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.vertex_color_use_as_albedo = vertex_col
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(2.6, 2.6, 2.6)
	m.roughness = 0.92
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _hoop(root: Node3D, at: Vector3, axis: Vector3, ring_r: float, tube_r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var m: ArrayMesh = _hoop_mesh(maxf(ring_r, 0.004), maxf(tube_r, 0.001), 16, 8)
	var mi: MeshInstance3D = _add(root, m, mat)
	mi.transform = Transform3D(_basis_y_to(axis), at)
	return mi


# ---------------------------------------------------------------------------
# axis "beast": the heads

## The head as the reference has it. Returns the nose point so a caller can
## hang something else off the end of the muzzle. nose_mode "bloom" leaves the
## nose, nostrils and lip off so a flower can take their place.
static func _horse_head(root: Node3D, h_org: Vector3, hb: Basis, rh: float,
		mat_head: StandardMaterial3D, mat_ear: StandardMaterial3D,
		mat_ear_in: StandardMaterial3D, mat_dark: StandardMaterial3D,
		muzzle_len: float, muzzle_droop: float,
		ear_len: float, ear_out: float, ear_pitch: float, ear_split: float,
		body_k: float, nose_mode: String) -> Vector3:
	var skull := SphereMesh.new()
	skull.radius = rh
	skull.height = rh * 2.0
	var skm: MeshInstance3D = _add(root, skull, mat_head)
	skm.transform = Transform3D(hb * Basis().scaled(Vector3(0.92, 1.02, 1.20)), h_org)

	_ball(root, h_org + hb * Vector3(0.0, rh * 0.42, rh * 0.72), rh * 0.62, Vector3(0.92, 0.80, 0.80), mat_head)
	for sgn in [-1.0, 1.0]:
		var sd: float = sgn
		_ball(root, h_org + hb * Vector3(sd * rh * 0.62, -rh * 0.18, rh * 0.16), rh * 0.58, Vector3(0.70, 0.95, 1.05), mat_head)
		_ball(root, h_org + hb * Vector3(sd * rh * 0.50, -rh * 0.55, rh * 0.10), rh * 0.42, Vector3(0.85, 0.80, 1.20), mat_head)

	# muzzle: swept elliptical tube off the front of the skull
	var muzzle: ArrayMesh = _muzzle_mesh(muzzle_len, rh * 0.86, rh * 0.44, muzzle_droop)
	var mzm: MeshInstance3D = _add(root, muzzle, mat_head)
	var mz_org: Vector3 = h_org + hb * Vector3(0.0, -rh * 0.10, -rh * 0.42)
	mzm.transform = Transform3D(hb, mz_org)
	var nose_p: Vector3 = mz_org + hb * Vector3(0.0, -muzzle_droop, -muzzle_len)
	if nose_mode != "bloom":
		_ball(root, nose_p, rh * 0.46, Vector3(1.05, 0.86, 0.80), mat_head)
		for sgn2 in [-1.0, 1.0]:
			var sd2: float = sgn2
			_ball(root, nose_p + hb * Vector3(sd2 * rh * 0.26, rh * 0.10, rh * 0.10), rh * 0.12, Vector3(0.80, 1.00, 1.20), mat_dark)
		# lip line
		var lip := BoxMesh.new()
		lip.size = Vector3(rh * 0.70, rh * 0.055, rh * 0.20)
		var lipm: MeshInstance3D = _add(root, lip, mat_dark)
		lipm.transform = Transform3D(hb, nose_p + hb * Vector3(0.0, -rh * 0.34, rh * 0.10))
	# jaw and chin
	var jaw_a: Vector3 = h_org + hb * Vector3(0.0, -rh * 0.62, rh * 0.30)
	var jaw_b: Vector3 = nose_p + hb * Vector3(0.0, -rh * 0.20, rh * 0.34)
	_limb(root, jaw_a, jaw_b, rh * 0.30, mat_head)
	_ball(root, jaw_b, rh * 0.26, Vector3(1.05, 0.90, 1.0), mat_head)

	# eyes on the SIDES of the skull, with brow ridges
	for sgn3 in [-1.0, 1.0]:
		var sd3: float = sgn3
		var ep: Vector3 = h_org + hb * Vector3(sd3 * rh * 0.80, rh * 0.30, -rh * 0.28)
		var eye := SphereMesh.new()
		eye.radius = rh * 0.24
		eye.height = rh * 0.48
		var em: MeshInstance3D = _add(root, eye, mat_dark)
		em.transform = Transform3D(hb * Basis().scaled(Vector3(0.72, 1.0, 1.05)), ep)
		var brow_d: Vector3 = (hb * Vector3(sd3 * 0.55, 0.80, -0.20)).normalized()
		_cone(root, ep + brow_d * (rh * 0.22), brow_d, rh * 0.30, rh * 0.20, mat_head)

	# ears: leaf shells on the poll
	for side_i in range(2):
		var sd4: float = -1.0 if side_i == 0 else 1.0
		var this_len: float = ear_len * (1.0 + sd4 * ear_split * 0.5) * body_k
		var eb: Basis = hb * Basis(Vector3.FORWARD, -sd4 * ear_out) * Basis(Vector3.RIGHT, ear_pitch + sd4 * ear_split * 0.6)
		var e_org: Vector3 = h_org + hb * Vector3(sd4 * rh * 0.52, rh * 0.78, rh * 0.34)
		var leaf: ArrayMesh = _leaf_mesh(this_len, this_len * 0.24, this_len * 0.15, this_len * 0.20)
		var lm: MeshInstance3D = _add(root, leaf, mat_ear)
		lm.transform = Transform3D(eb, e_org)
		var inner: ArrayMesh = _leaf_mesh(this_len * 0.74, this_len * 0.15, this_len * 0.09, this_len * 0.16)
		var im: MeshInstance3D = _add(root, inner, mat_ear_in)
		im.transform = Transform3D(eb, e_org + eb * Vector3(0.0, this_len * 0.06, -this_len * 0.055))
	return nose_p


## beast = reliquary: the flesh is gone. A narrow cranium, a long thin muzzle
## caged in bone hoops and struts, two rows of teeth, hollow sockets, an open
## hanging jaw, and bare horn spikes where the leaf ears were.
static func _bone_head(root: Node3D, h_org: Vector3, hb: Basis, rh: float,
		mat_bone: StandardMaterial3D, mat_dark: StandardMaterial3D, mat_shade: StandardMaterial3D,
		muzzle_len: float, muzzle_droop: float, ear_len: float) -> void:
	var ln: float = muzzle_len * 1.12
	var droop: float = muzzle_droop * 0.45
	var skull := SphereMesh.new()
	skull.radius = rh
	skull.height = rh * 2.0
	var skm: MeshInstance3D = _add(root, skull, mat_bone)
	skm.transform = Transform3D(hb * Basis().scaled(Vector3(0.70, 0.86, 1.12)), h_org)
	_ball(root, h_org + hb * Vector3(0.0, rh * 0.54, rh * 0.46), rh * 0.44, Vector3(0.26, 0.80, 1.10), mat_bone)

	var mz_org: Vector3 = h_org + hb * Vector3(0.0, -rh * 0.06, -rh * 0.40)
	var nose_p: Vector3 = mz_org + hb * Vector3(0.0, -droop, -ln)
	var muzzle: ArrayMesh = _muzzle_mesh(ln, rh * 0.50, rh * 0.21, droop)
	var mzm: MeshInstance3D = _add(root, muzzle, mat_bone)
	mzm.transform = Transform3D(hb, mz_org)

	var axis: Vector3 = (nose_p - mz_org).normalized()
	var n_hoop: int = 7
	for i in range(n_hoop):
		var t: float = float(i) / float(n_hoop - 1)
		var c: Vector3 = mz_org + hb * Vector3(0.0, -droop * t * t, -ln * t)
		var rr: float = lerpf(rh * 0.66, rh * 0.30, t)
		_hoop(root, c, axis, rr, rh * 0.055, mat_bone)
	for j in range(6):
		var th: float = TAU * float(j) / 6.0
		var a: Vector3 = mz_org + hb * Vector3(cos(th) * rh * 0.60, sin(th) * rh * 0.60, 0.0)
		var b: Vector3 = nose_p + hb * Vector3(cos(th) * rh * 0.28, sin(th) * rh * 0.28, 0.0)
		_tapered_cyl(root, a, b, rh * 0.045, rh * 0.026, mat_bone)

	var n_teeth: int = 6
	for i in range(n_teeth):
		var t: float = float(i) / float(n_teeth - 1)
		var f: float = 0.40 + 0.56 * t
		var cu: Vector3 = mz_org.lerp(nose_p, f)
		var rr: float = lerpf(rh * 0.54, rh * 0.24, f)
		for sgn in [-1.0, 1.0]:
			var sd: float = sgn
			var tooth := BoxMesh.new()
			tooth.size = Vector3(rh * 0.11, rh * 0.22, rh * 0.10)
			var tm: MeshInstance3D = _add(root, tooth, mat_shade)
			tm.transform = Transform3D(hb, cu + hb * Vector3(sd * rr * 0.60, -rr * 0.82, 0.0))

	# jaw hanging open under the muzzle
	var hinge: Vector3 = h_org + hb * Vector3(0.0, -rh * 0.60, rh * 0.24)
	var chin: Vector3 = nose_p + hb * Vector3(0.0, -rh * 1.00, rh * 0.34)
	for sgn2 in [-1.0, 1.0]:
		var sd2: float = sgn2
		_tapered_cyl(root, hinge + hb * Vector3(sd2 * rh * 0.20, 0.0, 0.0), chin + hb * Vector3(sd2 * rh * 0.10, 0.0, 0.0), rh * 0.10, rh * 0.055, mat_bone)
	_ball(root, chin, rh * 0.14, Vector3(1.20, 0.70, 1.0), mat_bone)

	# hollow sockets, ringed in bone
	for sgn3 in [-1.0, 1.0]:
		var sd3: float = sgn3
		var ep: Vector3 = h_org + hb * Vector3(sd3 * rh * 0.62, rh * 0.28, -rh * 0.20)
		_ball(root, ep, rh * 0.30, Vector3(0.82, 1.0, 1.0), mat_dark)
		var ed: Vector3 = (hb * Vector3(sd3 * 1.0, 0.12, -0.18)).normalized()
		_hoop(root, ep + ed * (rh * 0.10), ed, rh * 0.34, rh * 0.050, mat_bone)

	# bare horn spikes on the poll
	for sgn4 in [-1.0, 1.0]:
		var sd4: float = sgn4
		var base_e: Vector3 = h_org + hb * Vector3(sd4 * rh * 0.44, rh * 0.64, rh * 0.28)
		var ed2: Vector3 = (hb * Vector3(sd4 * 0.42, 1.0, 0.14)).normalized()
		_cone(root, base_e, ed2, ear_len * 1.15, rh * 0.16, mat_bone)


## beast = swarm: the head refuses to be one thing. Small muzzled skulls
## scattered through the volume the head occupied, spilling down the shoulders.
static func _swarm_head(root: Node3D, at: Vector3, rh: float,
		mat_a: StandardMaterial3D, mat_b: StandardMaterial3D,
		rng: RandomNumberGenerator, n: int) -> void:
	for i in range(n):
		var t: float = float(i) / float(maxi(n - 1, 1))
		var th: float = TAU * float(i) * 0.6180339887
		var rad: float = rh * lerpf(0.55, 3.10, pow(t, 0.72))
		var dir: Vector3 = Vector3(cos(th), rng.randf_range(-0.85, 0.85), sin(th)).normalized()
		var c: Vector3 = at + dir * rad + Vector3(0.0, -rh * 2.20 * t * t, 0.0)
		var k: float = rh * lerpf(0.36, 0.11, t) * rng.randf_range(0.80, 1.25)
		var mat_i: StandardMaterial3D = mat_a
		_ball(root, c, k, Vector3(0.90, 1.0, 1.24), mat_i)
		var md: Vector3 = (dir * 0.80 + Vector3(0.0, -0.42, 0.0)).normalized()
		_tapered_cyl(root, c, c + md * (k * 3.20), k * 0.74, k * 0.28, mat_i)
		if i % 5 == 0:
			_ball(root, c + md * (k * 3.30), k * 0.30, Vector3(1.0, 0.85, 0.85), mat_b)


## beast = blossom: a whorled flower. Reuses the ear leaf as a petal, so the
## bloom is made of the family's own parts.
static func _bloom(root: Node3D, at: Vector3, fwd: Vector3, r: float, rings: Array,
		mat_petal: StandardMaterial3D, mat_core: StandardMaterial3D) -> void:
	var f: Vector3 = fwd.normalized()
	var u_ax: Vector3 = Vector3.UP.cross(f)
	if u_ax.length() < 0.001:
		u_ax = Vector3.RIGHT
	u_ax = u_ax.normalized()
	var v_ax: Vector3 = f.cross(u_ax).normalized()
	var nw: int = rings.size()
	for w in range(nw):
		var n: int = int(rings[w])
		var tw: float = float(w) / maxf(float(nw - 1), 1.0)
		var tilt: float = lerpf(1.32, 0.44, tw)
		var plen: float = r * lerpf(1.00, 0.56, tw)
		var off: float = float(w) * 0.42
		for j in range(n):
			var th: float = TAU * float(j) / float(n) + off
			var radial: Vector3 = u_ax * cos(th) + v_ax * sin(th)
			var d: Vector3 = (f * cos(tilt) + radial * sin(tilt)).normalized()
			var petal: ArrayMesh = _leaf_mesh(plen, plen * 0.42, plen * 0.24, plen * 0.30)
			var pm: MeshInstance3D = _add(root, petal, mat_petal)
			pm.transform = Transform3D(_basis_y_to(d), at + d * (r * 0.16))
	_ball(root, at + f * (r * 0.10), r * 0.30, Vector3(1.0, 1.0, 0.82), mat_core)
	var n_st: int = 4
	for j in range(n_st):
		var th2: float = TAU * float(j) / float(n_st) + 0.3
		var radial2: Vector3 = u_ax * cos(th2) + v_ax * sin(th2)
		var d2: Vector3 = (f * 1.15 + radial2 * 0.44).normalized()
		var a: Vector3 = at + f * (r * 0.14)
		_tapered_cyl(root, a, a + d2 * (r * 0.58), r * 0.048, r * 0.022, mat_core)
		_ball(root, a + d2 * (r * 0.60), r * 0.080, Vector3(1.0, 1.0, 1.0), mat_core)


# ---------------------------------------------------------------------------
# SurfaceTool shells

static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
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


static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c) / 3.0
	if n_front.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


static func _muzzle_mesh(ln: float, r0: float, r1: float, droop: float) -> ArrayMesh:
	# a tube marching along -Z, drooping on t^2, pinched behind the nostrils
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 11
	var seg: int = 14
	var centres: Array = []
	var loops: Array = []
	for k in range(rings):
		var t: float = float(k) / float(rings - 1)
		var c := Vector3(0.0, -droop * t * t, -ln * t)
		var r: float = lerpf(r0, r1, pow(t, 0.78))
		var wide: float = 0.96 - 0.30 * t + 0.34 * t * t
		var tall: float = 1.08 - 0.20 * t
		var loop: Array = []
		for j in range(seg):
			var th: float = TAU * float(j) / float(seg)
			loop.append(c + Vector3(cos(th) * r * wide, sin(th) * r * tall, 0.0))
		centres.append(c)
		loops.append(loop)
	for k in range(rings - 1):
		var la: Array = loops[k]
		var lb: Array = loops[k + 1]
		var ca: Vector3 = centres[k]
		var cb: Vector3 = centres[k + 1]
		var mid: Vector3 = (ca + cb) * 0.5
		for j in range(seg):
			var j2: int = (j + 1) % seg
			_quad_out(st, la[j], la[j2], lb[j2], lb[j], mid)
	# tip fan
	var tip: Vector3 = centres[rings - 1] + Vector3(0.0, 0.0, -r1 * 0.55)
	var last: Array = loops[rings - 1]
	for j in range(seg):
		var j2: int = (j + 1) % seg
		var a: Vector3 = last[j]
		var b: Vector3 = last[j2]
		_tri_out(st, a, b, tip, centres[rings - 1])
	# back cap so the shell closes inside the skull
	var back_p: Vector3 = centres[0] + Vector3(0.0, 0.0, r0 * 0.35)
	var first: Array = loops[0]
	for j in range(seg):
		var j2: int = (j + 1) % seg
		var a: Vector3 = first[j]
		var b: Vector3 = first[j2]
		_tri_out(st, a, b, back_p, centres[0])
	st.generate_normals()
	return st.commit()


static func _leaf_mesh(ln: float, wd: float, cup: float, curl: float) -> ArrayMesh:
	# an upright ear: grows along +Y, width along X, cupped and curled along -Z
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nt: int = 9
	var ns: int = 7
	var grid: Array = []
	for i in range(nt + 1):
		var t: float = float(i) / float(nt)
		# 0.10..0.98 of the lobe, so the base has width and the tip nearly closes
		# without collapsing a row of triangles
		var w: float = wd * sin(PI * pow(0.10 + 0.88 * t, 0.62))
		var zc: float = -curl * t * t
		var row: Array = []
		for j in range(ns + 1):
			var s: float = -1.0 + 2.0 * float(j) / float(ns)
			var z: float = zc - cup * (1.0 - s * s) * (1.0 - t * 0.35)
			row.append(Vector3(w * s, ln * t, z))
		grid.append(row)
	for i in range(nt):
		var r0: Array = grid[i]
		var r1: Array = grid[i + 1]
		for j in range(ns):
			var p00: Vector3 = r0[j]
			var p01: Vector3 = r0[j + 1]
			var p10: Vector3 = r1[j]
			var p11: Vector3 = r1[j + 1]
			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p11)
			st.add_vertex(p00)
			st.add_vertex(p11)
			st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


## A bone hoop: a torus lying in the XZ plane with its axis along +Y, so a
## caller can aim it with _basis_y_to(). The armature ring of the reliquary —
## rib, muzzle cage, eye socket. Built as a SurfaceTool shell so it stays inside
## the same primitives-plus-ArrayMesh contract the rest of the file keeps.
static func _hoop_mesh(ring_r: float, tube_r: float, seg_major: int, seg_minor: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu: int = maxi(seg_major, 6)
	var nv: int = maxi(seg_minor, 4)
	var loops: Array = []
	var centres: Array = []
	for i in range(nu):
		var a: float = TAU * float(i) / float(nu)
		var radial: Vector3 = Vector3(cos(a), 0.0, sin(a))
		var c: Vector3 = radial * ring_r
		var loop: Array = []
		for j in range(nv):
			var b: float = TAU * float(j) / float(nv)
			var rr: float = tube_r * cos(b)
			var hh: float = tube_r * sin(b)
			loop.append(c + radial * rr + Vector3(0.0, hh, 0.0))
		centres.append(c)
		loops.append(loop)
	for i in range(nu):
		var i2: int = (i + 1) % nu
		var la: Array = loops[i]
		var lb: Array = loops[i2]
		var mid: Vector3 = (centres[i] + centres[i2]) * 0.5
		for j in range(nv):
			var j2: int = (j + 1) % nv
			_quad_out(st, la[j], la[j2], lb[j2], lb[j], mid)
	st.generate_normals()
	return st.commit()


## One point on the cloak's hanging surface, (u along the shoulder arc, v down
## the drop). The same arithmetic _cloak_sheet lays out as a grid, exposed a
## point at a time so the cloth can be taken APART: cloak=unravelling samples it
## at three depths per thread, cloak=shattered samples it plus a step in u and a
## step in v so a patch can recover its own tangents and outward normal.
static func _cloak_p(c_t: Vector3, cs: float, rx: float, rz: float,
		a0: float, a1: float, u_sh: float, lift: float,
		l_front: float, l_back: float, flare: float, sweep: float,
		folds: float, fold_amp: float, twist: float, phase: float,
		hem_n: float, hem_ph: float, push: float, y_floor: float,
		u: float, v: float) -> Vector3:
	var a: float = lerpf(a0, a1, u)
	var rad: Vector3 = Vector3(sin(a) * cs, 0.0, -cos(a))
	if rad.length() < 0.0001:
		rad = Vector3.FORWARD
	rad = rad.normalized()
	var yt: float = c_t.y + lift * exp(-pow((u - u_sh) / 0.24, 2.0)) - 0.11 * u
	var top: Vector3 = Vector3(c_t.x + sin(a) * cs * rx, yt, c_t.z - cos(a) * rz)
	var hem: float = 1.0 + 0.13 * _tri(u * hem_n + hem_ph) + 0.055 * sin(u * 17.0 + hem_ph * 6.0)
	var ln: float = lerpf(l_front, l_back, _ss(u * 1.18)) * hem
	# cloth stops at the ground here too — no thread and no plate may sink
	ln = minf(ln, maxf(0.12, top.y - y_floor))
	var rout: float = 0.05 + flare * u
	var swp: float = sweep * _ss(u * 1.30)
	var wave: float = _tri(u * folds + twist * v + phase)
	var fold: float = fold_amp * pow(v, 0.75) * wave
	var q: Vector3 = top
	q += Vector3(0.0, -ln * v, 0.0)
	q += rad * (push + rout * pow(v, 1.4) + fold)
	q += Vector3(0.0, 0.0, swp * pow(v, 1.6))
	return q


static func _cloak_sheet(c_t: Vector3, cs: float, rx: float, rz: float,
		a0: float, a1: float, u_sh: float, lift: float,
		l_front: float, l_back: float, flare: float, sweep: float,
		folds: float, fold_amp: float, twist: float, phase: float,
		hem_n: float, hem_ph: float, push: float, y_floor: float,
		col: Color, col_dark: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var nu: int = 26
	var nv: int = 14
	var grid: Array = []
	var tints: Array = []
	for iu in range(nu + 1):
		var u: float = float(iu) / float(nu)
		var a: float = lerpf(a0, a1, u)
		var rad := Vector3(sin(a) * cs, 0.0, -cos(a))
		if rad.length() < 0.0001:
			rad = Vector3.FORWARD
		rad = rad.normalized()
		var yt: float = c_t.y + lift * exp(-pow((u - u_sh) / 0.24, 2.0)) - 0.11 * u
		var top := Vector3(c_t.x + sin(a) * cs * rx, yt, c_t.z - cos(a) * rz)
		var hem: float = 1.0 + 0.13 * _tri(u * hem_n + hem_ph) + 0.055 * sin(u * 17.0 + hem_ph * 6.0)
		var ln: float = lerpf(l_front, l_back, _ss(u * 1.18)) * hem
		# cloth stops at the ground: nothing on this sheet may fall below y_floor
		ln = minf(ln, maxf(0.12, top.y - y_floor))
		var rout: float = 0.05 + flare * u
		var swp: float = sweep * _ss(u * 1.30)
		var row: Array = []
		var trow: Array = []
		for iv in range(nv + 1):
			var v: float = float(iv) / float(nv)
			var wave: float = _tri(u * folds + twist * v + phase)
			var fold: float = fold_amp * pow(v, 0.75) * wave
			var q: Vector3 = top
			q += Vector3(0.0, -ln * v, 0.0)
			q += rad * (push + rout * pow(v, 1.4) + fold)
			q += Vector3(0.0, 0.0, swp * pow(v, 1.6))
			row.append(q)
			var shade: float = (0.60 + 0.40 * (0.5 + 0.5 * wave)) * lerpf(1.0, 0.84, v)
			trow.append(col_dark.lerp(col, clampf(shade, 0.0, 1.0)))
		grid.append(row)
		tints.append(trow)
	for iu in range(nu):
		var r0: Array = grid[iu]
		var r1: Array = grid[iu + 1]
		var t0: Array = tints[iu]
		var t1: Array = tints[iu + 1]
		for iv in range(nv):
			var p00: Vector3 = r0[iv]
			var p01: Vector3 = r0[iv + 1]
			var p10: Vector3 = r1[iv]
			var p11: Vector3 = r1[iv + 1]
			var c00: Color = t0[iv]
			var c01: Color = t0[iv + 1]
			var c10: Color = t1[iv]
			var c11: Color = t1[iv + 1]
			st.set_color(c00)
			st.add_vertex(p00)
			st.set_color(c10)
			st.add_vertex(p10)
			st.set_color(c11)
			st.add_vertex(p11)
			st.set_color(c00)
			st.add_vertex(p00)
			st.set_color(c11)
			st.add_vertex(p11)
			st.set_color(c01)
			st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


## cloak = flood: the cloth does not hang, it POURS. A closed solid of
## revolution about the figure's own vertical axis — high at the shoulder where
## it leaves the body (a_hi picks that side), dipping to the waist all the way
## round, then widening the whole way down until it reaches y_floor and spreads.
## The figure is inside it from the waist down; the folds survive as vertical
## creases in the poured wall, sharpened by a triangle wave and flat shading so
## the mass reads as something that ran and then SET.
static func _pour_mesh(cx: float, cz: float, y_waist: float, y_top: float, a_hi: float,
		r_top: float, r_bot: float, y_floor: float,
		folds: float, amp: float, phase: float,
		col: Color, col_dark: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var nu: int = 30
	var nv: int = 12
	var grid: Array = []
	var tints: Array = []
	for iu in range(nu + 1):
		var u: float = float(iu) / float(nu)
		var th: float = TAU * u
		# the lip is highest on the pour side and sinks to the waist opposite it
		var lobe: float = pow(0.5 + 0.5 * cos(th - a_hi), 2.0)
		var lip: float = lerpf(y_waist, y_top, lobe)
		var row: Array = []
		var trow: Array = []
		for iv in range(nv + 1):
			var v: float = float(iv) / float(nv)
			var wave: float = _tri(u * folds + 0.35 * v + phase)
			var yq: float = lerpf(lip, y_floor, pow(v, 0.92))
			var base_r: float = lerpf(r_top, r_bot, _ss(pow(v, 1.15)))
			var crease: float = amp * pow(v, 0.80) * wave
			var shoulder_swell: float = 0.030 * lobe * (1.0 - _ss(v * 1.60))
			var rq: float = maxf(base_r + crease + shoulder_swell, 0.02)
			row.append(Vector3(cx + cos(th) * rq, yq, cz + sin(th) * rq))
			var shade: float = (0.56 + 0.44 * (0.5 + 0.5 * wave)) * lerpf(1.0, 0.70, v)
			trow.append(col_dark.lerp(col, clampf(shade, 0.0, 1.0)))
		grid.append(row)
		tints.append(trow)
	for iu in range(nu):
		var ra: Array = grid[iu]
		var rb: Array = grid[iu + 1]
		var ta: Array = tints[iu]
		var tb: Array = tints[iu + 1]
		for iv in range(nv):
			var p00: Vector3 = ra[iv]
			var p01: Vector3 = ra[iv + 1]
			var p10: Vector3 = rb[iv]
			var p11: Vector3 = rb[iv + 1]
			var c00: Color = ta[iv]
			var c01: Color = ta[iv + 1]
			var c10: Color = tb[iv]
			var c11: Color = tb[iv + 1]
			st.set_color(c00)
			st.add_vertex(p00)
			st.set_color(c11)
			st.add_vertex(p11)
			st.set_color(c10)
			st.add_vertex(p10)
			st.set_color(c00)
			st.add_vertex(p00)
			st.set_color(c01)
			st.add_vertex(p01)
			st.set_color(c11)
			st.add_vertex(p11)
	# the puddle face, closing the pour onto the ground
	var floor_c: Vector3 = Vector3(cx, y_floor, cz)
	var inside_lo: Vector3 = Vector3(cx, y_floor + 0.14, cz)
	st.set_color(col_dark.lerp(col, 0.34))
	for iu in range(nu):
		var pa: Vector3 = grid[iu][nv]
		var pb: Vector3 = grid[iu + 1][nv]
		_tri_out(st, floor_c, pa, pb, inside_lo)
	# the top surface, sloping in from the lip to the body it swallows
	var apex_y: float = lerpf(y_waist, y_top, 0.28)
	var apex: Vector3 = Vector3(cx, apex_y, cz)
	var inside_hi: Vector3 = Vector3(cx, y_waist - 0.24, cz)
	st.set_color(col_dark.lerp(col, 0.94))
	for iu in range(nu):
		var qa: Vector3 = grid[iu][0]
		var qb: Vector3 = grid[iu + 1][0]
		_tri_out(st, apex, qa, qb, inside_hi)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# textures

static func _marble_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# bone ground with thin wandering grey veins; seamless (integer frequencies)
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var f1: float = float(rng.randi_range(2, 4))
	var f2: float = float(rng.randi_range(1, 3))
	var f3: float = float(rng.randi_range(4, 7))
	var g1: float = float(rng.randi_range(1, 3))
	var g2: float = float(rng.randi_range(2, 5))
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	var warp: float = rng.randf_range(0.35, 0.85)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var u: float = float(x) / float(TEX_SIZE)
			var v: float = float(y) / float(TEX_SIZE)
			var w1: float = sin(TAU * (f1 * u + g1 * v) + ph1 + warp * sin(TAU * f2 * v + ph2))
			var w2: float = sin(TAU * (f3 * u - g2 * v) + ph3 + warp * 0.6 * sin(TAU * f1 * u + ph1))
			var vein: float = pow(1.0 - absf(w1), 14.0) * 0.55 + pow(1.0 - absf(w2), 22.0) * 0.35
			var mottle: float = 0.02 * sin(TAU * (g2 * u + f1 * v) + ph2)
			var tone: float = clampf(0.985 - vein * 0.20 + mottle, 0.70, 1.0)
			img.set_pixel(x, y, Color(tone, tone * 0.995, tone * 0.982))
	return ImageTexture.create_from_image(img)


static func _weave_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# near-white twill so the cloak's vertex colour tints it
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var period: int = rng.randi_range(5, 9)
	var run: int = maxi(2, period / 2)
	var depth: float = rng.randf_range(0.06, 0.13)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var d: int = posmod(x + y, period)
			var e: int = posmod(x - y, period * 2)
			var over: float = 1.0
			if d >= run:
				over = 1.0 - depth
			var slub: float = 1.0
			if e < 2:
				slub = 1.0 - depth * 0.35
			var jitter: float = rng.randf_range(-0.012, 0.012)
			var tone: float = clampf(over * slub + jitter, 0.55, 1.0)
			img.set_pixel(x, y, Color(tone, tone, tone))
	return ImageTexture.create_from_image(img)


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
