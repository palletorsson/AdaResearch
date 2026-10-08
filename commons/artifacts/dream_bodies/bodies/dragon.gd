extends RefCounted

## dream_bodies / dragon — one pastel ceramic garden dragon, rearing.
##
## Reference: scratchpad/refs/dragon.png (2048x536 panorama) — a row of glazed
## ceramic dragons in lavender, teal-to-blue, cream-pink and periwinkle, each
## standing on its hind legs with the forelegs held up in front of the chest,
## the neck rising in an S to an open toothed jaw, ridged bat wings folded up
## and back, hexagonal scale skins with a lighter belly, and a tail that rests
## on the ground and curls up at the tip.
##
## Reproduced, and how:
##   1. The rearing S-spine — 16..22 SphereMesh segments placed along a curve
##      integrated from a keyed lean angle (hips lean forward, chest straightens,
##      neck leans back, head tips forward); radii shrink hips -> neck.
##   2. Hexagonal scales — a 128x128 ImageTexture drawn in code (pointy-top hex
##      lattice, per-cell glaze mottle, groove between scales), tinted per
##      segment so the body carries the reference's top-to-bottom colour drift.
##   3. The pale belly — a second chain of smaller spheres hung on the front of
##      the spine in the belly colour, coarser scale texture.
##   4. Dorsal ridge — a cone (CylinderMesh, top_radius 0) on the back of every
##      body and tail segment, cream glaze.
##   5. Head with open jaw — SphereMesh skull, two tapered-box jaws built with
##      SurfaceTool (flat smooth group), the lower one hinged open 22..34 deg,
##      cone teeth along both jaw edges, glazed dark eyes, two-segment horns,
##      PrismMesh ear frills.
##   6. Bat wings — one arm bone + 5..7 tapering rib cylinders with knob tips,
##      and a SurfaceTool membrane fan (6 rings x 4 sub-steps per sector,
##      scalloped trailing edge, corrugated 4 mm ripple, vertex-colour pastel
##      gradient, alpha 0.7, double sided).
##   7. Hind legs and raised forelegs — CapsuleMesh thigh/shin/foot and
##      upper-arm/forearm with a sphere hand, cone claws; one arm raised higher
##      and one foot forward, chosen by seed.
##   8. Curled tail — 14..18 spheres continuing the chain backward, resting on
##      the plinth, curling up and to one side at the tip.
##
## Given up: the raised wave ridges moulded ON the wing membranes (only a colour
## band + shallow corrugation stands in for them), the neighbouring dragons
## touching each other, the garden, and the shoulder frill / mane spikes.
##
## THE FINISH (2026-09-03). The reference is a garden-centre pastel; the statue is
## not. Every dragon is dealt an outfit from its own seed, in two halves:
##
##   HIDE  — latex, patent, candy, wet or pearl. All five are DreamSkin finishes
##           that leave albedo_texture free, so the hexagon scale map still rides
##           on top of the gloss instead of being replaced by it. Rubber, patent
##           leather, sugar glaze, just-poured water, nacre.
##   EDGE  — oil slick, holographic foil, chrome or neon, on every hard part the
##           ceramic dragon has: dorsal ridge, teeth, horns, claws, tail spikes,
##           wing ribs and rib knobs. These are the finishes that CARRY a painted
##           texture (the iridescent sweep, the brushed streak), so the trim
##           changes hue as you walk past while the hide holds one colour. Neon
##           trim is pulled back to 1.4 energy — a lit tube per tooth blows the
##           frame out. The eyes are neon regardless.
##
## Colours come from DreamSkin's queer palette, pushed ~80% over the reference
## scheme, so the drift hip -> neck, the pale belly and the wing gradient survive
## as STRUCTURE while the hue goes hot pink, acid, cyan, tangerine.
##
## Two passages stay matte on purpose, and the contrast is the argument: the stone
## plinth, and the whole of `kiln = fossil`, where the point IS that the glaze has
## gone — chalk bone standing in a hall of wet-looking bodies.
##
## DNA axes
##   kiln  — what the firing did to the ceramic body itself.
##           glazed (as cast) | molten (every part sags and widens, and the
##           lower third drowns in a solid glass pour with drips hanging off
##           the jaw and wings) | crazed (the whole dragon flies apart, each
##           piece pushed out along its own outward normal and tilted, air
##           between every shard) | fossil (the flesh is gone: the trunk
##           shrinks to vertebra beads, bare rib hoops arc out of the spine,
##           the belly plates and the wing membranes are missing, the limbs
##           are half as thick and the glaze goes to matte bone) | swarm (the
##           biggest masses dissolve, each becoming a cloud of three small
##           copies of itself) | cast (ISO — see below).
##   necks — how many dragons the one statue holds.
##           one (as cast) | twinned (a second neck and head grow backward out
##           of the shoulder blades and look the other way) | hydra (two extra
##           necks fan forward off the upper spine, each with its own smaller
##           horned head) | ouroboros (the trunk rolls over into a closing
##           ring and the tail rises on a bezier to meet the jaw, which has
##           come down to bite it).
##
## kiln = cast — THE POUR, and what it grows.
##   The other four kiln values rearrange a body that was ASSEMBLED: you can see
##   where the sphere ends and the capsule starts. `cast` builds the same dragon
##   as one signed-distance field and marches it. The field is composed out of the
##   very same joints and radii the primitive version uses — the strided spine,
##   the tail chain, both hind legs, both forelegs and both hands, and any extra
##   neck — so the seed still means the same animal; it is only no longer a pile
##   of parts. What the smooth union then buys:
##     · the thighs SWELL into the hips with a fillet, no seam at the shoulder;
##     · a second neck (`twinned`) or a pair of them (`hydra`) grows OUT of the
##       trunk instead of being stuck on it — two heads over one poured shoulder;
##     · with `necks = ouroboros` the trunk rolls into a closing ring and the hole
##       in the middle is not a missing piece: it is a place the field never
##       crossed zero.
##   The head, jaws, teeth, horns, claws, dorsal ridge, tail spikes and both wings
##   stay MOULDED parts stuck onto the pour — which is how a real slip-cast
##   ceramic dragon is made, and which keeps the mesh count honest: a cast dragon
##   renders roughly 95–140 MeshInstance3D (one poured body, ~19 ridge cones, ~9
##   tail spikes, 12 claws, ~27 head parts, 28 wing parts, the plinth), well over
##   the family floor of 40.
##   DreamIso is new. If mesh_of yields nothing, `cast` REPLAYS every primitive it
##   held back — the spine beads, belly plates, tail beads, limb capsules and neck
##   beads are recorded as it goes — so a failed march gives a normal dragon, not
##   an empty plinth.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX_SIZE: int = 128
const PLINTH_TOP: float = 0.06
const ISO_CELL: float = 0.045
const ISO_FLOOR: float = 0.048

## Finishes that leave albedo_texture free, so the scale map survives on the hide.
const SKIN_FINISHES: Array = ["latex", "patent", "candy", "wet", "pearl"]
## Finishes that carry their own painted texture — for the hard trim only.
const TRIM_FINISHES: Array = ["oilslick", "holo", "chrome", "neon"]

