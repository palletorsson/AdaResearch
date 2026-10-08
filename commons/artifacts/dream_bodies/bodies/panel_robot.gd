extends RefCounted
## PANEL ROBOT — one body from refs/panel_robot.png, the second De Stijl robot
## group: armour-plated humanoids walking through a garden, each a single
## saturated flat colour (mint, violet, mustard, coral, white with red patches),
## their panels floating over a white undersuit with the gaps showing, chrome at
## every joint, a smooth helmet with a visor slit or one round eye.
##
## What is reproduced, and with what:
##  1. Panel armour with visible gaps — every plate is a BoxMesh or a bent
##     ArrayMesh shell (SurfaceTool, PRIMITIVE_TRIANGLES, generate_normals) held
##     `gap` metres off a CapsuleMesh limb or the torso core, so the undersuit
##     shows between plates exactly as in the picture.
##  2. Curved AND flat plates — upper arms, thighs, chest, pauldrons, hip skirts
##     and the abdomen bands are bent shells; forearms, shins, kneecaps, heels and
##     the backs of the hands are square sleeves of flat boxes.
##  3. One flat colour per body, chosen by seed from the picture's five; a
##     minority of plates take the body's second colour (white on the coloured
##     robots, red patches on the white one), so no two seeds patch alike.
##  4. The helmet — an egg-scaled SphereMesh with a bent faceplate and chin band,
##     chrome ear discs, and either the mint robot's horizontal slit (dark box,
##     white and orange segments, red button) or the violet robot's round eye
##     (chrome TorusMesh ring around a dark disc).
##  5. Chrome joints — SphereMesh at shoulder, elbow, hip, knee, ankle and
##     CylinderMesh at wrist and neck, metallic 1.0, roughness 0.18.
##  6. Pauldron caps over the shoulders and split pectoral plates — bent shells
##     whose axis runs front-to-back so they curve over the joint.
##  7. Screw dots on the panels — a 64x64 ImageTexture of two to four dark
##     screws drawn in code, repeated every 10 cm across the bent plates.
##  8. Pose — mid-stride: one foot forward, the back heel raised off the plinth,
##     opposite arm swung forward with the elbow bent, a forward lean, a shoulder
##     twist and a turned, tilted head. All of it seeded.
##
## Given up: the chamfered edges and the wiring in the gaps, the pink cloth and
## the hedge, the exact tapered chin of the AI helmet, and the crowd — this is
## one walker, not the procession.
##
## TWO AXES (see axes(); every plate in the body is emitted through _plate_bent /
## _plate_box, so an axis reaches the whole suit at once):
##
##  panelling — what the floating armour DOES with its gap. `floating` is the
##    suit as built; `shed` blows every plate outward along its own radius from
##    the chest until the robot walks inside a cloud of its own armour; `swarmed`
##    replaces each plate with a shoal of three small flakes of itself; `ribbed`
##    strips the plates to their edges, hoops and bars only, the armour a cage
##    around a bare undersuit; `molten` lets every plate sag off its mounting,
##    drip, and pool in a lake of the body colour on the plinth.
##
##  assembly — what came off the line. `walker` is one robot; `totem` stacks
##    three heads on the neck, each smaller and turned further, the top one
##    crowned with a fan of blades; `twinned` buds a second, thicker-limbed robot
##    out of its back, facing the other way, with its own head and two arms;
##    `poured` drowns the legs to the hip in a solid glossy pour of the body's
##    own colour, so the walker ends in a cone standing in a lake.
##
## Both defaults reproduce the original statue. build() now closes with the
## measured settle every dream body owes the plinth: merge the child AABBs, scale
## down into 1.20 x 1.20 x 1.68, centre x/z, stand the lowest point on y = 0 —
## which is what lets a shed, molten or totem variant blow up and still fit.

const PALETTE := [
	Color(0.31, 0.71, 0.60),  # mint green
	Color(0.42, 0.25, 0.78),  # deep violet
	Color(0.91, 0.73, 0.17),  # mustard yellow
	Color(0.89, 0.28, 0.18),  # coral red
	Color(0.93, 0.93, 0.91),  # white
]
const UNIT_HEIGHT := 1.76  # metres of the unscaled rig, floor to the crown of the tallest head
const PLINTH_H := 0.02
## Hard ceiling on MeshInstance3D children. The swarmed panelling triples every
## plate and the twinned assembly adds a second suit; the cap is what keeps the
## worst crossing inside the contract instead of trusting arithmetic.
const MESH_CAP := 252


static func describe() -> String:
	return "A panel-armoured humanoid robot caught mid-stride, one flat garden colour over a white undersuit with chrome joints, its plates floating apart with the gaps showing under a smooth visored helmet."


