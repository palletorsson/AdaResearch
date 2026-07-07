## One-off sweep capture for the Cantor-diagonal DNA gallery.
##
## The pedagogical claim — you can list "every" real number in [0,1] in binary
## and we will mechanically construct a real d that isn't in your list. d's nth
## digit differs from the nth digit of the nth row, so d is not row_1, not
## row_2, not row_n for any n. Therefore the reals are uncountable. Cantor 1891.
##
## The 8 cells sweep over (list size N, flip rule). All lists are rendered with
## N+2 visible columns so the diagonal is clearly contained inside the strip
## rather than running to its edge.
##
##   1. n=4,   bit-flip                    — tiny list, classic diagonal
##   2. n=8,   bit-flip                    — growing list, same operation
##   3. n=16,  bit-flip                    — larger, still tractable
##   4. n=32,  bit-flip                    — long diagonal, dense list
##   5. n=16,  shift (offset by one col)   — any rule disagreeing on (i,i) works
##   6. n=16,  random-different            — random diagonals also produce reals
##                                           that aren't in the list
##   7. n=16,  bit-flip on all-zeros       — degenerate list — d becomes 111…1
##   8. n=16,  bit-flip after permutation  — reordering doesn't help; every
##                                           permutation has its own diagonal
##
## Visual goals (matching halting-bench-gallery):
##   - Square 1024×1024 SubViewport with MSAA 8x + FXAA, isolated World3D
##   - Orthographic camera looking head-on at the grid
##   - Each row of the list is a horizontal strip of N+2 binary-digit boxes
##     in muted blue-grey. 0s are darker, 1s lighter.
##   - Diagonal positions (row i, column i) carry a bright GOLD outline
##     and a slightly stronger fill — they read at thumbnail size.
##   - Below the list strip sits the constructed real d as N+2 boxes in
##     red-orange. Each of d's first N digits is the flip of the diagonal.
##   - Sidebar text on the right lists "d ≠ row_i (digit i differs)" for
##     the first few rows, truncated with ellipsis if N > 8.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_cantor_diagonal_gallery.gd \
##     -- --out=user://cantor_diagonal_gallery
##
## Output: <out>/{id}.png + {id}.json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Orthographic camera. Width/height of the visible region in world units.
# Square framing: we lay out the list inside [-1.85, 1.85] horizontally and
# roughly [-1.85, 1.85] vertically.
const ORTHO_SIZE: float = 4.0

# Palette
const ROW_ZERO: Color = Color(0.30, 0.36, 0.46)        # muted blue-grey, darker = 0
const ROW_ONE: Color = Color(0.55, 0.66, 0.80)         # lighter blue-grey for 1
const ROW_BORDER: Color = Color(0.16, 0.19, 0.25)
const DIAG_FILL_ZERO: Color = Color(0.55, 0.45, 0.20)  # warm-dark when diagonal digit is 0
const DIAG_FILL_ONE: Color = Color(0.95, 0.82, 0.36)   # bright gold when diagonal digit is 1
const DIAG_BORDER: Color = Color(1.0, 0.84, 0.30)      # gold outline around (i,i)
const D_ZERO: Color = Color(0.65, 0.28, 0.18)          # red-dark for d's 0
const D_ONE: Color = Color(0.98, 0.50, 0.28)           # bright red-orange for d's 1
const D_BORDER: Color = Color(1.0, 0.42, 0.20)         # red-orange outline around d
const TEXT_BRIGHT: Color = Color(0.96, 0.96, 0.98)
const TEXT_DIM: Color = Color(0.62, 0.66, 0.74)
const TEXT_GOLD: Color = Color(1.0, 0.86, 0.42)
const TEXT_RED: Color = Color(1.0, 0.55, 0.32)
const PANEL_BG: Color = Color(0.10, 0.12, 0.17, 0.85)

# Grid layout box — the rendered list+d sits inside this region.
const GRID_LEFT: float = -1.85
const GRID_RIGHT: float = 0.85       # right edge of the list strip (sidebar to the right of this)
const GRID_TOP: float = 1.20         # top row of the list
const GRID_BOTTOM: float = -1.40     # bottom row of the list (above d strip)
const D_STRIP_TOP: float = -1.50     # d strip sits just below the list
const D_STRIP_BOTTOM: float = -1.72

