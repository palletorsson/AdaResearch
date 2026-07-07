## One-off sweep capture for the complexity-dial DNA gallery.
##
## The pedagogical claim — for input size N, algorithm complexity class
## determines runtime. At small N (N=5) the five algorithms — O(log N),
## O(N), O(N log N), O(N²), O(2^N) — are nearly indistinguishable. As N
## grows the exponential pulls catastrophically away from the polynomials,
## and somewhere around N=30 it crosses the "1 second @ 10⁹ ops/sec" wall
## clock — the practical-computation limit. Polynomial vs exponential
## isn't a constant factor; it's a different kind of thing.
##
## The 7 cells (one N per cell):
##   1. N=5   — all five algorithms finish nearly instantly
##   2. N=10  — exponential pulling away (2^10 = 1024 steps)
##   3. N=20  — exponential = 10⁶, quadratic = 400, others tiny
##   4. N=30  — exponential = 10⁹, quadratic = 900, linear = 30 (exp ≈ wall)
##   5. N=40  — exponential = 10¹², quadratic = 1600 (exp OFF chart)
##   6. N=50  — quadratic now visibly slower than linearithmic
##   7. N=60  — full divergence visible, five different growth regimes
##
## Visual goals (matching halting-bench-gallery / parametric-mesh-gallery):
##   - Square 1024×1024 SubViewport, MSAA 8x + FXAA, isolated World3D
##   - Orthographic camera looking head-on at the bar-chart plane
##   - 5 horizontal bars (one per complexity class), bar LENGTH = log10(steps)
##     so the exponential doesn't blow off the canvas
##   - Each bar annotated with the actual step count (e.g. "1,099,511,627,776")
##   - Horizontal "wall-clock" line at log10(10^9) = 9 marks the practical limit
##   - Big N label at the top
##   - Small line graph at the bottom — growth curves from N=1 to current N,
##     on log-scaled y-axis
##   - Saturated, distinguishable colors per algorithm
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_complexity_dial_gallery.gd \
##     -- --out=user://complexity_dial_gallery
##
## Output: <out>/{id}.png + {id}.json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Orthographic camera framing — XY plane, looking down +Z.
# World space coordinates roughly: x ∈ [-1.9, 1.9], y ∈ [-1.9, 1.9].
const ORTHO_SIZE: float = 4.0

# Bar-chart geometry
const BARS_TOP_Y: float = 1.05         # top of topmost bar
const BARS_BOTTOM_Y: float = -0.45     # bottom of bottommost bar
const BARS_LEFT_X: float = -1.30       # x-origin (zero-step) of bars
const BARS_RIGHT_X: float = 1.65       # x position of log10(10^15) = 15
const BAR_HEIGHT: float = 0.18         # height of one bar (5 bars stack)
const BAR_GAP: float = 0.10            # vertical gap between adjacent bars
const BAR_LOG_MAX: float = 15.0        # x axis spans log10(1) = 0 → log10(10^15) = 15

# Practical-limit line: log10(10^9) = 9 ops ≈ 1 second @ 10⁹ ops/sec.
const PRACTICAL_LOG: float = 9.0

# Line-graph geometry at the bottom.
const GRAPH_LEFT_X: float = -1.55
const GRAPH_RIGHT_X: float = 1.65
const GRAPH_BOTTOM_Y: float = -1.85
const GRAPH_TOP_Y: float = -0.85
const GRAPH_LOG_MAX: float = 15.0      # y axis: log10(steps) → 0..15

# Colors per complexity class (saturated, distinguishable, semantic).
const COL_LOG: Color = Color(0.62, 0.78, 0.95)     # pale blue — O(log N)
const COL_LIN: Color = Color(0.36, 0.86, 0.94)     # cyan — O(N)
const COL_NLOG: Color = Color(0.32, 0.78, 0.66)    # teal — O(N log N)
const COL_QUAD: Color = Color(0.98, 0.72, 0.28)    # amber — O(N²)
const COL_EXP: Color = Color(0.95, 0.36, 0.36)     # red — O(2^N)

