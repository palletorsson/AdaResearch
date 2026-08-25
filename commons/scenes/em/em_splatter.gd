extends Control
## THE SPLATTER (2026-08-24, Palle: "splatter animation on screen, to the
## endscene, back to the last save point. There should also be a fire splatter
## as you die"). Drawn, not textured: a handful of blobs with satellites and
## drips, seeded per death so two deaths are never the same picture, growing
## and running down the glass as `progress` is tweened 0 -> 1.
##
## Two palettes, because the museum kills you in two ways: LASER cuts (deep
## red, tight, arterial) and FIRE burns (ember orange, wide, smoking).

var progress: float = 0.0:
	set(v):
		progress = v
		queue_redraw()

var kind: String = "laser":
	set(v):
		kind = v
		_seed_blobs()
		queue_redraw()

var _blobs: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed_blobs()


func _seed_blobs() -> void:
	# a fresh seed per death: the picture is never quite the same twice
	_rng.randomize()
	_blobs.clear()
	var n: int = 7 if kind == "laser" else 9
	for i in range(n):
		# weighted to the edges: the middle stays readable enough to see the
		# room you died in, which is the whole point of a splatter over a fade
		var edge: float = _rng.randf_range(0.0, 1.0)
		var px: float = _rng.randf_range(0.04, 0.96)
		var py: float = _rng.randf_range(0.04, 0.96)
		if edge < 0.62:
			if _rng.randf() < 0.5:
				px = _rng.randf_range(0.02, 0.26) if _rng.randf() < 0.5 else _rng.randf_range(0.74, 0.98)
			else:
				py = _rng.randf_range(0.02, 0.24) if _rng.randf() < 0.5 else _rng.randf_range(0.76, 0.98)
		var sats: Array = []
		for s in range(_rng.randi_range(3, 7)):
			sats.append(Vector3(_rng.randf_range(-0.09, 0.09), _rng.randf_range(-0.09, 0.09),
				_rng.randf_range(0.10, 0.34)))
		_blobs.append({"p": Vector2(px, py), "r": _rng.randf_range(0.045, 0.135),
			"sats": sats, "drip": _rng.randf_range(0.0, 0.16), "t": _rng.randf_range(0.0, 0.35)})


func _draw() -> void:
	if progress <= 0.001:
		return
	var sz: Vector2 = size
	var base: Color = Color(0.58, 0.02, 0.03) if kind == "laser" else Color(0.86, 0.30, 0.05)
	var hot: Color = Color(0.90, 0.10, 0.08) if kind == "laser" else Color(1.00, 0.72, 0.18)
	for b_v in _blobs:
		var b: Dictionary = b_v
		# each blob has its own start, so the screen fills in bursts
		var t: float = clampf((progress - float(b["t"])) / maxf(0.05, 1.0 - float(b["t"])), 0.0, 1.0)
		if t <= 0.0:
			continue
		var grow: float = sqrt(t)
		var run: float = float(b["drip"]) * t * t          # gravity arrives late
		var c: Vector2 = (b["p"] as Vector2) * sz + Vector2(0.0, run * sz.y)
		var r: float = float(b["r"]) * grow * minf(sz.x, sz.y)
		var col: Color = base
		col.a = clampf(0.62 + 0.3 * t, 0.0, 0.94)
		draw_circle(c, r, col)
		# the hot core reads as wet, and on fire it reads as ember
		var hc: Color = hot
		hc.a = 0.5 * t
		draw_circle(c, r * 0.45, hc)
		for s_v in (b["sats"] as Array):
			var s: Vector3 = s_v
			var sc: Vector2 = c + Vector2(s.x, s.y) * minf(sz.x, sz.y) * grow
			var scol: Color = base
			scol.a = 0.5 * t
			draw_circle(sc, r * s.z, scol)
		# the drip's tail
		if run > 0.01:
			var w: float = r * 0.34
			var tail := Rect2(c.x - w, c.y - run * sz.y, w * 2.0, run * sz.y)
			var tcol: Color = base
			tcol.a = 0.42 * t
			draw_rect(tail, tcol)