static func axes() -> Dictionary:
	return {
		"panelling": ["floating", "shed", "swarmed", "ribbed", "molten"],
		"assembly": ["walker", "totem", "twinned", "poured"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var panelling: String = str(opts.get("panelling", "floating"))
	var assembly: String = str(opts.get("assembly", "walker"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the individual -------------------------------------------------
	var colour_index: int = rng.randi_range(0, PALETTE.size() - 1)
	var is_white: bool = colour_index == 4
	var body: Color = PALETTE[colour_index]
	var second: Color = PALETTE[3] if is_white else PALETTE[4]
	var accent_index: int = (colour_index + 1 + rng.randi_range(0, 2)) % 4
	var accent: Color = PALETTE[accent_index]
	var height: float = rng.randf_range(1.62, 1.70)
	var s: float = height / UNIT_HEIGHT
	var stride: float = rng.randf_range(0.14, 0.20)
	var lean: float = deg_to_rad(rng.randf_range(3.0, 9.0))
	var twist: float = deg_to_rad(rng.randf_range(-10.0, 10.0))
	var head_yaw: float = deg_to_rad(rng.randf_range(-28.0, 28.0))
	var head_tilt: float = deg_to_rad(rng.randf_range(-8.0, 8.0))
	var fwd_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var gap: float = rng.randf_range(0.012, 0.022)
	var eye_variant: int = 0 if rng.randf() < 0.6 else 1
	var eye_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var tex: ImageTexture = _screw_texture(rng)

	var c: Dictionary = {
		"root": root,
		"s": s,
		"rng": rng,
		"gap": gap,
		"panelling": panelling,
		"assembly": assembly,
		"shards": 3 if assembly == "walker" else 2,
		"hub": Vector3(0.0, 1.14, 0.0),
		"second_chance": 0.32 if is_white else 0.14,
		"plate": _mat(body, 0.55, 0.0, 0.3, tex),
		"plate2": _mat(second, 0.55, 0.0, 0.3, tex),
		"under": _mat(Color(0.86, 0.86, 0.85), 0.65, 0.0, 0.0, null),
		"chrome": _mat(Color(0.80, 0.82, 0.85), 0.18, 1.0, 0.0, null),
		"dark": _mat(Color(0.12, 0.13, 0.15), 0.35, 0.0, 0.0, null),
		"white": _mat(Color(0.96, 0.96, 0.95), 0.4, 0.0, 0.0, null),
		"orange": _mat(Color(0.94, 0.48, 0.16), 0.4, 0.0, 0.0, null),
		"red": _mat(Color(0.88, 0.22, 0.16), 0.4, 0.0, 0.0, null),
		"ring": _mat(accent, 0.5, 0.0, 0.2, null),
		"plinth": _mat(Color(0.30, 0.31, 0.33), 0.7, 0.0, 0.0, null),
		# the body colour with the screws and the matte gone: what the suit
		# becomes when it runs — drips, lake, and the pour that swallows the legs
		"pour": _mat(body, 0.22, 0.0, 0.8, null),
	}
	var red_mat: StandardMaterial3D = _m(c, "red")
	red_mat.emission_enabled = true
	red_mat.emission = Color(0.6, 0.1, 0.05)

	# --- plinth ---------------------------------------------------------
	var plinth := CylinderMesh.new()
	plinth.top_radius = 0.40
	plinth.bottom_radius = 0.42
	plinth.height = PLINTH_H
	_add(c, plinth, _m(c, "plinth"), Transform3D(Basis.IDENTITY, Vector3(0.0, PLINTH_H * 0.5, 0.0)))

	# --- the rig ---------------------------------------------------------
	# Pelvis frame: lean forward about X, twist the shoulders about Y.
	var up_b: Basis = Basis(Vector3.UP, twist) * Basis(Vector3.RIGHT, -lean)
	var up_xf := Transform3D(up_b, Vector3(0.0, 0.92 + PLINTH_H, 0.0))
	# the chest is the point the shed panelling throws every plate away from
	c["hub"] = up_xf * Vector3(0.0, 0.22, 0.0)
	_torso(c, up_xf)

	var head_b: Basis = up_b * Basis(Vector3.UP, head_yaw) * Basis(Vector3.BACK, head_tilt)
	var head_xf := Transform3D(head_b, up_xf * Vector3(0.0, 0.66, 0.0))
	_head(c, head_xf, eye_variant, eye_side)

	for si in range(2):
		var side: float = -1.0 if si == 0 else 1.0
		_leg(c, up_xf, side, side == fwd_side, stride)
		_arm(c, up_xf, side, side != fwd_side)

	# --- what came off the line -----------------------------------------
	match assembly:
		"totem":
			_totem(c, head_xf, eye_variant, eye_side)
		"twinned":
			_twin(c, up_xf, fwd_side)
		"poured":
			_pour(c)

	# the melt needs somewhere to land
	if panelling == "molten":
		_lake(c)

	# --- measured settle: fit, centre on x/z, stand on the floor ---------
	_settle(root)


# ---------------------------------------------------------------------------
# body parts
# ---------------------------------------------------------------------------

static func _torso(c: Dictionary, u: Transform3D) -> void:
	var under: StandardMaterial3D = _m(c, "under")
	var chrome: StandardMaterial3D = _m(c, "chrome")
	# undersuit core: spine capsule, chest capsule, a chest block for the shoulders, pelvis egg
	_capsule_between(c, u * Vector3(0.0, 0.02, 0.0), u * Vector3(0.0, 0.48, 0.0), 0.10, under)
	_capsule_between(c, u * Vector3(0.0, 0.26, 0.0), u * Vector3(0.0, 0.50, 0.0), 0.12, under)
	_box(c, Vector3(0.30, 0.14, 0.16), under, u * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.40, 0.0)))
	_sphere(c, 0.125, under, u * Transform3D(Basis.from_scale(Vector3(1.1, 0.75, 0.9)), Vector3(0.0, -0.01, 0.0)))
	for si in range(2):
		var side: float = -1.0 if si == 0 else 1.0
		# split pectoral plates, each a bent shell swung 39 degrees off the front
		_plate_bent(c, 0.165, 68.0, 0.21, 0.02, _plate_mat(c), u * Transform3D(Basis(Vector3.UP, PI + side * 0.68), Vector3(0.0, 0.35, -0.01)))
		# pauldron: axis front-to-back, arc facing up and outward, capping the shoulder joint
		var shoulder: Vector3 = Vector3(side * 0.21, 0.46, 0.0)
		var pb: Basis = _basis_yz(Vector3(0.0, 0.0, 1.0), Vector3(side * 0.55, 0.83, 0.0))
		_plate_bent(c, 0.105, 115.0, 0.15, 0.02, _plate_mat(c), u * Transform3D(pb, shoulder + Vector3(side * 0.005, 0.0, 0.0)))
		# hip skirt
		_plate_bent(c, 0.155, 80.0, 0.13, 0.018, _plate_mat(c), u * Transform3D(Basis(Vector3.UP, side * PI * 0.5), Vector3(0.0, -0.02, 0.0)))
		# abdomen side bands, staggered against the front rows
		for row in range(2):
			var yy: float = 0.10 + 0.07 * float(row)
			_plate_bent(c, 0.118, 58.0, 0.05, 0.014, _plate_mat(c), u * Transform3D(Basis(Vector3.UP, side * PI * 0.5), Vector3(0.0, yy, 0.0)))
	# back plate and the collar behind the neck
	_plate_bent(c, 0.15, 120.0, 0.24, 0.02, _plate_mat(c), u * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.33, 0.0)))
	_plate_bent(c, 0.075, 170.0, 0.045, 0.012, _plate_mat(c), u * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.515, 0.0)))
	# abdomen front bands
	for row in range(3):
		var yy2: float = 0.08 + 0.07 * float(row)
		_plate_bent(c, 0.118, 95.0, 0.052, 0.014, _plate_mat(c), u * Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, yy2, 0.0)))
	# codpiece and the back of the pelvis
	_plate_bent(c, 0.15, 55.0, 0.11, 0.018, _plate_mat(c), u * Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, -0.03, 0.0)))
	_plate_bent(c, 0.15, 70.0, 0.10, 0.018, _plate_mat(c), u * Transform3D(Basis.IDENTITY, Vector3(0.0, -0.03, 0.0)))
	# neck: chrome column with a ring in the accent colour at its base
	_cyl_between(c, u * Vector3(0.0, 0.49, 0.0), u * Vector3(0.0, 0.60, 0.0), 0.035, chrome)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.03
	ring.outer_radius = 0.05
	_add(c, ring, _m(c, "ring"), u * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.505, 0.0)))


