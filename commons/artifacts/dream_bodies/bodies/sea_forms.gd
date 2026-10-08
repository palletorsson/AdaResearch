extends RefCounted
## sea_forms — one striding walker from the sea-creature panorama.
##
## Reference: scratchpad/refs/sea_forms.png — a 2048x536 panorama of upright, striding
## sea-creature figurines: soft clay bodies with cartoon eyes, long swan necks and small
## beaked heads, segmented beaded tentacle arms (one raised, one trailing), and animal
## skins — zebra bands, honeycomb / giraffe cells, fine dot grids, chains of beads.
## This builder is the walker between the zebra one and the dotted one, carrying a
## beaded ball in its arms.
##
## Reproduced, and how:
##   1. The striding biped stance — two legs (CapsuleMesh thigh + shin, a knee sphere) in a
##      stride, flattened SphereMesh feet on the floor, a fat hip sphere. The seed picks the
##      stride length and which side the trailing tentacle and the raised one go.
##   2. The tapered clay torso leaning forward — a CylinderMesh frustum between the hip
##      sphere and a wide shoulder sphere; the lean is seeded.
##   3. The swan neck rising in an S — a chain of shrinking SphereMesh beads laid along a
##      Catmull-Rom spline (forward bow and sideways sway seeded), a head sphere on top with
##      a PrismMesh beak and two cartoon eyes (white sphere + black pupil), the head turned.
##   4. Four segmented tentacles — chains of shrinking beads on splines, spaced by their
##      own radius so they read as strings of beads: two cradle the ball from either
##      shoulder, one rises behind the neck and curls over the head, one trails from the hip
##      and coils on the floor behind as a tail.
##   5. The beaded ball the figures carry — a radiolarian lattice: seven TorusMesh rings
##      (four meridians, an equator and two parallels) tilted by the seed, a dark core
##      sphere, eight CylinderMesh cone spines pointing out through the rings.
##   6. The skins — three ImageTextures painted in code: irregular zebra bands, a fine dot
##      grid (sometimes staggered, sometimes inverted), Voronoi cells with light borders.
##      The seed deals them to torso/legs, neck/head and tentacles, so no two seeds wear
##      the same coat.
##   7. Fin flaps — thin PrismMesh fans: four to six dorsal flaps down the spine, three to
##      five on the crown of the head.
##
## Given up: the grass on the floor, and the other eleven bodies.
##
## ---------------------------------------------------------------------------------------
## THE GLOSS (2026-09-03 — Palle: "add super glossy and queer materials"). Every surface
## now comes out of DreamSkin. The seed deals ONE finish for the whole statue out of
## latex, patent, oil slick, holographic foil, candy glaze, chrome, pearl and wet, plus
## three colours from the queer palette. The panorama's monochrome is gone and the family
## keeps its argument anyway: the three painted skins still argue — the zebra bands, the
## dot grid and the Voronoi cells are printed as a saturated colour on a pale one and hung
## on the glossy material, so the coat is still a coat and the body underneath is wet.
## The fossil forces "pearl": a fossil in this family is nacre, not chalk.
##
## THE MATTE PASSAGE is the family's drawn LINE — beak, dorsal and crest fins, the ball's
## spines and dark core, the coral fans, the pupils. Those stay flat ink, because a
## cartoon eye and a drawn fin only read against a shine. That contrast is the point.
##
## ---------------------------------------------------------------------------------------
## AXES (the family's two dimensions of variation; the first value of each is the statue
## as it has always stood, so build(root, seed) is unchanged):
##
##   flesh — WHAT THE BODY IS MADE OF, and so its whole silhouette. clay: the striding
##           creature above. melted: the skeleton collapses to half height, the legs sag
##           into wide puddle feet, the hips drip into a solid floor pour, every bead
##           squashes and the raised tentacle flops. fossil: the flesh is gone — limbs
##           become thin bone rods with big joint knots, the torso a rib cage of hoops, and
##           every bead on every tentacle becomes a vertebra ring threaded on its spline.
##           swarm: torso, hips and legs dissolve into hundreds of loose grains and the
##           tentacles scatter off their own curves. inflated: the creature is blown up —
##           balloon limbs, a swollen ellipsoid trunk, few and enormous beads.
##           fused: the body is not assembled at all. The same joints and the same radii
##           are handed to DreamIso as a signed distance field and MARCHED, so the legs
##           swell into the hips instead of meeting them, the neck GROWS out of the
##           shoulders, the four tentacles leave the body as thickened webs rather than
##           strings of beads, and a hydra's three heads share one throat. A capsule is
##           subtracted through the chest, so the hole in this body is not a missing piece
##           but a place the field never crossed zero. DELIBERATE LOW COUNT: a grown body
##           is ONE MeshInstance3D, so "fused" publishes 46-69 meshes, the lowest in the
##           family — the lattice ball, the eyes and beak, the fins, the flowers and a line
##           of pearls pressed along the fused seams are still primitives on top. If the
##           mesher returns nothing the value falls back to the family's assembled body
##           (chunkier: trunk 1.18x, beads 1.25x) rather than standing an empty plinth.
##
##   crown — WHAT RISES OFF THE SHOULDERS. swan: one S-neck, one beaked two-eyed head with
##           its crest. hydra: three shorter necks, three heads splayed left, forward and
##           right. bloom: the head is gone and the neck opens into an eight-petalled
##           flower with stamens, with buds on two of the tentacle tips. coral: the neck
##           forks above the shoulders into four beaded branches, each ending in a flat fan.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

## The finishes a sea creature is allowed: every one of them is wet. "neon" and "matte"
## are left out of the deal — a whole body at emission 3.2 photographs as a white blob,
## and matte is reserved for this family's drawn line.
const WET_SKINS: Array[String] = ["latex", "patent", "oilslick", "holo", "candy",
	"chrome", "pearl", "wet"]


static func axes() -> Dictionary:
	return {
		"flesh": ["clay", "melted", "fossil", "swarm", "inflated", "fused"],
		"crown": ["swan", "hydra", "bloom", "coral"],
	}


