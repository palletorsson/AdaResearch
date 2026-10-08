extends RefCounted

## dream_bodies / coral_polyp — one standing reef creature, pebbled and fronded,
## and now poured in latex.
##
## Reference: scratchpad/refs/sea_b.png (2048x536 panorama) — a row of upright
## reef bodies printed in matte white, pale grey and dove grey, every square
## millimetre of them covered in dense rounded polyp pebbles like a raspberry;
## tall teardrop torsos that hunch forward, some with a small crested reptile
## head, a beak and one dark eye; branching coral fronds sprouting from the
## backs and shoulders in violet, orchid, teal or yellow, forking again and
## again into soft tubes with rounded club tips; a violet coral crust creeping
## up the foot of the grey bodies; and, standing in the middle of the row, one
## body that is smooth instead and wears thick wavy horizontal stripes in teal
## and white.
##
## Reproduced, and how:
##   1. The hunched teardrop torso — 26..32 SphereMesh segments walked along a
##      direction integrated from a keyed lean angle (heel back, belly upright,
##      shoulders hunched forward) with a seeded sideways bow; each sphere is
##      squashed front-to-back so the body reads as the reference's flattened
##      slab, and the radius profile swells at the belly and pinches to a neck.
##   2. The polyp skin — a 192x192 ImageTexture painted in code: a staggered
##      jittered lattice of pebbles, each shaded as a lit dome with a dark
##      groove between, applied with WORLD triplanar so the pebble field runs
##      unbroken across the whole chain of spheres instead of restarting per
##      mesh. Rim knob SphereMeshes make the silhouette lumpy too.
##   3. Branching coral fronds — a recursive static helper: each branch is 2..3
##      CapsuleMesh sub-segments that bend along the way, then forks into 2 (3
##      at the trunk, by seed) thinner children rolled to a seeded angle, four
##      levels deep, ending in a rounded club SphereMesh. 2..4 fronds rise from
##      shoulders and back out of a swelling bulb, in a seeded accent pair.
##   4. The crested head — SphereMesh skull stretched fore-aft, a PrismMesh
##      beak (apex rotated to point forward) with a smaller PrismMesh lower
##      jaw, 4..6 PrismMesh crest fins swept back over the skull and down the
##      neck, and one dark bead eye per side.
##   5. Hunched forelimbs — CapsuleMesh upper arm and forearm tucked to the
##      chest, a sphere hand and three small bud fingers; one side lifted
##      higher than the other, by seed.
##   6. The foot pad — 9..12 SphereMesh lobes flattened with a scaled basis,
##      spreading onto the floor, longer toward the front where the body leans.
##   7. The coral crust at the base — the lowest torso segments are tinted
##      toward the frond accent, so the colony looks like it is climbing.
##   8. The smooth kind, one seed in four — same silhouette, no pebbles and no
##      knobs, wearing a code-painted wavy stripe texture; world triplanar keeps
##      the bands level in y while the wave runs around.
##
## Given up: the black polyp-textured reef wall behind the row, the neighbours
## the creatures lean against, the true relief of the wavy stripes (they are
## painted, not moulded), the open inside of the beak, and the fine pores on
## the frond tubes.
##
## THE GLOSS (2026-09-03). The reference is matte print; this reef is not. Every
## surface now comes out of DreamSkin, and the finish is dealt from a THIRD seeded
## stream (seed ^ 0x6105505) so a queer colour never re-rolls the individual the
## seed already named. The body wears one of latex · patent · candy · pearl · wet
## — the five finishes that paint no texture of their own, so the pebble lattice
## and the wavy stripes survive on top of the shine instead of being replaced by
## it. The coral wears one of oilslick · holo · neon · patent · candy · wet, built
## ONCE and toned into a ramp: a branching frond has forty joints, and painting a
## 192x192 iridescence forty times is a stall, not a surface. The reference's
## greys survive as the VALUE ramp only — the hue is a dealt palette colour, so
## a body is hot pink over dove grey rather than dove grey.
##   ONE MATTE PASSAGE, on purpose: `bleached`. When the flesh has gone the bone
## is chalk — roughness 0.92, no clearcoat, no rim, no glow — and standing a
## chalk cage next to a patent-leather reef is the whole argument of that value.
##
## THE FUSED BODY (colony = fused). Torso, foot, both arms and BOTH heads are
## handed to DreamIso as one signed distance field and marched out as a single
## mesh, so nothing on it begins anywhere: the arm swells out of the flank with a
## fillet, and the second head shares the first one's throat instead of being
## stuck to it (measured: the field is negative all the way along the midpoint
## between the two skulls — one neck, two heads).
##   THE SLAB IS BUILT OUT OF PARTS, because a field has no anisotropic scale.
## Every torso link is TWO capsules set apart in x — radius r*dep, offset
## r*(1-dep) — whose smooth union has the reference's wide-and-shallow section.
## Measured across six seeds: width/depth 1.21..1.30 against a target of 1/dep.
##   THE HOLE IS A TORUS AND A GAP, not a subtraction. Two reasons. It is truer:
## the window is a place the field never crossed zero, not a place something was
## removed from. And DreamIso.cut is not usable as of 2026-09-03 — its smooth
## subtraction has an inverted sign (`-_smin(-d, carve, k)` where the smooth max
## needs `-_smin(-d, -carve, k)`), so ANY field containing a cut part comes back
## as roughly the cutter's own inside-out solid. Measured, not guessed: a torso
## point that should read -0.13 reads +0.80. This value therefore never calls it,
## and stays correct whichever way that line ends up.
##   A body cannot carry a bore narrower than its own flesh is thick, so the
## belly genuinely opens: torso links within `guard` of the ring stand down, the
## ring's outer edge holds the family's silhouette, and the mass goes around the
## window. Measured open radius 0.105..0.120 m — a hole you can see the far wall
## through — against a nominal R-t of 0.117..0.132, so the fillet eats about a
## centimetre of it. 20..24 parts, cell 0.052, blend 0.115, ~20k grid cells (the
## mesher's own budget is 220k, so the cell size is honoured and not coarsened).
##   The mesh is ONE MeshInstance3D, far under the family's floor of 40, so the
## fused body keeps every trimming as primitives: both beaks, both sets of eyes,
## nine crest fins, the frond bulbs and the whole branching reef growth — 80 to
## 180 meshes depending on the frond axis, the same as any other colony.
##   If DreamIso hands back null the value falls through to the primitive
## construction with no gap: `solid` goes true, and the torso spheres, the pad
## lobes, the arms and the skull build exactly as `single` builds them.
##
## AXES — two, each one a different thing the reef can do to a body:
##   colony  — how many animals this is, and how much of it is still flesh:
##             single (one polyp, the default) · budding (a second smaller
##             polyp with its own head growing out of the flank) · spawning
##             (everything above the belly burst into a hovering cloud of its
##             own loose polyps) · bleached (the flesh gone, only hooped rib
##             cage and spine standing, limbs and pad worn to bone, and the one
##             matte passage in the family) · drowned (the lower half swallowed
##             by a solid pour of coral that reaches the floor and stopped in a
##             lapping rim) · fused (not assembled at all: one field, marched —
##             arms grown out of the flank, two heads on one throat, a hole
##             through the belly the field never closed).
##   frond   — what the coral growths do at the ends: branch (forking tubes
##             with rounded club tips, the default) · bloom (every tip opens
##             into a five-petalled flower) · antler (the fronds fuse into one
##             flat wide horizontal rack with blunt paddles, and a ring of
##             spikes crowns the skull) · thread (the fronds unravel into
##             drooping filaments, a mane instead of a shrub).

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const PEB_TEX: int = 192
const STR_TEX: int = 224
const MAX_MESHES: int = 244

