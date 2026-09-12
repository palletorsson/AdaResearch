# additive_wave_demo.gd
# Interactive Additive Wave Synthesis demonstration
# Shows how complex waveforms are built from sine harmonics
extends Node3D

class_name AdditiveWaveDemo
## Demonstrates additive wave synthesis: building complex waveforms from sine harmonics.
## Uses the Fourier principle: f(t) = Σ Aₙ·sin(n·ωt + φₙ), where each harmonic
## contributes a sine wave at integer multiples of the fundamental frequency.
## Sliders control amplitudes of harmonics 1–5; preset detection identifies
## square, sawtooth, and triangle waves by their harmonic signatures.

# @identity
# essence: f(x) = sum(a_n * sin(n * omega * x)) — Fourier additive synthesis
# desire: Stack harmonics with VR sliders and watch complex waveforms build from pure sines
# critical_parameter: harmonic_amplitudes[] — each slider adds one frequency component
# triggers: slider movement updates harmonic amplitudes; waveform redraws in real-time
# emerges: square waves from odd harmonics, sawtooth from all — Fourier theorem made tactile
# needs: VR sliders for 5 harmonics [has], preset buttons [has]
# relationships: depends on fundamental + harmonics; contrasts with timbre_sculptor (visual vs audible synthesis); unlocks Fourier intuition
# truth: Any periodic function is a sum of sines; complexity is superposition of simplicity.

## STAGE-2 DNA PROMOTION (2026-07-29). Before this the demo had five NodePath
## exports and nothing else turnable: every one of its 9 placements showed the
## identical frame — one green sine, the label "f(t) = 1.0·sin(ωt)", four dead
## slider tracks. The Fourier claim ("any shape is a sum of sines") was written on
## the label and never shown, because the only way to see a second harmonic was to
## be in VR with your hand on a slider. A still of this artifact argued nothing.
##
## Two axes, both lifted from constants that were already in this file:
##
##   waveform    WHICH sum the demo stands at    sine · square · sawtooth · triangle · clear
##               (the amplitude tables in set_preset, previously reachable only by a
##               caller nobody wrote)
##   components  HOW the parts are shown         ladder · overlay · hidden
##               (the -0.35 - h*0.15 vertical offset in _draw_component_waves)
##
## The two axes argue different things. `waveform` decides whether the visitor
## meets synthesis at its start (a bare sine, build it yourself) or at its end (a
## sawtooth, already assembled — complexity as the normal case). `components`
## decides whether the harmonics are an INGREDIENT LIST hung below the result
## (ladder), a literal SUPERPOSITION drawn on the same axis so the sum is visibly
## the lines added (overlay), or withheld so only the result shows (hidden) — the
## black-box reading, where a waveform is a shape and not a sum.
##
## waveform=sine + components=ladder is exactly the pre-promotion behaviour and is
## the default, so all 9 existing placements are untouched.
##
## Usage in map_data.json:
##   "additive_wave_demo"
##   "additive_wave_demo#waveform:sawtooth"
##   "additive_wave_demo#waveform:square#components:overlay"
##
## THE BENCH (2026-09-11, Waves/Chance/Noise W4, WaveFunctions_Synthesis_Lab). A third,
## opt-in axis, `stand`, stages the same instrument for a body: the shipped scene hangs
## its component ladder from -0.35 to -1.15 below the origin, so on a 0.5 m placement
## harmonics 2–5 are drawn under the floor, and its five sliders stand in front of the
## sum's right third. Under `stand:bench` the display (sum, ladder, labels) is lifted
## onto a backboard with every row above a bench-top sight line, the sliders become a
## console at the bench's right end, a SUM panel offers BASELINE (the arrival
## coefficients), H1 ALONE (the first harmonic by itself) and HOLD (stop the scroll so a
## place on the display can be read), and a housed readout prints the five coefficients,
## the arrival five, each row's value at a marker, the sum of the drawn rows against the
## drawn total, and which coefficients differ from the arrival. The sum and the rows are
## drawn as ribbons under the bench (a one-pixel line strip vanishes in a capture).
## `stand:none` (the default) is byte-for-byte the previous behaviour.
##
##   "additive_wave_demo:0#stand:bench#waveform:sawtooth"

