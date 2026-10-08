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
##   2. Pebble skin — a 144x144 ImageTexture painted in code: a staggered jittered
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
##   8. A short tapering tail of 6..9 segments raked back and steeply down as a
##      counterweight to the punch, with two or three spikes along its ridge. It
##      is kept stubby on purpose: a long tail plus the punch would overrun the
##      1.25 m depth case and the fit pass would shrink the whole figure.
##
## Given up: the crowd (this is one body, not the group), the pink scaled dragon
## coils behind them, the trees and the black ground, the spear, the fabric straps
## and buckles round the wrist, the true moulded relief of the white one's filigree
## (beads stand in for engraved line), and the ridged pink interior of the mouth.
##
## THE FINISH (2026-09-03, Palle: "add super glossy and queer materials").
## The reference already reads as glossy figures under a hard light, so the gloss
## is not a costume here — it is what the flesh is made of, at every axis value.
## Every surface now comes from DreamSkin:
##   body, belly, plates, brow, jaw, ears — ONE finish dealt from the seed out of
##     latex · patent · oilslick · holo · candy · chrome · pearl · wet (neon is
##     held back: a whole body at emission 3.2 photographs as a white blob), in a
##     colour from the queer palette. The old SCHEMES survive as a VALUE ladder,
##     not a hue — the black scheme now deals an ink-dark hot-pink latex, the
##     white one a pale pearl, so a seed still lands on "the dark one".
##   horn, fang, claw, crest, blade — always PEARL. Nacre is what horn and nail
##     want to be, and it holds its own against whatever the body was dealt.
##   mouth and tongue — WET, in a hot pink bled toward blood.
##   eyes — NEON: the slit eye is the one lit thing on the figure.
##   studs, chain, cuff stud, filigree — CHROME, which carries a painted brushed
##     streak so the metal cannot photograph black in a bare capture scene.
##   pupils and wrist cuff — PATENT black.
## The ONE matte passage is `curse = reliquary`: the bone armature stays chalk
## (DreamSkin "matte"), so the horns, fangs, eyes and silver left at full size
## read as wet relics hung in a dry cage. That contrast is the point.
##
## DNA axes:
##   possession — how many demons ride this one body: `single` as built above, or
##     `three_faced` (two more shouting oni heads on splayed necks off the neck
##     base), `six_armed` (four subordinate arms fanned off the ribs in a mudra
##     spread), `brood` (a half-size second demon budding out of the free
##     shoulder, with its own head, arms and curled tail).
##   curse — what has become of the flesh: `flesh` as built above, or `tallow`
##     (the whole figure sags down its own height and pours into a puddle of
##     lobes round its feet, with drips hanging off the high parts), `exorcised`
##     (every part shoved apart along its own outward normal and tumbled, the
##     body held open in the air where the demon left it), `reliquary` (the
##     skinned parts shrink to a beaded bone armature inside eight rib hoops and
##     four long rods, with horns, fangs, eyes and silver left full size), or
##     `fused` — the ISO value.
##
## `fused` — the demon and the flesh grown as ONE body. The same joints and radii
## the primitive figure is assembled from are handed to DreamIso as a signed
## distance field (spine, neck, skull and cranial bulge, snout and dropped jaw,
## both ears, thighs, shins, feet, shoulders, arms, fists, tail — plus whatever
## the possession axis added: the two extra necks, the four subordinate arms, or
## the budding brood) and marched into a single mesh. The smooth union means no
## limb has an edge: the arm swells out of the shoulder, the belly is the torso,
## the two extra heads of `three_faced` share one neck instead of intersecting
## it. Three cuts carve what the union would otherwise web shut — two in the maw,
## so the open mouth is a place the field never crossed zero rather than a gap
## between two boxes, and two shallow eye sockets for the neon slits to sit in.
## The field is held at or under 40 parts. The flesh meshes are then deleted and
## the grown body takes their place; every hard part — horn, fang, claw, blade,
## brow slab, eye, silver, chain, cuff, mouth and tongue — stays a primitive and
## sits on the grown skin, which is what keeps the mesh count around 70 rather
## than the 1 the isosurface alone would give. THE MESHER IS NEW: if
## DreamIso.add_body returns null the primitive body is left standing untouched,
## so the worst case is a `fused` that looks like `flesh`, never an empty plinth.

const DreamSkin := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const DreamIso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX_SIZE: int = 144

# the finishes a whole BODY may be dealt: DreamSkin's list less "matte" (this
# family is never matte) and less "neon" (a body at emission 3.2 loses its form)
const BODY_FINISHES: Array = ["latex", "patent", "oilslick", "holo", "candy",
	"chrome", "pearl", "wet"]

# scheme: [body upper, body lower, belly, plate, horn/claw, mouth]
# kept for its VALUE ladder and for the filigree roll; the hue now comes from
# the queer palette, so scheme 1 is the dark one and scheme 4 the pale one.
const SCHEMES: Array = [
	["#8FDDA4", "#5FB981", "#E9F6E3", "#CBEBCC", "#EFF6EA", "#8E4C63"],
	["#26262B", "#101014", "#3D3D44", "#2C2C32", "#DCDCE0", "#7C3D52"],
	["#8FC3D9", "#679FBF", "#E1F0F5", "#BEE0EA", "#EDF4F7", "#8A4A62"],
	["#E2A6DE", "#C57CC2", "#F7E4F4", "#F0CBEC", "#FAEFF8", "#93425F"],
	["#F3F0EA", "#DBD5CB", "#FBF9F5", "#EDE9E2", "#C7C3BB", "#A2707F"],
]
const EYE_COLS: Array = ["#F2C230", "#EFE04A", "#5FD8B4", "#EA6E9C", "#7BC8F0"]


