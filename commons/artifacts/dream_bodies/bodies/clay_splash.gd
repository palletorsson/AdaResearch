extends RefCounted

## dream_bodies / clay_splash — one boneless clay figure heaped over grey rocks,
## GLAZED, wearing fluorescent flat paint.
##
## Reference (described, no image supplied): a pile of porcelain-clay figures
## heaped over grey rocks, painted like an animation cel — pale cream and blush
## bodies, smooth and boneless, carrying BOLD FLAT SPLASHES of colour that ignore
## anatomy: coral-red running down a thigh, saffron-yellow over a hip and calf, a
## soft blue wash across a shoulder. One figure wears a full bodysuit of fine grey
## scale print, another is dusty rose. Small clay animals lie among them — a green
## fish with a round eye, a yellow duck.
##
## THE GLAZE (2026-09-03, Palle: "add super glossy and queer materials"). The
## reference figures are dusty bisque. This family is now FIRED: the clay body
## goes into the kiln and comes out under a glaze, and the flat paints come out
## fluorescent. Every material in this file is dealt by DreamSkin:
##
##   the body      one glaze per seed from latex · patent · candy · pearl · wet —
##                 the five finishes that leave albedo_texture free, so the painted
##                 chalk-and-splash skin survives UNDER the shine instead of being
##                 replaced by it. The albedo is tinted only 0.22 toward the seed's
##                 queer colour, so the glaze colours the clay rather than hiding it.
##   the paint     when it stops being a texture and becomes matter (crust, flood,
##                 bloom) it takes the LOUD set — oilslick · holo · neon · patent ·
##                 wet — dealt once, so eleven crusts read as one pour and not as
##                 eleven accidents. Six glaze pots are mixed up front and shared,
##                 because a holo sweep texture per slab is eleven textures for one
##                 statue.
##   the splashes  the family's coral / saffron / pale blue survive as ORDER only:
##                 each is lerped 0.78 toward a dealt queer colour, so the palette
##                 keeps its three-against-one structure and goes hot.
##   the rocks     STAY MATTE. This is the one passage that must not shine: grey
##                 chalky stone under a wet body is the whole contrast, and a
##                 glossy rock would make the figure read as plastic on plastic.
##                 They ask DreamSkin for "matte" explicitly, so the choice is
##                 written down and not just an omission.
##
## Reproduced, and how:
##   1. The rocks that carry it — 4..6 ground rocks plus 1..2 perched on top and
##      3..5 pebbles, each a SurfaceTool lat/long sphere whose radius is modulated
##      by three random sine lobes and squashed on Y. A ground rock is then CUT:
##      its underside is clamped off at 0.88 of its own measured minimum (never at
##      a guessed depth — the lobes can pull the bottom anywhere) and lifted so the
##      cut face is local y = 0, so the heap SITS on the floor. One rock is forced
##      under the forward knee so the pose is carried and not floating.
##   2. A boneless body — no bone anywhere: a 16..20 link bezier chain of squashed
##      SphereMesh ellipsoids from pelvis to neck, oriented to the chain tangent,
##      with a soft belly, a buttock, two hip shelves and chest lumps hung off it
##      so the silhouette bulges rather than tapers. Limbs are sphere chains too.
##   3. The gesture, a diagonal — one arm braced straight down onto the ground on
##      one side, the heavy thigh thrown forward and down over the front rock on
##      the OTHER, the torso leaning over the braced arm and twisting away, the
##      free hand laid on that thigh. Sides, lean, twist and slump come from seed.
##   4. Flat splashes — a 160x160 ImageTexture painted pixel by pixel: a chalky
##      ground (cream / blush / dusty rose, tinted toward the seed's glaze, a
##      12-cell smoothed value lattice plus fine grain) under 6..10 blotches of the
##      fluorescent palette, each an angular-harmonic radius with a feathered edge
##      and 1..3 spatters. Applied with WORLD triplanar, so one splash runs across
##      belly and thigh unbroken — and across a fused body's merged flank.
##   5. The scale suit — one seed in three wears fine grey reptile print instead:
##      a 128x128 staggered lattice of overlapping tile-scales, each top-lit with
##      a dark groove, at uv scale 7.0 so the scales read about 6 mm. The head is
##      left bare, so it reads as a bodysuit and not as skin.
##   6. No face — a smooth bald ovoid tilted down and away, and two closed-lid
##      dashes: flattened ellipsoids tipped in the head's own frame, in patent
##      black so the only hard mirror on the statue is where the eyes would be.
##   7. A small clay animal beside it — by seed a green fish (squashed body, blunt
##      snout, PrismMesh wedge tail, dorsal wedge, round bead eyes) or a yellow
##      duck (body, head, prism beak, cocked tail, bead eyes), each pulled 0.42
##      toward the seed's accent colour and given its own glaze: same kiln,
##      different pot.
##   8. Wet, not dusty — the chalk lattice and the speckle stay in the ALBEDO, so
##      the clay is still mottled and hand-made; the shine is clearcoat, rim and a
##      trace of emission on top of it. Nothing is smooth-plastic: the glaze sits
##      over a painted surface, which is what a real glaze does.
##   9. FUSED (clay axis) — the same joints and radii handed to DreamIso as an SDF
##      instead of to SphereMesh: 34 parts, tetrahedra-marched at cell 0.055 with
##      a 0.12 fillet. Nothing is assembled. The thigh does not enter the hip, it
##      SWELLS into it; the neck and the skull are one pour; the braced arm and the
##      floor-flat mitt are a single continuous run of clay; and the navel is a
##      subtracted sphere — a place the field never crossed zero, with a lip on it
##      because the subtraction is smooth too. One mesh, so the family's own small
##      parts come back as primitives around it: 20 drips hung under the limbs
##      where the pour ran off, and 8 flat-cut lobed puddles of the same glazed
##      clay hardened on the floor. Worst case that is 43 meshes, over the floor
##      of 40; best case 52.
##
## Given up: the PILE (this is one figure, one animal — the reference is a heap of
## bodies reading against each other), the black cel contour line around every
## form (that needs a shader, not a material), the paint following the body's own
## contours (triplanar is a projection, not a brush), and the second and third
## figures' colourways, which survive only as this one's seeded ground colour.
##
## AXES
##   clay  — what the clay is doing to itself. boneless (as built) · melted (every
##           part sags and spreads in world Y, the head pooling near the shoulders,
##           puddles of skin running out across the floor) · swarm (each part halves
##           and drifts off the body axis, each leaving a smaller copy further out,
##           so the figure hangs in the air as a cloud of its own beads) · fossil
##           (the flesh sliced to thin plates in each part's OWN frame — ribs across
##           the spine, discs down the limbs, the rocks showing through the gaps) ·
##           mirrored (a second figure grows head-down out of the shoulders, which
##           doubles the height, so the settle pulls the whole heap small) · fused
##           (the body GROWN as one isosurface out of the same skeleton — limbs
##           merging into the torso with a fillet, drips off the underside, puddles
##           on the floor; if the mesher returns nothing the primitive body is built
##           instead, so the plinth is never empty).
##   paint — what the flat colour becomes once it stops being a texture. flat (as
##           built, paint only) · crust (eleven splashes come off the skin as thick
##           lobed slabs of matter with drips hanging and beading below them) ·
##           flood (the lower half submerged in a solid pour, a lipped pool over the
##           rocks with tongues rising out of it and droplets held above) · bloom
##           (both hands, both feet and the crown of the skull end in flower heads).

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const SPLASH_TEX: int = 160
const SCALE_TEX: int = 128
const SPECK_TEX: int = 96
const CHALK_CELLS: int = 12
const GRAIN_CELLS: int = 48

# grounds: cream, blush, dusty rose
const GROUNDS: Array = ["#F0E1CD", "#EAC7B7", "#D8A79B", "#F2E6D8"]
# the flat paints, as painted — kept for their ORDER; every one is pulled hot
const SPLASHES: Array = ["#D9503F", "#E9A72A", "#A6BFD6", "#C9604E", "#E7B94A", "#8FAECB"]
const ROCK_GREYS: Array = ["#9B9B96", "#8D8E8A", "#A7A49C", "#94908A"]