## Which harmonic signature the demo stands at when a visitor arrives.
@export_enum("sine", "square", "sawtooth", "triangle", "clear") var waveform: String = "sine"
## How the individual harmonics are drawn against the sum.
@export_enum("ladder", "overlay", "hidden") var components: String = "ladder"
## The staging: `none` (the shipped scene as it is) or `bench` (see THE BENCH above).
@export_enum("none", "bench") var stand: String = "none"

## Path to the fundamental frequency slider in the scene tree
@export var fundamental_slider_path: NodePath = "ControlPanel/FundamentalSlider"
## Path to the 2nd harmonic slider
@export var harmonic2_slider_path: NodePath = "ControlPanel/Harmonic2Slider"
## Path to the 3rd harmonic slider
@export var harmonic3_slider_path: NodePath = "ControlPanel/Harmonic3Slider"
## Path to the 4th harmonic slider
@export var harmonic4_slider_path: NodePath = "ControlPanel/Harmonic4Slider"
## Path to the 5th harmonic slider
@export var harmonic5_slider_path: NodePath = "ControlPanel/Harmonic5Slider"

## Visual elements
@onready var wave_mesh: MeshInstance3D = $WaveMesh
@onready var component_meshes: Node3D = $ComponentWaves
@onready var formula_label: Label3D = $FormulaLabel
@onready var preset_label: Label3D = $PresetLabel

## Sliders
var fundamental_slider
var harmonic_sliders: Array = []

## Parameters
var harmonic_amplitudes: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0]
var base_frequency: float = 1.0
var show_components: bool = true

## Wave rendering
const WAVE_POINTS: int = 256
const WAVE_LENGTH: float = 2.0  # Visual length in meters
const NUM_HARMONICS: int = 5
var _time: float = 0.0

## Dirty flag — set when harmonic parameters change so labels are rebuilt
var _dirty: bool = true

## True once _ready has built the meshes. apply_grid_config must not touch the
## visualization before that: the ImmediateMesh objects do not exist yet, and a
## rebuild from an empty state is how shipped placements get broken.
var _built: bool = false

## Cached ImmediateMesh objects (reused each frame instead of allocating new ones)
var _combined_im: ImmediateMesh
var _component_ims: Array[ImmediateMesh] = []

## Shared material for component wave rendering
var _component_mat: StandardMaterial3D

## Colors for harmonics
var harmonic_colors: Array[Color] = [
	Color(0.2, 1.0, 0.4),    # Fundamental - green
	Color(0.2, 0.6, 1.0),    # 2nd - blue
	Color(1.0, 0.4, 0.8),    # 3rd - pink
	Color(1.0, 0.8, 0.2),    # 4th - yellow
	Color(0.8, 0.4, 1.0),    # 5th - purple
]

# ── the bench (stand:bench only) ────────────────────────────────────────────
## The display's origin above the deck: rows at LIFT - 0.35 - h*0.15 (1.40 … 0.80 m),
## which clears the bench's back edge and the readout's top edge from a standing eye.
const LIFT: float = 1.75
const BENCH_H: float = 0.92
const BENCH_W: float = 2.90
const BENCH_D: float = 0.50
const BENCH_Z: float = 0.70       # the bench's centre; it spans z 0.45 … 0.95
## Where the marker stands along the display, 0 … 1 (sample MARK_T · (WAVE_POINTS - 1)).
const MARK_T: float = 0.625
const RIBBON_SUM: float = 0.007   # half-thickness of the drawn sum
const RIBBON_ROW: float = 0.0045  # half-thickness of a drawn row
## The display does not scroll while held (the scroll is _time advancing).
var held: bool = false
var _staging_root: Node3D
var _panel: Node3D
var _readout_case: Node3D
var _readout: Label3D
var _marker: MeshInstance3D
## The coefficients the visitor arrived at (the placed preset); BASELINE restores them.
var _baseline: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0]
var _readout_clock: float = 0.0

signal waveform_changed(amplitudes: Array[float])

