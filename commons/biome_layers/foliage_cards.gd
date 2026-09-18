extends RefCounted
## foliage_cards.gd — the biome's foliage cards drawn IN the engine, from the seed (gen 9;
## Palle: "can we make the foliage card procedurally?").
##
## Generation 8 put grass, reeds, ferns, meadow plants and litter on alpha-cut cards whose
## images came from PNG files drawn offline by tools/make_foliage_cards.py. This draws the
## same five cards at build time on an Image, with nothing loaded: every stroke is a
## quadratic Bézier walked in small steps and stamped with a filled disc (Image has no
## polygon fill; fill_rect per disc row is C++-fast), every leaf a disc brush whose radius
## follows sin(pi u)^0.8 along the leaf's axis, with a lighter midrib. So the cards become
## part of the DNA: the seed shapes them, the moisture changes what grows —
##   grass   8 + 8·m blades; straw to green by m; drier tufts lean and droop more
##   reed    height by m, cattail heads only when wet
##   fern    fuller (more, longer pinnae) when wet, a sparse frond when dry
##   plant   broader leaves when wet
##   litter  the fallen leaves' browns, redder when dry
## Cards are cached per (kind, seed, moisture band) so a world draws each of its cards once;
## a card costs roughly 20-70 ms at 256 px. Headless-safe: it is CPU work on an Image.
##
## The object keeps a `foliage` knob: `drawn` (this, the default) or `files` (the PNGs in
## commons/biome_layers/foliage/, for a hand-painted set).

const SIZE := 256
static var _cache: Dictionary = {}


## The card for a kind in a world: "grass" | "reed" | "fern" | "plant" | "litter".
static func card(kind: String, seed: int, moisture: float) -> ImageTexture:
	var band: int = clampi(int(round(clampf(moisture, 0.0, 1.0) * 4.0)), 0, 4)
	var key := "%s|%d|%d" % [kind, seed, band]
	if _cache.has(key):
		return _cache[key]
	var img := draw(kind, seed, float(band) / 4.0)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## The image itself (transparent RGBA, SIZE x SIZE), for probes and galleries.
static func draw(kind: String, seed: int, moisture: float) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "foliage_card", kind, int(round(moisture * 4.0))])
	match kind:
		"grass":
			_grass(img, rng, moisture)
		"reed":
			_reed(img, rng, moisture)
		"fern":
			_fern(img, rng, moisture)
		"plant":
			_plant(img, rng, moisture)
		"litter":
			_litter(img, rng, moisture)
		_:
			_grass(img, rng, moisture)
	return img


## Share of the card that is painted (alpha > 0.5) — the probe's coverage check.
static func coverage(img: Image) -> float:
	var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			if img.get_pixel(x, y).a > 0.5:
				n += 1
	return float(n) / float((img.get_width() / 2) * (img.get_height() / 2))


# ── the brush ────────────────────────────────────────────────────────────────────
static func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	var ri: int = maxi(1, int(ceil(r)))
	var icx := int(round(cx))
	var icy := int(round(cy))
	for dy in range(-ri, ri + 1):
		var hw: float = sqrt(maxf(0.0, r * r - float(dy) * float(dy)))
		var w: int = int(round(hw))
		var y: int = icy + dy
		if y < 0 or y >= SIZE:
			continue
		var x0: int = clampi(icx - w, 0, SIZE - 1)
		var x1: int = clampi(icx + w, 0, SIZE - 1)
		img.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), c)