static func describe() -> String:
	return "A striding sea-creature in latex, oil slick or chrome: a striped-or-dotted glossy body on two thick legs, a swan neck with a beaked two-eyed head, four beaded tentacles cradling a radiolarian lattice ball, matte ink fins down its spine."


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var flesh: String = String(opts.get("flesh", "clay"))
	var crown: String = String(opts.get("crown", "swan"))
	var melted: bool = flesh == "melted"
	var fossil: bool = flesh == "fossil"
	var swarmed: bool = flesh == "swarm"
	var puffed: bool = flesh == "inflated"
	var fused: bool = flesh == "fused"

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	# ---- the gloss: one finish and three colours for the whole individual ----
	var finish: String = WET_SKINS[rng.randi_range(0, WET_SKINS.size() - 1)]
	if fossil:
		finish = "pearl"
	var fit: Dictionary = Gloss.outfit(rng, finish)
	var main: Color = fit["main"]
	var accent: Color = fit["accent"]
	var third: Color = Gloss.queer_colour(rng)
	var ink: Color = Gloss.QUEER["ink"]
	var cream: Color = Gloss.QUEER["cream"]

	# ---- deal the three painted skins to torso/legs, neck/head, tentacles ----
	var pats: Array[int] = [0, 1, 2]
	for i in range(2, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = pats[i]
		pats[i] = pats[j]
		pats[j] = tmp
	var tex_body: ImageTexture = _tex_kind(pats[0], rng, main, _pale(main))
	var tex_neck: ImageTexture = _tex_kind(pats[1], rng, third, cream)
	var tex_tent: ImageTexture = _tex_kind(pats[2], rng, accent, _pale(accent))

	var mat_torso: StandardMaterial3D = _gloss(finish, main, tex_body, Vector3(3.0, 1.25, 1.0), false, rng)
	var mat_hip: StandardMaterial3D = _gloss(finish, main, tex_body, Vector3(2.0, 1.0, 1.0), false, rng)
	var mat_leg: StandardMaterial3D = _gloss(finish, main, tex_body, Vector3(1.5, 1.5, 1.0), false, rng)
	var mat_neck: StandardMaterial3D = _gloss(finish, third, tex_neck, Vector3(2.0, 1.0, 1.0), false, rng)
	var mat_tent: StandardMaterial3D = _gloss(finish, accent, tex_tent, Vector3(2.0, 1.0, 1.0), false, rng)
	var mat_white: StandardMaterial3D = Gloss.skin(finish, cream, rng)
	var mat_stud: StandardMaterial3D = Gloss.skin(finish, third, rng)
	# THE MATTE PASSAGE: the drawn line this family is drawn with.
	var mat_black: StandardMaterial3D = Gloss.skin("matte", ink, rng)
	var mat_pupil: StandardMaterial3D = Gloss.skin("matte", ink, rng)
	var mat_eye: StandardMaterial3D = Gloss.skin("wet", Color(0.98, 0.97, 0.99), rng)
	var mat_bone: StandardMaterial3D = Gloss.skin("pearl", accent, rng)

	# axis "flesh": the fossil wears no coat at all — nacre everywhere, and the cartoon
	# eyes become empty sockets.
	if fossil:
		mat_torso = mat_bone
		mat_hip = mat_bone
		mat_leg = mat_bone
		mat_neck = mat_bone
		mat_tent = mat_bone
		mat_eye = mat_black

	# ---- the individual: pose numbers ----
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lean_x: float = rng.randf_range(-0.08, 0.08)
	var lean_z: float = rng.randf_range(-0.14, -0.04)
	var stride: float = rng.randf_range(0.18, 0.32)
	var body_r: float = rng.randf_range(0.15, 0.18)
	var neck_len: float = rng.randf_range(0.28, 0.36)
	var neck_bow: float = rng.randf_range(0.10, 0.20)
	var neck_sway: float = rng.randf_range(-0.08, 0.08)
	var head_turn: float = rng.randf_range(-40.0, 40.0)
	var ball_x: float = rng.randf_range(-0.08, 0.08)
	var ball_y: float = rng.randf_range(0.66, 0.74)

	# ---- axis "flesh": the numbers that decide what the body is made of ----
	# Every multiplier is exactly 1.0 on "clay", so the default statue is untouched.
	var bead_mode: String = "bead"
	var bead_rk: float = 1.0
	var cap_k: float = 1.0
	var bead_sq: Vector3 = Vector3.ONE
	var bead_jit: float = 0.0
	var hip_y: float = 0.54
	var sh_y: float = 0.92
	var body_rr: float = body_r
	var raise_k: float = 1.0
	var reach_k: float = 1.0
	var ball_rr: float = 0.14
	var ball_sq: Vector3 = Vector3.ONE
	var fin_len_k: float = 1.0
	var fin_w_k: float = 1.0
	if melted:
		bead_mode = "melt"
		bead_rk = 1.08
		bead_sq = Vector3(1.36, 0.56, 1.36)
		hip_y = 0.32
		sh_y = 0.58
		lean_z -= 0.16
		body_rr = body_r * 1.42
		stride *= 1.55
		neck_len *= 0.60
		neck_bow *= 2.30
		raise_k = 0.32
		reach_k = 1.28
		ball_y *= 0.48
		ball_rr = 0.155
		ball_sq = Vector3(1.28, 0.52, 1.28)
		fin_len_k = 1.70
		fin_w_k = 0.85
	elif fossil:
		bead_mode = "ring"
		bead_rk = 1.20
		cap_k = 0.86
		body_rr = body_r * 0.86
		ball_rr = 0.145
		fin_len_k = 1.55
		fin_w_k = 1.35
	elif swarmed:
		bead_mode = "grain"
		bead_rk = 0.76
		cap_k = 0.72
		bead_jit = 1.0
		body_rr = body_r * 1.10
	elif puffed:
		bead_mode = "puff"
		bead_rk = 1.70
		cap_k = 0.55
		hip_y = 0.50
		sh_y = 0.90
		body_rr = body_r * 1.62
		stride *= 0.58
		neck_len *= 0.86
		raise_k = 0.88
		ball_rr = 0.185
		ball_sq = Vector3(1.14, 1.14, 1.14)
		fin_len_k = 0.55
		fin_w_k = 1.60
	elif fused:
		# thicker everywhere, and reaching a little less far: a field cannot carry a
		# noodle thinner than its own cell, and these numbers are also the fallback body.
		bead_rk = 1.25
		cap_k = 0.80
		body_rr = body_r * 1.18
		reach_k = 0.92
		raise_k = 0.94
		ball_rr = 0.150
		fin_len_k = 1.15
		fin_w_k = 1.20

	var hip: Vector3 = Vector3(0.0, hip_y, 0.0)
	var shoulder: Vector3 = Vector3(lean_x, sh_y, lean_z)
	var leg_lift: float = hip_y / 0.54

	# ---- the ball and the four tentacle curves, decided before anything is drawn, so the
	# ---- field and the bead chains are laid on exactly the same lines ----
	var ball: Vector3 = Vector3(ball_x, ball_y, -0.34 * reach_k)
	var a_pts: Array[Vector3] = [
		shoulder + Vector3(0.10 * reach_k, -0.01, -0.03),
		Vector3(0.30 * reach_k, sh_y - 0.06, -0.18),
		ball + Vector3(0.18, 0.06, 0.0),
		ball + Vector3(0.0, 0.0, -0.18),
		ball + Vector3(-0.18, -0.06, 0.0),
		ball + Vector3(-0.10, -0.16, 0.10),
		ball + Vector3(0.02, -0.22, 0.04),
	]
	var b_pts: Array[Vector3] = [
		shoulder + Vector3(-0.10 * reach_k, -0.01, -0.03),
		ball + Vector3(-0.26, 0.20, 0.14),
		ball + Vector3(-0.19, 0.02, -0.04),
		ball + Vector3(-0.04, -0.18, -0.06),
		ball + Vector3(0.16, -0.09, -0.13),
		ball + Vector3(0.12, 0.09, -0.20),
		ball + Vector3(-0.02, 0.14, -0.21),
	]
	var c_pts: Array[Vector3] = [
		shoulder + Vector3(side * 0.05 * reach_k, 0.05 * raise_k, 0.07 * reach_k),
		shoulder + Vector3(side * 0.15 * reach_k, 0.28 * raise_k, 0.16 * reach_k),
		shoulder + Vector3(side * 0.13 * reach_k, 0.52 * raise_k, 0.02 * reach_k),
		shoulder + Vector3(side * 0.02 * reach_k, 0.60 * raise_k, -0.16 * reach_k),
		shoulder + Vector3(-side * 0.08 * reach_k, 0.52 * raise_k, -0.30 * reach_k),
		shoulder + Vector3(-side * 0.10 * reach_k, 0.40 * raise_k, -0.30 * reach_k),
	]
	var d_pts: Array[Vector3] = [
		hip + Vector3(side * 0.04, -0.03, 0.10 * reach_k),
		Vector3(side * 0.16 * reach_k, 0.40 * raise_k, 0.30 * reach_k),
		Vector3(side * 0.27 * reach_k, 0.22 * raise_k, 0.42 * reach_k),
		Vector3(side * 0.16 * reach_k, 0.05, 0.48 * reach_k),
		Vector3(-side * 0.06 * reach_k, 0.045, 0.43 * reach_k),
		Vector3(-side * 0.15 * reach_k, 0.04, 0.28 * reach_k),
	]

	# ---- axis "flesh" = fused: march the whole creature out of one field ----
	# CHECKED, NOT ASSUMED: the mesher is new. If it hands back nothing, `grown` stays
	# false and every primitive block below runs exactly as it does for clay, so the
	# value falls back to an assembled body instead of an empty plinth.
	var grown: bool = false
	if fused:
		var parts: Array = _fused_parts(crown, hip, shoulder, body_rr, leg_lift, stride,
			neck_len, neck_bow, neck_sway, a_pts, b_pts, c_pts, d_pts)
		var grown_mesh: ArrayMesh = Iso.mesh_of(parts, 0.058, 0.125, 0.07)
		if grown_mesh != null:
			# triplanar, because a marched mesh carries no UVs at all
			var mat_grown: StandardMaterial3D = _gloss(finish, main, tex_body, Vector3(2.4, 2.4, 2.4), true, rng)
			_mesh_basis(root, grown_mesh, mat_grown, Vector3.ZERO, Basis.IDENTITY)
			grown = true

	# ---- legs: left leg steps forward (-z), right leg trails ----
	var leg_x: Array[float] = [-1.0, 1.0]
	var leg_count: int = 0 if grown else 2
	for li in range(leg_count):
		var lx: float = leg_x[li]
		var fwd: float = -1.0 if li == 0 else 1.0
		var kz: float = stride * 0.45 if li == 0 else stride * 0.35
		var hj: Vector3 = Vector3(lx * 0.09, 0.47 * leg_lift, 0.0)
		var knee: Vector3 = Vector3(lx * 0.10, 0.26 * leg_lift, fwd * kz)
		var foot: Vector3 = Vector3(lx * 0.11, 0.045, fwd * stride * 0.5)
		var ankle: Vector3 = foot + Vector3(0.0, 0.03, 0.0)
		if swarmed:
			# the leg is a falling column of its own grains
			var col: Array[Vector3] = [hj, knee, ankle]
			for gi in range(10):
				var gt: float = float(gi) / 9.0
				var gp: Vector3 = _spline(col, gt)
				gp += _rand_dir(rng) * rng.randf_range(0.01, 0.07) * (0.45 + gt)
				var gr: float = lerpf(0.050, 0.030, gt)
				gp.y = maxf(gp.y, gr)
				_sphere(root, gp, gr, mat_leg)
		elif melted:
			_taper(root, hj, knee, 0.104, 0.088, mat_leg)
			_taper(root, knee, ankle, 0.088, 0.062, mat_leg)
			_sphere(root, knee, 0.098, mat_leg)
			_mesh_basis(root, _sphere_mesh(0.082), mat_leg, Vector3(lx * 0.13, 0.020, fwd * stride * 0.52), Basis.from_scale(Vector3(2.6, 0.24, 3.0)))
		elif fossil:
			_capsule_between(root, hj, knee, 0.024, mat_leg)
			_capsule_between(root, knee, ankle, 0.020, mat_leg)
			_sphere(root, knee, 0.054, mat_leg)
			_mesh_basis(root, _sphere_mesh(0.058), mat_leg, foot, Basis.from_scale(Vector3(1.0, 0.42, 1.55)))
		elif puffed:
			_capsule_between(root, hj, knee, 0.128, mat_leg)
			_capsule_between(root, knee, ankle, 0.112, mat_leg)
			_sphere(root, knee, 0.126, mat_leg)
			_mesh_basis(root, _sphere_mesh(0.118), mat_leg, foot + Vector3(0.0, 0.035, 0.0), Basis.from_scale(Vector3(1.05, 0.74, 1.4)))
		else:
			_capsule_between(root, hj, knee, 0.072, mat_leg)
			_capsule_between(root, knee, ankle, 0.056, mat_leg)
			_sphere(root, knee, 0.066, mat_leg)
			_mesh_basis(root, _sphere_mesh(0.075), mat_leg, foot, Basis.from_scale(Vector3(1.0, 0.55, 1.35)))

	# ---- hips, torso, shoulders ----
	if grown:
		# the trunk is already in the field. What it gets instead is ornament: a line of
		# pearls pressed down the front, where the beads used to be.
		for sdi in range(5):
			var sd_t: float = 0.18 + 0.66 * float(sdi) / 4.0
			var sd_r: float = lerpf(body_rr * 0.88, 0.115, sd_t)
			var sd_p: Vector3 = hip.lerp(shoulder, sd_t) + Vector3(0.0, 0.0, -sd_r * 0.88)
			_sphere(root, sd_p, 0.026, mat_stud)
	elif swarmed:
		# the trunk is not a solid — it is a cloud of itself, still trunk-shaped
		var axis_d: Vector3 = shoulder - hip
		var axis_b: Basis = _basis_y(axis_d)
		for gj in range(30):
			var st_t: float = rng.randf()
			var st_r: float = lerpf(body_rr * 0.95, 0.10, st_t)
			var st_a: float = rng.randf() * TAU
			var st_u: float = sqrt(rng.randf()) * st_r * 1.20
			var st_p: Vector3 = hip + axis_d * st_t + axis_b * Vector3(cos(st_a) * st_u, 0.0, sin(st_a) * st_u * 0.9)
			_sphere(root, st_p, rng.randf_range(0.028, 0.050), mat_torso)
		for gk in range(10):
			_sphere(root, hip + _rand_dir(rng) * body_rr * rng.randf_range(0.30, 1.05), rng.randf_range(0.040, 0.062), mat_hip)
		for gl in range(6):
			_sphere(root, shoulder + _rand_dir(rng) * 0.13 * rng.randf_range(0.30, 1.10), rng.randf_range(0.038, 0.058), mat_hip)
	elif fossil:
		# no flesh left: a spine, a rib cage of hoops, a pelvis ring, a collar ring
		var ax_d: Vector3 = shoulder - hip
		var ax_b: Basis = _basis_y(ax_d)
		_capsule_between(root, hip, shoulder, 0.022, mat_torso)
		for ri in range(7):
			var rib_t: float = float(ri) / 6.0
			var rib_r: float = lerpf(body_rr * 1.04, 0.105, rib_t)
			_hoop(root, hip + ax_d * (0.06 + 0.88 * rib_t), ax_b * Basis.from_scale(Vector3(1.0, 1.0, 0.86)), rib_r, 0.013, mat_torso)
		_hoop(root, hip, Basis.IDENTITY, body_rr, 0.019, mat_hip)
		_hoop(root, shoulder, Basis(Vector3.RIGHT, deg_to_rad(14.0)), 0.125, 0.016, mat_hip)
	elif melted:
		_mesh_basis(root, _sphere_mesh(body_rr), mat_hip, hip, Basis.from_scale(Vector3(1.50, 0.72, 1.50)))
		var mtorso: CylinderMesh = CylinderMesh.new()
		mtorso.bottom_radius = body_rr * 1.05
		mtorso.top_radius = 0.13
		mtorso.height = hip.distance_to(shoulder)
		mtorso.radial_segments = 32
		mtorso.rings = 4
		_mesh_basis(root, mtorso, mat_torso, (hip + shoulder) * 0.5, _basis_y(shoulder - hip) * Basis.from_scale(Vector3(1.15, 1.0, 0.95)))
		_mesh_basis(root, _sphere_mesh(0.15), mat_hip, shoulder, Basis.from_scale(Vector3(1.30, 0.72, 1.0)))
		# the pour it is standing in, and the four ropes of body still feeding it
		_mesh_basis(root, _sphere_mesh(0.30), mat_torso, Vector3(0.0, 0.026, 0.02), Basis.from_scale(Vector3(1.15, 0.085, 1.25)))
		for mi2 in range(4):
			var drip_a: float = float(mi2) * TAU / 4.0 + 0.4
			var drip_p: Vector3 = hip + Vector3(cos(drip_a) * body_rr * 0.85, -0.02, sin(drip_a) * body_rr * 0.85)
			_taper(root, Vector3(drip_p.x * 1.30, 0.024, drip_p.z * 1.30), drip_p, 0.060, 0.030, mat_torso)
	elif puffed:
		_sphere(root, hip, body_rr, mat_hip)
		_mesh_basis(root, _sphere_mesh(body_rr * 1.12), mat_torso, hip.lerp(shoulder, 0.52), _basis_y(shoulder - hip) * Basis.from_scale(Vector3(1.0, 1.32, 0.94)))
		_mesh_basis(root, _sphere_mesh(0.16), mat_hip, shoulder, Basis.from_scale(Vector3(1.12, 0.92, 1.0)))
	else:
		_sphere(root, hip, body_rr, mat_hip)
		var torso: CylinderMesh = CylinderMesh.new()
		torso.bottom_radius = body_rr * 0.95
		torso.top_radius = 0.10
		torso.height = hip.distance_to(shoulder)
		torso.radial_segments = 32
		torso.rings = 4
		var torso_b: Basis = _basis_y(shoulder - hip) * Basis.from_scale(Vector3(1.0, 1.0, 0.88))
		_mesh_basis(root, torso, mat_torso, (hip + shoulder) * 0.5, torso_b)
		_mesh_basis(root, _sphere_mesh(0.115), mat_hip, shoulder, Basis.from_scale(Vector3(1.15, 0.9, 0.95)))

	# ---- axis "crown": what rises off the shoulders ----
	var n0: Vector3 = shoulder + Vector3(0.0, 0.05, -0.01)
	var neck_cap: int = maxi(int(round(14.0 * cap_k)), 5)
	var head: Vector3 = shoulder
	var hb: Basis = Basis(Vector3.UP, deg_to_rad(head_turn))

	if crown == "hydra":
		# three necks out of one collar — left, forward, right. On a fused body they are
		# one throat that splits, because the field unions them before it is meshed.
		for hi in range(3):
			var hpts: Array[Vector3] = _hydra_pts(shoulder, hi, neck_sway, neck_len, neck_bow)
			_bead_chain_g(root, grown, hpts, 0.060, 0.040, mat_neck, 1.0, maxi(int(round(9.0 * cap_k)), 4), bead_mode, bead_rk, bead_sq, bead_jit, rng)
			var hh: Vector3 = _hydra_head(hpts, hi, neck_sway)
			var hhb: Basis = Basis(Vector3.UP, deg_to_rad(head_turn + (float(hi) - 1.0) * 38.0))
			_head(root, hh, hhb, 0.062, mat_neck, mat_black, mat_eye, mat_pupil, not grown)
			if hi == 1:
				head = hh
				hb = hhb
	elif crown == "coral":
		# the neck never finishes: a short trunk, then four branches ending in flat fans
		var tpts: Array[Vector3] = _coral_pts(n0, neck_sway, neck_len, neck_bow)
		_bead_chain_g(root, grown, tpts, 0.078, 0.056, mat_neck, 1.0, maxi(int(round(8.0 * cap_k)), 4), bead_mode, bead_rk, bead_sq, bead_jit, rng)
		var fork: Vector3 = tpts[2]
		for bi in range(4):
			var bpts: Array[Vector3] = _coral_branch(fork, bi, neck_len, neck_bow)
			_bead_chain_g(root, grown, bpts, 0.048, 0.026, mat_neck, 1.2, maxi(int(round(7.0 * cap_k)), 3), bead_mode, bead_rk, bead_sq, bead_jit, rng)
			var br_a: float = _coral_angle(bi)
			var br_d: Vector3 = _coral_dir(bi)
			var tip: Vector3 = bpts[2]
			var fan: PrismMesh = PrismMesh.new()
			fan.size = Vector3(0.17, 0.13, 0.016)
			_mesh_basis(root, fan, mat_black, tip + br_d * 0.055, _basis_xy(Vector3(-sin(br_a), 0.0, cos(br_a)), br_d))
			_sphere(root, tip, 0.038, mat_neck)
		head = fork + Vector3(0.0, neck_len * 0.5, 0.0)
	elif crown == "bloom":
		# the head opens instead of looking
		var fpts: Array[Vector3] = _swan_pts(n0, neck_sway, neck_len, neck_bow)
		_bead_chain_g(root, grown, fpts, 0.072, 0.048, mat_neck, 1.0, neck_cap, bead_mode, bead_rk, bead_sq, bead_jit, rng)
		head = fpts[3] + Vector3(neck_sway * 0.1, 0.075, -0.02)
		hb = Basis(Vector3.UP, deg_to_rad(head_turn)) * Basis(Vector3.RIGHT, deg_to_rad(-26.0))
		_flower(root, head, hb, 0.150, 8, mat_white, mat_black, mat_neck)
	else:
		# ---- the swan neck: beads on a spline ----
		var n_pts: Array[Vector3] = _swan_pts(n0, neck_sway, neck_len, neck_bow)
		_bead_chain_g(root, grown, n_pts, 0.072, 0.048, mat_neck, 1.0, neck_cap, bead_mode, bead_rk, bead_sq, bead_jit, rng)
		head = n_pts[3] + Vector3(neck_sway * 0.1, 0.055, -0.02)
		# ---- head: elongated sphere, prism beak, two cartoon eyes ----
		_head(root, head, hb, 0.08, mat_neck, mat_black, mat_eye, mat_pupil, not grown)

	# ---- the crest on the crown of the head (a flower and a coral have none) ----
	var crest_n: int = rng.randi_range(3, 5)
	var crest_hs: float = 1.0
	if crown == "hydra":
		crest_hs = 0.775
	if crown != "bloom" and crown != "coral":
		_crest(root, head, hb, crest_n, crest_hs, mat_black)

	# ---- dorsal fin flaps down the spine (back is +z) ----
	var dorsal_n: int = rng.randi_range(4, 6)
	var fd: Vector3 = Vector3(0.0, 0.45, 1.0).normalized()
	var fin_mat: StandardMaterial3D = mat_black
	if melted:
		fd = Vector3(0.0, -0.62, 1.0).normalized()
	elif fossil:
		fin_mat = mat_bone
	for di in range(dorsal_n):
		var dt: float = 0.12 + 0.76 * float(di) / float(dorsal_n - 1)
		var axis_p: Vector3 = hip.lerp(shoulder, dt)
		var rad_t: float = lerpf(body_rr * 0.95, 0.10, dt) * 0.88
		var fp: Vector3 = axis_p + Vector3(0.0, 0.0, rad_t - 0.01)
		if swarmed:
			_sphere(root, fp + Vector3(0.0, 0.02, 0.035), 0.026, mat_black)
			continue
		var dfin: PrismMesh = PrismMesh.new()
		var dfl: float = lerpf(0.10, 0.06, dt) * fin_len_k
		dfin.size = Vector3(0.012 * fin_w_k, dfl, 0.055 * fin_w_k)
		_mesh_basis(root, dfin, fin_mat, fp + fd * dfl * 0.35, _basis_xy(Vector3.RIGHT, fd))
	if swarmed:
		for fi in range(4):
			var fl_t: float = 0.18 + 0.66 * float(fi) / 3.0
			_sphere(root, hip.lerp(shoulder, fl_t) + Vector3(0.0, 0.05, body_rr * 1.35), 0.022, mat_black)

	# ---- the radiolarian ball, held in front of the belly ----
	var ball_r: float = ball_rr
	var tilt: Basis = Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(-20.0, 20.0))) * Basis(Vector3.FORWARD, deg_to_rad(rng.randf_range(-25.0, 25.0)))
	if swarmed:
		# the lattice has come apart into the grains it was drawn with
		for bg in range(12):
			_sphere(root, ball + _rand_dir(rng) * ball_r * rng.randf_range(0.25, 1.35), rng.randf_range(0.022, 0.050), mat_white)
	else:
		var btilt: Basis = tilt
		if not ball_sq.is_equal_approx(Vector3.ONE):
			btilt = tilt * Basis.from_scale(ball_sq)
		var tube: float = 0.011
		if puffed:
			tube = 0.019
		elif fossil:
			tube = 0.013
		elif grown:
			tube = 0.014
		var par_off: Array[float] = [0.0, 0.57, -0.57]
		for pl in range(3):
			var off: float = par_off[pl]
			var pr: float = ball_r * sqrt(1.0 - off * off)
			var tor_p: TorusMesh = TorusMesh.new()
			tor_p.inner_radius = pr - tube
			tor_p.outer_radius = pr + tube
			tor_p.rings = 48
			tor_p.ring_segments = 16
			_mesh_basis(root, tor_p, mat_white, ball + btilt * Vector3(0.0, ball_r * off, 0.0), btilt)
		for mi_i in range(4):
			var phi: float = float(mi_i) * PI * 0.25
			var tor_m: TorusMesh = TorusMesh.new()
			tor_m.inner_radius = ball_r - tube
			tor_m.outer_radius = ball_r + tube
			tor_m.rings = 48
			tor_m.ring_segments = 16
			_mesh_basis(root, tor_m, mat_white, ball, btilt * Basis(Vector3.UP, phi) * Basis(Vector3.RIGHT, PI * 0.5))
		_sphere(root, ball, ball_r * 0.36, mat_black)
		var spine_n: int = 8
		if fossil:
			spine_n = 14
		for si in range(spine_n):
			var th: float = float(si) * TAU / float(spine_n) + rng.randf_range(-0.25, 0.25)
			var el: float = rng.randf_range(-0.55, 0.65)
			var sd: Vector3 = btilt * Vector3(cos(el) * cos(th), sin(el), cos(el) * sin(th))
			var spine: CylinderMesh = CylinderMesh.new()
			spine.top_radius = 0.0
			spine.bottom_radius = 0.007
			spine.height = 0.08
			spine.radial_segments = 8
			spine.rings = 1
			_mesh_basis(root, spine, mat_black, ball + sd * (ball_r + 0.035), _basis_y(sd))
		if melted:
			for mdi in range(3):
				var md_a: float = float(mdi) * TAU / 3.0 + 0.7
				var md_p: Vector3 = ball + Vector3(cos(md_a) * ball_r * 0.70, -ball_r * 0.40, sin(md_a) * ball_r * 0.70)
				_taper(root, Vector3(md_p.x, 0.024, md_p.z), md_p, 0.050, 0.022, mat_white)

	# ---- the four tentacles ----
	# A: right shoulder, out, then around the ball and down.
	_bead_chain_g(root, grown, a_pts, 0.055, 0.014, mat_tent, 1.45, maxi(int(round(34.0 * cap_k)), 10), bead_mode, bead_rk, bead_sq, bead_jit, rng)
	# B: left shoulder, down the side, under the ball, curling up in front.
	_bead_chain_g(root, grown, b_pts, 0.055, 0.014, mat_tent, 1.45, maxi(int(round(34.0 * cap_k)), 10), bead_mode, bead_rk, bead_sq, bead_jit, rng)
	# C: the raised one, up behind the neck and over the head.
	_bead_chain_g(root, grown, c_pts, 0.046, 0.012, mat_tent, 1.5, maxi(int(round(32.0 * cap_k)), 10), bead_mode, bead_rk, bead_sq, bead_jit, rng)
	# D: the tail, lifting off the hip and coiling on the floor behind.
	_bead_chain_g(root, grown, d_pts, 0.06, 0.03, mat_tent, 1.4, maxi(int(round(28.0 * cap_k)), 8), bead_mode, bead_rk, bead_sq, bead_jit, rng)

	# a grown body has no beads, so it wears them: pearls pressed into the two arms that
	# cradle the ball, along the line the chain would have taken.
	if grown:
		_studs(root, a_pts, 6, 0.080, 0.042, 0.023, mat_stud)
		_studs(root, b_pts, 6, 0.080, 0.042, 0.023, mat_stud)

	# a blooming body flowers at the ends of its arms too
	if crown == "bloom":
		_flower(root, a_pts[6] + Vector3(0.0, -0.02, 0.0), Basis(Vector3.RIGHT, deg_to_rad(158.0)), 0.078, 5, mat_white, mat_black, mat_tent)
		_flower(root, b_pts[6], Basis(Vector3.UP, deg_to_rad(40.0)) * Basis(Vector3.RIGHT, deg_to_rad(-62.0)), 0.082, 5, mat_white, mat_black, mat_tent)

	_settle(root)


