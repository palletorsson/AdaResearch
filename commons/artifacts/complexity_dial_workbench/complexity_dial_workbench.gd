extends Node3D
class_name ComplexityDialWorkbench

# @identity
# essence: an interactive complexity-dial workbench — the player turns ONE knob (input size N) and watches 5 algorithms race at their characteristic growth rates. At N=5 they're nearly indistinguishable. At N=30 the exponential bar crosses the wall-clock line. At N=60 the exponential is at 10^18 steps while linear is at 60; they cannot be reconciled by any constant factor.
# desire: learner viscerally feels the P-vs-NP intuition — polynomial scales, exponential does not, and the gap isn't a constant
# critical_parameter: N — the only knob. Drives 5 step counts simultaneously
# triggers: _ready() builds dial + 5 bars + readout + wall-clock line + growth curves; _on_slider_changed recomputes all 5 step counts and updates the bars
# emerges: the categorical difference between polynomial and exponential growth — same dial, eighteen orders of magnitude apart at large N
# needs: slider_horizontal [present]; 5 colored bars [present]; Label3D readouts [present]
# relationships: paired with /complexity-dial-gallery (web cells frozen at 7 N-values); sibling to halting_workbench (both probe limits of computing); embodies the foundationscrisis sequence
# truth: polynomial vs exponential isn't a speed difference; it's a different kind of thing. The dial demonstrates the gap is unbridgeable by any constant factor.

## A horizontal workbench for the polynomial-vs-exponential gap.
##
## One slider drives N ∈ [1, 60] (integer). As you move it:
##   • 5 step counts recompute simultaneously (log N, N, N log N, N², 2^N)
##   • 5 horizontal bars resize using a LOG10 scale (so 2^N doesn't blow up the chart)
##   • a dashed wall-clock line at log10(10^9) = 9 marks "1 second @ 1 GHz"
##   • bars that cross the line carry a red ✕ "no longer practical" badge
##   • a small line graph at the bottom plots all 5 growth curves from N=1 to current N
##   • the readout panel shows N, the 5 step counts, and the count past-practical
##
## Sister to /complexity-dial-gallery — the web version freezes the same view at
## 7 N-values; this is the live, draggable form. At N≈30 the exponential bar
## first crosses the wall-clock line; from there, 2^N is unreachable.

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
@export var plate_tilt_deg: float = -25.0
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Measure (debug)")
## Show a measure from the interface front face to the composed display — a rod
## + marker that makes the set-out distance visible. Spans either direction.
## Debug aid, off by default; toggle on when re-placing the display.
@export var show_marker: bool = false

@export_group("Display Panel")
## Anchor for the unified viz panel: above + slightly forward of the console,
## so all three pieces (bars, curve, readout) read as one screen on the desk.
@export var display_offset: Vector3 = Vector3(0.0, 1.78, 0.22)
## Uniform scale of the whole display (keeps it monitor-sized above the desk).
@export var display_scale: float = 0.7
## Slight back-lean so the panel faces a standing player (degrees about X).
@export var display_tilt_degrees: float = -10.0

@export_group("Bar Chart")
## Horizontal span allotted to "1.0" (max practical) on the log scale.
@export var bar_chart_width: float = 1.1
## Vertical spacing between bars.
@export var bar_spacing: float = 0.11
## Bar thickness (height of each box).
@export var bar_thickness: float = 0.07
## Local position of the bar chart within the display panel (upper-left).
@export var bar_chart_offset: Vector3 = Vector3(-0.88, 0.28, 0.0)

@export_group("Growth Curves")
## Width of the small line graph at the bottom of the chart.
@export var curve_width: float = 1.1
## Height of the curve panel (log y-axis spans 0..practical).
@export var curve_height: float = 0.25
## Local position of the curve panel within the display (below the bars).
@export var curve_offset: Vector3 = Vector3(-0.88, -0.62, 0.0)

@export_group("Wall Clock")
## log10(steps) threshold. 10^9 ops/sec = 1 second of compute.
@export var practical_log_threshold: float = 9.0

@export_group("Initial State")
@export var initial_n: int = 30
@export var n_min: int = 1
@export var n_max: int = 60

# ── Algorithm definitions (matches the web gallery palette) ──────────

class AlgoSpec:
	var key: String
	var label: String
	var complexity: String
	var color: Color
	func _init(k: String, l: String, c: String, col: Color) -> void:
		key = k
		label = l
		complexity = c
		color = col