# the five finishes that leave albedo_texture free, so the painted clay survives
const GLAZES: Array = ["latex", "patent", "candy", "pearl", "wet"]
# what paint becomes when it stops being a picture
const LOUD: Array = ["oilslick", "holo", "neon", "patent", "wet"]


static func describe() -> String:
	return "A boneless porcelain-clay figure half-kneeling over a heap of matte grey rocks, glazed wet and fluorescent, its bald tilted head faceless but for two patent-black closed-lid dashes, its body carrying flat splashes of hot pink, acid and cyan with a small glazed clay animal lying beside it."


static func axes() -> Dictionary:
	return {
		"clay": ["boneless", "melted", "swarm", "fossil", "mirrored", "fused"],
		"paint": ["flat", "crust", "flood", "bloom"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the two axes --------------------------------------------------------
	# the defaults draw nothing and read no rng, so build(root, seed) is the
	# statue exactly as the glaze left it
	var clay: String = str(opts.get("clay", "boneless"))
	var paint: String = str(opts.get("paint", "flat"))

	# --- who this one is -----------------------------------------------------
	var wears_scale: bool = rng.randi_range(0, 2) == 0
	var ground_code: String = GROUNDS[rng.randi_range(0, GROUNDS.size() - 1)]
	var rock_code: String = ROCK_GREYS[rng.randi_range(0, ROCK_GREYS.size() - 1)]
	var rock_col: Color = Color(rock_code)
	var sb: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lb: float = -sb
	var body_k: float = rng.randf_range(0.94, 1.06)
	var lean: float = rng.randf_range(0.10, 0.19) * sb
	var slump: float = rng.randf_range(0.09, 0.20)
	var head_yaw: float = deg_to_rad(rng.randf_range(10.0, 28.0)) * -sb
	var head_pitch: float = deg_to_rad(rng.randf_range(14.0, 30.0))
	var head_roll: float = deg_to_rad(rng.randf_range(4.0, 14.0)) * sb
	var head_k: float = rng.randf_range(0.94, 1.08)
	var n_t: int = rng.randi_range(16, 20)
	var n_thigh: int = rng.randi_range(8, 10)
	var n_shin: int = rng.randi_range(6, 8)
	var n_arm: int = rng.randi_range(5, 7)
	var belly_k: float = rng.randf_range(0.94, 1.14)
	var hip_k: float = rng.randf_range(0.95, 1.12)
	var is_fish: bool = rng.randf() < 0.55
	# the animal's spot is drawn here so the pebbles can keep clear of it
	var an_x: float = -sb * rng.randf_range(0.32, 0.42)
	var an_z: float = rng.randf_range(-0.36, -0.14)
	var an_yaw: float = rng.randf_range(0.0, TAU)

	# --- the firing: which glaze, which colours ------------------------------
	var body_fin: String = GLAZES[rng.randi_range(0, GLAZES.size() - 1)]
	var an_fin: String = GLAZES[rng.randi_range(0, GLAZES.size() - 1)]
	var main: Color = Gloss.queer_colour(rng)
	var accent: Color = Gloss.queer_colour(rng)
	# the ground keeps its chalk but takes the glaze's hue
	var ground: Color = Color(ground_code).lerp(main, 0.22)
	# the flat paints, pulled hot — same six slots, same order, fluorescent
	var paints: Array = []
	for i_p in range(SPLASHES.size()):
		var raw: Color = Color(str(SPLASHES[i_p]))
		paints.append(raw.lerp(Gloss.queer_colour(rng), 0.78))

	# --- painted skins, glazed -----------------------------------------------
	var speck: ImageTexture = _speckle_texture(rng)
	# the rocks are the family's matte passage and stay stone
	var mat_rock: StandardMaterial3D = Gloss.skin("matte", rock_col, rng)
	mat_rock.roughness = 0.95
	mat_rock.albedo_texture = speck
	mat_rock.uv1_triplanar = true
	mat_rock.uv1_world_triplanar = true
	mat_rock.uv1_triplanar_sharpness = 1.4
	mat_rock.uv1_scale = Vector3(2.6, 2.6, 2.6)
	var mat_rock_b: StandardMaterial3D = Gloss.skin("matte", rock_col.lightened(0.10), rng)
	mat_rock_b.roughness = 0.95
	mat_rock_b.albedo_texture = speck
	mat_rock_b.uv1_triplanar = true
	mat_rock_b.uv1_world_triplanar = true
	mat_rock_b.uv1_triplanar_sharpness = 1.4
	mat_rock_b.uv1_scale = Vector3(3.4, 3.4, 3.4)

	# the body: a GLAZE finish over the painted clay. the albedo is left near
	# white and only tinted, or the glaze colour would swallow the splashes the
	# whole family is about
	var mat_skin: StandardMaterial3D = Gloss.skin(body_fin, main, rng)
	mat_skin.albedo_color = Color(1.0, 1.0, 1.0).lerp(main, 0.22)
	mat_skin.uv1_triplanar = true
	mat_skin.uv1_world_triplanar = true
	mat_skin.uv1_triplanar_sharpness = 1.5
	mat_skin.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	if wears_scale:
		mat_skin.albedo_texture = _scale_texture(rng)
		var su: float = rng.randf_range(6.2, 8.0)
		mat_skin.uv1_scale = Vector3(su, su, su)
	else:
		mat_skin.albedo_texture = _splash_texture(rng, ground, paints)
		var pu: float = rng.randf_range(1.05, 1.36)
		mat_skin.uv1_scale = Vector3(pu, pu, pu)

	var mat_head: StandardMaterial3D = mat_skin
	if wears_scale:
		mat_head = Gloss.skin(body_fin, ground, rng)
		mat_head.albedo_texture = speck
		mat_head.uv1_triplanar = true
		mat_head.uv1_world_triplanar = true
		mat_head.uv1_scale = Vector3(3.0, 3.0, 3.0)
	# the only hard mirror on the statue is where the eyes would be
	var mat_lid: StandardMaterial3D = Gloss.skin("patent", Color("#241C22"), rng)

	# --- the heap of rocks ---------------------------------------------------
	var n_rock: int = rng.randi_range(4, 6)
	var knee_x: float = lb * rng.randf_range(0.25, 0.31)
	var knee_z: float = rng.randf_range(-0.30, -0.24)
	# a cut rock carries its own flat face at local y = 0, so these all sit at zero
	# the rock the forward knee lands on, placed first so the pose is carried
	var kr := Vector3(rng.randf_range(0.16, 0.21), rng.randf_range(0.10, 0.13), rng.randf_range(0.15, 0.20))
	_rock(root, rng, mat_rock, Vector3(knee_x, 0.0, knee_z), kr, 0.16, true)
	# the big rock under the pelvis — a cut rock stands about 2x its y radius, and
	# the pelvis rides at 0.56, so this tops out around 0.35 and is MET, not buried in
	var br := Vector3(rng.randf_range(0.31, 0.37), rng.randf_range(0.15, 0.19), rng.randf_range(0.27, 0.33))
	var bc := Vector3(rng.randf_range(-0.06, 0.06), 0.0, rng.randf_range(-0.04, 0.08))
	_rock(root, rng, mat_rock, bc, br, 0.14, true)
	var ring_a: float = rng.randf_range(0.0, TAU)
	for i in range(n_rock - 2):
		var fi: float = float(i)
		var ang: float = ring_a + fi * TAU / float(maxi(n_rock - 2, 1)) + rng.randf_range(-0.35, 0.35)
		var dist: float = rng.randf_range(0.18, 0.27)
		var rr := Vector3(rng.randf_range(0.14, 0.21), rng.randf_range(0.09, 0.15), rng.randf_range(0.14, 0.20))
		var rc := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		var mr: StandardMaterial3D = mat_rock if (i % 2) == 0 else mat_rock_b
		_rock(root, rng, mr, rc, rr, rng.randf_range(0.12, 0.20), true)
	var n_perch: int = rng.randi_range(1, 2)
	for _i in range(n_perch):
		var ang2: float = rng.randf_range(0.0, TAU)
		var d2: float = rng.randf_range(0.18, 0.30)
		var pr := Vector3(rng.randf_range(0.10, 0.16), rng.randf_range(0.07, 0.11), rng.randf_range(0.10, 0.15))
		var pc := Vector3(cos(ang2) * d2, rng.randf_range(0.20, 0.30), sin(ang2) * d2 - 0.05)
		_rock(root, rng, mat_rock_b, pc, pr, rng.randf_range(0.14, 0.24), false)
	var n_peb: int = rng.randi_range(3, 5)
	for _i in range(n_peb):
		var ang3: float = rng.randf_range(0.0, TAU)
		var d3: float = rng.randf_range(0.32, 0.44)
		var sr: float = rng.randf_range(0.045, 0.085)
		var pebr := Vector3(sr, sr * rng.randf_range(0.55, 0.80), sr * rng.randf_range(0.75, 1.10))
		var pp := Vector3(cos(ang3) * d3, 0.0, sin(ang3) * d3)
		if Vector2(pp.x - an_x, pp.z - an_z).length() < 0.19:
			continue
		_rock(root, rng, mat_rock_b, pp, pebr, 0.22, true)

	# every child from here to the animal is FLESH — an axis works on that span
	var mark_a: int = root.get_child_count()

	# --- the skeleton: joints and radii, drawn before anything is emitted -----
	# both bodies read from here — the primitive one and the poured one — so the
	# fused value is the SAME figure and not a second design
	var p_a := Vector3(lean * 0.25, 0.560, 0.115)
	var p_b := Vector3(lean * 0.60, 0.895, 0.070)
	var p_c := Vector3(lean, 1.115, -0.130 - slump * 0.60)
	var rx_keys: Array = [0.205 * hip_k, 0.198 * hip_k, 0.172, 0.163, 0.176, 0.183, 0.148, 0.078]
	var rz_keys: Array = [0.180 * hip_k, 0.176 * hip_k, 0.152, 0.146, 0.152, 0.150, 0.126, 0.074]

	var t_c: Array[Vector3] = []
	var t_b: Array[Basis] = []
	var t_front: Array[Vector3] = []
	var t_side: Array[Vector3] = []
	var t_rx: Array[float] = []
	var t_rz: Array[float] = []
	for i in range(n_t):
		var t: float = float(i) / float(n_t - 1)
		var q: Vector3 = _bez(p_a, p_b, p_c, t)
		var q0: Vector3 = _bez(p_a, p_b, p_c, maxf(t - 0.03, 0.0))
		var q1: Vector3 = _bez(p_a, p_b, p_c, minf(t + 0.03, 1.0))
		var tang: Vector3 = (q1 - q0).normalized()
		var bs: Basis = _basis_y_to(tang)
		t_c.append(q)
		t_b.append(bs)
		t_front.append((bs * Vector3(0.0, 0.0, -1.0)).normalized())
		t_side.append((bs * Vector3(1.0, 0.0, 0.0)).normalized())
		t_rx.append(_key(rx_keys, t))
		t_rz.append(_key(rz_keys, t))

	var i_belly: int = int(floor(float(n_t - 1) * 0.30))
	var i_hip: int = int(floor(float(n_t - 1) * 0.07))
	var i_chest: int = int(floor(float(n_t - 1) * 0.70))
	var i_sh: int = int(floor(float(n_t - 1) * 0.90))
	var neck_up: Vector3 = (t_c[n_t - 1] - t_c[n_t - 3]).normalized()
	var head_bs: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, -head_pitch) * Basis(Vector3.BACK, head_roll)
	var head_c: Vector3 = t_c[n_t - 1] + neck_up * 0.152 + Vector3(sb * 0.010, 0.030, -0.030)
	var head_up: Vector3 = (head_bs * Vector3(0.0, 1.0, 0.0)).normalized()

	var sh_a: Vector3 = t_c[i_sh] + t_side[i_sh] * (sb * 0.170)
	var el_a := Vector3(sb * 0.330, 0.700, -0.205 - slump * 0.20)
	var wr_a := Vector3(sb * 0.420, 0.300, -0.195 - slump * 0.20)
	var hn_a := Vector3(sb * 0.448, 0.058, -0.190 - slump * 0.20)
	var sh_f: Vector3 = t_c[i_sh] + t_side[i_sh] * (-sb * 0.170)
	var el_f := Vector3(-sb * 0.300, 0.760, -0.240 - slump * 0.30)
	var wr_f := Vector3(-sb * 0.302, 0.530, -0.235 - slump * 0.20)
	var hn_f := Vector3(-sb * 0.292, 0.428, -0.238 - slump * 0.10)
	var hip_l := Vector3(lb * 0.155 * hip_k, 0.540, 0.030)
	var knee_l := Vector3(knee_x, 0.278, knee_z)
	var ank_l := Vector3(lb * 0.305, 0.118, knee_z - 0.175)
	var toe_l := Vector3(lb * 0.312, 0.058, knee_z - 0.262)
	var hip_t := Vector3(sb * 0.155 * hip_k, 0.540, 0.055)
	var knee_t := Vector3(sb * 0.252, 0.300, -0.030)
	var ank_t := Vector3(sb * 0.288, 0.148, 0.232)
	var toe_t := Vector3(sb * 0.294, 0.062, 0.322)

	# --- axis "clay" = fused: the body POURED, not assembled ------------------
	# the mesher is young: if it hands back nothing, fall through to the primitive
	# body rather than leaving a plinth with a heap of rocks and no figure on it
	var fused: bool = clay == "fused"
	var iso_mi: MeshInstance3D = null
	if fused:
		var parts: Array = []
		# torso — six capsules down the SAME bezier, radius the mean of the two
		# ellipse axes the primitive links use
		var n_seg: int = 6
		for i in range(n_seg):
			var ta: float = float(i) / float(n_seg)
			var tb2: float = float(i + 1) / float(n_seg)
			var ra: float = (_key(rx_keys, ta) + _key(rz_keys, ta)) * 0.5
			var rb: float = (_key(rx_keys, tb2) + _key(rz_keys, tb2)) * 0.5
			parts.append(Iso.capsule(_bez(p_a, p_b, p_c, ta), _bez(p_a, p_b, p_c, tb2), ra, rb))
		# the bulges a chain will not give — the same offsets as the primitives
		parts.append(Iso.sphere(t_c[i_belly] + t_front[i_belly] * 0.085 + Vector3(0.0, -0.015, 0.0), 0.164 * belly_k))
		parts.append(Iso.sphere(t_c[i_hip] - t_front[i_hip] * 0.090, 0.158 * hip_k))
		for s_i in range(2):
			var sd_i: float = -1.0 if s_i == 0 else 1.0
			parts.append(Iso.sphere(t_c[i_hip] + t_side[i_hip] * (sd_i * 0.140 * hip_k) + Vector3(0.0, 0.010, 0.0), 0.131 * hip_k))
		for s_i in range(2):
			var sd_j: float = -1.0 if s_i == 0 else 1.0
			parts.append(Iso.sphere(t_c[i_chest] + t_side[i_chest] * (sd_j * 0.088) + t_front[i_chest] * 0.078, 0.090))
		for s_i in range(2):
			var sd_k: float = -1.0 if s_i == 0 else 1.0
			parts.append(Iso.sphere(t_c[i_sh] + t_side[i_sh] * (sd_k * 0.130), 0.104))
		# neck and skull are ONE pour: the capsule runs into the ovoid and the
		# fillet does the rest, so there is no join to find
		parts.append(Iso.capsule(t_c[n_t - 1] + neck_up * 0.020, head_c - head_up * 0.050, 0.072, 0.088))
		parts.append(Iso.capsule(head_c - head_up * 0.016 * head_k, head_c + head_up * 0.016 * head_k, 0.118 * head_k))
		# the braced arm, straight down into a mitt flat on the floor
		parts.append(Iso.capsule(sh_a, el_a, 0.092, 0.070))
		parts.append(Iso.capsule(el_a, wr_a, 0.070, 0.054))
		parts.append(Iso.capsule(wr_a, Vector3(hn_a.x, 0.096, hn_a.z), 0.054, 0.050))
		parts.append(Iso.box(Vector3(hn_a.x, 0.078, hn_a.z - 0.012), Vector3(0.070, 0.038, 0.084), 0.030))
		for f_i in range(3):
			var ff: float = float(f_i) - 1.0
			var fa := Vector3(hn_a.x + sb * 0.010 + ff * 0.040, 0.040, hn_a.z - 0.072)
			var fb := Vector3(hn_a.x + sb * 0.010 + ff * 0.046, 0.040, hn_a.z - 0.126 + absf(ff) * 0.018)
			parts.append(Iso.capsule(fa, fb, 0.024))
		# the free arm, hand laid on the heavy thigh
		parts.append(Iso.capsule(sh_f, el_f, 0.090, 0.068))
		parts.append(Iso.capsule(el_f, wr_f, 0.068, 0.052))
		parts.append(Iso.capsule(wr_f, hn_f, 0.052, 0.048))
		parts.append(Iso.box(hn_f + Vector3(0.0, -0.020, -0.024), Vector3(0.052, 0.028, 0.070), 0.026))
		# the heavy leg thrown forward, the tucked leg folded back
		parts.append(Iso.capsule(hip_l, knee_l, 0.158, 0.108))
		parts.append(Iso.capsule(knee_l, ank_l, 0.108, 0.064))
		parts.append(Iso.box(Vector3(toe_l.x, 0.070, toe_l.z), Vector3(0.058, 0.036, 0.082), 0.028))
		parts.append(Iso.capsule(hip_t, knee_t, 0.146, 0.102))
		parts.append(Iso.capsule(knee_t, ank_t, 0.102, 0.060))
		parts.append(Iso.box(Vector3(toe_t.x, 0.072, toe_t.z), Vector3(0.054, 0.034, 0.078), 0.026))
		# the navel: a place the field never crossed zero. subtracted smoothly, so
		# it has a lip and reads as a well in the clay rather than a drilled hole
		# 0.165 out against a 0.082 radius against a 0.164 belly: the well is about
		# 8 cm deep, a navel and not a wound, and it never reaches the torso capsule
		parts.append(Iso.cut(Iso.sphere(t_c[i_belly] + t_front[i_belly] * (0.085 + 0.165 * belly_k) + Vector3(0.0, -0.015, 0.0), 0.082)))

		iso_mi = Iso.add_body(root, parts, mat_skin, 0.055, 0.12)
		if iso_mi == null:
			# the mesher gave nothing: the primitive body is built below instead
			fused = false
		else:
			# keep the pour off the floor MYSELF — the settle lifts the whole heap
			# to the lowest point, so a body dipping under zero would float the rocks
			var ab: AABB = iso_mi.mesh.get_aabb()
			if ab.position.y < 0.0:
				iso_mi.transform = Transform3D(Basis(), Vector3(0.0, -ab.position.y, 0.0))

	# --- the body, assembled -------------------------------------------------
	if not fused:
		for i in range(n_t):
			_ellipsoid(root, mat_skin, t_c[i], Vector3(t_rx[i], 0.062, t_rz[i]), t_b[i])
		# belly, buttock, hip shelves, chest — the bulges a chain will not give
		_ellipsoid(root, mat_skin, t_c[i_belly] + t_front[i_belly] * 0.085 + Vector3(0.0, -0.015, 0.0), Vector3(0.176 * belly_k, 0.150 * belly_k, 0.166 * belly_k), t_b[i_belly])
		_ellipsoid(root, mat_skin, t_c[i_hip] - t_front[i_hip] * 0.090, Vector3(0.180 * hip_k, 0.145, 0.150), t_b[i_hip])
		for s_i in range(2):
			var sd: float = -1.0 if s_i == 0 else 1.0
			_ellipsoid(root, mat_skin, t_c[i_hip] + t_side[i_hip] * (sd * 0.140 * hip_k) + Vector3(0.0, 0.010, 0.0), Vector3(0.134 * hip_k, 0.130, 0.150), t_b[i_hip])
		for s_i in range(2):
			var sd2: float = -1.0 if s_i == 0 else 1.0
			_ellipsoid(root, mat_skin, t_c[i_chest] + t_side[i_chest] * (sd2 * 0.088) + t_front[i_chest] * 0.078, Vector3(0.096, 0.086, 0.090), t_b[i_chest])
		for s_i in range(2):
			var sd3: float = -1.0 if s_i == 0 else 1.0
			_ellipsoid(root, mat_skin, t_c[i_sh] + t_side[i_sh] * (sd3 * 0.130), Vector3(0.108, 0.098, 0.108), t_b[i_sh])
		# neck and head
		_ellipsoid(root, mat_head, t_c[n_t - 1] + neck_up * 0.045, Vector3(0.070, 0.058, 0.068), t_b[n_t - 1])
		_ellipsoid(root, mat_head, t_c[n_t - 1] + neck_up * 0.088, Vector3(0.076, 0.058, 0.074), t_b[n_t - 1])
		_ellipsoid(root, mat_head, head_c, Vector3(0.116 * head_k, 0.128 * head_k, 0.120 * head_k), head_bs)
		# the braced arm, straight down to the floor
		_chain(root, mat_skin, sh_a, el_a, 0.092, 0.070, n_arm)
		_chain(root, mat_skin, el_a, wr_a, 0.070, 0.054, n_arm)
		# the mitt is FLAT on the floor — 0.046 centre against a 0.040 half-height
		_ellipsoid(root, mat_skin, Vector3(hn_a.x, 0.046, hn_a.z - 0.012), Vector3(0.078, 0.040, 0.092), Basis(Vector3.UP, sb * 0.30))
		for f_i in range(3):
			var ff2: float = float(f_i) - 1.0
			var fp := Vector3(hn_a.x + sb * 0.010 + ff2 * 0.040, 0.024, hn_a.z - 0.104 + absf(ff2) * 0.020)
			_ellipsoid(root, mat_skin, fp, Vector3(0.022, 0.021, 0.036), Basis(Vector3.UP, ff2 * 0.24))
		# the free arm, hand laid on the heavy thigh
		_chain(root, mat_skin, sh_f, el_f, 0.090, 0.068, n_arm)
		_chain(root, mat_skin, el_f, wr_f, 0.068, 0.052, n_arm)
		_ellipsoid(root, mat_skin, hn_f + Vector3(0.0, -0.020, -0.024), Vector3(0.062, 0.036, 0.082), Basis(Vector3.UP, -sb * 0.22))
		# the heavy leg, thrown forward over the front rock
		_chain(root, mat_skin, hip_l, knee_l, 0.158, 0.108, n_thigh)
		_chain(root, mat_skin, knee_l, ank_l, 0.108, 0.064, n_shin)
		_ellipsoid(root, mat_skin, toe_l, Vector3(0.072, 0.048, 0.100), Basis(Vector3.UP, lb * 0.16))
		# the tucked leg, folded back under the hip
		_chain(root, mat_skin, hip_t, knee_t, 0.146, 0.102, n_thigh - 1)
		_chain(root, mat_skin, knee_t, ank_t, 0.102, 0.060, n_shin - 1)
		_ellipsoid(root, mat_skin, toe_t, Vector3(0.066, 0.044, 0.094), Basis(Vector3.UP, -sb * 0.20))

	# --- the two closed lids, on both bodies ---------------------------------
	for s_i in range(2):
		var sd4: float = -1.0 if s_i == 0 else 1.0
		var lid_bs: Basis = head_bs * Basis(Vector3.BACK, -sd4 * 0.24)
		# the dash has to stand PROUD: the head surface at this x/y is z = -0.1075 * head_k
		var lid_p: Vector3 = head_c + head_bs * Vector3(sd4 * 0.050 * head_k, 0.016 * head_k, -0.106 * head_k)
		_ellipsoid(root, mat_lid, lid_p, Vector3(0.034, 0.0075, 0.009) * head_k, lid_bs)

	# --- what the pour left behind ------------------------------------------
	# an isosurface is ONE mesh, and the contract asks for forty. these are not
	# padding: a poured body drips, and the drips are what makes it read as poured
	if fused:
		var segs: Array = [
			[sh_a, el_a], [el_a, wr_a], [sh_f, el_f], [el_f, wr_f],
			[hip_l, knee_l], [knee_l, ank_l], [hip_t, knee_t], [knee_t, ank_t],
			[t_c[i_hip], t_c[i_chest]], [t_c[i_belly], t_c[i_sh]],
		]
		for _i in range(20):
			var pair: Array = segs[rng.randi_range(0, segs.size() - 1)]
			var a0: Vector3 = pair[0]
			var b0: Vector3 = pair[1]
			var tt: float = rng.randf_range(0.12, 0.92)
			var pd: Vector3 = a0.lerp(b0, tt)
			var jit := Vector3(rng.randf_range(-0.058, 0.058), 0.0, rng.randf_range(-0.058, 0.058))
			var drop: float = rng.randf_range(0.055, 0.120)
			var dr: float = rng.randf_range(0.026, 0.048)
			var dy: float = maxf(pd.y - drop, 0.036)
			_ellipsoid(root, mat_skin, Vector3(pd.x, dy, pd.z) + jit, Vector3(dr, dr * 1.45, dr), Basis())
		for _i in range(8):
			var ang4: float = rng.randf_range(0.0, TAU)
			var d4: float = rng.randf_range(0.22, 0.46)
			var pp4 := Vector3(cos(ang4) * d4, 0.0, sin(ang4) * d4)
			# reflected, never skipped: the mesh floor is only safe if the count is fixed
			if Vector2(pp4.x - an_x, pp4.z - an_z).length() < 0.17:
				pp4 = Vector3(-pp4.x, 0.0, -pp4.z)
			var prr := Vector3(rng.randf_range(0.055, 0.105), rng.randf_range(0.014, 0.028), rng.randf_range(0.055, 0.105))
			_rock(root, rng, mat_skin, pp4, prr, 0.16, true)

	var mark_b: int = root.get_child_count()

	# --- one small clay animal on the floor beside the heap -------------------
	if is_fish:
		_fish(root, rng, Vector3(an_x, 0.0, an_z), an_yaw, an_fin, accent)
	else:
		_duck(root, rng, Vector3(an_x, 0.0, an_z), an_yaw, an_fin, accent)

	# --- the flesh, gathered so an axis can take hold of all of it ------------
	# the iso body is kept OUT: it has no per-part scale to read, and a crust
	# sized off its identity basis would be a 1.4 m slab through the whole statue
	var flesh: Array = []
	for i_f in range(mark_a, mini(mark_b, root.get_child_count())):
		var ch: Node = root.get_child(i_f)
		if ch is MeshInstance3D and ch != iso_mi:
			flesh.append(ch)

	# --- axis "paint": the flat colour, made matter ---------------------------
	if paint != "flat":
		# one pour, one finish: six glaze pots mixed once and shared, because a
		# holo sweep texture per slab is eleven 192x192 textures for one statue
		var paint_fin: String = LOUD[rng.randi_range(0, LOUD.size() - 1)]
		var pmats: Array = []
		for i_m in range(paints.size()):
			pmats.append(Gloss.skin(paint_fin, paints[i_m], rng))
		var pdark: StandardMaterial3D = Gloss.skin("patent", (paints[0] as Color).darkened(0.52), rng)
		if paint == "crust":
			# the fused body's flesh list is drips, which are small — so the slab
			# floor is raised, or eleven crusts would be eleven beads
			var min_r: float = 0.085 if fused else 0.038
			_crust(root, rng, flesh, pmats, min_r)
		elif paint == "flood":
			_flood(root, rng, paints, paint_fin)
		elif paint == "bloom":
			_flower(root, rng, Vector3(hn_a.x, 0.088, hn_a.z - 0.030), Vector3(sb * 0.30, 1.0, -0.20), 0.108, pmats, pdark)
			_flower(root, rng, hn_f + Vector3(0.0, 0.010, -0.060), Vector3(-sb * 0.35, 0.55, -1.0), 0.100, pmats, pdark)
			_flower(root, rng, toe_l + Vector3(0.0, 0.032, -0.050), Vector3(lb * 0.30, 1.0, -0.45), 0.098, pmats, pdark)
			_flower(root, rng, toe_t + Vector3(0.0, 0.032, 0.050), Vector3(sb * 0.30, 1.0, 0.45), 0.092, pmats, pdark)
			_flower(root, rng, head_c + Vector3(0.0, 0.118 * head_k, 0.0), Vector3(0.0, 1.0, -0.30), 0.132, pmats, pdark)

	# --- axis "clay": what the clay is doing to itself ------------------------
	# the room left under the 260-mesh ceiling, measured AFTER the paint stage,
	# so a crusted swarm and a flooded twin both stay legal
	var room: int = 236 - root.get_child_count()
	if clay == "melted":
		_melt(root, rng, flesh, mat_skin)
	elif clay == "swarm":
		_swarm(root, rng, flesh, room)
	elif clay == "fossil":
		_fossil(flesh)
	elif clay == "mirrored":
		_mirror(root, flesh, t_c[i_sh] + Vector3(0.0, 0.060, 0.0), room)

	# --- stature, then the measured settle ------------------------------------
	_rescale(root, body_k, Vector3.ZERO)

	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = 1.68 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_rescale(root, kfit, Vector3.ZERO)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	_shift(root, Vector3(-centre.x, -box.position.y, -centre.z))


# ---------------------------------------------------------------------------
# the clay animals — same kiln, its own pot

static func _fish(root: Node3D, rng: RandomNumberGenerator, at: Vector3, yaw: float, fin: String, tint: Color) -> void:
	var body_c: Color = Color("#6F9A5E").lerp(Color("#82A96A"), rng.randf()).lerp(tint, 0.42)
	var mat_b: StandardMaterial3D = Gloss.skin(fin, body_c, rng)
	var mat_f: StandardMaterial3D = Gloss.skin(fin, body_c.darkened(0.18), rng)
	var mat_w: StandardMaterial3D = Gloss.skin("pearl", Color("#F2EADD"), rng)
	var mat_p: StandardMaterial3D = Gloss.skin("patent", Color("#2E2723"), rng)
	var fb := Basis(Vector3.UP, yaw)
	var ln: float = rng.randf_range(0.92, 1.14)
	var base: Vector3 = at + Vector3(0.0, 0.062, 0.0)
	_ellipsoid(root, mat_b, base, Vector3(0.086 * ln, 0.062, 0.054), fb)
	_ellipsoid(root, mat_b, base + fb * Vector3(0.062 * ln, -0.004, 0.0), Vector3(0.058 * ln, 0.052, 0.046), fb)
	# the prism's apex is +Y, so a turn of -90 deg about Z aims it back into the body
	var tail := PrismMesh.new()
	tail.size = Vector3(0.076, 0.098 * ln, 0.017)
	var tm: MeshInstance3D = _add(root, tail, mat_f)
	tm.transform = Transform3D(fb * Basis(Vector3.BACK, -PI * 0.5), base + fb * Vector3(-0.128 * ln, 0.012, 0.0))
	var dors := PrismMesh.new()
	dors.size = Vector3(0.052 * ln, 0.038, 0.014)
	var dm: MeshInstance3D = _add(root, dors, mat_f)
	dm.transform = Transform3D(fb, base + fb * Vector3(-0.012, 0.058, 0.0))
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var ep: Vector3 = base + fb * Vector3(0.082 * ln, 0.020, sd * 0.036)
		_ellipsoid(root, mat_w, ep, Vector3(0.019, 0.019, 0.016), fb)
		# the pupil has to clear the bead it sits on, not hide inside it
		_ellipsoid(root, mat_p, ep + fb * Vector3(0.006, 0.0, sd * 0.014), Vector3(0.010, 0.010, 0.010), fb)


static func _duck(root: Node3D, rng: RandomNumberGenerator, at: Vector3, yaw: float, fin: String, tint: Color) -> void:
	var body_c: Color = Color("#E3B534").lerp(Color("#EDC85C"), rng.randf()).lerp(tint, 0.42)
	var mat_b: StandardMaterial3D = Gloss.skin(fin, body_c, rng)
	var mat_k: StandardMaterial3D = Gloss.skin(fin, Color("#D8813A").lerp(tint, 0.30), rng)
	var mat_p: StandardMaterial3D = Gloss.skin("patent", Color("#2E2723"), rng)
	var fb := Basis(Vector3.UP, yaw)
	var ln: float = rng.randf_range(0.94, 1.12)
	var base: Vector3 = at + Vector3(0.0, 0.070, 0.0)
	_ellipsoid(root, mat_b, base, Vector3(0.090 * ln, 0.070, 0.066), fb)
	_ellipsoid(root, mat_b, base + fb * Vector3(0.056 * ln, 0.038, 0.0), Vector3(0.048, 0.048, 0.044), fb)
	_ellipsoid(root, mat_b, base + fb * Vector3(0.078 * ln, 0.080, 0.0), Vector3(0.050, 0.048, 0.048), fb)
	# beak: apex forward. tail: apex cocked up and back off the rump
	var beak := PrismMesh.new()
	beak.size = Vector3(0.030, 0.046, 0.021)
	var bm: MeshInstance3D = _add(root, beak, mat_k)
	bm.transform = Transform3D(fb * Basis(Vector3.BACK, -PI * 0.5), base + fb * Vector3(0.116 * ln, 0.072, 0.0))
	var tail := PrismMesh.new()
	tail.size = Vector3(0.050, 0.064 * ln, 0.017)
	var tm: MeshInstance3D = _add(root, tail, mat_b)
	tm.transform = Transform3D(fb * Basis(Vector3.BACK, 0.64), base + fb * Vector3(-0.092 * ln, 0.038, 0.0))
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		# on the head's surface, not inside it: the 0.050 sphere sits at (0.078*ln, 0.080)
		_ellipsoid(root, mat_p, base + fb * Vector3(0.078 * ln + 0.028, 0.098, sd * 0.039), Vector3(0.010, 0.010, 0.010), fb)


# ---------------------------------------------------------------------------
# geometry helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _ellipsoid(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 20
	sph.rings = 11
	var mi: MeshInstance3D = _add(root, sph, mat)
	# the squash has to happen in the ellipsoid's OWN frame, so b * diag, never scaled()
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _chain(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r0: float, r1: float, n: int) -> void:
	var steps: int = maxi(n, 2)
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var p: Vector3 = a.lerp(b, t)
		var r: float = lerpf(r0, r1, t)
		_ellipsoid(root, mat, p, Vector3(r, r, r), Basis())


static func _bez(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var u: float = 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)


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
# the rocks — SurfaceTool spheres, lobed, squashed, flat-bottomed

static func _rock(root: Node3D, rng: RandomNumberGenerator, mat: StandardMaterial3D, c: Vector3, r: Vector3, bump: float, flat: bool) -> MeshInstance3D:
	var segs: int = 18
	var rings: int = 11
	var ax: Array[Vector3] = []
	var fq: Array[float] = []
	var am: Array[float] = []
	var ph: Array[float] = []
	for _k in range(3):
		var a := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		if a.length() < 0.01:
			a = Vector3.UP
		ax.append(a.normalized())
		fq.append(rng.randf_range(1.3, 3.1))
		am.append(bump * rng.randf_range(0.45, 1.0))
		ph.append(rng.randf_range(0.0, TAU))
	var grid: Array = []
	var min_y: float = 1.0e9
	for i in range(rings + 1):
		var row: Array = []
		var v: float = float(i) / float(rings)
		var phi: float = v * PI
		for j in range(segs + 1):
			var u: float = float(j) / float(segs)
			var th: float = u * TAU
			var d := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var f: float = 1.0
			for k in range(3):
				var a3: Vector3 = ax[k]
				var f3: float = fq[k]
				var m3: float = am[k]
				var p3: float = ph[k]
				f += m3 * sin(d.dot(a3) * f3 * PI + p3)
			var p := Vector3(d.x * r.x * f, d.y * r.y * f, d.z * r.z * f)
			min_y = minf(min_y, p.y)
			row.append(p)
		grid.append(row)

	# a flat rock is CUT, then lifted so its cut face is local y = 0 — measured off
	# the real minimum, because the lobes can pull the underside anywhere
	var cut: float = 0.0
	if flat:
		cut = min_y * 0.88
		for i in range(rings + 1):
			var row_c: Array = grid[i]
			for j in range(segs + 1):
				var pc: Vector3 = row_c[j]
				row_c[j] = Vector3(pc.x, maxf(pc.y, cut) - cut, pc.z)
	var inside := Vector3(0.0, -cut, 0.0)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings):
		var row0: Array = grid[i]
		var row1: Array = grid[i + 1]
		for j in range(segs):
			var p00: Vector3 = row0[j]
			var p01: Vector3 = row0[j + 1]
			var p10: Vector3 = row1[j]
			var p11: Vector3 = row1[j + 1]
			_tri_out(st, p00, p10, p11, inside)
			_tri_out(st, p00, p11, p01, inside)
	st.generate_normals()
	var rock_mesh: ArrayMesh = st.commit()
	var mi: MeshInstance3D = _add(root, rock_mesh, mat)
	mi.transform = Transform3D(Basis(), c)
	return mi