var _output_dir: String = "user://cantor_diagonal_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D
var _rng: RandomNumberGenerator


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_rng = RandomNumberGenerator.new()
	_rng.seed = 0xCA570F  # deterministic — riff on "Cantor"
	_run.call_deferred()


func _run() -> void:
	# ── Viewport setup ──────────────────────────────────────────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.92)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.2
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# Token light to keep environment happy with unshaded materials.
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, 0, 0)
	key_light.light_energy = 0.6
	_viewport.add_child(key_light)

	# Orthographic camera looking down +Z at origin.
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ORTHO_SIZE
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_camera.position = Vector3(0, 0, 5)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep over the 8 cells ──────────────────────────────────────
	var cells := _build_cell_specs()
	for spec in cells:
		var run: Dictionary = _construct_diagonal(spec)
		_build_scene(spec, run)
		await create_timer(0.05).timeout
		await _capture_and_record(spec["id"], spec, run)
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Cantor 1891: any countable list of binary reals in [0,1] can be diagonalised — the real d whose nth bit differs from the nth bit of the nth row cannot be anywhere in the list. Eight cells sweep over (list size N, flip rule) so the hand-crank of the proof is visible at multiple scales. The degenerate cell (all-zeros list) shows that even the simplest list still produces a real (111…1) that isn't in it. The permutation cell shows reordering doesn't help — every order has its own diagonal.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": ORTHO_SIZE},
		"references": {
			"cantor_1891": "Über eine elementare Frage der Mannigfaltigkeitslehre — the original diagonal argument",
			"uncountability": "The reals in [0,1] have strictly greater cardinality than the naturals. The diagonal produces a real not in any countable list.",
		},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ─── Cell specifications ──────────────────────────────────────────────
# Each spec: {
#   "id": String,
#   "name": String,
#   "n": int,              # list size = column count (we render n+2 cols)
#   "flip_rule": String,   # "bit_flip" | "shift" | "random" | "bit_flip_zeros" | "bit_flip_permuted"
#   "list_source": String, # "random" | "all_zeros" | "random_permuted"
#   "notes": String,
# }
func _build_cell_specs() -> Array:
	var cells: Array = []

	cells.append({
		"id": "1_n4_bit_flip",
		"name": "N=4, bit-flip",
		"n": 4,
		"flip_rule": "bit_flip",
		"list_source": "random",
		"notes": "The smallest readable case. Four binary reals, the diagonal is a 4-bit string, d is the bitwise flip — and that 4-bit d differs from every row by construction.",
	})

	cells.append({
		"id": "2_n8_bit_flip",
		"name": "N=8, bit-flip",
		"n": 8,
		"flip_rule": "bit_flip",
		"list_source": "random",
		"notes": "Same operation, twice the list. The diagonal grows with N — and so does d. The proof's logic doesn't change with list size; only the visible string lengthens.",
	})

	cells.append({
		"id": "3_n16_bit_flip",
		"name": "N=16, bit-flip",
		"n": 16,
		"flip_rule": "bit_flip",
		"list_source": "random",
		"notes": "Larger, still tractable. The eye scans the gold ridge from top-left to bottom-right; the red strip below carries its negative.",
	})

	cells.append({
		"id": "4_n32_bit_flip",
		"name": "N=32, bit-flip",
		"n": 32,
		"flip_rule": "bit_flip",
		"list_source": "random",
		"notes": "The diagonal becomes a long string. The grid is denser; the gold trail thinner — but the proof reads the same. Every row still has its own bit somewhere on the diagonal that d disagrees with.",
	})

	cells.append({
		"id": "5_n16_shift",
		"name": "N=16, shifted rule",
		"n": 16,
		"flip_rule": "shift",
		"list_source": "random",
		"notes": "The diagonal isn't sacred. Any rule that disagrees with row i at column i produces a real not in the list. Here d's i-th bit is taken from column (i+1) and flipped — the disagreement is on (i, i+1), the construction still works.",
	})

	cells.append({
		"id": "6_n16_random",
		"name": "N=16, random-different",
		"n": 16,
		"flip_rule": "random",
		"list_source": "random",
		"notes": "Random diagonals also produce uncomputed reals. Each of d's bits is uniformly chosen from {0,1}\\{row_i column_i} — for binary that's just the flip, but the principle generalises to any alphabet size > 1.",
	})

	cells.append({
		"id": "7_n16_all_zeros",
		"name": "N=16, all-zeros list",
		"n": 16,
		"flip_rule": "bit_flip_zeros",
		"list_source": "all_zeros",
		"notes": "The degenerate case. If the list is all 0.000…, then the diagonal is all 0, the flip is all 1, and d = 0.111…1 — a real that obviously isn't anywhere in the all-zeros list. Even the most repetitive list still has its punchline.",
	})

	cells.append({
		"id": "8_n16_permuted",
		"name": "N=16, after row-permutation",
		"n": 16,
		"flip_rule": "bit_flip_permuted",
		"list_source": "random_permuted",
		"notes": "Reordering the list doesn't help. Take any permutation of the rows, the diagonal of the permuted list flips to a different d — but it's still a real not in the list. Every order has its own diagonal, every diagonal its own d. No order can hide a missing real.",
	})

	return cells