static func _head(c: Dictionary, hx: Transform3D, eye_variant: int, eye_side: float) -> void:
	var plate: StandardMaterial3D = _m(c, "plate")
	var chrome: StandardMaterial3D = _m(c, "chrome")
	var dark: StandardMaterial3D = _m(c, "dark")
	# the dome: an egg
	_sphere(c, 0.115, plate, hx * Transform3D(Basis.from_scale(Vector3(0.92, 1.15, 1.0)), Vector3(0.0, 0.01, 0.0)))
	# faceplate and chin band, both bent shells facing forward (-Z)
	_plate_bent(c, 0.13, 105.0, 0.13, 0.014, plate, hx * Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, -0.01, 0.0)))
	_plate_bent(c, 0.088, 90.0, 0.04, 0.012, plate, hx * Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, -0.10, 0.0)))
	# chrome ear discs
	for si in range(2):
		var side: float = -1.0 if si == 0 else 1.0
		var ear := CylinderMesh.new()
		ear.top_radius = 0.026
		ear.bottom_radius = 0.026
		ear.height = 0.014
		_add(c, ear, chrome, hx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * 0.108, 0.0, 0.0)))
	if eye_variant == 0:
		# the mint robot's slit: dark band, white segment, orange segment, red button
		_box(c, Vector3(0.12, 0.024, 0.012), dark, hx * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.015, -0.138)))
		_box(c, Vector3(0.055, 0.016, 0.014), _m(c, "white"), hx * Transform3D(Basis.IDENTITY, Vector3(-0.022, 0.015, -0.139)))
		_box(c, Vector3(0.03, 0.016, 0.014), _m(c, "orange"), hx * Transform3D(Basis.IDENTITY, Vector3(0.036, 0.015, -0.139)))
		_sphere(c, 0.008, _m(c, "red"), hx * Transform3D(Basis.IDENTITY, Vector3(0.0, -0.03, -0.136)))
	else:
		# the violet robot's single round eye: chrome ring around a dark disc, button on the other cheek
		var eye_xf: Transform3D = hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(eye_side * 0.03, 0.02, -0.135))
		var ring := TorusMesh.new()
		ring.inner_radius = 0.016
		ring.outer_radius = 0.03
		_add(c, ring, chrome, eye_xf)
		var disc := CylinderMesh.new()
		disc.top_radius = 0.02
		disc.bottom_radius = 0.02
		disc.height = 0.012
		_add(c, disc, dark, eye_xf)
		_sphere(c, 0.008, _m(c, "red"), hx * Transform3D(Basis.IDENTITY, Vector3(-eye_side * 0.03, -0.02, -0.136)))