# ----------------------------------------------------------------------------------------------
# the grown body — the same joints and the same radii, handed to a field instead of a hand
# ----------------------------------------------------------------------------------------------

## The field for flesh = "fused". Under 40 parts, because DreamIso samples a grid: 3 for
## the trunk, 6 for the legs, 16 for the four tentacles, 3-10 for the crown, and one
## SUBTRACTED capsule through the chest — the hole nothing filled.
static func _fused_parts(crown: String, hip: Vector3, shoulder: Vector3, body_rr: float,
		leg_lift: float, stride: float, neck_len: float, neck_bow: float, neck_sway: float,
		a_pts: Array[Vector3], b_pts: Array[Vector3], c_pts: Array[Vector3],
		d_pts: Array[Vector3]) -> Array:
	var parts: Array = []
	# trunk: hips, a tapering torso, a shoulder mass — one solid, no seam anywhere
	parts.append(Iso.sphere(hip, body_rr * 0.96))
	parts.append(Iso.capsule(hip, shoulder, body_rr * 0.86, 0.112))
	parts.append(Iso.sphere(shoulder, 0.125))
	# legs: thigh and shin swell into the hips instead of meeting them
	var leg_x: Array[float] = [-1.0, 1.0]
	for li in range(2):
		var lx: float = leg_x[li]
		var fwd: float = -1.0 if li == 0 else 1.0
		var kz: float = stride * 0.45 if li == 0 else stride * 0.35
		var hj: Vector3 = Vector3(lx * 0.09, 0.47 * leg_lift, 0.0)
		var knee: Vector3 = Vector3(lx * 0.10, 0.26 * leg_lift, fwd * kz)
		var foot: Vector3 = Vector3(lx * 0.11, 0.062, fwd * stride * 0.5)
		parts.append(Iso.capsule(hj, knee, 0.090, 0.076))
		parts.append(Iso.capsule(knee, foot, 0.076, 0.060))
		parts.append(Iso.box(foot, Vector3(0.070, 0.028, 0.100), 0.026))
	# the tentacles leave the body as thickened webs, not as strings of beads
	_field_chain(parts, a_pts, 0.080, 0.042, 4)
	_field_chain(parts, b_pts, 0.080, 0.042, 4)
	_field_chain(parts, c_pts, 0.070, 0.040, 4)
	_field_chain(parts, d_pts, 0.082, 0.048, 4)
	# the crown grows out of the shoulders instead of standing on them
	var n0: Vector3 = shoulder + Vector3(0.0, 0.05, -0.01)
	if crown == "hydra":
		for hi in range(3):
			var hp: Array[Vector3] = _hydra_pts(shoulder, hi, neck_sway, neck_len, neck_bow)
			_field_chain(parts, hp, 0.070, 0.050, 2)
			parts.append(Iso.sphere(_hydra_head(hp, hi, neck_sway), 0.064))
	elif crown == "coral":
		var tp: Array[Vector3] = _coral_pts(n0, neck_sway, neck_len, neck_bow)
		_field_chain(parts, tp, 0.084, 0.062, 2)
		for bi in range(4):
			var bp: Array[Vector3] = _coral_branch(tp[2], bi, neck_len, neck_bow)
			_field_chain(parts, bp, 0.055, 0.038, 2)
	elif crown == "bloom":
		var fp: Array[Vector3] = _swan_pts(n0, neck_sway, neck_len, neck_bow)
		_field_chain(parts, fp, 0.078, 0.054, 3)
	else:
		var np: Array[Vector3] = _swan_pts(n0, neck_sway, neck_len, neck_bow)
		_field_chain(parts, np, 0.078, 0.054, 3)
		parts.append(Iso.sphere(np[3] + Vector3(neck_sway * 0.1, 0.055, -0.02), 0.082))
	# THE HOLE: subtracted, so it is a place the field never crossed zero
	var pierce: Vector3 = hip.lerp(shoulder, 0.62)
	parts.append(Iso.cut(Iso.capsule(pierce + Vector3(0.0, 0.0, 0.22),
		pierce + Vector3(0.0, 0.0, -0.22), 0.046)))
	return parts