# Text colors
const TEXT_BRIGHT: Color = Color(0.96, 0.96, 0.98)
const TEXT_DIM: Color = Color(0.62, 0.66, 0.74)
const PANEL_BG: Color = Color(0.10, 0.12, 0.17, 0.85)
const AXIS_LINE: Color = Color(0.35, 0.40, 0.50, 0.85)
const PRACTICAL_LINE: Color = Color(0.96, 0.55, 0.20, 0.95)
const OFF_CHART: Color = Color(0.95, 0.36, 0.36, 0.95)

# Algorithms — display order is top-to-bottom on the chart.
# Each entry: {key, label, complexity, color, steps_fn}
const ALGORITHMS := [
	{"key": "log",  "label": "logarithm",      "complexity": "O(log N)",   "color": COL_LOG},
	{"key": "lin",  "label": "linear",         "complexity": "O(N)",        "color": COL_LIN},
	{"key": "nlog", "label": "linearithmic",   "complexity": "O(N log N)",  "color": COL_NLOG},
	{"key": "quad", "label": "quadratic",      "complexity": "O(N²)",       "color": COL_QUAD},
	{"key": "exp",  "label": "exponential",    "complexity": "O(2^N)",      "color": COL_EXP},
]

# Sweep N values
const N_VALUES := [5, 10, 20, 30, 40, 50, 60]

var _output_dir: String = "user://complexity_dial_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
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

	# Cosmetic light (unshaded materials don't need it but keeps env happy).
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

	# ── Sweep over N values ─────────────────────────────────────────
	for idx in range(N_VALUES.size()):
		var n: int = N_VALUES[idx]
		var step_counts: Dictionary = _compute_step_counts(n)
		_build_scene(n, idx, step_counts)
		await create_timer(0.05).timeout
		await _capture_and_record(n, idx, step_counts)
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "One dial: input size N. Five algorithms running side-by-side at the same N — O(log N), O(N), O(N log N), O(N²), O(2^N). At N=5 they're identical; at N=40 the exponential is at 10¹² steps and the others are still readable. The polynomial-vs-exponential gap isn't a constant factor — it's a different kind of thing. The wall-clock line at 10⁹ ops marks where 'practical' ends. Bar length is log10(step count) so the exponential doesn't blow off the canvas; step counts are annotated as plain numbers. The bottom strip shows each algorithm's growth curve from N=1 to current N on a log-scaled axis. Turing-machine-era complexity theory made visible by sweeping one dial.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": ORTHO_SIZE},
		"practical_threshold_steps": 1_000_000_000,
		"practical_threshold_note": "1 second @ 10⁹ ops/sec — beyond this bar, an algorithm is no longer practical.",
		"algorithms": _algorithms_manifest(),
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ─── Step-count math ─────────────────────────────────────────────────
# Each algorithm gets a deterministic, exact step count for an input
# size N. We use exact integer arithmetic where possible; for 2^N
# we use float once it exceeds 2^53 (still accurate to ~15 digits).
func _compute_step_counts(n: int) -> Dictionary:
	# log_2(N) — clamped to 1 for N=1, otherwise ceil for "steps to halve".
	var log_n: float = max(1.0, ceil(log(float(n)) / log(2.0)))
	var lin: float = float(n)
	var nlog: float = float(n) * log_n
	var quad: float = float(n) * float(n)
	# 2^N — use pow() so big N stays representable as a float.
	var expv: float = pow(2.0, float(n))
	return {
		"log":  log_n,
		"lin":  lin,
		"nlog": nlog,
		"quad": quad,
		"exp":  expv,
	}


# ─── Scene construction ──────────────────────────────────────────────
func _build_scene(n: int, idx: int, step_counts: Dictionary) -> void:
	# Top: cell title with big N
	_add_n_header(n, idx)

	# Bar-chart axis & practical-limit line
	_add_chart_axis()
	_add_practical_line()

	# Five bars (one per algorithm)
	_add_bars(step_counts)

	# Small line graph at the bottom showing growth curves up to current N
	_add_growth_graph(n)

	# Footer caption
	_add_footer_caption(n, step_counts)