# the finishes that paint no texture of their own, so the pebble skin survives
const BODY_FINISHES: Array[String] = ["latex", "patent", "candy", "pearl", "wet"]
# the coral may be iridescent: it carries no painted skin of its own to lose
const CORAL_FINISHES: Array[String] = ["oilslick", "holo", "neon", "patent", "candy", "wet"]

# body: [top, middle, base] greys — the VALUE ramp; the hue is dealt
const BODY_SCHEMES: Array = [
	["#F2F1EC", "#C9CBCA", "#A9AEB1"],
	["#EDEDEA", "#D2D3D0", "#9DA3A7"],
	["#F6F4EF", "#DAD9D4", "#B4B7B9"],
	["#E7E8E7", "#C2C5C6", "#969CA1"],
]

# fronds: [stem, tip]
const ACCENTS: Array = [
	["#7B3FC4", "#B98AE8"],
	["#B76FD4", "#EBC5F0"],
	["#1F8E9B", "#82D2D4"],
	["#DFA61E", "#F6DF93"],
]


static func describe() -> String:
	return "A standing reef creature whose whole body is packed with rounded coral polyps under a skin of latex, patent or nacre, oil-slick fronds branching from its shoulders and a small crested head with a beak — or, one seed in four, the smooth kind wearing wavy glazed stripes."