static func _bez(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return p0 * (1.0 - t) * (1.0 - t) + p1 * 2.0 * (1.0 - t) * t + p2 * t * t


## A tapered stroke along a quadratic Bézier, colour lerped base → tip.
static func _stroke(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, w0: float, w1: float, c0: Color, c1: Color) -> void:
	var length: float = p0.distance_to(p1) + p1.distance_to(p2)
	var steps: int = maxi(8, int(length / 1.2))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = _bez(p0, p1, p2, t)
		_disc(img, p.x, p.y, lerpf(w0, w1, t) * 0.5, c0.lerp(c1, t))


## A leaf: a disc brush along a slightly curling axis, the radius following sin(pi u)^0.8,
## with an optional lighter midrib.
static func _leaf(img: Image, base: Vector2, angle: float, length: float, width: float, c: Color, rib: Color, curl: float, with_rib: bool) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var nrm := Vector2(-dir.y, dir.x)
	var steps: int = maxi(10, int(length / 1.5))
	var axis: PackedVector2Array = PackedVector2Array()
	for i in range(steps + 1):
		var u: float = float(i) / float(steps)
		var p: Vector2 = base + dir * (length * u) + nrm * (curl * length * u * u)
		var r: float = width * 0.5 * pow(sin(PI * u), 0.8)
		_disc(img, p.x, p.y, r, c)
		axis.append(p)
	if with_rib:
		for i in range(int(steps * 0.85)):
			var p: Vector2 = axis[i]
			_disc(img, p.x, p.y, maxf(0.6, width * 0.03), rib)


static func _jit(c: Color, j: float, rng: RandomNumberGenerator) -> Color:
	var d: float = rng.randf_range(-j, j)
	return Color(clampf(c.r + d, 0.0, 1.0), clampf(c.g + d, 0.0, 1.0), clampf(c.b + d, 0.0, 1.0), 1.0)


# ── the five cards ────────────────────────────────────────────────────────────────
static func _grass(img: Image, rng: RandomNumberGenerator, m: float) -> void:
	var s := float(SIZE)
	var base_y: float = s - 8.0
	var n: int = 8 + int(round(8.0 * m))
	var dry: float = clampf(1.0 - 1.3 * m, 0.0, 1.0)
	var c_base: Color = Color(0.17, 0.33, 0.10).lerp(Color(0.46, 0.38, 0.16), dry)
	var c_tip: Color = Color(0.46, 0.68, 0.26).lerp(Color(0.80, 0.68, 0.32), dry)
	for _i in range(n):
		var x0: float = s * 0.5 + rng.randf_range(-0.09, 0.09) * s
		var length: float = rng.randf_range(0.42, 0.86) * s * (0.85 + 0.15 * m)
		var lean: float = rng.randf_range(-0.30, 0.30) * s * (1.0 + 0.5 * dry)
		var droop: float = rng.randf_range(0.0, 0.5 + 0.3 * dry)
		var p0 := Vector2(x0, base_y)
		var p2 := Vector2(x0 + lean * (1.0 + droop), base_y - length * (1.0 - 0.45 * droop))
		var p1 := Vector2(x0 + lean * 0.25, base_y - length * 0.72)
		_stroke(img, p0, p1, p2, rng.randf_range(5.5, 8.5), 1.0, _jit(c_base, 0.03, rng), _jit(c_tip, 0.05, rng))


static func _reed(img: Image, rng: RandomNumberGenerator, m: float) -> void:
	var s := float(SIZE)
	var base_y: float = s - 6.0
	var heads := 0
	for _i in range(rng.randi_range(5, 7)):
		var x0: float = s * 0.5 + rng.randf_range(-0.11, 0.11) * s
		var length: float = rng.randf_range(0.70, 0.96) * s * (0.8 + 0.2 * m)
		var lean: float = rng.randf_range(-0.10, 0.10) * s
		var p0 := Vector2(x0, base_y)
		var p2 := Vector2(x0 + lean, base_y - length)
		var p1 := Vector2(x0 + lean * 0.4, base_y - length * 0.55)
		_stroke(img, p0, p1, p2, rng.randf_range(3.5, 5.0), 1.0, _jit(Color(0.30, 0.46, 0.20), 0.03, rng), _jit(Color(0.52, 0.64, 0.32), 0.04, rng))
		if m > 0.45 and heads < 2 and rng.randf() < 0.5:
			heads += 1
			var head: Color = _jit(Color(0.40, 0.25, 0.11), 0.03, rng)
			for k in range(-16, 17):
				_disc(img, p2.x, p2.y + float(k), 3.4 * sqrt(maxf(0.0, 1.0 - float(k * k) / 289.0)) + 0.5, head)


static func _fern(img: Image, rng: RandomNumberGenerator, m: float) -> void:
	var s := float(SIZE)
	var p0 := Vector2(s * 0.5, s - 6.0)
	var lean: float = rng.randf_range(-0.28, 0.28) * s
	var p2 := Vector2(s * 0.5 + lean * 1.3, s * 0.14)
	var p1 := Vector2(s * 0.5 + lean * 0.35, s * 0.52)
	var n: int = 9 + int(round(8.0 * m))
	for i in range(n):
		var t: float = 0.12 + 0.86 * float(i) / float(maxi(1, n - 1))
		var p: Vector2 = _bez(p0, p1, p2, t)
		var q: Vector2 = _bez(p0, p1, p2, minf(1.0, t + 0.02))
		var ang: float = atan2(q.y - p.y, q.x - p.x)
		var lp: float = (0.22 * s) * pow(1.0 - t, 0.75) * (0.7 + 0.3 * m) + 0.03 * s
		var wp: float = lp * 0.34
		var c: Color = _jit(Color(0.14, 0.38, 0.15), 0.03, rng)
		var c2: Color = _jit(Color(0.30, 0.56, 0.24), 0.03, rng)
		for side in [1.0, -1.0]:
			var a: float = ang + side * deg_to_rad(rng.randf_range(40.0, 55.0))
			_leaf(img, p, a, lp, wp, c if side > 0.0 else c2, Color.WHITE, 0.15 * side, false)
	_stroke(img, p0, p1, p2, 3.0, 0.8, Color(0.20, 0.36, 0.14), Color(0.34, 0.52, 0.22))


static func _plant(img: Image, rng: RandomNumberGenerator, m: float) -> void:
	var s := float(SIZE)
	var base := Vector2(s * 0.5, s - 10.0)
	var n: int = rng.randi_range(7, 9)
	var angles: Array[float] = []
	for _i in range(n):
		angles.append(rng.randf_range(-78.0, 78.0))
	angles.sort()
	for a_deg in angles:
		var a: float = deg_to_rad(-90.0 + a_deg)
		var length: float = rng.randf_range(0.34, 0.52) * s * (0.8 + 0.2 * (1.0 - absf(a_deg) / 90.0))
		var width: float = rng.randf_range(0.11, 0.19) * s * (0.75 + 0.35 * m)
		var c: Color = _jit(Color(0.19, 0.45, 0.21), 0.05, rng)
		var rib: Color = _jit(Color(0.46, 0.68, 0.36), 0.03, rng)
		_leaf(img, base + Vector2(rng.randf_range(-4.5, 4.5), 0.0), a, length, width, c, rib, rng.randf_range(-0.12, 0.12), true)


static func _litter(img: Image, rng: RandomNumberGenerator, m: float) -> void:
	var s := float(SIZE)
	var browns := [Color(0.42, 0.28, 0.12), Color(0.55, 0.38, 0.16), Color(0.36, 0.24, 0.10), Color(0.62, 0.48, 0.22), Color(0.30, 0.30, 0.14)]
	var red: float = clampf(1.0 - 1.2 * m, 0.0, 1.0) * 0.12
	for _i in range(rng.randi_range(30, 40)):
		var p := Vector2(rng.randf_range(0.08, 0.92) * s, rng.randf_range(0.08, 0.92) * s)
		var length: float = rng.randf_range(0.09, 0.17) * s
		var width: float = length * rng.randf_range(0.35, 0.55)
		var a: float = rng.randf_range(0.0, TAU)
		var c: Color = browns[rng.randi_range(0, browns.size() - 1)]
		c = _jit(Color(c.r + red, c.g, c.b - red * 0.5), 0.04, rng)
		_leaf(img, p, a, length, width, c, Color(0.30, 0.20, 0.09), rng.randf_range(-0.2, 0.2), true)