var _algos: Array = []  # Array[AlgoSpec]

# ── Internal state ────────────────────────────────────────────────────

const InterfacePresets = preload("res://commons/ui/interface_presets.gd")

var _n: int = 30

var _plate_root: Node3D   # now the canonical ControlConsole (board + cabinet)
var _slider: Node
var _plate_readout         # console readout (Label) — N + past-practical summary
var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

# Unified display panel (parents all three viz pieces)
var _display_root: Node3D
var _layout_loaded := false

# Bar chart
var _bars_root: Node3D
var _bar_meshes: Array[MeshInstance3D] = []  # one per algo
var _bar_materials: Array[StandardMaterial3D] = []
var _bar_labels: Array[Label3D] = []          # step count text per bar
var _bar_badges: Array[Label3D] = []          # "past practical" chevron

# Readout panel
var _readout_root: Node3D
var _readout_n: Label3D
var _readout_rows: Array[Label3D] = []        # one row per algo
var _readout_past: Label3D

# Growth curves
var _curve_root: Node3D
var _curve_meshes: Array[ImmediateMesh] = []
var _curve_mesh_insts: Array[MeshInstance3D] = []
var _curve_materials: Array[StandardMaterial3D] = []

# Wall-clock line
var _wall_clock_inst: MeshInstance3D


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_build_algorithm_specs()
	_n = clampi(initial_n, n_min, n_max)
	_build_plate_and_slider()
	_build_display_anchor()
	_build_display_support()
	_build_bar_chart()
	_build_growth_curves()
	_build_readout_panel()
	_build_position_marker()
	_refresh_all()


func _build_algorithm_specs() -> void:
	# Palette mirrors /complexity-dial-gallery/manifest.json so the VR
	# workbench and the web frieze speak the same visual language.
	_algos = [
		AlgoSpec.new("log",  "O(log N)",   "log",   Color(0.62, 0.78, 0.95)),  # pale blue
		AlgoSpec.new("lin",  "O(N)",       "lin",   Color(0.36, 0.86, 0.94)),  # cyan
		AlgoSpec.new("nlog", "O(N log N)", "nlog",  Color(0.32, 0.78, 0.66)),  # teal
		AlgoSpec.new("quad", "O(N²)",      "quad",  Color(0.98, 0.72, 0.28)),  # amber
		AlgoSpec.new("exp",  "O(2^N)",     "exp",   Color(0.95, 0.36, 0.36)),  # red
	]


# ── Step count math ───────────────────────────────────────────────────

## Returns log10(step_count) for the given algorithm key at this N.
##
## Computing log10(steps) directly (rather than computing steps then
## taking the log) keeps 2^N representable even at N=60 — log10(2^60)
## is ~18, an ordinary float. The raw step count for 2^N at N=60 is
## 1.15e18 which is still within int64 range but display-formatted
## as "1.2×10^18".
static func _log10_steps(key: String, n_val: int) -> float:
	var n_f: float = float(n_val)
	match key:
		"log":
			# log2(N): log10(log2(N)). Bottom out at log2(1)=0 → use max(1, ...).
			var l2: float = max(1.0, log(max(1.0, n_f)) / log(2.0))
			return log(l2) / log(10.0)
		"lin":
			return log(max(1.0, n_f)) / log(10.0)
		"nlog":
			var l2_nlog: float = max(1.0, log(max(1.0, n_f)) / log(2.0))
			return log(max(1.0, n_f * l2_nlog)) / log(10.0)
		"quad":
			# log10(N²) = 2·log10(N)
			return 2.0 * log(max(1.0, n_f)) / log(10.0)
		"exp":
			# log10(2^N) = N · log10(2)
			return n_f * (log(2.0) / log(10.0))
	return 0.0


## Returns a human-readable step count string for the display label.
## For N > 18 (where the value won't fit nicely as an integer), prints
## "1.2×10^X" form.
static func _format_steps(key: String, n_val: int) -> String:
	var log_steps: float = _log10_steps(key, n_val)
	if log_steps < 6.0:
		# Compute exact integer for small values.
		var steps: int = _exact_steps_small(key, n_val)
		return _commafy(steps)
	# Scientific form: a × 10^e where 1 ≤ a < 10
	var e: int = int(floor(log_steps))
	var mantissa: float = pow(10.0, log_steps - float(e))
	if mantissa >= 9.95:
		mantissa = 1.0
		e += 1
	return "%.1f×10^%d" % [mantissa, e]