static func axes() -> Dictionary:
	return {
		"possession": ["single", "three_faced", "six_armed", "brood"],
		"curse": ["flesh", "tallow", "exorcised", "reliquary", "fused"],
	}


static func describe() -> String:
	return "A standing oni-dragon in a wide stance with one arm punched forward, its pebble skin dealt as latex, patent, oil slick, holographic foil, candy, chrome or pearl, with a pale belly, heavy brow, wet open fanged jaw, neon slit eyes, pearl horn fins and chrome studs."


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var possession: String = str(opts.get("possession", "single"))
	var curse: String = str(opts.get("curse", "flesh"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- palette: the scheme keeps its VALUE, the queer palette takes the hue --
	var si: int = rng.randi_range(0, SCHEMES.size() - 1)
	var sc: Array = SCHEMES[si]
	var filigree: bool = si == 4
	var finish: String = str(BODY_FINISHES[rng.randi_range(0, BODY_FINISHES.size() - 1)])
	var main: Color = DreamSkin.queer_colour(rng)
	var accent: Color = DreamSkin.queer_colour(rng)
	var tries: int = 0
	while accent.is_equal_approx(main) and tries < 6:
		accent = DreamSkin.queer_colour(rng)
		tries += 1
	var cream: Color = DreamSkin.QUEER["cream"]

	var col_up: Color = _shade(main, _value(_c(sc, 0)))
	var col_low: Color = _shade(main.lerp(accent, 0.26), _value(_c(sc, 1)))
	var col_belly: Color = cream.lerp(main, 0.26)
	var col_plate: Color = cream.lerp(accent, 0.44)
	var col_horn: Color = cream.lerp(accent, 0.20)
	var pink: Color = DreamSkin.QUEER["hot_pink"]
	var blood: Color = DreamSkin.QUEER["blood"]
	var col_mouth: Color = pink.lerp(blood, rng.randf_range(0.20, 0.62))
	var col_eye: Color = _c(EYE_COLS, rng.randi_range(0, EYE_COLS.size() - 1))

	var skin_tex: ImageTexture = _pebble_texture(rng, 14, 16, 0.14, 0.52, 0.60)
	var plate_tex: ImageTexture = _pebble_texture(rng, 7, 8, 0.10, 0.66, 0.44)

	# the dealt finish, worn by everything that is flesh
	var mat_up: StandardMaterial3D = _gloss(finish, col_up, rng, skin_tex, 4.0)
	var mat_mid: StandardMaterial3D = _gloss(finish, col_low.lerp(col_up, 0.55), rng, skin_tex, 4.0)
	var mat_low: StandardMaterial3D = _gloss(finish, col_low, rng, skin_tex, 4.0)
	var mat_belly: StandardMaterial3D = _gloss(finish, col_belly, rng, plate_tex, 3.0)
	var mat_plate: StandardMaterial3D = _gloss(finish, col_plate, rng, plate_tex, 3.2)
	var mat_jaw: StandardMaterial3D = _gloss(finish, col_up.lerp(col_belly, 0.34), rng, skin_tex, 4.0)
	var mat_ear: StandardMaterial3D = _gloss(finish, col_up.lerp(col_horn, 0.34), rng, skin_tex, 4.0)
	# the brow slab survives every curse: it is the scowl, and it is not the skin
	var mat_brow: StandardMaterial3D = _gloss(finish, col_up.darkened(0.22), rng, skin_tex, 4.0)
	# the hard parts, always the same finishes whatever the body was dealt
	var mat_horn: StandardMaterial3D = DreamSkin.skin("pearl", col_horn, rng)
	var mat_mouth: StandardMaterial3D = DreamSkin.skin("wet", col_mouth, rng)
	var mat_tongue: StandardMaterial3D = DreamSkin.skin("wet", col_mouth.lightened(0.24), rng)
	var mat_dark: StandardMaterial3D = DreamSkin.skin("patent", Color(0.07, 0.06, 0.10), rng)
	var mat_silver: StandardMaterial3D = DreamSkin.skin("chrome", accent, rng)
	var mat_eye: StandardMaterial3D = DreamSkin.skin("neon", col_eye, rng)

	# what counts as FLESH: what the reliquary shrinks, and what the fused body
	# replaces. Membership by material identity, never by "has a texture" — the
	# chrome and oilslick finishes paint textures of their own.
	var flesh_mats: Array = [mat_up, mat_mid, mat_low, mat_belly, mat_plate, mat_jaw, mat_ear]
	# the same joints and radii, kept as a signed distance field for `fused`
	var iso_parts: Array = []

	# --- individual ----------------------------------------------------------
	var arm_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var girth: float = rng.randf_range(0.94, 1.07)
	var stance: float = rng.randf_range(0.205, 0.255)
	var lean: float = rng.randf_range(0.020, 0.070)
	var twist: float = deg_to_rad(rng.randf_range(12.0, 20.0)) * arm_side
	var reach: float = rng.randf_range(0.225, 0.262)
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
	var fuse_blend: float = rng.randf_range(0.075, 0.115)

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

	# the torso as five field capsules along the same points, radius pulled in a
	# little because the primitive rings are squashed in z and the smooth union
	# puts the volume back at every joint
	for j in range(5):
		var ta: float = float(j) / 5.0
		var tb: float = float(j + 1) / 5.0
		var ia: int = int(floor(ta * float(n_spine - 1)))
		var ib: int = int(floor(tb * float(n_spine - 1)))
		iso_parts.append(DreamIso.capsule(pts[ia], pts[ib], float(radii[ia]) * 0.92, float(radii[ib]) * 0.92))

	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var q: Vector3 = pts[i]
		var bf: Basis = frames[i]
		var r: float = radii[i]
		var wx: float = widths[i]
		var wz: float = depths[i]
		var mat_body: StandardMaterial3D = mat_low
		if t > 0.66:
			mat_body = mat_up
		elif t > 0.32:
			mat_body = mat_mid
		_ellipsoid(root, q, bf, r, wx, 1.0, wz, mat_body)

	var i_chest: int = n_spine - 2
	var p_chest: Vector3 = pts[i_chest]
	var b_chest: Basis = frames[i_chest]
	var r_chest: float = radii[i_chest]

	# --- pale belly, pectorals, abdominal lumps ------------------------------
	for i in range(6):
		var t: float = lerpf(0.06, 0.72, float(i) / 5.0)
		var idx: int = int(floor(t * float(n_spine - 1)))
		var q: Vector3 = pts[idx]
		var bf: Basis = frames[idx]
		var r: float = radii[idx]
		var wz: float = depths[idx]
		var front: Vector3 = bf * Vector3(0.0, 0.0, -1.0)
		_ellipsoid(root, q + front * (r * wz * 0.46), bf, r * 0.70, 0.95, 1.05, 0.70, mat_belly)
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var pec: Vector3 = p_chest + b_chest * Vector3(sd * r_chest * 0.52, 0.012, -r_chest * 0.74)
		_ellipsoid(root, pec, b_chest, 0.088 * girth, 1.12, 0.86, 0.72, mat_plate)
	for k in range(10):
		var kr: int = int(floor(float(k) / 3.0))
		var kc: int = k % 3
		var tl: float = lerpf(0.58, 0.16, float(kr) / 3.0)
		var idx: int = int(floor(tl * float(n_spine - 1)))
		var q: Vector3 = pts[idx]
		var bf: Basis = frames[idx]
		var r: float = radii[idx]
		var wz: float = depths[idx]
		var front: Vector3 = bf * Vector3(0.0, 0.0, -1.0)
		var offx: float = (float(kc) - 1.0) * r * 0.46
		var lump: float = lerpf(0.038, 0.024, float(kr) / 3.0) * girth
		var at: Vector3 = q + front * (r * wz * 0.72) + bf * Vector3(offx, 0.0, 0.0)
		_ellipsoid(root, at, bf, lump, 1.25, 0.85, 0.55, mat_plate)

	# --- legs ----------------------------------------------------------------
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var fwd: float = 0.070 if sd == -arm_side else -0.055
		var hip := Vector3(sd * 0.118, 0.860, 0.010)
		var knee := Vector3(sd * (stance * 0.88), 0.495, -0.020 + fwd * 0.55)
		var ankle := Vector3(sd * stance, 0.128, 0.010 + fwd)
		_ellipsoid(root, hip, Basis(), 0.108 * girth, 1.0, 0.94, 0.94, mat_mid)
		_limb(root, hip, knee, 0.095 * girth, mat_mid)
		_ellipsoid(root, knee, Basis(), 0.072 * girth, 1.0, 0.92, 1.0, mat_low)
		_limb(root, knee, ankle, 0.068 * girth, mat_low)
		var foot := Vector3(ankle.x + sd * 0.024, 0.050, ankle.z - 0.052)
		_ellipsoid(root, foot, Basis(Vector3.UP, sd * 0.24), 0.086, 1.0, 0.58, 1.55, mat_low)
		iso_parts.append(DreamIso.capsule(hip, knee, 0.100 * girth, 0.074 * girth))
		iso_parts.append(DreamIso.capsule(knee, ankle, 0.072 * girth, 0.058 * girth))
		iso_parts.append(DreamIso.capsule(Vector3(foot.x, foot.y, foot.z + 0.052),
			Vector3(foot.x + sd * 0.020, foot.y, foot.z - 0.086), 0.050, 0.042))
		for c in range(3):
			var ang: float = (float(c) - 1.0) * 0.46
			var td: Vector3 = Vector3(sin(ang) * 0.75 + sd * 0.14, -0.12, -cos(ang)).normalized()
			var toe: Vector3 = foot + td * 0.098
			_ellipsoid(root, toe, Basis(), 0.033, 1.0, 0.80, 1.0, mat_low)
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
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var punching: bool = sd == arm_side
		var shoulder: Vector3 = p_chest + b_chest * Vector3(sd * 0.255 * girth, 0.028, 0.0)
		_ellipsoid(root, shoulder, b_chest, 0.118 * girth, 1.0, 0.96, 1.02, mat_up)
		var trap: Vector3 = p_chest + b_chest * Vector3(sd * 0.145, 0.086, 0.020)
		_ellipsoid(root, trap, b_chest, 0.086 * girth, 1.10, 0.80, 1.0, mat_up)
		var elbow := Vector3.ZERO
		var wrist := Vector3.ZERO
		if punching:
			elbow = shoulder + b_chest * Vector3(sd * 0.055, -0.055, -reach)
			wrist = elbow + b_chest * Vector3(-sd * 0.022, 0.012, -reach * 1.06)
		else:
			elbow = shoulder + Vector3(sd * 0.098, -0.255, 0.028)
			wrist = elbow + Vector3(sd * 0.030, -0.235, -0.062)
		_limb(root, shoulder, elbow, 0.076 * girth, mat_up)
		_ellipsoid(root, elbow, Basis(), 0.058 * girth, 1.0, 1.0, 1.0, mat_up)
		_limb(root, elbow, wrist, 0.058 * girth, mat_up)
		var arm_dir: Vector3 = (wrist - elbow).normalized()
		var fist: Vector3 = wrist + arm_dir * 0.052
		_ellipsoid(root, fist, _frame(arm_dir, Vector3.UP), 0.066 * girth, 1.0, 0.92, 1.0, mat_up)
		iso_parts.append(DreamIso.sphere(shoulder, 0.112 * girth))
		iso_parts.append(DreamIso.capsule(shoulder, elbow, 0.080 * girth, 0.060 * girth))
		iso_parts.append(DreamIso.capsule(elbow, wrist, 0.058 * girth, 0.050 * girth))
		iso_parts.append(DreamIso.sphere(fist, 0.062 * girth))
		var knuck_up: Vector3 = _perp(arm_dir, Vector3.UP)
		var knuck_side: Vector3 = knuck_up.cross(arm_dir).normalized()
		for k in range(4):
			var fk: float = float(k) / 3.0
			var kp: Vector3 = fist + arm_dir * 0.026 + knuck_side * ((fk - 0.5) * 0.072) + knuck_up * 0.024
			_ellipsoid(root, kp, Basis(), 0.023, 1.0, 1.0, 1.0, mat_up)
			_cone(root, kp + arm_dir * 0.018, (arm_dir - knuck_up * 0.45).normalized(), 0.036, 0.011, mat_horn)
		var thumb: Vector3 = fist + knuck_side * (sd * 0.052) - knuck_up * 0.018
		_limb(root, fist, thumb, 0.024, mat_up)
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
		_ellipsoid(root, np, b_chest, lerpf(0.100, 0.086, t) * girth, 1.06, 1.0, 0.94, mat_up)

	# --- head ----------------------------------------------------------------
	var h_org := Vector3(p_neck.x + 0.006 * arm_side, 1.472, p_neck.z - 0.042)
	var rh: float = 0.118 * girth
	_ellipsoid(root, h_org, b_head, rh, 0.96, 1.02, 1.14, mat_up)
	_ellipsoid(root, h_org + b_head * Vector3(0.0, 0.026, 0.062), b_head, rh * 0.86, 1.02, 0.96, 1.0, mat_up)
	iso_parts.append(DreamIso.capsule(p_neck, h_org - b_head * Vector3(0.0, 0.055, 0.0), 0.096 * girth, 0.090 * girth))
	iso_parts.append(DreamIso.sphere(h_org, rh * 1.02))
	iso_parts.append(DreamIso.sphere(h_org + b_head * Vector3(0.0, 0.026, 0.062), rh * 0.86))

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

	# the snout, the jaw, and the maw the smooth union would otherwise web shut
	var mu_a: Vector3 = h_org + b_head * Vector3(0.0, -0.030, -0.046)
	var mu_b: Vector3 = mu_a + b_head * Vector3(0.0, -0.014, -0.186 * girth)
	var jw_a: Vector3 = hinge
	var jw_b: Vector3 = hinge + jb * Vector3(0.0, 0.0, -0.176 * girth)
	iso_parts.append(DreamIso.capsule(mu_a, mu_b, 0.070 * girth, 0.040 * girth))
	iso_parts.append(DreamIso.capsule(jw_a, jw_b, 0.052 * girth, 0.032 * girth))
	for k in range(2):
		var ft: float = 0.42 if k == 0 else 0.82
		var lo_mu: Vector3 = mu_a.lerp(mu_b, ft) + b_head * Vector3(0.0, -0.028 * girth, 0.0)
		var hi_jw: Vector3 = jw_a.lerp(jw_b, ft) + jb * Vector3(0.0, 0.024 * girth, 0.0)
		var gap_r: float = 0.040 * girth if k == 0 else 0.034 * girth
		iso_parts.append(DreamIso.cut(DreamIso.sphere(lo_mu.lerp(hi_jw, 0.5), gap_r)))

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

	# eyes with vertical slit pupils, each in a socket the field never filled
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var ep: Vector3 = h_org + b_head * Vector3(sd * 0.074, 0.008, -0.098)
		_ellipsoid(root, ep, b_head, 0.027, 1.0, 0.86, 1.0, mat_eye)
		_ellipsoid(root, ep + b_head * Vector3(sd * 0.004, 0.0, -0.017), b_head, 0.020, 0.34, 1.05, 0.40, mat_dark)
		iso_parts.append(DreamIso.cut(DreamIso.sphere(ep, 0.026 * girth)))

	# pointed ears
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var ed: Vector3 = (b_head * Vector3(sd * 0.74, 0.42, 0.52)).normalized()
		var eb: Basis = _frame(ed, b_head * Vector3(sd * 0.36, 0.86, -0.32))
		var e_root: Vector3 = h_org + b_head * Vector3(sd * 0.088, 0.024, 0.028)
		_blade(root, e_root + ed * 0.028, eb, 0.062 * girth, 0.185 * girth, 0.017, mat_ear)
		iso_parts.append(DreamIso.capsule(e_root, e_root + ed * (0.180 * girth), 0.032 * girth, 0.010 * girth))

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

	# --- possession: how many demons ride this one body -----------------------
	# every branch draws from its own RNG, so `single` keeps the original stream
	if possession == "three_faced":
		var vr := RandomNumberGenerator.new()
		vr.seed = seed * 13 + 4409
		for side_i in range(2):
			var sd: float = -1.0 if side_i == 0 else 1.0
			var yaw2: float = deg_to_rad(sd * vr.randf_range(46.0, 66.0))
			var b2: Basis = Basis(Vector3.UP, head_yaw + yaw2) * Basis(Vector3.BACK, sd * deg_to_rad(vr.randf_range(9.0, 23.0))) * Basis(Vector3.RIGHT, head_pitch)
			var o2: Vector3 = h_org + Vector3(sd * 0.152 * girth, -0.056, 0.026)
			var n2: Vector3 = p_neck + Vector3(sd * 0.050, 0.006, 0.012)
			_limb(root, n2, o2, 0.052 * girth, mat_up)
			var r2: float = rh * 0.76
			_ellipsoid(root, o2, b2, r2, 0.96, 1.02, 1.14, mat_up)
			var mz: ArrayMesh = _tapered_box(0.140 * girth, 0.090 * girth, 0.078 * girth, 0.048 * girth, 0.148 * girth, -0.012)
			var mzi: MeshInstance3D = _add(root, mz, mat_jaw)
			mzi.transform = Transform3D(b2, o2 + b2 * Vector3(0.0, -0.024, -0.036))
			var hinge2: Vector3 = o2 + b2 * Vector3(0.0, -0.050, -0.010)
			var jb2: Basis = b2 * Basis(Vector3.RIGHT, -jaw_open * 1.06)
			var jw: ArrayMesh = _tapered_box(0.122 * girth, 0.062 * girth, 0.070 * girth, 0.036 * girth, 0.140 * girth, 0.0)
			var jwi: MeshInstance3D = _add(root, jw, mat_jaw)
			jwi.transform = Transform3D(jb2, hinge2)
			_ellipsoid(root, o2 + b2 * Vector3(0.0, -0.058, -0.092), b2, 0.054 * girth, 0.84, 0.46, 1.18, mat_mouth)
			# grown: the extra neck swells out of the first one, and the snout
			# out of the extra skull, so three heads share one throat
			iso_parts.append(DreamIso.capsule(n2, o2, 0.056 * girth, 0.062 * girth))
			iso_parts.append(DreamIso.sphere(o2, r2 * 1.02))
			var m2a: Vector3 = o2 + b2 * Vector3(0.0, -0.024, -0.036)
			iso_parts.append(DreamIso.capsule(m2a, m2a + b2 * Vector3(0.0, -0.012, -0.148 * girth), 0.054 * girth, 0.032 * girth))
			for e in range(2):
				var es: float = -1.0 if e == 0 else 1.0
				var ep2: Vector3 = o2 + b2 * Vector3(es * 0.058, 0.006, -0.078)
				_ellipsoid(root, ep2, b2, 0.022, 1.0, 0.86, 1.0, mat_eye)
				_ellipsoid(root, ep2 + b2 * Vector3(0.0, 0.0, -0.014), b2, 0.016, 0.34, 1.05, 0.40, mat_dark)
				_cone(root, o2 + b2 * Vector3(es * 0.042, r2 * 0.84, 0.012), (b2 * Vector3(es * 0.30, 0.88, 0.38)).normalized(), 0.100, 0.017 * girth, mat_horn)
				_cone(root, o2 + b2 * Vector3(es * 0.052, -0.060 * girth, -0.104), b2 * Vector3(0.0, -1.0, -0.12), 0.036, 0.010, mat_horn)

	if possession == "six_armed":
		var vr := RandomNumberGenerator.new()
		vr.seed = seed * 17 + 2287
		for pair in range(2):
			var pf: float = float(pair)
			var down: float = 0.090 + 0.130 * pf
			var slim: float = 0.70 - 0.14 * pf
			for side_i in range(2):
				var sd: float = -1.0 if side_i == 0 else 1.0
				var sh: Vector3 = p_chest + b_chest * Vector3(sd * 0.205 * girth, -down, 0.006)
				_ellipsoid(root, sh, b_chest, 0.078 * girth * slim, 1.0, 0.94, 1.02, mat_up)
				var swing: float = deg_to_rad(vr.randf_range(18.0, 46.0)) + pf * 0.42
				var el: Vector3 = sh + b_chest * Vector3(sd * (0.118 + 0.052 * pf), -0.142 + 0.044 * pf, -0.086 + 0.130 * pf)
				var wr: Vector3 = el + b_chest * Vector3(sd * 0.104 * cos(swing), 0.128 - 0.246 * pf, -0.148 * sin(swing) - 0.030 + 0.120 * pf)
				_limb(root, sh, el, 0.052 * girth * slim, mat_up)
				_ellipsoid(root, el, Basis(), 0.050 * girth * slim, 1.0, 1.0, 1.0, mat_up)
				_limb(root, el, wr, 0.042 * girth * slim, mat_up)
				# the subordinate arms grow straight out of the ribs
				iso_parts.append(DreamIso.capsule(sh, el, 0.056 * girth * slim, 0.048 * girth * slim))
				iso_parts.append(DreamIso.capsule(el, wr, 0.046 * girth * slim, 0.040 * girth * slim))
				var hd2: Vector3 = (wr - el).normalized()
				var palm: Vector3 = wr + hd2 * 0.030
				_ellipsoid(root, palm, _frame(hd2, Vector3.UP), 0.048 * girth * slim, 1.0, 0.76, 1.05, mat_up)
				var across: Vector3 = _perp(hd2, Vector3.UP)
				for c2 in range(2):
					var cf2: float = -1.0 if c2 == 0 else 1.0
					_cone(root, palm + hd2 * 0.024 + across * (cf2 * 0.026), (hd2 - Vector3(0.0, 0.26, 0.0)).normalized(), 0.046, 0.010, mat_horn)

	if possession == "brood":
		var vr := RandomNumberGenerator.new()
		vr.seed = seed * 23 + 1301
		var mat_brood: StandardMaterial3D = _gloss(finish, col_up.lerp(col_belly, 0.26), rng, skin_tex, 5.2)
		flesh_mats.append(mat_brood)
		var anchor2: Vector3 = p_chest + b_chest * Vector3(-arm_side * 0.205 * girth, 0.098, -0.014)
		var grow: Vector3 = (b_chest * Vector3(-arm_side * 0.52, 0.80, -0.30)).normalized()
		var bb: Basis = _frame(grow, b_chest * Vector3(0.0, 0.0, -1.0))
		var sway: float = vr.randf_range(0.016, 0.052)
		var spine2: Array = []
		for i in range(5):
			var f: float = float(i) / 4.0
			var bend: float = sway * sin(PI * f)
			var q2: Vector3 = anchor2 + grow * lerpf(0.046, 0.256, f) + bb * Vector3(bend * arm_side, 0.0, -bend)
			spine2.append(q2)
			var rr: float = lerpf(0.074, 0.052, f) * girth
			_ellipsoid(root, q2, bb, rr, 1.06, 1.0, 0.90, mat_brood)
		var top_seg: Vector3 = spine2[4]
		var top2: Vector3 = top_seg + grow * 0.058
		var hb: Basis = bb * Basis(Vector3.UP, vr.randf_range(-0.55, 0.55))
		_ellipsoid(root, top2, hb, 0.062 * girth, 0.98, 1.04, 1.16, mat_up)
		# the brood does not sit ON the shoulder, it buds OUT of it
		iso_parts.append(DreamIso.capsule(spine2[0], spine2[2], 0.070 * girth, 0.062 * girth))
		iso_parts.append(DreamIso.capsule(spine2[2], spine2[4], 0.062 * girth, 0.052 * girth))
		iso_parts.append(DreamIso.sphere(top2, 0.062 * girth))
		var mz2: ArrayMesh = _tapered_box(0.100 * girth, 0.064 * girth, 0.056 * girth, 0.034 * girth, 0.108 * girth, -0.010)
		var mzi2: MeshInstance3D = _add(root, mz2, mat_jaw)
		mzi2.transform = Transform3D(hb, top2 + hb * Vector3(0.0, -0.016, -0.028))
		var hinge3: Vector3 = top2 + hb * Vector3(0.0, -0.034, -0.008)
		var jw2: ArrayMesh = _tapered_box(0.088 * girth, 0.044 * girth, 0.050 * girth, 0.026 * girth, 0.100 * girth, 0.0)
		var jwi2: MeshInstance3D = _add(root, jw2, mat_jaw)
		jwi2.transform = Transform3D(hb * Basis(Vector3.RIGHT, -jaw_open * 1.10), hinge3)
		_ellipsoid(root, top2 + hb * Vector3(0.0, -0.040, -0.062), hb, 0.036 * girth, 0.84, 0.46, 1.18, mat_mouth)
		for e in range(2):
			var es: float = -1.0 if e == 0 else 1.0
			_ellipsoid(root, top2 + hb * Vector3(es * 0.040, 0.006, -0.052), hb, 0.016, 1.0, 0.86, 1.0, mat_eye)
			_cone(root, top2 + hb * Vector3(es * 0.030, 0.050 * girth, 0.008), (hb * Vector3(es * 0.34, 0.86, 0.38)).normalized(), 0.074, 0.013 * girth, mat_horn)
		var arm_seg: Vector3 = spine2[3]
		for e in range(2):
			var es: float = -1.0 if e == 0 else 1.0
			var sh2: Vector3 = arm_seg + bb * Vector3(es * 0.060 * girth, 0.0, 0.0)
			var hn2: Vector3 = sh2 + bb * Vector3(es * 0.090, -0.010, -0.126)
			_limb(root, sh2, hn2, 0.026 * girth, mat_up)
			_ellipsoid(root, hn2, Basis(), 0.030 * girth, 1.0, 0.86, 1.0, mat_up)
			iso_parts.append(DreamIso.capsule(sh2, hn2, 0.030 * girth, 0.028 * girth))
		var root_seg: Vector3 = spine2[0]
		var tq: Vector3 = root_seg - grow * 0.036
		var tdir: Vector3 = (bb * Vector3(-arm_side * 0.34, -0.56, 0.76)).normalized()
		var t_start: Vector3 = tq
		for i in range(3):
			tq = tq + tdir * 0.062
			var tr2: float = lerpf(0.038, 0.018, float(i) / 2.0) * girth
			_ellipsoid(root, tq, _frame(tdir, Vector3.UP), tr2, 1.0, 1.0, 1.0, mat_low)
		iso_parts.append(DreamIso.capsule(t_start, tq, 0.038 * girth, 0.018 * girth))

	# --- silver: sternum studs, shoulder chain, filigree ----------------------
	for k in range(n_studs):
		var fk: float = float(k) / float(maxi(n_studs - 1, 1))
		var tl: float = lerpf(0.80, 0.24, fk)
		var idx: int = int(floor(tl * float(n_spine - 1)))
		var q: Vector3 = pts[idx]
		var bf: Basis = frames[idx]
		var r: float = radii[idx]
		var wz: float = depths[idx]
		var front: Vector3 = bf * Vector3(0.0, 0.0, -1.0)
		var sp: Vector3 = q + front * (r * wz * 0.95) + bf * Vector3(arm_side * 0.014, 0.0, 0.0)
		var sph := SphereMesh.new()
		sph.radius = lerpf(0.026, 0.018, fk)
		sph.height = sph.radius * 2.0
		var mi: MeshInstance3D = _add(root, sph, mat_silver)
		mi.transform = Transform3D(Basis(), sp)
	var chain_a: Vector3 = p_chest + b_chest * Vector3(arm_side * 0.190, 0.076, -0.060)
	var p_underarm: Vector3 = pts[maxi(i_chest - 4, 0)]
	var chain_b: Vector3 = p_underarm + b_chest * Vector3(-arm_side * 0.150, 0.0, -0.100)
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
	# short and raked steeply down: a long tail would eat the 1.25 m depth case
	# and force the fit pass to shrink the whole figure under 1.55 m.
	var p_pelvis: Vector3 = pts[0]
	var tp2: Vector3 = p_pelvis + Vector3(0.0, -0.070, 0.100)
	var tail_root: Vector3 = tp2
	var tail_mid: Vector3 = tp2
	var tail_mid_r: float = 0.050 * girth
	var i_mid: int = n_tail / 2
	var seg: float = 0.330 / float(n_tail)
	var last_dir := Vector3(0.0, 0.0, 1.0)
	for i in range(n_tail):
		var s: float = float(i + 1) / float(n_tail)
		var ang: float = -0.55 - 1.05 * pow(s, 1.05)
		var td: Vector3 = Vector3(tail_side * 0.30 * sin(PI * s), sin(ang), cos(ang)).normalized()
		last_dir = td
		tp2 = tp2 + td * seg
		var tr: float = lerpf(0.094, 0.021, pow(s, 0.90)) * girth
		var ty: float = maxf(tp2.y, tr + 0.006)
		tp2 = Vector3(tp2.x, ty, tp2.z)
		_ellipsoid(root, tp2, _frame(td, Vector3.UP), tr, 1.0, 1.0, 1.0, mat_low)
		if i == i_mid:
			tail_mid = tp2
			tail_mid_r = tr
		if i % 3 == 1 and s < 0.85:
			var up_ish: Vector3 = _perp(td, Vector3.UP)
			_cone(root, tp2 + up_ish * (tr * 0.82), up_ish, tr * 0.90, tr * 0.30, mat_horn)
	_cone(root, tp2 + last_dir * 0.014, last_dir, 0.060, 0.021, mat_horn)
	iso_parts.append(DreamIso.capsule(tail_root, tail_mid, 0.090 * girth, tail_mid_r))
	iso_parts.append(DreamIso.capsule(tail_mid, tp2, tail_mid_r, 0.022 * girth))

	# --- the curse: what has become of the flesh ------------------------------
	# runs before the fit pass, so a tallow, exorcised or fused body still lands
	# in the case
	if curse == "fused":
		# ONE body, grown out of the joints above. If the mesher gives nothing
		# back, the primitive figure is left exactly as it stands.
		var mat_fused: StandardMaterial3D = _gloss(finish, col_up.lerp(col_low, 0.34), rng, skin_tex, 3.4)
		_fuse(root, iso_parts, mat_fused, flesh_mats, 0.048, fuse_blend)
	elif curse != "flesh":
		var mat_bone: StandardMaterial3D = _gloss("matte", col_belly.lerp(Color("#EFE8D8"), 0.55), rng, plate_tex, 2.4)
		_curse(root, curse, seed, pts, frames, radii, mat_low, mat_bone, flesh_mats)

	# --- fit to the case, then a measured settle onto the floor ---------------
	var box: AABB = _union_aabb(root)
	var ky: float = target_h / maxf(box.size.y, 0.01)
	var kx: float = 1.210 / maxf(box.size.x, 0.01)
	var kz: float = 1.210 / maxf(box.size.z, 0.01)
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
# the grown body

## `curse = fused`. Marches the field, then — and ONLY then — takes the flesh
## primitives away. DreamIso is new and unverified, so a null mesh is not an
## error here: it means this body stays assembled instead of grown, which looks
## like `flesh` rather than like an empty plinth.
static func _fuse(root: Node3D, parts: Array, mat: StandardMaterial3D, flesh_mats: Array, cell: float, blend: float) -> bool:
	if parts.is_empty():
		return false
	var grown: MeshInstance3D = DreamIso.add_body(root, parts, mat, cell, blend)
	if grown == null:
		return false
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm == grown:
			continue
		if flesh_mats.has(cm.material_override):
			root.remove_child(cm)
			cm.free()
	return true


# ---------------------------------------------------------------------------
# shape helpers

static func _c(arr: Array, i: int) -> Color:
	var code: String = arr[i]
	return Color(code)


## The mean value of a scheme colour: what survives of the old palette.
static func _value(c: Color) -> float:
	return (c.r + c.g + c.b) / 3.0


## A queer hue pushed to the scheme's own lightness, so the dark scheme still
## reads dark and the pale one still reads pale.
static func _shade(c: Color, v: float) -> Color:
	if v < 0.42:
		return c.darkened(clampf((0.42 - v) / 0.42, 0.0, 1.0) * 0.66)
	if v > 0.74:
		return c.lightened(clampf((v - 0.74) / 0.26, 0.0, 1.0) * 0.42)
	return c


## A DreamSkin finish with this family's pebble field kept on it. The finishes
## that paint their own sweep (oilslick, holo, chrome) keep theirs, but run it
## in WORLD space so the band is unbroken across the chain of parts — the same
## argument the pebble texture was making.
static func _gloss(finish: String, c: Color, rng: RandomNumberGenerator, tex: ImageTexture, tri: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = DreamSkin.skin(finish, c, rng)
	if m.albedo_texture == null:
		if tex != null:
			m.albedo_texture = tex
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_triplanar_sharpness = 1.2
			m.uv1_scale = Vector3(tri, tri, tri)
	else:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 1.2
	return m


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


static func _curse(root: Node3D, mode: String, seed: int, pts: Array, frames: Array, radii: Array, mat_flesh: StandardMaterial3D, mat_bone: StandardMaterial3D, flesh_mats: Array) -> void:
	var kids: Array = []
	for ch in root.get_children():
		if ch is MeshInstance3D:
			kids.append(ch)
	if kids.is_empty():
		return
	var box: AABB = _union_aabb(root)
	var base_y: float = box.position.y
	var span: float = maxf(box.size.y, 0.01)
	var centre: Vector3 = box.position + box.size * 0.5
	var vr := RandomNumberGenerator.new()
	vr.seed = seed * 37 + 6113

	if mode == "tallow":
		# every part sinks toward the floor and spreads as it goes; the low parts
		# flatten into lobes, the high parts only sag
		for ch in kids:
			var mi: MeshInstance3D = ch
			var tf: Transform3D = mi.transform
			var u: float = clampf((tf.origin.y - base_y) / span, 0.0, 1.0)
			var pull: float = pow(u, 1.45)
			var ny: float = base_y + span * 0.88 * pull
			var wide: float = 1.0 + 0.56 * pow(1.0 - u, 2.0)
			var nx: float = centre.x + (tf.origin.x - centre.x) * wide
			var nz: float = centre.z + (tf.origin.z - centre.z) * wide
			var sy: float = lerpf(0.30, 1.04, u)
			var sxz: float = lerpf(1.55, 1.0, u)
			var sb := Basis(Vector3(sxz, 0.0, 0.0), Vector3(0.0, sy, 0.0), Vector3(0.0, 0.0, sxz))
			mi.transform = Transform3D(sb * tf.basis, Vector3(nx, ny, nz))
		# the puddle it stands in
		for k in range(9):
			var ang: float = float(k) / 9.0 * TAU + vr.randf_range(-0.16, 0.16)
			var rad: float = vr.randf_range(0.06, 0.25)
			var lobe: float = vr.randf_range(0.11, 0.19)
			var at := Vector3(centre.x + cos(ang) * rad, base_y + 0.018, centre.z + sin(ang) * rad)
			_ellipsoid(root, at, Basis(Vector3.UP, ang), lobe, 1.0, 0.14, 1.40, mat_flesh)
		# four drips hanging off whatever is still high up
		for k in range(4):
			var pick: int = int(floor(float(k + 1) * float(kids.size()) / 5.0))
			var src: MeshInstance3D = kids[clampi(pick, 0, kids.size() - 1)]
			var org: Vector3 = src.transform.origin
			if org.y - base_y < span * 0.30:
				continue
			var drop: float = span * vr.randf_range(0.14, 0.26)
			var tip: Vector3 = Vector3(org.x, org.y - drop, org.z)
			_limb(root, org, tip, 0.013, mat_flesh)
			_ellipsoid(root, tip, Basis(), 0.030, 1.0, 1.45, 1.0, mat_flesh)

	elif mode == "exorcised":
		# each part shoved out along its own normal from the body centre and
		# tumbled, so the figure hangs open in the air where the demon left it
		var idx: int = 0
		for ch in kids:
			var mi: MeshInstance3D = ch
			var tf: Transform3D = mi.transform
			var d: Vector3 = tf.origin - centre
			var out_dir: Vector3 = d
			if out_dir.length() < 0.0005:
				out_dir = Vector3.UP
			out_dir = out_dir.normalized()
			var far: float = clampf(d.length() / (span * 0.42), 0.0, 1.5)
			var gap: float = 0.026 + 0.062 * far
			var no: Vector3 = centre + d * 1.11 + out_dir * gap
			var raw := Vector3(sin(float(idx) * 2.399 + 0.7), cos(float(idx) * 1.117), sin(float(idx) * 0.731 + 1.9))
			var ax: Vector3 = raw.normalized() if raw.length() > 0.001 else Vector3.UP
			var spin: float = 0.20 + 0.22 * sin(float(idx) * 0.53)
			mi.transform = Transform3D(Basis(ax, spin) * tf.basis.scaled(Vector3(0.90, 0.90, 0.90)), no)
			idx += 1

	elif mode == "reliquary":
		# the flesh shrinks to a beaded armature and goes chalk — the ONE matte
		# passage in this family — while horn, fang, eye and silver stay their
		# full glossy size as the relics. Membership by material identity: the
		# chrome and oilslick finishes carry textures of their own, so the old
		# "has an albedo texture" test would have shrunk the studs too.
		for ch in kids:
			var mi: MeshInstance3D = ch
			if not flesh_mats.has(mi.material_override):
				continue
			var tf: Transform3D = mi.transform
			mi.transform = Transform3D(tf.basis.scaled(Vector3(0.30, 0.30, 0.30)), tf.origin)
			mi.material_override = mat_bone
		var n: int = pts.size()
		for k in range(8):
			var fk: float = float(k) / 7.0
			var ii: int = int(floor(fk * float(n - 1)))
			var q: Vector3 = pts[ii]
			var bf: Basis = frames[ii]
			var rr: float = float(radii[ii])
			var ring := TorusMesh.new()
			ring.inner_radius = rr * 1.04
			ring.outer_radius = rr * 1.26
			ring.rings = 16
			ring.ring_segments = 7
			var mi2: MeshInstance3D = _add(root, ring, mat_bone)
			mi2.transform = Transform3D(bf * Basis(Vector3.RIGHT, deg_to_rad(-14.0)), q)
		var a_i: int = 1
		var b_i: int = maxi(n - 2, 1)
		var qa: Vector3 = pts[a_i]
		var qb: Vector3 = pts[b_i]
		var ba: Basis = frames[a_i]
		var bb2: Basis = frames[b_i]
		var ra: float = float(radii[a_i])
		var rb2: float = float(radii[b_i])
		for k in range(4):
			var ang: float = float(k) * TAU / 4.0 + PI * 0.25
			var ua: Vector3 = ba * Vector3(sin(ang), 0.0, cos(ang))
			var ub: Vector3 = bb2 * Vector3(sin(ang), 0.0, cos(ang))
			_limb(root, qa + ua * (ra * 1.14), qb + ub * (rb2 * 1.14), 0.012, mat_bone)


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