# scheme: [hips colour, neck colour, belly, accent, wing inner, wing mid, wing outer, rib]
const SCHEMES: Array = [
	["#A98BD8", "#C4A8E6", "#EEDDF2", "#F4EBDF", "#B9A3E8", "#DCC1EA", "#F1C9DE", "#EAC7E0"],
	["#7FA5DC", "#74CFC2", "#E2F1DB", "#F4EBDF", "#9AD9C9", "#CDEBD1", "#C6BDE8", "#E4F0DC"],
	["#EBD9CF", "#F3E6DE", "#FAF2EC", "#E8C9D5", "#F2CCDC", "#E5C6E6", "#C9C4EA", "#F6E3EA"],
	["#A78FD8", "#86A8E6", "#DAD8F1", "#F4EBDF", "#A9C3EE", "#C4BBEC", "#E6C2E2", "#DDE4F4"],
]


static func describe() -> String:
	return "A high-gloss ceramic garden dragon rearing on its hind legs, forelegs raised, jaw open, hexagon-scaled in latex or patent or oil slick with iridescent teeth and horns, ridged bat wings and a curled tail."


static func axes() -> Dictionary:
	return {
		"kiln": ["glazed", "molten", "crazed", "fossil", "swarm", "cast"],
		"necks": ["one", "twinned", "hydra", "ouroboros"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var kiln: String = String(opts.get("kiln", "glazed"))
	var necks: String = String(opts.get("necks", "one"))
	var is_fossil: bool = kiln == "fossil"
	var is_cast: bool = kiln == "cast"
	var is_ouro: bool = necks == "ouroboros"
	var bone_k: float = 0.5 if is_fossil else 1.0

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the outfit: one gloss for the hide, one for every hard edge ---------
	var finish_body: String = String(SKIN_FINISHES[rng.randi_range(0, SKIN_FINISHES.size() - 1)])
	var finish_trim: String = String(TRIM_FINISHES[rng.randi_range(0, TRIM_FINISHES.size() - 1)])
	# fossil is the one value whose argument is the ABSENCE of glaze
	var finish_flesh: String = "matte" if is_fossil else finish_body
	var finish_edge: String = "matte" if is_fossil else finish_trim
	var finish_eye: String = "matte" if is_fossil else "neon"
	var col_main: Color = Gloss.queer_colour(rng)
	var col_hot: Color = Gloss.queer_colour(rng)
	var col_third: Color = Gloss.queer_colour(rng)
	var cream: Color = Gloss.QUEER["cream"]

	# the reference scheme survives as STRUCTURE — hip -> neck drift, pale belly,
	# wing gradient — with the hue pushed most of the way over to the palette
	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_hip: Color = _c(scheme, 0).lerp(col_main, 0.80)
	var col_neck: Color = _c(scheme, 1).lerp(col_main.lerp(col_hot, 0.45), 0.80)
	var col_belly: Color = _c(scheme, 2).lerp(cream.lerp(col_third, 0.40), 0.72)
	var col_accent: Color = _c(scheme, 3).lerp(col_hot, 0.90)
	var wing_cols: Array = [
		_c(scheme, 4).lerp(col_main, 0.82),
		_c(scheme, 5).lerp(col_third, 0.82),
		_c(scheme, 6).lerp(col_hot, 0.86),
	]
	var col_rib: Color = _c(scheme, 7).lerp(col_hot.lerp(col_main, 0.35), 0.82)
	if is_fossil:
		col_hip = Color("#E9E3D3").lerp(col_main, 0.10)
		col_neck = Color("#F3EEE1").lerp(col_main, 0.08)
		col_belly = Color("#DDD6C5").lerp(col_third, 0.08)
		col_accent = Color("#CEC5AF").lerp(col_hot, 0.10)
		wing_cols = [Color("#E9E3D3"), Color("#DDD6C5"), Color("#CEC5AF")]
		col_rib = Color("#E3DCCA").lerp(col_hot, 0.08)

	var scale_tex: ImageTexture = _scale_texture(rng, 10, 12, 0.86)
	var belly_tex: ImageTexture = _scale_texture(rng, 6, 8, 0.90)
	var mat_accent: StandardMaterial3D = _glaze(finish_edge, col_accent, rng)
	var mat_rib: StandardMaterial3D = _glaze(finish_edge, col_rib, rng)
	if finish_edge == "neon":
		# a lit tube per tooth blows the frame out; the trim glows, it does not burn
		mat_accent.emission_energy_multiplier = 1.4
		mat_rib.emission_energy_multiplier = 1.1
	var mat_belly: StandardMaterial3D = _scaled(_glaze(finish_flesh, col_belly, rng), belly_tex, Vector3(1.0, 1.0, 1.0))
	var mat_eye: StandardMaterial3D = _glaze(finish_eye, col_hot, rng)
	if finish_eye == "neon":
		mat_eye.emission_energy_multiplier = 2.4
	# the matte passage: stone under a wet body
	var mat_plinth: StandardMaterial3D = _glaze("matte", Color("#C9CFC6"), rng)
	mat_plinth.roughness = 0.85

	# the pour's field, and the primitives it holds back in case the march fails
	var iso: Dictionary = {"on": is_cast, "parts": [], "spare": []}
	var iso_parts: Array = iso["parts"]

	# --- individual parameters ---------------------------------------------
	var n_spine: int = rng.randi_range(16, 22)
	var body_k: float = rng.randf_range(0.92, 1.08)
	var lean_x: float = rng.randf_range(-0.12, 0.12)
	var y_hip: float = 0.47
	var y_head_base: float = rng.randf_range(1.38, 1.44)
	var bend_a: float = rng.randf_range(0.55, 0.80)
	var bend_b: float = rng.randf_range(-0.35, -0.15)
	var bend_c: float = rng.randf_range(0.35, 0.60)
	var head_yaw: float = deg_to_rad(rng.randf_range(-14.0, 14.0))
	var jaw_open: float = deg_to_rad(rng.randf_range(22.0, 34.0))
	var raised_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var forward_foot: float = 1.0 if rng.randf() < 0.5 else -1.0
	var tail_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var tail_curl: float = rng.randf_range(2.9, 3.5)
	var n_tail: int = rng.randi_range(14, 18)
	var n_ribs: int = rng.randi_range(5, 7)
	var spread_l: float = deg_to_rad(rng.randf_range(95.0, 120.0))
	var spread_r: float = deg_to_rad(rng.randf_range(95.0, 120.0))
	var wing_lift: float = rng.randf_range(0.20, 0.28)

	# --- axis parameters: extra draws fire ONLY off the default values -------
	var burst: float = 0.0
	var sag: float = 0.0
	var frag_jitter: float = 0.0
	var neck_fan: float = 0.0
	var ouro_span: float = 0.0
	var iso_blend: float = 0.105
	if kiln == "crazed":
		burst = rng.randf_range(0.15, 0.26)
	elif kiln == "molten":
		sag = rng.randf_range(0.30, 0.44)
	elif kiln == "swarm":
		frag_jitter = rng.randf_range(0.85, 1.30)
	elif is_cast:
		# how far the limbs swell into the trunk: the size of the fillet
		iso_blend = rng.randf_range(0.095, 0.145)
	if necks == "hydra":
		neck_fan = rng.randf_range(0.42, 0.62)
	elif necks == "twinned":
		neck_fan = rng.randf_range(0.85, 1.15)
	elif is_ouro:
		ouro_span = rng.randf_range(2.75, 3.05)

	# --- spine: dry run for direction, then scaled to land the head ----------
	var dirs: Array = []
	var rise: float = 0.0
	for i in range(1, n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var a: float = _arc_angle(t, ouro_span) if is_ouro else _spine_angle(t, bend_a, bend_b, bend_c)
		var d: Vector3 = Vector3(lean_x * 0.35 * sin(PI * t), cos(a), -sin(a)).normalized()
		dirs.append(d)
		rise += d.y
	var step: float = (y_head_base - y_hip) / maxf(rise, 0.1)
	if is_ouro:
		# the trunk rolls over instead of rising, so length is set by arc, not height
		step = (1.15 * body_k) / float(n_spine - 1)

	var pts: Array = []
	var radii: Array = []
	var p := Vector3(0.0, y_hip, 0.08)
	pts.append(p)
	radii.append(_r_profile(0.0) * body_k)
	for i in range(1, n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var d: Vector3 = dirs[i - 1]
		p = p + d * step
		pts.append(p)
		radii.append(_r_profile(t) * body_k)

	# body segments, belly plates, dorsal ridge
	for i in range(n_spine):
		var t: float = float(i) / float(n_spine - 1)
		var q: Vector3 = pts[i]
		var r: float = radii[i]
		var tang: Vector3 = _tangent(pts, i)
		var front := Vector3(0.0, tang.z, -tang.y).normalized()
		var mat_body: StandardMaterial3D = _scaled(_glaze(finish_flesh, col_hip.lerp(col_neck, t), rng), scale_tex, Vector3(2.0, 1.0, 1.0))
		var r_draw: float = r * 0.40 if is_fossil else r
		_body_sphere(root, iso, q, _basis_y_to(tang), r_draw, mat_body)
		if t <= 0.78 and not is_fossil:
			# the belly plates dissolve INTO the pour; kept in reserve for the fallback
			_body_sphere(root, iso, q + front * (r * 0.52), _basis_y_to(tang), r * 0.74, mat_belly)
		var spike_h: float = r * (0.55 if t < 0.5 else 0.7)
		if is_fossil:
			spike_h = r * 1.15
		_cone(root, q - front * (r_draw * 0.92), -front, spike_h, r_draw * 0.16, mat_accent)
		if is_fossil and (i % 3) == 1 and t < 0.70:
			# bare rib hoops: the barrel of the chest with nothing on it
			var side_v: Vector3 = tang.cross(front)
			if side_v.length() < 0.001:
				side_v = Vector3.RIGHT
			side_v = side_v.normalized()
			for sgn in [-1.0, 1.0]:
				var sgf: float = sgn
				var out_p: Vector3 = q + side_v * (sgf * r * 1.02) + front * (r * 0.20)
				var low_p: Vector3 = q + front * (r * 1.02) + side_v * (sgf * r * 0.18) - Vector3(0.0, r * 0.34, 0.0)
				_tapered_cyl(root, q, out_p, r * 0.11, r * 0.085, mat_accent)
				_tapered_cyl(root, out_p, low_p, r * 0.085, r * 0.055, mat_accent)

	# the trunk, poured: a handful of capsules whose smooth union is ONE body, so
	# the neck does not start anywhere and the hips do not end
	if is_cast:
		var s_stride: int = maxi(1, int(ceil(float(n_spine - 1) / 6.0)))
		var si: int = 0
		while si < n_spine - 1:
			var sj: int = mini(si + s_stride, n_spine - 1)
			var pa: Vector3 = pts[si]
			var pb: Vector3 = pts[sj]
			var ra: float = maxf(float(radii[si]) * 0.90, ISO_FLOOR)
			var rb: float = maxf(float(radii[sj]) * 0.90, ISO_FLOOR)
			iso_parts.append(Iso.capsule(pa, pb, ra, rb))
			si = sj

	var p_hip: Vector3 = pts[0]
	var r_hip: float = radii[0]
	var p_head_base: Vector3 = pts[n_spine - 1]
	var r_neck_end: float = radii[n_spine - 1]

	# --- tail ---------------------------------------------------------------
	var tail_p: Vector3 = p_hip
	var tail_r: float = r_hip * 0.8
	var tail_len: float = 0.84 * body_k
	var tail_last_dir := Vector3(0.0, 0.0, 1.0)
	# ouroboros: the tail leaves the hips backward, climbs over the back on a
	# bezier and comes down to the head, which is waiting for it with its jaw
	var ouro_ctrl: Vector3 = p_hip + Vector3(tail_side * 0.26, 0.58, 0.72)
	var ouro_end: Vector3 = p_head_base + Vector3(0.0, -0.15, -0.20)
	var tail_pts: Array = []
	var tail_rs: Array = []
	for i in range(1, n_tail + 1):
		var s: float = float(i) / float(n_tail)
		var d: Vector3 = Vector3(0.0, 0.0, 1.0)
		if is_ouro:
			var nx: Vector3 = _bez(p_hip, ouro_ctrl, ouro_end, s)
			var dv: Vector3 = nx - tail_p
			if dv.length() < 0.0001:
				dv = Vector3(0.0, 0.0, 1.0)
			d = dv.normalized()
			tail_p = nx
		else:
			var e: float = -0.7 + tail_curl * pow(s, 1.3)
			var sway: float = tail_side * 0.22 * sin(PI * s) * cos(0.5 * PI * s)
			d = Vector3(sway, sin(e), cos(e)).normalized()
			tail_p = tail_p + d * (tail_len / float(n_tail))
		tail_last_dir = d
		tail_r = lerpf(r_hip * 0.8, 0.028, pow(s, 0.85)) * bone_k
		var ty: float = maxf(tail_p.y, PLINTH_TOP + tail_r)
		tail_p = Vector3(tail_p.x, ty, tail_p.z)
		var mat_tail: StandardMaterial3D = _scaled(_glaze(finish_flesh, col_hip.darkened(0.08 * s), rng), scale_tex, Vector3(2.0, 1.0, 1.0))
		_body_sphere(root, iso, tail_p, _basis_y_to(d), tail_r, mat_tail)
		tail_pts.append(tail_p)
		tail_rs.append(tail_r)
		if i % 2 == 0 and s < 0.9:
			var up_ish := Vector3(0.0, -d.z, d.y).normalized()
			if up_ish.y < 0.0:
				up_ish = -up_ish
			_cone(root, tail_p + up_ish * (tail_r * 0.9), up_ish, tail_r * 0.7, tail_r * 0.18, mat_accent)
	_cone(root, tail_p + tail_last_dir * (tail_r * 0.6), tail_last_dir, 0.075, 0.03, mat_accent)

	# the tail poured as one taper out of the hips — and, when the trunk has
	# rolled into a ring, the closing arm of the hole
	if is_cast:
		var t_stride: int = maxi(1, int(ceil(float(n_tail) / 5.0)))
		var prev_p: Vector3 = p_hip
		var prev_r: float = maxf(r_hip * 0.8, ISO_FLOOR)
		var ti: int = t_stride - 1
		while ti < n_tail:
			var cp: Vector3 = tail_pts[ti]
			var cr: float = maxf(float(tail_rs[ti]), ISO_FLOOR)
			iso_parts.append(Iso.capsule(prev_p, cp, prev_r, cr))
			prev_p = cp
			prev_r = cr
			ti += t_stride
		var last_p: Vector3 = tail_pts[n_tail - 1]
		if prev_p.distance_to(last_p) > 0.001:
			iso_parts.append(Iso.capsule(prev_p, last_p, prev_r, ISO_FLOOR))

	# --- hind legs ----------------------------------------------------------
	var mat_leg: StandardMaterial3D = _scaled(_glaze(finish_flesh, col_hip.lerp(col_neck, 0.1), rng), scale_tex, Vector3(1.0, 1.0, 1.0))
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var fwd: float = 0.045 if sd == forward_foot else -0.02
		var hip := p_hip + Vector3(sd * 0.13 * body_k, -0.05, 0.02)
		var knee := hip + Vector3(sd * 0.05, -0.14, -0.13 + fwd * 0.4)
		var ankle := knee + Vector3(sd * 0.02, -0.17, 0.10 + fwd * 0.3)
		ankle = Vector3(ankle.x, PLINTH_TOP + 0.05, ankle.z)
		var toe := ankle + Vector3(0.0, -0.005, -0.15)
		_body_limb(root, iso, hip, knee, 0.078 * body_k * bone_k, mat_leg)
		_body_limb(root, iso, knee, ankle, 0.056 * body_k * bone_k, mat_leg)
		_body_limb(root, iso, ankle, toe, 0.045 * bone_k, mat_leg)
		for c in range(3):
			var ang: float = (float(c) - 1.0) * 0.5
			var cd: Vector3 = Vector3(sin(ang) * 0.9, -0.35, -cos(ang)).normalized()
			_cone(root, toe + cd * 0.035 + Vector3(0.0, -0.01, 0.0), cd, 0.055, 0.012, mat_accent)

	# --- forelegs, raised ---------------------------------------------------
	var i_chest: int = int(floor(float(n_spine - 1) * 0.42))
	var p_chest: Vector3 = pts[i_chest]
	var r_chest: float = radii[i_chest]
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var lift: float = 0.07 if sd == raised_side else 0.0
		var shoulder := p_chest + Vector3(sd * (r_chest * 0.85), 0.02, -r_chest * 0.25)
		var elbow := shoulder + Vector3(sd * 0.05, -0.16 + lift * 0.3, -0.07)
		var hand := elbow + Vector3(-sd * 0.03, 0.05 + lift, -0.16)
		_body_limb(root, iso, shoulder, elbow, 0.052 * body_k * bone_k, mat_leg)
		_body_limb(root, iso, elbow, hand, 0.040 * body_k * bone_k, mat_leg)
		_body_sphere(root, iso, hand, Basis(), 0.046 * bone_k, mat_leg, true)
		for c in range(3):
			var ang: float = (float(c) - 1.0) * 0.55
			var cd: Vector3 = Vector3(sin(ang) * 0.8 - sd * 0.15, -0.75, -cos(ang) * 0.7).normalized()
			_cone(root, hand + cd * 0.045, cd, 0.05, 0.011, mat_accent)

	# --- head(s) ------------------------------------------------------------
	var mat_head: StandardMaterial3D = _scaled(_glaze(finish_flesh, col_neck, rng), scale_tex, Vector3(1.5, 1.0, 1.0))
	var mat_jaw: StandardMaterial3D = _glaze(finish_flesh, col_neck.lerp(col_belly, 0.35), rng)
	var horn_back: float = rng.randf_range(0.35, 0.6)
	var rh: float = 0.105 * body_k
	var f_head: Vector3 = Vector3(sin(head_yaw), -0.24, -cos(head_yaw)).normalized()
	var jaw_main: float = jaw_open
	if is_ouro:
		# the head has come down to find the tail that climbed over the back
		var bite_v: Vector3 = tail_p - p_head_base
		if bite_v.length() < 0.001:
			bite_v = Vector3(0.0, -0.3, -1.0)
		f_head = bite_v.normalized()
		jaw_main = jaw_open * 0.55
	_head(root, p_head_base, f_head, rh, body_k, jaw_main, r_neck_end, horn_back, 5, true, mat_head, mat_jaw, mat_accent, mat_eye)

	# --- extra necks: a second dragon budding out of the first ---------------
	var mat_neck2: StandardMaterial3D = _scaled(_glaze(finish_flesh, col_neck.lerp(col_hip, 0.3), rng), scale_tex, Vector3(2.0, 1.0, 1.0))
	var neck_mats: Array = [mat_neck2, mat_head, mat_jaw, mat_accent, mat_eye]
	if necks == "twinned":
		var i_b: int = int(floor(float(n_spine - 1) * 0.55))
		var b_p: Vector3 = pts[i_b]
		var b_r: float = radii[i_b]
		var d0 := Vector3(neck_fan * 0.08 * tail_side, 0.70, 0.72).normalized()
		var cu := Vector3(neck_fan * 0.20 * tail_side, -0.12, 0.62).normalized()
		_extra_neck(root, b_p + Vector3(0.0, b_r * 0.20, b_r * 0.95), d0, cu, 9, b_r * 0.70 * bone_k, 0.095 * body_k, rh * 0.94, body_k, jaw_open, horn_back, 4, neck_mats, iso)
	elif necks == "hydra":
		var i_n: int = int(floor(float(n_spine - 1) * 0.62))
		var n_p: Vector3 = pts[i_n]
		var n_r: float = radii[i_n]
		var tg: Vector3 = _tangent(pts, i_n)
		for sgn in [-1.0, 1.0]:
			var sgf: float = sgn
			var d0: Vector3 = (tg + Vector3(sgf * (0.9 + neck_fan), 0.05, -0.30)).normalized()
			var cu: Vector3 = Vector3(sgf * 0.45, 0.34, -0.82).normalized()
			_extra_neck(root, n_p + Vector3(sgf * n_r * 0.85, n_r * 0.20, 0.0), d0, cu, 6, n_r * 0.62 * bone_k, 0.088 * body_k, rh * 0.78, body_k, jaw_open * 1.15, horn_back, 3, neck_mats, iso)

	# --- wings --------------------------------------------------------------
	var i_sh: int = int(floor(float(n_spine - 1) * 0.58))
	var p_sh: Vector3 = pts[i_sh]
	var r_sh: float = radii[i_sh]
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var spread: float = spread_l if side_i == 0 else spread_r
		var s_pt := p_sh + Vector3(sd * (r_sh * 0.7), r_sh * 0.3, r_sh * 0.4)
		var w_pt := s_pt + Vector3(sd * 0.16, wing_lift, 0.10)
		_tapered_cyl(root, s_pt, w_pt, 0.030 * bone_k, 0.024 * bone_k, mat_rib)
		var e1 := Vector3(sd * 0.62, 0.68, 0.38).normalized()
		var e2 := Vector3(sd * 0.08, -0.30, 0.95)
		e2 = (e2 - e1 * e1.dot(e2)).normalized()
		var nrm: Vector3 = e1.cross(e2).normalized()
		var rib_dirs: Array = []
		var rib_lens: Array = []
		for k in range(n_ribs):
			var fr: float = float(k) / float(n_ribs - 1)
			var th: float = fr * spread
			var rd: Vector3 = (e1 * cos(th) + e2 * sin(th)).normalized()
			var ln: float = lerpf(0.46, 0.27, pow(fr, 1.4))
			if k == 0:
				ln = 0.40
			ln *= body_k
			if is_fossil:
				ln *= 1.18
			rib_dirs.append(rd)
			rib_lens.append(ln)
			var tip: Vector3 = w_pt + rd * ln
			var rib_thin: float = 0.72 if is_fossil else 1.0
			_tapered_cyl(root, w_pt, tip, 0.012 * rib_thin, 0.006 * rib_thin, mat_rib)
			var knob := SphereMesh.new()
			knob.radius = 0.014 * rib_thin
			knob.height = 0.028 * rib_thin
			var km: MeshInstance3D = _add(root, knob, mat_accent)
			km.transform = Transform3D(Basis(), tip)
		# closing pseudo-rib back to the shoulder
		rib_dirs.append((s_pt - w_pt).normalized())
		rib_lens.append((s_pt - w_pt).length())
		if not is_fossil:
			var membrane: ArrayMesh = _membrane(w_pt, rib_dirs, rib_lens, nrm, wing_cols, n_ribs)
			# a wet film over the pastel gradient: the vertex colours carry the hue,
			# the finish carries the rim so the membrane glows at its own edge
			var mat_wing: StandardMaterial3D = _glaze("wet", wing_cols[1], rng)
			mat_wing.albedo_color = Color(1.0, 1.0, 1.0, 0.72)
			mat_wing.vertex_color_use_as_albedo = true
			mat_wing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat_wing.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat_wing.emission = wing_cols[2]
			mat_wing.emission_energy_multiplier = 0.32
			var wm: MeshInstance3D = _add(root, membrane, mat_wing)
			wm.transform = Transform3D(Basis(), Vector3.ZERO)

	# --- the kiln pass: sag, burst, dissolve or POUR the finished body -------
	if kiln == "molten":
		_kiln_molten(root, rng, sag, col_belly, col_accent, finish_flesh)
	elif kiln == "crazed":
		_kiln_crazed(root, rng, burst)
	elif kiln == "swarm":
		_kiln_swarm(root, rng, frag_jitter)
	elif is_cast:
		# THE POUR. One field, marched: the thighs swell into the hips, a second
		# neck grows out of the shoulder, and an ouroboros ring encloses a hole
		# the field never crossed zero inside. The scale map goes on TRIPLANAR —
		# a marched mesh has no UVs, so an ordinary albedo map would be flat.
		var mat_cast: StandardMaterial3D = _glaze(finish_flesh, col_hip.lerp(col_neck, 0.45), rng)
		mat_cast.albedo_texture = scale_tex
		mat_cast.uv1_triplanar = true
		mat_cast.uv1_scale = Vector3(2.6, 2.6, 2.6)
		var poured: MeshInstance3D = Iso.add_body(root, iso_parts, mat_cast, ISO_CELL, iso_blend)
		if poured == null:
			# the mesher is new. If the march yields nothing, the dragon is
			# assembled out of the very primitives the field was composed from,
			# rather than standing on the plinth as a head with no body.
			_replay(root, iso["spare"])

	# --- fit, centre, plinth ------------------------------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.16 / maxf(box.size.x, 0.01)
	var kz: float = 1.16 / maxf(box.size.z, 0.01)
	var ky: float = (1.70 - PLINTH_TOP) / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			var pivot := Vector3(0.0, PLINTH_TOP, 0.0)
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), pivot + (tf.origin - pivot) * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, 0.0, -centre.z)
	if box.position.y < 0.0:
		shift.y = -box.position.y
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)
	var plinth := BoxMesh.new()
	plinth.size = Vector3(minf(1.2, box.size.x + 0.08), PLINTH_TOP, minf(1.2, box.size.z + 0.08))
	var pm: MeshInstance3D = _add(root, plinth, mat_plinth)
	pm.transform = Transform3D(Basis(), Vector3(0.0, PLINTH_TOP * 0.5, 0.0))


# ---------------------------------------------------------------------------
# shape helpers

static func _spine_angle(t: float, a0: float, a1: float, a2: float) -> float:
	# lean from vertical toward the front (-Z); keyed hips -> chest -> neck -> head
	var keys: Array = [a0, a0 * 0.35, a1, a2]
	var f: float = t * 3.0
	var i: int = int(floor(f))
	if i >= 3:
		return a2
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _r_profile(t: float) -> float:
	var keys: Array = [0.175, 0.19, 0.20, 0.155, 0.115, 0.095, 0.088]
	var f: float = t * 6.0
	var i: int = int(floor(f))
	if i >= 6:
		return keys[6]
	var u: float = f - float(i)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
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


static func _c(scheme: Array, i: int) -> Color:
	var code: String = scheme[i]
	return Color(code)


## Every surface on the dragon comes through here, so the family has ONE idea of
## shine and it is DreamSkin's. `finish` decides everything the old rough/clearcoat
## pair used to; "matte" is the chalk-bone and stone passage.
static func _glaze(finish: String, c: Color, rng: RandomNumberGenerator) -> StandardMaterial3D:
	return Gloss.skin(finish, c, rng)


## The hexagon scale map, laid over a gloss. Triplanar is forced OFF: the hide
## finishes are the untextured ones, and their uv1 must stay the mesh's own.
static func _scaled(m: StandardMaterial3D, tex: ImageTexture, uv: Vector3) -> StandardMaterial3D:
	m.albedo_texture = tex
	m.uv1_triplanar = false
	m.uv1_scale = uv
	return m


## A body bead. Under `cast` no mesh is made: the bead is held in reserve for the
## fallback, and (for a hand, which nothing else in the field covers) contributed
## to the field as a sphere.
static func _body_sphere(root: Node3D, iso: Dictionary, o: Vector3, bs: Basis, r: float, mat: StandardMaterial3D, to_field: bool = false) -> void:
	if bool(iso["on"]):
		if to_field:
			var parts: Array = iso["parts"]
			parts.append(Iso.sphere(o, maxf(r, ISO_FLOOR)))
		var spare: Array = iso["spare"]
		spare.append({"t": "sph", "o": o, "bs": bs, "r": r, "m": mat})
		return
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(bs, o)


## A limb bone. Under `cast` it becomes a field capsule — the smooth union is what
## turns the thigh joining the hip from an intersection into a fillet.
static func _body_limb(root: Node3D, iso: Dictionary, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> void:
	if bool(iso["on"]):
		var rf: float = maxf(r * 0.94, ISO_FLOOR)
		var parts: Array = iso["parts"]
		parts.append(Iso.capsule(a, b, rf, rf))
		var spare: Array = iso["spare"]
		spare.append({"t": "cap", "p0": a, "p1": b, "r": r, "m": mat})
		return
	_limb(root, a, b, r, mat)


## The fallback: draw everything `cast` held back, as the other five kiln values
## would have drawn it. Only ever runs when DreamIso returns no mesh.
static func _replay(root: Node3D, spare: Array) -> void:
	for e_v in spare:
		var e: Dictionary = e_v
		var m: StandardMaterial3D = e["m"]
		if String(e["t"]) == "sph":
			var r: float = e["r"]
			var bs: Basis = e["bs"]
			var o: Vector3 = e["o"]
			var sph := SphereMesh.new()
			sph.radius = r
			sph.height = r * 2.0
			var mi: MeshInstance3D = _add(root, sph, m)
			mi.transform = Transform3D(bs, o)
		else:
			var p0: Vector3 = e["p0"]
			var p1: Vector3 = e["p1"]
			_limb(root, p0, p1, float(e["r"]), m)


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 1.6
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


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	# emit a quad whose Godot front face (clockwise) points away from `inside`
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
	# back face at z = 0 (w0 x h0), front face at z = -ln (w1 x h1), front centre lowered by `drop`
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


static func _membrane(w: Vector3, rib_dirs: Array, rib_lens: Array, nrm: Vector3, cols: Array, n_real: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 6
	var subs: int = 4
	var waves: float = 4.0
	var n_sect: int = rib_dirs.size() - 1
	for i in range(n_sect):
		var da: Vector3 = rib_dirs[i]
		var db: Vector3 = rib_dirs[i + 1]
		var la: float = rib_lens[i]
		var lb: float = rib_lens[i + 1]
		var scallop: float = 0.16 if i < n_real - 1 else 0.0
		var grid: Array = []
		for k in range(rings + 1):
			var row: Array = []
			var f: float = float(k) / float(rings)
			for j in range(subs + 1):
				var fr: float = float(j) / float(subs)
				var d: Vector3 = (da * (1.0 - fr) + db * fr).normalized()
				var ln: float = lerpf(la, lb, fr) * (1.0 - scallop * f * sin(PI * fr))
				var ripple: float = 0.004 * sin(f * PI * waves) * (0.3 + 0.7 * f)
				row.append(w + d * (ln * f) + nrm * ripple)
			grid.append(row)
		for k in range(rings):
			var f0: float = float(k) / float(rings)
			var f1: float = float(k + 1) / float(rings)
			var c0: Color = _wing_col(cols, f0, waves)
			var c1: Color = _wing_col(cols, f1, waves)
			var row0: Array = grid[k]
			var row1: Array = grid[k + 1]
			for j in range(subs):
				var p00: Vector3 = row0[j]
				var p01: Vector3 = row0[j + 1]
				var p10: Vector3 = row1[j]
				var p11: Vector3 = row1[j + 1]
				if k == 0:
					st.set_color(c0)
					st.add_vertex(p00)
					st.set_color(c1)
					st.add_vertex(p10)
					st.set_color(c1)
					st.add_vertex(p11)
				else:
					st.set_color(c0)
					st.add_vertex(p00)
					st.set_color(c1)
					st.add_vertex(p10)
					st.set_color(c1)
					st.add_vertex(p11)
					st.set_color(c0)
					st.add_vertex(p00)
					st.set_color(c1)
					st.add_vertex(p11)
					st.set_color(c0)
					st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


static func _wing_col(cols: Array, f: float, waves: float) -> Color:
	var ca: Color = cols[0]
	var cb: Color = cols[1]
	var cc: Color = cols[2]
	var base: Color = ca.lerp(cb, clampf(f * 2.0, 0.0, 1.0)) if f < 0.5 else cb.lerp(cc, clampf((f - 0.5) * 2.0, 0.0, 1.0))
	var band: float = 1.0 + 0.07 * sin(f * PI * waves)
	return Color(clampf(base.r * band, 0.0, 1.0), clampf(base.g * band, 0.0, 1.0), clampf(base.b * band, 0.0, 1.0), 1.0)


static func _scale_texture(rng: RandomNumberGenerator, cols: int, rows: int, fill: float) -> ImageTexture:
	# pointy-top hexagon lattice, seamless; near-white so albedo_color tints it
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var w: float = float(TEX_SIZE) / float(cols)
	var h: float = float(TEX_SIZE) / float(rows)
	var tints: Array = []
	for c in range(cols * rows):
		tints.append(Vector3(rng.randf_range(0.90, 1.0), rng.randf_range(0.90, 1.0), rng.randf_range(0.90, 1.0)))
	var groove: float = 0.60
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var row_c: int = int(floor(py / h))
			var best_d: float = 1.0e9
			var best_dx: float = 0.0
			var best_dy: float = 0.0
			var best_i: int = 0
			for rr in range(row_c - 1, row_c + 2):
				var rw: int = posmod(rr, rows)
				var off: float = 0.5 * w if (rw % 2) == 1 else 0.0
				var cy: float = (float(rr) + 0.5) * h
				var col_c: int = int(floor((px - off) / w))
				for cc in range(col_c - 1, col_c + 2):
					var cx: float = (float(cc) + 0.5) * w + off
					var dx: float = px - cx
					var dy: float = py - cy
					var dd: float = dx * dx + dy * dy
					if dd < best_d:
						best_d = dd
						best_dx = dx
						best_dy = dy
						best_i = rw * cols + posmod(cc, cols)
			var ndy: float = best_dy * (0.866 * w / h)
			var hd: float = maxf(absf(best_dx), maxf(absf(best_dx * 0.5 + ndy * 0.866), absf(best_dx * 0.5 - ndy * 0.866))) / (w * 0.5)
			var edge: float = clampf((fill + 0.05 - hd) / 0.09, 0.0, 1.0)
			var shade: float = 0.80 + 0.14 * (1.0 - hd) - 0.10 * (ndy / (w * 0.5))
			shade = clampf(shade, 0.6, 1.0)
			var tint: Vector3 = tints[best_i]
			var r_v: float = lerpf(groove, tint.x * shade, edge)
			var g_v: float = lerpf(groove, tint.y * shade, edge)
			var b_v: float = lerpf(groove, tint.z * shade, edge)
			img.set_pixel(x, y, Color(r_v, g_v, b_v))
	return ImageTexture.create_from_image(img)


static func _arc_angle(t: float, span: float) -> float:
	# ouroboros trunk: one smooth roll from a forward lean to past the vertical
	var u: float = clampf(t, 0.0, 1.0)
	var s: float = u * u * (3.0 - 2.0 * u)
	return lerpf(0.30, span, s)


static func _bez(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var u: float = 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)


static func _rand_unit(rng: RandomNumberGenerator) -> Vector3:
	var v := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	if v.length() < 0.001:
		return Vector3.UP
	return v.normalized()


# one skull, jaws, teeth, eyes, horns and (optionally) ear frills, aimed along
# f_dir. `mini` falls out of rh so the main head is bit-for-bit what it was.
static func _head(root: Node3D, base_p: Vector3, f_dir: Vector3, rh: float, body_k: float, jaw_open: float, r_neck: float, horn_back: float, n_teeth: int, frills: bool, mat_head: StandardMaterial3D, mat_jaw: StandardMaterial3D, mat_accent: StandardMaterial3D, mat_eye: StandardMaterial3D) -> void:
	var mini: float = rh / maxf(0.105 * body_k, 0.0001)
	var f_head: Vector3 = f_dir.normalized()
	var up_proj: Vector3 = Vector3.UP - f_head * Vector3.UP.dot(f_head)
	if up_proj.length() < 0.001:
		up_proj = Vector3.BACK - f_head * Vector3.BACK.dot(f_head)
	var u_head: Vector3 = up_proj.normalized()
	var r_head: Vector3 = f_head.cross(u_head).normalized()
	var hb := Basis(r_head, u_head, -f_head)
	var h_org: Vector3 = base_p + f_head * (rh * 0.35) + u_head * (rh * 0.1)
	var skull := SphereMesh.new()
	skull.radius = rh
	skull.height = rh * 1.9
	var sm: MeshInstance3D = _add(root, skull, mat_head)
	sm.transform = Transform3D(hb, h_org)
	# neck-to-skull filler so the chain does not show a gap under the jaw
	var filler := SphereMesh.new()
	filler.radius = r_neck * 0.9
	filler.height = r_neck * 1.8
	var fm: MeshInstance3D = _add(root, filler, mat_head)
	fm.transform = Transform3D(hb, base_p + f_head * (rh * 0.05) - u_head * (rh * 0.35))

	var jaw_l: float = 0.24 * body_k * mini
	var upper: ArrayMesh = _tapered_box(0.16 * body_k * mini, 0.10 * body_k * mini, 0.09 * body_k * mini, 0.045 * body_k * mini, jaw_l, -0.02 * mini)
	var um: MeshInstance3D = _add(root, upper, mat_jaw)
	um.transform = Transform3D(hb, h_org + hb * Vector3(0.0, -0.025 * mini, 0.02 * mini))
	var jb: Basis = hb * Basis(Vector3.RIGHT, -jaw_open)
	var lower: ArrayMesh = _tapered_box(0.14 * body_k * mini, 0.05 * body_k * mini, 0.075 * body_k * mini, 0.03 * body_k * mini, jaw_l * 0.92, 0.0)
	var lm: MeshInstance3D = _add(root, lower, mat_jaw)
	var hinge: Vector3 = h_org + hb * Vector3(0.0, -0.025 * mini - 0.05 * body_k * mini, 0.02 * mini)
	lm.transform = Transform3D(jb, hinge)
	# teeth: upper jaw hangs them down, lower jaw points them up
	var nt: int = maxi(n_teeth, 2)
	for k in range(nt):
		var fz: float = lerpf(0.07 * mini, jaw_l - 0.02 * mini, float(k) / float(nt - 1))
		var wq: float = lerpf(0.16 * body_k * mini, 0.09 * body_k * mini, fz / jaw_l) * 0.44
		var yq: float = -0.025 * mini - lerpf(0.05 * body_k * mini, 0.0225 * body_k * mini, fz / jaw_l) - 0.02 * mini * (fz / jaw_l)
		for sgn in [-1.0, 1.0]:
			var sgf: float = sgn
			var tp: Vector3 = h_org + hb * Vector3(sgf * wq, yq + 0.01 * mini, 0.02 * mini - fz)
			_cone(root, tp, -u_head, 0.032 * mini, 0.008 * mini, mat_accent)
		if k < nt - 1:
			var fz2: float = fz + 0.02 * mini
			var wq2: float = lerpf(0.14 * body_k * mini, 0.075 * body_k * mini, fz2 / jaw_l) * 0.42
			var yq2: float = lerpf(0.025 * body_k * mini, 0.015 * body_k * mini, fz2 / jaw_l)
			for sgn in [-1.0, 1.0]:
				var sgf: float = sgn
				var tp2: Vector3 = hinge + jb * Vector3(sgf * wq2, yq2 - 0.008 * mini, -fz2)
				_cone(root, tp2, jb * Vector3.UP, 0.028 * mini, 0.007 * mini, mat_accent)
	# eyes
	for sgn in [-1.0, 1.0]:
		var sgf: float = sgn
		var eye := SphereMesh.new()
		eye.radius = 0.021 * mini
		eye.height = 0.042 * mini
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(Basis(), h_org + hb * Vector3(sgf * rh * 0.72, rh * 0.30, -rh * 0.55))
	# horns, two segments each, bending back
	for sgn in [-1.0, 1.0]:
		var sgf: float = sgn
		var base_h: Vector3 = h_org + hb * Vector3(sgf * rh * 0.45, rh * 0.75, rh * 0.15)
		var d1: Vector3 = (hb * Vector3(sgf * 0.25, 0.85, horn_back)).normalized()
		var mid_p: Vector3 = base_h + d1 * (0.09 * mini)
		var d2: Vector3 = (hb * Vector3(sgf * 0.3, 0.55, horn_back + 0.35)).normalized()
		var tip_p: Vector3 = mid_p + d2 * (0.08 * mini)
		_tapered_cyl(root, base_h, mid_p, 0.022 * mini, 0.013 * mini, mat_accent)
		_tapered_cyl(root, mid_p, tip_p, 0.013 * mini, 0.0, mat_accent)
	# ear frills
	if frills:
		for sgn in [-1.0, 1.0]:
			var sgf: float = sgn
			var frill := PrismMesh.new()
			frill.size = Vector3(0.03 * mini, 0.10 * mini, 0.06 * mini)
			var frm: MeshInstance3D = _add(root, frill, mat_accent)
			var fb: Basis = hb * Basis(Vector3.FORWARD, sgf * 0.9) * Basis(Vector3.RIGHT, 0.5)
			frm.transform = Transform3D(fb, h_org + hb * Vector3(sgf * rh * 0.95, rh * 0.25, rh * 0.25))


# a second (or third) neck budding off the trunk, ending in its own head
static func _extra_neck(root: Node3D, org: Vector3, dir0: Vector3, curl: Vector3, n: int, r0: float, seg: float, rh: float, body_k: float, jaw: float, horn_back: float, n_teeth: int, mats: Array, iso: Dictionary) -> void:
	var mat_body: StandardMaterial3D = mats[0]
	var mat_head: StandardMaterial3D = mats[1]
	var mat_jaw: StandardMaterial3D = mats[2]
	var mat_accent: StandardMaterial3D = mats[3]
	var mat_eye: StandardMaterial3D = mats[4]
	var d: Vector3 = dir0.normalized()
	var p: Vector3 = org
	var r_end: float = r0 * 0.44
	var chain_p: Array = []
	var chain_r: Array = []
	for i in range(n):
		var f: float = float(i) / float(maxi(n - 1, 1))
		var nd: Vector3 = d + curl * 0.30
		if nd.length() < 0.001:
			nd = d
		d = nd.normalized()
		p = p + d * seg
		var rr: float = lerpf(r0, r_end, f)
		chain_p.append(p)
		chain_r.append(rr)
		_body_sphere(root, iso, p, _basis_y_to(d), rr, mat_body)
	if bool(iso["on"]) and n >= 1:
		# two capsules, rooted AT the shoulder point: under the smooth union the
		# second neck is poured out of the trunk, not stuck onto it
		var parts: Array = iso["parts"]
		var mid_i: int = maxi(0, int(floor(float(n - 1) * 0.5)))
		var mid_p: Vector3 = chain_p[mid_i]
		var mid_r: float = maxf(float(chain_r[mid_i]), ISO_FLOOR)
		var end_p: Vector3 = chain_p[n - 1]
		var end_r: float = maxf(float(chain_r[n - 1]), ISO_FLOOR)
		parts.append(Iso.capsule(org, mid_p, maxf(r0, ISO_FLOOR), mid_r))
		parts.append(Iso.capsule(mid_p, end_p, mid_r, end_r))
	var f_dir: Vector3 = (d + Vector3(0.0, -0.26, 0.0)).normalized()
	_head(root, p, f_dir, rh, body_k, jaw, r_end, horn_back, n_teeth, false, mat_head, mat_jaw, mat_accent, mat_eye)


# --- the kiln passes, run over the finished body before the settle ----------

static func _kiln_molten(root: Node3D, rng: RandomNumberGenerator, sag: float, col_pour: Color, col_drip: Color, finish: String) -> void:
	var box: AABB = _union_aabb(root)
	var y0: float = box.position.y
	var span: float = maxf(box.size.y, 0.01)
	var kids: Array = []
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		kids.append(ch)
	if kids.is_empty():
		return
	for it in kids:
		var cm: MeshInstance3D = it
		var tf: Transform3D = cm.transform
		var o: Vector3 = tf.origin
		var f: float = clampf((o.y - y0) / span, 0.0, 1.0)
		var low: float = 1.0 - f
		var ny: float = y0 + (o.y - y0) * (1.0 - sag * 0.62)
		var out_k: float = 1.0 + 0.52 * low * low
		var no := Vector3(o.x * out_k, ny, o.z * out_k)
		var sq := Vector3(1.0 + 0.50 * low, 1.0 - 0.44 * low, 1.0 + 0.50 * low)
		cm.transform = Transform3D(tf.basis.scaled(sq), no)
	# the pour the lower third has drowned in
	var box2: AABB = _union_aabb(root)
	var flood: float = box2.position.y + box2.size.y * 0.34
	var rad: float = maxf(maxf(box2.size.x, box2.size.z) * 0.50, 0.22)
	# a slab of standing glass: "wet" is exactly that, plus the alpha it needs
	var mat_pour: StandardMaterial3D = Gloss.skin("wet", col_pour, rng)
	mat_pour.albedo_color = Color(col_pour.r, col_pour.g, col_pour.b, 0.88)
	mat_pour.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var pour_h: float = maxf((flood - box2.position.y) * 0.44, 0.03)
	for k in range(3):
		var fk: float = float(k) / 2.0
		var disc := CylinderMesh.new()
		disc.bottom_radius = lerpf(rad * 1.14, rad * 0.52, fk)
		disc.top_radius = lerpf(rad * 0.96, rad * 0.30, fk)
		disc.height = pour_h
		disc.radial_segments = 24
		var dm: MeshInstance3D = _add(root, disc, mat_pour)
		dm.transform = Transform3D(Basis(), Vector3(0.0, box2.position.y + pour_h * (0.5 + 0.66 * float(k)), 0.0))
	# drips off whatever is hanging highest
	var mat_dr: StandardMaterial3D = _glaze(finish, col_drip, rng)
	for k in range(6):
		var src: MeshInstance3D = kids[rng.randi_range(0, kids.size() - 1)]
		var o: Vector3 = src.transform.origin
		if o.y < flood:
			continue
		var ln: float = rng.randf_range(0.07, 0.20)
		_tapered_cyl(root, o, o - Vector3(0.0, ln, 0.0), 0.022, 0.005, mat_dr)


static func _kiln_crazed(root: Node3D, rng: RandomNumberGenerator, burst: float) -> void:
	var box: AABB = _union_aabb(root)
	var c: Vector3 = box.position + box.size * 0.5
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		var away: Vector3 = tf.origin - c
		if away.length() < 0.002:
			away = Vector3.UP * 0.01
		var nrm: Vector3 = away.normalized()
		var jit: Vector3 = _rand_unit(rng)
		var no: Vector3 = c + away * 1.18 + nrm * (burst * rng.randf_range(0.35, 1.0)) + jit * (burst * 0.32)
		cm.transform = Transform3D(Basis(jit, rng.randf_range(-0.5, 0.5)) * tf.basis, no)


static func _kiln_swarm(root: Node3D, rng: RandomNumberGenerator, jitter: float) -> void:
	var kids: Array = []
	var vols: Array = []
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var sz: Vector3 = cm.mesh.get_aabb().size
		kids.append(cm)
		vols.append(sz.x * sz.y * sz.z)
	if kids.is_empty():
		return
	# budget: two new fragments per dissolved part, and never past the cap
	var room: int = 246 - root.get_child_count()
	var n_pick: int = clampi(int(floor(float(room) * 0.5)), 0, kids.size())
	if n_pick <= 0:
		return
	var taken: Array = []
	for i in range(kids.size()):
		taken.append(false)
	var picked: Array = []
	for _p in range(n_pick):
		var best: int = -1
		var best_v: float = -1.0
		for i in range(kids.size()):
			if bool(taken[i]):
				continue
			var v: float = vols[i]
			if v > best_v:
				best_v = v
				best = i
		if best < 0:
			break
		taken[best] = true
		picked.append(kids[best])
	var k_small: float = 0.36
	for it in picked:
		var cm: MeshInstance3D = it
		var tf: Transform3D = cm.transform
		var o: Vector3 = tf.origin
		var spread: float = maxf(cm.mesh.get_aabb().size.length() * 0.30, 0.02) * jitter
		var sb: Basis = tf.basis.scaled(Vector3(k_small, k_small, k_small))
		cm.transform = Transform3D(sb, o + _rand_unit(rng) * (spread * 0.45))
		for _j in range(2):
			var mi := MeshInstance3D.new()
			mi.mesh = cm.mesh
			mi.material_override = cm.material_override
			var spin := Basis(_rand_unit(rng), rng.randf_range(0.0, TAU))
			mi.transform = Transform3D(sb * spin, o + _rand_unit(rng) * spread)
			root.add_child(mi)


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