static func _exact_steps_small(key: String, n_val: int) -> int:
	var n_f: float = float(n_val)
	match key:
		"log":
			return int(max(1.0, log(max(1.0, n_f)) / log(2.0)))
		"lin":
			return n_val
		"nlog":
			var l2: int = int(max(1.0, log(max(1.0, n_f)) / log(2.0)))
			return n_val * l2
		"quad":
			return n_val * n_val
		"exp":
			# Safe up to N=60 in int64, but only call this in the < 1e6 branch.
			var v: int = 1
			for i in range(n_val):
				v *= 2
			return v
	return 0


static func _commafy(n_val: int) -> String:
	var s: String = str(n_val)
	var out: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = s[i] + out
		count += 1
	return out


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole (workbench principal) hosts the ONE knob +
	# a summary readout. The bar chart / growth curves / detail card are independent
	# world-space viz (children of self) and are unchanged. Also swaps the old jumpy
	# slider_horizontal for the canonical seated slider_smooth.
	_plate_root = InterfacePresets.build("workbench", "Complexity Dial", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)
	_plate_readout = _plate_root.add_readout("")
	_slider = _plate_root.add_slider("N (size)", "N")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _n_to_normalized(_n))
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _n_to_normalized(n_val: int) -> float:
	return float(n_val - n_min) / float(max(1, n_max - n_min))


func _normalized_to_n(t: float) -> int:
	# Round to nearest integer — N is an integer.
	return clampi(int(round(float(n_min) + clampf(t, 0.0, 1.0) * float(n_max - n_min))), n_min, n_max)


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var t: Variant = _slider.call("get_normalized_value")
	var new_n: int = _normalized_to_n(float(t))
	if new_n == _n:
		return
	_n = new_n
	_viz_dirty = true   # throttled rebuild (see _process) — keep the grab loop free


func _process(delta: float) -> void:
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_refresh_all()


# ── Bar chart (5 horizontal bars stacked) ─────────────────────────────

## Single anchor for the three viz pieces — stands above + forward of the
## console so the whole readout reads as one screen, clear of the controls.
func _build_display_anchor() -> void:
	# A web-composed layout (interface-composer → display_layout.json) overrides
	# the @export defaults, so placement is dragged in the browser, not guessed.
	var rot := Vector3(display_tilt_degrees, 0.0, 0.0)
	var layout := _load_display_layout()
	if not layout.is_empty():
		_layout_loaded = true
		display_offset = _arr_to_vec3(layout.get("display_offset", []), display_offset)
		if layout.has("display_scale"):
			display_scale = float(layout["display_scale"])
		rot = _arr_to_vec3(layout.get("display_rotation_degrees", []), rot)
	_display_root = Node3D.new()
	_display_root.name = "Display"
	_display_root.position = display_offset
	_display_root.scale = Vector3.ONE * display_scale
	_display_root.rotation_degrees = rot
	add_child(_display_root)

	# Bezel + screen so the bars / curve / readout read as one monitor face,
	# not three floating panels. Centered on the content's bounding box.
	var screen_center := Vector3(0.02, -0.16, 0.0)

	# Bezel is a thin slab (not a flat plane) so the monitor reads as a solid
	# object from any angle — and gives the support boom something to grip.
	var bezel := MeshInstance3D.new()
	bezel.name = "Bezel"
	var bezel_mesh := BoxMesh.new()
	bezel_mesh.size = Vector3(2.52, 1.28, 0.05)
	bezel.mesh = bezel_mesh
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = Color(0.13, 0.14, 0.16)
	bezel_mat.roughness = 0.8
	bezel.material_override = bezel_mat
	bezel.position = screen_center + Vector3(0.0, 0.0, -0.04)
	_display_root.add_child(bezel)

	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var screen_mesh := QuadMesh.new()
	screen_mesh.size = Vector2(2.40, 1.16)
	screen.mesh = screen_mesh
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.02, 0.03, 0.05)
	screen_mat.roughness = 0.95
	screen.material_override = screen_mat
	screen.position = screen_center + Vector3(0.0, 0.0, -0.005)
	_display_root.add_child(screen)