func _ready() -> void:
	# Create cached ImmediateMesh for the combined wave
	_combined_im = ImmediateMesh.new()
	if wave_mesh:
		wave_mesh.mesh = _combined_im

	# Pre-allocate component ImmediateMesh objects
	_component_ims.resize(NUM_HARMONICS)
	for i in NUM_HARMONICS:
		_component_ims[i] = ImmediateMesh.new()

	# Shared material for all component waves (colors set per-vertex)
	_component_mat = StandardMaterial3D.new()
	_component_mat.vertex_color_use_as_albedo = true
	_component_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_component_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_setup_sliders()
	_setup_component_meshes()
	# DNA axes. waveform=sine writes exactly the amplitudes the sliders were just
	# given ([1,0,0,0,0]), so the default path is a no-op on the legacy look.
	show_components = components != "hidden"
	set_preset(waveform)
	_baseline = harmonic_amplitudes.duplicate()
	_built = true
	_update_visualization()
	_apply_stand()

## Connects slider nodes to harmonic amplitude controls
func _setup_sliders() -> void:
	fundamental_slider = get_node_or_null(fundamental_slider_path)
	if fundamental_slider:
		fundamental_slider.set_range(0.0, 1.0)
		fundamental_slider.set_param_name("H1")
		fundamental_slider.set_normalized_value(1.0)
		fundamental_slider.slider_moved.connect(_on_harmonic_changed.bind(0))
		harmonic_sliders.append(fundamental_slider)

	var paths = [harmonic2_slider_path, harmonic3_slider_path, harmonic4_slider_path, harmonic5_slider_path]
	for i in range(paths.size()):
		var slider = get_node_or_null(paths[i])
		if slider:
			slider.set_range(0.0, 1.0)
			slider.set_param_name("H%d" % (i + 2))
			slider.set_normalized_value(0.0)
			slider.slider_moved.connect(_on_harmonic_changed.bind(i + 1))
			harmonic_sliders.append(slider)

## Creates MeshInstance3D nodes for visualizing individual harmonic components
func _setup_component_meshes() -> void:
	if not component_meshes:
		component_meshes = Node3D.new()
		component_meshes.name = "ComponentWaves"
		add_child(component_meshes)

	for i in range(NUM_HARMONICS):
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Harmonic%d" % (i + 1)
		mesh_instance.material_override = _component_mat
		mesh_instance.mesh = _component_ims[i]
		component_meshes.add_child(mesh_instance)

func _process(delta: float) -> void:
	# Bound the accumulator to prevent floating-point precision loss over long sessions
	if not held:
		_time = fmod(_time + delta * base_frequency, 1000.0)
	# Meshes must rebuild every frame because the wave animates over time.
	# Labels only need updating when harmonic parameters change (_dirty).
	_draw_combined_wave()
	if show_components:
		_draw_component_waves()
	if _dirty:
		_update_labels()
		_dirty = false
		_update_readout()
	elif _readout != null and not held:
		# the values at the marker move with the scroll: ten times a second is readable
		_readout_clock += delta
		if _readout_clock >= 0.1:
			_readout_clock = 0.0
			_update_readout()

## Redraws combined and component waves, updates formula labels
func _update_visualization() -> void:
	_draw_combined_wave()
	if show_components:
		_draw_component_waves()
	_update_labels()
	_update_readout()

## Draws the summed waveform into the reusable combined ImmediateMesh
func _draw_combined_wave() -> void:
	if not wave_mesh:
		return

	_combined_im.clear_surfaces()

	if WAVE_POINTS < 2:
		return

	var pts := PackedVector3Array()
	var cols := PackedColorArray()
	for i in range(WAVE_POINTS):
		var t = float(i) / (WAVE_POINTS - 1)
		var x = (t - 0.5) * WAVE_LENGTH
		var phase = t * TAU * 4.0 + _time * TAU

		# Sum all harmonics
		var y = _calculate_wave_value(phase)

		# Color based on amplitude
		var brightness = 0.5 + abs(y) * 0.5
		cols.append(Color(brightness, brightness * 1.2, brightness * 0.8))
		pts.append(Vector3(x, y * 0.3, 0))

	_emit_strip(_combined_im, pts, cols, RIBBON_SUM if stand == "bench" else 0.0)