static func _leg(c: Dictionary, u: Transform3D, side: float, forward: bool, stride: float) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var under: StandardMaterial3D = _m(c, "under")
	var chrome: StandardMaterial3D = _m(c, "chrome")
	var gap: float = c["gap"]
	var hip: Vector3 = u * Vector3(side * 0.10, -0.02, 0.0)
	var ankle: Vector3 = Vector3.ZERO
	var foot_b: Basis = Basis.IDENTITY
	var foot_centre: Vector3 = Vector3.ZERO
	if forward:
		# planted flat, toes a touch out
		foot_b = Basis(Vector3.UP, side * 0.08)
		ankle = Vector3(side * 0.10, PLINTH_H + 0.10, -stride)
		foot_centre = ankle + foot_b * Vector3(0.0, -0.07, -0.05)
	else:
		# pushing off: the foot pivots about its toe edge and the heel lifts
		var pitch: float = deg_to_rad(rng.randf_range(18.0, 30.0))
		foot_b = Basis(Vector3.RIGHT, -pitch)
		var toe: Vector3 = Vector3(side * 0.10, PLINTH_H, stride - 0.17)
		ankle = toe + foot_b * Vector3(0.0, 0.10, 0.175)
		foot_centre = toe + foot_b * Vector3(0.0, 0.03, 0.125)
	var knee: Vector3 = (hip + ankle) * 0.5 + Vector3(0.0, 0.02, -0.06)

	_sphere(c, 0.07, chrome, Transform3D(Basis.IDENTITY, hip))
	_capsule_between(c, hip, knee, 0.075, under)
	_plates_around(c, hip, knee, 0.075, 3, 95.0, 0.68, 0.018, true)
	_sphere(c, 0.06, chrome, Transform3D(Basis.IDENTITY, knee))
	_capsule_between(c, knee, ankle, 0.055, under)
	_plates_around(c, knee, ankle, 0.055, 4, 90.0, 0.72, 0.016, false)
	_sphere(c, 0.045, chrome, Transform3D(Basis.IDENTITY, ankle))
	# kneecap: a flat plate floating in front of the knee sphere
	var leg_dir: Vector3 = (hip - ankle).normalized()
	var kb: Basis = _basis_yz(leg_dir, Vector3(0.0, 0.0, -1.0))
	_plate_box(c, Vector3(0.10, 0.085, 0.016), _plate_mat(c), Transform3D(kb, knee + kb.z * (0.06 + gap + 0.008)))
	# foot: undersuit block, bent toe cap, flat heel plate
	_box(c, Vector3(0.10, 0.06, 0.25), under, Transform3D(foot_b, foot_centre))
	var cap_b: Basis = foot_b * _basis_yz(Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.7, -0.7))
	_plate_bent(c, 0.062, 110.0, 0.11, 0.014, _plate_mat(c), Transform3D(cap_b, foot_centre + foot_b * Vector3(0.0, -0.012, -0.075)))
	_plate_box(c, Vector3(0.10, 0.05, 0.016), _plate_mat(c), Transform3D(foot_b, foot_centre + foot_b * Vector3(0.0, 0.012, 0.135)))


static func _arm(c: Dictionary, u: Transform3D, side: float, forward: bool) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var under: StandardMaterial3D = _m(c, "under")
	var chrome: StandardMaterial3D = _m(c, "chrome")
	var gap: float = c["gap"]
	var sw: float = deg_to_rad(rng.randf_range(22.0, 30.0)) if forward else deg_to_rad(rng.randf_range(-24.0, -14.0))
	var bend: float = deg_to_rad(rng.randf_range(50.0, 64.0)) if forward else deg_to_rad(rng.randf_range(15.0, 30.0))
	var shoulder: Vector3 = u * Vector3(side * 0.21, 0.46, 0.0)
	var upper_dir: Vector3 = u.basis * (Basis(Vector3.RIGHT, sw) * Vector3(side * 0.14, -1.0, 0.0).normalized())
	var elbow: Vector3 = shoulder + upper_dir * 0.30
	var fore_dir: Vector3 = u.basis * (Basis(Vector3.RIGHT, sw + bend) * Vector3(side * 0.03, -1.0, 0.0).normalized())
	var wrist: Vector3 = elbow + fore_dir * 0.26

	_sphere(c, 0.055, chrome, Transform3D(Basis.IDENTITY, shoulder))
	_capsule_between(c, shoulder, elbow, 0.045, under)
	_plates_around(c, shoulder, elbow, 0.045, 3, 100.0, 0.64, 0.016, true)
	_sphere(c, 0.045, chrome, Transform3D(Basis.IDENTITY, elbow))
	_capsule_between(c, elbow, wrist, 0.04, under)
	_plates_around(c, elbow, wrist, 0.04, 4, 90.0, 0.70, 0.014, false)
	_cyl_between(c, wrist - fore_dir * 0.025, wrist + fore_dir * 0.025, 0.034, chrome)
	# hand: palm block, a plate on its back, curled fingers, a thumb
	var hand_b: Basis = _basis_yz(fore_dir, Vector3(-side, 0.0, 0.0))
	var palm_c: Vector3 = wrist + fore_dir * 0.075
	_box(c, Vector3(0.075, 0.10, 0.035), under, Transform3D(hand_b, palm_c))
	_plate_box(c, Vector3(0.068, 0.085, 0.012), _plate_mat(c), Transform3D(hand_b, palm_c - hand_b.z * (0.0175 + gap)))
	var curl: float = deg_to_rad(rng.randf_range(22.0, 42.0))
	var finger_b: Basis = hand_b * Basis(Vector3.RIGHT, curl)
	var palm_end: Vector3 = wrist + fore_dir * 0.125
	_box(c, Vector3(0.07, 0.075, 0.03), under, Transform3D(finger_b, palm_end + finger_b.y * 0.037))
	var thumb_b: Basis = hand_b * Basis(Vector3.BACK, side * 0.6)
	_box(c, Vector3(0.028, 0.06, 0.028), under, Transform3D(thumb_b, wrist + fore_dir * 0.07 + hand_b.x * (side * 0.045)))


# ---------------------------------------------------------------------------
# plates
# ---------------------------------------------------------------------------

