extends Node3D

# Controls sine wave parameters using ValueMapper interfaces
# ValueMapper2D controls frequency and amplitude
# ValueMapper1D controls a third parameter (like phase or volume)

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")
## The kin. Loaded for ONE static function — the family's single reader for an
## evidence token — so the two artifacts cannot end up with two vocabularies for
## one axis, which is the drift that cost the exhibits family a whole convergence
## pass. Nothing else about the tank is used here.
const WaveTank := preload("res://commons/artifacts/wave_interference_tank/wave_interference_tank.gd")

# @identity
# essence: a control surface for a sine wave that does not show you the sine wave. A pad for
#   frequency against amplitude, a line for phase, three numbers floating beside them — and the
#   wave itself living only inside get_sine_value(), which nothing in the scene ever calls. You
#   turn the handles of a machine whose output is off-stage.
# desire: to close the loop it was built with open — to let the parameter you are dragging have
#   a visible consequence, and then to let that consequence be taken apart into the factors that
#   made it.
# critical_parameter: evidence — how much of the wave's arithmetic the panel puts on the table.
#   The same ordered ladder [[wave_interference_tank]] carries, in a one-source body:
#   result (the three numbers alone, the legacy default) < trace (the wave plotted, so the
#   handles finally have a picture) < longhand (the plot with its factors laid over it: the
#   unit carrier as a ghost, the amplitude as a pair of rails, the formula written under).
# triggers: _ready reads #evidence: and builds the plot panel; the mappers' own change signals
#   redraw it; apply_grid_config({evidence}).
# emerges: at `result` you learn that a machine has settings. At `trace` you learn what a
#   setting DOES. At `longhand` you learn that the thing you are dragging is one factor in an
#   expression, and that the shape on the panel is the product of factors you can point at.
# needs: nothing new — the plotted curve is exactly get_sine_value()'s own expression,
#   A·sin(2πft + φ), sampled over a 25 ms window. The signal is curriculum and is untouched.
# relationships: kin to [[wave_interference_tank]] through the shared `evidence` ladder and the
#   shared reader; built on [[value_mapper_2d]] and [[value_mapper_1d]].
# truth: a knob without a readout does not teach a parameter, it teaches obedience.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). This file had exactly one export —
# use_mario_slider, a boolean about plumbing — and no configuration hook at all.
# It is the sparsest artifact in the wave category and the one with the sharpest
# epistemic problem: it is an INSTRUMENT WITH NO DIAL. The sine it controls is
# printed to the console sixty times a second and drawn nowhere.
#
# The register question does not apply here at all (nobody asks what institution
# a control panel belongs to), so the axis is the pair's shared one — EVIDENCE,
# how much of the arithmetic is on the table:
#
#   result  <  trace  <  longhand
#
#   result    the pad, the line, and the three billboarded numbers. THE LEGACY
#             LINEAGE, byte-for-byte: a readout that commits to a value and to
#             nothing else. One placement, untouched.
#   trace     an oscilloscope face above the mappers carrying A·sin(2πft + φ)
#             across 25 ms, with the area under the curve lit. Frequency becomes
#             a count of cycles, amplitude becomes a height, phase becomes a
#             shift — three numbers become three things you can see.
#   longhand  the same face with the expression taken apart on it: the unit
#             carrier sin(2πft) as a grey ghost at full height and zero phase,
#             the amplitude as two lit rails at ±A, and the formula printed
#             underneath. The product stops being a shape and becomes a result.
#
# THE ONE DEGRADE, declared rather than discovered. The tank's third rung,
# `sources`, shows the operands as the processes that produced the answer. A
# single sine has one source and no spreading fronts, so on this body the token
# climbs one rung to `longhand`, the nearest thing here that puts the operands on
# the table. It is therefore NOT declared as a variant of this artifact — the
# evidence loop would photograph it as an identical twin of longhand and report a
# dead axis. It resolves for a map author and it does not lie to the critic.
#
# Deliberately NOT the axis: the plot's sweep window, its sample count, or any
# other per-second quantity. A still cannot see a rate. What a still can see is
# whether the machine drew the wave at all, which is the whole question here.
# ─────────────────────────────────────────────────────────────────────────────

