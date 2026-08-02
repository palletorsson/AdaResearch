extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MandelbrotBench

## @identity
## The Mandelbrot set on a panel: one question — does z -> z² + c stay bounded? — asked of
## every point c in the plane. Truth: "z -> z² + c, asked of every point". The black body is
## where the iteration never escapes; the burning fringe is where it almost does, and that edge
## is infinitely intricate.

@export var grid: int = 72
@export var max_iter: int = 70
@export var panel_size: float = 0.7
@export var sway: bool = true

## AXIS — WHAT THE BENCH PUTS ON SHOW OF THE LADDER OF DEPTHS.
##
## A fractal is a rule with no last step, so anything a bench can physically hold is one rung cut
## out of an infinite climb. Here the rung is `max_iter`: the black body is not the Mandelbrot
## set, it is every point that had not escaped BY SEVENTY, and at seven hundred some of it would
## be gone. `max_iter` picks WHICH rung. This axis is the different question of whether the bench
## admits there were others — whether it presents a finished object or an interrupted procedure.
##
## Shared word for word with [[fractal_arch_bench]], [[sierpinski_bench]] and [[julia_bench]].
## Those four were built as one family — same base class, same 1.1 m bench body, same 0.7 m
## panel at 1.25 m, same billboard caption, six placements each — and they duplicate one
## another's helper code verbatim (this file's `_field` and sierpinski_bench's are the same
## twenty lines). One vocabulary, so a fractals room reads as an argument, not four props.
##
##   figure   one rung, the deepest — the intricate fringe at 70 iterations, presented as a
##            finished object. The legacy lineage, byte for byte.
##   series   the whole climb tiled 3 x 2 across the panel: a bald disc at 4 iterations, then 6,
##            10, 15, 32, and the familiar figure last. Six pictures of the same question.
##   seed     the first rung only, at full panel size — a fat black body ringed by three or four
##            hard colour bands, because at four iterations only the far field has escaped and
##            everything else is still 'bounded'. The rule stated, the result withheld.
##   relief   every rung at once and INTERIORS ONLY: six nested silhouettes, each a solid plate
##            on its own plane stepping toward the viewer, the fat 4-iteration one furthest back
##            and darkest. You see the set being whittled down toward a limit it never reaches.
##   section  ONE panel cut across the ladder: the iteration budget steps up in six vertical
##            bands, 4 at the left edge to 70 at the right, with a lit hairline on every seam.
##            The same fringe, six depths, in one frame.
##
## This bench and [[julia_bench]] are the strongest subjects of the four: the panel is the only
## saturated, emissive thing in the frame, so the hottest pixels ARE the picture and every value
## rewrites all of them.
@export var ladder: String = "figure"  # figure | series | seed | relief | section
const LADDERS: PackedStringArray = ["figure", "series", "seed", "relief", "section"]

const X_MIN: float = -2.2
const X_MAX: float = 0.8
const Y_MIN: float = -1.5
const Y_MAX: float = 1.5

var _panel: Node3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = int(config["grid"])
	if config.has("max_iter"):
		max_iter = maxi(int(config["max_iter"]), 2)
	if config.has("ladder"):
		var _l: String = str(config["ladder"]).strip_edges().to_lower()
		ladder = _l if LADDERS.has(_l) else ladder
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_build_bench()
	add_child(_mandel_field())
	add_child(_billboard_label("z -> z² + c", Vector3(0.0, 1.6, 0.0), 22, Color(1.0, 0.7, 0.35)))

	# LADDER dressing, appended LAST so every child index and position above is untouched on the
	# legacy path. "figure" falls through and adds nothing at all.
	#
	# The legacy panel is not deleted, it is MUTED: layers = 0 takes it off every camera while
	# leaving it in the tree. The capture rig fits its frame to the merged AABB of every
	# MeshInstance3D it can find, so all five values frame at exactly the same distance and the
	# critic measures the picture rather than the zoom.
	if ladder != "figure":
		if _panel != null:
			_mute(_panel)
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
	# Backing frame for the fractal panel.
	add_child(_box(Vector3(0.0, 1.25, -0.02), Vector3(panel_size + 0.06, panel_size + 0.06, 0.02), _matte_mat(Color(0.08, 0.08, 0.1), 0.6)))


func _mandel_field() -> MultiMeshInstance3D:
	var g: int = clampi(grid, 16, 96)
	var n: int = g * g
	var mi := _field(n, true)
	var mm: MultiMesh = mi.multimesh
	var cell: float = panel_size / float(g)
	var s: float = cell * 0.96
	var base_y: float = 1.25
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var cx: float = X_MIN + (X_MAX - X_MIN) * (float(gx) + 0.5) / float(g)
			var cy: float = Y_MIN + (Y_MAX - Y_MIN) * (float(gy) + 0.5) / float(g)
			var esc: int = _escape(cx, cy)
			var col: Color = _color_for(esc)
			var px: float = -panel_size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = base_y - panel_size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)), Vector3(px, py, 0.0)))
			mm.set_instance_color(i, col)
			i += 1
	_panel = mi
	return mi


# Both of these now take the rung as an argument so the LADDER values can ask the same question
# at a different budget. The no-argument forms delegate at `max_iter`, which is exactly what
# every legacy caller passed implicitly — same arithmetic, same output.
func _escape(cx: float, cy: float) -> int:
	return _escape_n(cx, cy, max_iter)


