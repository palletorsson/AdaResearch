## THE ONE-DIMENSIONAL MAN, as a Doom sprite (2026-08-29, Palle: "the enemies
## should be silhouettes in the beginning like in doom but more abstract ... black
## and gray silhouettes ... it can allude to the one dimensional man but this is
## 2d. Like doom they are 2.5 billboard sprite cheats that are procedurally
## generated").
##
## A figure is a stack of parts on a 64x128 canvas — head, neck, torso, hips,
## two legs, up to two arms, and sometimes one thing too many (a second head, a
## horn, a long neck) — every proportion drawn from a seeded RNG, so a seed IS a
## body and the same seed is the same body on every machine. Grey with a darker
## foot and a faint vertical grain; alpha one inside, zero outside, one pixel of
## soft edge so it does not shimmer at a grazing angle. Mirrored across x seven
## times in ten, which is what makes it read as a Doom sprite and not a blot.
##
## Marcuse's one-dimensional man has no depth by definition. So: a quad, unshaded,
## upright, turning to face you around Y only (BILLBOARD_FIXED_Y — the Doom cheat),
## never lit, never showing a side. It is flat because flatness is the point.
##
## STATIC AND PURE. Give it a seed, get a texture. Nothing here touches the tree,
## so the probe can draw fifty of them headless and write them out as PNGs.
class_name SilhouetteSprite

const W := 64
const H := 128


## One figure. Deterministic in `seed`.
static func make_texture(seed: int) -> ImageTexture:
	return ImageTexture.create_from_image(make_image(seed))


