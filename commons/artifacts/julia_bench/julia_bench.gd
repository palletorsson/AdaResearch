extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name JuliaBench

## @identity
## A Julia set: the same map z -> z² + c, but now c is fixed and the question is asked of the
## starting point z. Truth: "move c, the set breathes". Nudge c by a hair and the whole figure
## reorganises — connected dust, spirals, dendrites — a one-parameter family of worlds.

@export var c_re: float = -0.4
@export var c_im: float = 0.6
@export var grid: int = 72
@export var max_iter: int = 70
@export var panel_size: float = 0.7
@export var animate_c: bool = true

## AXIS — WHAT THE BENCH PUTS ON SHOW OF THE LADDER OF DEPTHS.
##
## A fractal is a rule with no last step, so anything a bench can physically hold is one rung cut
## out of an infinite climb. Here the rung is `max_iter`: the dark body is not the filled Julia
## set, it is every starting point that had not escaped BY SEVENTY. `max_iter` picks WHICH rung.
## This axis is the different question of whether the bench admits there were others — whether it
## presents a finished object or an interrupted procedure. It is orthogonal to `c`, which the
## bench already drifts: c chooses WHICH figure, the ladder chooses how much of it you are shown.
##
## Shared word for word with [[fractal_arch_bench]], [[sierpinski_bench]] and [[mandelbrot_bench]].
## Those four were built as one family — same base class, same 1.1 m bench body, same 0.7 m panel
## at 1.25 m, same billboard caption, six placements each — and they duplicate one another's
## helper code verbatim (this file's `_field` and mandelbrot_bench's are the same twenty lines).
## One vocabulary, so a fractals room reads as an argument and not as four unrelated props.
##
##   figure   one rung, the deepest — the dendrite at 70 iterations, presented as a finished
##            object. The legacy lineage, byte for byte, drift and all.
##   series   the whole climb tiled 3 x 2 across the panel: a fat rounded blob at 4 iterations,
##            then 6, 10, 15, 32, and the familiar dendrite last. The same c, six budgets.
##   seed     the first rung only, at full panel size — the dark body swollen out to the corners
##            with a hard colour band at each corner, because at four iterations only the far
##            field has escaped. The rule stated, the result withheld.
##   relief   every rung at once and INTERIORS ONLY: six nested silhouettes, each a solid plate
##            on its own plane stepping toward the viewer, the fat early one furthest back and
##            darkest, the true dendrite pale at the front. The set whittled toward a limit.
##   section  ONE panel cut across the ladder: the iteration budget steps up in six vertical
##            bands, 4 at the left edge to 70 at the right, with a lit hairline on every seam.
##            The dendrite grows its filaments left to right, in visible jumps.
##
## Every value except `figure` also FREEZES c (see _process): a variant that both drifts and
## re-cuts would be two axes in one frame, and the sweep could not say which one it measured.
@export var ladder: String = "figure"  # figure | series | seed | relief | section
const LADDERS: PackedStringArray = ["figure", "series", "seed", "relief", "section"]

const VIEW: float = 1.6

var _mm_inst: MultiMeshInstance3D
var _readout: Label3D
var _t: float = 0.0
var _base_re: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_base_re = c_re
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("c_re"):
		c_re = float(config["c_re"])
	if config.has("c_im"):
		c_im = float(config["c_im"])
	if config.has("max_iter"):
		max_iter = maxi(int(config["max_iter"]), 2)
	# Exposed so a still-capture fixture can pin c and photograph the LADDER on its own. The
	# default stays true, so a map that says nothing gets today's breathing bench.
	if config.has("animate_c"):
		animate_c = bool(config["animate_c"])
	if config.has("ladder"):
		var _l: String = str(config["ladder"]).strip_edges().to_lower()
		ladder = _l if LADDERS.has(_l) else ladder
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_base_re = c_re
	_build()