static func axes() -> Dictionary:
	return {
		"colony": ["single", "budding", "spawning", "bleached", "drowned", "fused"],
		"frond": ["branch", "bloom", "antler", "thread"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# every axis draws on its OWN stream, so a variant keeps the same torso
	# path, palette, head, limbs and frond anchors as the default body
	var arng := RandomNumberGenerator.new()
	arng.seed = seed ^ 0x5EEDC0
	# and the gloss draws on a THIRD, so dealing a finish and a queer colour
	# does not re-roll the individual this seed already names
	var grng := RandomNumberGenerator.new()
	grng.seed = seed ^ 0x6105505
	var colony: String = str(opts.get("colony", "single"))
	var frond_kind: String = str(opts.get("frond", "branch"))

	# --- the gloss: a finish for the flesh, a finish for the coral -----------
	var body_finish: String = BODY_FINISHES[grng.randi_range(0, BODY_FINISHES.size() - 1)]
	var coral_finish: String = CORAL_FINISHES[grng.randi_range(0, CORAL_FINISHES.size() - 1)]
	var q_body: Color = Gloss.queer_colour(grng)
	var q_stem: Color = Gloss.queer_colour(grng)
	var q_tip: Color = Gloss.queer_colour(grng)
	var tries: int = 0
	while q_tip.is_equal_approx(q_stem) and tries < 6:
		q_tip = Gloss.queer_colour(grng)
		tries += 1

	# --- kind and palette ---------------------------------------------------
	var striped: bool = (rng.randi_range(0, 3) == 0)
	var scheme: Array = BODY_SCHEMES[rng.randi_range(0, BODY_SCHEMES.size() - 1)]
	var accent: Array = ACCENTS[rng.randi_range(0, ACCENTS.size() - 1)]
	# the reference's greys survive as the value ramp; the hue is the dealt one
	var col_high: Color = _hex(scheme, 0).lerp(q_body, 0.56)
	var col_mid: Color = _hex(scheme, 1).lerp(q_body, 0.76)
	var col_low: Color = _hex(scheme, 2).lerp(q_body.darkened(0.30), 0.84)
	var col_stem: Color = _hex(accent, 0).lerp(q_stem, 0.84)
	var col_tip: Color = _hex(accent, 1).lerp(q_tip, 0.84)
	if striped:
		# the striped body in the reference is flanked by pale violet coral
		var soft: Array = ACCENTS[rng.randi_range(0, 1)]
		col_stem = _hex(soft, 0).lerp(q_stem, 0.72)
		col_tip = _hex(soft, 1).lerp(q_tip, 0.72)

	var col_band_a: Color = Color("#1B818F").lerp(Color("#2FA0A2"), rng.randf()).lerp(q_body, 0.74)
	var col_band_b: Color = Color("#F4F2EA")

	# --- skin texture -------------------------------------------------------
	var tex_body: ImageTexture
	var uv_k: float = 6.4
	if striped:
		tex_body = _stripe_texture(rng, col_band_a, col_band_b, 5, 3)
		uv_k = rng.randf_range(1.75, 2.05)
	else:
		tex_body = _pebble_texture(rng, 9, 10)
		uv_k = rng.randf_range(5.9, 7.0)
	var uv_off := Vector3(rng.randf(), rng.randf(), rng.randf())

	# --- materials ----------------------------------------------------------
	var mat_beak: StandardMaterial3D = Gloss.skin("pearl", col_high.lerp(Color("#EDE4D2"), 0.35), grng)
	var mat_eye: StandardMaterial3D = Gloss.skin("wet", Color("#191317"), grng)
	var mat_crest: StandardMaterial3D = Gloss.skin(body_finish, col_high.lerp(col_mid, 0.3), grng)
	if striped:
		mat_beak = Gloss.skin("pearl", col_band_b.lerp(Color("#E4DDCB"), 0.3), grng)
		mat_crest = Gloss.skin(body_finish, col_band_b, grng)
	# the coral kit: ONE painted sweep, toned into a ramp and its tips
	var coral: Dictionary = _coral_kit(coral_finish, col_stem, col_tip, grng)
	var mat_bulb: StandardMaterial3D = coral["bulb"]

	# --- individual parameters ----------------------------------------------
	var n_body: int = rng.randi_range(26, 32)
	var body_k: float = rng.randf_range(0.92, 1.06)
	var dep: float = rng.randf_range(0.70, 0.86)
	# the first torso sphere must not hang below the pad, or the settle pass
	# lifts the whole creature and leaves the foot hovering
	var y_base: float = _r_profile(0.0) * body_k * 0.95 + 0.012
	var y_top: float = rng.randf_range(1.31, 1.42)
	var lean_a: float = rng.randf_range(-0.20, -0.05)
	var lean_b: float = rng.randf_range(-0.05, 0.06)
	var lean_c: float = rng.randf_range(0.10, 0.24)
	var lean_d: float = rng.randf_range(0.28, 0.48)
	var sway: float = rng.randf_range(-0.17, 0.17)
	var raised_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var n_fronds: int = rng.randi_range(2, 4)
	var lvl: int = 4 if n_fronds <= 3 else 3
	# a three-way trunk fork only when there are few enough fronds to pay for it
	var max_child: int = 3 if n_fronds == 2 else 2
	var n_crest: int = rng.randi_range(4, 6)
	var n_lobes: int = rng.randi_range(9, 12)

	# --- axis budgets: no rng here, so the base body does not move -----------
	var knobs_on: bool = true
	var spawn_t: float = 0.40
	if colony == "bleached":
		knobs_on = false
		n_fronds = mini(n_fronds, 2)
		lvl = mini(lvl, 3)
	if frond_kind == "bloom":
		n_fronds = mini(n_fronds, 3)
		lvl = mini(lvl, 3)
	elif frond_kind == "thread":
		n_fronds = mini(n_fronds, 3)

	# --- torso: dry run for direction, then a step that lands the neck -------
	var dirs: Array = []
	var rise: float = 0.0
	for i in range(1, n_body):
		var t: float = float(i) / float(n_body - 1)
		var a: float = _lean_angle(t, lean_a, lean_b, lean_c, lean_d)
		var d := Vector3(sway * sin(PI * t) * 0.62, cos(a), -sin(a))
		d = d.normalized()
		dirs.append(d)
		rise += d.y
	var step: float = (y_top - y_base) / maxf(rise, 0.1)

	var pts: Array = []
	var radii: Array = []
	var p := Vector3(0.0, y_base, 0.06)
	pts.append(p)
	radii.append(_r_profile(0.0) * body_k)
	for i in range(1, n_body):
		var t: float = float(i) / float(n_body - 1)
		var d: Vector3 = dirs[i - 1]
		p = p + d * step
		pts.append(p)
		radii.append(_r_profile(t) * body_k)

	# --- landmarks, computed early because the fused field grows from them ---
	var p_top: Vector3 = pts[n_body - 1]
	var r_top: float = radii[n_body - 1]
	var tang_top: Vector3 = _tangent(pts, n_body - 1)
	var rh: float = 0.088 * body_k
	var i_sh: int = int(floor(float(n_body - 1) * 0.64))
	var p_sh: Vector3 = pts[i_sh]
	var r_sh: float = radii[i_sh]
	var p_foot: Vector3 = pts[0]
	var pad_c := Vector3(p_foot.x * 0.6, 0.0, p_foot.z)
	var side_h: float = -raised_side

	# --- the fused body: one field, marched ---------------------------------
	# nothing on it begins anywhere. If the mesher hands back null, `solid`
	# stays true and the primitive body below builds exactly as `single` does.
	var fused: bool = (colony == "fused")
	var iso_ok: bool = false
	var fu_hb := Basis()
	var fu_f := Vector3.FORWARD
	var fu_u := Vector3.UP
	var fu_h2 := Vector3.ZERO
	if fused:
		var fu_yaw: float = deg_to_rad(arng.randf_range(-18.0, 18.0))
		var fu_pitch: float = arng.randf_range(-0.30, -0.10)
		fu_f = Vector3(sin(fu_yaw) * cos(fu_pitch), sin(fu_pitch), -cos(fu_yaw) * cos(fu_pitch))
		fu_f = fu_f.normalized()
		fu_u = (Vector3.UP - fu_f * Vector3.UP.dot(fu_f)).normalized()
		var fu_x: Vector3 = fu_f.cross(fu_u).normalized()
		fu_hb = Basis(fu_x, fu_u, -fu_f)
		var fu_org: Vector3 = p_top + tang_top * (rh * 0.60) + fu_f * (rh * 0.34)
		fu_h2 = p_top + Vector3(side_h * rh * 2.05, rh * 1.00, rh * 0.12)
		var mat_fused: StandardMaterial3D = _skin_mat(body_finish, col_mid.lerp(col_high, 0.28), tex_body, uv_k * 0.78, uv_off, grng)
		var parts: Array = _fused_field(pts, radii, dep, body_k, rh, p_sh, r_sh, raised_side, pad_c, fu_org, fu_h2)
		var iso_mi: MeshInstance3D = Iso.add_body(root, parts, mat_fused, 0.052, 0.115)
		iso_ok = (iso_mi != null)
	# when the field built, the primitive torso, pad, arms and skull stand down
	var solid: bool = not (fused and iso_ok)

	# --- torso segments, knobs, back ridge ----------------------------------
	var squash: Basis = Basis().scaled(Vector3(1.0, 1.0, dep))
	var mat_shared: StandardMaterial3D = null
	if striped:
		mat_shared = _skin_mat(body_finish, Color(1.0, 1.0, 1.0), tex_body, uv_k, uv_off, grng)
	# bone, for when the flesh has gone off the reef — the family's matte passage
	var col_bone: Color = Color("#EFE8D6").lerp(col_high, 0.20)
	var mat_bone: StandardMaterial3D = Gloss.skin("matte", col_bone, grng)
	# the water line, for when the pour has swallowed the lower half
	var flood_y: float = -1.0
	if colony == "drowned":
		flood_y = y_base + (y_top - y_base) * 0.44
	var cage_prev: Vector3 = Vector3.ZERO
	var cage_has: bool = false
	for i in range(n_body):
		var t: float = float(i) / float(n_body - 1)
		var q: Vector3 = pts[i]
		var r: float = radii[i]
		var mat_seg: StandardMaterial3D = mat_shared
		if mat_seg == null:
			var base_c: Color = col_low.lerp(col_mid, clampf(t * 2.2, 0.0, 1.0))
			if t > 0.5:
				base_c = col_mid.lerp(col_high, clampf((t - 0.5) * 1.8, 0.0, 1.0))
			# the colony creeping up the foot
			var crust: float = clampf((0.24 - t) / 0.24, 0.0, 1.0)
			base_c = base_c.lerp(col_stem, crust * 0.5)
			mat_seg = _skin_mat(body_finish, base_c, tex_body, uv_k, uv_off, grng)
		var drowned_seg: bool = (colony == "drowned" and q.y < flood_y)
		var burst_seg: bool = (colony == "spawning" and t > spawn_t)
		if colony == "bleached":
			# the flesh is gone: a hooped rib every second ring, threaded on a spine
			if i % 2 == 0 and _room(root):
				_hoop(root, q, r * 0.99, r * 0.99 * dep, 5, r * 0.085 + 0.006, mat_bone)
				if cage_has:
					_limb(root, cage_prev, q, r * 0.10 + 0.008, mat_bone)
				cage_prev = q
				cage_has = true
		elif burst_seg:
			# the body above the belly has let go of itself
			var spread_f: float = clampf((t - spawn_t) / maxf(1.0 - spawn_t, 0.01), 0.0, 1.0)
			for b in range(3):
				if not _room(root):
					break
				var a_b: float = arng.randf_range(0.0, TAU)
				var out_b: float = r * lerpf(0.24, 1.95, spread_f) * arng.randf_range(0.35, 1.15)
				if b == 0:
					out_b = r * 0.20 * arng.randf_range(0.6, 1.2)
				var y_b: float = arng.randf_range(-0.055, 0.080) * (1.0 + spread_f)
				var r_b: float = r * arng.randf_range(0.20, 0.36)
				var pm2: MeshInstance3D = _add(root, _sphere(r_b, 10, 6), mat_seg)
				pm2.transform = Transform3D(Basis(), q + Vector3(cos(a_b) * out_b, y_b, sin(a_b) * out_b * dep))
		elif not drowned_seg and solid:
			var mi: MeshInstance3D = _add(root, _sphere(r, 20, 10), mat_seg)
			mi.transform = Transform3D(squash, q)
		# lumpy rim so the silhouette is pebbled too
		if not striped and i % 2 == 0 and t > 0.06 and t < 0.94:
			var sd: float = 1.0 if (i % 4 == 0) else -1.0
			var wob: float = rng.randf_range(-0.22, 0.22)
			var yjit: float = rng.randf_range(-0.12, 0.12)
			var krf: float = rng.randf_range(0.16, 0.24)
			if knobs_on and solid and not drowned_seg and not burst_seg:
				var off := Vector3(sd * cos(wob), yjit, sin(wob) * dep)
				off = off.normalized()
				var kr: float = r * krf
				var km: MeshInstance3D = _add(root, _sphere(kr, 10, 6), mat_seg)
				km.transform = Transform3D(Basis(), q + Vector3(off.x * r * 0.92, off.y * r * 0.5, off.z * r * 0.92))

	# --- foot pad spreading onto the floor ----------------------------------
	var pad_mat: StandardMaterial3D = mat_shared
	if pad_mat == null:
		pad_mat = _skin_mat(body_finish, col_low.lerp(col_stem, 0.42), tex_body, uv_k, uv_off, grng)
	if colony == "bleached":
		pad_mat = mat_bone
	var sunk: bool = (colony == "drowned")
	for k in range(n_lobes):
		var fk: float = float(k) / float(n_lobes)
		var ang: float = fk * TAU + rng.randf_range(-0.14, 0.14)
		var forward: float = 0.5 + 0.5 * cos(ang)
		var reach: float = lerpf(0.115, 0.215, forward) * rng.randf_range(0.86, 1.12) * body_k
		var lr: float = rng.randf_range(0.085, 0.135) * body_k
		var flat: float = rng.randf_range(0.30, 0.42)
		# the draws above always run, so the pad keeps its shape across variants
		if sunk or not solid:
			continue
		if colony == "bleached":
			lr *= 0.60
			flat *= 0.82
		var lb: Basis = Basis(Vector3.UP, ang) * Basis().scaled(Vector3(1.0, flat, 0.72))
		var lm: MeshInstance3D = _add(root, _sphere(lr, 14, 8), pad_mat)
		lm.transform = Transform3D(lb, pad_c + Vector3(-sin(ang) * reach, lr * flat, -cos(ang) * reach))
	if sunk:
		# a solid pour of coral has run in and set around the lower half
		_pour(root, pad_c, flood_y, coral, arng)
	elif solid:
		var hub: MeshInstance3D = _add(root, _sphere(0.19 * body_k, 18, 9), pad_mat)
		hub.transform = Transform3D(Basis().scaled(Vector3(1.0, 0.44, 0.86)), pad_c + Vector3(0.0, 0.19 * body_k * 0.44, 0.0))

	# --- hunched forelimbs ---------------------------------------------------
	var mat_limb: StandardMaterial3D = mat_shared
	if mat_limb == null:
		mat_limb = _skin_mat(body_finish, col_mid.lerp(col_high, 0.25), tex_body, uv_k, uv_off, grng)
	var limb_k: float = 1.0
	if colony == "bleached":
		mat_limb = mat_bone
		limb_k = 0.46
	for side_i in range(2):
		if not solid:
			break   # the fused body grew its arms out of its own flank
		var sd: float = -1.0 if side_i == 0 else 1.0
		var lift: float = 0.055 if sd == raised_side else 0.0
		var sh_p: Vector3 = p_sh + Vector3(sd * r_sh * 0.86, -0.015, -r_sh * 0.2 * dep)
		var elb: Vector3 = sh_p + Vector3(sd * 0.055, -0.145 + lift * 0.45, -0.055)
		var hand: Vector3 = elb + Vector3(-sd * 0.035, -0.015 + lift, -0.105)
		_limb(root, sh_p, elb, 0.05 * body_k * limb_k, mat_limb)
		_limb(root, elb, hand, 0.038 * body_k * limb_k, mat_limb)
		var hm: MeshInstance3D = _add(root, _sphere(0.043 * body_k * limb_k, 12, 7), mat_limb)
		hm.transform = Transform3D(Basis(), hand)
		for c in range(3):
			var fa: float = (float(c) - 1.0) * 0.62
			var fd := Vector3(sin(fa) * 0.7 - sd * 0.2, -0.42, -cos(fa) * 0.8)
			fd = fd.normalized()
			var bm: MeshInstance3D = _add(root, _sphere(0.019 * body_k * limb_k, 10, 6), mat_limb)
			bm.transform = Transform3D(Basis(), hand + fd * (0.048 * body_k))

	# --- head ---------------------------------------------------------------
	var head_yaw: float = deg_to_rad(rng.randf_range(-22.0, 22.0))
	var head_pitch: float = rng.randf_range(-0.34, -0.12)
	var f_head := Vector3(sin(head_yaw) * cos(head_pitch), sin(head_pitch), -cos(head_yaw) * cos(head_pitch))
	f_head = f_head.normalized()
	var u_head: Vector3 = (Vector3.UP - f_head * Vector3.UP.dot(f_head)).normalized()
	var x_head: Vector3 = f_head.cross(u_head).normalized()
	var hb := Basis(x_head, u_head, -f_head)
	if not solid:
		# the fused skull was grown at its own frame; the beak, the crest and
		# the eyes have to find it there
		f_head = fu_f
		u_head = fu_u
		hb = fu_hb
	var h_org: Vector3 = p_top + tang_top * (rh * 0.60) + f_head * (rh * 0.34)

	var mat_head: StandardMaterial3D = mat_shared
	if mat_head == null:
		mat_head = _skin_mat(body_finish, col_high, tex_body, uv_k * 1.15, uv_off, grng)
	if colony == "bleached":
		mat_head = mat_bone
		mat_beak = mat_bone
		mat_crest = mat_bone
	if solid:
		var skull: MeshInstance3D = _add(root, _sphere(rh, 22, 12), mat_head)
		skull.transform = Transform3D(hb * Basis().scaled(Vector3(0.92, 0.96, 1.30)), h_org)
		if colony != "bleached":
			var fill: MeshInstance3D = _add(root, _sphere(r_top * 1.02, 16, 9), mat_head)
			fill.transform = Transform3D(squash, (p_top + h_org) * 0.5)

	# beak: a prism rotated so its apex points forward, extruded vertically
	var beak_b: Basis = hb * Basis(Vector3.RIGHT, -PI * 0.5)
	var beak := PrismMesh.new()
	beak.size = Vector3(0.076 * body_k, 0.155 * body_k, 0.052 * body_k)
	var bkm: MeshInstance3D = _add(root, beak, mat_beak)
	bkm.transform = Transform3D(beak_b, h_org + f_head * (rh * 0.72) - u_head * (rh * 0.14))
	var jaw := PrismMesh.new()
	jaw.size = Vector3(0.058 * body_k, 0.108 * body_k, 0.030 * body_k)
	var jwm: MeshInstance3D = _add(root, jaw, mat_beak)
	var jaw_b: Basis = hb * Basis(Vector3.RIGHT, -PI * 0.5 + 0.16)
	jwm.transform = Transform3D(jaw_b, h_org + f_head * (rh * 0.60) - u_head * (rh * 0.52))

	# crest fins, swept back over the skull and down the neck
	for k in range(n_crest):
		var fk: float = float(k) / float(n_crest - 1)
		var hgt: float = lerpf(0.088, 0.034, fk) * body_k
		var tilt: float = 0.32 + 0.30 * fk
		var fin := PrismMesh.new()
		fin.size = Vector3(0.013 * body_k, hgt, hgt * 0.92)
		var fm: MeshInstance3D = _add(root, fin, mat_crest)
		var zk: float = rh * (0.10 + 1.35 * fk)
		var yk: float = rh * (0.78 - 0.22 * fk)
		fm.transform = Transform3D(hb * Basis(Vector3.RIGHT, tilt), h_org + hb * Vector3(0.0, yk, zk))

	# one dark bead eye per side, so the gaze reads from anywhere in the hall
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var em: MeshInstance3D = _add(root, _sphere(0.0165 * body_k, 12, 7), mat_eye)
		em.transform = Transform3D(Basis(), h_org + hb * Vector3(sd * rh * 0.70, rh * 0.22, -rh * 0.36))

	# --- the second head, which never grew a neck of its own -----------------
	if not solid:
		var f2 := Vector3(side_h * 0.60, -0.14, -0.79)
		f2 = f2.normalized()
		var u2: Vector3 = (Vector3.UP - f2 * Vector3.UP.dot(f2)).normalized()
		var x2: Vector3 = f2.cross(u2).normalized()
		var b2 := Basis(x2, u2, -f2)
		var rh2: float = rh * 0.86
		var bk2 := PrismMesh.new()
		bk2.size = Vector3(0.052 * body_k, 0.112 * body_k, 0.036 * body_k)
		var bkm2: MeshInstance3D = _add(root, bk2, mat_beak)
		bkm2.transform = Transform3D(b2 * Basis(Vector3.RIGHT, -PI * 0.5), fu_h2 + f2 * (rh2 * 0.74) - u2 * (rh2 * 0.12))
		for side_i in range(2):
			var sd2: float = -1.0 if side_i == 0 else 1.0
			var em2: MeshInstance3D = _add(root, _sphere(0.0145 * body_k, 12, 7), mat_eye)
			em2.transform = Transform3D(Basis(), fu_h2 + b2 * Vector3(sd2 * rh2 * 0.70, rh2 * 0.22, -rh2 * 0.36))
		for k in range(3):
			var fk2: float = float(k) / 2.0
			var hgt2: float = lerpf(0.062, 0.028, fk2) * body_k
			var fin2 := PrismMesh.new()
			fin2.size = Vector3(0.011 * body_k, hgt2, hgt2 * 0.92)
			var fm2: MeshInstance3D = _add(root, fin2, mat_crest)
			var zk2: float = rh2 * (0.12 + 1.25 * fk2)
			var yk2: float = rh2 * (0.76 - 0.20 * fk2)
			fm2.transform = Transform3D(b2 * Basis(Vector3.RIGHT, 0.34 + 0.28 * fk2), fu_h2 + b2 * Vector3(0.0, yk2, zk2))

	# --- coral fronds off the shoulders and back -----------------------------
	if frond_kind == "antler":
		# the fronds have fused into one flat wide rack, and the skull is crowned
		var i_rack: int = clampi(int(floor(0.74 * float(n_body - 1))), 1, n_body - 1)
		var ap_r: Vector3 = pts[i_rack]
		var ar_r: float = radii[i_rack]
		for k in range(3):
			var side_r: float = 0.0
			if k == 1:
				side_r = 1.0
			elif k == 2:
				side_r = -1.0
			var back_r: float = 0.62 - 0.28 * absf(side_r)
			var base_r: Vector3 = ap_r + Vector3(side_r * ar_r * 0.74, ar_r * (0.22 - 0.16 * absf(side_r)), ar_r * back_r * dep)
			var dir_r := Vector3(side_r * 0.88, 0.72 + 0.26 * (1.0 - absf(side_r)), back_r * 0.62)
			dir_r = dir_r.normalized()
			var bmr: MeshInstance3D = _add(root, _sphere(ar_r * 0.30, 12, 7), mat_bulb)
			bmr.transform = Transform3D(Basis(), base_r)
			_antler(root, base_r, dir_r, 0.235 * body_k, 0.060 * body_k, 3, arng, coral)
		var mat_spike: StandardMaterial3D = coral["pad"]
		for k in range(7):
			if not _room(root):
				break
			var a_c: float = float(k) / 7.0 * TAU
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.017 * body_k
			cone.height = 0.115 * body_k
			cone.radial_segments = 8
			cone.rings = 1
			var out_c := Vector3(cos(a_c), 0.0, sin(a_c))
			var ax_c: Vector3 = out_c.cross(Vector3.UP).normalized()
			var cmz: MeshInstance3D = _add(root, cone, mat_spike)
			cmz.transform = Transform3D(hb * Basis(ax_c, deg_to_rad(-24.0)), h_org + hb * (out_c * (rh * 0.86) + Vector3(0.0, rh * 0.50 + cone.height * 0.44, 0.0)))
		n_fronds = 0
	for k in range(n_fronds):
		var anchor_t: float = 0.0
		var side_sd: float = 1.0 if (k % 2 == 0) else -1.0
		var out_k: float = 0.0
		var back_k: float = 0.0
		if k == 0:
			anchor_t = rng.randf_range(0.68, 0.76)
			out_k = 0.60
			back_k = 0.34
		elif k == 1:
			anchor_t = rng.randf_range(0.62, 0.72)
			out_k = 0.56
			back_k = 0.40
		elif k == 2:
			anchor_t = rng.randf_range(0.46, 0.56)
			out_k = 0.34
			back_k = 0.62
		else:
			anchor_t = rng.randf_range(0.30, 0.40)
			out_k = 0.30
			back_k = 0.68
		var idx: int = int(floor(anchor_t * float(n_body - 1)))
		idx = clampi(idx, 1, n_body - 1)
		var ap: Vector3 = pts[idx]
		var ar: float = radii[idx]
		var base_p: Vector3 = ap + Vector3(side_sd * ar * out_k, ar * 0.10, ar * back_k * dep)
		var dir := Vector3(side_sd * out_k * 0.95, 0.82, back_k * 0.72)
		dir = dir.normalized()
		var bulb_r: float = ar * 0.28
		if frond_kind == "thread":
			bulb_r = ar * 0.17
		var bm2: MeshInstance3D = _add(root, _sphere(bulb_r, 12, 7), mat_bulb)
		bm2.transform = Transform3D(Basis(), base_p)
		var ln0: float = rng.randf_range(0.185, 0.235) * body_k
		var rad0: float = rng.randf_range(0.040, 0.052) * body_k
		if frond_kind == "thread":
			# the frond has come undone into filaments that hang
			_threads(root, base_p, dir, 8, ln0 * 0.60, rad0 * 0.28, arng, coral)
		else:
			var tip_kind: String = "club"
			if frond_kind == "bloom":
				tip_kind = "bloom"
			_frond(root, base_p, dir, ln0, rad0, lvl, lvl, max_child, rng, coral, tip_kind)

	# --- a second polyp budding out of the flank -----------------------------
	if colony == "budding":
		var side_b: float = -raised_side
		var i_bud: int = clampi(int(floor(0.38 * float(n_body - 1))), 1, n_body - 2)
		var ap_b: Vector3 = pts[i_bud]
		var ar_b: float = radii[i_bud]
		var mat_bud: StandardMaterial3D = mat_shared
		if mat_bud == null:
			mat_bud = _skin_mat(body_finish, col_mid.lerp(col_high, 0.15), tex_body, uv_k * 1.45, uv_off, grng)
		var d_bud := Vector3(side_b * 0.82, 0.56, 0.18)
		d_bud = d_bud.normalized()
		var n_bud: int = 12
		var k_bud: float = 0.46 * body_k
		var pb: Vector3 = ap_b + d_bud * (ar_b * 0.70)
		var last_b: Vector3 = pb
		var last_r: float = 0.0
		for i in range(n_bud):
			if not _room(root):
				break
			var tb: float = float(i) / float(n_bud - 1)
			var rb: float = _r_profile(clampf(tb * 0.90 + 0.08, 0.0, 1.0)) * k_bud
			var bend_b: Vector3 = (d_bud + Vector3.UP * (tb * 1.05)).normalized()
			pb = pb + bend_b * (0.055 * body_k)
			var mb: MeshInstance3D = _add(root, _sphere(rb, 14, 8), mat_bud)
			mb.transform = Transform3D(Basis().scaled(Vector3(1.0, 1.0, dep)), pb)
			last_b = pb
			last_r = rb
		# the bud has grown its own beaked head, looking the other way
		var rh_b: float = 0.052 * body_k
		var f_b := Vector3(side_b * 0.42, -0.16, -0.89)
		f_b = f_b.normalized()
		var u_b: Vector3 = (Vector3.UP - f_b * Vector3.UP.dot(f_b)).normalized()
		var x_b: Vector3 = f_b.cross(u_b).normalized()
		var fb := Basis(x_b, u_b, -f_b)
		var hc_b: Vector3 = last_b + Vector3(0.0, last_r * 0.95, 0.0)
		var skb: MeshInstance3D = _add(root, _sphere(rh_b, 16, 9), mat_bud)
		skb.transform = Transform3D(fb * Basis().scaled(Vector3(0.92, 0.96, 1.30)), hc_b)
		var beak_b2 := PrismMesh.new()
		beak_b2.size = Vector3(0.046 * body_k, 0.092 * body_k, 0.032 * body_k)
		var bkb: MeshInstance3D = _add(root, beak_b2, mat_beak)
		bkb.transform = Transform3D(fb * Basis(Vector3.RIGHT, -PI * 0.5), hc_b + f_b * (rh_b * 0.72) - u_b * (rh_b * 0.14))
		for side_i in range(2):
			var sdb: float = -1.0 if side_i == 0 else 1.0
			var eb: MeshInstance3D = _add(root, _sphere(0.011 * body_k, 10, 6), mat_eye)
			eb.transform = Transform3D(Basis(), hc_b + fb * Vector3(sdb * rh_b * 0.70, rh_b * 0.22, -rh_b * 0.36))
		# and its own small growth, in whatever the frond axis says
		var dir_b := Vector3(side_b * 0.46, 0.86, 0.20)
		dir_b = dir_b.normalized()
		var bulb_b: MeshInstance3D = _add(root, _sphere(last_r * 0.42, 10, 6), mat_bulb)
		bulb_b.transform = Transform3D(Basis(), last_b + dir_b * (last_r * 0.6))
		if frond_kind == "thread":
			_threads(root, last_b, dir_b, 5, 0.072 * body_k, 0.011 * body_k, arng, coral)
		elif frond_kind == "antler":
			_antler(root, last_b, dir_b, 0.125 * body_k, 0.030 * body_k, 2, arng, coral)
		else:
			var tip_b: String = "club"
			if frond_kind == "bloom":
				tip_b = "bloom"
			_frond(root, last_b, dir_b, 0.115 * body_k, 0.026 * body_k, 2, 2, 2, arng, coral, tip_b)

	# --- fit inside the 1.25 x 1.25 x 1.7 envelope --------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.22 / maxf(box.size.x, 0.01)
	var kz: float = 1.22 / maxf(box.size.z, 0.01)
	var ky: float = 1.66 / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)

	# --- measured settle: centre on x/z, seat the lowest point on the floor --
	box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# the fused body: the same joints and radii, handed over as a field

static func _fused_field(pts: Array, radii: Array, dep: float, body_k: float, rh: float,
		p_sh: Vector3, r_sh: float, raised_side: float, pad_c: Vector3,
		h_org: Vector3, h2: Vector3) -> Array:
	var parts: Array = []
	var n: int = pts.size()
	if n < 2:
		return parts

	# THE HOLE, first, because the torso has to be told to go around it. It is a
	# TORUS and a gap — not DreamIso.cut — so the void is a place the field never
	# crossed zero rather than a place something was taken out of. A body cannot
	# carry a bore narrower than its own flesh is thick, so the belly genuinely
	# opens: the ring's outer edge holds the family's silhouette while the mass
	# goes around the window.
	var i_hole: int = clampi(int(floor(float(n - 1) * 0.44)), 1, n - 2)
	var hp: Vector3 = pts[i_hole]
	var hr: float = float(radii[i_hole])
	var ring_r: float = hr * 0.86
	var ring_t: float = hr * 0.34
	# the last torso mass has to clear the window: its own radius, plus the hole
	var guard: float = hr * dep + (ring_r - ring_t) + 0.02

	# the torso, decimated to ~9 links. Each link is TWO capsules set apart in
	# x — radius r*dep, offset r*(1-dep) — because a field has no anisotropic
	# scale, so the family's flattened slab has to be built out of parts: the
	# smooth union of the pair is wide in x and shallow in z, like the reference.
	var stride: int = maxi(1, int(floor(float(n) / 9.0)))
	var i: int = 0
	while i < n - 1:
		var j: int = mini(i + stride, n - 1)
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[j]
		if absf(a.y - hp.y) > guard and absf(b.y - hp.y) > guard:
			var ra: float = float(radii[i])
			var rb: float = float(radii[j])
			var ea: float = ra * (1.0 - dep)
			var eb: float = rb * (1.0 - dep)
			parts.append(Iso.capsule(a + Vector3(ea, 0.0, 0.0), b + Vector3(eb, 0.0, 0.0), ra * dep, rb * dep))
			parts.append(Iso.capsule(a - Vector3(ea, 0.0, 0.0), b - Vector3(eb, 0.0, 0.0), ra * dep, rb * dep))
		i = j
	# the ring itself, standing in the x/y plane so the window looks straight out
	parts.append(Iso.torus(hp, ring_r, ring_t, Vector3.BACK))

	# the foot: a rounded slab the torso runs into, no seam and no ankle
	parts.append(Iso.box(pad_c + Vector3(0.0, 0.052, -0.02), Vector3(0.19, 0.040, 0.15), 0.055))
	parts.append(Iso.sphere(pad_c + Vector3(0.0, 0.115, -0.09), 0.145))

	# the throat, and two heads sharing it
	var p_top: Vector3 = pts[n - 1]
	parts.append(Iso.capsule(pts[maxi(n - 4, 0)], h_org, rh * 0.95, rh * 0.62))
	parts.append(Iso.sphere(h_org, rh * 1.02))
	parts.append(Iso.capsule(pts[maxi(n - 3, 0)], h2, rh * 0.72, rh * 0.50))
	parts.append(Iso.sphere(h2, rh * 0.88))
	parts.append(Iso.sphere(p_top + Vector3(0.0, rh * 0.30, 0.0), rh * 0.80))

	# the arms, which do not begin: they swell out of the flank
	for s in range(2):
		var sd: float = -1.0 if s == 0 else 1.0
		var lift: float = 0.055 if sd == raised_side else 0.0
		var sh_p: Vector3 = p_sh + Vector3(sd * r_sh * 0.80, -0.015, -r_sh * 0.2 * dep)
		var elb: Vector3 = sh_p + Vector3(sd * 0.055, -0.145 + lift * 0.45, -0.055)
		var hnd: Vector3 = elb + Vector3(-sd * 0.035, -0.015 + lift, -0.105)
		parts.append(Iso.capsule(sh_p, elb, 0.058 * body_k, 0.046 * body_k))
		parts.append(Iso.capsule(elb, hnd, 0.046 * body_k, 0.038 * body_k))
		parts.append(Iso.sphere(hnd, 0.050 * body_k))
	return parts


# ---------------------------------------------------------------------------
# the recursive coral frond

static func _frond(root: Node3D, base: Vector3, dir: Vector3, ln: float, rad: float, depth: int, lvl_max: int, max_child: int, rng: RandomNumberGenerator, coral: Dictionary, tip: String = "club") -> void:
	if depth <= 0:
		return
	if root.get_child_count() >= MAX_MESHES:
		return
	var f: float = 1.0 - float(depth - 1) / maxf(float(lvl_max - 1), 1.0)
	var mat: StandardMaterial3D = _pick(coral["ramp"], clampf(f * 0.85, 0.0, 1.0))

	var d: Vector3 = dir.normalized()
	var side: Vector3 = d.cross(Vector3.UP)
	if side.length() < 0.001:
		side = Vector3.RIGHT
	side = side.normalized()
	var bend := side * rng.randf_range(-0.55, 0.55) + Vector3.UP * rng.randf_range(0.10, 0.55)
	bend = bend.normalized()

	var steps: int = 3 if depth >= lvl_max - 1 else 2
	var p: Vector3 = base
	var seg: float = ln / float(steps)
	for i in range(steps):
		var u: float = float(i + 1) / float(steps)
		var nd: Vector3 = (d + bend * (0.34 / float(steps))).normalized()
		var q: Vector3 = p + nd * seg
		var r_i: float = lerpf(rad, rad * 0.80, u)
		_limb(root, p, q, r_i, mat)
		p = q
		d = nd

	if depth == 1:
		if tip == "bloom":
			_flower(root, p, d, rad, coral, rng)
			return
		var mat_club: StandardMaterial3D = coral["tip"]
		var club: MeshInstance3D = _add(root, _sphere(rad * 1.45, 12, 8), mat_club)
		club.transform = Transform3D(Basis(), p)
		return

	var n_child: int = 2
	if depth == lvl_max and max_child >= 3 and rng.randf() < 0.5:
		n_child = 3
	var spread: float = deg_to_rad(rng.randf_range(34.0, 58.0))
	var roll: float = rng.randf_range(0.0, TAU)
	var e1: Vector3 = d.cross(Vector3.UP)
	if e1.length() < 0.001:
		e1 = Vector3.RIGHT
	e1 = e1.normalized()
	var e2: Vector3 = d.cross(e1).normalized()
	var perp: Vector3 = (e1 * cos(roll) + e2 * sin(roll)).normalized()
	for k in range(n_child):
		var frac: float = 0.0
		if n_child > 1:
			frac = float(k) / float(n_child - 1) - 0.5
		var ang: float = frac * spread * 2.0
		var cd: Vector3 = (d * cos(ang) + perp * sin(ang)).normalized()
		cd = (cd + Vector3.UP * rng.randf_range(0.10, 0.30)).normalized()
		var ck: float = rng.randf_range(0.64, 0.80)
		_frond(root, p, cd, ln * ck, rad * rng.randf_range(0.62, 0.76), depth - 1, lvl_max, max_child, rng, coral, tip)


# ---------------------------------------------------------------------------
# the frond axis: what the coral does at the far end

static func _flower(root: Node3D, at: Vector3, dir: Vector3, rad: float, coral: Dictionary, rng: RandomNumberGenerator) -> void:
	# a five-petalled bloom opening off the tip, petals flattened into blades
	if not _room(root):
		return
	var bb: Basis = _basis_y_to(dir)
	var mat_p: StandardMaterial3D = coral["petal"]
	var mat_c: StandardMaterial3D = coral["core"]
	var n: int = 5
	var pr: float = rad * 3.0
	for k in range(n):
		if not _room(root):
			return
		var a: float = float(k) / float(n) * TAU + rng.randf_range(-0.10, 0.10)
		var pb: Basis = bb * Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(58.0)) * Basis().scaled(Vector3(0.80, 0.20, 1.55))
		var pm: MeshInstance3D = _add(root, _sphere(pr, 10, 6), mat_p)
		var lp: Vector3 = Vector3(sin(a), 0.0, cos(a)) * (pr * 0.95) + Vector3(0.0, rad * 0.55, 0.0)
		pm.transform = Transform3D(pb, at + bb * lp)
	if not _room(root):
		return
	var cm2: MeshInstance3D = _add(root, _sphere(rad * 1.15, 10, 6), mat_c)
	cm2.transform = Transform3D(bb * Basis().scaled(Vector3(1.0, 0.62, 1.0)), at + bb * Vector3(0.0, rad * 0.55, 0.0))