## Places `count` plates around the limb segment a->b, each `gap` off the limb
## surface. Bent plates are curved shells centred on the axis; flat plates are
## boxes tangent to it. Each plate takes its own length, shift and colour from
## the generator.
static func _plates_around(c: Dictionary, a: Vector3, b: Vector3, radius: float, count: int, arc_deg: float, len_frac: float, thickness: float, bent: bool) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var gap: float = c["gap"]
	var axis_b: Basis = _basis_y(b - a)
	var seg_len: float = a.distance_to(b)
	var phase: float = rng.randf_range(0.0, TAU)
	var mid: Vector3 = (a + b) * 0.5
	var r: float = radius + gap + thickness * 0.5
	for k in range(count):
		var ang: float = phase + TAU * float(k) / float(count)
		var frac: float = len_frac * rng.randf_range(0.8, 1.0)
		var shift: float = seg_len * rng.randf_range(-0.08, 0.08)
		var plate_len: float = seg_len * frac
		var centre: Vector3 = mid + axis_b.y * shift
		var yaw: Basis = Basis(Vector3.UP, PI * 0.5 - ang)
		var mat: StandardMaterial3D = _plate_mat(c)
		if bent:
			_plate_bent(c, r, arc_deg, plate_len, thickness, mat, Transform3D(axis_b * yaw, centre))
		else:
			var width: float = 2.0 * (radius + gap) * tan(deg_to_rad(arc_deg) * 0.5) * 0.92
			var radial: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
			var pos: Vector3 = centre + axis_b * (radial * r)
			_plate_box(c, Vector3(width, plate_len, thickness), mat, Transform3D(axis_b * yaw, pos))


# ---------------------------------------------------------------------------
# AXIS 1 — panelling. Every armour plate in the body, torso, helmet, limbs and
# the twin's suit alike, is emitted through these two doors, so one word rewrites
# the whole suit. `floating` takes the original path and draws no extra numbers
# from the generator, which is what keeps the default statue byte-identical.
# ---------------------------------------------------------------------------

static func _plate_bent(c: Dictionary, radius: float, arc_deg: float, height: float, thickness: float, mat: StandardMaterial3D, xf: Transform3D) -> void:
	var mode: String = c["panelling"]
	if mode == "floating":
		_bent(c, radius, arc_deg, height, thickness, mat, xf)
		return
	var rng: RandomNumberGenerator = c["rng"]
	if mode == "shed":
		_bent(c, radius, arc_deg, height, thickness, mat, _shed_xf(c, xf, maxf(height, radius)))
	elif mode == "swarmed":
		var shards: int = c["shards"]
		for _k in range(shards):
			var f: float = rng.randf_range(0.30, 0.46)
			_bent(c, radius, arc_deg * f + 8.0, height * f, thickness * 0.9, mat, _scatter_xf(c, xf, maxf(height, radius * 0.7)))
	elif mode == "ribbed":
		# only the two rims survive: the shell becomes a pair of hoops
		var rib_h: float = maxf(thickness * 1.5, 0.010)
		for k in range(2):
			var sgn: float = -1.0 if k == 0 else 1.0
			var off: float = height * 0.42 * sgn
			_bent(c, radius, arc_deg, rib_h, thickness * 1.4, mat, Transform3D(xf.basis, xf.origin + xf.basis.y * off))
	elif mode == "molten":
		# the plate lets go of its mounting and hangs
		var sag: float = deg_to_rad(rng.randf_range(24.0, 58.0))
		var mb: Basis = xf.basis * Basis(Vector3.RIGHT, sag)
		var mo: Vector3 = xf.origin + Vector3(0.0, -height * 0.30, 0.0)
		_bent(c, radius, arc_deg, height * 1.25, thickness, mat, Transform3D(mb, mo))
		if rng.randf() < 0.55:
			_drip(c, mo + Vector3(0.0, -height * 0.55, 0.0), thickness)
	else:
		# an unspoken value falls back to the suit as built, so a typo photographs
		# as an inert frame rather than quietly wearing another value's clothes
		_bent(c, radius, arc_deg, height, thickness, mat, xf)


static func _plate_box(c: Dictionary, dims: Vector3, mat: StandardMaterial3D, xf: Transform3D) -> void:
	var mode: String = c["panelling"]
	if mode == "floating":
		_box(c, dims, mat, xf)
		return
	var rng: RandomNumberGenerator = c["rng"]
	if mode == "shed":
		_box(c, dims, mat, _shed_xf(c, xf, maxf(dims.x, dims.y)))
	elif mode == "swarmed":
		var shards: int = c["shards"]
		for _k in range(shards):
			var f: float = rng.randf_range(0.30, 0.46)
			_box(c, Vector3(dims.x * f, dims.y * f, dims.z * 0.9), mat, _scatter_xf(c, xf, maxf(dims.x, dims.y)))
	elif mode == "ribbed":
		var bar_w: float = maxf(dims.x * 0.17, 0.008)
		for k in range(2):
			var sgn: float = -1.0 if k == 0 else 1.0
			var off: float = dims.x * 0.42 * sgn
			_box(c, Vector3(bar_w, dims.y, dims.z * 1.25), mat, Transform3D(xf.basis, xf.origin + xf.basis.x * off))
	elif mode == "molten":
		var sag: float = deg_to_rad(rng.randf_range(22.0, 55.0))
		var mb: Basis = xf.basis * Basis(Vector3.RIGHT, sag)
		var mo: Vector3 = xf.origin + Vector3(0.0, -dims.y * 0.28, 0.0)
		_box(c, Vector3(dims.x, dims.y * 1.30, dims.z), mat, Transform3D(mb, mo))
		if rng.randf() < 0.55:
			_drip(c, mo + Vector3(0.0, -dims.y * 0.60, 0.0), dims.z)
	else:
		_box(c, dims, mat, xf)


## Blow one plate outward along the line from the chest through its own centre,
## and let it tumble. The downward component is clipped so a shed foot plate does
## not dig under the plinth and lift the whole statue off it in the settle.
static func _shed_xf(c: Dictionary, xf: Transform3D, span: float) -> Transform3D:
	var rng: RandomNumberGenerator = c["rng"]
	var hub: Vector3 = c["hub"]
	var away: Vector3 = xf.origin - hub
	if away.length_squared() < 0.0001:
		away = Vector3(0.0, 1.0, 0.0)
	away = away.normalized()
	var push: float = 0.085 + span * 0.35 + rng.randf_range(0.0, 0.075)
	var off: Vector3 = away * push
	off.y = maxf(off.y, -0.055)
	return Transform3D(_tumble(rng, 0.45) * xf.basis, xf.origin + off)