func _build() -> void:
	_build_bench()
	_mm_inst = _julia_field()
	add_child(_mm_inst)
	add_child(_billboard_label("MOVE c, THE SET BREATHES", Vector3(0.0, 1.6, 0.0), 20, Color(0.6, 0.85, 1.0)))
	_readout = _billboard_label(_c_text(), Vector3(0.0, 0.95, 0.0), 14, Color(0.8, 0.9, 1.0))
	add_child(_readout)

	# LADDER dressing, appended LAST so every child index and position above is untouched on the
	# legacy path. "figure" falls through and adds nothing at all.
	#
	# The legacy panel is not deleted, it is MUTED: layers = 0 takes it off every camera while
	# leaving it in the tree. The capture rig fits its frame to the merged AABB of every
	# MeshInstance3D it can find, so all five values frame at exactly the same distance and the
	# critic measures the picture rather than the zoom.
	if ladder != "figure":
		if _mm_inst != null:
			_mute(_mm_inst)
		match ladder:
			"series":
				_ladder_series()
			"seed":
				_ladder_seed()
			"relief":
				_ladder_relief()
			"section":
				_ladder_section()
			_:
				pass


func _build_bench() -> void:
	var top_mat := _matte_mat(Color(0.16, 0.18, 0.22), 0.7, 0.1)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.08, 0.45), top_mat))
	var leg_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_box(Vector3(-0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.0, 1.25, -0.02), Vector3(panel_size + 0.06, panel_size + 0.06, 0.02), _matte_mat(Color(0.08, 0.08, 0.1), 0.6)))


func _c_text() -> String:
	return "c = %+.2f %+.2fi" % [c_re, c_im]


func _julia_field() -> MultiMeshInstance3D:
	var g: int = clampi(grid, 16, 96)
	var n: int = g * g
	var mi := _field(n, true)
	_fill_julia(mi.multimesh, g)
	return mi


func _fill_julia(mm: MultiMesh, g: int) -> void:
	var cell: float = panel_size / float(g)
	var s: float = cell * 0.96
	var base_y: float = 1.25
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var zr: float = -VIEW + 2.0 * VIEW * (float(gx) + 0.5) / float(g)
			var zi: float = -VIEW + 2.0 * VIEW * (float(gy) + 0.5) / float(g)
			var esc: int = _escape(zr, zi)
			var col: Color = _color_for(esc)
			var px: float = -panel_size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = base_y - panel_size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)), Vector3(px, py, 0.0)))
			mm.set_instance_color(i, col)
			i += 1


# Both of these now take the rung as an argument so the LADDER values can ask the same question
# at a different budget. The no-argument forms delegate at `max_iter`, which is exactly what
# every legacy caller passed implicitly — same arithmetic, same output.
func _escape(zr0: float, zi0: float) -> int:
	return _escape_n(zr0, zi0, max_iter)


func _escape_n(zr0: float, zi0: float, iters: int) -> int:
	var zr: float = zr0
	var zi: float = zi0
	var it: int = 0
	while it < iters:
		var nzr: float = zr * zr - zi * zi + c_re
		var nzi: float = 2.0 * zr * zi + c_im
		zr = nzr
		zi = nzi
		if zr * zr + zi * zi > 4.0:
			break
		it += 1
	return it


func _color_for(esc: int) -> Color:
	return _color_for_n(esc, max_iter)


func _color_for_n(esc: int, iters: int) -> Color:
	if esc >= iters:
		return Color(0.02, 0.03, 0.08)
	var t: float = float(esc) / float(maxi(iters, 1))
	# Cool ramp: deep blue -> cyan -> teal -> pale, evoking the "breathing" Julia palette.
	if t < 0.33:
		return Color(0.05, 0.0, 0.3).lerp(Color(0.1, 0.3, 0.9), t / 0.33)
	elif t < 0.66:
		return Color(0.1, 0.3, 0.9).lerp(Color(0.2, 0.85, 0.85), (t - 0.33) / 0.33)
	else:
		return Color(0.2, 0.85, 0.85).lerp(Color(0.85, 1.0, 0.95), (t - 0.66) / 0.34)