## A spline turned into `segs` tapering capsules, the field's version of a bead chain.
static func _field_chain(parts: Array, pts: Array[Vector3], r0: float, r1: float, segs: int) -> void:
	var prev: Vector3 = _spline(pts, 0.0)
	for i in range(1, segs + 1):
		var t: float = float(i) / float(segs)
		var ra: float = lerpf(r0, r1, float(i - 1) / float(segs))
		var rb: float = lerpf(r0, r1, t)
		var p: Vector3 = _spline(pts, t)
		parts.append(Iso.capsule(prev, p, ra, rb))
		prev = p


## Pearls pressed along a curve, sitting proud of a limb of radius r0 -> r1.
static func _studs(root: Node3D, pts: Array[Vector3], n: int, r0: float, r1: float, sr: float, mat: Material) -> void:
	for i in range(n):
		var t: float = 0.12 + 0.76 * float(i) / float(maxi(n - 1, 1))
		var p: Vector3 = _spline(pts, t)
		var tg: Vector3 = _spline(pts, minf(t + 0.01, 1.0)) - _spline(pts, maxf(t - 0.01, 0.0))
		if tg.length() < 0.0001:
			tg = Vector3.UP
		var rr: float = lerpf(r0, r1, t)
		var q: Vector3 = p + _basis_y(tg) * Vector3(0.0, 0.0, rr * 0.82)
		q.y = maxf(q.y, sr)
		_sphere(root, q, sr, mat)


