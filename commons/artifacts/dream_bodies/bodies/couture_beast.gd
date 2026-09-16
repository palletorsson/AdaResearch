extends RefCounted

## dream_bodies / couture_beast — a shop mannequin in a printed gown, wearing an
## animal helmet made of smooth plates.
##
## Reference: FinalMD/m1/0_0306-0000.jpg (4096x1072 panorama). NOTE FOR WHOEVER
## READS THIS NEXT: the brief that commissioned this family described mannequins
## in patterned couture with rabbit, cat and long-beaked golden heads against
## floral wallpaper. The file at that path is a different picture — a black-ground
## reef panorama — and it was opened before a line was written, which is the whole
## reason the discrepancy is recorded here instead of quietly split the difference.
## What is actually in the frame:
##
##   dense sage ribbon-grass swirling edge to edge on near-black; big lilac
##   dichotomous coral trees, flattened and antler-like; white radiating pleated
##   fans with fine dark ribs; ivory ribbon scrolls curling into interlocking
##   loops; a mauve tapering tube quilted in a diamond lattice of tesserae; a
##   mauve tesselated sphere; and — the thing that rescues the brief — several
##   small glossy HEADS on long necks: a pale blue-green one under a golden crest,
##   a cream-and-gold nautilus head with a curling beak, snake heads hooding at the
##   top corners. Palette: black, lilac-mauve, sage-olive, ivory, gold, pale teal.
##
## So the family is the brief's ARGUMENT built out of the panorama's VOCABULARY.
## The argument is fashion, not ritual — masked_dancer is already the ritual
## dancer, batik_beast the soft toy under a muzzle, botanic_mannequin the headless
## shop form. This one is the atelier: a tailor's dress form on a chrome pole,
## a garment that IS the sculpture, and a helmet on top.
##
## Reproduced, and how:
##   1. The dress form — 16 squashed ellipsoids from hip cut to shoulder cut,
##      keyed hip -> waist -> bust -> chest -> shoulder, closed at both ends by a
##      flat oval disc so it reads CUT rather than tapered. That flat cut is the
##      only thing that tells a tailor's bust from a torso.
##   2. The stand — a chrome disc, a stepped ring, a pole and a height collar. A
##      shop fitting, and the reason the hem can stop 20 cm off the floor.
##   3. The print — a 176x176 ImageTexture drawn pixel by pixel and dealt by seed:
##      lilac CORAL dendrites on black, sage GRASS ribbons on black, a mauve SCALE
##      lattice of diamond tesserae in pale grout, or scattered SPRAY blooms with
##      dark contour arcs on ivory. World triplanar, so one cloth runs unbroken
##      across every panel of the gown.
##   4. The helmet — smooth plates: squashed ellipsoids and prism wedges in patent,
##      chrome, holo or pearl over a gold or lilac ground, never a face.
##   5. The pleated fan, three times over — as the epaulette on one shoulder, as
##      the serpent's hood, and as the whole head at head="fan".
##   6. A seed is an individual: print kind, cloth finish, plate finish, palette,
##      bust, hip and waist, stature, the twist of the form on its pole, the head's
##      yaw and tilt, which shoulder carries the epaulette, how many seam beads.
##
## THE ONE MATTE PASSAGE is THE FORM ITSELF — the chain, its two cut discs and its
## seam tapes are chalk-dry unglazed linen, and nothing else on the statue is. The
## gown is latex or patent or oil slick, the helmet is patent or chrome, the stand
## is chrome, the beads are candy or neon. A wet gown only reads wet against the
## dry bust it was fitted on, and at garment="crinoline" — where the cloth is gone
## and only the cage is left — that dry form is most of what you see. The contrast
## IS the axis.
##
## Given up: the wallpaper (a statue has no ground), the reference's crowd, the
## grass ribbons as real geometry everywhere rather than print plus one garment,
## the ivory scroll's true interlocking loops (three rolled toruses stand in for
## it), and any face at all — an animal helmet with eyes painted on stops being
## couture and starts being a costume.
##
## AXES — two, and both cut the object, not the settings:
##   head    — the animal on the shoulders. "hare" is two long tapered ear plates
##             over a narrow skull; "cat" a round skull with wedge ears and rod
##             whiskers; "beak" the golden-crested prow, a 30 cm cone and a five-
##             plate crest fin; "serpent" a flat wedge head carried forward on a
##             five-joint S neck under a spread seven-plate hood; "fan" has no
##             animal at all — the head is a radiating pleated shell, a couture
##             headdress on a bare neck; "antler" is a small skull under a coral
##             crown grown by the same dichotomous branch that grows the gown.
##   garment — what hangs on the form. "sheath" is the printed column of the
##             reference's quilted tube read as cloth; "crinoline" takes the cloth
##             away entirely and leaves six hoops and twelve staves, so the dry
##             form stands naked inside its own cage; "quilted" rebuilds the column
##             out of ninety-nine raised diamond tesserae standing 12 mm proud;
##             "bloom" bursts the skirt into six branching lilac coral arms;
##             "fringe" dissolves it into forty-six hanging ribbon-grass strands.
##
## WHY BOTH AXES SURVIVE A STILL. Neither changes a rate or a duration. Every head
## value changes the silhouette above the shoulder line and every garment value
## changes the silhouette below the waist, and the two zones do not overlap, so the
## sweep's thirty frames are six helmets x five gowns and the critic can read
## either axis without the other confounding it.

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const TEX: int = 176

# the statue's own frame, before the measured settle at the end
const BASE_H: float = 0.045
const POLE_TOP: float = 0.72
const HIP_Y: float = 0.70
const SH_Y: float = 1.26
const NECK_Y: float = 1.35
const HEAD_Y: float = 1.45
const HEM_Y: float = 0.20

const K_CORAL: int = 0
const K_GRASS: int = 1
const K_SCALE: int = 2
const K_SPRAY: int = 3

# what a gown may be cut in — never "matte", because the form owns dry
const CLOTH_FIN: Array[String] = ["latex", "patent", "candy", "wet", "pearl", "holo",
	"oilslick"]
# what a helmet plate is: hard, smooth, reflective. No latex — a plate is not skin.
const PLATE_FIN: Array[String] = ["patent", "chrome", "holo", "pearl", "candy"]
# small marks only, so neon is allowed in the deck without eating the frame
const MARK_FIN: Array[String] = ["patent", "candy", "neon", "wet", "latex"]

# straight off the panorama: mauve, sage, ivory, gold, teal, plum
const REEF: Array = [
	"#B487CE", "#8E6BB0", "#C9A9DC", "#6E8455", "#A8B87A", "#EDE2C8", "#C9A227",
	"#5FAEBE", "#3B1F3A",
]
const I_LILAC: int = 0
const I_MAUVE: int = 1
const I_PALE: int = 2
const I_SAGE: int = 3
const I_MOSS: int = 4
const I_IVORY: int = 5
const I_GOLD: int = 6
const I_TEAL: int = 7
const I_PLUM: int = 8


static func describe() -> String:
	return "A tailor's dress form on a chrome pole in a code-printed gown of coral, grass, tesserae or scattered blooms, under a smooth-plated animal helmet — hare, cat, long-beaked crest, hooded serpent, pleated fan or coral antler."


static func axes() -> Dictionary:
	return {
		"head": ["hare", "cat", "beak", "serpent", "fan", "antler"],
		"garment": ["sheath", "crinoline", "quilted", "bloom", "fringe"],
	}