static func _antler(root: Node3D, base: Vector3, dir: Vector3, ln: float, rad: float, depth: int, rng: RandomNumberGenerator, coral: Dictionary) -> void:
	# a fused rack: straight thick runs, wide horizontal forks, blunt paddles
	if depth <= 0:
		return
	if not _room(root):
		return
	var f: float = 1.0 - float(depth - 1) / 2.0
	var mat: StandardMaterial3D = _pick(coral["ramp"], clampf(f * 0.9, 0.0, 1.0))
	var d: Vector3 = dir.normalized()
	var p: Vector3 = base
	var steps: int = 2
	var seg: float = ln / float(steps)
	for i in range(steps):
		var u: float = float(i + 1) / float(steps)
		var q: Vector3 = p + d * seg
		var r_i: float = lerpf(rad, rad * 0.74, u)
		_limb(root, p, q, r_i, mat)
		p = q
	if depth == 1:
		var mat_pad: StandardMaterial3D = coral["pad"]
		var pad: MeshInstance3D = _add(root, _sphere(rad * 1.9, 12, 7), mat_pad)
		pad.transform = Transform3D(_basis_y_to(d) * Basis().scaled(Vector3(2.3, 0.30, 1.15)), p + d * (rad * 1.1))
		return
	var perp: Vector3 = d.cross(Vector3.UP)
	if perp.length() < 0.001:
		perp = Vector3.RIGHT
	perp = perp.normalized()
	var spread: float = deg_to_rad(rng.randf_range(58.0, 84.0))
	for k in range(2):
		var sgn: float = 1.0 if k == 0 else -1.0
		var cd: Vector3 = (d * cos(spread) + perp * (sgn * sin(spread))).normalized()
		cd = (cd + Vector3.UP * rng.randf_range(0.06, 0.26)).normalized()
		_antler(root, p, cd, ln * rng.randf_range(0.70, 0.86), rad * rng.randf_range(0.66, 0.78), depth - 1, rng, coral)


