extends RefCounted

## dream_bodies / vasarely_beast — one smooth CG animal wearing a quad wireframe.
##
## Reference: scratchpad/refs/vasarely.png (2048x536 panorama) — a rank of smooth
## sinuous creatures rendered as CG surfaces: rounded organic bodies with long
## necks and tails that arch, bend and pass through holes in themselves, in
## lilac, lime green and pale grey, every surface covered in a fine quad
## wireframe grid, one body carrying a dark speckled patch.
##
## Reproduced, and how:
##   1. ONE CONTINUOUS TUBE. Tail tip and snout are the two ends of a single
##      25-point Catmull-Rom spine swept by SurfaceTool with parallel-transport
##      frames — no joins, exactly like a subdivision surface. It is cut into 32
##      MeshInstance chunks only so colour can block along it.
##   2. THE ARCH. The spine rises out of the tail, swells at the haunch, arches
##      over the back, dips at the saddle, then rises through a thin neck and
##      curls forward over itself into a blunt lowered head.
##   3. A HOLE IN ITSELF. The descending head tip and the top of the back leave a
##      ~18 cm slot; the tail is routed up the outside of the rump, over the
##      back and THROUGH that slot, its lime tip resting inside the neck loop
##      with ~5 cm clearance on every side. The tail's own sweep to the floor
##      leaves a second hole between it and the rump.
##   4. VARYING RADIUS. A 25-key profile: 28 mm at the tail tip, 178 mm at the
##      haunch, 72 mm through the neck, a small skull swell, 30 mm at the snout.
##      Both ends close with a measured quarter-circle taper, so nothing is capped
##      flat.
##   5. THREE STUBBY LEGS. Two front columns off the shoulder and one rear column
##      off the haunch, offset to the side opposite the tail — a tripod that is a
##      lean, not a stance. Each is its own tapered tube with a forward toe.
##   6. THE QUAD GRID. A 256x256 ImageTexture painted in code (anti-aliased dark
##      lattice on near-white, faint per-cell tint), run through uv1_triplanar so
##      one unbroken ~1 cm grid crosses body, legs, sail and head. Every gridded
##      surface is an ArrayMesh built in root-local coordinates with an identity
##      transform, so the lattice never breaks at a chunk seam.
##   7. PALETTE AND BLOCKING. No longer Vasarely's lilac and lime: the colours
##      are dealt from the shared queer palette (hot pink, magenta, violet,
##      cyan, acid, tangerine, lemon, lilac, mint, blood) and blocked hard along
##      the line the way the reference blocks them — a near-neighbour colour
##      from the shoulder forward, a LIT tail tip, sometimes one contrasting
##      lower leg.
##   8. THE SPECKLED PATCH. On some seeds two chunks of the haunch wear a dark
##      stippled skin — its own painted texture, grid still faintly under it,
##      and the one MATTE passage on the whole animal. A chalk haunch on a wet
##      body is the contrast; that is why it stays matte.
##   9. ONE LATERAL SAIL. A single fin off one shoulder, built as a closed
##      SurfaceTool slab that tapers to zero thickness at every free edge. One
##      side only: the asymmetry is the gesture.
##  10. THE GLOSS (2026-09-03, Palle: "add super glossy and queer materials").
##      Every surface but the speckled patch and the nostrils runs through
##      DreamSkin. One finish per seed carries the whole body — latex, patent,
##      oilslick, holo, candy, chrome, pearl or wet — and the tail tip and the
##      sail take a LOUDER one on top: neon, patent, holo, candy or wet. The
##      painted lattice keeps the albedo (the wireframe is the family's whole
##      argument, it does not get traded for a sweep), the finish keeps its
##      roughness, clearcoat, rim and emission, and the emission is remapped
##      onto the lattice so the CELLS glow and the wires stay dark. Vasarely
##      modulated hue cell by cell; the lattice's own cells now carry a small
##      seeded hue drift as well as a value one.
##
## Given up: the neighbouring creatures and the way they lean on each other; the
## sharp CG specular of the render; any subdivision crease. The grid is painted,
## not modelled — read it from a metre, not a hand's width. True smooth blends
## where tail, legs and sail meet the body were given up too — and then taken
## back on exactly one axis value, tube = fused, which is what that value is for.
##
## AXES (dream-body DNA — two, each cutting the silhouette, not the hue):
##   tube   — what the one continuous line is MADE of. smooth = the swept CG
##            surface as built; vertebrae = the same line as 46 separate
##            spindles with air between them, the outline scalloped; cage = the
##            flesh gone, eight meridian ribs and twenty-two hoops left standing
##            and see-through; swarm = the trunk dissolved into 96 small commas
##            of itself orbiting the line it used to be; melt = the arch sagging
##            under its own weight, radii swelling, drips hanging off the belly
##            into a poured puddle on the floor; fused = the same line handed to
##            an ISOSURFACE instead of a sweep.
##
##            fused, at length: the same 25 joints and the same 25 radii become
##            22 capsules in a signed-distance field, the three legs add nine
##            more, the cheeks and chin three spheres, and DreamIso marches the
##            lot at 5.8 cm cells under a 6 cm smooth union. So the legs swell
##            OUT of the belly with a fillet instead of being pushed into it,
##            the cheeks are swellings of the skull rather than balls stuck on
##            it, and the slot the tail threads through stops being a gap
##            between two meshes and becomes a place the field never crossed
##            zero. One poured mesh cannot block colour, so the blocking moves
##            outward: 34 thin GIRDLES stand proud of the flesh, carrying the
##            same per-station colours the chunks used to carry — the painted
##            grid made real, exactly where the flesh stopped being modelled.
##            MESH COUNT: 1 grown body + 34 girdles + 4 head fittings + the
##            growth axis = 42 at its thinnest, over the family floor of 40.
##            The mesher is new; if mesh_of comes back null the value falls back
##            to the swept trunk and swept legs and keeps its girdles, so the
##            plinth is never empty and the value is still not smooth.
##   growth — what grows off the shoulder where the one lit sail sits. sail =
##            the single lateral fin as built; crest = seven fins standing up
##            the whole back instead; mirror = a second whole beast, flipped and
##            at 0.44 scale, riding out of the shoulder; bloom = no fin at all,
##            and snout, tail tip and all three feet open into seven-petal
##            flowers.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const TEX: int = 256
const CAP_N: int = 4
const N_SAMP: int = 116
const RING: int = 20
const CHUNKS: int = 32
const LEG_SAMP: int = 30
const LEG_CHUNKS: int = 4
const LEG_RING: int = 14

const ISO_TRUNK: int = 22
const ISO_LEG: int = 3
const GIRDLES: int = 34

## The whole animal wears ONE of these, so a seed reads as a single wet object
## and not a sampler. "matte" and "neon" are deliberately absent: matte is
## reserved for the speckled patch, neon would blow out a body this large.
const BODY_FINISHES: Array = ["latex", "patent", "oilslick", "holo", "candy",
	"chrome", "pearl", "wet"]

## Louder, and only ever worn by the tail tip, the accent leg and the sail —
## small parts, where neon is a lit lure rather than a floodlight.
const ACCENT_FINISHES: Array = ["neon", "patent", "holo", "candy", "wet"]

## The one matte passage: the dark speckled haunch of the reference.
const PATCH_DARKS: Array = ["#2A2733", "#31302A", "#26302E", "#332A2E", "#2B2E38"]


