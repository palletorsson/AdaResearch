extends RefCounted
class_name DistributionField

## DistributionField — the one engine behind every paint layer.
##
## A paint layer is `element × distribution × density`. This turns the
## DISTRIBUTION half into concrete placements over the map grid, so every
## population layer (tree, critter, flower, …) shares one placement model
## instead of its own bespoke ring math. See doc/PAINT_LAYERS.md.
##
## Five modes, one signature:
##   plane   — regular lattice, spacing from density (the grid aesthetic)
##   random  — stochastic scatter, count ∝ density
##   curve   — density varies along an axis (x / z / radial) by a falloff
##   noise   — FastNoiseLite field, thresholded → organic clumps + clearings
##   brush   — a per-cell density field painted by hand (desktop or VR)
##
## Everything is deterministic from rng_seed (no global RNG) so a map renders
## the same every launch — curriculum-honest, capture-stable.

const MODE_PLANE := "plane"
const MODE_RANDOM := "random"
const MODE_CURVE := "curve"
const MODE_NOISE := "noise"
const MODE_FRACTAL := "fractal"
const MODE_BRUSH := "brush"

const DEFAULT_MAX := 160   ## safety ceiling per layer (before budget scaling)


## Per-cell density field in [0..1], row-major (idx = z * grid_w + x).
## The substrate layers (ground height / shader / particle) will consume this
## field directly; the population layers go through `placements()` below.
static func build_field(spec: Dictionary, grid_w: int, grid_d: int, rng_seed: int) -> PackedFloat32Array:
	var n: int = maxi(0, grid_w * grid_d)
	var field := PackedFloat32Array()
	field.resize(n)
	var mode: String = str(spec.get("mode", MODE_NOISE))
	var density: float = clampf(float(spec.get("density", 0.5)), 0.0, 1.0)
	match mode:
		MODE_PLANE, MODE_RANDOM:
			for i in n:
				field[i] = density
		MODE_CURVE:
			var axis: String = str(spec.get("axis", "radial"))
			var falloff: String = str(spec.get("falloff", "smooth"))
			var invert: bool = bool(spec.get("invert", false))
			for z in grid_d:
				for x in grid_w:
					var t: float = _curve_t(axis, x, z, grid_w, grid_d)
					var v: float = _shape(falloff, t)
					if invert:
						v = 1.0 - v
					field[z * grid_w + x] = density * clampf(v, 0.0, 1.0)
		MODE_NOISE:
			var noise := FastNoiseLite.new()
			noise.seed = rng_seed
			noise.frequency = maxf(0.001, float(spec.get("scale", 0.12)))
			var thr: float = clampf(float(spec.get("threshold", 0.35)), 0.0, 0.99)
			for z in grid_d:
				for x in grid_w:
					var nv: float = (noise.get_noise_2d(float(x), float(z)) + 1.0) * 0.5
					nv = clampf((nv - thr) / (1.0 - thr), 0.0, 1.0)
					field[z * grid_w + x] = density * nv
		MODE_FRACTAL:
			# Self-similar clumping: multi-octave fBm noise — detail at many scales,
			# the "fractal" step past plain noise. Higher octaves = more recursion.
			var fnoise := FastNoiseLite.new()
			fnoise.seed = rng_seed
			fnoise.frequency = maxf(0.001, float(spec.get("scale", 0.16)))
			fnoise.fractal_type = FastNoiseLite.FRACTAL_FBM
			fnoise.fractal_octaves = clampi(int(spec.get("octaves", 4)), 1, 8)
			fnoise.fractal_lacunarity = float(spec.get("lacunarity", 2.0))
			fnoise.fractal_gain = float(spec.get("gain", 0.5))
			var fthr: float = clampf(float(spec.get("threshold", 0.5)), 0.0, 0.99)
			for z in grid_d:
				for x in grid_w:
					var fv: float = (fnoise.get_noise_2d(float(x), float(z)) + 1.0) * 0.5
					fv = clampf((fv - fthr) / (1.0 - fthr), 0.0, 1.0)
					field[z * grid_w + x] = density * fv
		MODE_BRUSH:
			_read_brush(spec.get("brush", []), field, grid_w, grid_d, density)
		_:
			for i in n:
				field[i] = density
	return field