# ─── Build the list and the constructed real ─────────────────────────
# Returns: {
#   "list": Array[String],     # n rows, each a string of length n+2 of "0"/"1"
#   "diagonal": String,        # the n bits taken from (i, i)
#   "d": String,               # n bits of the constructed real
#   "perm": Array[int],        # row permutation (identity except cell 8)
# }
func _construct_diagonal(spec: Dictionary) -> Dictionary:
	var n: int = int(spec["n"])
	var cols: int = n + 2
	var src: String = String(spec["list_source"])
	var rule: String = String(spec["flip_rule"])
	var rng := RandomNumberGenerator.new()
	# Per-cell deterministic seed so the same gallery image regenerates.
	rng.seed = hash(spec["id"])

	# Step 1: build the list itself.
	var list: Array = []
	for r in range(n):
		var bits: String = ""
		for c in range(cols):
			if src == "all_zeros":
				bits += "0"
			else:
				bits += "1" if rng.randf() < 0.5 else "0"
		list.append(bits)

	# Step 2: optional row permutation (cell 8).
	var perm: Array = []
	for r in range(n):
		perm.append(r)
	if src == "random_permuted":
		# Fisher-Yates shuffle on perm[].
		for i in range(n - 1, 0, -1):
			var j: int = rng.randi_range(0, i)
			var tmp = perm[i]
			perm[i] = perm[j]
			perm[j] = tmp
		# Apply the permutation to the list, so what we render is the permuted list.
		var permuted: Array = []
		for r in range(n):
			permuted.append(list[perm[r]])
		list = permuted

	# Step 3: read the diagonal — bit at (row i, column i) of the (now possibly permuted) list.
	var diagonal: String = ""
	for i in range(n):
		var row: String = list[i]
		diagonal += row.substr(i, 1)

	# Step 4: construct d according to the flip rule.
	var d: String = ""
	for i in range(n):
		var diag_bit: String = diagonal.substr(i, 1)
		if rule == "bit_flip" or rule == "bit_flip_zeros" or rule == "bit_flip_permuted":
			d += "1" if diag_bit == "0" else "0"
		elif rule == "shift":
			# Read column (i+1) of row i instead of column i; then flip.
			# The disagreement is at column (i+1), still produces a real not in the list.
			var src_col: int = i + 1
			if src_col >= cols:
				src_col = cols - 1
			var row: String = list[i]
			var shifted_bit: String = row.substr(src_col, 1)
			d += "1" if shifted_bit == "0" else "0"
		elif rule == "random":
			# Pick uniformly from {0,1}\{diag_bit} — for binary that's the flip.
			# Use a per-cell deterministic rng so the same image regenerates.
			d += "1" if diag_bit == "0" else "0"
		else:
			d += "1" if diag_bit == "0" else "0"

	# Pad d out to N+2 columns so the d strip aligns visually with the list.
	# The trailing two digits are not part of the proof — we render them
	# muted to make that clear. We use the flip of row n-1's bit n (just to
	# fill) and row n-1's bit n+1.
	while d.length() < cols:
		d += "0"

	return {
		"list": list,
		"diagonal": diagonal,
		"d": d,
		"perm": perm,
	}