## Draws each harmonic as a separate wave line below the combined wave
func _draw_component_waves() -> void:
	if WAVE_POINTS < 2:
		return

	for h in range(NUM_HARMONICS):
		var mesh_node = component_meshes.get_child(h) as MeshInstance3D
		if not mesh_node:
			continue

		if harmonic_amplitudes[h] < 0.01:
			mesh_node.visible = false
			continue

		mesh_node.visible = true
		var im := _component_ims[h]
		im.clear_surfaces()

		var color = harmonic_colors[h]
		# overlay draws the parts ON the sum, so they must be fainter than the
		# ladder's already-faint 0.4 or the result is unreadable through them
		color.a = 0.28 if components == "overlay" else 0.4
		if stand == "bench" and components != "overlay":
			color.a = 0.85   # a ribbon on a dark backboard

		var pts := PackedVector3Array()
		var cols := PackedColorArray()
		for i in range(WAVE_POINTS):
			var t = float(i) / (WAVE_POINTS - 1)
			var x = (t - 0.5) * WAVE_LENGTH
			var phase = t * TAU * 4.0 + _time * TAU

			# Single harmonic
			var y = harmonic_amplitudes[h] * sin(phase * (h + 1))

			cols.append(color)
			pts.append(_component_vertex(x, y, h))

		_emit_strip(im, pts, cols, RIBBON_ROW if stand == "bench" else 0.0)

## One polyline into an ImmediateMesh: the shipped LINE_STRIP when `half` is 0, else a
## flat ribbon of triangles of that half-thickness (the bench; a one-pixel line strip
## vanishes in a capture). Six vertices per segment: a+n, b+n, b-n, a+n, b-n, a-n —
## the point at sample k is the mean of vertices 6k and 6k+5.
func _emit_strip(im: ImmediateMesh, pts: PackedVector3Array, cols: PackedColorArray, half: float) -> void:
	if half <= 0.0:
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(pts.size()):
			im.surface_set_color(cols[i])
			im.surface_add_vertex(pts[i])
		im.surface_end()
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d: Vector3 = b - a
		if d.length() < 0.000001:
			d = Vector3(0.001, 0.0, 0.0)
		var n: Vector3 = Vector3(-d.y, d.x, 0.0).normalized() * half
		for q in [a + n, b + n, b - n, a + n, b - n, a - n]:
			im.surface_set_color(cols[i])
			im.surface_add_vertex(q)
	im.surface_end()

## Where one harmonic's sample sits, per the `components` axis.
## ladder  — stacked below the sum, an ingredient list (legacy: y*0.2 - 0.35 - h*0.15)
## overlay — drawn at the sum's own scale and on its own axis, so the combined
##           wave is visibly these lines added rather than a shape beside them
func _component_vertex(x: float, y: float, h: int) -> Vector3:
	if components == "overlay":
		return Vector3(x, y * 0.3, 0.02)
	return Vector3(x, y * 0.2 - 0.35 - h * 0.15, 0.1)

## Computes the sum of all harmonics at the given phase angle
func _calculate_wave_value(phase: float) -> float:
	var value = 0.0
	for h in range(harmonic_amplitudes.size()):
		value += harmonic_amplitudes[h] * sin(phase * (h + 1))
	return value

## Updates the formula display and preset detection label
func _update_labels() -> void:
	if formula_label:
		var active_terms = []
		for h in range(harmonic_amplitudes.size()):
			if harmonic_amplitudes[h] > 0.01:
				if h == 0:
					active_terms.append("%.1f·sin(ωt)" % harmonic_amplitudes[h])
				else:
					active_terms.append("%.1f·sin(%dωt)" % [harmonic_amplitudes[h], h + 1])

		if active_terms.size() > 0:
			formula_label.text = "f(t) = " + " + ".join(active_terms)
		else:
			formula_label.text = "f(t) = 0"

	if preset_label:
		var preset = _detect_preset()
		preset_label.text = preset