static func _threads(root: Node3D, base: Vector3, dir: Vector3, n_fil: int, ln: float, rad: float, rng: RandomNumberGenerator, coral: Dictionary) -> void:
	# the frond unravelled: filaments that leave the bulb and fall
	var mat_a: StandardMaterial3D = _pick(coral["ramp"], 0.0)
	var mat_b: StandardMaterial3D = _pick(coral["ramp"], 0.65)
	var e1: Vector3 = dir.cross(Vector3.UP)
	if e1.length() < 0.001:
		e1 = Vector3.RIGHT
	e1 = e1.normalized()
	var e2: Vector3 = dir.cross(e1).normalized()
	for k in range(n_fil):
		if not _room(root):
			return
		var a: float = float(k) / float(n_fil) * TAU + rng.randf_range(-0.22, 0.22)
		var tilt: float = rng.randf_range(0.42, 1.10)
		var d: Vector3 = (dir * cos(tilt) + (e1 * cos(a) + e2 * sin(a)) * sin(tilt)).normalized()
		var droop: float = rng.randf_range(0.28, 0.62)
		var mat: StandardMaterial3D = mat_a
		if k % 2 == 1:
			mat = mat_b
		var p: Vector3 = base
		for s in range(4):
			if not _room(root):
				return
			var u: float = float(s) / 3.0
			d = (d + Vector3.DOWN * (droop * (0.22 + u))).normalized()
			var q: Vector3 = p + d * ln
			var r_i: float = rad * lerpf(1.0, 0.34, u)
			_limb(root, p, q, r_i, mat)
			p = q