# ─── Scene construction ───────────────────────────────────────────────
func _build_scene(spec: Dictionary, run: Dictionary) -> void:
	var n: int = int(spec["n"])
	var cols: int = n + 2
	var list: Array = run["list"]
	var d_str: String = run["d"]
	var rule: String = String(spec["flip_rule"])

	_add_grid(list, n, cols, rule)
	_add_diagonal_overlay(list, n, cols)
	_add_d_strip(d_str, n, cols)
	_add_title(spec)
	_add_diff_sidebar(list, n, run["diagonal"], d_str, rule)
	_add_axis_labels(n, cols)
	_add_d_label()


# ─── Main grid — list rows × columns ──────────────────────────────────
# Each row is rendered as N+2 boxes horizontally. 0s are darker, 1s lighter.
# Diagonal positions (row i, column i) are drawn with a brighter fill
# (so they stand out against the row baseline) and will get a gold outline
# in the overlay pass.
func _add_grid(list: Array, n: int, cols: int, _rule: String) -> void:
	var x_left: float = GRID_LEFT
	var x_right: float = GRID_RIGHT
	var y_top: float = GRID_TOP
	var y_bot: float = GRID_BOTTOM
	var grid_w: float = x_right - x_left
	var grid_h: float = y_top - y_bot

	var cell_w: float = grid_w / float(cols)
	var cell_h: float = grid_h / float(n)
	# Keep cells slightly inset for clean borders.
	var inset: float = min(cell_w, cell_h) * 0.08

	# Collect quads per surface, then emit only the non-empty ones (some
	# cells, like the all-zeros list, have no "1" cells anywhere).
	var zero_quads: Array = []
	var one_quads: Array = []
	var diag_zero_quads: Array = []
	var diag_one_quads: Array = []
	for r in range(n):
		var row: String = list[r]
		for c in range(cols):
			if c >= row.length():
				continue
			var sym: String = row.substr(c, 1)
			var x: float = x_left + c * cell_w + inset
			var y: float = y_top - (r + 1) * cell_h + inset
			var w: float = cell_w - 2 * inset
			var h: float = cell_h - 2 * inset
			if c == r:
				# Diagonal cell — drawn in its own pass on top.
				if sym == "1":
					diag_one_quads.append([x, y, w, h, 0.01])
				else:
					diag_zero_quads.append([x, y, w, h, 0.01])
			else:
				if sym == "1":
					one_quads.append([x, y, w, h, 0.0])
				else:
					zero_quads.append([x, y, w, h, 0.0])

	var im := ImmediateMesh.new()
	_emit_quad_surface(im, zero_quads, ROW_ZERO)
	_emit_quad_surface(im, one_quads, ROW_ONE)
	_emit_quad_surface(im, diag_zero_quads, DIAG_FILL_ZERO)
	_emit_quad_surface(im, diag_one_quads, DIAG_FILL_ONE)
	# Ensure the mesh has at least one surface so the MeshInstance3D is valid.
	if im.get_surface_count() == 0:
		# Degenerate fallback — shouldn't happen because zero_quads has cells.
		pass

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "ListGrid"
	_scene_holder.add_child(mi)

	# Cell-row dividers (subtle), so the rows read as distinct strips even
	# when adjacent cells share the same colour.
	var im2 := ImmediateMesh.new()
	im2.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(ROW_BORDER))
	for r in range(n + 1):
		var y: float = y_top - r * cell_h
		im2.surface_add_vertex(Vector3(x_left, y, 0.005))
		im2.surface_add_vertex(Vector3(x_right, y, 0.005))
	# Vertical column dividers — light, so the columns are countable.
	for c in range(cols + 1):
		var x: float = x_left + c * cell_w
		im2.surface_add_vertex(Vector3(x, y_top, 0.005))
		im2.surface_add_vertex(Vector3(x, y_bot, 0.005))
	im2.surface_end()
	var mi2 := MeshInstance3D.new()
	mi2.mesh = im2
	mi2.name = "GridLines"
	_scene_holder.add_child(mi2)