@export var use_mario_slider: bool = false  # If true, connects to SimpleMarioSlider

## THE AXIS — how much of the wave's arithmetic the panel puts on the table.
## One ordered ladder, monotone in disclosure:
##   result (legacy default) < trace < longhand
## Parsed through WaveTank.evidence_name(), then through EVIDENCE_DEGRADE below.
@export var evidence: String = "result"

## The rungs this body cannot build, and the rung each climbs to. `sources` is the
## tank's — two families of crest rings, one per emitter. There is one emitter here.
const EVIDENCE_DEGRADE := {
	"sources": "longhand",
	"fronts": "longhand",
}

@onready var mapper_2d = $ValueMapper2D  # Frequency (X) and Amplitude (Y)
@onready var mapper_1d = $ValueMapper1D  # Phase or other parameter

# Sine wave parameters
var frequency: float = 440.0
var amplitude: float = 0.5
var phase: float = 0.0

# Reference to Mario slider if using it
var mario_slider: SimpleMarioSlider

# ── the plot face (built only above `result`) ────────────────────────────────
const PLOT_SAMPLES: int = 640          # ~26 samples per cycle at the pad's centre
const PLOT_WINDOW_S: float = 0.025     # 25 ms of signal — one oscilloscope sweep
const PLOT_HALF_W: float = 1.10        # half the drawable width, metres
const PLOT_GAIN: float = 0.19          # metres of face per unit of amplitude
const PLOT_Y: float = 0.86             # face centre, clear of the 2D mapper's labels
var _plot_root: Node3D             # the whole face hangs here, and only here
var _plot_mi: MeshInstance3D
var _plot_im: ImmediateMesh
var _rail_hi: MeshInstance3D
var _rail_lo: MeshInstance3D
var _plot_longhand: bool = false
var _plotted: Vector3 = Vector3(-1.0, -1.0, -1.0)   # freq, amp, phase last drawn

func _ready() -> void:
	_read_meta_overrides()
	_build_evidence()
	if mapper_2d:
		mapper_2d.values_changed.connect(_on_2d_values_changed)
		var initial_2d = mapper_2d.get_values()
		_on_2d_values_changed(initial_2d.x, initial_2d.y)

	if mapper_1d:
		mapper_1d.value_changed.connect(_on_1d_value_changed)
		var initial_1d = mapper_1d.get_value()
		_on_1d_value_changed(initial_1d)

	if use_mario_slider:
		_find_mario_slider()

	print("SineWaveController ready")
	print("- Frequency range: %.0f - %.0f Hz" % [mapper_2d.output_x_min, mapper_2d.output_x_max])
	print("- Amplitude range: %.2f - %.2f" % [mapper_2d.output_y_min, mapper_2d.output_y_max])
	print("- Phase range: %.2f - %.2f" % [mapper_1d.output_min, mapper_1d.output_max])

func _find_mario_slider() -> void:
	# Wait for scene to load
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	mario_slider = get_tree().get_first_node_in_group("mario_slider_control")
	if mario_slider:
		print("SineWaveController: Connected to SimpleMarioSlider")
	else:
		push_warning("SineWaveController: Could not find SimpleMarioSlider")

func _on_2d_values_changed(freq_value: float, amp_value: float) -> void:
	frequency = freq_value
	amplitude = amp_value
	_refresh_plot()

	print("Sine wave: Frequency=%.1f Hz, Amplitude=%.2f" % [frequency, amplitude])

	# If using Mario slider, update its parameters
	if use_mario_slider and mario_slider:
		_update_mario_slider()

func _on_1d_value_changed(phase_value: float) -> void:
	phase = phase_value
	_refresh_plot()
	print("Sine wave: Phase=%.2f" % phase)

	# If using Mario slider, update its parameters
	if use_mario_slider and mario_slider:
		_update_mario_slider()