func _escape_n(cx: float, cy: float, iters: int) -> int:
	var zr: float = 0.0
	var zi: float = 0.0
	var it: int = 0
	while it < iters:
		# z = z*z + c ; (a+bi)^2 = (a^2 - b^2) + (2ab)i
		var nzr: float = zr * zr - zi * zi + cx
		var nzi: float = 2.0 * zr * zi + cy
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
		return Color(0.02, 0.02, 0.05)
	var t: float = float(esc) / float(maxi(iters, 1))
	# Warm ramp: deep purple -> red -> orange -> pale yellow as escape gets faster -> slower.
	if t < 0.33:
		return Color(0.25, 0.0, 0.35).lerp(Color(0.9, 0.15, 0.1), t / 0.33)
	elif t < 0.66:
		return Color(0.9, 0.15, 0.1).lerp(Color(1.0, 0.6, 0.1), (t - 0.33) / 0.33)
	else:
		return Color(1.0, 0.6, 0.1).lerp(Color(1.0, 0.95, 0.7), (t - 0.66) / 0.34)


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
	if not sway:
		return
	_t += delta


# ── LADDER ───────────────────────────────────────────────────────────────────
# Every rung this bench can climb, coarse first, ending on the working budget. Nothing here
# draws at random: the escape test is arithmetic, so two captures of one value are one picture.

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
# on (cx, cy). Same cell shape and same warm ramp the legacy panel uses, only the budget moves.
func _panel_at(cx: float, cy: float, size: float, g: int, iters: int, z: float) -> MultiMeshInstance3D:
	var gg: int = clampi(g, 8, 96)
	var mi: MultiMeshInstance3D = _field(gg * gg, true)
	var mm: MultiMesh = mi.multimesh
	var cell: float = size / float(gg)
	var s: float = cell * 0.96
	var i: int = 0
	for gy in range(gg):
		for gx in range(gg):
			var mx: float = X_MIN + (X_MAX - X_MIN) * (float(gx) + 0.5) / float(gg)
			var my: float = Y_MIN + (Y_MAX - Y_MIN) * (float(gy) + 0.5) / float(gg)
			var esc: int = _escape_n(mx, my, iters)
			var px: float = cx - size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = cy - size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)),
				Vector3(px, py, z)))
			mm.set_instance_color(i, _color_for_n(esc, iters))
			i += 1
	return mi


# The INTERIOR at a given budget and nothing else — every point that had not escaped yet, as one
# flat silhouette. Used by `relief`, where the silhouettes nest: whatever survives 70 iterations
# survived 3, so the plates stack without hiding one another.
func _shell(cx: float, cy: float, size: float, g: int, iters: int, z: float, tint: Color) -> MultiMeshInstance3D:
	var gg: int = clampi(g, 8, 96)
	var cell: float = size / float(gg)
	var pts: Array = []
	for gy in range(gg):
		for gx in range(gg):
			var mx: float = X_MIN + (X_MAX - X_MIN) * (float(gx) + 0.5) / float(gg)
			var my: float = Y_MIN + (Y_MAX - Y_MIN) * (float(gy) + 0.5) / float(gg)
			if _escape_n(mx, my, iters) >= iters:
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
## 3 x 2 block, 3 iterations at the top left through 70 at the bottom right. The first two tiles
## are bald blobs; the fringe only grows teeth in the last two. The rule caught mid-argument.
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
## far field to escape, so most of the panel goes to the dead black of "still bounded", ringed by
## three or four hard colour bands out at the left where |c| was already too large. The question
## asked, and cut off before it has said anything.
func _ladder_seed() -> void:
	var rungs: PackedInt32Array = _rungs()
	add_child(_panel_at(0.0, 1.25, panel_size, clampi(grid, 16, 96), rungs[0], 0.0))


## RELIEF — six interiors, one per rung, stacked out of the frame toward the viewer: the fat
## 4-iteration blob furthest back and nearly black, the true fringe at the front and pale. The
## set is visibly being whittled toward a limit, and every intermediate stage is still standing
## there behind it. All scales present, none of them the fractal.
func _ladder_relief() -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var last: float = maxf(float(n - 1), 1.0)
	var g: int = clampi(grid, 16, 96)
	for i in range(n):
		var f: float = float(i) / last
		var tint: Color = Color(0.20, 0.04, 0.26).lerp(Color(1.0, 0.78, 0.35), f)
		add_child(_shell(0.0, 1.25, panel_size, g, rungs[i], 0.004 + 0.023 * float(i), tint))


## SECTION — one panel cut across the ladder. The iteration budget steps up in six vertical
## bands, 4 at the left edge to 70 at the right, so the fringe grows teeth from left to right in
## visible jumps, and a lit hairline stands on every seam. The same picture at six depths,
## side by side, admitting that where you stop is a choice.
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
			var mx: float = X_MIN + (X_MAX - X_MIN) * (float(gx) + 0.5) / float(g)
			var my: float = Y_MIN + (Y_MAX - Y_MIN) * (float(gy) + 0.5) / float(g)
			var esc: int = _escape_n(mx, my, iters)
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
			_glow_mat(Color(1.0, 0.88, 0.55), 1.8)))