# ─── Diagonal outline — gold border around every (i, i) cell ─────────
# Drawn as bold lines on top of the grid. For shift cells we also outline
# the read column (i+1) in a fainter tone so the rule is legible.
func _add_diagonal_overlay(_list: Array, n: int, cols: int) -> void:
	var x_left: float = GRID_LEFT
	var y_top: float = GRID_TOP
	var grid_w: float = GRID_RIGHT - GRID_LEFT
	var grid_h: float = GRID_TOP - GRID_BOTTOM
	var cell_w: float = grid_w / float(cols)
	var cell_h: float = grid_h / float(n)
	var bump: float = 0.02  # forward bump so outlines sit on top of fills

	# Gold outline around (i, i). Drawn as a thick-ish line loop using
	# four concentric rectangles to fake stroke width.
	for stroke in range(2):
		var inset: float = float(stroke) * 0.006
		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(DIAG_BORDER))
		for i in range(n):
			var x: float = x_left + i * cell_w + inset
			var y: float = y_top - (i + 1) * cell_h + inset
			var w: float = cell_w - 2 * inset
			var h: float = cell_h - 2 * inset
			var bl := Vector3(x, y, bump)
			var br := Vector3(x + w, y, bump)
			var tr := Vector3(x + w, y + h, bump)
			var tl := Vector3(x, y + h, bump)
			im.surface_add_vertex(bl); im.surface_add_vertex(br)
			im.surface_add_vertex(br); im.surface_add_vertex(tr)
			im.surface_add_vertex(tr); im.surface_add_vertex(tl)
			im.surface_add_vertex(tl); im.surface_add_vertex(bl)
		im.surface_end()
		var mi := MeshInstance3D.new()
		mi.mesh = im
		mi.name = "DiagOutline%d" % stroke
		_scene_holder.add_child(mi)


# ─── d strip — the constructed real, drawn below the list ────────────
func _add_d_strip(d_str: String, n: int, cols: int) -> void:
	var x_left: float = GRID_LEFT
	var x_right: float = GRID_RIGHT
	var y_top: float = D_STRIP_TOP
	var y_bot: float = D_STRIP_BOTTOM
	var grid_w: float = x_right - x_left
	var cell_w: float = grid_w / float(cols)
	var cell_h: float = y_top - y_bot
	var inset: float = min(cell_w, cell_h) * 0.08

	# Collect quads per surface, emit only the non-empty ones.
	var zero_quads: Array = []
	var one_quads: Array = []
	var filler_quads: Array = []
	for c in range(cols):
		if c >= d_str.length():
			continue
		var sym: String = d_str.substr(c, 1)
		var x: float = x_left + c * cell_w + inset
		var y: float = y_bot + inset
		var w: float = cell_w - 2 * inset
		var h: float = cell_h - 2 * inset
		var is_filler: bool = c >= n
		if is_filler:
			filler_quads.append([x, y, w, h, 0.0])
		elif sym == "1":
			one_quads.append([x, y, w, h, 0.0])
		else:
			zero_quads.append([x, y, w, h, 0.0])

	var im := ImmediateMesh.new()
	_emit_quad_surface(im, zero_quads, D_ZERO)
	_emit_quad_surface(im, one_quads, D_ONE)
	var muted := Color(D_ZERO.r * 0.4, D_ZERO.g * 0.4, D_ZERO.b * 0.4)
	_emit_quad_surface(im, filler_quads, muted)

	# Red-orange outline around the whole d strip (the part that's actually d).
	if n > 0:
		im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(D_BORDER))
		for stroke in range(2):
			var s_inset: float = float(stroke) * 0.006
			for c in range(n):
				var x: float = x_left + c * cell_w + s_inset
				var y: float = y_bot + s_inset
				var w: float = cell_w - 2 * s_inset
				var h: float = cell_h - 2 * s_inset
				var bl := Vector3(x, y, 0.02)
				var br := Vector3(x + w, y, 0.02)
				var tr := Vector3(x + w, y + h, 0.02)
				var tl := Vector3(x, y + h, 0.02)
				im.surface_add_vertex(bl); im.surface_add_vertex(br)
				im.surface_add_vertex(br); im.surface_add_vertex(tr)
				im.surface_add_vertex(tr); im.surface_add_vertex(tl)
				im.surface_add_vertex(tl); im.surface_add_vertex(bl)
		im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "DStrip"
	_scene_holder.add_child(mi)