# Top header: "INPUT SIZE N = 30" in big text.
func _add_n_header(n: int, idx: int) -> void:
	var lab := Label3D.new()
	lab.text = "INPUT SIZE  N = %d" % n
	lab.font_size = 88
	lab.outline_size = 14
	lab.modulate = TEXT_BRIGHT
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, 1.62, 0.02)
	_scene_holder.add_child(lab)

	# Cell index in the sweep
	var subtitle := Label3D.new()
	subtitle.text = "cell %d / %d  ·  complexity dial sweep" % [idx + 1, N_VALUES.size()]
	subtitle.font_size = 32
	subtitle.outline_size = 6
	subtitle.modulate = TEXT_DIM
	subtitle.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	subtitle.shaded = false
	subtitle.no_depth_test = true
	subtitle.pixel_size = 0.0025
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector3(0.0, 1.39, 0.02)
	_scene_holder.add_child(subtitle)


# X-axis baseline + tick labels at log10 = 0, 3, 6, 9, 12, 15.
func _add_chart_axis() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(AXIS_LINE))
	# Vertical zero-axis (left edge of bars)
	im.surface_add_vertex(Vector3(BARS_LEFT_X, BARS_BOTTOM_Y - 0.05, 0.01))
	im.surface_add_vertex(Vector3(BARS_LEFT_X, BARS_TOP_Y + 0.05, 0.01))
	# Horizontal baseline at bottom of bars
	im.surface_add_vertex(Vector3(BARS_LEFT_X, BARS_BOTTOM_Y - 0.05, 0.01))
	im.surface_add_vertex(Vector3(BARS_RIGHT_X, BARS_BOTTOM_Y - 0.05, 0.01))
	# Tick marks at 10^0, 10^3, 10^6, 10^9, 10^12, 10^15
	for tick_log in [0, 3, 6, 9, 12, 15]:
		var x: float = _log_to_x(float(tick_log))
		im.surface_add_vertex(Vector3(x, BARS_BOTTOM_Y - 0.05, 0.01))
		im.surface_add_vertex(Vector3(x, BARS_BOTTOM_Y - 0.10, 0.01))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "ChartAxis"
	_scene_holder.add_child(mi)

	# Tick labels: 1, 10³, 10⁶, 10⁹, 10¹², 10¹⁵
	var tick_labels := ["1", "10³", "10⁶", "10⁹", "10¹²", "10¹⁵"]
	for i in range(tick_labels.size()):
		var tl := tick_labels[i] as String
		var tick_log: int = [0, 3, 6, 9, 12, 15][i]
		var x: float = _log_to_x(float(tick_log))
		var lab := Label3D.new()
		lab.text = tl
		lab.font_size = 28
		lab.outline_size = 6
		lab.modulate = TEXT_DIM
		lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		lab.shaded = false
		lab.no_depth_test = true
		lab.pixel_size = 0.0025
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.position = Vector3(x, BARS_BOTTOM_Y - 0.20, 0.02)
		_scene_holder.add_child(lab)

	# X-axis label
	var axis_lab := Label3D.new()
	axis_lab.text = "step count  (log scale)"
	axis_lab.font_size = 26
	axis_lab.outline_size = 5
	axis_lab.modulate = TEXT_DIM
	axis_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	axis_lab.shaded = false
	axis_lab.no_depth_test = true
	axis_lab.pixel_size = 0.0025
	axis_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	axis_lab.position = Vector3((BARS_LEFT_X + BARS_RIGHT_X) * 0.5, BARS_BOTTOM_Y - 0.34, 0.02)
	_scene_holder.add_child(axis_lab)