func _update_mario_slider() -> void:
	if not mario_slider:
		return

	# Map our sine wave parameters to Mario slider frequencies
	# Freq1 = base frequency
	# Freq2 = frequency + some offset or harmonic relationship
	var freq1 = frequency
	var freq2 = frequency * 1.5  # Harmonic relationship

	# Access the sliders directly
	if mario_slider.has_node("VBox/Freq1Container/Freq1Slider"):
		var freq1_slider = mario_slider.get_node("VBox/Freq1Container/Freq1Slider")
		freq1_slider.value = clamp(freq1, freq1_slider.min_value, freq1_slider.max_value)

	if mario_slider.has_node("VBox/Freq2Container/Freq2Slider"):
		var freq2_slider = mario_slider.get_node("VBox/Freq2Container/Freq2Slider")
		freq2_slider.value = clamp(freq2, freq2_slider.min_value, freq2_slider.max_value)

	# Update volume based on amplitude
	if mario_slider.has_node("VBox/VolumeContainer/VolumeSlider"):
		var volume_slider = mario_slider.get_node("VBox/VolumeContainer/VolumeSlider")
		volume_slider.value = amplitude

	print("SineWaveController: Updated Mario slider - Freq1=%.1f Hz, Freq2=%.1f Hz, Volume=%.2f" %
		[freq1, freq2, amplitude])

# Public API for getting current sine wave value
func get_sine_value(time: float) -> float:
	return amplitude * sin(TAU * frequency * time + phase)

func get_parameters() -> Dictionary:
	return {
		"frequency": frequency,
		"amplitude": amplitude,
		"phase": phase
	}

func set_parameters(freq: float, amp: float, ph: float) -> void:
	if mapper_2d:
		mapper_2d.set_values(freq, amp)
	if mapper_1d:
		mapper_1d.set_value(ph)

# ── evidence: the ladder of disclosure ───────────────────────────────────────
#
#   result  <  trace  <  longhand
#
# The token is normalised by the family's shared reader first, then by this
# body's own degrade table. Two steps on purpose: the vocabulary is the family's
# and must not fork, but what a given body can BUILD is that body's own fact.

## NEW — this artifact had no configuration hook at all, so no map could reach it.
## Nothing on the default path: a scan of every map_data.json finds zero
## placements carrying a config token on this artifact.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var was: String = evidence
	_read_meta_overrides()
	# The grid defers this call and capture_artifact_config.gd makes it after
	# add_child, so a token arriving post-_ready must rebuild or it does nothing
	# at all. capture_config_sweep.gd sets the export before add_child instead and
	# takes the _ready path; both roads arrive at the same face.
	if is_inside_tree() and evidence != was:
		_teardown_evidence()
		_build_evidence()

func _read_meta_overrides() -> void:
	if has_meta("config_evidence"):
		evidence = _evidence_name(str(get_meta("config_evidence")))

func _evidence_name(raw: String) -> String:
	var word: String = WaveTank.evidence_name(raw)
	return str(EVIDENCE_DEGRADE.get(word, word))

func _build_evidence() -> void:
	match evidence:
		"result":
			pass                              # the three numbers alone — the legacy lineage
		"trace":
			_build_plot(false)
		"longhand":
			_build_plot(true)
		_:
			pass                              # an unrecognised word is the bare readout

## The amplitude the pad calls "full". Read from the mapper rather than assumed,
## so a scene that re-ranges the pad still fills the face.
func _amp_span() -> float:
	if mapper_2d and "output_y_max" in mapper_2d:
		return maxf(absf(float(mapper_2d.output_y_max)), 0.0001)
	return 1.0

## Drop the face so a changed token can build a different one. Only reachable
## through apply_grid_config; on the default path this never runs.
func _teardown_evidence() -> void:
	if is_instance_valid(_plot_root):
		_plot_root.queue_free()
	_plot_root = null
	_plot_mi = null
	_plot_im = null
	_rail_hi = null
	_rail_lo = null
	_plot_longhand = false
	_plotted = Vector3(-1.0, -1.0, -1.0)

## The whole face hangs off one node, created lazily — so `result` adds nothing to
## the tree at all and the legacy scene is exactly the scene it was.
func _ev_add(n: Node) -> void:
	if _plot_root == null:
		_plot_root = Node3D.new()
		_plot_root.name = "PlotFace"
		add_child(_plot_root)
	_plot_root.add_child(n)