## Build a brush field WITHOUT the [0..1] clamp — for the "ground" HEIGHT map, whose
## brush cells store HEIGHTS IN METRES (0..max_cap), not 0..1 density. The normal
## build_field / _read_brush path clamps every cell to [0,1] (correct for scatter
## density), which would flatten any painted height above 1 metre. This reads the same
## sparse {w,d,cells} (or rows / flat) brush at full magnitude, only ceiling it at
## `max_cap` (the slider's top, 4.0). density still scales (kept at 1.0 by the ground
## path so the painted SHAPE owns the terrain). Same resample rules as _read_brush.
static func build_height_field(spec: Dictionary, grid_w: int, grid_d: int, max_cap: float = 4.0) -> PackedFloat32Array:
	var n: int = maxi(0, grid_w * grid_d)
	var field := PackedFloat32Array()
	field.resize(n)
	var density: float = clampf(float(spec.get("density", 1.0)), 0.0, 1.0)
	var brush = spec.get("brush", [])
	if brush is Dictionary and brush.has("cells"):
		brush = _sparse_to_rows(brush)
	if brush is Array and brush.size() > 0 and brush[0] is Array:
		var bd: int = brush.size()
		var bw: int = (brush[0] as Array).size()
		if bw <= 0:
			return field
		if bw == grid_w and bd == grid_d:
			for z in grid_d:
				var row = brush[z]
				if row is Array:
					for x in mini(grid_w, row.size()):
						field[z * grid_w + x] = density * clampf(float(row[x]), 0.0, max_cap)
		else:
			for z in grid_d:
				var v: float = (float(z) + 0.5) / float(grid_d)
				for x in grid_w:
					var u: float = (float(x) + 0.5) / float(grid_w)
					field[z * grid_w + x] = density * clampf(_height_bilinear(brush, bw, bd, u, v), 0.0, max_cap)
	elif brush is Array:
		for i in mini(field.size(), brush.size()):
			field[i] = density * clampf(float(brush[i]), 0.0, max_cap)
	return field


## Bilinear sample for the unclamped height field (mirrors _brush_bilinear but does NOT
## clamp the per-cell value to [0,1], so metres > 1 survive the resample).
static func _height_bilinear(brush: Array, bw: int, bd: int, u: float, v: float) -> float:
	var fx: float = clampf(u * float(bw) - 0.5, 0.0, float(bw - 1))
	var fz: float = clampf(v * float(bd) - 0.5, 0.0, float(bd - 1))
	var x0: int = int(floor(fx)); var z0: int = int(floor(fz))
	var x1: int = mini(x0 + 1, bw - 1); var z1: int = mini(z0 + 1, bd - 1)
	var tx: float = fx - float(x0); var tz: float = fz - float(z0)
	return lerpf(lerpf(_height_cell(brush, x0, z0), _height_cell(brush, x1, z0), tx),
				 lerpf(_height_cell(brush, x0, z1), _height_cell(brush, x1, z1), tx), tz)


static func _height_cell(brush: Array, x: int, z: int) -> float:
	if z < 0 or z >= brush.size():
		return 0.0
	var row = brush[z]
	if not (row is Array) or x < 0 or x >= row.size():
		return 0.0
	return maxf(0.0, float(row[x]))