static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(b - a)
	if nf.length() < 0.0000001:
		return
	var centroid: Vector3 = (a + b + c) / 3.0
	if nf.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


# ---------------------------------------------------------------------------
# painted skins — every pixel drawn in code, and every one of them lives UNDER
# a DreamSkin glaze rather than instead of it

static func _lattice(rng: RandomNumberGenerator, cells: int) -> PackedFloat32Array:
	var v := PackedFloat32Array()
	for _i in range(cells * cells):
		v.append(rng.randf())
	return v


static func _lattice_at(v: PackedFloat32Array, cells: int, u: float, w: float) -> float:
	var fx: float = u * float(cells)
	var fy: float = w * float(cells)
	var x0: int = int(floor(fx))
	var y0: int = int(floor(fy))
	var tx: float = fx - float(x0)
	var ty: float = fy - float(y0)
	var sx: float = tx * tx * (3.0 - 2.0 * tx)
	var sy: float = ty * ty * (3.0 - 2.0 * ty)
	var a: float = v[posmod(y0, cells) * cells + posmod(x0, cells)]
	var b: float = v[posmod(y0, cells) * cells + posmod(x0 + 1, cells)]
	var c: float = v[posmod(y0 + 1, cells) * cells + posmod(x0, cells)]
	var d: float = v[posmod(y0 + 1, cells) * cells + posmod(x0 + 1, cells)]
	var ab: float = lerpf(a, b, sx)
	var cd: float = lerpf(c, d, sx)
	return lerpf(ab, cd, sy)