# ---------------------------------------------------------------------------
# the colony axis: the cage and the pour

static func _hoop(root: Node3D, c: Vector3, rx: float, rz: float, n: int, thick: float, mat: StandardMaterial3D) -> void:
	# a horizontal rib, chorded out of capsules
	var prev := Vector3(c.x + rx, c.y, c.z)
	for k in range(1, n + 1):
		if not _room(root):
			return
		var a: float = float(k) / float(n) * TAU
		var q := Vector3(c.x + cos(a) * rx, c.y, c.z + sin(a) * rz)
		_limb(root, prev, q, thick, mat)
		prev = q


static func _pour(root: Node3D, c: Vector3, top_y: float, coral: Dictionary, rng: RandomNumberGenerator) -> void:
	# a solid mass that ran in, rose to the water line and set
	var mat: StandardMaterial3D = _pick(coral["ramp"], 0.22)
	var mat_rim: StandardMaterial3D = _pick(coral["ramp"], 0.55)
	var tiers: int = 4
	var y_top_pour: float = maxf(top_y - 0.16, 0.18)
	for k in range(tiers):
		var fk: float = float(k) / float(tiers - 1)
		var rr: float = lerpf(0.48, 0.27, fk)
		var fl: float = lerpf(0.30, 0.54, fk)
		var yy: float = lerpf(0.0, y_top_pour, fk)
		var mi: MeshInstance3D = _add(root, _sphere(rr, 22, 11), mat)
		mi.transform = Transform3D(Basis().scaled(Vector3(1.0, fl, 0.94)), Vector3(c.x, yy + rr * fl * 0.92, c.z))
	for k in range(12):
		if not _room(root):
			return
		var a: float = float(k) / 12.0 * TAU + rng.randf_range(-0.12, 0.12)
		var rr2: float = rng.randf_range(0.055, 0.095)
		var reach: float = 0.36 + rng.randf_range(-0.03, 0.09)
		var mi2: MeshInstance3D = _add(root, _sphere(rr2, 12, 7), mat_rim)
		mi2.transform = Transform3D(Basis(Vector3.UP, -a) * Basis().scaled(Vector3(1.0, 0.44, 1.5)), Vector3(c.x + cos(a) * reach, rr2 * 0.40, c.z + sin(a) * reach * 0.95))