## A boom that carries the monitor up from the console rear — so the screen
## is held by structure, not floating. (Cables implied hidden inside.)
func _build_display_support() -> void:
	# Floor stand under the composed display — rises from the floor to the
	# screen's lower-rear so the panel is carried by structure wherever it sits.
	# Adapts to display_offset / display_scale (set by the interface-composer),
	# so a re-placed screen is always held, not floating. Cables implied inside.
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.60, 0.62, 0.64)
	steel.roughness = 0.55
	steel.metallic = 0.3
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.17, 0.18, 0.20)
	dark.roughness = 0.7
	var cx: float = display_offset.x
	var cz: float = display_offset.z
	var floor_y: float = 0.40                                    # console base plane
	var bottom_y: float = display_offset.y - 0.74 * display_scale  # screen lower edge
	var pole_z: float = cz - 0.10                                # just behind the screen
	var pole_h: float = maxf(0.2, bottom_y - floor_y)
	_sbox("StandFoot", Vector3(cx, floor_y + 0.04, pole_z), Vector3(0.55, 0.08, 0.46), steel)
	_sbox("StandPole", Vector3(cx, floor_y + pole_h * 0.5, pole_z), Vector3(0.13, pole_h, 0.13), dark)
	_sbox("StandMount", Vector3(cx, bottom_y + 0.05, cz - 0.02), Vector3(0.36, 0.24, 0.16), steel)


## DEBUG marker — a bright cube a clear distance in front of the console, with
## a rod from the interface front face showing the frontward distance. Lets us
## agree on where the visualization should sit before moving it there.
func _build_position_marker() -> void:
	if not show_marker:
		return
	var rod_mat := StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.2, 0.9, 1.0)
	rod_mat.emission_enabled = true
	rod_mat.emission = Color(0.2, 0.9, 1.0)
	rod_mat.emission_energy_multiplier = 2.0
	var mark_mat := StandardMaterial3D.new()
	mark_mat.albedo_color = Color(1.0, 0.1, 0.7)
	mark_mat.emission_enabled = true
	mark_mat.emission = Color(1.0, 0.1, 0.7)
	mark_mat.emission_energy_multiplier = 2.5
	# Console front face sits at ~z0.10 (measured). Rod runs along Z from there
	# to the composed display plane, so the set-out distance is visible whether
	# the panel is in front (+Z) or set out beyond the console (-Z).
	var front_z: float = 0.10
	var target_z: float = display_offset.z
	var my: float = display_offset.y
	var rod_len: float = maxf(0.05, absf(target_z - front_z))
	_sbox("MeasureTick", Vector3(display_offset.x, my, front_z), Vector3(0.18, 0.18, 0.02), rod_mat)
	_sbox("MeasureRod", Vector3(display_offset.x, my, (front_z + target_z) * 0.5), Vector3(0.03, 0.03, rod_len), rod_mat)
	_sbox("MeasureMarker", Vector3(display_offset.x, my, target_z), Vector3(0.16, 0.16, 0.16), mark_mat)