func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Any LADDER value but the legacy one holds c still. The drift rebuilds ONE panel from ONE
	# pair of c values every frame; the other values put six panels on the board or cut one panel
	# into six budgets, and a drift that only touched the first of them would be a lie. Freezing
	# also keeps the axis alone in the frame — see the note on the export.
	if ladder != "figure":
		return
	if not animate_c:
		return
	_t += delta
	# Slowly orbit c so the set visibly breathes; rebuild the grid at a modest cadence.
	c_re = _base_re + 0.12 * sin(_t * 0.35)
	c_im = 0.6 + 0.08 * cos(_t * 0.3)
	if _mm_inst != null and _mm_inst.multimesh != null:
		var g: int = clampi(grid, 16, 96)
		_fill_julia(_mm_inst.multimesh, g)
	if _readout != null:
		_readout.text = _c_text()


# ── LADDER ───────────────────────────────────────────────────────────────────
# Every rung this bench can climb, coarse first, ending on the working budget. Nothing here
# draws at random: the escape test is arithmetic and c is held still, so two captures of one
# value are one picture.

func _rungs() -> PackedInt32Array:
	var top: int = maxi(max_iter, 8)
	var out := PackedInt32Array()
	for f in [0.06, 0.09, 0.14, 0.22, 0.45, 1.0]:
		var v: int = maxi(int(round(float(top) * float(f))), 2)
		if out.is_empty() or v > out[out.size() - 1]:
			out.append(v)
	return out


# Take a subtree off every camera without freeing it — see the note in _build().
func _mute(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 0
	for c in n.get_children():
		_mute(c)


# One escape-time panel over the standard window, cut at `iters`, `size` metres square, centred
# on (cx, cy). Same cell shape and same cool ramp the legacy panel uses; only the budget moves.
func _panel_at(cx: float, cy: float, size: float, g: int, iters: int, z: float) -> MultiMeshInstance3D:
	var gg: int = clampi(g, 8, 96)
	var mi: MultiMeshInstance3D = _field(gg * gg, true)
	var mm: MultiMesh = mi.multimesh
	var cell: float = size / float(gg)
	var s: float = cell * 0.96
	var i: int = 0
	for gy in range(gg):
		for gx in range(gg):
			var zr: float = -VIEW + 2.0 * VIEW * (float(gx) + 0.5) / float(gg)
			var zi: float = -VIEW + 2.0 * VIEW * (float(gy) + 0.5) / float(gg)
			var esc: int = _escape_n(zr, zi, iters)
			var px: float = cx - size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = cy - size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)),
				Vector3(px, py, z)))
			mm.set_instance_color(i, _color_for_n(esc, iters))
			i += 1
	return mi


# The INTERIOR at a given budget and nothing else — every starting point that had not escaped
# yet, as one flat silhouette. Used by `relief`, where the silhouettes nest: whatever survives 70
# iterations survived 4, so the plates stack without hiding one another.
func _shell(cx: float, cy: float, size: float, g: int, iters: int, z: float, tint: Color) -> MultiMeshInstance3D:
	var gg: int = clampi(g, 8, 96)
	var cell: float = size / float(gg)
	var pts: Array = []
	for gy in range(gg):
		for gx in range(gg):
			var zr: float = -VIEW + 2.0 * VIEW * (float(gx) + 0.5) / float(gg)
			var zi: float = -VIEW + 2.0 * VIEW * (float(gy) + 0.5) / float(gg)
			if _escape_n(zr, zi, iters) >= iters:
				pts.append(Vector2(cx - size * 0.5 + (float(gx) + 0.5) * cell,
					cy - size * 0.5 + (float(gy) + 0.5) * cell))
	var mi: MultiMeshInstance3D = _field(pts.size(), true)
	var mm: MultiMesh = mi.multimesh
	var s: float = cell * 0.99
	for i in range(pts.size()):
		var p: Vector2 = pts[i]
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.5)),
			Vector3(p.x, p.y, z)))
		mm.set_instance_color(i, tint)
	return mi