# ----------------------------------------------------------------------------------------------
# the crown's curves — written once, so the field and the bead chains cannot drift apart
# ----------------------------------------------------------------------------------------------

static func _swan_pts(n0: Vector3, sway: float, ln: float, bow: float) -> Array[Vector3]:
	var out: Array[Vector3] = [
		n0,
		n0 + Vector3(sway * 0.3, 0.10, -bow * 0.7),
		n0 + Vector3(sway * 0.8, 0.22, -bow),
		n0 + Vector3(sway, ln, -bow * 0.35),
	]
	return out


static func _hydra_sway(hi: int, sway: float) -> float:
	return sway * 0.4 + (float(hi) - 1.0) * 0.26


static func _hydra_pts(shoulder: Vector3, hi: int, sway: float, ln: float, bow: float) -> Array[Vector3]:
	var hx: float = float(hi) - 1.0
	var nb: Vector3 = shoulder + Vector3(hx * 0.085, 0.045, -0.012 + absf(hx) * 0.035)
	var hlen: float = ln * 0.66
	var hsway: float = _hydra_sway(hi, sway)
	var hbow: float = bow * 1.0 if hi == 1 else bow * 0.62
	var out: Array[Vector3] = [
		nb,
		nb + Vector3(hsway * 0.30, hlen * 0.30, -hbow * 0.70),
		nb + Vector3(hsway * 0.80, hlen * 0.66, -hbow),
		nb + Vector3(hsway, hlen, -hbow * 0.35),
	]
	return out