func _sbox(node_name: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


## Read a web-composed placement (interface-composer writes it). Empty if none.
func _load_display_layout() -> Dictionary:
	var p := "res://commons/artifacts/complexity_dial_workbench/display_layout.json"
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


func _arr_to_vec3(a: Variant, fallback: Vector3) -> Vector3:
	if a is Array and a.size() == 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return fallback


func _build_bar_chart() -> void:
	_bars_root = Node3D.new()
	_bars_root.name = "BarChart"
	_bars_root.position = bar_chart_offset
	_display_root.add_child(_bars_root)

	# Backplate — gives bars a frame to read against.
	var back := MeshInstance3D.new()
	back.name = "BarBackplate"
	var back_mesh := QuadMesh.new()
	var back_h: float = bar_spacing * float(_algos.size()) + 0.06
	back_mesh.size = Vector2(bar_chart_width + 0.16, back_h)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.03, 0.05)
	back_mat.roughness = 0.95
	back.material_override = back_mat
	back.position = Vector3(bar_chart_width * 0.5 + 0.04, -back_h * 0.5 + bar_spacing * 0.5, -0.005)
	_bars_root.add_child(back)

	# Wall-clock line — vertical dashed marker at log10(threshold) = 9.
	_build_wall_clock_line(back_h)

	_bar_meshes.clear()
	_bar_materials.clear()
	_bar_labels.clear()
	_bar_badges.clear()

	for i in range(_algos.size()):
		var algo: AlgoSpec = _algos[i]
		var row_y: float = -float(i) * bar_spacing

		# Bar (BoxMesh; scaled in X by step count log).
		var bar := MeshInstance3D.new()
		bar.name = "Bar_%s" % algo.key
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(1.0, bar_thickness, 0.04)
		bar.mesh = bar_mesh

		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = algo.color
		bar_mat.emission_enabled = true
		bar_mat.emission = algo.color
		bar_mat.emission_energy_multiplier = 1.2
		bar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bar.material_override = bar_mat
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# Bar is positioned by its center; we scale so length grows from x=0.
		bar.position = Vector3(0.0, row_y, 0.0)
		_bars_root.add_child(bar)
		_bar_meshes.append(bar)
		_bar_materials.append(bar_mat)

		# Algorithm name label, left of the bar at x=-0.02.
		var name_label := Label3D.new()
		name_label.name = "Name_%s" % algo.key
		name_label.text = algo.complexity
		name_label.font_size = 22
		name_label.pixel_size = 0.001
		name_label.outline_size = 3
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_label.modulate = algo.color
		name_label.position = Vector3(-0.02, row_y, 0.01)
		_bars_root.add_child(name_label)

		# Step count label, sits at the end of the bar.
		var step_label := Label3D.new()
		step_label.name = "Steps_%s" % algo.key
		step_label.font_size = 20
		step_label.pixel_size = 0.001
		step_label.outline_size = 3
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		step_label.modulate = Color(0.95, 0.95, 1.0)
		_bars_root.add_child(step_label)
		_bar_labels.append(step_label)

		# Past-practical badge — initially hidden.
		var badge := Label3D.new()
		badge.name = "Badge_%s" % algo.key
		badge.text = "✕ past practical"
		badge.font_size = 18
		badge.pixel_size = 0.001
		badge.outline_size = 3
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		badge.modulate = Color(1.0, 0.4, 0.4)
		badge.visible = false
		_bars_root.add_child(badge)
		_bar_badges.append(badge)


func _build_wall_clock_line(back_h: float) -> void:
	# Position: x = bar_chart_width (i.e. where log10(steps) = practical_log_threshold)
	# Wait — bars are scaled so that x=bar_chart_width maps to log_threshold. Yes:
	#   bar_length_x = (log10_steps / practical_log_threshold) * bar_chart_width
	# So the threshold marker sits exactly at x = bar_chart_width.
	_wall_clock_inst = MeshInstance3D.new()
	_wall_clock_inst.name = "WallClockLine"
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Dashed effect: emit short line segments.
	var top_y: float = bar_spacing * 0.5
	var bot_y: float = -bar_spacing * (float(_algos.size()) - 0.5)
	var dash_step: float = 0.025
	var y: float = top_y
	var on: bool = true
	while y > bot_y:
		var y_next: float = y - dash_step
		if on:
			mesh.surface_add_vertex(Vector3(bar_chart_width, y, 0.003))
			mesh.surface_add_vertex(Vector3(bar_chart_width, max(y_next, bot_y), 0.003))
		on = not on
		y = y_next
	mesh.surface_end()
	_wall_clock_inst.mesh = mesh
	_wall_clock_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var wc_mat := StandardMaterial3D.new()
	wc_mat.albedo_color = Color(1.0, 0.45, 0.45)
	wc_mat.emission_enabled = true
	wc_mat.emission = Color(1.0, 0.5, 0.5)
	wc_mat.emission_energy_multiplier = 2.0
	wc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wall_clock_inst.material_override = wc_mat
	_bars_root.add_child(_wall_clock_inst)

	# Label: "1 sec @ 10^9 ops"
	var wc_label := Label3D.new()
	wc_label.name = "WallClockLabel"
	wc_label.text = "wall clock — 10⁹ ops/sec"
	wc_label.font_size = 16
	wc_label.pixel_size = 0.001
	wc_label.outline_size = 3
	wc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wc_label.modulate = Color(1.0, 0.55, 0.55)
	wc_label.rotation_degrees.z = 90.0
	wc_label.position = Vector3(bar_chart_width + 0.045, -bar_spacing * (float(_algos.size()) - 1.0) * 0.5, 0.0)
	_bars_root.add_child(wc_label)