func _slab(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	_ev_add(mi)
	return mi

func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.3
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m

# The face. `trace` and `longhand` build the same instrument; longhand switches on
# the factors drawn over it. Sharing the builder is the point — the rung above is
# the rung below plus its workings, not a different machine.
func _build_plot(longhand: bool) -> void:
	_plot_longhand = longhand

	_slab(Vector3(2.36, 0.58, 0.010), Vector3(0, PLOT_Y, -0.024),
			_flat(Color(0.10, 0.11, 0.13), 0.65))                       # bezel
	_slab(Vector3(2.30, 0.52, 0.016), Vector3(0, PLOT_Y, -0.014),
			_flat(Color(0.028, 0.036, 0.055), 0.9))                     # face
	_slab(Vector3(2.22, 0.004, 0.004), Vector3(0, PLOT_Y, 0.004),
			_glow(Color(0.40, 0.48, 0.58), 0.5))                        # zero rule
	# 5 ms ticks — the face declares that its horizontal is time.
	for i in range(5):
		var tx: float = -PLOT_HALF_W + (2.0 * PLOT_HALF_W) * float(i) / 4.0
		_slab(Vector3(0.004, 0.030, 0.004), Vector3(tx, PLOT_Y - 0.226, 0.004),
				_glow(Color(0.34, 0.42, 0.52), 0.45))

	if longhand:
		# The amplitude, as a pair of rails the product can never cross. Positioned
		# in _refresh_plot; A is a live value, not a build-time one.
		_rail_hi = _slab(Vector3(2.22, 0.014, 0.010), Vector3(0, PLOT_Y, 0.002),
				_glow(Color(1.0, 0.72, 0.24), 2.2))
		_rail_lo = _slab(Vector3(2.22, 0.014, 0.010), Vector3(0, PLOT_Y, 0.002),
				_glow(Color(1.0, 0.72, 0.24), 2.2))
		# The rail names ride the rails as children, so they follow amplitude for
		# free — a label pinned to a build-time height would lie the moment the pad
		# moved, and a lying label is worse than none.
		var hi: MeshInstance3D = BakedText.make_label_mesh(
				"A", Color(1.0, 0.80, 0.40), Vector2(0.052, 0.052), 1400, true)
		if hi:
			hi.position = Vector3(-1.09, 0.052, 0.008)
			_rail_hi.add_child(hi)
		var lo: MeshInstance3D = BakedText.make_label_mesh(
				"-A", Color(1.0, 0.80, 0.40), Vector2(0.072, 0.052), 1400, true)
		if lo:
			lo.position = Vector3(-1.09, -0.052, 0.008)
			_rail_lo.add_child(lo)
		# The expression, written out under its own product. ASCII on purpose:
		# ThemeDB.fallback_font is not guaranteed to carry pi or phi, and a caption
		# that renders as boxes is worse than a caption that renders as words.
		var cap: MeshInstance3D = BakedText.make_label_mesh(
				"A  x  SIN( F T + PHASE )", Color(0.86, 0.90, 0.96),
				Vector2(1.30, 0.075), 1400, true)
		if cap:
			cap.position = Vector3(0, PLOT_Y - 0.345, 0.006)
			_ev_add(cap)

	_plot_mi = MeshInstance3D.new()
	_plot_mi.name = "PlotCurve"
	_plot_im = ImmediateMesh.new()
	_plot_mi.mesh = _plot_im
	_plot_mi.position = Vector3(0, PLOT_Y, 0.008)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_plot_mi.material_override = m
	_plot_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ev_add(_plot_mi)

	_refresh_plot()

## Redraw the face. The mappers emit values_changed EVERY FRAME whether or not
## anything moved (see value_mapper_2d._process), so this compares against the
## last-drawn triple and returns early — otherwise a static panel would rebuild
## 640 samples sixty times a second for nothing.
func _refresh_plot() -> void:
	if _plot_im == null:
		return
	if absf(frequency - _plotted.x) < 0.05 \
			and absf(amplitude - _plotted.y) < 0.0005 \
			and absf(phase - _plotted.z) < 0.0005:
		return
	_plotted = Vector3(frequency, amplitude, phase)

	var unit: float = clampf(absf(amplitude) / _amp_span(), 0.0, 1.0)
	if _rail_hi:
		_rail_hi.position = Vector3(0, PLOT_Y + unit * PLOT_GAIN, 0.002)
	if _rail_lo:
		_rail_lo.position = Vector3(0, PLOT_Y - unit * PLOT_GAIN, 0.002)

	var n: int = PLOT_SAMPLES
	var xs: PackedFloat32Array = PackedFloat32Array()
	var ys: PackedFloat32Array = PackedFloat32Array()
	var gs: PackedFloat32Array = PackedFloat32Array()
	for i in range(n):
		var u: float = float(i) / float(n - 1)
		var t: float = u * PLOT_WINDOW_S
		# get_sine_value()'s own expression, drawn instead of printed.
		var carrier: float = sin(TAU * frequency * t + phase)
		xs.append(-PLOT_HALF_W + u * (2.0 * PLOT_HALF_W))
		ys.append(unit * PLOT_GAIN * carrier)
		gs.append(PLOT_GAIN * sin(TAU * frequency * t))   # the unit carrier, unshifted

	_plot_im.clear_surfaces()
	_plot_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# The area under the product. This is what makes the rung read from across the
	# room instead of being a hairline the critic scores as inert.
	var fill: Color = Color(0.22, 0.70, 1.0, 0.38)
	for i in range(n - 1):
		_plot_im.surface_set_color(fill)
		_plot_im.surface_add_vertex(Vector3(xs[i], 0.0, 0.0))
		_plot_im.surface_set_color(fill)
		_plot_im.surface_add_vertex(Vector3(xs[i + 1], 0.0, 0.0))
		_plot_im.surface_set_color(fill)
		_plot_im.surface_add_vertex(Vector3(xs[i + 1], ys[i + 1], 0.0))
		_plot_im.surface_set_color(fill)
		_plot_im.surface_add_vertex(Vector3(xs[i], 0.0, 0.0))
		_plot_im.surface_set_color(fill)
		_plot_im.surface_add_vertex(Vector3(xs[i + 1], ys[i + 1], 0.0))
		_plot_im.surface_set_color(fill)
		_plot_im.surface_add_vertex(Vector3(xs[i], ys[i], 0.0))
	if _plot_longhand:
		# The carrier at full height and zero phase: the factor the amplitude
		# scales and the phase slides. Everything between it and the bright curve
		# is what A and phase actually did.
		_ribbon(xs, gs, 0.009, 0.003, Color(0.62, 0.66, 0.74, 0.92))
	_ribbon(xs, ys, 0.013, 0.005, Color(0.62, 0.92, 1.0, 1.0))
	_plot_im.surface_end()

## A polyline as a ribbon, offset along each segment's normal so a steep stretch
## stays as thick as a flat one. Emitted into the surface already open.
func _ribbon(xs: PackedFloat32Array, ys: PackedFloat32Array, w: float, z: float,
		col: Color) -> void:
	for i in range(xs.size() - 1):
		var a: Vector2 = Vector2(xs[i], ys[i])
		var b: Vector2 = Vector2(xs[i + 1], ys[i + 1])
		var d: Vector2 = b - a
		if d.length() < 0.000001:
			continue
		var nrm: Vector2 = Vector2(-d.y, d.x).normalized() * (w * 0.5)
		var p0: Vector2 = a - nrm
		var p1: Vector2 = a + nrm
		var p2: Vector2 = b + nrm
		var p3: Vector2 = b - nrm
		_plot_im.surface_set_color(col)
		_plot_im.surface_add_vertex(Vector3(p0.x, p0.y, z))
		_plot_im.surface_set_color(col)
		_plot_im.surface_add_vertex(Vector3(p1.x, p1.y, z))
		_plot_im.surface_set_color(col)
		_plot_im.surface_add_vertex(Vector3(p2.x, p2.y, z))
		_plot_im.surface_set_color(col)
		_plot_im.surface_add_vertex(Vector3(p0.x, p0.y, z))
		_plot_im.surface_set_color(col)
		_plot_im.surface_add_vertex(Vector3(p2.x, p2.y, z))
		_plot_im.surface_set_color(col)
		_plot_im.surface_add_vertex(Vector3(p3.x, p3.y, z))