## SERIES — the panel stops holding one answer and holds the whole climb: six small panels in a
## 3 x 2 block at one fixed c, 4 iterations at the top left through 70 at the bottom right. The
## first tiles are rounded blobs; the dendrite only grows filaments in the last two.
func _ladder_series() -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var cols: int = 3
	var rows: int = int(ceil(float(n) / float(cols)))
	var pitch_x: float = panel_size / float(cols)
	var pitch_y: float = panel_size / float(maxi(rows, 1))
	var tile: float = minf(pitch_x, pitch_y) * 0.90
	for i in range(n):
		var row: int = i / cols
		var col: int = i % cols
		var in_row: int = mini(cols, n - row * cols)
		var tx: float = (float(col) - (float(in_row) - 1.0) * 0.5) * pitch_x
		var ty: float = 1.25 + ((float(rows) - 1.0) * 0.5 - float(row)) * pitch_y
		add_child(_panel_at(tx, ty, tile, 30, rungs[i], 0.0))


## SEED — the first rung at full panel size. Four iterations is not enough for anything but the
## far corners to escape, so the dark body swells out to fill the panel with a hard colour band
## at each corner. The question asked, and cut off before it has said anything.
func _ladder_seed() -> void:
	var rungs: PackedInt32Array = _rungs()
	add_child(_panel_at(0.0, 1.25, panel_size, clampi(grid, 16, 96), rungs[0], 0.0))


## RELIEF — six interiors, one per rung, stacked out of the frame toward the viewer: the fat
## 4-iteration blob furthest back and nearly black, the true dendrite pale at the front. The set
## is visibly being whittled toward a limit, with every intermediate stage still standing behind
## it. All scales present at once, none of them the fractal.
func _ladder_relief() -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var last: float = maxf(float(n - 1), 1.0)
	var g: int = clampi(grid, 16, 96)
	for i in range(n):
		var f: float = float(i) / last
		var tint: Color = Color(0.04, 0.06, 0.26).lerp(Color(0.55, 1.0, 0.95), f)
		add_child(_shell(0.0, 1.25, panel_size, g, rungs[i], 0.004 + 0.023 * float(i), tint))


## SECTION — one panel cut across the ladder. The iteration budget steps up in six vertical
## bands, 4 at the left edge to 70 at the right, so the dendrite grows its filaments from left to
## right in visible jumps, and a lit hairline stands on every seam. One figure, six depths,
## admitting that where you stop is a choice and not a fact about the set.
func _ladder_section() -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var g: int = clampi(grid, 16, 96)
	var mi: MultiMeshInstance3D = _field(g * g, true)
	var mm: MultiMesh = mi.multimesh
	var cell: float = panel_size / float(g)
	var s: float = cell * 0.96
	var base_y: float = 1.25
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var band: int = clampi(int(float(gx) * float(n) / float(g)), 0, n - 1)
			var iters: int = rungs[band]
			var zr: float = -VIEW + 2.0 * VIEW * (float(gx) + 0.5) / float(g)
			var zi: float = -VIEW + 2.0 * VIEW * (float(gy) + 0.5) / float(g)
			var esc: int = _escape_n(zr, zi, iters)
			var px: float = -panel_size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = base_y - panel_size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)),
				Vector3(px, py, 0.0)))
			mm.set_instance_color(i, _color_for_n(esc, iters))
			i += 1
	add_child(mi)
	for b in range(1, n):
		var sx: float = -panel_size * 0.5 + panel_size * float(b) / float(n)
		add_child(_box(Vector3(sx, base_y, 0.03), Vector3(0.005, panel_size, 0.005),
			_glow_mat(Color(0.65, 0.95, 1.0), 1.8)))