static func _tint(c: Color, m: float) -> Color:
	return Color(clampf(c.r * m, 0.0, 1.0), clampf(c.g * m, 0.0, 1.0), clampf(c.b * m, 0.0, 1.0))


# --- the flat splashes on a chalky ground -----------------------------------

static func _splash_texture(rng: RandomNumberGenerator, ground: Color, pal: Array) -> ImageTexture:
	var n: int = SPLASH_TEX
	var fn: float = float(n)
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGB8)
	var chalk: PackedFloat32Array = _lattice(rng, CHALK_CELLS)
	var grain: PackedFloat32Array = _lattice(rng, GRAIN_CELLS)
	for y in range(n):
		var fy: float = (float(y) + 0.5) / fn
		for x in range(n):
			var fx: float = (float(x) + 0.5) / fn
			var m: float = 0.935 + 0.095 * _lattice_at(chalk, CHALK_CELLS, fx, fy) + 0.040 * (_lattice_at(grain, GRAIN_CELLS, fx, fy) - 0.5)
			img.set_pixel(x, y, _tint(ground, m))
	var n_b: int = rng.randi_range(6, 10)
	for _b in range(n_b):
		var col: Color = pal[rng.randi_range(0, pal.size() - 1)]
		var cx: float = rng.randf_range(0.0, fn)
		var cy: float = rng.randf_range(0.0, fn)
		var r0: float = rng.randf_range(0.12, 0.25) * fn
		_blotch(img, rng, cx, cy, r0, col, chalk)
		var n_s: int = rng.randi_range(1, 3)
		for _s in range(n_s):
			var sx: float = cx + rng.randf_range(-1.9, 1.9) * r0
			var sy: float = cy + rng.randf_range(-1.9, 1.9) * r0
			_blotch(img, rng, sx, sy, r0 * rng.randf_range(0.10, 0.26), col, chalk)
	return ImageTexture.create_from_image(img)