# Vertical line at log10 = 9 = "1 second @ 10⁹ ops/sec" practical limit.
func _add_practical_line() -> void:
	var x: float = _log_to_x(PRACTICAL_LOG)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(PRACTICAL_LINE))
	# Dashed vertical line: ~12 dashes
	var y0: float = BARS_BOTTOM_Y - 0.05
	var y1: float = BARS_TOP_Y + 0.20
	var total: float = y1 - y0
	var dash_count: int = 14
	var dash_unit: float = total / float(dash_count * 2 - 1)
	for i in range(dash_count):
		var ys: float = y0 + float(i * 2) * dash_unit
		var ye: float = ys + dash_unit
		im.surface_add_vertex(Vector3(x, ys, 0.02))
		im.surface_add_vertex(Vector3(x, ye, 0.02))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "PracticalLine"
	_scene_holder.add_child(mi)

	# Label at the top of the dashed line
	var lab := Label3D.new()
	lab.text = "wall clock — 1 sec @ 10⁹ ops/sec"
	lab.font_size = 24
	lab.outline_size = 5
	lab.modulate = PRACTICAL_LINE
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(x, BARS_TOP_Y + 0.28, 0.02)
	_scene_holder.add_child(lab)


# Five horizontal bars, one per algorithm. Bar length = log10(steps).
# Each bar gets a complexity label on the left and the actual step count
# annotated on the right.
func _add_bars(step_counts: Dictionary) -> void:
	# Vertical pitch: distribute 5 bars between BARS_TOP_Y and BARS_BOTTOM_Y.
	var total_h: float = BARS_TOP_Y - BARS_BOTTOM_Y
	var pitch: float = total_h / float(ALGORITHMS.size())

	for i in range(ALGORITHMS.size()):
		var algo: Dictionary = ALGORITHMS[i]
		var key: String = algo["key"]
		var color: Color = algo["color"]
		var label_short: String = algo["complexity"]
		var steps: float = float(step_counts[key])
		var log_steps: float = 0.0
		if steps > 0.0:
			log_steps = log(steps) / log(10.0)
		log_steps = max(0.0, log_steps)
		# Bar center Y — topmost is "log", index 0 → top.
		var y_center: float = BARS_TOP_Y - pitch * (float(i) + 0.5)
		var y_lo: float = y_center - BAR_HEIGHT * 0.5
		var y_hi: float = y_center + BAR_HEIGHT * 0.5

		# Bar fill — extends from BARS_LEFT_X to log_to_x(log_steps).
		# If the bar would exceed log10 = 15, clip and draw an "off-chart" tab.
		var visible_log: float = min(log_steps, BAR_LOG_MAX)
		var x_end: float = _log_to_x(visible_log)
		var off_chart: bool = (log_steps > BAR_LOG_MAX)

		# Filled bar quad
		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(color))
		_quad(im, Vector3(BARS_LEFT_X, y_lo, 0.01),
			Vector3(x_end, y_lo, 0.01),
			Vector3(x_end, y_hi, 0.01),
			Vector3(BARS_LEFT_X, y_hi, 0.01))
		im.surface_end()

		# Subtle border for the bar
		im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1.0)))
		var bl := Vector3(BARS_LEFT_X, y_lo, 0.02)
		var br := Vector3(x_end, y_lo, 0.02)
		var tr := Vector3(x_end, y_hi, 0.02)
		var tl := Vector3(BARS_LEFT_X, y_hi, 0.02)
		im.surface_add_vertex(bl); im.surface_add_vertex(br)
		im.surface_add_vertex(br); im.surface_add_vertex(tr)
		im.surface_add_vertex(tr); im.surface_add_vertex(tl)
		im.surface_add_vertex(tl); im.surface_add_vertex(bl)
		im.surface_end()

		# If the bar exceeds the chart range, draw a chevron at the right edge.
		if off_chart:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(OFF_CHART))
			var ax: float = BARS_RIGHT_X + 0.02
			var bx: float = BARS_RIGHT_X + 0.18
			im.surface_add_vertex(Vector3(ax, y_lo, 0.03))
			im.surface_add_vertex(Vector3(bx, y_center, 0.03))
			im.surface_add_vertex(Vector3(ax, y_hi, 0.03))
			im.surface_end()

		var mi := MeshInstance3D.new()
		mi.mesh = im
		mi.name = "Bar_%s" % key
		_scene_holder.add_child(mi)

		# Complexity label on the LEFT of the bar
		var class_lab := Label3D.new()
		class_lab.text = label_short
		class_lab.font_size = 38
		class_lab.outline_size = 7
		class_lab.modulate = color
		class_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		class_lab.shaded = false
		class_lab.no_depth_test = true
		class_lab.pixel_size = 0.0025
		class_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		class_lab.position = Vector3(BARS_LEFT_X - 0.05, y_center + 0.025, 0.04)
		_scene_holder.add_child(class_lab)

		# Sub-label (name) under the class label
		var name_lab := Label3D.new()
		name_lab.text = algo["label"]
		name_lab.font_size = 22
		name_lab.outline_size = 4
		name_lab.modulate = TEXT_DIM
		name_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		name_lab.shaded = false
		name_lab.no_depth_test = true
		name_lab.pixel_size = 0.0025
		name_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_lab.position = Vector3(BARS_LEFT_X - 0.05, y_center - 0.045, 0.04)
		_scene_holder.add_child(name_lab)

		# Step count annotation at the END of the bar (or right of chevron).
		var count_text: String = _format_count(steps)
		var count_lab := Label3D.new()
		count_lab.text = count_text
		count_lab.font_size = 28
		count_lab.outline_size = 6
		count_lab.modulate = TEXT_BRIGHT
		count_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		count_lab.shaded = false
		count_lab.no_depth_test = true
		count_lab.pixel_size = 0.0025
		count_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var ann_x: float = (BARS_RIGHT_X + 0.22) if off_chart else (x_end + 0.04)
		count_lab.position = Vector3(ann_x, y_center, 0.04)
		_scene_holder.add_child(count_lab)

		# If the bar crosses the practical threshold, add a small "beyond practical" tag.
		if log_steps > PRACTICAL_LOG:
			var warn_lab := Label3D.new()
			warn_lab.text = "✕ beyond practical"
			warn_lab.font_size = 18
			warn_lab.outline_size = 4
			warn_lab.modulate = PRACTICAL_LINE
			warn_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
			warn_lab.shaded = false
			warn_lab.no_depth_test = true
			warn_lab.pixel_size = 0.0025
			warn_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			warn_lab.position = Vector3(ann_x, y_center - 0.055, 0.04)
			_scene_holder.add_child(warn_lab)