static func _room(root: Node3D) -> bool:
	return root.get_child_count() < MAX_MESHES


# ---------------------------------------------------------------------------
# shape helpers

static func _lean_angle(t: float, a0: float, a1: float, a2: float, a3: float) -> float:
	var keys: Array = [a0, a1, a2, a3]
	var f: float = t * 3.0
	var i: int = int(floor(f))
	if i >= 3:
		return a3
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var va: float = keys[i]
	var vb: float = keys[i + 1]
	return lerpf(va, vb, s)


static func _r_profile(t: float) -> float:
	var keys: Array = [0.145, 0.205, 0.243, 0.238, 0.196, 0.132, 0.078]
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


static func _hex(arr: Array, i: int) -> Color:
	var code: String = arr[i]
	return Color(code)


static func _sphere(r: float, seg: int, rings: int) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = rings
	return s


# ---------------------------------------------------------------------------
# the gloss

static func _skin_mat(finish: String, c: Color, tex: ImageTexture, uvs: float, off: Vector3, rng: RandomNumberGenerator) -> StandardMaterial3D:
	# the finish decides the shine, the family's painted skin sits on top of it.
	# BODY_FINISHES paint no texture of their own, so nothing is clobbered here;
	# world triplanar keeps the pebble field unbroken across the whole chain.
	var m: StandardMaterial3D = Gloss.skin(finish, c, rng)
	if tex != null:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(uvs, uvs, uvs)
		m.uv1_offset = off
	return m