static func _blotch(img: Image, rng: RandomNumberGenerator, cx: float, cy: float, r0: float, col: Color, chalk: PackedFloat32Array) -> void:
	var n: int = img.get_width()
	var fn: float = float(n)
	var w1: float = rng.randf_range(0.10, 0.26)
	var w2: float = rng.randf_range(0.04, 0.14)
	var p1: float = rng.randf_range(0.0, TAU)
	var p2: float = rng.randf_range(0.0, TAU)
	var k1: float = float(rng.randi_range(2, 4))
	var k2: float = float(rng.randi_range(5, 8))
	var soft: float = maxf(1.8, r0 * rng.randf_range(0.07, 0.17))
	var strength: float = rng.randf_range(0.88, 0.98)
	var rad: int = int(ceil(r0 * (1.0 + w1 + w2) + soft + 2.0))
	var icx: int = int(round(cx))
	var icy: int = int(round(cy))
	for dy in range(-rad, rad + 1):
		var ay: float = float(dy)
		for dx in range(-rad, rad + 1):
			var axf: float = float(dx)
			var dist: float = sqrt(axf * axf + ay * ay)
			if dist > float(rad):
				continue
			var ang: float = atan2(ay, axf)
			var rr: float = r0 * (1.0 + w1 * sin(k1 * ang + p1) + w2 * sin(k2 * ang + p2))
			var a: float = clampf((rr - dist) / soft, 0.0, 1.0)
			if a <= 0.004:
				continue
			var sm: float = a * a * (3.0 - 2.0 * a) * strength
			var px: int = posmod(icx + dx, n)
			var py: int = posmod(icy + dy, n)
			var mo: float = 0.92 + 0.14 * _lattice_at(chalk, CHALK_CELLS, (float(px) + 0.5) / fn, (float(py) + 0.5) / fn)
			var prev: Color = img.get_pixel(px, py)
			img.set_pixel(px, py, prev.lerp(_tint(col, mo), sm))