## Checks if current harmonic amplitudes match a known waveform type
func _detect_preset() -> String:
	# Check if current settings match known waveforms
	var a = harmonic_amplitudes

	# Square wave: odd harmonics with 1/n amplitude
	if a[0] > 0.9 and a[1] < 0.1 and abs(a[2] - a[0]/3.0) < 0.1 and a[3] < 0.1:
		return "≈ Square Wave (odd harmonics)"

	# Sawtooth: all harmonics with 1/n amplitude
	if a[0] > 0.9 and abs(a[1] - a[0]/2.0) < 0.15 and abs(a[2] - a[0]/3.0) < 0.15:
		return "≈ Sawtooth Wave (all harmonics)"

	# Triangle: odd harmonics with 1/n² amplitude
	if a[0] > 0.9 and a[1] < 0.1 and abs(a[2] - a[0]/9.0) < 0.1:
		return "≈ Triangle Wave"

	# Pure sine
	if a[0] > 0.5 and a[1] < 0.1 and a[2] < 0.1 and a[3] < 0.1 and a[4] < 0.1:
		return "Pure Sine Wave"

	return "Custom Waveform"

## Handles slider value changes for a specific harmonic index
func _on_harmonic_changed(_value, harmonic_index: int) -> void:
	if harmonic_index < harmonic_sliders.size() and harmonic_sliders[harmonic_index]:
		harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
		_dirty = true
		waveform_changed.emit(harmonic_amplitudes)

## Cleans up dynamically created nodes when exiting the tree
func _exit_tree() -> void:
	if component_meshes:
		for child in component_meshes.get_children():
			if is_instance_valid(child):
				child.queue_free()

# Public API

## Applies a named harmonic preset (sine, square, sawtooth, triangle, clear)
func set_preset(preset_name: String) -> void:
	match preset_name:
		"sine":
			_set_amplitudes([1.0, 0.0, 0.0, 0.0, 0.0])
		"square":
			# Square wave: only odd harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.0, 0.333, 0.0, 0.2])
		"sawtooth":
			# Sawtooth: all harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
		"triangle":
			# Triangle: odd harmonics, amplitude 1/n²
			_set_amplitudes([1.0, 0.0, 0.111, 0.0, 0.04])
		"clear":
			_set_amplitudes([0.0, 0.0, 0.0, 0.0, 0.0])

## Sets all harmonic amplitudes and updates corresponding sliders
func _set_amplitudes(amps: Array) -> void:
	for i in range(min(amps.size(), harmonic_amplitudes.size())):
		harmonic_amplitudes[i] = amps[i]
		if i < harmonic_sliders.size() and harmonic_sliders[i]:
			harmonic_sliders[i].set_normalized_value(amps[i])
	_dirty = true

## Toggles visibility of individual harmonic component waves
func toggle_components() -> void:
	show_components = not show_components
	_dirty = true

## Grid system integration.
## Guarded: nothing is redrawn unless a value actually changed AND _ready has already
## built the meshes once. An unguarded rebuild here would break the placements this
## promotion exists to leave alone.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("waveform"):
		var w: String = str(config_data["waveform"])
		if w != waveform:
			waveform = w
			changed = true
	if config_data.has("components"):
		var c: String = str(config_data["components"])
		if c != components:
			components = c
			changed = true
	if config_data.has("stand"):
		var s: String = str(config_data["stand"]).to_lower()
		var s2: String = "bench" if s in ["bench", "desk", "table", "stand"] else "none"
		if s2 != stand:
			stand = s2
			changed = true
	if not changed or not _built:
		return
	show_components = components != "hidden"
	set_preset(waveform)
	_baseline = harmonic_amplitudes.duplicate()
	if not show_components and component_meshes:
		for child in component_meshes.get_children():
			var m: MeshInstance3D = child as MeshInstance3D
			if m:
				m.visible = false
	_apply_stand()
	_update_visualization()

# ═════════════════════════════════════════════════════════════════════
# THE BENCH — the staging (stand:bench), its panel and its readout
# ═════════════════════════════════════════════════════════════════════

func _apply_stand() -> void:
	if stand == "bench" and _staging_root == null:
		_build_bench()
	elif stand != "bench" and _staging_root != null:
		_teardown_bench()

