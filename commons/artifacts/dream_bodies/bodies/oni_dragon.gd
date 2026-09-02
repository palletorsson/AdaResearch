extends RefCounted

## dream_bodies / oni_dragon — one standing kabuki oni-dragon, arm punched forward.
##
## Reference: scratchpad/refs/samurai_dragon.png (2048x536 panorama) — a crowd of
## humanoid dragon-demons cast as glossy figures against a black night and thin
## trees: one entirely matte black under a fine pebble skin, wearing silver studs
## down the chest, a bead chain over the shoulder and a wrist cuff, its long snout
## open on a pink mouth with fangs and one amber eye, one arm punched straight out
## across the whole frame; a mint-green one beside it with a pale pebbled belly,
## heavy scowling brows, long pointed ears and a shouting mouth; a white one with
## silver filigree; a pale blue and an orchid body behind, and pink scaled dragon
## coils filling the back of the group.
##
## Reproduced, and how:
##   1. The stance and the gesture — legs planted wide with one foot advanced, the
##      torso built as a 13..17 SphereMesh spine that yaws 12..20 deg toward the
##      punching side so the thrust shoulder leads, the hips shifted the other way.
##      One arm reaches straight out to a closed fist; the other hangs heavy and
##      slightly back. Side, lean, twist and reach all come from the seed.
##   2. Pebble skin — a 160x160 ImageTexture painted in code: a staggered jittered
##      lattice where every cell is shaded as a lit dome with a dark groove between,
##      applied with WORLD triplanar so the pebble field runs unbroken across the
##      whole chain of spheres and capsules instead of restarting on each mesh.
##      A second, coarser bake covers the belly.
##   3. The paler belly — a chain of 6 belly-coloured ellipsoids hung on the front
##      of the spine, two pectoral domes, and a scattered grid of 10 pale lumps
##      over the abdomen, the way the mint figure's chest plates read.
##   4. The oni head — an egg skull with a cranial bulge, a heavy brow slab tilted
##      down over the eyes and two brow ridges angled into a scowl, muzzle and
##      lower jaw as SurfaceTool tapered boxes with the jaw dropped 24..38 deg on
##      a hinge, a dark mouth ellipsoid and tongue in the gap, 4..8 cone fangs, and
##      slit-pupil eyes in one of five eye colours chosen by seed.
##   5. Ears, horn fins and crest — two long PrismMesh ears swept out, up and back
##      as flat fins; 2..4 thin cones rising off the crown and raked backward; a
##      midline row of 4 small crest spikes running down the back of the skull.
##   6. Fin crests — rows of thin PrismMesh blades along both forearms and both
##      calves, each row swelling to a bell in the middle, standing off the limb
##      outward and back.
##   7. Silver — 3..6 metallic studs down the sternum, one on each deltoid, a
##      shoulder chain of 9 tiny beads sagging across the chest, and a TorusMesh
##      wrist cuff with its own stud on the punching arm. The white scheme adds
##      two filigree curls of 7 beads each over chest and shoulder.
##   8. A short tapering tail of 6..9 segments sweeping back and down as a
##      counterweight to the punch, with three small spikes along its ridge.
##
## Given up: the crowd (this is one body, not the group), the pink scaled dragon
## coils behind them, the trees and the black ground, the spear, the fabric straps
## and buckles round the wrist, the true moulded relief of the white one's filigree
## (beads stand in for engraved line), and the ridged pink interior of the mouth.

const TEX_SIZE: int = 160

# scheme: [body upper, body lower, belly, plate, horn/claw, mouth]
const SCHEMES: Array = [
	["#8FDDA4", "#5FB981", "#E9F6E3", "#CBEBCC", "#EFF6EA", "#8E4C63"],
	["#26262B", "#101014", "#3D3D44", "#2C2C32", "#DCDCE0", "#7C3D52"],
	["#8FC3D9", "#679FBF", "#E1F0F5", "#BEE0EA", "#EDF4F7", "#8A4A62"],
	["#E2A6DE", "#C57CC2", "#F7E4F4", "#F0CBEC", "#FAEFF8", "#93425F"],
	["#F3F0EA", "#DBD5CB", "#FBF9F5", "#EDE9E2", "#C7C3BB", "#A2707F"],
]
const EYE_COLS: Array = ["#F2C230", "#EFE04A", "#5FD8B4", "#EA6E9C", "#7BC8F0"]
const SILVER: String = "#C6CAD0"