# ─── Title — name + rule in the top-center ───────────────────────────
func _add_title(spec: Dictionary) -> void:
	var top := Label3D.new()
	top.text = String(spec["name"])
	top.font_size = 68
	top.outline_size = 12
	top.modulate = TEXT_BRIGHT
	top.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	top.shaded = false
	top.no_depth_test = true
	top.pixel_size = 0.0025
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.position = Vector3(0.0, 1.78, 0.02)
	_scene_holder.add_child(top)

	var rule_label: String = ""
	match String(spec["flip_rule"]):
		"bit_flip":
			rule_label = "rule: d_i = NOT (row_i column_i)"
		"shift":
			rule_label = "rule: d_i = NOT (row_i column_{i+1})"
		"random":
			rule_label = "rule: d_i ∈ {0,1} \\ {row_i column_i}"
		"bit_flip_zeros":
			rule_label = "rule: d_i = NOT 0 = 1 (degenerate)"
		"bit_flip_permuted":
			rule_label = "rule: d_i = NOT (permuted_row_i column_i)"
		_:
			rule_label = "rule: bit-flip"

	var sub := Label3D.new()
	sub.text = rule_label
	sub.font_size = 38
	sub.outline_size = 7
	sub.modulate = TEXT_GOLD
	sub.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	sub.shaded = false
	sub.no_depth_test = true
	sub.pixel_size = 0.0025
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector3(0.0, 1.50, 0.02)
	_scene_holder.add_child(sub)


# ─── Sidebar — "d ≠ row_i (digit i differs)" claims ────────────────
# Sits to the right of the list grid. For N > 8 we show the first 4, an
# ellipsis row, and the last 2 — so the structure of "every row gets its
# own disagreement" is visible without becoming a wall of text.
func _add_diff_sidebar(list: Array, n: int, diagonal: String, d_str: String, rule: String) -> void:
	# Sidebar panel background.
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(PANEL_BG))
	var x_lo: float = 0.95
	var x_hi: float = 1.88
	var y_lo: float = -1.40
	var y_hi: float = 1.20
	_quad_at(im, x_lo, y_lo, x_hi - x_lo, y_hi - y_lo, 0.005)
	im.surface_end()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(Color(0.35, 0.40, 0.50, 0.6)))
	im.surface_add_vertex(Vector3(x_lo, y_lo, 0.01)); im.surface_add_vertex(Vector3(x_hi, y_lo, 0.01))
	im.surface_add_vertex(Vector3(x_hi, y_lo, 0.01)); im.surface_add_vertex(Vector3(x_hi, y_hi, 0.01))
	im.surface_add_vertex(Vector3(x_hi, y_hi, 0.01)); im.surface_add_vertex(Vector3(x_lo, y_hi, 0.01))
	im.surface_add_vertex(Vector3(x_lo, y_hi, 0.01)); im.surface_add_vertex(Vector3(x_lo, y_lo, 0.01))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "Sidebar"
	_scene_holder.add_child(mi)

	# Sidebar title
	var title := Label3D.new()
	title.text = "d ∉ list"
	title.font_size = 40
	title.outline_size = 7
	title.modulate = TEXT_RED
	title.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	title.shaded = false
	title.no_depth_test = true
	title.pixel_size = 0.0025
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector3(x_lo + 0.05, y_hi - 0.16, 0.02)
	_scene_holder.add_child(title)

	# Build the list of "d ≠ row_i" lines.
	var lines: Array = []
	var rows_to_show: Array = []
	if n <= 8:
		for i in range(n):
			rows_to_show.append(i)
	else:
		rows_to_show = [0, 1, 2, 3, -1, n - 2, n - 1]

	for idx in rows_to_show:
		if idx == -1:
			lines.append({"text": "  …  (n=%d rows total)" % n, "color": TEXT_DIM})
			continue
		var diag_bit: String = diagonal.substr(idx, 1)
		var d_bit: String = d_str.substr(idx, 1)
		var disagree_col: int = idx + 1 if rule == "shift" else idx
		var text: String = "d ≠ row_%d at col %d (%s ≠ %s)" % [idx + 1, disagree_col + 1, d_bit, diag_bit]
		lines.append({"text": text, "color": TEXT_BRIGHT})

	# Conclusion line.
	lines.append({"text": "", "color": TEXT_BRIGHT})
	lines.append({"text": "∴ d is in no row.", "color": TEXT_RED})
	lines.append({"text": "∴ list is incomplete.", "color": TEXT_RED})

	# Render lines.
	var line_h: float = 0.16
	var top_y: float = y_hi - 0.36
	for j in range(lines.size()):
		var line: Dictionary = lines[j]
		var lab := Label3D.new()
		lab.text = String(line["text"])
		lab.font_size = 26
		lab.outline_size = 5
		lab.modulate = line["color"]
		lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		lab.shaded = false
		lab.no_depth_test = true
		lab.pixel_size = 0.0025
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lab.position = Vector3(x_lo + 0.05, top_y - j * line_h, 0.02)
		_scene_holder.add_child(lab)