## One flake of a swarmed plate: a small displacement on a sphere around where
## the plate used to be, and a free rotation.
static func _scatter_xf(c: Dictionary, xf: Transform3D, span: float) -> Transform3D:
	var rng: RandomNumberGenerator = c["rng"]
	var d: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	if d.length_squared() < 0.0001:
		d = Vector3(0.0, 1.0, 0.0)
	d = d.normalized()
	var reach: float = 0.02 + span * rng.randf_range(0.25, 1.15)
	var off: Vector3 = d * reach
	off.y = maxf(off.y, -0.05)
	return Transform3D(_tumble(rng, PI) * xf.basis, xf.origin + off)


static func _tumble(rng: RandomNumberGenerator, amount: float) -> Basis:
	var ax: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	if ax.length_squared() < 0.0001:
		ax = Vector3(0.0, 1.0, 0.0)
	return Basis(ax.normalized(), rng.randf_range(-amount, amount))


## A tapering run of the body colour hanging straight down in world space. It is
## cut short near the floor so the drips land in the lake instead of below it.
static func _drip(c: Dictionary, top: Vector3, girth: float) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var room: float = maxf(top.y - (PLINTH_H + 0.012), 0.02)
	var ln: float = clampf(rng.randf_range(0.05, 0.20), 0.02, room)
	var r0: float = maxf(girth * 0.75, 0.010)
	var cone := CylinderMesh.new()
	cone.top_radius = r0
	cone.bottom_radius = r0 * 0.22
	cone.height = ln
	cone.radial_segments = 8
	cone.rings = 1
	_add(c, cone, _m(c, "pour"), Transform3D(Basis.IDENTITY, top + Vector3(0.0, -ln * 0.5, 0.0)))


## What the molten suit has run into: a lake of the body's colour on the plinth,
## with a few tongues of it creeping outward.
static func _lake(c: Dictionary) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var pour: StandardMaterial3D = _m(c, "pour")
	var pool := CylinderMesh.new()
	pool.top_radius = 0.40
	pool.bottom_radius = 0.46
	pool.height = 0.035
	pool.radial_segments = 32
	_add(c, pool, pour, Transform3D(Basis.IDENTITY, Vector3(0.0, PLINTH_H + 0.015, 0.0)))
	for i in range(4):
		var a: float = TAU * float(i) * 0.25 + rng.randf_range(-0.4, 0.4)
		var rr: float = rng.randf_range(0.24, 0.40)
		var blob_r: float = rng.randf_range(0.05, 0.10)
		_sphere(c, blob_r, pour, Transform3D(Basis.from_scale(Vector3(1.0, 0.28, 1.0)), Vector3(cos(a) * rr, PLINTH_H + 0.018, sin(a) * rr)))


# ---------------------------------------------------------------------------
# AXIS 2 — assembly. Three ways the line can get the body wrong.
# ---------------------------------------------------------------------------

## totem: the neck keeps going. Two more helmets, each smaller and turned
## further off the last, with a chrome collar between them, and a fan of thin
## blades standing off the topmost crown.
static func _totem(c: Dictionary, hx: Transform3D, eye_variant: int, eye_side: float) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var chrome: StandardMaterial3D = _m(c, "chrome")
	var lvl: Transform3D = hx
	for i in range(2):
		# the collar the next head sits on; lvl.basis already carries the level's
		# scale, so the disc is written at its own size and shrinks with the stack
		var disc := CylinderMesh.new()
		disc.top_radius = 0.085
		disc.bottom_radius = 0.105
		disc.height = 0.030
		_add(c, disc, chrome, Transform3D(lvl.basis, lvl * Vector3(0.0, 0.135, 0.0)))
		var nb: Basis = lvl.basis * Basis(Vector3.UP, rng.randf_range(-1.15, 1.15)) * Basis(Vector3.BACK, rng.randf_range(-0.14, 0.14)) * Basis.from_scale(Vector3(0.76, 0.76, 0.76))
		lvl = Transform3D(nb, lvl * Vector3(0.0, 0.180, 0.0))
		var ev: int = (eye_variant + i + 1) % 2
		_head(c, lvl, ev, -eye_side)
	var blades: int = rng.randi_range(7, 9)
	var base: Vector3 = lvl * Vector3(0.0, 0.100, 0.0)
	for b in range(blades):
		var ang: float = TAU * float(b) / float(blades)
		var bb: Basis = lvl.basis * Basis(Vector3.UP, ang) * Basis(Vector3.RIGHT, deg_to_rad(-26.0))
		_bent(c, 0.05, 44.0, 0.28, 0.012, _plate_mat(c), Transform3D(bb, base + bb.y * 0.16))


## twinned: a second suit budding out of the back, facing the other way, its head
## rising past the host's — legless, because a bud has no floor to stand on.
##
## The scale stays near 1.0 on purpose. A plate transform inherits this basis and
## shrinks with it, but _capsule_between and _cyl_between build the undersuit from
## absolute radii and do not, so below about k = 0.85 the abdomen bands (r 0.118)
## sink inside the spine capsule (r 0.10) and the twin photographs as a bare
## undersuit wearing nothing. The twin is told apart by its facing and its lean.
static func _twin(c: Dictionary, u: Transform3D, side: float) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var k: float = rng.randf_range(0.90, 1.00)
	var yaw: float = PI + rng.randf_range(-0.30, 0.30)
	var pitch: float = deg_to_rad(rng.randf_range(10.0, 26.0))
	var tb: Basis = u.basis * Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis.from_scale(Vector3(k, k, k))
	var tu := Transform3D(tb, u * Vector3(side * 0.09, 0.24, 0.17))
	_torso(c, tu)
	var thb: Basis = tb * Basis(Vector3.UP, rng.randf_range(-0.50, 0.50)) * Basis(Vector3.BACK, rng.randf_range(-0.18, 0.18))
	_head(c, Transform3D(thb, tu * Vector3(0.0, 0.66, 0.0)), 1, 1.0)
	_arm(c, tu, -1.0, true)
	_arm(c, tu, 1.0, false)