static func describe() -> String:
	return "A standing oni-dragon in a wide stance with one arm punched forward, pebble-skinned with a pale belly, heavy brow, open fanged jaw, pointed ears, horn fins, fin crests down its limbs and silver studs."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- palette -------------------------------------------------------------
	var si: int = rng.randi_range(0, SCHEMES.size() - 1)
	var sc: Array = SCHEMES[si]
	var col_up: Color = _c(sc, 0)
	var col_low: Color = _c(sc, 1)
	var col_belly: Color = _c(sc, 2)
	var col_plate: Color = _c(sc, 3)
	var col_horn: Color = _c(sc, 4)
	var col_mouth: Color = _c(sc, 5)
	var col_eye: Color = _c(EYE_COLS, rng.randi_range(0, EYE_COLS.size() - 1))
	var filigree: bool = si == 4

	var skin_tex: ImageTexture = _pebble_texture(rng, 14, 16, 0.14, 0.52, 0.60)
	var plate_tex: ImageTexture = _pebble_texture(rng, 7, 8, 0.10, 0.66, 0.44)

	var mat_belly: StandardMaterial3D = _skin(col_belly, plate_tex, 0.52, 3.0)
	var mat_plate: StandardMaterial3D = _skin(col_plate, plate_tex, 0.50, 3.2)
	var mat_horn: StandardMaterial3D = _skin(col_horn, null, 0.34, 1.0)
	mat_horn.clearcoat_enabled = true
	mat_horn.clearcoat = 0.5
	var mat_mouth: StandardMaterial3D = _skin(col_mouth, null, 0.42, 1.0)
	var mat_tongue: StandardMaterial3D = _skin(col_mouth.lightened(0.18), null, 0.38, 1.0)
	var mat_dark: StandardMaterial3D = _skin(Color("#17141A"), null, 0.30, 1.0)
	var mat_silver: StandardMaterial3D = _skin(Color(SILVER), null, 0.18, 1.0)
	mat_silver.metallic = 1.0
	mat_silver.metallic_specular = 0.85
	var mat_eye: StandardMaterial3D = _skin(col_eye, null, 0.12, 1.0)
	mat_eye.emission_enabled = true
	mat_eye.emission = col_eye
	mat_eye.emission_energy_multiplier = 0.30
	mat_eye.clearcoat_enabled = true
	mat_eye.clearcoat = 0.85

	# --- individual ----------------------------------------------------------
	var arm_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var girth: float = rng.randf_range(0.94, 1.07)
	var stance: float = rng.randf_range(0.205, 0.255)
	var lean: float = rng.randf_range(0.020, 0.070)
	var twist: float = deg_to_rad(rng.randf_range(12.0, 20.0)) * arm_side
	var reach: float = rng.randf_range(0.235, 0.275)
	var jaw_open: float = deg_to_rad(rng.randf_range(24.0, 38.0))
	var head_yaw: float = twist * 0.45 + deg_to_rad(rng.randf_range(-7.0, 7.0))
	var head_pitch: float = deg_to_rad(rng.randf_range(-6.0, 5.0))
	var n_spine: int = rng.randi_range(13, 17)
	var n_horn: int = rng.randi_range(2, 4)
	var n_low_fangs: int = rng.randi_range(0, 2)
	var n_arm_blades: int = rng.randi_range(4, 6)
	var n_calf_blades: int = rng.randi_range(3, 5)
	var n_studs: int = rng.randi_range(3, 6)
	var n_tail: int = rng.randi_range(6, 9)
	var tail_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var target_h: float = rng.randf_range(1.565, 1.660)

	# --- spine ---------------------------------------------------------------
	var y_pel: float = 0.835
	var y_neck: float = 1.330
	var pts: Array = []
	var frames: Array = []
	var radii: Array = []
	var widths: Array = []
	var depths: Array = []
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var s: float = t * t * (3.0 - 2.0 * t)
		var py: float = lerpf(y_pel, y_neck, t)
		var pz: float = lerpf(0.035, -lean, s) + 0.030 * sin(PI * t)
		var px: float = -arm_side * 0.030 * (1.0 - s) + arm_side * 0.014 * s
		pts.append(Vector3(px, py, pz))
		frames.append(Basis(Vector3.UP, twist * s))
		radii.append(_keyed([0.150, 0.133, 0.148, 0.176, 0.126], t) * girth)
		widths.append(_keyed([1.14, 1.02, 1.10, 1.24, 1.02], t))
		depths.append(_keyed([0.88, 0.82, 0.84, 0.87, 0.80], t))

	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var mat_body: StandardMaterial3D = _skin(col_low.lerp(col_up, clampf(t * 1.15, 0.0, 1.0)), skin_tex, 0.55, 4.0)
		_ellipsoid(root, pts[i], frames[i], radii[i], widths[i], 1.0, depths[i], mat_body)

	var i_chest: int = n_spine - 2
	var p_chest: Vector3 = pts[i_chest]
	var b_chest: Basis = frames[i_chest]
	var r_chest: float = radii[i_chest]

	# --- pale belly, pectorals, abdominal lumps ------------------------------
	for i in range(6):
		var t: float = lerpf(0.06, 0.72, float(i) / 5.0)
		var idx: int = int(floor(t * float(n_spine - 1)))
		var bf: Basis = frames[idx]
		var front: Vector3 = bf * Vector3(0.0, 0.0, -1.0)
		var rb: float = radii[idx] * 0.70
		_ellipsoid(root, pts[idx] + front * (radii[idx] * depths[idx] * 0.46), bf, rb, 0.95, 1.05, 0.70, mat_belly)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var pec: Vector3 = p_chest + b_chest * Vector3(sd * r_chest * 0.52, 0.012, -r_chest * 0.74)
		_ellipsoid(root, pec, b_chest, 0.088 * girth, 1.12, 0.86, 0.72, mat_plate)
	for k in range(10):
		var kr: int = int(floor(float(k) / 3.0))
		var kc: int = k % 3
		var tl: float = lerpf(0.58, 0.16, float(kr) / 3.0)
		var idx: int = int(floor(tl * float(n_spine - 1)))
		var bf: Basis = frames[idx]
		var front: Vector3 = bf * Vector3(0.0, 0.0, -1.0)
		var offx: float = (float(kc) - 1.0) * radii[idx] * 0.46
		var lump: float = lerpf(0.038, 0.024, float(kr) / 3.0) * girth
		var pos: Vector3 = pts[idx] + front * (radii[idx] * depths[idx] * 0.72) + bf * Vector3(offx, 0.0, 0.0)
		_ellipsoid(root, pos, bf, lump, 1.25, 0.85, 0.55, mat_plate)

	# --- legs ----------------------------------------------------------------
	var mat_leg: StandardMaterial3D = _skin(col_low, skin_tex, 0.55, 4.0)
	var mat_thigh: StandardMaterial3D = _skin(col_low.lerp(col_up, 0.35), skin_tex, 0.55, 4.0)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var fwd: float = 0.070 if sd == -arm_side else -0.055
		var hip := Vector3(sd * 0.118, 0.860, 0.010)
		var knee := Vector3(sd * (stance * 0.88), 0.495, -0.020 + fwd * 0.55)
		var ankle := Vector3(sd * stance, 0.128, 0.010 + fwd)
		_ellipsoid(root, hip, Basis(), 0.108 * girth, 1.0, 0.94, 0.94, mat_thigh)
		_limb(root, hip, knee, 0.095 * girth, mat_thigh)
		_ellipsoid(root, knee, Basis(), 0.072 * girth, 1.0, 0.92, 1.0, mat_leg)
		_limb(root, knee, ankle, 0.068 * girth, mat_leg)
		var foot := Vector3(ankle.x + sd * 0.024, 0.050, ankle.z - 0.052)
		_ellipsoid(root, foot, Basis(Vector3.UP, sd * 0.24), 0.086, 1.0, 0.58, 1.55, mat_leg)
		for c in range(3):
			var ang: float = (float(c) - 1.0) * 0.46
			var td: Vector3 = Vector3(sin(ang) * 0.75 + sd * 0.14, -0.12, -cos(ang)).normalized()
			var toe: Vector3 = foot + td * 0.098
			_ellipsoid(root, toe, Basis(), 0.033, 1.0, 0.80, 1.0, mat_leg)
			_cone(root, toe + td * 0.020 + Vector3(0.0, -0.004, 0.0), (td + Vector3(0.0, -0.30, 0.0)).normalized(), 0.048, 0.014, mat_horn)
		# calf fin crest
		var leg_dir: Vector3 = (ankle - knee).normalized()
		var fin_dir: Vector3 = _perp(leg_dir, Vector3(sd * 0.55, 0.10, 0.86))
		for b in range(n_calf_blades):
			var fb: float = float(b) / float(n_calf_blades - 1)
			var bell: float = sin(PI * clampf(0.18 + fb * 0.72, 0.0, 1.0))
			var at: Vector3 = knee.lerp(ankle, lerpf(0.16, 0.86, fb))
			_blade(root, at + fin_dir * 0.038, _frame(fin_dir, leg_dir), 0.052, lerpf(0.048, 0.086, bell), 0.013, mat_horn)

	# --- shoulders and arms ---------------------------------------------------
	var mat_arm: StandardMaterial3D = _skin(col_up, skin_tex, 0.55, 4.0)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var punching: bool = sd == arm_side
		var shoulder: Vector3 = p_chest + b_chest * Vector3(sd * 0.255 * girth, 0.028, 0.0)
		_ellipsoid(root, shoulder, b_chest, 0.118 * girth, 1.0, 0.96, 1.02, mat_arm)
		var trap: Vector3 = p_chest + b_chest * Vector3(sd * 0.145, 0.086, 0.020)
		_ellipsoid(root, trap, b_chest, 0.086 * girth, 1.10, 0.80, 1.0, mat_arm)
		var elbow := Vector3.ZERO
		var wrist := Vector3.ZERO
		if punching:
			elbow = shoulder + b_chest * Vector3(sd * 0.055, -0.055, -reach)
			wrist = elbow + b_chest * Vector3(-sd * 0.022, 0.012, -reach * 1.06)
		else:
			elbow = shoulder + Vector3(sd * 0.098, -0.255, 0.028)
			wrist = elbow + Vector3(sd * 0.030, -0.235, -0.062)
		_limb(root, shoulder, elbow, 0.076 * girth, mat_arm)
		_ellipsoid(root, elbow, Basis(), 0.058 * girth, 1.0, 1.0, 1.0, mat_arm)
		_limb(root, elbow, wrist, 0.058 * girth, mat_arm)
		var arm_dir: Vector3 = (wrist - elbow).normalized()
		var fist: Vector3 = wrist + arm_dir * 0.052
		_ellipsoid(root, fist, _frame(arm_dir, Vector3.UP), 0.066 * girth, 1.0, 0.92, 1.0, mat_arm)
		var knuck_up: Vector3 = _perp(arm_dir, Vector3.UP)
		var knuck_side: Vector3 = knuck_up.cross(arm_dir).normalized()
		for k in range(4):
			var fk: float = float(k) / 3.0
			var kp: Vector3 = fist + arm_dir * 0.026 + knuck_side * ((fk - 0.5) * 0.072) + knuck_up * 0.024
			_ellipsoid(root, kp, Basis(), 0.023, 1.0, 1.0, 1.0, mat_arm)
			_cone(root, kp + arm_dir * 0.018, (arm_dir - knuck_up * 0.45).normalized(), 0.036, 0.011, mat_horn)
		var thumb: Vector3 = fist + knuck_side * (sd * 0.052) - knuck_up * 0.018
		_limb(root, fist, thumb, 0.024, mat_arm)
		# forearm fin crest
		var fin_dir: Vector3 = _perp(arm_dir, Vector3(sd * 0.42, 0.72, 0.55))
		for b in range(n_arm_blades):
			var fb: float = float(b) / float(n_arm_blades - 1)
			var bell: float = sin(PI * clampf(0.14 + fb * 0.76, 0.0, 1.0))
			var at: Vector3 = elbow.lerp(wrist, lerpf(0.14, 0.92, fb))
			_blade(root, at + fin_dir * 0.032, _frame(fin_dir, arm_dir), 0.046, lerpf(0.040, 0.078, bell), 0.012, mat_horn)
		if punching:
			var cuff := TorusMesh.new()
			cuff.inner_radius = 0.058
			cuff.outer_radius = 0.082
			cuff.rings = 14
			cuff.ring_segments = 10
			var cm: MeshInstance3D = _add(root, cuff, mat_dark)
			cm.transform = Transform3D(_frame(arm_dir, Vector3.UP), wrist - arm_dir * 0.030)
			var stud := SphereMesh.new()
			stud.radius = 0.021
			stud.height = 0.042
			var sm: MeshInstance3D = _add(root, stud, mat_silver)
			sm.transform = Transform3D(Basis(), wrist - arm_dir * 0.030 + knuck_up * 0.076)
		var deltoid_stud: Vector3 = shoulder + b_chest * Vector3(sd * 0.070, 0.062, -0.048)
		var ds := SphereMesh.new()
		ds.radius = 0.024
		ds.height = 0.048
		var dm: MeshInstance3D = _add(root, ds, mat_silver)
		dm.transform = Transform3D(Basis(), deltoid_stud)

	# --- neck ----------------------------------------------------------------
	var p_neck: Vector3 = pts[n_spine - 1]
	var b_head := Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_pitch)
	for i in range(3):
		var t: float = float(i + 1) / 3.0
		var np: Vector3 = p_neck + Vector3(0.0, 0.040 * float(i + 1), -0.012 * float(i + 1))
		_ellipsoid(root, np, b_chest, lerpf(0.100, 0.086, t) * girth, 1.06, 1.0, 0.94, mat_arm)

	# --- head ----------------------------------------------------------------
	var h_org := Vector3(p_neck.x + 0.006 * arm_side, 1.472, p_neck.z - 0.042)
	var mat_head: StandardMaterial3D = _skin(col_up, skin_tex, 0.54, 4.0)
	var mat_brow: StandardMaterial3D = _skin(col_up.darkened(0.16), skin_tex, 0.52, 4.0)
	var mat_jaw: StandardMaterial3D = _skin(col_up.lerp(col_belly, 0.30), skin_tex, 0.52, 4.0)
	var rh: float = 0.118 * girth
	_ellipsoid(root, h_org, b_head, rh, 0.96, 1.02, 1.14, mat_head)
	_ellipsoid(root, h_org + b_head * Vector3(0.0, 0.026, 0.062), b_head, rh * 0.86, 1.02, 0.96, 1.0, mat_head)

	# muzzle and dropped jaw
	var muzzle: ArrayMesh = _tapered_box(0.188 * girth, 0.118 * girth, 0.104 * girth, 0.062 * girth, 0.186 * girth, -0.014)
	var mm: MeshInstance3D = _add(root, muzzle, mat_jaw)
	mm.transform = Transform3D(b_head, h_org + b_head * Vector3(0.0, -0.030, -0.046))
	var hinge: Vector3 = h_org + b_head * Vector3(0.0, -0.062, -0.014)
	var jb: Basis = b_head * Basis(Vector3.RIGHT, -jaw_open)
	var jaw: ArrayMesh = _tapered_box(0.162 * girth, 0.078 * girth, 0.096 * girth, 0.046 * girth, 0.176 * girth, 0.0)
	var jm: MeshInstance3D = _add(root, jaw, mat_jaw)
	jm.transform = Transform3D(jb, hinge)
	_ellipsoid(root, h_org + b_head * Vector3(0.0, -0.072, -0.118), b_head, 0.070 * girth, 0.84, 0.46, 1.18, mat_mouth)
	var tongue_a: Vector3 = hinge + jb * Vector3(0.0, 0.016, -0.030)
	var tongue_b: Vector3 = hinge + jb * Vector3(0.0, 0.008, -0.132)
	_limb(root, tongue_a, tongue_b, 0.022 * girth, mat_tongue)

	# fangs: two upper pairs hanging from the muzzle, 0..2 lower pairs rising
	for k in range(2):
		var fz: float = lerpf(0.072, 0.150, float(k))
		var fx: float = lerpf(0.076, 0.056, float(k)) * girth
		for side_i in range(2):
			var sd: float = -1.0 if side_i == 0 else 1.0
			var tp: Vector3 = h_org + b_head * Vector3(sd * fx, -0.078 * girth, -fz - 0.046)
			_cone(root, tp, b_head * Vector3(0.0, -1.0, -0.12), lerpf(0.046, 0.034, float(k)), 0.011, mat_horn)
	for k in range(n_low_fangs):
		var fz: float = lerpf(0.058, 0.122, float(k))
		var fx: float = lerpf(0.064, 0.048, float(k)) * girth
		for side_i in range(2):
			var sd: float = -1.0 if side_i == 0 else 1.0
			var tp: Vector3 = hinge + jb * Vector3(sd * fx, 0.030 * girth, -fz)
			_cone(root, tp, jb * Vector3(0.0, 1.0, -0.10), 0.034, 0.010, mat_horn)

	# heavy brow slab and the two scowl ridges
	var brow := BoxMesh.new()
	brow.size = Vector3(0.212 * girth, 0.050, 0.086)
	var bm: MeshInstance3D = _add(root, brow, mat_brow)
	bm.transform = Transform3D(b_head * Basis(Vector3.RIGHT, deg_to_rad(-14.0)), h_org + b_head * Vector3(0.0, 0.050, -0.074))
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var ridge := BoxMesh.new()
		ridge.size = Vector3(0.104 * girth, 0.036, 0.058)
		var rm: MeshInstance3D = _add(root, ridge, mat_brow)
		var rb: Basis = b_head * Basis(Vector3.BACK, sd * 0.30) * Basis(Vector3.RIGHT, deg_to_rad(-10.0))
		rm.transform = Transform3D(rb, h_org + b_head * Vector3(sd * 0.062, 0.030, -0.104))

	# eyes with vertical slit pupils
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var ep: Vector3 = h_org + b_head * Vector3(sd * 0.074, 0.008, -0.098)
		_ellipsoid(root, ep, b_head, 0.027, 1.0, 0.86, 1.0, mat_eye)
		_ellipsoid(root, ep + b_head * Vector3(sd * 0.004, 0.0, -0.017), b_head, 0.020, 0.34, 1.05, 0.40, mat_dark)

	# pointed ears
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var ed: Vector3 = (b_head * Vector3(sd * 0.74, 0.42, 0.52)).normalized()
		var eb: Basis = _frame(ed, b_head * Vector3(sd * 0.36, 0.86, -0.32))
		_blade(root, h_org + b_head * Vector3(sd * 0.088, 0.024, 0.028) + ed * 0.028, eb, 0.062 * girth, 0.185 * girth, 0.017, mat_head)

	# horn fins off the crown, raked back
	for k in range(n_horn):
		var fk: float = 0.0 if n_horn < 2 else float(k) / float(n_horn - 1)
		var xo: float = (fk - 0.5) * 0.112 * girth
		var sgn: float = -1.0 if xo < 0.0 else 1.0
		var base_p: Vector3 = h_org + b_head * Vector3(xo, rh * 0.86, 0.014)
		var hd: Vector3 = (b_head * Vector3(sgn * 0.26, 0.86, 0.46)).normalized()
		var hl: float = lerpf(0.132, 0.096, absf(fk - 0.5) * 2.0)
		_cone(root, base_p, hd, hl, 0.021 * girth, mat_horn)

	# midline crest spikes down the back of the skull
	for k in range(4):
		var fk: float = float(k) / 3.0
		var cp: Vector3 = h_org + b_head * Vector3(0.0, lerpf(rh * 0.78, rh * 0.20, fk), lerpf(0.056, 0.124, fk))
		var cd: Vector3 = (b_head * Vector3(0.0, lerpf(0.80, 0.35, fk), lerpf(0.55, 0.94, fk))).normalized()
		_cone(root, cp, cd, lerpf(0.050, 0.028, fk), 0.014, mat_horn)

	# --- silver: sternum studs, shoulder chain, filigree ----------------------
	for k in range(n_studs):
		var fk: float = float(k) / float(maxi(n_studs - 1, 1))
		var tl: float = lerpf(0.80, 0.24, fk)
		var idx: int = int(floor(tl * float(n_spine - 1)))
		var bf: Basis = frames[idx]
		var front: Vector3 = bf * Vector3(0.0, 0.0, -1.0)
		var sp: Vector3 = pts[idx] + front * (radii[idx] * depths[idx] * 0.95) + bf * Vector3(arm_side * 0.014, 0.0, 0.0)
		var sph := SphereMesh.new()
		sph.radius = lerpf(0.026, 0.018, fk)
		sph.height = sph.radius * 2.0
		var mi: MeshInstance3D = _add(root, sph, mat_silver)
		mi.transform = Transform3D(Basis(), sp)
	var chain_a: Vector3 = p_chest + b_chest * Vector3(arm_side * 0.190, 0.076, -0.060)
	var chain_b: Vector3 = pts[maxi(i_chest - 4, 0)] + b_chest * Vector3(-arm_side * 0.150, 0.0, -0.100)
	for k in range(9):
		var fk: float = float(k) / 8.0
		var sag: float = sin(PI * fk)
		var cp: Vector3 = chain_a.lerp(chain_b, fk) + b_chest * Vector3(0.0, -0.052 * sag, -0.030 * sag)
		var bead := SphereMesh.new()
		bead.radius = 0.0155
		bead.height = 0.031
		var mi: MeshInstance3D = _add(root, bead, mat_silver)
		mi.transform = Transform3D(Basis(), cp)
	if filigree:
		for curl in range(2):
			var cf: float = -1.0 if curl == 0 else 1.0
			var anchor: Vector3 = p_chest + b_chest * Vector3(cf * 0.120, -0.070 - 0.040 * float(curl), -r_chest * 0.92)
			for k in range(7):
				var fk: float = float(k) / 6.0
				var ang: float = fk * PI * 1.6
				var rad: float = lerpf(0.020, 0.072, fk)
				var cp: Vector3 = anchor + b_chest * Vector3(cf * rad * cos(ang), rad * sin(ang), -0.010 * fk)
				var bead := SphereMesh.new()
				bead.radius = 0.0125
				bead.height = 0.025
				var mi: MeshInstance3D = _add(root, bead, mat_silver)
				mi.transform = Transform3D(Basis(), cp)

	# --- tail ----------------------------------------------------------------
	var mat_tail: StandardMaterial3D = _skin(col_low, skin_tex, 0.55, 4.0)
	var tp2: Vector3 = pts[0] + Vector3(0.0, -0.060, 0.135)
	var seg: float = 0.545 / float(n_tail)
	var last_dir := Vector3(0.0, 0.0, 1.0)
	for i in range(n_tail):
		var s: float = float(i + 1) / float(n_tail)
		var ang: float = -0.22 - 1.20 * pow(s, 1.15)
		var td: Vector3 = Vector3(tail_side * 0.34 * sin(PI * s), sin(ang), cos(ang)).normalized()
		last_dir = td
		tp2 = tp2 + td * seg
		var tr: float = lerpf(0.098, 0.021, pow(s, 0.90)) * girth
		var ty: float = maxf(tp2.y, tr + 0.006)
		tp2 = Vector3(tp2.x, ty, tp2.z)
		_ellipsoid(root, tp2, _frame(td, Vector3.UP), tr, 1.0, 1.0, 1.0, mat_tail)
		if i % 3 == 1 and s < 0.85:
			var up_ish: Vector3 = _perp(td, Vector3.UP)
			_cone(root, tp2 + up_ish * (tr * 0.82), up_ish, tr * 0.90, tr * 0.30, mat_horn)
	_cone(root, tp2 + last_dir * 0.014, last_dir, 0.060, 0.021, mat_horn)

	# --- fit to the case, then a measured settle onto the floor ---------------
	var box: AABB = _union_aabb(root)
	var ky: float = target_h / maxf(box.size.y, 0.01)
	var kx: float = 1.200 / maxf(box.size.x, 0.01)
	var kz: float = 1.200 / maxf(box.size.z, 0.01)
	var kfit: float = minf(ky, minf(kx, kz))
	if absf(kfit - 1.0) > 0.001:
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
# shape helpers