# Growth curves: for each algorithm, plot a polyline from N=1 to current N
# on the log10(steps) axis. Bottom panel of the cell.
func _add_growth_graph(current_n: int) -> void:
	# Panel background
	var im_bg := ImmediateMesh.new()
	im_bg.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(PANEL_BG))
	_quad(im_bg, Vector3(GRAPH_LEFT_X - 0.05, GRAPH_BOTTOM_Y - 0.05, 0.005),
		Vector3(GRAPH_RIGHT_X + 0.05, GRAPH_BOTTOM_Y - 0.05, 0.005),
		Vector3(GRAPH_RIGHT_X + 0.05, GRAPH_TOP_Y + 0.05, 0.005),
		Vector3(GRAPH_LEFT_X - 0.05, GRAPH_TOP_Y + 0.05, 0.005))
	im_bg.surface_end()
	var mi_bg := MeshInstance3D.new()
	mi_bg.mesh = im_bg
	mi_bg.name = "GraphBG"
	_scene_holder.add_child(mi_bg)

	# Axes (left + bottom) + practical-limit horizontal line
	var im_ax := ImmediateMesh.new()
	im_ax.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(AXIS_LINE))
	# bottom axis
	im_ax.surface_add_vertex(Vector3(GRAPH_LEFT_X, GRAPH_BOTTOM_Y, 0.01))
	im_ax.surface_add_vertex(Vector3(GRAPH_RIGHT_X, GRAPH_BOTTOM_Y, 0.01))
	# left axis
	im_ax.surface_add_vertex(Vector3(GRAPH_LEFT_X, GRAPH_BOTTOM_Y, 0.01))
	im_ax.surface_add_vertex(Vector3(GRAPH_LEFT_X, GRAPH_TOP_Y, 0.01))
	im_ax.surface_end()
	# practical limit
	im_ax.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(PRACTICAL_LINE))
	var prac_y: float = _graph_log_to_y(PRACTICAL_LOG)
	# Dashed horizontal
	var dash_count: int = 24
	var total_w: float = GRAPH_RIGHT_X - GRAPH_LEFT_X
	var dash_unit: float = total_w / float(dash_count * 2 - 1)
	for i in range(dash_count):
		var xs: float = GRAPH_LEFT_X + float(i * 2) * dash_unit
		var xe: float = xs + dash_unit
		im_ax.surface_add_vertex(Vector3(xs, prac_y, 0.02))
		im_ax.surface_add_vertex(Vector3(xe, prac_y, 0.02))
	im_ax.surface_end()
	var mi_ax := MeshInstance3D.new()
	mi_ax.mesh = im_ax
	mi_ax.name = "GraphAxis"
	_scene_holder.add_child(mi_ax)

	# Curves: for each algorithm, polyline N=1..current_n in log space.
	# X axis: N spans 0..max(60). We sample at every integer N from 1 to current_n.
	var n_max: int = N_VALUES[N_VALUES.size() - 1]
	for algo in ALGORITHMS:
		var key: String = algo["key"]
		var color: Color = algo["color"]
		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _unshaded_material(color))
		# We add a faint "future" segment from current_n+1 to n_max (only if curve fits).
		# For simplicity, just plot 1..current_n.
		for n_i in range(1, current_n + 1):
			var sc: Dictionary = _compute_step_counts(n_i)
			var steps: float = float(sc[key])
			var log_s: float = 0.0
			if steps > 0.0:
				log_s = log(steps) / log(10.0)
			log_s = clamp(log_s, 0.0, GRAPH_LOG_MAX)
			var x: float = lerpf(GRAPH_LEFT_X, GRAPH_RIGHT_X, float(n_i) / float(n_max))
			var y: float = _graph_log_to_y(log_s)
			im.surface_add_vertex(Vector3(x, y, 0.03))
		im.surface_end()
		var mi := MeshInstance3D.new()
		mi.mesh = im
		mi.name = "Curve_%s" % key
		_scene_holder.add_child(mi)

	# Graph title + N-range labels
	var title := Label3D.new()
	title.text = "growth curves  ·  N = 1 → %d" % current_n
	title.font_size = 24
	title.outline_size = 5
	title.modulate = TEXT_DIM
	title.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	title.shaded = false
	title.no_depth_test = true
	title.pixel_size = 0.0025
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector3(GRAPH_LEFT_X + 0.02, GRAPH_TOP_Y + 0.10, 0.04)
	_scene_holder.add_child(title)

	# Practical line tag inside graph
	var prac_lab := Label3D.new()
	prac_lab.text = "10⁹ ops"
	prac_lab.font_size = 18
	prac_lab.outline_size = 4
	prac_lab.modulate = PRACTICAL_LINE
	prac_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	prac_lab.shaded = false
	prac_lab.no_depth_test = true
	prac_lab.pixel_size = 0.0025
	prac_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	prac_lab.position = Vector3(GRAPH_LEFT_X + 0.04, prac_y + 0.04, 0.04)
	_scene_holder.add_child(prac_lab)

	# Y-axis hint
	var ylab := Label3D.new()
	ylab.text = "log₁₀(steps)"
	ylab.font_size = 18
	ylab.outline_size = 4
	ylab.modulate = TEXT_DIM
	ylab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	ylab.shaded = false
	ylab.no_depth_test = true
	ylab.pixel_size = 0.0025
	ylab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ylab.position = Vector3(GRAPH_LEFT_X - 0.02, GRAPH_TOP_Y - 0.04, 0.04)
	_scene_holder.add_child(ylab)

	# X-axis tick labels at N = 1, n_max/4, n_max/2, 3*n_max/4, n_max
	var nticks := [1, int(n_max * 0.25), int(n_max * 0.5), int(n_max * 0.75), n_max]
	for t in nticks:
		var x: float = lerpf(GRAPH_LEFT_X, GRAPH_RIGHT_X, float(t) / float(n_max))
		var tk := Label3D.new()
		tk.text = "N=%d" % t
		tk.font_size = 16
		tk.outline_size = 3
		tk.modulate = TEXT_DIM
		tk.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		tk.shaded = false
		tk.no_depth_test = true
		tk.pixel_size = 0.0025
		tk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tk.position = Vector3(x, GRAPH_BOTTOM_Y - 0.07, 0.04)
		_scene_holder.add_child(tk)