static func _hydra_head(pts: Array[Vector3], hi: int, sway: float) -> Vector3:
	return pts[3] + Vector3(_hydra_sway(hi, sway) * 0.10, 0.046, -0.018)


static func _coral_pts(n0: Vector3, sway: float, ln: float, bow: float) -> Array[Vector3]:
	var out: Array[Vector3] = [
		n0,
		n0 + Vector3(sway * 0.30, ln * 0.30, -bow * 0.60),
		n0 + Vector3(sway * 0.60, ln * 0.55, -bow * 0.80),
	]
	return out


static func _coral_angle(bi: int) -> float:
	return float(bi) * TAU / 4.0 + 0.6


static func _coral_dir(bi: int) -> Vector3:
	var a: float = _coral_angle(bi)
	return Vector3(cos(a) * 0.62, 1.0, sin(a) * 0.62).normalized()


static func _coral_branch(fork: Vector3, bi: int, ln: float, bow: float) -> Array[Vector3]:
	var d: Vector3 = _coral_dir(bi)
	var bl: float = ln * 0.92 if (bi % 2) == 0 else ln * 0.66
	var out: Array[Vector3] = [
		fork,
		fork + d * (bl * 0.5) + Vector3(0.0, 0.0, -bow * 0.20),
		fork + d * bl,
	]
	return out


# ----------------------------------------------------------------------------------------------
# fit, centre, settle — measured, never assumed: no variant may be wider than 1.20 m or
# taller than 1.68 m, and nothing may hang under the plinth top.
# ----------------------------------------------------------------------------------------------

static func _settle(root: Node3D) -> void:
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
	var shift: Vector3 = Vector3(-centre.x, 0.0, -centre.z)
	for ch2 in root.get_children():
		if not (ch2 is MeshInstance3D):
			continue
		var cm2: MeshInstance3D = ch2
		cm2.transform = Transform3D(cm2.transform.basis, cm2.transform.origin + shift)
	box = _union_aabb(root)
	if box.position.y < 0.0:
		var lift: float = -box.position.y
		for ch3 in root.get_children():
			if not (ch3 is MeshInstance3D):
				continue
			var cm3: MeshInstance3D = ch3
			var tf3: Transform3D = cm3.transform
			cm3.transform = Transform3D(tf3.basis, tf3.origin + Vector3(0.0, lift, 0.0))


static func _union_aabb(root: Node3D) -> AABB:
	var box: AABB = AABB()
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


# ----------------------------------------------------------------------------------------------
# head, crest, flower — the parts the "crown" axis deals out
# ----------------------------------------------------------------------------------------------

## The beaked, two-eyed head. hr = 0.08 is the head this family has always worn; every
## offset scales with it, so a hydra's smaller heads keep the same face. `skull` is false
## on a grown body, where the skull is already in the field and only the face is added.
static func _head(root: Node3D, head: Vector3, hb: Basis, hr: float, mat_skin: Material, mat_dark: Material, mat_eye: Material, mat_pupil: Material, skull: bool = true) -> void:
	var hs: float = hr / 0.08
	if skull:
		_mesh_basis(root, _sphere_mesh(hr), mat_skin, head, hb * Basis.from_scale(Vector3(0.95, 0.9, 1.15)))
	var beak: PrismMesh = PrismMesh.new()
	beak.size = Vector3(0.07, 0.10, 0.034) * hs
	_mesh_basis(root, beak, mat_dark, head + hb * (Vector3(0.0, -0.012, -0.10) * hs), hb * Basis(Vector3.RIGHT, -PI * 0.5))
	for ex: float in [-1.0, 1.0]:
		var ec: Vector3 = head + hb * (Vector3(ex * 0.058, 0.022, -0.042) * hs)
		_sphere(root, ec, 0.024 * hs, mat_eye)
		_sphere(root, ec + hb * (Vector3(ex * 0.011, 0.002, -0.015) * hs), 0.012 * hs, mat_pupil)