static func _c(arr: Array, i: int) -> Color:
	var code: String = arr[i]
	return Color(code)


static func _keyed(keys: Array, t: float) -> float:
	var n: int = keys.size()
	var f: float = clampf(t, 0.0, 1.0) * float(n - 1)
	var i: int = int(floor(f))
	if i >= n - 1:
		return float(keys[n - 1])
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = float(keys[i])
	var vb: float = float(keys[i + 1])
	return lerpf(va, vb, s)


static func _perp(axis: Vector3, hint: Vector3) -> Vector3:
	var a: Vector3 = axis.normalized()
	var v: Vector3 = hint - a * a.dot(hint)
	if v.length() < 0.0001:
		v = Vector3.UP - a * a.dot(Vector3.UP)
	if v.length() < 0.0001:
		v = Vector3.RIGHT - a * a.dot(Vector3.RIGHT)
	return v.normalized()


static func _frame(y_dir: Vector3, z_hint: Vector3) -> Basis:
	var by: Vector3 = y_dir.normalized()
	var bz: Vector3 = _perp(by, z_hint)
	var bx: Vector3 = by.cross(bz).normalized()
	return Basis(bx, by, bz)


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


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _skin(c: Color, tex: ImageTexture, rough: float, tri: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	if tex != null:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 1.2
		m.uv1_scale = Vector3(tri, tri, tri)
	return m


static func _ellipsoid(root: Node3D, pos: Vector3, bs: Basis, r: float, sx: float, sy: float, sz: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 20
	sph.rings = 11
	var mi: MeshInstance3D = _add(root, sph, mat)
	var sb := Basis(Vector3(sx, 0.0, 0.0), Vector3(0.0, sy, 0.0), Vector3(0.0, 0.0, sz))
	mi.transform = Transform3D(bs * sb, pos)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 1.7
	cap.radial_segments = 16
	cap.rings = 6
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _cone(root: Node3D, base: Vector3, dir: Vector3, h: float, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = 0.0
	cyl.height = h
	cyl.radial_segments = 10
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), base + d * (h * 0.5))
	return mi


static func _blade(root: Node3D, pos: Vector3, bs: Basis, base_w: float, hgt: float, thick: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var pri := PrismMesh.new()
	pri.size = Vector3(base_w, hgt, thick)
	pri.left_to_right = 0.34
	var mi: MeshInstance3D = _add(root, pri, mat)
	mi.transform = Transform3D(bs, pos)
	return mi


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


static func _tapered_box(w0: float, h0: float, w1: float, h1: float, ln: float, drop: float) -> ArrayMesh:
	# back face at z = 0 (w0 x h0), front face at z = -ln (w1 x h1), front centre offset by `drop`
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


static func _pebble_texture(rng: RandomNumberGenerator, cols: int, rows: int, jitter: float, groove: float, contrast: float) -> ImageTexture:
	# staggered lattice of lit domes, near-white so albedo_color tints it
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var w: float = float(TEX_SIZE) / float(cols)
	var h: float = float(TEX_SIZE) / float(rows)
	var n_cells: int = cols * rows
	var ox: Array = []
	var oy: Array = []
	var tints: Array = []
	for i in range(n_cells):
		ox.append(rng.randf_range(-jitter, jitter))
		oy.append(rng.randf_range(-jitter, jitter))
		tints.append(rng.randf_range(0.90, 1.0))
	var lx: float = -0.44
	var ly: float = 0.60
	var lz: float = 0.67
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var row_c: int = int(floor(py / h))
			var best: float = 1.0e9
			var bdx: float = 0.0
			var bdy: float = 0.0
			var bi: int = 0
			for rr in range(row_c - 1, row_c + 2):
				var rw: int = posmod(rr, rows)
				var off: float = w * 0.5 if (rw % 2) == 1 else 0.0
				var col_c: int = int(floor((px - off) / w))
				for cc in range(col_c - 1, col_c + 2):
					var ci: int = rw * cols + posmod(cc, cols)
					var cx: float = (float(cc) + 0.5) * w + off + float(ox[ci]) * w
					var cy: float = (float(rr) + 0.5) * h + float(oy[ci]) * h
					var dx: float = px - cx
					var dy: float = py - cy
					var dd: float = dx * dx + dy * dy
					if dd < best:
						best = dd
						bdx = dx
						bdy = dy
						bi = ci
			var nx: float = bdx / (w * 0.54)
			var ny: float = bdy / (h * 0.54)
			var q: float = sqrt(nx * nx + ny * ny)
			var qc: float = minf(q, 1.0)
			var nz: float = sqrt(maxf(1.0 - qc * qc, 0.0))
			var lam: float = clampf(nx * lx + ny * ly + nz * lz, 0.0, 1.0)
			var shade: float = (1.0 - contrast) + contrast * lam
			var edge: float = clampf((1.03 - q) / 0.20, 0.0, 1.0)
			var v: float = clampf(lerpf(groove, shade * float(tints[bi]), edge), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
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