# Footer caption — count how many algorithms are beyond the wall clock.
func _add_footer_caption(n: int, step_counts: Dictionary) -> void:
	var beyond: Array = []
	for algo in ALGORITHMS:
		var key: String = algo["key"]
		var steps: float = float(step_counts[key])
		if steps > 0.0 and (log(steps) / log(10.0)) > PRACTICAL_LOG:
			beyond.append(algo["complexity"])
	var msg: String = "all five practical at N = %d" % n
	if beyond.size() > 0:
		msg = "%d of 5 beyond 10⁹ ops  ·  %s" % [beyond.size(), ", ".join(beyond)]
	# Position just below the bar chart, above the graph panel.
	var lab := Label3D.new()
	lab.text = msg
	lab.font_size = 24
	lab.outline_size = 5
	if beyond.size() > 0:
		lab.modulate = PRACTICAL_LINE
	else:
		lab.modulate = COL_LIN
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, -0.75, 0.04)
	_scene_holder.add_child(lab)


# ─── Helpers ──────────────────────────────────────────────────────────
func _quad(im: ImmediateMesh, bl: Vector3, br: Vector3, tr: Vector3, tl: Vector3) -> void:
	im.surface_add_vertex(bl)
	im.surface_add_vertex(br)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(tl)


# Map a log10(steps) value to the X coordinate on the bar chart.
func _log_to_x(log_value: float) -> float:
	var t: float = clamp(log_value / BAR_LOG_MAX, 0.0, 1.0)
	return lerpf(BARS_LEFT_X, BARS_RIGHT_X, t)