func _refresh_bars() -> void:
	if _bar_meshes.is_empty():
		return
	for i in range(_algos.size()):
		var algo: AlgoSpec = _algos[i]
		var log_steps: float = _log10_steps(algo.key, _n)
		# Length on the chart: clamp at the practical threshold + a small
		# overshoot margin so exponential bars visibly punch into the
		# past-practical zone but don't fly across the table.
		var max_len_factor: float = 1.18  # 18% overshoot past threshold
		var t: float = clampf(log_steps / practical_log_threshold, 0.0, max_len_factor)
		var bar_len: float = t * bar_chart_width
		var bar: MeshInstance3D = _bar_meshes[i]

		# Box mesh has size 1×bar_thickness×0.04; scale X by bar_len; offset so
		# the bar grows from the left edge (x=0) instead of being centered.
		bar.scale = Vector3(bar_len, 1.0, 1.0)
		bar.position.x = bar_len * 0.5

		# Step count text floats just past the end of the bar.
		var label: Label3D = _bar_labels[i]
		label.text = _format_steps(algo.key, _n)
		label.position = Vector3(bar_len + 0.02, -float(i) * bar_spacing, 0.01)

		# Past-practical badge.
		var badge: Label3D = _bar_badges[i]
		var past: bool = log_steps > practical_log_threshold
		badge.visible = past
		if past:
			# Place badge after the step count text — push out further.
			badge.position = Vector3(bar_len + 0.18, -float(i) * bar_spacing, 0.01)
			# Make bar pulse red-tinted when past practical.
			var mat: StandardMaterial3D = _bar_materials[i]
			mat.emission_energy_multiplier = 2.4
		else:
			var mat2: StandardMaterial3D = _bar_materials[i]
			mat2.emission_energy_multiplier = 1.2


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	# Right of the bar chart, within the unified display panel.
	_readout_root.position = Vector3(0.69, 0.0, 0.0)
	_display_root.add_child(_readout_root)

	# Dark backing card.
	var card := MeshInstance3D.new()
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.48, 0.6)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.03, 0.05, 0.08)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.24, -0.16, -0.005)
	_readout_root.add_child(card)

	# Big "N = NN" header.
	_readout_n = Label3D.new()
	_readout_n.name = "ReadoutN"
	_readout_n.font_size = 56
	_readout_n.outline_size = 5
	_readout_n.pixel_size = 0.001
	_readout_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_n.modulate = Color(1.0, 1.0, 0.65)
	_readout_n.position = Vector3(0.02, 0.07, 0.0)
	_readout_root.add_child(_readout_n)

	# 5 algorithm rows.
	_readout_rows.clear()
	for i in range(_algos.size()):
		var algo: AlgoSpec = _algos[i]
		var row := Label3D.new()
		row.name = "Row_%s" % algo.key
		row.font_size = 18
		row.outline_size = 3
		row.pixel_size = 0.001
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.modulate = algo.color
		row.position = Vector3(0.02, -0.02 - float(i) * 0.05, 0.0)
		_readout_root.add_child(row)
		_readout_rows.append(row)

	# Past-practical count row.
	_readout_past = Label3D.new()
	_readout_past.name = "ReadoutPast"
	_readout_past.font_size = 22
	_readout_past.outline_size = 3
	_readout_past.pixel_size = 0.001
	_readout_past.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_past.modulate = Color(1.0, 0.5, 0.5)
	_readout_past.position = Vector3(0.02, -0.32, 0.0)
	_readout_root.add_child(_readout_past)


func _refresh_readout() -> void:
	_readout_n.text = "N = %d" % _n
	var past_count: int = 0
	for i in range(_algos.size()):
		var algo: AlgoSpec = _algos[i]
		var log_steps: float = _log10_steps(algo.key, _n)
		var step_str: String = _format_steps(algo.key, _n)
		_readout_rows[i].text = "%s :  %s steps" % [algo.complexity, step_str]
		if log_steps > practical_log_threshold:
			past_count += 1
	_readout_past.text = "algorithms past practical: %d / 5" % past_count
	if _plate_readout:
		_plate_readout.text = "N = %d\n%d / 5 past practical" % [_n, past_count]


# ── Growth curves (small line graph at the bottom) ────────────────────