## Lift the display onto a backboard, put the console on the bench, add the SUM panel,
## the readout and the marker. Every node the shipped scene has keeps its name; only
## positions change, and the staging lives under one "Staging" node.
func _build_bench() -> void:
	_staging_root = Node3D.new()
	_staging_root.name = "Staging"
	add_child(_staging_root)
	# ── the display, lifted ──
	if wave_mesh:
		wave_mesh.position.y = LIFT
		# the sum's ribbon faces the visitor; culling is off so a turned ribbon still shows
		if wave_mesh.material_override != null:
			var m: Material = wave_mesh.material_override.duplicate()
			if m is BaseMaterial3D:
				(m as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
			wave_mesh.material_override = m
	if _component_mat != null:
		_component_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if component_meshes:
		component_meshes.position.y = LIFT
	if formula_label:
		formula_label.position.y = 0.6 + LIFT
	if preset_label:
		preset_label.position.y = 0.45 + LIFT
	var title: Node3D = get_node_or_null("TitleLabel")
	if title != null:
		title.position.y = 0.8 + LIFT
	var base: Node3D = get_node_or_null("Base")
	if base != null:
		base.position = Vector3(0.0, 0.01, 0.0)   # the foot plate, on the deck
	var expl: Node3D = get_node_or_null("ExplanationLabel")
	if expl != null:
		# the shipped caption, onto the bench's front face
		expl.position = Vector3(0.0, 0.62, BENCH_Z + BENCH_D * 0.5 + 0.011)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.16, 0.17)
	dark.roughness = 0.8
	var board := StandardMaterial3D.new()
	board.albedo_color = Color(0.07, 0.07, 0.08)
	board.roughness = 0.9
	_box("Backboard", Vector3(0.0, LIFT - 0.40, -0.06), Vector3(2.30, 1.55, 0.02), board, false)
	_box("PostL", Vector3(-1.05, (LIFT - 1.175) * 0.5, -0.06), Vector3(0.05, LIFT - 1.175, 0.05), dark, false)
	_box("PostR", Vector3(1.05, (LIFT - 1.175) * 0.5, -0.06), Vector3(0.05, LIFT - 1.175, 0.05), dark, false)
	# ── the bench: a solid support the walker meets ──
	_box("Bench", Vector3(0.20, BENCH_H * 0.5, BENCH_Z), Vector3(BENCH_W, BENCH_H, BENCH_D), dark, true)
	# ── the console: the shipped ControlPanel, standing at the bench's right end ──
	var panel: Node3D = get_node_or_null("ControlPanel")
	if panel != null:
		panel.position = Vector3(1.36, 1.17, 0.62)
		panel.rotation = Vector3(deg_to_rad(-20.0), 0.0, 0.0)
		var back := MeshInstance3D.new()
		back.name = "ConsoleBack"
		var bb := BoxMesh.new()
		bb.size = Vector3(0.50, 0.66, 0.02)
		back.mesh = bb
		back.material_override = dark
		back.position = Vector3(-0.05, 0.02, -0.012)
		panel.add_child(back)
	_build_panel()
	_build_readout()
	_build_marker()
	_update_readout()

func _box(box_name: String, at: Vector3, size: Vector3, mat: Material, solid: bool) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = box_name
	node.position = at
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	node.add_child(mi)
	if solid:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		node.add_child(col)
	_staging_root.add_child(node)
	return node

## BASELINE restores the arrival coefficients; H1 ALONE keeps the first harmonic and
## zeroes the rest; HOLD stops the scroll (and starts it again).
func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	_panel = RackTpl.create_panel("SUM", [
		[{"type": "button", "label": "BASELINE"}, {"type": "button", "label": "H1 ALONE"}, {"type": "button", "label": "HOLD"}],
	])
	_panel.name = "Panel"
	# the panel's button areas are hand targets, not the installation's footprint
	_panel.set_meta("em_local_instrument", true)
	# on the bench's front half, tilted up toward the visitor
	_panel.position = Vector3(-0.80, BENCH_H + 0.055, BENCH_Z + 0.12)
	_panel.rotation = Vector3(deg_to_rad(-60.0), 0.0, 0.0)
	_staging_root.add_child(_panel)
	var actions := {"Btn_0": func(): restore_baseline(), "Btn_1": func(): first_alone(), "Btn_2": func(): toggle_hold()}
	for btn_name in actions.keys():
		var btn: Node = _panel.find_child(btn_name, true, false)
		if btn == null:
			continue
		var area: Node = btn.get_node_or_null("InteractableAreaButton")
		if area != null and area.has_signal("button_pressed"):
			var action: Callable = actions[btn_name]
			area.button_pressed.connect(func(_b): action.call())