static func _crest(root: Node3D, head: Vector3, hb: Basis, crest_n: int, hs: float, mat: Material) -> void:
	var head_right: Vector3 = hb * Vector3.RIGHT
	for ci in range(crest_n):
		var cang: float = deg_to_rad(-30.0 + 100.0 * float(ci) / float(maxi(crest_n - 1, 1)))
		var cd: Vector3 = hb * Vector3(0.0, cos(cang), sin(cang))
		var cfin: PrismMesh = PrismMesh.new()
		var cfl: float = (0.07 - 0.012 * absf(float(ci) - float(crest_n - 1) * 0.5)) * hs
		cfin.size = Vector3(0.01 * hs, cfl, 0.03 * hs)
		_mesh_basis(root, cfin, mat, head + cd * (0.075 * hs), _basis_xy(head_right, cd))


## A daisy: a flattened core, petals as thin scaled spheres splaying off the core's plane,
## and — on the big blooms only — five stamens with bead tips.
static func _flower(root: Node3D, pos: Vector3, b: Basis, r: float, petals: int, mat_petal: Material, mat_core: Material, mat_stem: Material) -> void:
	_mesh_basis(root, _sphere_mesh(r * 0.36), mat_core, pos, b * Basis.from_scale(Vector3(1.0, 0.5, 1.0)))
	var up_axis: Vector3 = b * Vector3.UP
	for fpi in range(petals):
		var pa: float = float(fpi) * TAU / float(petals)
		var pdir: Vector3 = b * Vector3(cos(pa), 0.42, sin(pa)).normalized()
		var pcross: Vector3 = up_axis.cross(pdir)
		if pcross.length() < 0.001:
			pcross = b * Vector3.RIGHT
		_mesh_basis(root, _sphere_mesh(r * 0.50), mat_petal, pos + pdir * (r * 0.72), _basis_xy(pcross, pdir) * Basis.from_scale(Vector3(0.62, 1.55, 0.20)))
	if petals < 7:
		return
	for sti in range(5):
		var sa: float = float(sti) * TAU / 5.0 + 0.3
		var sd: Vector3 = b * Vector3(cos(sa) * 0.35, 1.0, sin(sa) * 0.35).normalized()
		var stem: CylinderMesh = CylinderMesh.new()
		stem.top_radius = 0.006
		stem.bottom_radius = 0.008
		stem.height = r * 0.62
		stem.radial_segments = 8
		stem.rings = 1
		_mesh_basis(root, stem, mat_stem, pos + sd * (r * 0.34), _basis_y(sd))
		_sphere(root, pos + sd * (r * 0.70), r * 0.11, mat_core)


# ----------------------------------------------------------------------------------------------
# skins — the family's three coats, now printed in the palette instead of in greys
# ----------------------------------------------------------------------------------------------

static func _pale(c: Color) -> Color:
	return c.lerp(Color(0.98, 0.96, 0.94), 0.80)


static func _tex_kind(kind: int, rng: RandomNumberGenerator, dark: Color, light: Color) -> ImageTexture:
	if kind == 0:
		return _tex_stripes(rng, dark, light)
	if kind == 1:
		return _tex_dots(rng, dark, light)
	return _tex_cells(rng, dark, light)


## Irregular zebra bands: horizontal stripes whose edges wobble along u and whose
## width swells and thins, all periodic so the tile is seamless.
static func _tex_stripes(rng: RandomNumberGenerator, dark: Color, light: Color) -> ImageTexture:
	var w: int = 128
	var h: int = 128
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
	var bands: float = float(rng.randi_range(5, 8))
	var wob: float = rng.randf_range(1.5, 3.5)
	var wob2: float = float(rng.randi_range(1, 2))
	var phase: float = rng.randf_range(0.0, TAU)
	var duty: float = rng.randf_range(-0.15, 0.25)
	var swell: float = rng.randf_range(0.15, 0.35)
	for y in range(h):
		for x in range(w):
			var u: float = float(x) / float(w)
			var v: float = float(y) / float(h)
			var wave: float = sin(u * TAU + phase) * 0.35 + sin(u * TAU * 2.0 + v * TAU * wob2) * 0.2
			var s: float = sin(v * TAU * bands + wave * wob)
			var thr: float = duty + swell * sin(u * TAU * 2.0 + phase * 0.5)
			var c: Color = light if s > thr else dark
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## A fine dot grid, 16 or 32 dots per tile, sometimes staggered, sometimes inverted.
static func _tex_dots(rng: RandomNumberGenerator, dark: Color, light: Color) -> ImageTexture:
	var w: int = 256
	var h: int = 256
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
	var cells: int = 16 if rng.randf() < 0.5 else 32
	var cell: float = float(w) / float(cells)
	var rad: float = cell * rng.randf_range(0.22, 0.34)
	var stagger: bool = rng.randf() < 0.6
	var invert: bool = rng.randf() < 0.3
	var ink_c: Color = light if invert else dark
	var paper: Color = dark if invert else light
	for y in range(h):
		for x in range(w):
			var fx: float = float(x) + 0.5
			var fy: float = float(y) + 0.5
			var row: int = int(floor(fy / cell))
			if stagger and (row % 2) == 1:
				fx += cell * 0.5
			var cx: float = fposmod(fx, cell) - cell * 0.5
			var cy: float = fposmod(fy, cell) - cell * 0.5
			var d: float = sqrt(cx * cx + cy * cy)
			var c: Color = ink_c if d < rad else paper
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Voronoi cells with light borders on dark fill — the giraffe / honeycomb skin.
## Distances wrap toroidally so the tile is seamless.
static func _tex_cells(rng: RandomNumberGenerator, dark: Color, light: Color) -> ImageTexture:
	var w: int = 96
	var h: int = 96
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
	var n: int = rng.randi_range(18, 28)
	var seeds: Array[Vector2] = []
	for i in range(n):
		seeds.append(Vector2(rng.randf() * float(w), rng.randf() * float(h)))
	var border: float = rng.randf_range(2.0, 3.4)
	var fw: float = float(w)
	var fh: float = float(h)
	for y in range(h):
		for x in range(w):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var d1: float = 1.0e9
			var d2: float = 1.0e9
			for s: Vector2 in seeds:
				var dx: float = absf(px - s.x)
				var dy: float = absf(py - s.y)
				dx = minf(dx, fw - dx)
				dy = minf(dy, fh - dy)
				var d: float = sqrt(dx * dx + dy * dy)
				if d < d1:
					d2 = d1
					d1 = d
				elif d < d2:
					d2 = d
			var c: Color = light if (d2 - d1) < border else dark
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ----------------------------------------------------------------------------------------------
# materials — every one of them comes out of DreamSkin
# ----------------------------------------------------------------------------------------------

## A DreamSkin finish wearing one of this family's painted coats. The finish keeps its
## clearcoat, metal, rim and emission; the coat replaces its albedo — and its emission
## texture too, where it had one, so an oil slick or a foil glows in the pattern's own
## colours instead of a sweep it can no longer see. `tri` is triplanar, which is the only
## way to map a marched mesh: an isosurface carries no UVs at all.
static func _gloss(finish: String, base: Color, tex: Texture2D, uvs: Vector3, tri: bool, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, base, rng)
	if tex == null:
		return m
	m.albedo_texture = tex
	m.albedo_color = Color(1.0, 1.0, 1.0)
	if m.emission_enabled and m.emission_texture != null:
		m.emission_texture = tex
	if finish == "chrome":
		# the coat has replaced the brushed streaks, so give the mirror a little more
		# of its own light — a metal with nothing to reflect photographs black
		m.emission_energy_multiplier = 0.22
	m.uv1_triplanar = tri
	m.uv1_scale = uvs
	return m