static func make_image(seed: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# ── the body plan, in canvas units (x 0..1 across, y 0 top .. 1 feet) ──
	var mirror: bool = rng.randf() < 0.7
	var grey: float = rng.randf_range(0.04, 0.30)          # the whole figure's value
	var head_r: float = rng.randf_range(0.055, 0.11)
	var neck_h: float = rng.randf_range(0.0, 0.09)
	var torso_w: float = rng.randf_range(0.14, 0.30)
	var torso_h: float = rng.randf_range(0.22, 0.40)
	var hip_w: float = torso_w * rng.randf_range(0.6, 1.25)
	var leg_w: float = rng.randf_range(0.04, 0.09)
	var leg_spread: float = rng.randf_range(0.02, 0.14)
	var leg_h: float = 1.0 - (0.06 + head_r * 2.0 + neck_h + torso_h)
	var arms: int = [0, 1, 2, 2, 2][rng.randi_range(0, 4)]
	var arm_w: float = rng.randf_range(0.035, 0.07)
	var arm_len: float = rng.randf_range(0.18, 0.42)
	var arm_ang: float = rng.randf_range(-0.9, 0.6)         # radians from straight down
	var extra: int = rng.randi_range(0, 5)                  # 0..2 = something extra
	var grain: float = rng.randf_range(0.0, 0.05)
	var wobble: float = rng.randf_range(0.0, 0.025)         # outline noise amplitude
	var wobble_f: float = rng.randf_range(3.0, 9.0)

	# ── paint ──
	var cx := 0.5
	var y := 0.06
	_ellipse(img, cx, y + head_r, head_r, head_r * rng.randf_range(0.9, 1.35), grey, grain, wobble, wobble_f, rng)
	y += head_r * 2.0
	if neck_h > 0.0:
		_quad(img, cx - head_r * 0.35, y, head_r * 0.7, neck_h, grey, grain, wobble * 0.5, wobble_f, rng)
	y += neck_h
	# torso: a trapezoid, shoulders to hips
	_trap(img, cx, y, torso_w, hip_w, torso_h, grey, grain, wobble, wobble_f, rng)
	var shoulder_y := y + torso_h * 0.08
	y += torso_h
	# legs
	var lx := cx - leg_spread * 0.5 - leg_w * 0.5
	var rx := cx + leg_spread * 0.5 - leg_w * 0.5
	_quad(img, lx, y, leg_w, leg_h, grey, grain, wobble, wobble_f, rng)
	if mirror:
		_quad(img, rx, y, leg_w, leg_h, grey, grain, wobble, wobble_f, rng)
	else:
		_quad(img, rx + rng.randf_range(-0.04, 0.04), y, leg_w * rng.randf_range(0.7, 1.4),
			leg_h * rng.randf_range(0.85, 1.0), grey, grain, wobble, wobble_f, rng)
	# arms, hanging from the shoulders at arm_ang
	if arms >= 1:
		_limb(img, cx - torso_w * 0.5, shoulder_y, -1.0, arm_ang, arm_len, arm_w, grey, grain, rng)
	if arms >= 2:
		var a2: float = arm_ang if mirror else rng.randf_range(-1.2, 0.8)
		_limb(img, cx + torso_w * 0.5, shoulder_y, 1.0, a2, arm_len * (1.0 if mirror else rng.randf_range(0.6, 1.3)),
			arm_w, grey, grain, rng)
	# one thing too many
	match extra:
		0:   # a second, smaller head beside the first
			_ellipse(img, cx + (head_r * 1.9) * (1.0 if rng.randf() < 0.5 else -1.0), 0.06 + head_r * 1.3,
				head_r * 0.6, head_r * 0.6, grey, grain, wobble, wobble_f, rng)
		1:   # a horn
			_limb(img, cx, 0.06 + head_r * 0.3, 1.0 if rng.randf() < 0.5 else -1.0,
				rng.randf_range(-2.6, -2.0), head_r * 2.2, arm_w * 0.6, grey, grain, rng)
		2:   # a bar held across — the tool, the placard, the thing carried
			_quad(img, cx - torso_w * 0.9, shoulder_y + torso_h * rng.randf_range(0.2, 0.7),
				torso_w * 1.8, arm_w * 0.8, grey, grain, 0.0, 1.0, rng)
		_:
			pass

	# the darker foot: value falls off toward the ground so it stands ON something
	for py in range(H):
		var fall: float = 1.0 - 0.45 * pow(float(py) / float(H - 1), 3.0)
		for px in range(W):
			var c := img.get_pixel(px, py)
			if c.a > 0.0:
				img.set_pixel(px, py, Color(c.r * fall, c.g * fall, c.b * fall, c.a))
	_soften(img)
	return img


# ── primitives: every shape writes the same grey with a per-pixel grain ──────

static func _pix(img: Image, px: int, py: int, g: float, grain: float, rng: RandomNumberGenerator) -> void:
	if px < 0 or py < 0 or px >= W or py >= H:
		return
	var v: float = clampf(g + (rng.randf() - 0.5) * grain, 0.0, 1.0)
	img.set_pixel(px, py, Color(v, v, v + 0.01, 1.0))


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, g: float, grain: float,
		wob: float, wf: float, rng: RandomNumberGenerator) -> void:
	var x0 := int((cx - rx - wob) * W) - 1
	var x1 := int((cx + rx + wob) * W) + 1
	var y0 := int((cy - ry) * H) - 1
	var y1 := int((cy + ry) * H) + 1
	for py in range(y0, y1 + 1):
		var fy: float = (float(py) + 0.5) / float(H)
		var w: float = wob * sin(fy * wf * 6.283)
		for px in range(x0, x1 + 1):
			var fx: float = (float(px) + 0.5) / float(W)
			var dx: float = (fx - cx) / (rx + w)
			var dy: float = (fy - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_pix(img, px, py, g, grain, rng)


static func _quad(img: Image, x: float, y: float, w: float, h: float, g: float, grain: float,
		wob: float, wf: float, rng: RandomNumberGenerator) -> void:
	var y0 := int(y * H)
	var y1 := int((y + h) * H)
	for py in range(y0, y1 + 1):
		var fy: float = (float(py) + 0.5) / float(H)
		var ww: float = wob * sin(fy * wf * 6.283)
		var px0 := int((x - ww) * W)
		var px1 := int((x + w + ww) * W)
		for px in range(px0, px1 + 1):
			_pix(img, px, py, g, grain, rng)


## Shoulders to hips: wider at the top, and the outline may lean.
static func _trap(img: Image, cx: float, y: float, top_w: float, bot_w: float, h: float, g: float,
		grain: float, wob: float, wf: float, rng: RandomNumberGenerator) -> void:
	var y0 := int(y * H)
	var y1 := int((y + h) * H)
	for py in range(y0, y1 + 1):
		var t: float = clampf((float(py) - y0) / maxf(1.0, float(y1 - y0)), 0.0, 1.0)
		var fy: float = (float(py) + 0.5) / float(H)
		var w: float = lerpf(top_w, bot_w, t) + wob * sin(fy * wf * 6.283)
		var px0 := int((cx - w * 0.5) * W)
		var px1 := int((cx + w * 0.5) * W)
		for px in range(px0, px1 + 1):
			_pix(img, px, py, g, grain, rng)


## A limb: a thick line from (x, y) at angle `ang` from straight-down, `side`
## flips it. Drawn as stamped discs so it can lean without stair-stepping.
static func _limb(img: Image, x: float, y: float, side: float, ang: float, len: float, w: float,
		g: float, grain: float, rng: RandomNumberGenerator) -> void:
	var steps: int = int(len * H)
	for i in range(steps + 1):
		var t: float = float(i) / maxf(1.0, float(steps))
		var px: float = x + side * sin(ang) * len * t
		var py: float = y + cos(ang) * len * t
		var r: float = w * 0.5 * (1.0 - 0.25 * t)      # tapers a little
		var rx := int(r * W) + 1
		var ry := int(r * H * 0.5) + 1
		var ix := int(px * W)
		var iy := int(py * H)
		for oy in range(-ry, ry + 1):
			for ox in range(-rx, rx + 1):
				if float(ox * ox) / float(rx * rx) + float(oy * oy) / float(ry * ry) <= 1.0:
					_pix(img, ix + ox, iy + oy, g, grain, rng)


## One pixel of soft edge: alpha becomes the fraction of opaque neighbours, so
## the outline resolves instead of aliasing when the quad is seen at an angle.
static func _soften(img: Image) -> void:
	var src := img.duplicate() as Image
	for py in range(H):
		for px in range(W):
			var c := src.get_pixel(px, py)
			if c.a > 0.0:
				continue
			var n := 0
			for oy in [-1, 0, 1]:
				for ox in [-1, 0, 1]:
					var qx: int = px + ox
					var qy: int = py + oy
					if qx < 0 or qy < 0 or qx >= W or qy >= H:
						continue
					if src.get_pixel(qx, qy).a > 0.0:
						n += 1
			if n > 0:
				var near: Color = src.get_pixel(clampi(px, 1, W - 2), clampi(py, 1, H - 2))
				var v: float = near.r if near.a > 0.0 else 0.12
				img.set_pixel(px, py, Color(v, v, v, float(n) / 8.0 * 0.6))