# --- the fine grey scale bodysuit -------------------------------------------

static func _scale_texture(rng: RandomNumberGenerator) -> ImageTexture:
	var n: int = SCALE_TEX
	var fn: float = float(n)
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGB8)
	var cols: int = 18
	var rows: int = 24
	var cw: float = fn / float(cols)
	var rh: float = fn / float(rows)
	var tint: PackedFloat32Array = PackedFloat32Array()
	for _i in range(cols * rows):
		tint.append(rng.randf_range(0.90, 1.10))
	var base := Color("#A9A9A4")
	var groove: float = 0.62
	var hw: float = cw * 0.60
	var hh: float = rh * 0.92
	for y in range(n):
		var py: float = float(y) + 0.5
		var r_here: int = int(floor(py / rh))
		for x in range(n):
			var px: float = float(x) + 0.5
			var shade: float = groove
			# a scale from a lower row laps over the one above it, so the last hit wins
			for rr in range(r_here - 2, r_here + 1):
				var rw: int = posmod(rr, rows)
				var off: float = 0.5 * cw if (rw % 2) == 1 else 0.0
				var cy: float = (float(rr) + 0.5) * rh
				var cc0: int = int(floor((px - off) / cw))
				for cc in range(cc0 - 1, cc0 + 2):
					var cx: float = (float(cc) + 0.5) * cw + off
					var ux: float = (px - cx) / hw
					var uy: float = (py - cy) / hh
					var q: float = ux * ux + uy * uy
					if q > 1.0:
						continue
					var edge: float = clampf((1.0 - q) / 0.22, 0.0, 1.0)
					var lit: float = 1.02 - 0.32 * clampf(uy * 0.5 + 0.5, 0.0, 1.0)
					var tk: float = tint[rw * cols + posmod(cc, cols)]
					shade = lerpf(groove, lit * tk, edge)
			img.set_pixel(x, y, _tint(base, shade * 1.15))
	return ImageTexture.create_from_image(img)