## The prediction, named BEFORE the capture and carried into the registry by
## tools/dream_bodies_promote.py, so nobody retypes a number into JSON.
##
## THE CLOSEST PAIR IS head: hare vs cat, at garment="quilted". Both are the same
## mammal skull on the same neck with the same short muzzle and the same two eyes;
## the whole difference is what stands on top of it. And quilted is the loudest
## gown — ninety-nine raised tesserae over the full column — so it fills the frame
## and dilutes anything happening at the head.
##
## THE ARITHMETIC. What changes between the two frames, in square metres of
## silhouette:
##
##   hare ears:  2 x (0.29 m along the ear x ~0.075 m mean width x 0.72 fill) = 0.0313
##   cat ears:   2 x (0.078 x 0.125 prism, half of the box)                   = 0.0098
##   whiskers:   4 rods, 0.11 m x 0.007 m                                     = 0.0031
##   skull and muzzle: hare's is narrower and longer than cat's                = 0.0040
##   overlap just above the skull, where both ear sets sit, counted once      = -0.0060
##   changed silhouette area                                                  ~ 0.042 m^2
##
##   this statue's own silhouette: 1.68 m x ~0.32 m mean width x ~0.62 fill   ~ 0.333 m^2
##   so the change is 12.6% of the BODY.
##
## AND NOW THE DENOMINATOR, which is the step that has cost this corpus a whole
## reading before. fetish_idol quoted 3.4% of the SILHOUETTE as if it were 3.4% of
## the picture and over-predicted by 2.2x; the measurement that came back —
## 0.98% of frame for 3.4% of silhouette — is the only CALIBRATION the corpus owns,
## and it says a 1.68 x 0.78 m body is about 29% of a sweep frame. This statue is a
## narrow column, 0.50 m across at garment="quilted", so its silhouette is
## 0.333 / 0.573 = 58% of that one's, and its share of the frame is ~17%.
##
##   12.6% of the body x 17% of the frame = ~2.1%, called at 2.0%.
##
## IT IS A FLOOR, NOT A FORECAST. Two things push the real render above it and
## neither is in the arithmetic: the ear plates are patent, chrome or holo and
## throw specular highlights a flat area estimate cannot see at all, and the settle
## scales the statue to fit 1.68 m — hare stands ~1.80 m natural against cat's
## ~1.63, so the hare frame is uniformly ~7% smaller and every pixel of the gown
## moves with it. If the sweep comes back UNDER 2.0%, stop: the capture is broken,
## not the axis.
static func predicted() -> Dictionary:
	return {
		"pair": "head: hare vs cat, at garment=quilted",
		"predicted_pct": 2.0,
		"reasoning": ("the two mammal helmets share the grammar — one skull, one muzzle, two "
			+ "eyes, two ears — so only the ears really move: hare's two 0.29 m tapered "
			+ "plates against cat's 0.125 m wedges plus four whiskers, with a small skull "
			+ "and muzzle difference, is ~0.042 m^2 of changed silhouette on a ~0.333 m^2 "
			+ "body, or 12.6% of the body. The body's share of frame is calibrated off the "
			+ "corpus's one measured case (fetish_idol: 3.4% of silhouette read 0.98% of "
			+ "frame, so a 0.78 m-wide body is ~29% of frame) scaled by area for this "
			+ "narrower 0.50 m column: ~17%. 12.6% x 17% = ~2.0% of the picture. A LOWER "
			+ "bound — the plates are specular, and the 1.68 m fit rescales the hare frame "
			+ "~7% smaller, which moves the gown too"),
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	# str(), never String(): a map token is JSON and String() THROWS on a
	# Dictionary or Array cell, where str() falls through to the default below.
	var head: String = str(opts.get("head", "hare"))
	var garment: String = str(opts.get("garment", "sheath"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- who this one is ------------------------------------------------------
	var bust: float = rng.randf_range(0.90, 1.14)
	var hipw: float = rng.randf_range(0.92, 1.16)
	var waist: float = rng.randf_range(0.78, 0.98)
	var stature: float = rng.randf_range(0.96, 1.05)
	var turn: float = deg_to_rad(rng.randf_range(-24.0, 24.0))
	var lean: float = deg_to_rad(rng.randf_range(-5.0, 5.0))
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var head_yaw: float = deg_to_rad(rng.randf_range(-30.0, 30.0))
	var head_tilt: float = deg_to_rad(rng.randf_range(-9.0, 9.0))
	var print_k: int = rng.randi_range(0, 3)
	var beads: int = rng.randi_range(6, 10)

	# --- the wardrobe, dealt ---------------------------------------------------
	var lilac: Color = Color(str(REEF[I_LILAC])).lerp(Color(str(REEF[I_PALE])), rng.randf())
	var gold: Color = Color(str(REEF[I_GOLD]))
	var ivory: Color = Color(str(REEF[I_IVORY]))
	var sage: Color = Color(str(REEF[I_SAGE])).lerp(Color(str(REEF[I_MOSS])), rng.randf())
	var teal: Color = Color(str(REEF[I_TEAL]))
	var plum: Color = Color(str(REEF[I_PLUM]))

	var cloth_fin: String = CLOTH_FIN[rng.randi_range(0, CLOTH_FIN.size() - 1)]
	var plate_fin: String = PLATE_FIN[rng.randi_range(0, PLATE_FIN.size() - 1)]
	var cloth_col: Color = lilac
	if rng.randf() < 0.34:
		cloth_col = Gloss.queer_colour(rng)
	var plate_col: Color = gold if rng.randf() < 0.5 else lilac.lerp(teal, rng.randf_range(0.2, 0.8))
	var trim_col: Color = ivory if rng.randf() < 0.55 else gold

	var pal: Array = []
	for i in range(REEF.size()):
		pal.append(Color(str(REEF[i])))
	pal.append(Gloss.queer_colour(rng))
	pal.append(Gloss.queer_colour(rng))
	var ink: Color = Color(0.055, 0.050, 0.062)

	var tex: ImageTexture = _make_tex(print_k, rng, pal, ink, lilac, sage, ivory, gold)
	var mat_cloth: StandardMaterial3D = _dress(cloth_fin, cloth_col, tex, _tex_uv(print_k), rng)
	var mat_plate: StandardMaterial3D = Gloss.skin(plate_fin, plate_col, rng)
	mat_plate.metallic = minf(mat_plate.metallic, 0.72)
	var mat_trim: StandardMaterial3D = Gloss.skin("patent", trim_col, rng)
	var mat_dark: StandardMaterial3D = Gloss.skin("patent", plum, rng)
	var mat_steel: StandardMaterial3D = Gloss.skin("chrome", Color(0.72, 0.74, 0.80), rng)
	var mat_bead: StandardMaterial3D = _mark_mat(pal[rng.randi_range(0, pal.size() - 1)], rng)
	var mat_leaf: StandardMaterial3D = Gloss.skin("wet", sage, rng)
	# THE ONE DRY PASSAGE. Everything else on this statue is wet, plated or
	# chromed; the bust it was all fitted on is unglazed linen over plaster.
	var mat_form: StandardMaterial3D = Gloss.skin("matte", ivory.lerp(Color(0.88, 0.85, 0.79), 0.5))
	var mat_tape: StandardMaterial3D = Gloss.skin("matte", Color(0.24, 0.22, 0.24))

	# --- the stand: a shop fitting, and the reason the hem clears the floor ----
	_disc(root, mat_steel, Vector3(0.0, BASE_H * 0.5, 0.0), Vector3.UP, 0.255, BASE_H)
	_disc(root, mat_steel, Vector3(0.0, BASE_H + 0.020, 0.0), Vector3.UP, 0.130, 0.040)
	_rod(root, mat_steel, Vector3(0.0, BASE_H, 0.0), Vector3(0.0, POLE_TOP, 0.0), 0.019)
	_disc(root, mat_dark, Vector3(0.0, POLE_TOP - 0.085, 0.0), Vector3.UP, 0.036, 0.028)

	# --- the dress form -------------------------------------------------------
	var n_seg: int = 16
	var rx_keys: Array = [0.212 * hipw, 0.196 * hipw, 0.150 * waist, 0.176, 0.208 * bust, 0.186, 0.156]
	var rz_keys: Array = [0.158 * hipw, 0.146 * hipw, 0.116 * waist, 0.140, 0.164 * bust, 0.146, 0.124]
	var t_c: Array[Vector3] = []
	var t_b: Array[Basis] = []
	var t_rx: Array[float] = []
	var t_rz: Array[float] = []
	for i in range(n_seg):
		var t: float = float(i) / float(n_seg - 1)
		var yq: float = lerpf(HIP_Y, SH_Y, t)
		# the form turned on its own pole, and tipped a few degrees — a mannequin
		# is POSED by hand, and this is the seed's signature in the fingerprint
		var bs: Basis = Basis(Vector3.UP, turn * t) * Basis(Vector3.BACK, lean * t)
		t_c.append(Vector3(0.0, yq, sin(t * PI) * 0.012))
		t_b.append(bs)
		t_rx.append(_key(rx_keys, t))
		t_rz.append(_key(rz_keys, t))
		_ellipsoid(root, mat_form, t_c[i], Vector3(t_rx[i], 0.030, t_rz[i]), bs)

	# the two flat cuts. Without these it is a torso; with them it is a bust on a
	# stand, which is the entire read of the object.
	_disc(root, mat_form, Vector3(0.0, HIP_Y - 0.004, t_c[0].z), Vector3.UP, t_rx[0] * 0.99, 0.016)
	_disc(root, mat_form, t_c[n_seg - 1] + Vector3(0.0, 0.006, 0.0), Vector3.UP,
		t_rx[n_seg - 1] * 0.99, 0.016)

	# the seam tapes — dry, like the form, because they are part of it
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		for j in range(4):
			var tj: float = 0.16 + 0.24 * float(j)
			var idx: int = clampi(int(round(tj * float(n_seg - 1))), 0, n_seg - 1)
			var ang: float = sd * 0.62
			var pp: Vector3 = t_c[idx] + t_b[idx] * Vector3(t_rx[idx] * sin(ang), 0.0,
				-t_rz[idx] * cos(ang))
			_ellipsoid(root, mat_tape, pp, Vector3(0.013, 0.048, 0.013), t_b[idx], 8, 5)

	# --- the garment ----------------------------------------------------------
	var g_top: float = 1.16
	var g_ctx := {
		"cloth": mat_cloth,
		"trim": mat_trim,
		"plate": mat_plate,
		"leaf": mat_leaf,
		"bead": mat_bead,
		"steel": mat_steel,
		"hipw": hipw,
		"bust": bust,
		"waist": waist,
		"top": g_top,
		"turn": turn,
	}
	match garment:
		"crinoline":
			_g_crinoline(root, g_ctx, rng)
		"quilted":
			_g_quilted(root, g_ctx, rng)
		"bloom":
			_g_bloom(root, g_ctx, lilac, rng)
		"fringe":
			_g_fringe(root, g_ctx, sage, rng)
		_:
			_g_sheath(root, g_ctx, rng)

	# --- the neck and the helmet ---------------------------------------------
	var neck_b: Basis = Basis(Vector3.UP, turn) * Basis(Vector3.BACK, lean)
	var neck_c: Vector3 = Vector3(0.0, NECK_Y, t_c[n_seg - 1].z)
	# the plate collar — the helmet's own gorget, so the join never shows a gap
	_disc(root, mat_plate, neck_c + Vector3(0.0, -0.060, 0.0), Vector3.UP, 0.095, 0.024)
	_ellipsoid(root, mat_plate, neck_c, Vector3(0.056, 0.052, 0.052), neck_b)

	var hb: Basis = Basis(Vector3.UP, turn + head_yaw) * Basis(Vector3.RIGHT, head_tilt)
	var hc: Vector3 = Vector3(0.0, HEAD_Y, t_c[n_seg - 1].z) + hb * Vector3(0.0, 0.052, -0.014)
	var h_ctx := {
		"plate": mat_plate,
		"trim": mat_trim,
		"dark": mat_dark,
		"bead": mat_bead,
		"cloth": mat_cloth,
	}
	match head:
		"cat":
			_h_cat(root, h_ctx, hc, hb, rng)
		"beak":
			_h_beak(root, h_ctx, hc, hb, gold, rng)
		"serpent":
			_h_serpent(root, h_ctx, hc, hb, rng)
		"fan":
			_h_fan(root, h_ctx, hc, hb, rng)
		"antler":
			_h_antler(root, h_ctx, hc, hb, lilac, rng)
		_:
			_h_hare(root, h_ctx, hc, hb, rng)

	# --- trim that is always there, on every one of the thirty frames ---------
	# the pleated fan again, this time as an epaulette — the reference's white
	# radiating shell, worn on one shoulder
	var ep_c: Vector3 = t_c[n_seg - 1] + t_b[n_seg - 1] * Vector3(side * t_rx[n_seg - 1] * 0.86,
		0.010, 0.0)
	var ep_b: Basis = t_b[n_seg - 1] * Basis(Vector3.BACK, -side * 1.02)
	_fan(root, mat_trim, mat_plate, ep_c, ep_b, 7, 0.185, 1.05, 0.012, rng)

	# the ivory scroll, rolled at the hip
	for k in range(3):
		var sc: float = 0.062 - 0.011 * float(k)
		_hoop(root, mat_trim, t_c[2] + t_b[2] * Vector3(-side * (t_rx[2] * 0.78 + 0.02),
			0.018 * float(k), -t_rz[2] * 0.42), sc, 0.55,
			t_b[2] * Basis(Vector3.RIGHT, 1.35 + 0.20 * float(k)))

	# the seam beads down the front — the panorama's tesselated sphere, shrunk
	for k in range(beads):
		var tk: float = 0.10 + 0.78 * float(k) / float(maxi(beads - 1, 1))
		var ik: int = clampi(int(round(tk * float(n_seg - 1))), 0, n_seg - 1)
		var br: float = rng.randf_range(0.016, 0.026)
		_ellipsoid(root, mat_bead, t_c[ik] + t_b[ik] * Vector3(0.0, 0.0, -t_rz[ik] - br * 0.35),
			Vector3(br, br, br * 0.82), t_b[ik], 12, 7)

	# --- stature, then the measured settle ------------------------------------
	_rescale(root, stature, Vector3.ZERO)

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
	box = _union_aabb(root)
	if box.position.y < 0.0:
		_shift(root, Vector3(0.0, -box.position.y, 0.0))


# ---------------------------------------------------------------------------
# the garment axis — five different objects hanging on one form

## The printed column. The reference's quilted tube, read as cloth rather than
## armour: it hugs the form to the knee and flares a little at the hem.
static func _g_sheath(root: Node3D, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var cloth: StandardMaterial3D = ctx["cloth"]
	var trim: StandardMaterial3D = ctx["trim"]
	var hipw: float = float(ctx["hipw"])
	var top: float = float(ctx["top"])
	var turn: float = float(ctx["turn"])
	var keys_x: Array = [0.196, 0.160, 0.224 * hipw, 0.206, 0.190, 0.214]
	var keys_z: Array = [0.152, 0.124, 0.170 * hipw, 0.158, 0.148, 0.170]
	var n: int = 22
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var yq: float = lerpf(top, HEM_Y, t)
		var bs: Basis = Basis(Vector3.UP, turn * (1.0 - t) * 0.8)
		_ellipsoid(root, cloth, Vector3(0.0, yq, 0.0),
			Vector3(_key(keys_x, t) * rng.randf_range(0.99, 1.02), 0.038,
				_key(keys_z, t) * rng.randf_range(0.99, 1.02)), bs)
	_hoop(root, trim, Vector3(0.0, top - 0.150, 0.0), 0.172, 0.86, Basis())


## The cloth taken away. Six hoops and twelve staves, and the dry form standing
## naked inside them — which is the argument the matte passage exists to make.
static func _g_crinoline(root: Node3D, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var steel: StandardMaterial3D = ctx["steel"]
	var trim: StandardMaterial3D = ctx["trim"]
	var hipw: float = float(ctx["hipw"])
	var top: float = float(ctx["top"]) - 0.14
	var hoops: int = 6
	var rads: Array[float] = []
	var ys: Array[float] = []
	for i in range(hoops):
		var t: float = float(i) / float(hoops - 1)
		ys.append(lerpf(top, HEM_Y + 0.04, t))
		# a bell: narrow at the waist, widest two thirds down, drawn back at the hem
		rads.append(lerpf(0.165 * hipw, 0.345 * hipw, sin(t * 2.1) / sin(2.1)))
		_hoop(root, trim if i % 2 == 0 else steel, Vector3(0.0, ys[i], 0.0), rads[i], 0.90,
			Basis())
	var staves: int = 12
	for s in range(staves):
		var a: float = TAU * float(s) / float(staves) + rng.randf_range(-0.03, 0.03)
		var mid: int = hoops / 2
		var p0 := Vector3(sin(a) * rads[0], ys[0], cos(a) * rads[0])
		var p1 := Vector3(sin(a) * rads[mid], ys[mid], cos(a) * rads[mid])
		var p2 := Vector3(sin(a) * rads[hoops - 1], ys[hoops - 1], cos(a) * rads[hoops - 1])
		_rod(root, steel, p0, p1, 0.0075)
		_rod(root, steel, p1, p2, 0.0075)
	_hoop(root, trim, Vector3(0.0, top + 0.055, 0.0), 0.172, 0.86, Basis())


## The same column rebuilt out of ninety-nine tesserae standing 12 mm proud — the
## panorama's diamond-quilted tube, as armour rather than print.
static func _g_quilted(root: Node3D, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var cloth: StandardMaterial3D = ctx["cloth"]
	var plate: StandardMaterial3D = ctx["plate"]
	var trim: StandardMaterial3D = ctx["trim"]
	var hipw: float = float(ctx["hipw"])
	var top: float = float(ctx["top"])
	var keys_x: Array = [0.186, 0.152, 0.214 * hipw, 0.198, 0.184, 0.206]
	var keys_z: Array = [0.144, 0.118, 0.162 * hipw, 0.152, 0.142, 0.164]
	# the cloth underneath, so the gaps between tesserae are dark and not sky
	var under: int = 10
	for i in range(under):
		var t: float = float(i) / float(under - 1)
		_ellipsoid(root, cloth, Vector3(0.0, lerpf(top, HEM_Y, t), 0.0),
			Vector3(_key(keys_x, t) * 0.97, 0.062, _key(keys_z, t) * 0.97), Basis())
	var rows: int = 11
	var cols: int = 9
	for r in range(rows):
		var t: float = float(r) / float(rows - 1)
		var yq: float = lerpf(top - 0.01, HEM_Y + 0.01, t)
		var rx: float = _key(keys_x, t)
		var rz: float = _key(keys_z, t)
		for c in range(cols):
			# every other row offset half a cell — a real quilt lattice, not a grid
			var a: float = TAU * (float(c) + (0.5 if r % 2 == 1 else 0.0)) / float(cols)
			var loc := Vector3(sin(a) * rx, 0.0, cos(a) * rz)
			var nrm: Vector3 = Vector3(sin(a) / rx, 0.0, cos(a) / rz).normalized()
			var sz: float = lerpf(0.052, 0.044, t)
			var m: StandardMaterial3D = plate if (r + c) % 3 == 0 else cloth
			_ellipsoid(root, m, Vector3(0.0, yq, 0.0) + loc + nrm * 0.012,
				Vector3(sz, sz * 0.72, sz * 0.46), _basis_z_to(nrm) * Basis(Vector3.BACK, PI * 0.25),
				12, 7)
	_hoop(root, trim, Vector3(0.0, top - 0.150, 0.0), 0.170, 0.86, Basis())
	# a seed still has to move this gown, and the lattice above is deterministic
	_ellipsoid(root, trim, Vector3(rng.randf_range(-0.02, 0.02), top + 0.02,
		-_key(keys_z, 0.0) - 0.02), Vector3(0.030, 0.030, 0.022), Basis(), 12, 7)


## The skirt bursts. Six lilac coral arms, dichotomous, grown by the same branch
## that grows the antler crown — the panorama's flattened trees.
static func _g_bloom(root: Node3D, ctx: Dictionary, lilac: Color,
		rng: RandomNumberGenerator) -> void:
	var cloth: StandardMaterial3D = ctx["cloth"]
	var trim: StandardMaterial3D = ctx["trim"]
	var hipw: float = float(ctx["hipw"])
	var top: float = float(ctx["top"])
	var coral: StandardMaterial3D = Gloss.skin("pearl", lilac, rng)
	var bud: StandardMaterial3D = _mark_mat(lilac.lerp(Color(str(REEF[I_PALE])), 0.6), rng)
	# a short bodice, so the burst has something to burst OUT of
	var bod: int = 8
	for i in range(bod):
		var t: float = float(i) / float(bod - 1)
		_ellipsoid(root, cloth, Vector3(0.0, lerpf(top, HIP_Y - 0.06, t), 0.0),
			Vector3(lerpf(0.184, 0.216 * hipw, t), 0.048, lerpf(0.142, 0.166 * hipw, t)),
			Basis())
	var roots: int = 6
	for s in range(roots):
		var a: float = TAU * float(s) / float(roots) + rng.randf_range(-0.18, 0.18)
		var p0 := Vector3(sin(a) * 0.135 * hipw, HIP_Y - 0.09, cos(a) * 0.106 * hipw)
		# MOSTLY DOWN, NOT MOSTLY OUT, and it was the other way round first. At
		# (0.72, -0.62, 0.72) the worst-case radial reach is 0.68 m — a 1.36 m spread
		# against the family's 1.20 m width cap, so the settle scaled the whole statue
		# to 0.86 and bloom stood 1.44 m where its five siblings stand 1.68. That is a
		# height axis nobody declared, and it would have inflated every bloom-vs-other
		# pair in the sweep with pixels that have nothing to do with the garment.
		var dir: Vector3 = Vector3(sin(a) * 0.58, -0.86, cos(a) * 0.58).normalized()
		_branch(root, coral, bud, p0, dir, rng.randf_range(0.17, 0.22), 0.030, 2, rng)
	_hoop(root, trim, Vector3(0.0, top - 0.140, 0.0), 0.172, 0.86, Basis())


## The gown dissolves into the panorama's ribbon grass: forty-six strands hanging
## from the waistband, each with a kink in it so the fall is not a curtain.
static func _g_fringe(root: Node3D, ctx: Dictionary, sage: Color,
		rng: RandomNumberGenerator) -> void:
	var cloth: StandardMaterial3D = ctx["cloth"]
	var trim: StandardMaterial3D = ctx["trim"]
	var leaf: StandardMaterial3D = ctx["leaf"]
	var hipw: float = float(ctx["hipw"])
	var top: float = float(ctx["top"])
	var n: int = 46
	for i in range(n):
		var a: float = TAU * float(i) / float(n) + rng.randf_range(-0.05, 0.05)
		var rr: float = 0.170 * hipw * rng.randf_range(0.94, 1.06)
		var y0: float = top - 0.12 + rng.randf_range(-0.03, 0.03)
		var p0 := Vector3(sin(a) * rr, y0, cos(a) * rr)
		# same cap, same reason as the bloom skirt: swing 0.32 put the outermost
		# strand at 0.61 m and the whole statue got scaled down to fit
		var swing: float = rng.randf_range(0.08, 0.24)
		var drop: float = rng.randf_range(0.34, 0.56)
		var p1 := p0 + Vector3(sin(a) * swing * 0.55, -drop * 0.62, cos(a) * swing * 0.55)
		var p2 := p1 + Vector3(sin(a + rng.randf_range(-0.8, 0.8)) * swing * 0.75,
			-drop * 0.55, cos(a + rng.randf_range(-0.8, 0.8)) * swing * 0.75)
		# the lowest strand must not spear the floor: the settle lifts to y=0, so a
		# strand below the base disc drags the whole statue up and hangs the hem
		p2.y = maxf(p2.y, 0.055)
		var m: StandardMaterial3D = leaf if i % 3 != 0 else cloth
		_rod(root, m, p0, p1, 0.010)
		_rod(root, m, p1, p2, 0.007)
	_hoop(root, trim, Vector3(0.0, top - 0.10, 0.0), 0.176, 0.86, Basis())


# ---------------------------------------------------------------------------
# the head axis — six helmets of smooth plates, and never a face

static func _h_hare(root: Node3D, ctx: Dictionary, c: Vector3, b: Basis,
		rng: RandomNumberGenerator) -> void:
	var plate: StandardMaterial3D = ctx["plate"]
	var trim: StandardMaterial3D = ctx["trim"]
	var dark: StandardMaterial3D = ctx["dark"]
	_ellipsoid(root, plate, c, Vector3(0.094, 0.112, 0.126), b)
	_ellipsoid(root, plate, c + b * Vector3(0.0, -0.036, -0.104), Vector3(0.058, 0.052, 0.066), b)
	_ellipsoid(root, dark, c + b * Vector3(0.0, -0.030, -0.158), Vector3(0.024, 0.020, 0.018), b)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var dir: Vector3 = (b * Vector3(sd * 0.30, 1.0, -0.16)).normalized()
		var base: Vector3 = c + b * Vector3(sd * 0.046, 0.084, 0.006)
		var eb: Basis = _basis_y_to(dir) * Basis(Vector3.UP, sd * 0.30)
		# three plates up the ear, each thinner than the last — a plate ear, not a
		# tube: the flat face is what catches the light in a still
		# 0.215, NOT 0.245, AND THE 3 CM IS THE PREDICTION'S DOING. The settle scales
		# the statue to fit 1.68 m, so an ear that overshoots shrinks the WHOLE body:
		# at 0.245 the hare stood 1.83 m natural against the cat's 1.63 and every
		# pixel of the gown moved between the two, which would have inflated the
		# family's own closest pair with a height difference nobody declared.
		for k in range(3):
			var u: float = float(k) / 2.0
			var pos: Vector3 = base + dir * lerpf(0.075, 0.215, u)
			var w: float = lerpf(0.052, 0.030, u)
			_ellipsoid(root, plate, pos, Vector3(w, lerpf(0.086, 0.062, u), w * 0.42), eb)
		_ellipsoid(root, trim, base + dir * 0.140 + (b * Vector3(0.0, 0.0, -0.020)),
			Vector3(0.026, 0.086, 0.012), eb, 12, 7)
	for s_i in range(2):
		var sd2: float = -1.0 if s_i == 0 else 1.0
		_ellipsoid(root, dark, c + b * Vector3(sd2 * 0.080, 0.014, -0.072),
			Vector3(0.020, 0.026, 0.014), b, 12, 7)


static func _h_cat(root: Node3D, ctx: Dictionary, c: Vector3, b: Basis,
		rng: RandomNumberGenerator) -> void:
	var plate: StandardMaterial3D = ctx["plate"]
	var trim: StandardMaterial3D = ctx["trim"]
	var dark: StandardMaterial3D = ctx["dark"]
	_ellipsoid(root, plate, c, Vector3(0.112, 0.106, 0.108), b)
	_ellipsoid(root, plate, c + b * Vector3(0.0, -0.034, -0.086), Vector3(0.072, 0.048, 0.052), b)
	_ellipsoid(root, dark, c + b * Vector3(0.0, -0.024, -0.126), Vector3(0.020, 0.016, 0.014), b)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		var eb: Basis = b * Basis(Vector3.BACK, -sd * 0.34) * Basis(Vector3.RIGHT, -0.20)
		# and the cat's ears were raised to meet the hare's trim halfway, for the same
		# reason: the closest pair has to differ by its EARS, not by its stature
		_wedge(root, plate, c + b * Vector3(sd * 0.062, 0.116, 0.010),
			Vector3(0.078, 0.125, 0.026), eb)
		_wedge(root, trim, c + b * Vector3(sd * 0.060, 0.110, -0.008),
			Vector3(0.046, 0.084, 0.014), eb)
	for s_i in range(2):
		var sd2: float = -1.0 if s_i == 0 else 1.0
		_ellipsoid(root, dark, c + b * Vector3(sd2 * 0.058, 0.012, -0.088),
			Vector3(0.024, 0.019, 0.012), b, 12, 7)
	# four whiskers, thin rods — cheap, and they are half of what says "cat"
	for k in range(4):
		var sd3: float = -1.0 if k < 2 else 1.0
		var ky: float = -0.028 + 0.026 * float(k % 2)
		var a0: Vector3 = c + b * Vector3(sd3 * 0.030, ky, -0.108)
		_rod(root, dark, a0, a0 + b * Vector3(sd3 * 0.100, 0.024 * float(k % 2), -0.048), 0.0035)


static func _h_beak(root: Node3D, ctx: Dictionary, c: Vector3, b: Basis, gold: Color,
		rng: RandomNumberGenerator) -> void:
	var plate: StandardMaterial3D = ctx["plate"]
	var dark: StandardMaterial3D = ctx["dark"]
	var crest_m: StandardMaterial3D = Gloss.skin("chrome", gold, rng)
	_ellipsoid(root, plate, c, Vector3(0.098, 0.104, 0.114), b)
	# the prow: 30 cm of cone, the single loudest silhouette in the family
	var tip: Vector3 = c + b * Vector3(0.0, -0.062, -0.330)
	_cone(root, plate, c + b * Vector3(0.0, -0.014, -0.066), tip, 0.062, 0.005)
	_cone(root, dark, c + b * Vector3(0.0, -0.044, -0.070), tip + b * Vector3(0.0, 0.010, 0.020),
		0.038, 0.004)
	# a five-plate crest fin along the top midline, rising then falling
	for k in range(5):
		var u: float = float(k) / 4.0
		var hgt: float = 0.052 * sin(PI * clampf(u * 0.86 + 0.14, 0.0, 1.0))
		var pos: Vector3 = c + b * Vector3(0.0, 0.098 + hgt * 0.5, lerpf(0.062, -0.098, u))
		_wedge(root, crest_m, pos, Vector3(0.020, 0.028 + hgt, 0.070), b)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		_ellipsoid(root, crest_m, c + b * Vector3(sd * 0.086, 0.010, -0.030),
			Vector3(0.036, 0.060, 0.048), b * Basis(Vector3.BACK, -sd * 0.24), 14, 8)
		_ellipsoid(root, dark, c + b * Vector3(sd * 0.082, 0.030, -0.086),
			Vector3(0.020, 0.024, 0.012), b, 12, 7)


static func _h_serpent(root: Node3D, ctx: Dictionary, c: Vector3, b: Basis,
		rng: RandomNumberGenerator) -> void:
	var plate: StandardMaterial3D = ctx["plate"]
	var trim: StandardMaterial3D = ctx["trim"]
	var dark: StandardMaterial3D = ctx["dark"]
	# five joints of S neck, carrying the head forward and up off the shoulders
	var pts: Array[Vector3] = []
	for k in range(5):
		var u: float = float(k) / 4.0
		var fwd: float = -0.020 - 0.150 * sin(u * PI * 0.86)
		pts.append(c + b * Vector3(0.0, -0.070 + 0.170 * u, fwd))
		_ellipsoid(root, plate, pts[k], Vector3(0.052 - 0.008 * u, 0.046, 0.052 - 0.008 * u), b)
	var hd: Vector3 = pts[4] + b * Vector3(0.0, 0.046, -0.062)
	var hbb: Basis = b * Basis(Vector3.RIGHT, 0.34)
	_ellipsoid(root, plate, hd, Vector3(0.082, 0.044, 0.126), hbb)
	_ellipsoid(root, trim, hd + hbb * Vector3(0.0, 0.028, 0.018), Vector3(0.056, 0.022, 0.070),
		hbb, 14, 8)
	# the hood, spread behind the head — the panorama's hooded snakes, and the
	# third appearance of the pleated fan
	_fan(root, trim, plate, pts[3] + b * Vector3(0.0, 0.030, 0.030),
		b * Basis(Vector3.RIGHT, -0.50), 7, 0.195, 1.15, 0.011, rng)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		_ellipsoid(root, dark, hd + hbb * Vector3(sd * 0.052, 0.016, -0.060),
			Vector3(0.020, 0.016, 0.014), hbb, 12, 7)


## No animal at all. The head IS the reference's radiating pleated shell, worn as
## a headdress on a bare plated neck — the value that argues couture over costume.
static func _h_fan(root: Node3D, ctx: Dictionary, c: Vector3, b: Basis,
		rng: RandomNumberGenerator) -> void:
	var plate: StandardMaterial3D = ctx["plate"]
	var trim: StandardMaterial3D = ctx["trim"]
	var bead: StandardMaterial3D = ctx["bead"]
	var boss: Vector3 = c + b * Vector3(0.0, -0.070, 0.0)
	_ellipsoid(root, plate, boss, Vector3(0.070, 0.058, 0.062), b)
	_fan(root, trim, plate, boss + b * Vector3(0.0, 0.030, 0.0),
		b * Basis(Vector3.RIGHT, -0.22), 13, 0.300, 1.34, 0.013, rng)
	# four beads along the rim, so the fan has a finished edge and not a cut one
	for k in range(4):
		var a: float = lerpf(-1.20, 1.20, float(k) / 3.0)
		var dir: Vector3 = (b * Basis(Vector3.RIGHT, -0.22)) * (Basis(Vector3.FORWARD, a) * Vector3.UP)
		_ellipsoid(root, bead, boss + b * Vector3(0.0, 0.030, 0.0) + dir * 0.300,
			Vector3(0.022, 0.022, 0.018), b, 12, 7)


static func _h_antler(root: Node3D, ctx: Dictionary, c: Vector3, b: Basis, lilac: Color,
		rng: RandomNumberGenerator) -> void:
	var plate: StandardMaterial3D = ctx["plate"]
	var dark: StandardMaterial3D = ctx["dark"]
	var coral: StandardMaterial3D = Gloss.skin("pearl", lilac, rng)
	var bud: StandardMaterial3D = _mark_mat(lilac.lerp(Color(str(REEF[I_PALE])), 0.6), rng)
	_ellipsoid(root, plate, c, Vector3(0.088, 0.098, 0.112), b)
	_ellipsoid(root, plate, c + b * Vector3(0.0, -0.036, -0.094), Vector3(0.056, 0.046, 0.058), b)
	for s_i in range(2):
		var sd: float = -1.0 if s_i == 0 else 1.0
		_ellipsoid(root, dark, c + b * Vector3(sd * 0.070, 0.012, -0.070),
			Vector3(0.020, 0.024, 0.013), b, 12, 7)
	# three roots, dichotomous twice — the same growth as the bloom skirt, worn
	# as a crown, so the statue rhymes with itself across the two axes
	for s in range(3):
		var a: float = TAU * float(s) / 3.0 + rng.randf_range(-0.25, 0.25)
		var base: Vector3 = c + b * Vector3(sin(a) * 0.052, 0.086, cos(a) * 0.052)
		_ellipsoid(root, plate, base, Vector3(0.028, 0.020, 0.028), b, 12, 7)
		var dir: Vector3 = (b * Vector3(sin(a) * 0.44, 1.0, cos(a) * 0.44)).normalized()
		_branch(root, coral, bud, base, dir, rng.randf_range(0.085, 0.115), 0.017, 2, rng)


# ---------------------------------------------------------------------------
# shape helpers shared by both axes

## The pleated fan: n tapered plates radiating in the b frame's own XY plane, each
## staggered a little fore or aft so the pleats catch different light. Used three
## times — epaulette, serpent hood, and the whole head at head="fan".
static func _fan(root: Node3D, mat: StandardMaterial3D, edge: StandardMaterial3D, c: Vector3,
		b: Basis, n: int, r: float, spread: float, th: float,
		rng: RandomNumberGenerator) -> void:
	for i in range(n):
		var t: float = float(i) / float(maxi(n - 1, 1))
		var a: float = lerpf(-spread, spread, t)
		var rot := Basis(Vector3.FORWARD, a)
		var dir: Vector3 = b * (rot * Vector3.UP)
		var taper: float = 1.0 - 0.24 * absf(t * 2.0 - 1.0)
		var stagger: float = th * (0.7 if i % 2 == 0 else -0.7)
		var pos: Vector3 = c + dir * r * 0.52 * taper + b * Vector3(0.0, 0.0, stagger)
		var m: StandardMaterial3D = edge if i % 3 == 1 else mat
		_ellipsoid(root, m, pos, Vector3(r * 0.088, r * 0.52 * taper, th), b * rot, 12, 7)


## Dichotomous coral, the panorama's flattened lilac trees. Depth 2 is 7 rods and
## 4 buds per root — measured, because the family's ceiling is 260 meshes and the
## loudest combination (quilted + antler) has to fit under it with room to spare.
static func _branch(root: Node3D, mat: StandardMaterial3D, tip: StandardMaterial3D, a: Vector3,
		dir: Vector3, ln: float, rad: float, depth: int, rng: RandomNumberGenerator) -> void:
	var b: Vector3 = a + dir * ln
	_cone(root, mat, a, b, rad, rad * 0.64)
	if depth <= 0:
		_ellipsoid(root, tip, b, Vector3(rad * 1.6, rad * 2.0, rad * 1.6), Basis(), 10, 6)
		return
	var axis: Vector3 = dir.cross(Vector3.UP)
	if axis.length() < 0.001:
		axis = dir.cross(Vector3.FORWARD)
	axis = axis.normalized().rotated(dir.normalized(), rng.randf_range(0.0, TAU))
	var fork: float = rng.randf_range(0.44, 0.80)
	for s in [-1.0, 1.0]:
		var sf: float = s
		var nd: Vector3 = dir.rotated(axis, fork * sf).normalized()
		_branch(root, mat, tip, b, nd, ln * rng.randf_range(0.60, 0.80), rad * 0.66, depth - 1, rng)


# ---------------------------------------------------------------------------
# primitives

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ellipsoid(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: Vector3, b: Basis,
		seg: int = 20, rings: int = 11) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = seg
	sph.rings = rings
	var mi: MeshInstance3D = _add(root, sph, mat)
	# NOTE Basis.scaled() is diag * B — the PARENT frame — which on a sphere cancels
	# the rotation outright. The squash has to happen in the ellipsoid's OWN frame,
	# or every plate in this file comes out round.
	mi.transform = Transform3D(b * _diag(r), c)
	return mi


static func _diag(r: Vector3) -> Basis:
	return Basis(Vector3(r.x, 0.0, 0.0), Vector3(0.0, r.y, 0.0), Vector3(0.0, 0.0, r.z))


static func _wedge(root: Node3D, mat: StandardMaterial3D, c: Vector3, size: Vector3,
		b: Basis) -> void:
	var pr := PrismMesh.new()
	pr.size = size
	var mi: MeshInstance3D = _add(root, pr, mat)
	mi.transform = Transform3D(b, c)


static func _rod(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r: float) -> void:
	_cone(root, mat, a, b, r, r)


static func _cone(root: Node3D, mat: StandardMaterial3D, a: Vector3, b: Vector3, r0: float,
		r1: float) -> void:
	var v: Vector3 = b - a
	var l: float = v.length()
	if l < 0.0005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r1
	cyl.bottom_radius = r0
	cyl.height = l
	cyl.radial_segments = 10
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(v), (a + b) * 0.5)


static func _disc(root: Node3D, mat: StandardMaterial3D, p: Vector3, nrm: Vector3, r: float,
		th: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = th
	cyl.radial_segments = 24
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(nrm), p)


static func _hoop(root: Node3D, mat: StandardMaterial3D, c: Vector3, r: float, inner: float,
		b: Basis) -> void:
	var tor := TorusMesh.new()
	tor.outer_radius = 1.0
	tor.inner_radius = clampf(inner, 0.05, 0.98)
	tor.rings = 24
	tor.ring_segments = 6
	var mi: MeshInstance3D = _add(root, tor, mat)
	mi.transform = Transform3D(b * _diag(Vector3(r, r, r)), c)


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	return Basis(ax, acos(clampf(dot_up, -1.0, 1.0)))


static func _basis_z_to(dir: Vector3) -> Basis:
	var zc: Vector3 = dir.normalized()
	var yc: Vector3 = Vector3.UP - zc * Vector3.UP.dot(zc)
	if yc.length() < 0.001:
		yc = Vector3.FORWARD - zc * Vector3.FORWARD.dot(zc)
	yc = yc.normalized()
	return Basis(yc.cross(zc).normalized(), yc, zc)


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
	return lerpf(float(keys[i]), float(keys[i + 1]), sm)


# ---------------------------------------------------------------------------
# the measured settle — copied from bodies/nana_gloss.gd rather than reinvented,
# so every family in this directory stands the same way

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
# materials

## A gown: a finish out of the shared library with the code-painted print as its
## albedo in world triplanar, so one cloth runs unbroken across twenty-two panels.
## The two caps are deliberate and both were learned the hard way elsewhere in the
## corpus — a body at metallic 1.0 photographs BLACK in a bare capture, and a print
## under a strong emission stops reading as a print.
static func _dress(finish: String, ground: Color, tex: ImageTexture, uv: float,
		rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, ground, rng)
	m.albedo_color = ground
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 1.6
	m.uv1_scale = Vector3(uv, uv, uv)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	m.metallic = minf(m.metallic, 0.58)
	m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.50)
	return m


## A small mark — a bead, a bud, an eye. Small enough to wear neon without the
## glow taking the frame off the statue.
static func _mark_mat(c: Color, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(MARK_FIN[rng.randi_range(0, MARK_FIN.size() - 1)], c, rng)
	m.metallic = minf(m.metallic, 0.50)
	return m


static func _tex_uv(kind: int) -> float:
	if kind == K_SCALE:
		return 2.30
	if kind == K_SPRAY:
		return 1.60
	if kind == K_GRASS:
		return 1.35
	return 1.45


# ---------------------------------------------------------------------------
# the print — every pixel drawn in code, four cloths, dealt by seed

static func _make_tex(kind: int, rng: RandomNumberGenerator, pal: Array, ink: Color, lilac: Color,
		sage: Color, ivory: Color, gold: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	if kind == K_GRASS:
		_paint_grass(img, rng, sage, ink)
	elif kind == K_SCALE:
		_paint_scale(img, rng, lilac, ivory)
	elif kind == K_SPRAY:
		_paint_spray(img, rng, pal, ink, ivory, gold)
	else:
		_paint_coral(img, rng, lilac, ink)
	return ImageTexture.create_from_image(img)


static func _put(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, TEX), posmod(y, TEX), c)


static func _fill(img: Image, c: Color) -> void:
	for y in range(TEX):
		for x in range(TEX):
			img.set_pixel(x, y, c)


## A thick stroke, sampled along the segment. Wraps at the tile edge via _put, so
## a ribbon that runs off the right comes back on the left and the triplanar
## projection never shows a seam — a visible join on a gown reads as a tear.
static func _stroke(img: Image, x0: float, y0: float, x1: float, y1: float, th: float,
		c: Color) -> void:
	var dx: float = x1 - x0
	var dy: float = y1 - y0
	var steps: int = int(ceil(maxf(absf(dx), absf(dy)))) + 2
	var ti: int = int(ceil(th))
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var px: float = x0 + dx * t
		var py: float = y0 + dy * t
		for yy in range(-ti, ti + 1):
			for xx in range(-ti, ti + 1):
				if float(xx * xx + yy * yy) <= th * th:
					_put(img, int(round(px)) + xx, int(round(py)) + yy, c)


static func _blob_px(img: Image, cx: float, cy: float, a: float, b: float, ang: float,
		c: Color) -> void:
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var rad: int = int(ceil(maxf(a, b))) + 2
	for y in range(-rad, rad + 1):
		for x in range(-rad, rad + 1):
			var u: float = (float(x) * ca + float(y) * sa) / maxf(a, 0.5)
			var v: float = (-float(x) * sa + float(y) * ca) / maxf(b, 0.5)
			if u * u + v * v <= 1.0:
				_put(img, int(round(cx)) + x, int(round(cy)) + y, c)


static func _ring_px(img: Image, cx: float, cy: float, r: float, th: float, a0: float, a1: float,
		c: Color) -> void:
	var steps: int = int(ceil((a1 - a0) * r * 2.2)) + 6
	for i in range(steps):
		var ang: float = lerpf(a0, a1, float(i) / float(steps - 1))
		_stroke(img, cx + cos(ang) * r, cy + sin(ang) * r, cx + cos(ang) * r, cy + sin(ang) * r,
			th, c)


## The panorama's lilac coral, flattened into a print: dichotomous trees on black.
static func _paint_coral(img: Image, rng: RandomNumberGenerator, lilac: Color, ink: Color) -> void:
	_fill(img, Color(0.045, 0.042, 0.052))
	var pale: Color = lilac.lerp(Color(1.0, 1.0, 1.0), 0.42)
	var n: int = rng.randi_range(6, 9)
	for i in range(n):
		var x0: float = rng.randf_range(0.0, float(TEX))
		var y0: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(0.0, TAU)
		_px_branch(img, x0, y0, ang, rng.randf_range(22.0, 34.0), 3.2, 3, lilac, pale, ink, rng)


static func _px_branch(img: Image, x: float, y: float, ang: float, ln: float, th: float,
		depth: int, stem: Color, pale: Color, ink: Color, rng: RandomNumberGenerator) -> void:
	var x1: float = x + cos(ang) * ln
	var y1: float = y + sin(ang) * ln
	# the dark outline first, then the stem over it — the reference's corals all
	# carry a thin dark contour, and it is what stops them dissolving into the
	# black ground at triplanar scale
	_stroke(img, x, y, x1, y1, th + 1.3, ink)
	_stroke(img, x, y, x1, y1, th, stem)
	if depth <= 0:
		_blob_px(img, x1, y1, th * 1.5, th * 1.5, 0.0, pale)
		return
	var fork: float = rng.randf_range(0.42, 0.86)
	for s in [-1.0, 1.0]:
		var sf: float = s
		_px_branch(img, x1, y1, ang + fork * sf, ln * rng.randf_range(0.60, 0.80), th * 0.66,
			depth - 1, stem, pale, ink, rng)


## The sage ribbon grass that fills the panorama's ground, as cloth.
static func _paint_grass(img: Image, rng: RandomNumberGenerator, sage: Color, ink: Color) -> void:
	_fill(img, Color(0.038, 0.046, 0.040))
	var pale: Color = sage.lerp(Color(1.0, 1.0, 0.92), 0.40)
	var n: int = rng.randi_range(34, 46)
	for i in range(n):
		var x0: float = rng.randf_range(0.0, float(TEX))
		var y0: float = rng.randf_range(0.0, float(TEX))
		var ang: float = rng.randf_range(-1.1, 1.1) + (0.0 if rng.randf() < 0.5 else PI)
		var seg: float = rng.randf_range(11.0, 19.0)
		var curl: float = rng.randf_range(-0.34, 0.34)
		var px: float = x0
		var py: float = y0
		var th: float = rng.randf_range(1.6, 2.9)
		for k in range(rng.randi_range(4, 7)):
			var nx: float = px + cos(ang) * seg
			var ny: float = py + sin(ang) * seg
			_stroke(img, px, py, nx, ny, th, sage if k % 2 == 0 else pale)
			px = nx
			py = ny
			ang += curl
			th = maxf(th * 0.88, 1.0)


## The quilted diamond lattice off the panorama's tapering tube, in pale grout.
## Every other row offset half a cell, which is what makes it tesserae and not
## graph paper.
static func _paint_scale(img: Image, rng: RandomNumberGenerator, lilac: Color,
		ivory: Color) -> void:
	var cols: float = float(rng.randi_range(9, 13))
	var rows: float = float(rng.randi_range(11, 16))
	var tint: Array[float] = []
	var cells: int = int(cols) * int(rows) + int(cols) + 2
	for i in range(cells):
		tint.append(rng.randf_range(0.80, 1.22))
	for y in range(TEX):
		var v: float = float(y) / float(TEX) * rows
		var r0: int = int(floor(v))
		var fy: float = v - floor(v) - 0.5
		for x in range(TEX):
			var u: float = float(x) / float(TEX) * cols + (0.5 if posmod(r0, 2) == 1 else 0.0)
			var c0: int = int(floor(u))
			var fx: float = u - floor(u) - 0.5
			var d: float = absf(fx) + absf(fy)
			if d > 0.44:
				img.set_pixel(x, y, ivory)
			else:
				var k: float = tint[posmod(r0 * int(cols) + c0, cells)]
				var shade: float = clampf(k * (0.84 + 0.44 * (0.44 - d)), 0.35, 1.45)
				img.set_pixel(x, y, Color(clampf(lilac.r * shade, 0.0, 1.0),
					clampf(lilac.g * shade, 0.0, 1.0), clampf(lilac.b * shade, 0.0, 1.0)))


## Scattered blooms with dark contour arcs on ivory — the couture print the brief
## asked for, drawn in the panorama's colours.
static func _paint_spray(img: Image, rng: RandomNumberGenerator, pal: Array, ink: Color,
		ivory: Color, gold: Color) -> void:
	_fill(img, ivory.lerp(Color(1.0, 1.0, 1.0), 0.35))
	var n: int = rng.randi_range(18, 26)
	for i in range(n):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var r: float = rng.randf_range(6.0, 13.0)
		var c: Color = pal[rng.randi_range(0, pal.size() - 1)]
		var spin: float = rng.randf_range(0.0, TAU)
		for p in range(5):
			var a: float = spin + TAU * float(p) / 5.0
			var px: float = cx + cos(a) * r * 0.62
			var py: float = cy + sin(a) * r * 0.62
			_blob_px(img, px, py, r * 0.56 + 1.2, r * 0.40 + 1.2, a, ink)
			_blob_px(img, px, py, r * 0.56, r * 0.40, a, c)
		_blob_px(img, cx, cy, r * 0.30, r * 0.30, 0.0, gold)
	for i in range(rng.randi_range(5, 9)):
		var ax: float = rng.randf_range(0.0, float(TEX))
		var ay: float = rng.randf_range(0.0, float(TEX))
		var ar: float = rng.randf_range(15.0, 36.0)
		var a0: float = rng.randf_range(0.0, TAU)
		_ring_px(img, ax, ay, ar, rng.randf_range(1.3, 2.4), a0, a0 + rng.randf_range(1.1, 3.2),
			ink)