# Map a log10(steps) value to the Y coordinate on the growth-graph panel.
func _graph_log_to_y(log_value: float) -> float:
	var t: float = clamp(log_value / GRAPH_LOG_MAX, 0.0, 1.0)
	return lerpf(GRAPH_BOTTOM_Y, GRAPH_TOP_Y, t)


# Format a step count for display.
# Small numbers: plain integer with thousands commas.
# Large numbers: scientific notation "1.1×10¹²" with a unicode multiply.
func _format_count(steps: float) -> String:
	if steps < 1.0:
		return "0"
	if steps < 1.0e6:
		return _commas(int(round(steps)))
	# Scientific
	var exponent: int = int(floor(log(steps) / log(10.0)))
	var mantissa: float = steps / pow(10.0, float(exponent))
	# Round mantissa to 1 decimal
	mantissa = round(mantissa * 10.0) / 10.0
	# Avoid "10.0×10^N" — promote to next exponent
	if mantissa >= 10.0:
		mantissa = mantissa / 10.0
		exponent += 1
	return "%.1f×10%s" % [mantissa, _superscript(exponent)]


# Convert an integer to its unicode-superscript representation (e.g. 12 → "¹²")
func _superscript(n: int) -> String:
	var digits := "0123456789"
	var sup := "⁰¹²³⁴⁵⁶⁷⁸⁹"
	var s: String = str(n)
	var out: String = ""
	for i in range(s.length()):
		var c: String = s[i]
		var idx: int = digits.find(c)
		if idx >= 0:
			out += sup[idx]
		else:
			out += c  # passes through "-", etc.
	return out


# Insert thousands commas into an integer.
func _commas(n: int) -> String:
	var s: String = str(n)
	var out: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count == 3 and i > 0 and s[i - 1] != "-":
			out = "," + out
			count = 0
	return out


# Manifest entry describing each algorithm.
func _algorithms_manifest() -> Array:
	var out: Array = []
	for algo in ALGORITHMS:
		var c: Color = algo["color"]
		out.append({
			"key": algo["key"],
			"label": algo["label"],
			"complexity": algo["complexity"],
			"color": [c.r, c.g, c.b],
		})
	return out


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