## poured: the walk is over. A glossy cone of the body's own colour has risen to
## the hip and taken the legs; the robot stands in the lake it came out of.
static func _pour(c: Dictionary) -> void:
	var rng: RandomNumberGenerator = c["rng"]
	var pour: StandardMaterial3D = _m(c, "pour")
	var top_y: float = rng.randf_range(0.72, 0.84)
	var neck_r: float = rng.randf_range(0.17, 0.22)
	var cone := CylinderMesh.new()
	cone.top_radius = neck_r
	cone.bottom_radius = rng.randf_range(0.40, 0.46)
	cone.height = top_y - PLINTH_H
	cone.radial_segments = 30
	_add(c, cone, pour, Transform3D(Basis.IDENTITY, Vector3(0.0, PLINTH_H + cone.height * 0.5, 0.0)))
	var pool := CylinderMesh.new()
	pool.top_radius = 0.46
	pool.bottom_radius = 0.50
	pool.height = 0.040
	pool.radial_segments = 32
	_add(c, pool, pour, Transform3D(Basis.IDENTITY, Vector3(0.0, PLINTH_H + 0.020, 0.0)))
	var lip := TorusMesh.new()
	lip.inner_radius = neck_r * 0.86
	lip.outer_radius = neck_r * 1.32
	_add(c, lip, pour, Transform3D(Basis.IDENTITY, Vector3(0.0, top_y, 0.0)))
	for i in range(3):
		var a: float = TAU * float(i) / 3.0 + rng.randf_range(-0.5, 0.5)
		var rr: float = rng.randf_range(0.28, 0.42)
		var blob_r: float = rng.randf_range(0.06, 0.11)
		_sphere(c, blob_r, pour, Transform3D(Basis.from_scale(Vector3(1.0, 0.26, 1.0)), Vector3(cos(a) * rr, PLINTH_H + 0.022, sin(a) * rr)))


static func _plate_mat(c: Dictionary) -> StandardMaterial3D:
	var rng: RandomNumberGenerator = c["rng"]
	var chance: float = c["second_chance"]
	if rng.randf() < chance:
		return _m(c, "plate2")
	return _m(c, "plate")


## A curved shell: axis along local Y, arc centred on local +Z, closed on all
## six sides. Outer and inner faces are smooth-shaded, the rims flat.
static func _bent_plate_mesh(radius: float, arc: float, height: float, thickness: float, segs: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r_out: float = radius + thickness * 0.5
	var r_in: float = maxf(radius - thickness * 0.5, 0.001)
	var y0: float = -height * 0.5
	var y1: float = height * 0.5
	var u_rep: float = maxf(radius * arc / 0.10, 0.25)
	var v_rep: float = maxf(height / 0.10, 0.25)
	for i in range(segs):
		var a0: float = -arc * 0.5 + arc * float(i) / float(segs)
		var a1: float = -arc * 0.5 + arc * float(i + 1) / float(segs)
		var u0: float = u_rep * float(i) / float(segs)
		var u1: float = u_rep * float(i + 1) / float(segs)
		var d0: Vector3 = Vector3(sin(a0), 0.0, cos(a0))
		var d1: Vector3 = Vector3(sin(a1), 0.0, cos(a1))
		var mid_dir: Vector3 = (d0 + d1).normalized()
		var o00: Vector3 = d0 * r_out + Vector3(0.0, y0, 0.0)
		var o01: Vector3 = d0 * r_out + Vector3(0.0, y1, 0.0)
		var o10: Vector3 = d1 * r_out + Vector3(0.0, y0, 0.0)
		var o11: Vector3 = d1 * r_out + Vector3(0.0, y1, 0.0)
		var i00: Vector3 = d0 * r_in + Vector3(0.0, y0, 0.0)
		var i01: Vector3 = d0 * r_in + Vector3(0.0, y1, 0.0)
		var i10: Vector3 = d1 * r_in + Vector3(0.0, y0, 0.0)
		var i11: Vector3 = d1 * r_in + Vector3(0.0, y1, 0.0)
		st.set_smooth_group(0)
		_quad(st, o00, o01, o11, o10, mid_dir, Vector2(u0, v_rep), Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, v_rep))
		_quad(st, i00, i01, i11, i10, -mid_dir, Vector2(u0, v_rep), Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, v_rep))
		st.set_smooth_group(-1)
		_quad(st, o01, o11, i11, i01, Vector3.UP, Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 0.1), Vector2(u0, 0.1))
		_quad(st, o00, o10, i10, i00, Vector3.DOWN, Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 0.1), Vector2(u0, 0.1))
	# the two end rims
	var a_lo: float = -arc * 0.5
	var a_hi: float = arc * 0.5
	var d_lo: Vector3 = Vector3(sin(a_lo), 0.0, cos(a_lo))
	var d_hi: Vector3 = Vector3(sin(a_hi), 0.0, cos(a_hi))
	var out_lo: Vector3 = Vector3(-cos(a_lo), 0.0, sin(a_lo))
	var out_hi: Vector3 = Vector3(cos(a_hi), 0.0, -sin(a_hi))
	st.set_smooth_group(-1)
	_quad(st,
		d_lo * r_out + Vector3(0.0, y0, 0.0), d_lo * r_out + Vector3(0.0, y1, 0.0),
		d_lo * r_in + Vector3(0.0, y1, 0.0), d_lo * r_in + Vector3(0.0, y0, 0.0),
		out_lo, Vector2(0.0, v_rep), Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.1, v_rep))
	_quad(st,
		d_hi * r_out + Vector3(0.0, y0, 0.0), d_hi * r_out + Vector3(0.0, y1, 0.0),
		d_hi * r_in + Vector3(0.0, y1, 0.0), d_hi * r_in + Vector3(0.0, y0, 0.0),
		out_hi, Vector2(0.0, v_rep), Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.1, v_rep))
	st.generate_normals()
	return st.commit()