static func describe() -> String:
	return "A wet-glossed creature under a fine quad wireframe, arching over three stubby legs while its tail sweeps to the floor and threads back through the hole under its own lowered head — latex, oil slick or chrome by seed, with one chalk-dark speckled haunch."


static func axes() -> Dictionary:
	return {
		"tube": ["smooth", "vertebrae", "cage", "swarm", "melt", "fused"],
		"growth": ["sail", "crest", "mirror", "bloom"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var tube: String = String(opts.get("tube", "smooth"))
	var growth: String = String(opts.get("growth", "sail"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- the outfit: one finish for the animal, a louder one for its accents ---
	var finish: String = str(BODY_FINISHES[rng.randi_range(0, BODY_FINISHES.size() - 1)])
	var accent_finish: String = str(ACCENT_FINISHES[rng.randi_range(0, ACCENT_FINISHES.size() - 1)])
	var col_body: Color = Gloss.queer_colour(rng)
	var col_block: Color = col_body.lerp(Gloss.queer_colour(rng), rng.randf_range(0.42, 0.70))
	var col_tip: Color = Gloss.queer_colour(rng)
	var tries: int = 0
	while _too_close(col_tip, col_body) and tries < 6:
		col_tip = Gloss.queer_colour(rng)
		tries += 1
	var col_sail: Color = col_tip if rng.randf() < 0.55 else Gloss.queer_colour(rng)
	var col_patch: Color = Color(str(PATCH_DARKS[rng.randi_range(0, PATCH_DARKS.size() - 1)]))

	# --- individual parameters ---------------------------------------------
	var body_k: float = rng.randf_range(0.95, 1.02)
	var arch: float = rng.randf_range(-0.035, 0.055)
	var head_lift: float = rng.randf_range(-0.03, 0.03)
	var sway_amp: float = rng.randf_range(0.014, 0.052)
	var sway_w: float = rng.randf_range(1.1, 2.3)
	var sway_ph: float = rng.randf_range(0.0, TAU)
	var flip: float = 1.0 if rng.randf() < 0.5 else -1.0
	var sail_side: float = -flip
	var has_patch: bool = rng.randf() < 0.55
	var patch_a: float = rng.randf_range(0.50, 0.58)
	var patch_b: float = patch_a + rng.randf_range(0.06, 0.11)
	var two_tone: bool = rng.randf() < 0.7
	var split_t: float = rng.randf_range(0.78, 0.90) if two_tone else 2.0
	var grid_cells: int = 4
	var grid_k: float = rng.randf_range(19.0, 27.0)
	# Vasarely modulated hue cell by cell; the lattice does the same, faintly.
	var hue0: float = rng.randf()
	var hue1: float = hue0 + rng.randf_range(0.08, 0.34)
	var chroma: float = rng.randf_range(0.10, 0.26)
	var accent_leg: int = rng.randi_range(0, 2)
	var has_accent_leg: bool = rng.randf() < 0.5
	var yaw: float = rng.randf_range(-0.26, 0.26)
	var sail_len: float = rng.randf_range(0.24, 0.33) * body_k

	# --- skins ---------------------------------------------------------------
	# The lattice keeps the albedo on every gridded surface; DreamSkin supplies
	# the shine around it. See _gloss for why the finish's own texture is given
	# up and its emission re-hung on the grid.
	var tex_grid: ImageTexture = _skin_texture(grid_cells, 2.5, 0.44, 1.0, 0, hue0, hue1, chroma, rng)
	var mat_body: StandardMaterial3D = _gloss(finish, col_body, tex_grid, grid_k, rng, 0.42)
	var mat_block: StandardMaterial3D = _gloss(finish, col_block, tex_grid, grid_k, rng, 0.42)
	var mat_tip: StandardMaterial3D = _gloss(accent_finish, col_tip, tex_grid, grid_k * 1.12, rng, 1.05)
	var mat_sail: StandardMaterial3D = _gloss(accent_finish, col_sail, tex_grid, grid_k * 0.88, rng, 0.80)
	var mat_patch: StandardMaterial3D = mat_body
	if has_patch:
		# THE ONE MATTE PASSAGE. A chalk-dark stippled haunch against a wet body
		# is the whole point of it — route it through DreamSkin's matte, never
		# through the gloss.
		var tex_speck: ImageTexture = _skin_texture(grid_cells, 2.0, 0.34, 0.46, 2400, 0.0, 0.0, 0.0, rng)
		mat_patch = Gloss.skin("matte", col_patch, rng)
		mat_patch.albedo_texture = tex_speck
		mat_patch.uv1_triplanar = true
		mat_patch.uv1_scale = Vector3(grid_k * 1.35, grid_k * 1.35, grid_k * 1.35)
		mat_patch.roughness = 0.94
	var mat_eye: StandardMaterial3D = Gloss.skin("patent", Color(0.06, 0.05, 0.10), rng)
	var mat_nose: StandardMaterial3D = Gloss.skin("matte", col_body.darkened(0.62), rng)

	# --- the one spine: index 0 = tail tip, index 24 = snout -----------------
	var ctrl: Array = [
		Vector3(-0.02, 1.31, -0.20),
		Vector3(-0.01, 1.24, -0.08),
		Vector3(0.02, 1.24, 0.06),
		Vector3(0.09, 1.17, 0.20),
		Vector3(0.19, 1.00, 0.34),
		Vector3(0.28, 0.78, 0.44),
		Vector3(0.32, 0.54, 0.50),
		Vector3(0.30, 0.30, 0.52),
		Vector3(0.24, 0.16, 0.47),
		Vector3(0.13, 0.11, 0.38),
		Vector3(0.04, 0.20, 0.34),
		Vector3(0.00, 0.40, 0.36),
		Vector3(0.00, 0.62, 0.35),
		Vector3(0.00, 0.82, 0.26),
		Vector3(0.00, 0.96, 0.10),
		Vector3(0.00, 1.01, -0.06),
		Vector3(0.00, 0.97, -0.20),
		Vector3(0.00, 0.92, -0.30),
		Vector3(0.00, 0.97, -0.38),
		Vector3(0.00, 1.15, -0.42),
		Vector3(0.00, 1.34, -0.40),
		Vector3(0.00, 1.45, -0.30),
		Vector3(0.00, 1.48, -0.17),
		Vector3(0.00, 1.43, -0.06),
		Vector3(0.00, 1.36, -0.02),
	]
	var radk: Array = [
		0.028, 0.036, 0.043, 0.052, 0.062, 0.072, 0.082, 0.092, 0.100, 0.106,
		0.115, 0.132, 0.158, 0.178, 0.176, 0.164, 0.148, 0.132, 0.120, 0.098,
		0.080, 0.072, 0.090, 0.072, 0.030,
	]
	ctrl[15] = (ctrl[15] as Vector3) + Vector3(0.0, arch, 0.0)
	ctrl[14] = (ctrl[14] as Vector3) + Vector3(0.0, arch * 0.6, 0.0)
	ctrl[16] = (ctrl[16] as Vector3) + Vector3(0.0, arch * 0.6, 0.0)
	for i in range(20, 25):
		ctrl[i] = (ctrl[i] as Vector3) + Vector3(0.0, head_lift, 0.0)
	var n_ctrl: int = ctrl.size()
	for i in range(n_ctrl):
		var t: float = float(i) / float(n_ctrl - 1)
		var p: Vector3 = ctrl[i]
		var wob: float = sway_amp * sin(PI * t) * sin(sway_w * TAU * t + sway_ph)
		ctrl[i] = Vector3((p.x + wob) * flip, p.y, p.z) * body_k

	var base_pts: Array = _spline(ctrl, N_SAMP)
	var pts: Array = base_pts.duplicate()
	var rad: Array = []
	for i in range(N_SAMP):
		var t: float = float(i) / float(N_SAMP - 1)
		rad.append(_key(radk, t) * body_k)
	_round_end(pts, rad, true)
	_round_end(pts, rad, false)

	# --- axis "tube" = melt: the line sags before a single frame is taken -----
	if tube == "melt":
		var sag: float = 0.30 * body_k
		for i in range(pts.size()):
			var p: Vector3 = pts[i]
			var h: float = clampf(p.y / (1.50 * body_k), 0.0, 1.0)
			var drop: float = sag * pow(h, 1.35)
			var away: Vector3 = Vector3(p.x, 0.0, p.z)
			if away.length() > 0.001:
				away = away.normalized()
			else:
				away = Vector3.FORWARD
			var spread: float = 0.46 * drop
			pts[i] = Vector3(p.x + away.x * spread, maxf(p.y - drop, 0.030 * body_k), p.z + away.z * spread)
			rad[i] = float(rad[i]) * (1.0 + 1.10 * drop)

	var frames: Array = _frames(pts)

	# --- colour blocking, resolved once per spine sample ---------------------
	var smat: Array = []
	for i in range(pts.size()):
		var tb: float = clampf(float(i - CAP_N) / float(N_SAMP - 1), 0.0, 1.0)
		var m: StandardMaterial3D = mat_body
		if tb < 0.085:
			m = mat_tip
		elif has_patch and tb >= patch_a and tb <= patch_b:
			m = mat_patch
		elif tb > split_t:
			m = mat_block
		smat.append(m)

	# --- the body itself: axis "tube" ----------------------------------------
	# tube = fused collects a signed-distance FIELD here instead of emitting
	# meshes; the legs add their own capsules below and the whole thing is
	# marched in one go afterwards, which is what lets a limb merge into a belly.
	var grown: bool = tube == "fused"
	var iso_parts: Array = []
	var leg_cache: Array = []
	if tube == "vertebrae":
		var n_seg: int = 46
		var n_pt: int = pts.size()
		for s in range(n_seg):
			var i0: int = int(round(float(s) * float(n_pt - 1) / float(n_seg)))
			var i1: int = int(round((float(s) + 0.66) * float(n_pt - 1) / float(n_seg)))
			i1 = mini(maxi(i1, i0 + 2), n_pt - 1)
			if i1 - i0 < 2:
				continue
			var brad: Array = rad.duplicate()
			for i in range(i0, i1 + 1):
				var u: float = float(i - i0) / float(i1 - i0)
				var bul: float = 0.06 + 1.34 * pow(maxf(sin(PI * u), 0.0), 0.52)
				brad[i] = float(rad[i]) * bul
			var mid: int = int((i0 + i1) / 2)
			_add(root, _tube(pts, brad, frames, i0, i1, RING), smat[mid])
	elif tube == "cage":
		var n_pt: int = pts.size()
		var rib_r: float = 0.0092 * body_k
		for k in range(8):
			var a: float = TAU * float(k) / 8.0
			var rp: Array = []
			var rr2: Array = []
			for i in range(n_pt):
				var fr: Array = frames[i]
				var nv2: Vector3 = fr[1]
				var bv2: Vector3 = fr[2]
				rp.append((pts[i] as Vector3) + (nv2 * cos(a) + bv2 * sin(a)) * float(rad[i]))
				rr2.append(rib_r)
			var rfr: Array = _frames(rp)
			var b2: Array = _bounds(n_pt, 4)
			for c in range(4):
				var i0: int = int(b2[c])
				var i1: int = int(b2[c + 1])
				if i1 <= i0:
					continue
				var mid: int = int((i0 + i1) / 2)
				_add(root, _tube(rp, rr2, rfr, i0, i1, 8), smat[mid])
		for hoop in range(22):
			var si: int = clampi(int(round(float(hoop) * float(n_pt - 1) / 21.0)), 0, n_pt - 1)
			var fr: Array = frames[si]
			var c0: Vector3 = pts[si]
			var nv3: Vector3 = fr[1]
			var bv3: Vector3 = fr[2]
			var r0: float = float(rad[si])
			var hp: Array = []
			var hr: Array = []
			for j in range(23):
				var a2: float = TAU * float(j) / 20.0
				hp.append(c0 + (nv3 * cos(a2) + bv3 * sin(a2)) * r0)
				hr.append(rib_r * 0.80)
			var hfr: Array = _frames(hp)
			_add(root, _tube(hp, hr, hfr, 0, hp.size() - 1, 7), smat[si])
	elif tube == "swarm":
		var n_pt: int = pts.size()
		for s in range(96):
			var u: float = float(s) / 95.0
			var si: int = clampi(int(round(u * float(n_pt - 1))), 0, n_pt - 1)
			var fr: Array = frames[si]
			var tv: Vector3 = fr[0]
			var nv4: Vector3 = fr[1]
			var bv4: Vector3 = fr[2]
			var r0: float = maxf(float(rad[si]), 0.014 * body_k)
			var a: float = float(s) * 2.39996
			var rho: float = 0.30 + 1.10 * fposmod(float(s) * 0.61803, 1.0)
			var off: Vector3 = (nv4 * cos(a) + bv4 * sin(a)) * (r0 * rho) + tv * (0.03 * body_k * sin(float(s) * 1.71))
			var sz: float = maxf(r0 * 0.50, 0.020 * body_k)
			var c0: Vector3 = (pts[si] as Vector3) + off
			c0.y = maxf(c0.y, sz * 1.75)
			_mini(root, c0, tv, nv4, a * 1.7, sz, smat[si])
	elif grown:
		# THE FIELD. The same joints and the same radii the sweep uses, read off
		# as capsules — 22 of them, so the head curl and the arch keep their
		# shape — and nothing is emitted yet.
		var n_pt: int = pts.size()
		for s in range(ISO_TRUNK):
			var i0: int = clampi(int(round(float(s) * float(n_pt - 1) / float(ISO_TRUNK))), 0, n_pt - 1)
			var i1: int = clampi(int(round(float(s + 1) * float(n_pt - 1) / float(ISO_TRUNK))), 0, n_pt - 1)
			if i1 <= i0:
				continue
			iso_parts.append(Iso.capsule(pts[i0] as Vector3, pts[i1] as Vector3, float(rad[i0]), float(rad[i1])))
	else:
		var b: Array = _bounds(pts.size(), CHUNKS)
		var mats: Array = []
		for c in range(CHUNKS):
			var mid: int = int((int(b[c]) + int(b[c + 1])) / 2)
			mats.append(smat[mid])
		_emit_chunks(root, pts, rad, frames, RING, CHUNKS, mats)

	# --- melt: the drips, and the pour they fall into -------------------------
	if tube == "melt":
		var lowest: float = 1000.0
		var sx: float = 0.0
		var sz2: float = 0.0
		var cnt: int = 0
		for i in range(pts.size()):
			var p: Vector3 = pts[i]
			lowest = minf(lowest, p.y - float(rad[i]))
			if p.y < 0.60 * body_k:
				sx += p.x
				sz2 += p.z
				cnt += 1
		if cnt < 1:
			cnt = 1
		var pud: Vector3 = Vector3(sx / float(cnt), lowest + 0.058 * body_k, sz2 / float(cnt))
		_add(root, _ellip(pud, Vector3(0.40 * body_k, 0.056 * body_k, 0.44 * body_k), 26, 12), mat_block)
		for d in range(9):
			var td: float = lerpf(0.14, 0.88, float(d) / 8.0)
			var si: int = _idx(td)
			var pc: Vector3 = pts[si]
			var rr: float = float(rad[si])
			var top: Vector3 = pc - Vector3(0.0, rr * 0.35, 0.0)
			var by: float = lowest + (0.035 + 0.30 * absf(sin(float(d) * 2.3994))) * body_k
			if top.y - by < 0.09 * body_k:
				continue
			_drip(root, top, by, rr * 0.42, smat[si])

	# --- legs ----------------------------------------------------------------
	var legs: Array = [
		[0.712, 1.0, 0.108],
		[0.712, -1.0, 0.108],
		[0.556, -1.0, 0.128],
	]
	for li in range(legs.size()):
		var spec: Array = legs[li]
		var tb: float = float(spec[0])
		var sgn: float = float(spec[1]) * flip
		var r_top: float = float(spec[2]) * body_k
		var si: int = _idx(tb)
		var pc: Vector3 = pts[si]
		var rr: float = float(rad[si])
		var fr: Array = frames[si]
		var tv: Vector3 = fr[0]
		var lat: Vector3 = _lat(tv)
		var dors: Vector3 = _dors(tv, lat)
		var hip: Vector3 = pc + lat * (sgn * 0.55 * rr)
		var root_p: Vector3 = pc + lat * (sgn * 0.28 * rr) - dors * (0.22 * rr)
		var lc: Array = [
			root_p,
			Vector3(hip.x + sgn * 0.020, 0.72 * body_k, hip.z - 0.03 * body_k),
			Vector3(hip.x + sgn * 0.042, 0.50 * body_k, hip.z - 0.05 * body_k),
			Vector3(hip.x + sgn * 0.050, 0.30 * body_k, hip.z - 0.02 * body_k),
			Vector3(hip.x + sgn * 0.050, 0.125 * body_k, hip.z - 0.03 * body_k),
			Vector3(hip.x + sgn * 0.050, 0.055 * body_k, hip.z - 0.115 * body_k),
		]
		var lk: Array = [r_top, r_top * 0.84, r_top * 0.69, r_top * 0.56, r_top * 0.51, r_top * 0.44]
		if tube == "melt":
			# a melted leg is a splayed cone, not a column: it pools at the foot
			var y_top: float = maxf(hip.y - 0.07 * body_k, 0.12 * body_k)
			for i in range(1, lc.size()):
				var q: Vector3 = lc[i]
				var f: float = float(i - 1) / float(lc.size() - 2)
				var yy: float = lerpf(y_top, -0.020 * body_k, pow(f, 0.82))
				lc[i] = Vector3(q.x + sgn * 0.070 * body_k * f, yy, q.z + 0.020 * body_k * f)
			lk = [r_top, r_top * 0.96, r_top * 0.98, r_top * 1.10, r_top * 1.28, r_top * 1.48]
		var lpts: Array = _spline(lc, LEG_SAMP)
		var lrad: Array = []
		for i in range(LEG_SAMP):
			lrad.append(_key(lk, float(i) / float(LEG_SAMP - 1)))
		_round_end(lpts, lrad, true)
		var lfr: Array = _frames(lpts)
		var lmats: Array = []
		for c in range(LEG_CHUNKS):
			var m: StandardMaterial3D = mat_body
			if has_accent_leg and li == accent_leg and c >= LEG_CHUNKS - 2:
				m = mat_tip
			lmats.append(m)
		if grown:
			# the limb goes into the FIELD, so it swells out of the belly with a
			# fillet instead of being pushed through it. Cached whole, because
			# the mesher is new and the fallback has to be able to sweep it.
			leg_cache.append([lpts, lrad, lfr, lmats])
			var n_lp: int = lpts.size()
			for s in range(ISO_LEG):
				var j0: int = clampi(int(round(float(s) * float(n_lp - 1) / float(ISO_LEG))), 0, n_lp - 1)
				var j1: int = clampi(int(round(float(s + 1) * float(n_lp - 1) / float(ISO_LEG))), 0, n_lp - 1)
				if j1 <= j0:
					continue
				iso_parts.append(Iso.capsule(lpts[j0] as Vector3, lpts[j1] as Vector3, float(lrad[j0]), float(lrad[j1])))
		else:
			_emit_chunks(root, lpts, lrad, lfr, LEG_RING, LEG_CHUNKS, lmats)
		if growth == "bloom":
			var toe: Vector3 = lpts[lpts.size() - 1]
			var heel: Vector3 = lpts[lpts.size() - 7]
			var fdir: Vector3 = toe - heel
			if fdir.length() < 0.0001:
				fdir = Vector3.FORWARD
			var fax: Vector3 = (Vector3.UP * 0.92 - fdir.normalized() * 0.34).normalized()
			_flower(root, toe + fax * (0.030 * body_k), fax, 0.115 * body_k, mat_sail, mat_tip)

	# --- head anchors, resolved once -----------------------------------------
	# Hoisted above the march: on tube = fused the cheeks and the chin are parts
	# of the FIELD, so the skull swells rather than wearing three stuck-on balls,
	# and the field has to know where they are before it is meshed.
	var hi: int = _idx(0.917)
	var hp: Vector3 = pts[hi]
	var hr: float = float(rad[hi])
	var hfr: Array = frames[hi]
	var ht: Vector3 = hfr[0]
	var hlat: Vector3 = _lat(ht)
	var hdors: Vector3 = _dors(ht, hlat)
	var chin_i: int = _idx(0.958)
	var chin_fr: Array = frames[chin_i]
	var chin_t: Vector3 = chin_fr[0]
	var chin_p: Vector3 = pts[chin_i]
	var chin: Vector3 = chin_p - _dors(chin_t, _lat(chin_t)) * (0.032 * body_k)
	var cheeks: Array = []
	for s in range(2):
		var sg3: float = -1.0 if s == 0 else 1.0
		cheeks.append(hp + hlat * (sg3 * 0.64 * hr) + ht * (0.22 * hr) - hdors * (0.09 * hr))

	# --- tube = fused: the march, and its fallback ---------------------------
	var fused_ok: bool = false
	if grown:
		iso_parts.append(Iso.sphere(chin, 0.050 * body_k))
		iso_parts.append(Iso.sphere(cheeks[0] as Vector3, 0.60 * hr))
		iso_parts.append(Iso.sphere(cheeks[1] as Vector3, 0.60 * hr))
		# 5.8 cm cells and a 6 cm union: loose enough to fillet every joint,
		# tight enough that the ~18 cm slot the tail threads through does not
		# weld shut — the hole survives as a place the field never crosses zero.
		# A 5 cm pad instead of the default 12 keeps the sample grid near 34k
		# corners; at this cell the 28 mm tail tip is about one cell across, so
		# it grows a rounded stub rather than the swept point. That is the
		# resolution of the thing, and it is meant to show.
		# mesh_of, not add_body, so the pad is ours and the null is unambiguous.
		var grown_mesh: ArrayMesh = Iso.mesh_of(iso_parts, 0.058 * body_k, 0.060 * body_k, 0.05)
		fused_ok = grown_mesh != null
		if fused_ok:
			_add(root, grown_mesh, mat_body)
		else:
			# THE MESHER IS NEW. An empty field, or a field that never crossed
			# zero, returns null — so sweep the family's own trunk and legs
			# rather than stand an empty plinth. The girdles below still go on,
			# so the value is still not a second copy of smooth.
			var bf: Array = _bounds(pts.size(), CHUNKS)
			var fmats: Array = []
			for c in range(CHUNKS):
				var mid: int = int((int(bf[c]) + int(bf[c + 1])) / 2)
				fmats.append(smat[mid])
			_emit_chunks(root, pts, rad, frames, RING, CHUNKS, fmats)
			for lc_v in leg_cache:
				var lc2: Array = lc_v
				_emit_chunks(root, lc2[0], lc2[1], lc2[2], LEG_RING, LEG_CHUNKS, lc2[3])
		# THE GIRDLES. One poured mesh has one material, so the hard colour
		# blocking the family lives by moves off the flesh and onto 34 thin
		# hoops standing proud of it: the painted grid, made real, exactly where
		# the modelling stopped.
		for g in range(GIRDLES):
			var si: int = clampi(int(round(float(g) * float(pts.size() - 1) / float(GIRDLES - 1))), 0, pts.size() - 1)
			var gfr0: Array = frames[si]
			var gc: Vector3 = pts[si]
			var gn: Vector3 = gfr0[1]
			var gb: Vector3 = gfr0[2]
			# clear of the fillet: a smooth union swells the surface at a joint
			var g_r: float = float(rad[si]) * 1.05 + 0.014 * body_k
			var gp: Array = []
			var gr: Array = []
			for j in range(23):
				var a4: float = TAU * float(j) / 20.0
				gp.append(gc + (gn * cos(a4) + gb * sin(a4)) * g_r)
				gr.append(0.0074 * body_k)
			var gfr: Array = _frames(gp)
			_add(root, _tube(gp, gr, gfr, 0, gp.size() - 1, 7), smat[si])

	# --- axis "growth": what comes off the shoulder ---------------------------
	var sail_th: float = 0.021 * body_k
	if growth == "crest":
		# the one fin multiplied into a dorsal rank standing up the whole back
		for f in range(7):
			var fu: float = float(f) / 6.0
			var u0: float = lerpf(0.30, 0.90, fu)
			var alt: float = 1.0 if f % 2 == 0 else -1.0
			var flen: float = sail_len * lerpf(1.45, 0.58, fu)
			_fin(root, pts, rad, frames, u0 - 0.038, u0 + 0.038, alt * 0.16, 1.0, alt * 0.07, 0.82, flen, sail_th * 0.92, body_k, mat_sail)
	elif growth == "mirror":
		# a second whole beast, flipped, riding out of the shoulder
		var mi: int = _idx(0.735)
		var mfr: Array = frames[mi]
		var mtv: Vector3 = mfr[0]
		var mlat: Vector3 = _lat(mtv)
		var mdors: Vector3 = _dors(mtv, mlat)
		var mrr: float = float(rad[mi])
		var k2: float = 0.44
		var anchor: Vector3 = (pts[mi] as Vector3) + mlat * (sail_side * 0.95 * mrr) + mdors * (0.60 * mrr)
		var pivot: Vector3 = pts[_idx(0.50)]
		var bas: Basis = Basis(mlat, PI).scaled(Vector3(k2, k2, k2))
		var mp: Array = []
		var mr: Array = []
		for i in range(pts.size()):
			mp.append(anchor + bas * ((pts[i] as Vector3) - pivot))
			mr.append(float(rad[i]) * k2)
		var mfrs: Array = _frames(mp)
		var mb: Array = _bounds(mp.size(), 14)
		for c in range(14):
			var i0: int = int(mb[c])
			var i1: int = int(mb[c + 1])
			if i1 <= i0:
				continue
			var mid: int = int((i0 + i1) / 2)
			_add(root, _tube(mp, mr, mfrs, i0, i1, 12), smat[mid])
		var ei: int = _idx(0.917)
		var efr: Array = mfrs[ei]
		var etv: Vector3 = efr[0]
		var elat: Vector3 = _lat(etv)
		var ep: Vector3 = mp[ei]
		var er: float = float(mr[ei])
		for s in range(2):
			var sg2: float = -1.0 if s == 0 else 1.0
			_add(root, _ball(ep + elat * (sg2 * 0.72 * er), 0.60 * er, 12, 8), mat_block)
	elif growth != "bloom":
		_fin(root, pts, rad, frames, 0.665, 0.805, sail_side * 0.86, 0.50, sail_side * 0.52, 0.60, sail_len, sail_th, body_k, mat_sail)

	# --- head ----------------------------------------------------------------
	# The lumps are skipped only when the field actually marched: on a grown
	# skull the chin and cheeks ARE the skull, and a ball on top of them would
	# be a coincident surface.
	var head_mat: StandardMaterial3D = mat_block if two_tone else mat_body
	var head_lumps: bool = not fused_ok
	if head_lumps:
		_add(root, _ball(chin, 0.048 * body_k, 14, 9), head_mat)
	for s in range(2):
		var sgn: float = -1.0 if s == 0 else 1.0
		var cheek: Vector3 = cheeks[s]
		if head_lumps:
			_add(root, _ball(cheek, 0.56 * hr, 14, 9), head_mat)
		var out_e: Vector3 = (hlat * (sgn * 0.76) + hdors * 0.52 + ht * 0.38).normalized()
		var eye_p: Vector3 = cheek + out_e * (0.49 * hr)
		var eye := SphereMesh.new()
		eye.radius = 0.017 * body_k
		eye.height = 0.034 * body_k
		eye.radial_segments = 14
		eye.rings = 8
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(Basis(), eye_p)
		var ni: int = _idx(0.978)
		var nfr: Array = frames[ni]
		var nt: Vector3 = nfr[0]
		var np: Vector3 = pts[ni]
		var nr: float = float(rad[ni])
		var nl: Vector3 = _lat(nt)
		var nose_p: Vector3 = np + nl * (sgn * 0.70 * nr) - _dors(nt, nl) * (0.68 * nr)
		var nose := SphereMesh.new()
		nose.radius = 0.0085 * body_k
		nose.height = 0.017 * body_k
		nose.radial_segments = 10
		nose.rings = 6
		var nm: MeshInstance3D = _add(root, nose, mat_nose)
		nm.transform = Transform3D(Basis(), nose_p)

	# --- bloom: the two free ends of the one line open into flowers -----------
	if growth == "bloom":
		var bi: int = _idx(0.995)
		var bfr: Array = frames[bi]
		var btv: Vector3 = bfr[0]
		var bax: Vector3 = btv.normalized()
		_flower(root, (pts[bi] as Vector3) + bax * (0.035 * body_k), bax, 0.175 * body_k, mat_sail, mat_block)
		var ti: int = _idx(0.006)
		var tfr: Array = frames[ti]
		var ttv: Vector3 = tfr[0]
		var tax: Vector3 = -(ttv.normalized())
		_flower(root, (pts[ti] as Vector3) + tax * (0.025 * body_k), tax, 0.135 * body_k, mat_sail, mat_tip)

	# --- measured settle: yaw, fit, floor, centre ----------------------------
	_premul(root, Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO))
	var box: AABB = _union_aabb(root)
	var kfit: float = 1.0
	kfit = minf(kfit, 1.2 / maxf(box.size.x, 0.001))
	kfit = minf(kfit, 1.2 / maxf(box.size.z, 0.001))
	kfit = minf(kfit, 1.68 / maxf(box.size.y, 0.001))
	if box.size.y * kfit < 1.06:
		var grow: float = 1.06 / maxf(box.size.y * kfit, 0.001)
		grow = minf(grow, 1.2 / maxf(box.size.x * kfit, 0.001))
		grow = minf(grow, 1.2 / maxf(box.size.z * kfit, 0.001))
		if grow > 1.0:
			kfit *= grow
	if absf(kfit - 1.0) > 0.0005:
		_premul(root, Transform3D(Basis().scaled(Vector3(kfit, kfit, kfit)), Vector3.ZERO))
		box = _union_aabb(root)
	var ctr: Vector3 = box.position + box.size * 0.5
	_premul(root, Transform3D(Basis(), Vector3(-ctr.x, -box.position.y, -ctr.z)))


# ---------------------------------------------------------------------------
# materials and scene plumbing

## One gridded, glossy surface: DreamSkin's finish with the family's lattice put
## back on the albedo.
##
## The trade is deliberate. oilslick, holo and chrome each paint their own
## texture — a sweep or a brushed streak — and this family cannot keep it: the
## wireframe IS the argument, and two textures cannot share one uv1 scale (the
## lattice wants ~20x triplanar, a sweep wants 0.5x, and a sweep tiled twenty
## times is moiré, not iridescence). So the lattice takes the albedo, and the
## iridescence is carried the way the family already carries colour — blocked
## hard along the line — plus rim tint, which is angle and needs no texture.
##
## Two finishes also darken or bleach their albedo because they expected their
## own texture there; they get the colour back, or a chrome beast under a
## near-white lattice photographs as a grey one.
##
## The emission is re-hung on the same lattice, so the CELLS glow and the wires
## stay dark — a wireframe in negative — and capped, because a whole animal at
## neon's 3.2 is a white blob under ACES.
static func _gloss(finish: String, base: Color, tex: ImageTexture, k: float,
		rng: RandomNumberGenerator, emit_cap: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, base, rng)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(k, k, k)
	var lit: Color = base
	if finish == "chrome":
		lit = Color(0.86, 0.88, 0.92).lerp(base, 0.32)
	elif finish == "pearl":
		lit = Color(0.95, 0.93, 0.95).lerp(base, 0.36)
	elif finish == "oilslick":
		lit = base.lerp(Color(0.10, 0.09, 0.17), 0.42)
	m.albedo_color = lit
	if m.emission_enabled:
		m.emission = base
		m.emission_texture = tex
		m.emission_energy_multiplier = minf(m.emission_energy_multiplier, emit_cap)
	return m


## Two palette picks landing on the same hue kill the blocking, which is the one
## thing this family reads by from a distance.
static func _too_close(a: Color, b: Color) -> bool:
	var d: float = absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
	return d < 0.55


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _premul(root: Node3D, m: Transform3D) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = m * cm.transform


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
# curves

static func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2: float = u * u
	var u3: float = u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)


static func _spline(ctrl: Array, n: int) -> Array:
	var m: int = ctrl.size()
	var out: Array = []
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var f: float = t * float(m - 1)
		var seg: int = int(floor(f))
		if seg > m - 2:
			seg = m - 2
		var u: float = f - float(seg)
		var p0: Vector3 = ctrl[maxi(seg - 1, 0)]
		var p1: Vector3 = ctrl[seg]
		var p2: Vector3 = ctrl[mini(seg + 1, m - 1)]
		var p3: Vector3 = ctrl[mini(seg + 2, m - 1)]
		out.append(_catmull(p0, p1, p2, p3, u))
	return out


static func _key(keys: Array, t: float) -> float:
	# Catmull-Rom on scalars: a smoothstep ladder flattens at every key and reads
	# as ribbing along a long swept tube.
	var m: int = keys.size()
	if m < 2:
		return float(keys[0])
	var f: float = clampf(t, 0.0, 1.0) * float(m - 1)
	var i: int = clampi(int(floor(f)), 0, m - 2)
	var u: float = f - float(i)
	var k0: float = float(keys[maxi(i - 1, 0)])
	var k1: float = float(keys[i])
	var k2: float = float(keys[mini(i + 1, m - 1)])
	var k3: float = float(keys[mini(i + 2, m - 1)])
	var u2: float = u * u
	var u3: float = u2 * u
	var r: float = 0.5 * ((2.0 * k1) + (-k0 + k2) * u + (2.0 * k0 - 5.0 * k1 + 4.0 * k2 - k3) * u2 + (-k0 + 3.0 * k1 - 3.0 * k2 + k3) * u3)
	return maxf(r, 0.004)


static func _round_end(pts: Array, radii: Array, at_end: bool) -> void:
	var n: int = pts.size()
	var idx: int = n - 1 if at_end else 0
	var other: int = n - 2 if at_end else 1
	var base: Vector3 = pts[idx]
	var away: Vector3 = base - (pts[other] as Vector3)
	if away.length() < 0.000001:
		away = Vector3.UP
	var d: Vector3 = away.normalized()
	var r: float = float(radii[idx])
	var phis: Array = [32.0, 58.0, 78.0, 90.0]
	for k in range(phis.size()):
		var ph: float = deg_to_rad(float(phis[k]))
		var p: Vector3 = base + d * (r * sin(ph))
		var rr: float = maxf(r * cos(ph), 0.0035)
		if at_end:
			pts.append(p)
			radii.append(rr)
		else:
			pts.insert(0, p)
			radii.insert(0, rr)


static func _frames(pts: Array) -> Array:
	var n: int = pts.size()
	var tans: Array = []
	for i in range(n):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var bq: Vector3 = pts[mini(i + 1, n - 1)]
		var d: Vector3 = bq - a
		if d.length() < 0.000001:
			d = Vector3.FORWARD
		tans.append(d.normalized())
	var t0: Vector3 = tans[0]
	var refv: Vector3 = Vector3.RIGHT
	if absf(t0.dot(refv)) > 0.9:
		refv = Vector3.UP
	var nrm: Vector3 = (refv - t0 * t0.dot(refv)).normalized()
	var out: Array = []
	for i in range(n):
		var tv: Vector3 = tans[i]
		var proj: Vector3 = nrm - tv * tv.dot(nrm)
		if proj.length() < 0.00001:
			proj = Vector3.UP - tv * tv.dot(Vector3.UP)
		if proj.length() < 0.00001:
			proj = Vector3.RIGHT - tv * tv.dot(Vector3.RIGHT)
		nrm = proj.normalized()
		out.append([tv, nrm, tv.cross(nrm).normalized()])
	return out


static func _bounds(n_pts: int, n_chunks: int) -> Array:
	var out: Array = []
	for c in range(n_chunks + 1):
		out.append(int(round(float(c) * float(n_pts - 1) / float(n_chunks))))
	return out


static func _idx(t: float) -> int:
	return CAP_N + clampi(int(round(clampf(t, 0.0, 1.0) * float(N_SAMP - 1))), 0, N_SAMP - 1)


static func _lat(tv: Vector3) -> Vector3:
	var l: Vector3 = tv.cross(Vector3.UP)
	if l.length() < 0.001:
		l = tv.cross(Vector3.FORWARD)
	if l.length() < 0.001:
		return Vector3.RIGHT
	return l.normalized()


static func _dors(tv: Vector3, lat: Vector3) -> Vector3:
	var d: Vector3 = lat.cross(tv)
	if d.length() < 0.001:
		return Vector3.UP
	d = d.normalized()
	if d.y < 0.0:
		d = -d
	return d


# ---------------------------------------------------------------------------
# surfaces

static func _quad_n(st: SurfaceTool, a: Vector3, bq: Vector3, c: Vector3, d: Vector3, want: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(bq - a)
	if nf.dot(want) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(bq)
		st.add_vertex(c)
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(bq)
		st.add_vertex(a)
		st.add_vertex(d)
		st.add_vertex(c)


static func _tri_n(st: SurfaceTool, a: Vector3, bq: Vector3, c: Vector3, want: Vector3) -> void:
	var nf: Vector3 = (c - a).cross(bq - a)
	if nf.dot(want) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(bq)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(bq)


static func _tube(pts: Array, radii: Array, frames: Array, i0: int, i1: int, seg: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in range(i0, i1 + 1):
		var fr: Array = frames[i]
		var c: Vector3 = pts[i]
		var nv: Vector3 = fr[1]
		var bv: Vector3 = fr[2]
		var r: float = float(radii[i])
		var ring: Array = []
		for j in range(seg):
			var a: float = TAU * float(j) / float(seg)
			ring.append(c + (nv * cos(a) + bv * sin(a)) * r)
		rings.append(ring)
	for k in range(rings.size() - 1):
		var r0: Array = rings[k]
		var r1: Array = rings[k + 1]
		var axis: Vector3 = ((pts[i0 + k] as Vector3) + (pts[i0 + k + 1] as Vector3)) * 0.5
		for j in range(seg):
			var j2: int = (j + 1) % seg
			var a0: Vector3 = r0[j]
			var a1: Vector3 = r0[j2]
			var b0: Vector3 = r1[j]
			var b1: Vector3 = r1[j2]
			var mid: Vector3 = (a0 + a1 + b0 + b1) * 0.25
			var want: Vector3 = mid - axis
			if want.length() < 0.00001:
				want = Vector3.UP
			_quad_n(st, a0, a1, b1, b0, want.normalized())
	st.generate_normals()
	return st.commit()


static func _emit_chunks(root: Node3D, pts: Array, radii: Array, frames: Array, seg: int, n_chunks: int, mats: Array) -> void:
	var b: Array = _bounds(pts.size(), n_chunks)
	for c in range(n_chunks):
		var i0: int = int(b[c])
		var i1: int = int(b[c + 1])
		if i1 <= i0:
			continue
		_add(root, _tube(pts, radii, frames, i0, i1, seg), mats[c])


static func _sph(u: float, v: float) -> Vector3:
	return Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))


static func _ball(c: Vector3, r: float, su: int, sv: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(sv):
		var v0: float = PI * float(i) / float(sv)
		var v1: float = PI * float(i + 1) / float(sv)
		for j in range(su):
			var u0: float = TAU * float(j) / float(su)
			var u1: float = TAU * float(j + 1) / float(su)
			var p00: Vector3 = c + _sph(u0, v0) * r
			var p10: Vector3 = c + _sph(u1, v0) * r
			var p11: Vector3 = c + _sph(u1, v1) * r
			var p01: Vector3 = c + _sph(u0, v1) * r
			if i == 0:
				_tri_n(st, p00, p11, p01, (p11 + p01) * 0.5 - c)
			elif i == sv - 1:
				_tri_n(st, p00, p10, p11, (p00 + p10) * 0.5 - c)
			else:
				var mid: Vector3 = (p00 + p10 + p11 + p01) * 0.25
				_quad_n(st, p00, p10, p11, p01, (mid - c).normalized())
	st.generate_normals()
	return st.commit()


static func _fin(root: Node3D, pts: Array, rad: Array, frames: Array, t0: float, t1: float, side_mix: float, dors_mix: float, root_lat: float, root_dors: float, fin_len: float, fin_th: float, body_k: float, mat: StandardMaterial3D) -> void:
	# The one lateral sail, generalised: side_mix / dors_mix aim the blade, so the
	# same closed slab that tapers to nothing at every free edge serves both the
	# shoulder fin and the dorsal crest.
	var nu: int = 18
	var nv: int = 7
	var grid: Array = []
	var snrm: Array = []
	var sthk: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / float(nu)
		var tb: float = lerpf(t0, t1, u)
		var si: int = _idx(tb)
		var fr: Array = frames[si]
		var tv: Vector3 = fr[0]
		var pc: Vector3 = pts[si]
		var rr: float = float(rad[si])
		var lat: Vector3 = _lat(tv)
		var dors: Vector3 = _dors(tv, lat)
		var root_p: Vector3 = pc + lat * (root_lat * rr) + dors * (root_dors * rr)
		var out_d: Vector3 = (lat * side_mix + dors * dors_mix).normalized()
		var sw: float = maxf(sin(PI * (0.055 + 0.89 * u)), 0.0)
		var ln: float = fin_len * pow(sw, 0.68)
		var row: Array = []
		var hrow: Array = []
		for j in range(nv + 1):
			var v: float = float(j) / float(nv)
			row.append(root_p + out_d * (ln * v) - tv * (0.075 * body_k * v * v))
			var edge: float = maxf(sin(PI * u), 0.0)
			hrow.append(fin_th * pow(1.0 - v, 0.5) * pow(edge, 0.45))
		grid.append(row)
		sthk.append(hrow)
		snrm.append(out_d.cross(tv).normalized())
	for panel in range(3):
		var i0: int = panel * 6
		var i1: int = i0 + 6
		_add(root, _sail_panel(grid, snrm, sthk, i0, i1, nv), mat)


static func _mini(root: Node3D, c: Vector3, tv: Vector3, nv: Vector3, a: float, sz: float, mat: StandardMaterial3D) -> void:
	# One grain of the swarm: the beast's own comma — two tapered ends, a fat
	# middle — at a fiftieth of its size, thrown onto an arbitrary axis.
	var ax: Vector3 = tv * cos(a) + nv * sin(a)
	if ax.length() < 0.0001:
		ax = Vector3.UP
	ax = ax.normalized()
	var up2: Vector3 = ax.cross(Vector3.UP)
	if up2.length() < 0.001:
		up2 = ax.cross(Vector3.RIGHT)
	if up2.length() < 0.001:
		up2 = Vector3.FORWARD
	up2 = up2.normalized()
	var mc: Array = [
		c - ax * (sz * 1.45),
		c - ax * (sz * 0.50) + up2 * (sz * 0.30),
		c + ax * (sz * 0.50) + up2 * (sz * 0.34),
		c + ax * (sz * 1.30) - up2 * (sz * 0.40),
	]
	var mpts: Array = _spline(mc, 9)
	var keys: Array = [sz * 0.10, sz * 0.40, sz * 0.50, sz * 0.15]
	var mrad: Array = []
	for i in range(9):
		mrad.append(_key(keys, float(i) / 8.0))
	_round_end(mpts, mrad, true)
	_round_end(mpts, mrad, false)
	var mfr: Array = _frames(mpts)
	_add(root, _tube(mpts, mrad, mfr, 0, mpts.size() - 1, 8), mat)


static func _drip(root: Node3D, top: Vector3, bot_y: float, r_top: float, mat: StandardMaterial3D) -> void:
	# A pendant off the melted belly: a thin neck, a swollen bead, a point.
	var bot: Vector3 = Vector3(top.x, bot_y, top.z)
	var dc: Array = [
		top,
		top.lerp(bot, 0.45) + Vector3(0.006, 0.0, -0.004),
		top.lerp(bot, 0.82) + Vector3(0.002, 0.0, 0.003),
		bot,
	]
	var dp: Array = _spline(dc, 14)
	var keys: Array = [r_top, r_top * 0.30, r_top * 0.44, r_top * 0.12]
	var dr: Array = []
	for i in range(14):
		dr.append(_key(keys, float(i) / 13.0))
	_round_end(dp, dr, true)
	var dfr: Array = _frames(dp)
	_add(root, _tube(dp, dr, dfr, 0, dp.size() - 1, 12), mat)


static func _ellip(c: Vector3, r: Vector3, su: int, sv: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(sv):
		var v0: float = PI * float(i) / float(sv)
		var v1: float = PI * float(i + 1) / float(sv)
		for j in range(su):
			var u0: float = TAU * float(j) / float(su)
			var u1: float = TAU * float(j + 1) / float(su)
			var p00: Vector3 = c + _sph(u0, v0) * r
			var p10: Vector3 = c + _sph(u1, v0) * r
			var p11: Vector3 = c + _sph(u1, v1) * r
			var p01: Vector3 = c + _sph(u0, v1) * r
			if i == 0:
				_tri_n(st, p00, p11, p01, (p11 + p01) * 0.5 - c)
			elif i == sv - 1:
				_tri_n(st, p00, p10, p11, (p00 + p10) * 0.5 - c)
			else:
				var mid: Vector3 = (p00 + p10 + p11 + p01) * 0.25
				_quad_n(st, p00, p10, p11, p01, (mid - c).normalized())
	st.generate_normals()
	return st.commit()


static func _petal(c: Vector3, out_d: Vector3, up_d: Vector3, ln: float, wid: float, th: float) -> ArrayMesh:
	# A cupped leaf, built as a one-panel sail so the family's edge rule still
	# holds: zero width at base and tip, zero thickness at both free sides.
	var od: Vector3 = out_d.normalized()
	var side: Vector3 = od.cross(up_d)
	if side.length() < 0.0001:
		side = od.cross(Vector3.UP)
	if side.length() < 0.0001:
		side = od.cross(Vector3.RIGHT)
	side = side.normalized()
	var pn: Vector3 = side.cross(od).normalized()
	var nu: int = 8
	var nv: int = 6
	var grid: Array = []
	var nrms: Array = []
	var thick: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / float(nu)
		var w: float = wid * sin(PI * pow(clampf(u, 0.0, 1.0), 0.60))
		var curl: float = ln * 0.22 * (1.0 - cos(PI * u))
		var ap: Vector3 = c + od * (ln * u) + pn * curl
		var row: Array = []
		var hrow: Array = []
		for j in range(nv + 1):
			var v: float = float(j) / float(nv) * 2.0 - 1.0
			row.append(ap + side * (w * v) + pn * (w * absf(v) * 0.30))
			hrow.append(th * (1.0 - absf(v)) * maxf(sin(PI * u), 0.06))
		grid.append(row)
		thick.append(hrow)
		nrms.append(pn)
	return _sail_panel(grid, nrms, thick, 0, nu, nv)


static func _flower(root: Node3D, c: Vector3, ax: Vector3, r: float, mat_p: StandardMaterial3D, mat_c: StandardMaterial3D) -> void:
	var up_d: Vector3 = ax.normalized()
	var s0: Vector3 = _lat(up_d)
	var s1: Vector3 = up_d.cross(s0).normalized()
	_add(root, _ball(c, r * 0.30, 12, 8), mat_c)
	for k in range(7):
		var a: float = TAU * float(k) / 7.0
		var out_d: Vector3 = (s0 * cos(a) + s1 * sin(a) + up_d * 0.34).normalized()
		_add(root, _petal(c + out_d * (r * 0.20), out_d, up_d, r * 1.30, r * 0.44, r * 0.055), mat_p)


static func _sail_panel(grid: Array, nrms: Array, thick: Array, i0: int, i1: int, nv: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(i0, i1):
		var ra: Array = grid[i]
		var rb: Array = grid[i + 1]
		var ha: Array = thick[i]
		var hb: Array = thick[i + 1]
		var na: Vector3 = nrms[i]
		var nb: Vector3 = nrms[i + 1]
		for j in range(nv):
			var a0: Vector3 = ra[j]
			var a1: Vector3 = ra[j + 1]
			var b0: Vector3 = rb[j]
			var b1: Vector3 = rb[j + 1]
			var fa0: Vector3 = a0 + na * float(ha[j])
			var fa1: Vector3 = a1 + na * float(ha[j + 1])
			var fb0: Vector3 = b0 + nb * float(hb[j])
			var fb1: Vector3 = b1 + nb * float(hb[j + 1])
			var ka0: Vector3 = a0 - na * float(ha[j])
			var ka1: Vector3 = a1 - na * float(ha[j + 1])
			var kb0: Vector3 = b0 - nb * float(hb[j])
			var kb1: Vector3 = b1 - nb * float(hb[j + 1])
			_quad_n(st, fa0, fa1, fb1, fb0, na)
			_quad_n(st, ka0, ka1, kb1, kb0, -na)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# painted skins

## The quad lattice. Per-cell tinting was always here as a VALUE drift; the hue
## drift (chroma > 0) is the queer half — Vasarely's own practice was modulating
## a unit cell by cell, and a body that shifts hue across a centimetre grid is
## the closest this family gets to iridescence without giving the albedo away.
## chroma = 0 reproduces the old greyscale lattice exactly, which is what the
## speckled patch still wants.
static func _skin_texture(cells: int, line_w: float, ink: float, base_v: float, speck: int,
		hue0: float, hue1: float, chroma: float, rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	img.fill(Color(base_v, base_v, base_v))
	var cell: float = float(TEX) / float(cells)
	var tint: Array = []
	for i in range(cells * cells):
		var hh: float = fposmod(lerpf(hue0, hue1, rng.randf()), 1.0)
		var vv: float = rng.randf_range(0.972, 1.0)
		tint.append(Color.from_hsv(hh, chroma, vv))
	var line_col := Color(ink, ink, ink)
	for y in range(TEX):
		for x in range(TEX):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var cx: int = int(floor(px / cell))
			var cy: int = int(floor(py / cell))
			var fx: float = px - float(cx) * cell
			var fy: float = py - float(cy) * cell
			var d: float = minf(minf(fx, cell - fx), minf(fy, cell - fy))
			var amt: float = clampf((line_w - d) / 1.15, 0.0, 1.0)
			var tc: Color = tint[posmod(cy, cells) * cells + posmod(cx, cells)]
			var bc := Color(base_v * tc.r, base_v * tc.g, base_v * tc.b)
			img.set_pixel(x, y, bc.lerp(line_col, amt))
	for i in range(speck):
		var sx: int = rng.randi_range(0, TEX - 1)
		var sy: int = rng.randi_range(0, TEX - 1)
		var sv: float = rng.randf_range(0.58, 1.0)
		img.set_pixel(sx, sy, Color(sv, sv, sv))
		if rng.randf() < 0.45:
			var s2: float = sv * 0.88
			img.set_pixel(posmod(sx + 1, TEX), sy, Color(s2, s2, s2))
		if rng.randf() < 0.45:
			var s3: float = sv * 0.88
			img.set_pixel(sx, posmod(sy + 1, TEX), Color(s3, s3, s3))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