# ----------------------------------------------------------------------------------------------
# curves and bead chains
# ----------------------------------------------------------------------------------------------

## Catmull-Rom through pts, t in [0, 1] over the whole chain, ends clamped.
static func _spline(pts: Array[Vector3], t: float) -> Vector3:
	var n: int = pts.size()
	if n == 0:
		return Vector3.ZERO
	if n == 1:
		return pts[0]
	var seg_count: int = n - 1
	var ft: float = clampf(t, 0.0, 0.9999) * float(seg_count)
	var i: int = int(floor(ft))
	var u: float = ft - float(i)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[mini(i + 1, n - 1)]
	var p3: Vector3 = pts[mini(i + 2, n - 1)]
	var a: Vector3 = p1 * 2.0
	var b: Vector3 = (p2 - p0) * u
	var c: Vector3 = (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * (u * u)
	var d: Vector3 = (p1 * 3.0 - p0 - p2 * 3.0 + p3) * (u * u * u)
	return (a + b + c + d) * 0.5


## Walks the spline and returns the t of each bead: a bead is dropped whenever the arc
## since the last one reaches k times the bead's own radius (radius shrinks r0 -> r1).
static func _chain_ts(pts: Array[Vector3], r0: float, r1: float, k: float) -> Array[float]:
	var ts: Array[float] = []
	var steps: int = 720
	var last: Vector3 = _spline(pts, 0.0)
	var acc: float = 0.0
	ts.append(0.0)
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector3 = _spline(pts, t)
		acc += p.distance_to(last)
		last = p
		var r: float = lerpf(r0, r1, t)
		if acc >= r * k:
			ts.append(t)
			acc = 0.0
	return ts


## The bead chain, unless the body was GROWN — in which case this curve is already in the
## field (see _fused_parts) and drawing it again would put beads inside the flesh.
static func _bead_chain_g(root: Node3D, grown: bool, pts: Array[Vector3], r0: float, r1: float, mat: Material, k: float, max_beads: int, mode: String, rk: float, squash: Vector3, jit: float, rng: RandomNumberGenerator) -> void:
	if grown:
		return
	_bead_chain_m(root, pts, r0, r1, mat, k, max_beads, mode, rk, squash, jit, rng)


## A chain wearing whatever the "flesh" axis has decided a bead is:
##   bead  — the sphere this family has always used (rk 1, no squash, no jitter: identical)
##   melt  — the same spheres, squashed into sagging discs
##   ring  — a vertebra: a TorusMesh threaded on the spline, axis along the tangent
##   grain — smaller beads shaken off their own curve, more the further along they are
##   puff  — far bigger beads, so far fewer of them fit
## If the chain would need more than max_beads, the spacing is widened until it fits, so
## the mesh budget holds for any seed. No bead sinks below the floor.
static func _bead_chain_m(root: Node3D, pts: Array[Vector3], r0: float, r1: float, mat: Material, k: float, max_beads: int, mode: String, rk: float, squash: Vector3, jit: float, rng: RandomNumberGenerator) -> void:
	var a0: float = r0 * rk
	var a1: float = r1 * rk
	var kk: float = k
	var ts: Array[float] = _chain_ts(pts, a0, a1, kk)
	var guard: int = 0
	while ts.size() > max_beads and guard < 6:
		kk *= float(ts.size()) / float(max_beads) * 1.06
		ts = _chain_ts(pts, a0, a1, kk)
		guard += 1
	var plain: bool = squash.is_equal_approx(Vector3.ONE)
	for t: float in ts:
		var r: float = lerpf(a0, a1, t)
		var p: Vector3 = _spline(pts, t)
		if jit > 0.0:
			p += _rand_dir(rng) * (r * 3.2 * jit * (0.35 + t) * rng.randf())
		if mode == "ring":
			var eps: float = 0.004
			var tg: Vector3 = _spline(pts, minf(t + eps, 1.0)) - _spline(pts, maxf(t - eps, 0.0))
			if tg.length() < 0.0001:
				tg = Vector3.UP
			var rp: Vector3 = p
			rp.y = maxf(rp.y, r)
			var vert: TorusMesh = TorusMesh.new()
			vert.inner_radius = maxf(r * 0.52, 0.002)
			vert.outer_radius = r * 1.18
			vert.rings = 20
			vert.ring_segments = 8
			_mesh_basis(root, vert, mat, rp, _basis_y(tg))
			continue
		p.y = maxf(p.y, r * maxf(squash.y, 0.05))
		if plain:
			_sphere(root, p, r, mat)
		else:
			_mesh_basis(root, _sphere_mesh(r), mat, p, Basis.from_scale(squash))


# ----------------------------------------------------------------------------------------------
# primitives and placement
# ----------------------------------------------------------------------------------------------

static func _sphere_mesh(r: float) -> SphereMesh:
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	return sm


static func _sphere(root: Node3D, pos: Vector3, r: float, mat: Material) -> MeshInstance3D:
	return _mesh(root, _sphere_mesh(r), mat, pos, Vector3.ZERO)


static func _capsule_between(root: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var cm: CapsuleMesh = CapsuleMesh.new()
	cm.radius = r
	cm.height = a.distance_to(b) + r * 2.0
	cm.radial_segments = 24
	cm.rings = 8
	return _mesh_basis(root, cm, mat, (a + b) * 0.5, _basis_y(b - a))


## A tapered tube from a to b: radius ra at the a end, rb at the b end. The drips and
## sagging limbs of the melted body are made of these.
static func _taper(root: Node3D, a: Vector3, b: Vector3, ra: float, rb: float, mat: Material) -> MeshInstance3D:
	var cm: CylinderMesh = CylinderMesh.new()
	cm.bottom_radius = maxf(ra, 0.001)
	cm.top_radius = maxf(rb, 0.0)
	cm.height = maxf(a.distance_to(b), 0.002)
	cm.radial_segments = 20
	cm.rings = 2
	return _mesh_basis(root, cm, mat, (a + b) * 0.5, _basis_y(b - a))


## A ring of radius r and thickness tube, its hole along the basis' own y.
static func _hoop(root: Node3D, pos: Vector3, b: Basis, r: float, tube: float, mat: Material) -> MeshInstance3D:
	var t: TorusMesh = TorusMesh.new()
	t.inner_radius = maxf(r - tube, 0.002)
	t.outer_radius = r + tube
	t.rings = 32
	t.ring_segments = 8
	return _mesh_basis(root, t, mat, pos, b)


static func _rand_dir(rng: RandomNumberGenerator) -> Vector3:
	var v: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	if v.length() < 0.001:
		return Vector3.UP
	return v.normalized()


## A right-handed basis whose y axis points along dir; x and z are any perpendicular pair.
static func _basis_y(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var helper: Vector3 = Vector3.UP if absf(d.y) < 0.98 else Vector3.RIGHT
	var xa: Vector3 = helper.cross(d).normalized()
	var za: Vector3 = xa.cross(d).normalized()
	return Basis(xa, d, za)


## A right-handed basis from a wanted x axis and a wanted y axis (x is re-squared to y).
static func _basis_xy(xa: Vector3, ya: Vector3) -> Basis:
	var ay: Vector3 = ya.normalized()
	var az: Vector3 = xa.normalized().cross(ay).normalized()
	var ax: Vector3 = ay.cross(az).normalized()
	return Basis(ax, ay, az)


static func _mesh(root: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	root.add_child(mi)
	return mi


static func _mesh_basis(root: Node3D, mesh: Mesh, mat: Material, pos: Vector3, b: Basis) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(b, pos)
	root.add_child(mi)
	return mi