## Five lines on a dark plate on the bench: the coefficients, the arrival coefficients,
## each row's value at the marker, the sum of the drawn rows against the drawn total,
## and what differs from the arrival.
func _build_readout() -> void:
	_readout_case = Node3D.new()
	_readout_case.name = "ReadoutCase"
	_readout_case.set_meta("em_local_instrument", true)
	_readout_case.position = Vector3(0.15, BENCH_H + 0.06, BENCH_Z + 0.12)
	_readout_case.rotation = Vector3(deg_to_rad(-60.0), 0.0, 0.0)
	_staging_root.add_child(_readout_case)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.13, 0.14)
	mat.roughness = 0.75
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var box := BoxMesh.new()
	box.size = Vector3(0.78, 0.21, 0.02)
	plate.mesh = box
	plate.material_override = mat
	_readout_case.add_child(plate)
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.pixel_size = 0.0015
	_readout.font_size = 18
	_readout.outline_size = 0
	_readout.modulate = Color(0.85, 0.95, 1.0)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout.position = Vector3(-0.37, 0.0, 0.012)
	_readout_case.add_child(_readout)

## A thin amber line across the sum and the ladder at one place, so "here" can be read
## on every row and on the total at once.
func _build_marker() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.30)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker = MeshInstance3D.new()
	_marker.name = "Marker"
	var box := BoxMesh.new()
	box.size = Vector3(0.004, 1.55, 0.003)
	_marker.mesh = box
	_marker.material_override = mat
	_marker.position = Vector3(mark_x(), LIFT - 0.42, 0.125)
	_staging_root.add_child(_marker)
	var tag := Label3D.new()
	tag.name = "MarkerTag"
	tag.text = "mark"
	tag.pixel_size = 0.0015
	tag.font_size = 16
	tag.outline_size = 0
	tag.modulate = Color(1.0, 0.75, 0.30)
	tag.position = Vector3(mark_x(), LIFT + 0.37, 0.125)
	_staging_root.add_child(tag)

func _teardown_bench() -> void:
	if is_instance_valid(_staging_root):
		_staging_root.queue_free()
	_staging_root = null
	_panel = null
	_readout_case = null
	_readout = null
	_marker = null
	held = false
	if wave_mesh:
		wave_mesh.position.y = 0.0
	if component_meshes:
		component_meshes.position.y = 0.0
	if formula_label:
		formula_label.position.y = 0.6
	if preset_label:
		preset_label.position.y = 0.45
	var title: Node3D = get_node_or_null("TitleLabel")
	if title != null:
		title.position.y = 0.8
	var base: Node3D = get_node_or_null("Base")
	if base != null:
		base.position = Vector3(0.0, -0.4, 0.0)
	var expl: Node3D = get_node_or_null("ExplanationLabel")
	if expl != null:
		expl.position = Vector3(0.0, -1.05, 0.0)
	var panel: Node3D = get_node_or_null("ControlPanel")
	if panel != null:
		panel.position = Vector3(0.7, 0.1, 0.3)
		panel.rotation = Vector3.ZERO
		var back: Node = panel.get_node_or_null("ConsoleBack")
		if back != null:
			back.queue_free()

# ── the readout's arithmetic (the same lines the meshes are drawn from) ──

## The marker's sample index and its x on the display.
func mark_index() -> int:
	return int(round(MARK_T * float(WAVE_POINTS - 1)))

func mark_x() -> float:
	return (float(mark_index()) / float(WAVE_POINTS - 1) - 0.5) * WAVE_LENGTH