# ─── Capture and record ──────────────────────────────────────────────
func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(n: int, idx: int, step_counts: Dictionary) -> void:
	# Yield a few frames so the viewport renders before sampling.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var id: String = "%d_n_%02d" % [idx + 1, n]
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# Build a dict of step counts keyed by complexity-class string for sidecar.
	var sc_by_class: Dictionary = {}
	var beyond_practical: Array = []
	for algo in ALGORITHMS:
		var key: String = algo["key"]
		var complexity: String = algo["complexity"]
		var steps: float = float(step_counts[key])
		var display: String = _format_count(steps)
		# Store as both number and pretty string.
		sc_by_class[complexity] = {
			"key": key,
			"label": algo["label"],
			"steps_raw": steps,
			"steps_display": display,
			"log10_steps": (log(steps) / log(10.0)) if steps > 0.0 else 0.0,
		}
		if steps > 0.0 and (log(steps) / log(10.0)) > PRACTICAL_LOG:
			beyond_practical.append(complexity)

	var notes: String = _notes_for_n(n, step_counts, beyond_practical)

	var cfg := {
		"id": id,
		"n": n,
		"cell_index": idx + 1,
		"step_counts": sc_by_class,
		"practical_threshold": 1_000_000_000,
		"practical_threshold_log10": PRACTICAL_LOG,
		"beyond_practical": beyond_practical,
		"notes": notes,
	}
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(cfg, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"n": n,
		"cell_index": idx + 1,
		"step_counts_pretty": _pretty_step_counts(step_counts),
		"beyond_practical": beyond_practical,
		"notes": notes,
		"image": "/complexity-dial-gallery/%s" % img_rel,
		"config": "/complexity-dial-gallery/%s" % cfg_rel,
	})
	print("  saved: %s  N=%d  beyond=%d (%s)" % [
		id, n, beyond_practical.size(), ", ".join(beyond_practical)
	])


func _pretty_step_counts(step_counts: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for algo in ALGORITHMS:
		var key: String = algo["key"]
		out[algo["complexity"]] = _format_count(float(step_counts[key]))
	return out


# Build the per-cell pedagogical note.
func _notes_for_n(n: int, step_counts: Dictionary, beyond_practical: Array) -> String:
	var lin: int = int(step_counts["lin"])
	var quad: int = int(step_counts["quad"])
	var exp_display: String = _format_count(float(step_counts["exp"]))
	if n <= 5:
		return "At N=%d all five algorithms finish nearly instantly. Linear: %d steps. Quadratic: %d. Exponential: %s. The difference is invisible — every algorithm class is equally 'fast'." % [n, lin, quad, exp_display]
	elif n <= 10:
		return "At N=%d the exponential pulls visibly away — %s steps versus %d for quadratic and %d for linear. The polynomials still finish almost instantly; the exponential takes a noticeable instant." % [n, exp_display, quad, lin]
	elif n <= 20:
		return "At N=%d the exponential is at %s steps — already a million. Quadratic %d, linear %d. The polynomials are still trivially fast. The first hint of the gap." % [n, exp_display, quad, lin]
	elif n <= 30:
		return "At N=%d the exponential is at %s — crossing the 10⁹ wall clock. One second of compute at a billion ops/sec. Everything polynomial is still tiny: quadratic %d, linear %d. This is where 'beyond practical' begins for 2^N." % [n, exp_display, quad, lin]
	elif n <= 40:
		return "At N=%d the exponential's bar is OFF THE CHART — %s steps, roughly a thousand seconds at 10⁹ ops/sec. The polynomials are still fast: quadratic %d, linearithmic comfortable. The gap is now categorical, not quantitative." % [n, exp_display, quad]
	elif n <= 50:
		return "At N=%d the quadratic is visibly slower than linearithmic — %d vs %d. The polynomial separation finally appears at this scale. Exponential is %s, deep in the unreachable zone." % [n, quad, int(step_counts["nlog"]), exp_display]
	else:
		return "At N=%d all five growth regimes are visible. Linear is %d, linearithmic %d, quadratic %d, exponential %s. The exponential's bar would need 18 orders of magnitude more chart to fit. Five algorithms with the same input — five completely different fates." % [n, lin, int(step_counts["nlog"]), quad, exp_display]