## World-space placement positions (y = 0, on the grid floor) for ONE paint
## layer spec. `budget` (Phase-5 population budget) scales the final count.
static func placements(spec: Dictionary, grid_w: int, grid_d: int, cube_size: float,
		rng_seed: int, budget: float = 1.0) -> Array:
	if grid_w <= 0 or grid_d <= 0:
		return []
	var mode: String = str(spec.get("mode", MODE_NOISE))
	var field := build_field(spec, grid_w, grid_d, rng_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed + 777

	var cells: Array = []
	if mode == MODE_PLANE:
		# Regular lattice — spacing from density (dense → step 1, sparse → 5).
		var density: float = clampf(float(spec.get("density", 0.5)), 0.05, 1.0)
		var step: int = maxi(1, int(round(lerpf(5.0, 1.0, density))))
		var ox: int = (grid_w % step) / 2
		var oz: int = (grid_d % step) / 2
		for z in range(oz, grid_d, step):
			for x in range(ox, grid_w, step):
				cells.append(Vector2i(x, z))
	else:
		# Stochastic — place a cell with probability = its field value.
		for z in grid_d:
			for x in grid_w:
				if rng.randf() < field[z * grid_w + x]:
					cells.append(Vector2i(x, z))

	# Population budget + safety cap: keep = natural × budget, ceiling DEFAULT_MAX.
	var keep: int = int(round(float(cells.size()) * clampf(budget, 0.0, 1.0)))
	keep = mini(keep, int(spec.get("max", DEFAULT_MAX)))
	if cells.size() > keep:
		_shuffle(cells, rng)
		cells.resize(maxi(0, keep))

	# Cells → world positions (cell centres). Jitter the stochastic modes so
	# they don't read as grid-aligned; keep PLANE crisp.
	var jitter: float = 0.0 if mode == MODE_PLANE else cube_size * 0.7
	var pts: Array = []
	for c in cells:
		var jx: float = (rng.randf() - 0.5) * jitter
		var jz: float = (rng.randf() - 0.5) * jitter
		pts.append(Vector3((float(c.x) + 0.5) * cube_size + jx, 0.0, (float(c.y) + 0.5) * cube_size + jz))
	return pts


## True if a layer carries an explicit artifact list (`artifacts: [...]` or the
## legacy `params.artifact`). Such layers are placed by object_scatter — any
## element with a list scatters those artifacts by its distribution, instead of
## the element's default morphology. See doc/PAINT_LAYERS.md § Object scatter.
static func is_artifact_layer(layer) -> bool:
	if not (layer is Dictionary):
		return false
	var arts = layer.get("artifacts", null)
	if arts is Array and not (arts as Array).is_empty():
		return true
	var p = layer.get("params", null)
	return p is Dictionary and p.has("artifact")


## Union of placements across every paint layer in `ctx.paint_layers` whose
## `element` matches. A population layer calls this; if it returns non-empty,
## the layer places there instead of its default ring. Empty → default behaviour.
## Artifact-layers are skipped (object_scatter handles those).
static func placements_for(ctx: Dictionary, element: String) -> Array:
	var out: Array = []
	var layers = ctx.get("paint_layers", [])
	if not (layers is Array):
		return out
	var dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube: float = float(ctx.get("cube_size", 1.0))
	var base: int = int(ctx.get("rng_seed", 0))
	var budget: float = float(ctx.get("budget_scale", 1.0))
	var idx: int = 0
	for layer in layers:
		if not (layer is Dictionary):
			continue
		if str(layer.get("element", "")) != element:
			continue
		# An artifacts-layer (carries an explicit artifact list) is placed by
		# object_scatter, not the default morphology — skip it here so we don't
		# double-populate. has_layer_for still sees it (suppresses the ring).
		if is_artifact_layer(layer):
			continue
		out.append_array(placements(layer, dims.x, dims.z, cube, base + idx * 131 + 7, budget))
		idx += 1
	if out.size() <= 1:
		return out
	# Sequence accrual UNIONS same-element layers (a map builds on the maps before
	# it), so the same high-density cells get placed many times and a long sequence
	# would multiply the organism count without bound — the VR draw-call cliff.
	# Collapse to one placement per grid cell, then cap the ELEMENT TOTAL (not each
	# layer). See doc/PAINT_LAYERS.md § Sequence accrual.
	out = _dedupe_by_cell(out, cube)
	var union_cap: int = maxi(1, int(round(float(ctx.get("union_max", DEFAULT_MAX)) * clampf(budget, 0.05, 1.0))))
	if out.size() > union_cap:
		var rng := RandomNumberGenerator.new()
		rng.seed = base + 99
		_shuffle(out, rng)
		out.resize(union_cap)
	return out


## Collapse placements that land in the same grid cell to one (keep the first).
## Stacked same-element layers from accrual otherwise pile many organisms on the
## same high-density cells — wasted budget + z-fighting clumps.
static func _dedupe_by_cell(pts: Array, cube: float) -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	for p in pts:
		var key := Vector2i(int(floor(p.x / cube)), int(floor(p.z / cube)))
		if not seen.has(key):
			seen[key] = true
			out.append(p)
	return out


## True if the map authored at least one paint layer for `element` — lets a
## layer decide to suppress its default ring even if the field placed nothing.
static func has_layer_for(ctx: Dictionary, element: String) -> bool:
	var layers = ctx.get("paint_layers", [])
	if not (layers is Array):
		return false
	for layer in layers:
		if layer is Dictionary and str(layer.get("element", "")) == element:
			return true
	return false


# ── internals ─────────────────────────────────────────────────────────
static func _curve_t(axis: String, x: int, z: int, grid_w: int, grid_d: int) -> float:
	# Returns 0 at centre/start → 1 at edge/end.
	match axis:
		"x":
			return float(x) / maxf(1.0, float(grid_w - 1))
		"z":
			return float(z) / maxf(1.0, float(grid_d - 1))
		_:
			var cx: float = float(grid_w - 1) * 0.5
			var cz: float = float(grid_d - 1) * 0.5
			var dx: float = (float(x) - cx) / maxf(1.0, cx)
			var dz: float = (float(z) - cz) / maxf(1.0, cz)
			return clampf(sqrt(dx * dx + dz * dz), 0.0, 1.0)


static func _shape(falloff: String, t: float) -> float:
	# t in [0,1]; returns a weight. Default "smooth" = dome, high in the centre.
	match falloff:
		"linear":
			return 1.0 - t
		"sharp":
			return pow(1.0 - t, 2.0)
		"ring":
			return 1.0 - absf(t - 0.5) * 2.0   # peak at the mid-band
		_:
			return smoothstep(0.0, 1.0, 1.0 - t)


## Hand-painted brush mask → a compact, git-friendly sparse form: only the painted
## cells, not a dense grid_w×grid_d array of mostly-zeros. {w, d, cells:[[x,z,v]…]}.
static func field_to_sparse(field: PackedFloat32Array, grid_w: int, grid_d: int, eps: float = 0.01) -> Dictionary:
	var cells: Array = []
	for z in grid_d:
		for x in grid_w:
			var i: int = z * grid_w + x
			var v: float = field[i] if i < field.size() else 0.0
			if v > eps:
				cells.append([x, z, snappedf(v, 0.01)])
	return {"w": grid_w, "d": grid_d, "cells": cells}


## Sparse {w,d,cells} → dense 2D rows, so the resample path below handles it.
static func _sparse_to_rows(spec: Dictionary) -> Array:
	var w: int = int(spec.get("w", spec.get("brush_w", 0)))
	var d: int = int(spec.get("d", spec.get("brush_d", 0)))
	var rows: Array = []
	for z in d:
		var row: Array = []
		row.resize(w)
		row.fill(0.0)
		rows.append(row)
	for c in spec.get("cells", []):
		if c is Array and (c as Array).size() >= 3:
			var x: int = int(c[0]); var z: int = int(c[1])
			if z >= 0 and z < d and x >= 0 and x < w:
				rows[z][x] = float(c[2])
	return rows


static func _read_brush(brush, field: PackedFloat32Array, grid_w: int, grid_d: int, density: float) -> void:
	# brush may be a sparse {w,d,cells} dict (new, compact), a 2D array (rows), or a
	# flat array. A mask whose native size differs from the target grid (e.g. an
	# earlier sequence map's stroke blooming on THIS map's grid — see
	# sequence_accrual.gd) is bilinear-resampled. Same size = crisp direct copy.
	if brush is Dictionary and brush.has("cells"):
		brush = _sparse_to_rows(brush)
	if brush is Array and brush.size() > 0 and brush[0] is Array:
		var bd: int = brush.size()
		var bw: int = (brush[0] as Array).size()
		if bw <= 0:
			return
		if bw == grid_w and bd == grid_d:
			for z in grid_d:
				var row = brush[z]
				if row is Array:
					for x in mini(grid_w, row.size()):
						field[z * grid_w + x] = density * clampf(float(row[x]), 0.0, 1.0)
		else:
			for z in grid_d:
				var v: float = (float(z) + 0.5) / float(grid_d)
				for x in grid_w:
					var u: float = (float(x) + 0.5) / float(grid_w)
					field[z * grid_w + x] = density * clampf(_brush_bilinear(brush, bw, bd, u, v), 0.0, 1.0)
	elif brush is Array:
		for i in mini(field.size(), brush.size()):
			field[i] = density * clampf(float(brush[i]), 0.0, 1.0)


static func _brush_bilinear(brush: Array, bw: int, bd: int, u: float, v: float) -> float:
	var fx: float = clampf(u * float(bw) - 0.5, 0.0, float(bw - 1))
	var fz: float = clampf(v * float(bd) - 0.5, 0.0, float(bd - 1))
	var x0: int = int(floor(fx)); var z0: int = int(floor(fz))
	var x1: int = mini(x0 + 1, bw - 1); var z1: int = mini(z0 + 1, bd - 1)
	var tx: float = fx - float(x0); var tz: float = fz - float(z0)
	return lerpf(lerpf(_brush_cell(brush, x0, z0), _brush_cell(brush, x1, z0), tx),
				 lerpf(_brush_cell(brush, x0, z1), _brush_cell(brush, x1, z1), tx), tz)


static func _brush_cell(brush: Array, x: int, z: int) -> float:
	if z < 0 or z >= brush.size():
		return 0.0
	var row = brush[z]
	if not (row is Array) or x < 0 or x >= row.size():
		return 0.0
	return clampf(float(row[x]), 0.0, 1.0)


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