static func _coral_kit(finish: String, a: Color, b: Color, rng: RandomNumberGenerator) -> Dictionary:
	# ONE painted sweep for the whole reef growth, then toned. A branching frond
	# makes forty materials, and painting a 192x192 iridescence forty times is a
	# stall, not a surface.
	var base_mat: StandardMaterial3D = Gloss.skin(finish, a, rng)
	_worldize(base_mat, 1.15)
	var ramp: Array = []
	ramp.append(base_mat)
	for i in range(1, 5):
		var f: float = float(i) / 4.0
		ramp.append(_tone(base_mat, a.lerp(b, f)))
	return {
		"ramp": ramp,
		"tip": _tone(base_mat, b),
		"petal": _tone(base_mat, b.lerp(Color(1.0, 1.0, 1.0), 0.18)),
		"core": _tone(base_mat, a.darkened(0.34)),
		"pad": _tone(base_mat, b.lerp(a, 0.25)),
		"bulb": _tone(base_mat, a.lerp(b, 0.25)),
	}


static func _tone(src: StandardMaterial3D, c: Color) -> StandardMaterial3D:
	# a duplicate SHARES the painted texture, which is the whole point
	var m: StandardMaterial3D = src.duplicate() as StandardMaterial3D
	m.albedo_color = src.albedo_color.lerp(c, 0.78)
	if m.emission_enabled and m.emission_texture == null:
		m.emission = c
	return m


static func _worldize(m: StandardMaterial3D, s: float) -> void:
	# the sweep finishes carry their own texture: make it run across the whole
	# creature instead of restarting on every capsule
	if m.albedo_texture == null:
		return
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(s, s, s)


static func _pick(ramp: Array, f: float) -> StandardMaterial3D:
	var n: int = ramp.size()
	if n <= 0:
		return null
	var idx: int = int(round(clampf(f, 0.0, 1.0) * float(n - 1)))
	idx = clampi(idx, 0, n - 1)
	return ramp[idx] as StandardMaterial3D


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.008)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = maxf(ln + r * 1.7, r * 2.05)
	cap.radial_segments = 12
	cap.rings = 4
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


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
# painted skins

static func _pebble_texture(rng: RandomNumberGenerator, cols: int, rows: int) -> ImageTexture:
	# staggered jittered lattice of dome-shaded pebbles, seamless in both axes
	var size: int = PEB_TEX
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGB8)
	var w: float = float(size) / float(cols)
	var h: float = float(size) / float(rows)
	var jx: Array = []
	var jy: Array = []
	var tint: Array = []
	var prad: Array = []
	for c in range(cols * rows):
		jx.append(rng.randf_range(-0.16, 0.16) * w)
		jy.append(rng.randf_range(-0.14, 0.14) * h)
		tint.append(rng.randf_range(0.88, 1.0))
		prad.append(rng.randf_range(0.42, 0.52) * w)
	var groove: float = 0.40
	for y in range(size):
		for x in range(size):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var row_c: int = int(floor(py / h))
			var best: float = 1.0e9
			var bdx: float = 0.0
			var bdy: float = 0.0
			var bi: int = 0
			var brad: float = w * 0.46
			for rr in range(row_c - 1, row_c + 2):
				var rw: int = posmod(rr, rows)
				var off: float = 0.0
				if (rw % 2) == 1:
					off = 0.5 * w
				var col_c: int = int(floor((px - off) / w))
				for cc in range(col_c - 1, col_c + 2):
					var cw: int = posmod(cc, cols)
					var idx: int = rw * cols + cw
					var cx: float = (float(cc) + 0.5) * w + off + jx[idx]
					var cy: float = (float(rr) + 0.5) * h + jy[idx]
					var dx: float = px - cx
					var dy: float = py - cy
					var dd: float = dx * dx + dy * dy
					if dd < best:
						best = dd
						bdx = dx
						bdy = dy
						bi = idx
						brad = prad[idx]
			var rr_safe: float = maxf(brad, 0.001)
			var q: float = sqrt(best) / rr_safe
			var v: float = groove
			if q < 1.0:
				var dome: float = sqrt(maxf(1.0 - q * q, 0.0))
				var lightv: float = -(bdx * 0.55 + bdy * 0.80) / rr_safe
				var tv: float = tint[bi]
				var lit: float = clampf((0.60 + 0.32 * dome + 0.17 * lightv * dome) * tv, 0.28, 1.0)
				var edge: float = clampf((1.0 - q) / 0.16, 0.0, 1.0)
				v = lerpf(groove, lit, edge)
			img.set_pixel(x, y, Color(v, v * 0.995, v * 0.982))
	return ImageTexture.create_from_image(img)


static func _stripe_texture(rng: RandomNumberGenerator, col_a: Color, col_b: Color, bands: int, waves: int) -> ImageTexture:
	# thick wavy horizontal bands; the wave runs along u, the bands stack in v
	var size: int = STR_TEX
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGB8)
	var phase: float = rng.randf_range(0.0, TAU)
	var amp: float = rng.randf_range(0.24, 0.34)
	var duty: float = rng.randf_range(0.24, 0.29)
	for y in range(size):
		var v: float = float(y) / float(size)
		for x in range(size):
			var u: float = float(x) / float(size)
			var wob: float = amp * sin(u * TAU * float(waves) + phase)
			wob += amp * 0.32 * sin(u * TAU * float(waves * 2) + phase * 1.7)
			var s: float = fposmod(v * float(bands) + wob, 1.0)
			var d0: float = absf(s - 0.5)
			var m: float = clampf((duty - d0) / 0.055, 0.0, 1.0)
			var c: Color = col_a.lerp(col_b, m)
			var sh: float = 0.93 + 0.11 * m
			img.set_pixel(x, y, Color(clampf(c.r * sh, 0.0, 1.0), clampf(c.g * sh, 0.0, 1.0), clampf(c.b * sh, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