## The phase the draw loops use at sample i, at the present _time.
func phase_at(i: int) -> float:
	var t: float = float(i) / float(WAVE_POINTS - 1)
	return t * TAU * 4.0 + _time * TAU

## What the display holds at sample i: each row's value (the drawn rows only, as the
## ladder shows them), their sum, and the total the sum mesh was drawn from.
func display_values(i: int) -> Dictionary:
	var phase: float = phase_at(i)
	var rows: Array = []
	var drawn_sum: float = 0.0
	for h in range(NUM_HARMONICS):
		var v: float = harmonic_amplitudes[h] * sin(phase * (h + 1))
		var drawn: bool = harmonic_amplitudes[h] >= 0.01
		rows.append({"value": v, "drawn": drawn})
		if drawn:
			drawn_sum += v
	return {"index": i, "phase": phase, "rows": rows, "sum_of_drawn_rows": drawn_sum, "total": _calculate_wave_value(phase)}

static func _fmt_amps(a: Array) -> String:
	var parts: Array[String] = []
	for v in a:
		parts.append("%.2f" % float(v))
	return " ".join(parts)

## Which coefficients differ from the arrival, in the readout's words: "a2 0.50→0.00".
func differences_from_baseline() -> Array[String]:
	var out: Array[String] = []
	for h in range(mini(_baseline.size(), harmonic_amplitudes.size())):
		if absf(harmonic_amplitudes[h] - _baseline[h]) > 0.005:
			out.append("a%d %.2f→%.2f" % [h + 1, _baseline[h], harmonic_amplitudes[h]])
	return out

func _update_readout() -> void:
	if _readout == null:
		return
	var dv: Dictionary = display_values(mark_index())
	var parts: Array[String] = []
	for r in dv["rows"]:
		parts.append(("%+.2f" % float(r["value"])) if bool(r["drawn"]) else "  ·  ")
	var s: float = float(dv["sum_of_drawn_rows"])
	var tot: float = float(dv["total"])
	var diffs: Array[String] = differences_from_baseline()
	var dline: String = "differs: none"
	if not diffs.is_empty():
		var shown: Array[String] = diffs.slice(0, 2)
		dline = "differs: " + ", ".join(shown) + (" +%d more" % (diffs.size() - 2) if diffs.size() > 2 else "")
	_readout.text = "a     %s\nbase  %s\nmark  %s\nsum %+.2f %s total %+.2f · %s\n%s" % [
		_fmt_amps(harmonic_amplitudes), _fmt_amps(_baseline), "  ".join(parts),
		s, "=" if absf(s - tot) < 0.005 else "≠", tot, "held" if held else "running", dline]

# ── the panel's actions ──

## The arrival coefficients, back on every slider.
func restore_baseline() -> void:
	_set_amplitudes(_baseline)
	waveform_changed.emit(harmonic_amplitudes)

## The first harmonic by itself (as it is; 1.0 if it was down), the rest at zero.
func first_alone() -> void:
	var a1: float = harmonic_amplitudes[0] if harmonic_amplitudes[0] >= 0.01 else 1.0
	_set_amplitudes([a1, 0.0, 0.0, 0.0, 0.0])
	waveform_changed.emit(harmonic_amplitudes)

func set_held(on: bool) -> void:
	held = on
	_dirty = true

func toggle_hold() -> void:
	set_held(not held)

func get_baseline() -> Array[float]:
	return _baseline.duplicate()

## For probes and reviews: the staging, the coefficients, the arrival five, the values
## at the marker and what differs.
func get_synthesis_state() -> Dictionary:
	return {"stand": stand, "lift": LIFT if stand == "bench" else 0.0, "waveform": waveform, "components": components,
		"amplitudes": harmonic_amplitudes.duplicate(), "baseline": _baseline.duplicate(), "held": held,
		"mark_index": mark_index(), "mark_x": mark_x(), "at_mark": display_values(mark_index()),
		"differences": differences_from_baseline(), "preset": preset_label.text if preset_label else "",
		"formula": formula_label.text if formula_label else ""}