## Two triangles for a planar quad. Godot's front faces wind clockwise, so the
## face normal of (p0, p1, p2) is (p2 - p0) x (p1 - p0); if that points against
## `outward` the order is reversed. The quad is never emitted inside-out.
static func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, outward: Vector3, t0: Vector2, t1: Vector2, t2: Vector2, t3: Vector2) -> void:
	var n: Vector3 = (p2 - p0).cross(p1 - p0)
	if n.dot(outward) < 0.0:
		_tri(st, p0, p3, p2, t0, t3, t2)
		_tri(st, p0, p2, p1, t0, t2, t1)
	else:
		_tri(st, p0, p1, p2, t0, t1, t2)
		_tri(st, p0, p2, p3, t0, t2, t3)


static func _tri(st: SurfaceTool, pa: Vector3, pb: Vector3, pc: Vector3, ta: Vector2, tb: Vector2, tc: Vector2) -> void:
	st.set_uv(ta)
	st.add_vertex(pa)
	st.set_uv(tb)
	st.add_vertex(pb)
	st.set_uv(tc)
	st.add_vertex(pc)


# ---------------------------------------------------------------------------
# primitives, materials, frames
# ---------------------------------------------------------------------------

static func _add(c: Dictionary, mesh: Mesh, mat: Material, xf: Transform3D) -> MeshInstance3D:
	var root: Node3D = c["root"]
	if root.get_child_count() >= MESH_CAP:
		return null
	var s: float = c["s"]
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(xf.basis.scaled(Vector3(s, s, s)), xf.origin * s)
	root.add_child(mi)
	return mi


static func _m(c: Dictionary, key: String) -> StandardMaterial3D:
	return c[key]


static func _mat(col: Color, rough: float, metal: float, clear: float, tex: ImageTexture) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if clear > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = clear
		m.clearcoat_roughness = 0.3
	if tex != null:
		m.albedo_texture = tex
	return m


## Two to four dark screw heads on white; the plate colour multiplies it.
static func _screw_texture(rng: RandomNumberGenerator) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(1.0, 1.0, 1.0))
	var n: int = rng.randi_range(2, 4)
	for _i in range(n):
		var cx: int = rng.randi_range(8, 55)
		var cy: int = rng.randi_range(8, 55)
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var d2: int = dx * dx + dy * dy
				if d2 <= 9:
					var shade: float = 0.22 if d2 <= 4 else 0.62
					img.set_pixel(cx + dx, cy + dy, Color(shade, shade, shade))
	return ImageTexture.create_from_image(img)


static func _box(c: Dictionary, dims: Vector3, mat: Material, xf: Transform3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dims
	_add(c, mesh, mat, xf)


static func _sphere(c: Dictionary, radius: float, mat: Material, xf: Transform3D) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	_add(c, mesh, mat, xf)


static func _capsule_between(c: Dictionary, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(a.distance_to(b), radius * 2.0)
	_add(c, mesh, mat, Transform3D(_basis_y(b - a), (a + b) * 0.5))


static func _cyl_between(c: Dictionary, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(a.distance_to(b), 0.001)
	_add(c, mesh, mat, Transform3D(_basis_y(b - a), (a + b) * 0.5))


static func _bent(c: Dictionary, radius: float, arc_deg: float, height: float, thickness: float, mat: Material, xf: Transform3D) -> void:
	var segs: int = maxi(4, int(arc_deg / 12.0))
	var mesh: ArrayMesh = _bent_plate_mesh(radius, deg_to_rad(arc_deg), height, thickness, segs)
	_add(c, mesh, mat, xf)


## Right-handed orthonormal basis with Y along `y_dir` and Z as close to
## `z_hint` as the axis allows.
static func _basis_yz(y_dir: Vector3, z_hint: Vector3) -> Basis:
	var ay: Vector3 = y_dir.normalized()
	var az: Vector3 = z_hint - ay * ay.dot(z_hint)
	if az.length_squared() < 0.000001:
		var alt: Vector3 = Vector3(0.0, 0.0, 1.0) if absf(ay.z) < 0.9 else Vector3(1.0, 0.0, 0.0)
		az = alt - ay * ay.dot(alt)
	az = az.normalized()
	var ax: Vector3 = ay.cross(az)
	return Basis(ax, ay, az)


static func _basis_y(dir: Vector3) -> Basis:
	var hint: Vector3 = Vector3(0.0, 0.0, 1.0)
	if absf(dir.normalized().z) > 0.9:
		hint = Vector3(1.0, 0.0, 0.0)
	return _basis_yz(dir, hint)


# ---------------------------------------------------------------------------
# the measured settle
# ---------------------------------------------------------------------------

## Fit the built body into 1.20 x 1.20 x 1.68, centre it on x/z, and stand its
## lowest point on y = 0. Shrinking only: a body that already fits is scaled by
## 1.0. This is what lets a shed cloud, a molten lake or a three-headed totem
## blow past the walker's envelope and still come back onto the plinth.
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
			var mi: MeshInstance3D = ch
			var tf: Transform3D = mi.transform
			mi.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		mi.transform = Transform3D(mi.transform.basis, mi.transform.origin + shift)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		if mi.mesh == null:
			continue
		var wb: AABB = mi.transform * mi.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