# --- the chalky speckle worn by rocks and by a bare head ---------------------

static func _speckle_texture(rng: RandomNumberGenerator) -> ImageTexture:
	var n: int = SPECK_TEX
	var fn: float = float(n)
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGB8)
	var big: PackedFloat32Array = _lattice(rng, 8)
	var fine: PackedFloat32Array = _lattice(rng, 32)
	for y in range(n):
		var fy: float = (float(y) + 0.5) / fn
		for x in range(n):
			var fx: float = (float(x) + 0.5) / fn
			var m: float = 0.80 + 0.16 * _lattice_at(big, 8, fx, fy) + 0.10 * _lattice_at(fine, 32, fx, fy)
			var g: float = clampf(m, 0.0, 1.0)
			img.set_pixel(x, y, Color(g, g, g * 0.995))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# axis "clay" — what the clay is doing to itself

static func _clone(root: Node3D, src: MeshInstance3D, tf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = src.mesh
	mi.material_override = src.material_override
	mi.transform = tf
	root.add_child(mi)
	return mi


# MELTED — a world-Y squash on every part plus a fall that grows with height, so
# the head pools down at the shoulders while the braced hand, already on the
# floor, stays where it is. Nothing may end below y = 0.03: the settle lifts the
# lowest point to zero, so one long drip would hoist the whole heap off the floor.
static func _melt(root: Node3D, rng: RandomNumberGenerator, flesh: Array, mat: StandardMaterial3D) -> void:
	var squash := Basis(Vector3(1.26, 0.0, 0.0), Vector3(0.0, 0.48, 0.0), Vector3(0.0, 0.0, 1.26))
	for i in range(flesh.size()):
		var mi: MeshInstance3D = flesh[i]
		var tf: Transform3D = mi.transform
		var o: Vector3 = tf.origin
		var f: float = clampf(o.y / 1.36, 0.0, 1.0)
		var drop: float = 0.66 * f * f
		var spread: float = 1.0 + 0.34 * f
		var ny: float = maxf(o.y - drop, 0.030)
		mi.transform = Transform3D(squash * tf.basis, Vector3(o.x * spread, ny, o.z * spread))
	# what ran off the body: flat-cut lobed puddles of skin lying on the floor
	for _i in range(6):
		var ang: float = rng.randf_range(0.0, TAU)
		var d: float = rng.randf_range(0.24, 0.50)
		var pr := Vector3(rng.randf_range(0.10, 0.19), rng.randf_range(0.020, 0.036), rng.randf_range(0.10, 0.19))
		_rock(root, rng, mat, Vector3(cos(ang) * d, 0.0, sin(ang) * d), pr, 0.12, true)


# SWARM — every part halves and drifts off the body's vertical axis, and while
# there is room under the mesh ceiling each one leaves a third-size copy of
# itself twice as far out. The pose survives; the skin does not.
static func _swarm(root: Node3D, rng: RandomNumberGenerator, flesh: Array, room: int) -> void:
	var made: int = 0
	for i in range(flesh.size()):
		var mi: MeshInstance3D = flesh[i]
		var tf: Transform3D = mi.transform
		var o: Vector3 = tf.origin
		var away := Vector3(o.x, 0.0, o.z)
		if away.length() < 0.02:
			away = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
			if away.length() < 0.02:
				away = Vector3.RIGHT
		var dir: Vector3 = away.normalized()
		var jit := Vector3(rng.randf_range(-0.055, 0.055), rng.randf_range(-0.045, 0.045), rng.randf_range(-0.055, 0.055))
		var push: float = rng.randf_range(0.045, 0.135)
		var p1: Vector3 = o + dir * push + jit
		var y1: float = maxf(p1.y, 0.030)
		mi.transform = Transform3D(tf.basis.scaled(Vector3(0.50, 0.50, 0.50)), Vector3(p1.x, y1, p1.z))
		if made < room:
			var p2: Vector3 = o + dir * (push * 2.2) + jit * 2.1
			var y2: float = maxf(p2.y, 0.030)
			_clone(root, mi, Transform3D(tf.basis.scaled(Vector3(0.33, 0.33, 0.33)), Vector3(p2.x, y2, p2.z)))
			made += 1


# FOSSIL — the squash happens in each part's OWN frame, which is what keeps this
# from being the melt: a torso link's local Y is the spine tangent, so it becomes
# a rib; a chain sphere's local Y is world up, so a limb becomes a stack of
# discs. The pose and the outline hold, the flesh between the plates is gone.
static func _fossil(flesh: Array) -> void:
	var plate := Basis(Vector3(1.12, 0.0, 0.0), Vector3(0.0, 0.15, 0.0), Vector3(0.0, 0.0, 1.12))
	for i in range(flesh.size()):
		var mi: MeshInstance3D = flesh[i]
		var tf: Transform3D = mi.transform
		mi.transform = Transform3D(tf.basis * plate, tf.origin)


# MIRRORED — a half-turn about Z taken around a pivot at the shoulder, so a
# second figure grows head-down out of the first with its pelvis in the air. A
# turn and never a negative scale, or the winding would flip and the twin would
# render inside out. The stride holds the clone count under the ceiling; the
# doubled height is the settle's problem, and it pulls the whole heap small.
static func _mirror(root: Node3D, flesh: Array, piv: Vector3, room: int) -> void:
	if room <= 0 or flesh.is_empty():
		return
	var rot := Basis(Vector3.BACK, PI)
	var xf := Transform3D(rot, piv - rot * piv)
	var stride: int = 1
	if flesh.size() > room:
		stride = int(ceil(float(flesh.size()) / float(maxi(room, 1))))
	var i: int = 0
	while i < flesh.size():
		var mi: MeshInstance3D = flesh[i]
		_clone(root, mi, xf * mi.transform)
		i += stride


# ---------------------------------------------------------------------------
# axis "paint" — the flat colour, made matter, in the LOUD finishes

# CRUST — a splash stops being a projection and becomes a lobed slab of matter
# clamped over whatever part it landed on, ignoring anatomy exactly as the
# painted one does, with a drip and a bead running off its underside. The drip
# is measured off the slab's own bottom and floored, never off a guessed depth.
# The slab is clamped at BOTH ends: a floor so it is visible, a ceiling so no
# part's scale can turn one splash into a slab across the whole statue.
static func _crust(root: Node3D, rng: RandomNumberGenerator, flesh: Array, pmats: Array, min_r: float) -> void:
	if flesh.is_empty() or pmats.is_empty():
		return
	for _i in range(11):
		var src: MeshInstance3D = flesh[rng.randi_range(0, flesh.size() - 1)]
		var tf: Transform3D = src.transform
		var sc: Vector3 = tf.basis.get_scale()
		var mat: StandardMaterial3D = pmats[rng.randi_range(0, pmats.size() - 1)]
		var k: float = rng.randf_range(1.24, 1.44)
		var rx: float = clampf(maxf(sc.x, min_r) * k, min_r, 0.30)
		var ry: float = clampf(maxf(sc.y, min_r) * k, min_r, 0.30)
		var rz: float = clampf(maxf(sc.z, min_r) * k, min_r, 0.30)
		var rr := Vector3(rx, ry, rz)
		var at: Vector3 = tf.origin + Vector3(rng.randf_range(-0.02, 0.02), rng.randf_range(-0.01, 0.02), rng.randf_range(-0.02, 0.02))
		_rock(root, rng, mat, at, rr, rng.randf_range(0.18, 0.28), false)
		var under: float = at.y - rr.y
		var dl: float = clampf(rng.randf_range(0.09, 0.26), 0.03, maxf(under - 0.06, 0.03))
		var dx: float = rng.randf_range(-0.030, 0.030)
		var dz: float = rng.randf_range(-0.030, 0.030)
		var sy: float = maxf(under - dl * 0.5, 0.055)
		_ellipsoid(root, mat, Vector3(at.x + dx, sy, at.z + dz), Vector3(0.020, maxf(dl * 0.5, 0.030), 0.020), Basis())
		var by: float = maxf(under - dl, 0.040)
		_ellipsoid(root, mat, Vector3(at.x + dx, by, at.z + dz), Vector3(0.032, 0.028, 0.032), Basis())


# FLOOD — one splash colour poured over the whole heap: a flat-cut lobed pool
# that drowns the rocks, the clay animal and both shins to the knee, a wider thin
# lip around its foot, tongues standing up out of the surface, and droplets held
# in the air above it. Poured in the LOUD finish, so the one matte thing left in
# the statue is whatever rock the pool did not reach.
static func _flood(root: Node3D, rng: RandomNumberGenerator, pal: Array, fin: String) -> void:
	var col: Color = pal[rng.randi_range(0, pal.size() - 1)]
	var mat: StandardMaterial3D = Gloss.skin(fin, col, rng)
	var lip: StandardMaterial3D = Gloss.skin(fin, col.lightened(0.12), rng)
	_rock(root, rng, lip, Vector3(0.0, 0.0, -0.020), Vector3(0.520, 0.050, 0.500), 0.06, true)
	_rock(root, rng, mat, Vector3(0.0, 0.0, -0.020), Vector3(0.420, 0.230, 0.410), 0.07, true)
	for _i in range(5):
		var ang: float = rng.randf_range(0.0, TAU)
		var d: float = rng.randf_range(0.20, 0.40)
		var h: float = rng.randf_range(0.16, 0.34)
		var foot: float = rng.randf_range(0.24, 0.34)
		var p := Vector3(cos(ang) * d, foot + h * 0.5, sin(ang) * d)
		var tb: Basis = Basis(Vector3.UP, ang) * Basis(Vector3.BACK, rng.randf_range(-0.40, 0.40))
		_ellipsoid(root, mat, p, Vector3(0.052, h * 0.5, 0.052), tb)
		_ellipsoid(root, mat, p + Vector3(0.0, h * 0.5 + 0.030, 0.0), Vector3(0.044, 0.044, 0.044), Basis())
	for _i in range(3):
		var ang2: float = rng.randf_range(0.0, TAU)
		var d2: float = rng.randf_range(0.16, 0.42)
		var yy: float = rng.randf_range(0.62, 1.05)
		var rd: float = rng.randf_range(0.028, 0.052)
		_ellipsoid(root, mat, Vector3(cos(ang2) * d2, yy, sin(ang2) * d2), Vector3(rd, rd * 1.35, rd), Basis())


# BLOOM — a splash colour, opened. Six petals splayed a third of a turn up out of
# the plane across the given axis, with a dark patent eye set into the middle;
# hung on both hands, both feet and the crown of the skull, so every end of the
# body that used to be a mitt or a toe is now a flower. The glaze pots are handed
# in, not mixed here: five flowers mixing their own would be ten textures.
static func _flower(root: Node3D, rng: RandomNumberGenerator, at: Vector3, up: Vector3, rad: float, pmats: Array, dark: StandardMaterial3D) -> void:
	if pmats.is_empty():
		return
	var mat_p: StandardMaterial3D = pmats[rng.randi_range(0, pmats.size() - 1)]
	var bs: Basis = _basis_y_to(up.normalized())
	var n: int = 6
	var roll: float = rng.randf_range(0.0, TAU)
	for i in range(n):
		var a: float = roll + float(i) * TAU / float(n)
		var d: Vector3 = (bs * Vector3(cos(a), 0.34, sin(a))).normalized()
		var pb: Basis = _basis_y_to(d)
		_ellipsoid(root, mat_p, at + d * (rad * 0.86), Vector3(rad * 0.34, rad * 0.62, rad * 0.13), pb)
	_ellipsoid(root, dark, at + bs * Vector3(0.0, rad * 0.20, 0.0), Vector3(rad * 0.42, rad * 0.30, rad * 0.42), bs)