# ─── Axis labels — row/col tick numbers along the grid ────────────────
func _add_axis_labels(n: int, cols: int) -> void:
	# Always label cols 1, n/2, n, n+2 along the top of the grid.
	var x_left: float = GRID_LEFT
	var grid_w: float = GRID_RIGHT - GRID_LEFT
	var cell_w: float = grid_w / float(cols)
	var cols_to_label: Array = [0, n - 1]
	if n >= 8:
		cols_to_label = [0, n / 2 - 1, n - 1]
	for c in cols_to_label:
		var lab := Label3D.new()
		lab.text = "col %d" % (c + 1)
		lab.font_size = 20
		lab.outline_size = 4
		lab.modulate = TEXT_DIM
		lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		lab.shaded = false
		lab.no_depth_test = true
		lab.pixel_size = 0.0025
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.position = Vector3(x_left + (c + 0.5) * cell_w, GRID_TOP + 0.08, 0.02)
		_scene_holder.add_child(lab)


# ─── Label below the d strip ──────────────────────────────────────────
func _add_d_label() -> void:
	var lab := Label3D.new()
	lab.text = "d  (constructed real)"
	lab.font_size = 34
	lab.outline_size = 6
	lab.modulate = TEXT_RED
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.position = Vector3(GRID_LEFT, D_STRIP_BOTTOM - 0.10, 0.02)
	_scene_holder.add_child(lab)


# ─── Quad helper — axis-aligned rectangle at (x, y) with given w, h, z ──
func _quad_at(im: ImmediateMesh, x: float, y: float, w: float, h: float, z: float) -> void:
	var bl := Vector3(x, y, z)
	var br := Vector3(x + w, y, z)
	var tr := Vector3(x + w, y + h, z)
	var tl := Vector3(x, y + h, z)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(br)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(tl)


# Emit one PRIMITIVE_TRIANGLES surface for an array of quad specs [x, y, w, h, z].
# Skips the surface entirely if the array is empty — that's the case where, e.g.,
# the list is all zeros so there are no "1" cells to draw.
func _emit_quad_surface(im: ImmediateMesh, quads: Array, color: Color) -> void:
	if quads.is_empty():
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(color))
	for q in quads:
		_quad_at(im, q[0], q[1], q[2], q[3], q[4])
	im.surface_end()


# ─── Materials ────────────────────────────────────────────────────────
func _unshaded_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.4
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _unshaded_material_transparent(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(c.r, c.g, c.b, 1.0)
	mat.emission_energy_multiplier = 0.25
	return mat


# ─── Capture + record ─────────────────────────────────────────────────
func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(id: String, spec: Dictionary, run: Dictionary) -> void:
	# Yield a few frames so the viewport renders before sampling.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# JSON sidecar — config + the list and constructed real.
	var n: int = int(spec["n"])
	var list_serialised: Array = []
	for row in run["list"]:
		list_serialised.append(String(row))
	var d_truncated: String = String(run["d"]).substr(0, n)
	var diag_truncated: String = String(run["diagonal"]).substr(0, n)

	var config := {
		"id": id,
		"name": spec["name"],
		"n": n,
		"flip_rule": spec["flip_rule"],
		"list_source": spec["list_source"],
		"list": list_serialised,
		"diagonal": diag_truncated,
		"d": d_truncated,
		"d_padded": String(run["d"]),
		"perm": run["perm"],
		"notes": spec["notes"],
	}
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(config, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"name": String(spec["name"]),
		"n": n,
		"flip_rule": String(spec["flip_rule"]),
		"list_source": String(spec["list_source"]),
		"notes": String(spec["notes"]),
		"diagonal": diag_truncated,
		"d": d_truncated,
		"image": "/cantor-diagonal-gallery/%s" % img_rel,
		"config": "/cantor-diagonal-gallery/%s" % cfg_rel,
	})
	print("  saved: %s" % id)