func _build_growth_curves() -> void:
	_curve_root = Node3D.new()
	_curve_root.name = "GrowthCurves"
	_curve_root.position = curve_offset
	_display_root.add_child(_curve_root)

	# Backplate for the curve panel.
	var back := MeshInstance3D.new()
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(curve_width + 0.06, curve_height + 0.06)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.03, 0.05)
	back_mat.roughness = 0.95
	back.material_override = back_mat
	back.position = Vector3(curve_width * 0.5, curve_height * 0.5, -0.005)
	_curve_root.add_child(back)

	# Wall-clock horizontal reference (log10(steps) = 9) — gridline.
	var ref_mesh := ImmediateMesh.new()
	ref_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var ref_y: float = (practical_log_threshold / 18.0) * curve_height  # y-axis spans 0..18 log
	# Dashed.
	var dash_step: float = 0.03
	var x: float = 0.0
	var on: bool = true
	while x < curve_width:
		var x_next: float = x + dash_step
		if on:
			ref_mesh.surface_add_vertex(Vector3(x, ref_y, 0.001))
			ref_mesh.surface_add_vertex(Vector3(min(x_next, curve_width), ref_y, 0.001))
		on = not on
		x = x_next
	ref_mesh.surface_end()

	var ref_inst := MeshInstance3D.new()
	ref_inst.name = "WallClockRef"
	ref_inst.mesh = ref_mesh
	ref_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ref_mat := StandardMaterial3D.new()
	ref_mat.albedo_color = Color(0.95, 0.45, 0.45)
	ref_mat.emission_enabled = true
	ref_mat.emission = Color(0.95, 0.5, 0.5)
	ref_mat.emission_energy_multiplier = 1.4
	ref_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ref_inst.material_override = ref_mat
	_curve_root.add_child(ref_inst)

	# 5 curves — one ImmediateMesh per algorithm.
	_curve_meshes.clear()
	_curve_mesh_insts.clear()
	_curve_materials.clear()
	for i in range(_algos.size()):
		var algo: AlgoSpec = _algos[i]
		var mesh := ImmediateMesh.new()
		var inst := MeshInstance3D.new()
		inst.name = "Curve_%s" % algo.key
		inst.mesh = mesh
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var mat := StandardMaterial3D.new()
		mat.albedo_color = algo.color
		mat.emission_enabled = true
		mat.emission = algo.color
		mat.emission_energy_multiplier = 1.8
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		inst.material_override = mat

		_curve_root.add_child(inst)
		_curve_meshes.append(mesh)
		_curve_mesh_insts.append(inst)
		_curve_materials.append(mat)

	# Title label.
	var title := Label3D.new()
	title.text = "growth curves  (log y, N=1..%d)" % n_max
	title.font_size = 16
	title.pixel_size = 0.001
	title.outline_size = 3
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.modulate = Color(0.65, 0.7, 0.8)
	title.position = Vector3(0.0, curve_height + 0.025, 0.0)
	_curve_root.add_child(title)


func _refresh_growth_curves() -> void:
	# Y-axis: log10(steps), scaled to fit 0..18 in curve_height.
	# X-axis: N, scaled to fit n_min..current_n in curve_width.
	# As the slider moves, the curves redraw from N=1 to current N — so the
	# polynomial curves bend gently and the exponential ramps at ~45°.
	var y_max: float = 18.0
	var n_target: int = _n
	var n_span: float = float(max(1, n_target - n_min))
	for i in range(_algos.size()):
		var algo: AlgoSpec = _algos[i]
		var mesh: ImmediateMesh = _curve_meshes[i]
		mesh.clear_surfaces()
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		# Sample at every integer N from n_min to n_target so the curve
		# faithfully shows where each algorithm becomes legible.
		for nv in range(n_min, n_target + 1):
			var x: float = (float(nv - n_min) / n_span) * curve_width
			var log_v: float = _log10_steps(algo.key, nv)
			var y: float = clampf(log_v / y_max, 0.0, 1.0) * curve_height
			mesh.surface_add_vertex(Vector3(x, y, 0.002))
		mesh.surface_end()


# ── Refresh ───────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_bars()
	_refresh_readout()
	_refresh_growth_curves()


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_n"):
		_n = clampi(int(config_data["initial_n"]), n_min, n_max)
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _n_to_normalized(_n))
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("practical_log_threshold"):
		practical_log_threshold = float(config_data["practical_log_threshold"])
		_refresh_all()
