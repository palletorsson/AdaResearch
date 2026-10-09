# distribution_sampler.gd
# Interactive probability distribution visualizer
# Shows Gaussian, Uniform, Poisson, Exponential distributions
#
# QFEP: Distributions as "shape of randomness" — entropy has structure
#
# @identity
# essence: f(x|θ) — probability density function parameterized by distribution type
# desire: switch between Uniform, Gaussian, Poisson, Exponential and watch falling particles build different shapes
# critical_parameter: law — which PDF governs the draw, each with fundamentally different tail behavior (uniform | gaussian | poisson | exponential); evidence — how many draws the histogram is standing on when you find it (none | anecdote | sample | census)
# triggers: _sample_distribution() dispatches to Box-Muller (Gaussian), inverse CDF (Exponential), Knuth (Poisson)
# emerges: the theoretical PDF curve overlays the histogram and they converge — shape is not noise, noise has shape
# needs: VR push buttons for distribution switching [has]; falling-particle animation [has]; slider for params [missing]
# relationships: depends on galton_board (Gaussian intuition); contrasts with slot_machine (discrete uniform vs continuous families)
# truth: Every distribution is a constraint on randomness — the shape of what remains possible.
#
## Implements an interactive probability distribution sampler.
## Draws samples from Uniform, Gaussian (Box-Muller transform), Poisson
## (inverse transform), or Exponential (inverse CDF) distributions and
## displays them as a falling-particle histogram with theoretical PDF overlay.
## Key parameters: distribution selects the active type, samples_per_second
## controls animation speed, num_bins sets histogram resolution.

extends Node3D

class_name DistributionSampler

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# --- Constants ---
const AXIS_RADIUS := 0.002
const BAR_DEPTH := 0.02
const BAR_HEIGHT_MIN := 0.01
const BAR_FILL_RATIO := 0.9
const CURVE_SEGMENTS := 100
const FALL_SPEED := 0.5
const MARKER_RADIUS := 0.008
const SAMPLE_SPAWN_OFFSET := 0.05
const TIMER_WRAP := 1000.0


## Width of the histogram display area in meters
@export_range(0.1, 2.0, 0.05) var display_width: float = 0.6
## Height of the histogram display area in meters
@export_range(0.1, 2.0, 0.05) var display_height: float = 0.4
## Number of histogram bins
@export_range(2, 200) var num_bins: int = 30
## Maximum number of samples before auto-sampling stops
@export_range(10, 10000) var max_samples: int = 1000

## Distribution type
enum DistType { UNIFORM, GAUSSIAN, POISSON, EXPONENTIAL }
## Which probability distribution to sample from
@export var distribution: DistType = DistType.GAUSSIAN:
	set(value):
		distribution = value
		_clear_samples()

## Mean of the Gaussian distribution (normalized 0–1 range)
@export_range(0.0, 1.0, 0.01) var gaussian_mean: float = 0.5
## Standard deviation of the Gaussian distribution
@export_range(0.01, 0.5, 0.01) var gaussian_std: float = 0.15

## Lambda parameter for the Poisson distribution
@export_range(0.1, 20.0, 0.1) var poisson_lambda: float = 5.0

## Rate parameter for the Exponential distribution
@export_range(0.1, 20.0, 0.1) var exponential_rate: float = 3.0

## Number of random samples generated per second
@export_range(1.0, 200.0, 1.0) var samples_per_second: float = 50.0:
	set(value):
		samples_per_second = clampf(value, 1.0, 200.0)

## Whether to continuously generate samples automatically
@export var auto_sample: bool = true

## Seed for the sampler. -1 (the default) draws from the global stream exactly as
## before — same calls, same order, byte-identical histogram behaviour.
##
## NOT AN AXIS, AND DELIBERATELY SO. This instrument builds its whole picture out of
## unseeded draws while it runs, which means two captures of it are two different
## histograms even with every knob identical: any axis declared here would be measured
## against sampling noise and would report whatever the dice said. Set this
## non-negative and CLEAR (or a config change) replays the same sample sequence, so a
## future axis on this artifact can be measured rather than guessed at.
##
## THAT FUTURE ARRIVED 2026-08-03 and took the other road: `evidence` below lays its
## draws down from its OWN seeded generator (`evidence_seed`), which leaves this knob
## and the live stream exactly as they were. sample_seed is still not an axis.
@export var sample_seed: int = -1
var _rng: RandomNumberGenerator = null

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA — promoted by hand 2026-08-03
#
# The note above is why this artifact was passed over twice. It is right that an
# unseeded stream cannot be measured, and it is right that the histogram builds
# over TIME — at 50 samples/second, a still taken 0.35 s after _ready catches a
# machine with an empty chart and a handful of markers still in the air. So the
# first knob this needed was not an axis at all.
#
#   law         WHICH RULE GOVERNS THE DRAW
#               uniform · gaussian · poisson · exponential
#   evidence    HOW MANY DRAWS THE HISTOGRAM STANDS ON WHEN YOU FIND IT
#               none · anecdote · sample · census
#
# `law` is the @identity critical_parameter — "f(x|θ), each with fundamentally
# different tail behaviour" — made reachable from a map token. The word is
# shared with force_field_visualizer, which asks the same question of a field
# (which law shapes what you are looking at); in probability the LAW of a random
# variable is literally its distribution, so the word is not a metaphor here.
# The four values are the four the code has always dispatched on.
#
# `evidence` is what makes `law` photographable, and it is the same ladder, word
# for word, as galton_board and shannon_workbench: how much looking the picture
# is standing on. As with those two, the rungs are qualitative and the counts
# are this machine's own.
#   none       0. The legacy lineage: bins empty, only the theory curve drawn.
#              Every one of the 10 placements is here.
#   anecdote   1. One bin at full height. A distribution "shown" by one draw.
#   sample     25. Scattered single-count bars across 30 bins — the shape is
#              not yet legible and the bars claim it is.
#   census     1000. max_samples. The histogram closes on the curve drawn over
#              it, which is the whole argument of the artifact.
#
# The pre-seeded draws run through the SAME _sample_distribution() the live
# machine uses, in the same order — they are earlier draws, not different ones.
# They come from a private generator seeded by `evidence_seed`, so at
# evidence=none no RNG is constructed and the global stream is never touched:
# frame one of an unconfigured placement is byte-identical to yesterday's.
#
# Deliberately NOT promoted: samples_per_second (a rate is invisible to a still
# — the exact fault this artifact was already declining), auto_sample (same),
# and gaussian_mean / gaussian_std / poisson_lambda / exponential_rate, which
# are the operating knobs of ONE law rather than a choice between laws.
# ─────────────────────────────────────────────────────────────────────────────

## AXIS 1 — which law governs the draw. "gaussian" is the shipped default, and
## at that value nothing is assigned: the export default below already IS
## DistType.GAUSSIAN, so a scene or map that set `distribution` directly keeps
## whatever it set.
@export_enum("uniform", "gaussian", "poisson", "exponential") var law: String = "gaussian"
## AXIS 2 — how many draws the histogram stands on when you find it. Shared
## vocabulary with galton_board and shannon_workbench. none = the legacy state:
## an empty chart waiting for the sampler to fill it.
@export_enum("none", "anecdote", "sample", "census") var evidence: String = "none"
## Seed for the pre-seeded draws only, so a variant photographs the same
## histogram twice. Off the default path entirely: at evidence=none nothing
## reads it and no generator is built.
@export var evidence_seed: int = 20260803

## THE CABINET (waves / randomness / noise, R3, 2026-09-11) — an opt-in staging for a body.
## The shipped sampler is authored at bench scale and stands on the deck: its histogram at
## the knees and its keypad eight centimetres BELOW the floor. `#stand:cabinet` builds a
## cabinet under it, lifts the display to standing height, carries the keypad and a second
## panel — BATCH (a hundred draws landed at once), PAUSE / RUN, NEW SEED, BINS (10 · 30 · 60,
## the same draws re-binned) — on a shoulder at hand height, houses a six-line readout under
## the histogram (the law and its formula; landed, in flight and the cap; clipped draws and the
## counts in the two edge bins; bins, mean, deviation; the seed and what CLEAR does with it;
## the cadence), and draws the EXPECTED count of every bin at the present N as a ghost behind
## the bars, the mass the law puts beyond the display folded into the edge bins — so a bounded
## display cannot impersonate an unbounded distribution (R7). Under the cabinet the sampler
## runs a NAMED five-digit seed, so CLEAR replays the same draws and a change of law sends the
## same stream through another transform (R1). `stand:none` (the default) builds nothing of
## this and leaves the stream alone.
##
##   "distribution_sampler:180#stand:cabinet"           the cabinet, its own seed
##   "distribution_sampler:180#stand:cabinet#seed:777"  the cabinet, a pinned seed
@export_enum("none", "cabinet") var stand: String = "none"
## Draws BATCH lands at once, without the rain.
@export var batch_size: int = 100

## The axis words, mapped onto the enum the rest of the file already uses.
const LAW_TYPES := {
	"uniform": DistType.UNIFORM,
	"gaussian": DistType.GAUSSIAN,     # the legacy lineage
	"poisson": DistType.POISSON,
	"exponential": DistType.EXPONENTIAL,
}
## The evidence ladder, as draws already made.
const EVIDENCE_DRAWS := {
	"none": 0,          # the legacy lineage — 10 placements, all of them
	"anecdote": 1,
	"sample": 25,
	"census": 1000,     # = max_samples
}
## Set for the duration of _seed_evidence() and null everywhere else, so the
## pre-seeded draws are deterministic without the live machine's stream — or the
## global stream — changing at all.
var _evidence_rng: RandomNumberGenerator = null

## Color of the histogram bars
@export var color_bar: Color = Color(0.3, 0.7, 1.0)
## Color of the theoretical PDF curve overlay
@export var color_theory: Color = Color(1.0, 0.5, 0.3, 0.6)
## Color of the falling sample markers
@export var color_sample: Color = Color(1.0, 0.9, 0.3)

# State
var _bins: Array[int] = []
var _total_samples: int = 0
var _sample_timer: float = 0.0
var _falling_samples: Array[Dictionary] = []

# Bars — rendered as MultiMesh
var _bar_mm: MultiMesh
var _bar_mmi: MultiMeshInstance3D
var _bar_x_positions: PackedFloat32Array

# Theory curve — reused ImmediateMesh
var _theory_curve: MeshInstance3D
var _im: ImmediateMesh
var _theory_mat: StandardMaterial3D

# Sample markers — shared mesh and material
var _sample_markers: Node3D
var _sample_sphere: SphereMesh
var _sample_mat: StandardMaterial3D

# Labels and controls
var _info_label: Label3D
var _stats_label: Label3D
var _stats_plate: Node3D
var _headline: Label3D   # the law, N, bins and the clipped count, large, over the six lines (12 September)
var _control_panel: Node3D

# Shared materials
var _panel_mat: StandardMaterial3D
var _axis_mat: StandardMaterial3D

# Signal tracking for cleanup
var _signal_connections: Array = []

# Bookkeeping every path pays for (an append and a compare per draw): the landed values,
# so a change of bins can re-bin the SAME draws, and the draws the clamp folded onto an edge.
var _values: PackedFloat32Array = PackedFloat32Array()
var _drawn: int = 0
var _clipped: int = 0

# THE CABINET (stand:cabinet only). Nothing here is created on the default path.
const CAB_W: float = 1.60
const CAB_D: float = 0.40
const CAB_H: float = 0.95            # the cabinet top: the display stands on it
const CAB_FACE: float = 0.16         # the front face (local +z); the display's back panel is at -0.01
const SHOULDER_Y: float = 0.70
const BIN_CHOICES: PackedInt32Array = [10, 30, 60]
var _stand_root: Node3D
var _stand_panel: Node3D
var _readout: Label3D
var _ghost_mm: MultiMesh
var _ghost_mmi: MultiMeshInstance3D
var _readout_accum: float = 0.0
var _built: bool = false

func _ready() -> void:
	_read_meta_overrides()
	# "gaussian" is the export default of `distribution`, so this is a genuine
	# no-op at the default value — nothing is assigned and anything the .tscn or
	# a map already set survives untouched.
	if law != "gaussian":
		distribution = int(LAW_TYPES.get(law, DistType.GAUSSIAN)) as DistType
	_init_shared_resources()
	_create_display()
	_create_bars()
	_create_theory_curve()
	_create_sample_markers()
	_create_labels()
	_create_vr_controls()
	_clear_samples()
	_seed_evidence()
	_built = true
	_apply_stand()

## Initialize reusable mesh and material resources.
func _init_shared_resources() -> void:
	_panel_mat = StandardMaterial3D.new()
	_panel_mat.albedo_color = Color(0.05, 0.05, 0.08)

	_axis_mat = StandardMaterial3D.new()
	_axis_mat.albedo_color = Color(0.4, 0.4, 0.5)

	_sample_sphere = SphereMesh.new()
	_sample_sphere.radius = MARKER_RADIUS
	_sample_sphere.height = MARKER_RADIUS * 2.0

	_sample_mat = StandardMaterial3D.new()
	_sample_mat.albedo_color = color_sample
	_sample_mat.emission_enabled = true
	_sample_mat.emission = color_sample
	_sample_mat.emission_energy_multiplier = 0.5

	_theory_mat = StandardMaterial3D.new()
	_theory_mat.albedo_color = color_theory
	_theory_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_im = ImmediateMesh.new()

## Build the back panel and axis lines.
func _create_display() -> void:
	var back := MeshInstance3D.new()
	back.name = "BackPanel"
	var box := BoxMesh.new()
	box.size = Vector3(display_width + 0.04, display_height + 0.04, 0.01)
	back.mesh = box
	back.material_override = _panel_mat
	back.position = Vector3(0, display_height / 2, -0.01)
	add_child(back)

	_create_axis_line(Vector3(-display_width / 2, 0, 0), Vector3(display_width / 2, 0, 0))
	_create_axis_line(Vector3(-display_width / 2, 0, 0), Vector3(-display_width / 2, display_height, 0))

## Create a cylinder-based axis line between two 3D points.
func _create_axis_line(start: Vector3, end: Vector3) -> void:
	var line := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = AXIS_RADIUS
	cylinder.bottom_radius = AXIS_RADIUS
	cylinder.height = (end - start).length()
	line.mesh = cylinder
	line.material_override = _axis_mat

	line.position = (start + end) / 2
	var direction := end - start

	add_child(line)

	if direction.length() > 0.001:
		var up := Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		line.look_at(line.global_position + direction, up)
		line.rotate_object_local(Vector3.RIGHT, PI / 2)

## Create histogram bars as a MultiMesh for efficient GPU instancing.
func _create_bars() -> void:
	var bar_width := display_width / float(num_bins)

	var box := BoxMesh.new()
	box.size = Vector3(bar_width * BAR_FILL_RATIO, BAR_HEIGHT_MIN, BAR_DEPTH)

	_bar_mm = MultiMesh.new()
	_bar_mm.transform_format = MultiMesh.TRANSFORM_3D
	_bar_mm.mesh = box
	_bar_mm.instance_count = num_bins

	_bar_x_positions = PackedFloat32Array()
	_bar_x_positions.resize(num_bins)

	for i in range(num_bins):
		var x := -display_width / 2 + (i + 0.5) * bar_width
		_bar_x_positions[i] = x
		var xf := Transform3D()
		xf.origin = Vector3(x, 0, 0)
		_bar_mm.set_instance_transform(i, xf)

	_bar_mmi = MultiMeshInstance3D.new()
	_bar_mmi.name = "Bars"
	_bar_mmi.multimesh = _bar_mm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_bar
	mat.emission_enabled = true
	mat.emission = color_bar
	mat.emission_energy_multiplier = 0.2
	_bar_mmi.material_override = mat

	add_child(_bar_mmi)

## Create the theory curve mesh node with a reusable ImmediateMesh.
func _create_theory_curve() -> void:
	_theory_curve = MeshInstance3D.new()
	_theory_curve.name = "TheoryCurve"
	_theory_curve.mesh = _im
	_theory_curve.material_override = _theory_mat
	add_child(_theory_curve)

## Create the container node for falling sample markers.
func _create_sample_markers() -> void:
	_sample_markers = Node3D.new()
	_sample_markers.name = "SampleMarkers"
	add_child(_sample_markers)

## Create title and statistics labels.
func _create_labels() -> void:
	# Title — a framed 2D-in-3D sign on a STALK above the screen (mounted to the body, not floating).
	var title := HangarKit.signage("DISTRIBUTION SAMPLER", [], Vector2(display_width * 0.64, 0.11), 0.13, Vector3(0, 1, 0))
	title.position = Vector3(0, display_height, 0)
	add_child(title)

	# Stats — an empty framed plate on a side BRACKET; the live value text sits on its face
	# (2D-on-surface, fixed orientation), updated every frame by _update_stats().
	var arm := 0.12
	var sx := display_width / 2 + 0.05
	var sy := display_height / 2
	var stats_plate := HangarKit.signage("", [], Vector2(0.34, 0.3), arm, Vector3(1, 0, 0))
	stats_plate.position = Vector3(sx, sy, 0)
	add_child(stats_plate)
	_stats_plate = stats_plate
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.pixel_size = 0.0011
	_stats_label.font_size = 12
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_stats_label.modulate = Color(0.09, 0.09, 0.11)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.position = Vector3(sx + arm, sy + 0.02, 0.05)
	add_child(_stats_label)

## Create VR-interactive buttons for switching distributions and clearing data.
func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("DISTRIBUTIONS", [
		[{"type": "button", "label": "UNIFORM"}, {"type": "button", "label": "GAUSS"}, {"type": "button", "label": "POISSON"}, {"type": "button", "label": "EXPON"}],
		[{"type": "button", "label": "CLEAR"}],
	])
	_control_panel.position = Vector3(0, -0.08, 0.15)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	for i in range(4):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				var type_idx := i
				var cb := func(_b): distribution = type_idx as DistType
				area.button_pressed.connect(cb)
				_signal_connections.append([area, &"button_pressed", cb])

	var clear_btn: Node = _control_panel.find_child("Btn_4", true, false)
	if clear_btn:
		var area = clear_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _clear_samples())
			_signal_connections.append([area, &"button_pressed", _clear_samples])

## Reset all bins, samples, and visuals to initial state.
func _clear_samples(_button = null) -> void:
	# Re-seeded here so CLEAR replays the same sample sequence. At sample_seed = -1
	# this is skipped entirely and the global stream is untouched — the legacy path.
	if sample_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = sample_seed
	_bins.clear()
	_bins.resize(num_bins)
	for i in range(num_bins):
		_bins[i] = 0
	_total_samples = 0
	_sample_timer = 0.0
	_falling_samples.clear()
	_values = PackedFloat32Array()
	_drawn = 0
	_clipped = 0
	if _bar_mm:
		_update_bars()
	if _im:
		_update_theory_curve()
	_update_readout()

func _process(delta: float) -> void:
	if auto_sample and _total_samples < max_samples:
		_sample_timer = wrapf(_sample_timer + delta, 0.0, TIMER_WRAP)
		var interval := 1.0 / samples_per_second
		while _sample_timer >= interval and _total_samples < max_samples:
			_sample_timer -= interval
			_add_sample()

	_update_falling_samples(delta)
	_update_stats()
	if _readout != null:
		_readout_accum += delta
		if _readout_accum >= 0.1:
			_readout_accum = 0.0
			_update_readout()

## Draw a single sample from the current distribution and spawn a falling marker.
func _add_sample() -> void:
	var value := _sample_distribution()

	var x := -display_width / 2 + value * display_width
	_falling_samples.append({
		"x": x,
		"y": display_height + SAMPLE_SPAWN_OFFSET,
		"value": value,
		"landed": false
	})

	var marker := MeshInstance3D.new()
	marker.mesh = _sample_sphere
	marker.material_override = _sample_mat
	marker.position = Vector3(x, display_height + SAMPLE_SPAWN_OFFSET, 0.02)
	_sample_markers.add_child(marker)

## Sample a value in [0, 1] from the currently selected distribution. The raw value of each
## law is computed first and then folded into [0, 1] by `_fit`, which counts the folds.
func _sample_distribution() -> float:
	_drawn += 1
	match distribution:
		DistType.UNIFORM:
			return _rand()

		DistType.GAUSSIAN:
			var u1 := _rand()
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1 + 0.0001)) * cos(TAU * u2)
			return _fit(gaussian_mean + z * gaussian_std)

		DistType.POISSON:
			var L := exp(-poisson_lambda)
			var k := 0
			var p := 1.0
			while p > L:
				k += 1
				p *= _rand()
			return _fit(float(k - 1) / maxf(poisson_lambda * 3, 0.0001))

		DistType.EXPONENTIAL:
			var u := _rand()
			var val := -log(u + 0.0001) / maxf(exponential_rate, 0.0001)
			return _fit(val / 2.0)

	return _rand()


## The clamp the display has always applied, counted: a raw value outside [0, 1] lands on the
## edge it crossed, and the readout says how many did.
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)


## The only draw in this artifact. sample_seed = -1 falls straight through to randf(),
## same call, same order, same stream, so the legacy histogram is unchanged.
func _rand() -> float:
	# The pre-seeded history, when one is being laid down. Null at every other
	# moment, including the whole of the default path.
	if _evidence_rng != null:
		return _evidence_rng.randf()
	if sample_seed < 0:
		return randf()
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = sample_seed
	return _rng.randf()

## Animate falling markers downward and register them into histogram bins on landing.
func _update_falling_samples(delta: float) -> void:
	var to_remove: Array[int] = []

	for i in range(_falling_samples.size()):
		var sample = _falling_samples[i]
		if sample.landed:
			to_remove.append(i)
			continue

		sample.y -= delta * FALL_SPEED

		var bin_idx := int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
		var bin_height := float(_bins[bin_idx]) / maxf(float(max_samples), 1.0) * display_height * 5

		if sample.y <= bin_height:
			sample.landed = true
			_bins[bin_idx] += 1
			_total_samples += 1
			_values.append(sample.value)
			_update_bars()

	var markers := _sample_markers.get_children()
	for i in range(mini(_falling_samples.size(), markers.size())):
		markers[i].position.y = _falling_samples[i].y

	for i in range(to_remove.size() - 1, -1, -1):
		var idx := to_remove[i]
		_falling_samples.remove_at(idx)
		if idx < _sample_markers.get_child_count():
			_sample_markers.get_child(idx).queue_free()

## Update histogram bar transforms via MultiMesh based on current bin counts.
func _update_bars() -> void:
	var max_count := 1
	for count in _bins:
		max_count = maxi(max_count, count)

	for i in range(num_bins):
		var height := float(_bins[i]) / float(max_count) * display_height * BAR_FILL_RATIO + BAR_HEIGHT_MIN
		var xf := Transform3D()
		xf.basis = Basis.IDENTITY.scaled(Vector3(1.0, height / BAR_HEIGHT_MIN, 1.0))
		xf.origin = Vector3(_bar_x_positions[i], height / 2.0, 0.0)
		_bar_mm.set_instance_transform(i, xf)
	if _ghost_mm != null:
		_update_ghosts(max_count)

## Rebuild the theoretical PDF curve on the reusable ImmediateMesh.
func _update_theory_curve() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(CURVE_SEGMENTS + 1):
		var x_norm := float(i) / float(CURVE_SEGMENTS)
		var y := _theoretical_pdf(x_norm)
		var x := -display_width / 2 + x_norm * display_width
		_im.surface_add_vertex(Vector3(x, y * display_height * 0.8, 0.01))

	_im.surface_end()

## Return the theoretical PDF value for the current distribution at normalized x.
func _theoretical_pdf(x: float) -> float:
	match distribution:
		DistType.UNIFORM:
			return 1.0

		DistType.GAUSSIAN:
			var z := (x - gaussian_mean) / maxf(gaussian_std, 0.0001)
			return exp(-0.5 * z * z) / (maxf(gaussian_std, 0.0001) * sqrt(TAU))

		DistType.POISSON:
			var k := int(x * poisson_lambda * 3)
			var factorial := 1.0
			for i in range(1, k + 1):
				factorial *= i
			return pow(poisson_lambda, k) * exp(-poisson_lambda) / maxf(factorial, 0.0001) * 3

		DistType.EXPONENTIAL:
			var t := x * 2
			return exponential_rate * exp(-exponential_rate * t) * 2

	return 0.0

## Update statistics label with sample mean, standard deviation, and count.
func _update_stats() -> void:
	if _total_samples == 0:
		_stats_label.text = "n = 0"
		return

	var sum := 0.0
	var sum_sq := 0.0
	var bar_width := 1.0 / float(num_bins)

	for i in range(num_bins):
		var x := (i + 0.5) * bar_width
		sum += x * _bins[i]
		sum_sq += x * x * _bins[i]

	var mean := sum / _total_samples
	var variance := sum_sq / _total_samples - mean * mean
	var std := sqrt(maxf(variance, 0))

	var dist_names = ["Uniform", "Gaussian", "Poisson", "Exponential"]
	_stats_label.text = "%s\nn = %d\nμ = %.3f\nσ = %.3f" % [dist_names[distribution], _total_samples, mean, std]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: distribution = DistType.UNIFORM
			KEY_2: distribution = DistType.GAUSSIAN
			KEY_3: distribution = DistType.POISSON
			KEY_4: distribution = DistType.EXPONENTIAL
			KEY_SPACE: auto_sample = not auto_sample
			KEY_C: _clear_samples()
			KEY_S: _add_sample()

func _exit_tree() -> void:
	for conn in _signal_connections:
		if is_instance_valid(conn[0]) and conn[0].is_connected(conn[1], conn[2]):
			conn[0].disconnect(conn[1], conn[2])
	_signal_connections.clear()

## Set the active probability distribution.
func set_distribution(d: DistType) -> void:
	distribution = d

## Clear all samples and reset the histogram.
func clear() -> void:
	_clear_samples()

## Draw a single sample from the current distribution.
func sample() -> void:
	_add_sample()

# ═════════════════════════════════════════════════════════════════════
# DNA — law and evidence
# ═════════════════════════════════════════════════════════════════════

## Lay down the draws this machine is found standing on. Returns before building
## anything at evidence=none, which is the state every existing placement is in.
func _seed_evidence() -> void:
	var draws: int = mini(int(EVIDENCE_DRAWS.get(evidence, 0)), max_samples)
	if draws <= 0:
		return
	_evidence_rng = RandomNumberGenerator.new()
	_evidence_rng.seed = evidence_seed
	for _i in draws:
		var value: float = _sample_distribution()
		var bin_idx: int = clampi(int(value * num_bins), 0, num_bins - 1)
		_bins[bin_idx] += 1
		_total_samples += 1
		_values.append(value)
	_evidence_rng = null
	_update_bars()


## Validate an axis value against the code's own list. An unknown word keeps the
## current value rather than silently building something nobody asked for.
func _axis_value(raw: String, allowed: Array, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return v if allowed.has(v) else fallback


## Map tokens arrive as `config_*` metadata BEFORE the node enters the tree
## (GridInteractablesComponent sets the metas, then add_child), so reading them
## here means _ready builds the asked-for variant in one pass.
func _read_meta_overrides() -> void:
	if has_meta("config_law"):
		law = _axis_value(str(get_meta("config_law")), LAW_TYPES.keys(), law)
	if has_meta("config_evidence"):
		evidence = _axis_value(str(get_meta("config_evidence")),
			EVIDENCE_DRAWS.keys(), evidence)
	if has_meta("config_evidence_seed"):
		evidence_seed = int(str(get_meta("config_evidence_seed")))


## GUARDED. The grid calls this deferred, AFTER _ready has built the body, so a
## rebuild here must be earned: nothing is cleared unless a value this artifact
## owns actually differs from what it already built with.
func apply_grid_config(config_data: Dictionary) -> void:
	# Parsed through str() first: a fixture that passes "7" rather than 7 would be
	# rejected outright by set() on a typed int and the seed would silently not apply.
	if config_data.has("sample_seed"):
		sample_seed = int(str(config_data["sample_seed"]))
		_clear_samples()
	elif config_data.has("seed"):
		# the programme's shared key (#seed:N is whitelisted as a value)
		sample_seed = int(str(config_data["seed"]))
		_clear_samples()
	if config_data.has("batch"):
		batch_size = maxi(1, int(str(config_data["batch"])))
	if config_data.has("stand"):
		var sv: String = str(config_data["stand"]).strip_edges().to_lower()
		stand = "cabinet" if sv in ["cabinet", "case", "desk", "bench", "stand"] else "none"
		# The museum hands a token's config to apply_grid_config BEFORE _ready (the value is
		# stored and _ready honours it); the grid hands it after, to a built body.
		if _built:
			_apply_stand()

	var want_law: String = law
	var want_evidence: String = evidence
	var want_seed: int = evidence_seed
	if config_data.has("law"):
		want_law = _axis_value(str(config_data["law"]), LAW_TYPES.keys(), law)
	if config_data.has("evidence"):
		want_evidence = _axis_value(str(config_data["evidence"]),
			EVIDENCE_DRAWS.keys(), evidence)
	if config_data.has("evidence_seed"):
		want_seed = int(str(config_data["evidence_seed"]))

	if want_law == law and want_evidence == evidence and want_seed == evidence_seed:
		return

	var law_changed: bool = want_law != law
	law = want_law
	evidence = want_evidence
	evidence_seed = want_seed
	# Only when the law itself moved — otherwise a map that changes `evidence`
	# alone would silently overwrite a `distribution` the scene had set.
	# The setter clears the histogram and redraws the theory curve, which is
	# exactly what a change of law should do.
	if law_changed:
		distribution = int(LAW_TYPES.get(law, distribution)) as DistType
	# Before _ready has run there is nothing built to re-seed; _ready will.
	if _bar_mm == null:
		return
	_clear_samples()
	_seed_evidence()


# ═════════════════════════════════════════════════════════════════════
# THE CABINET — the staging (stand:cabinet), its readout, its ghosts, its buttons
# ═════════════════════════════════════════════════════════════════════

func _apply_stand() -> void:
	if stand == "cabinet":
		if sample_seed < 0:
			# a NAMED seed a visitor can read and repeat — from a private generator, never
			# the global stream (R6); CLEAR re-seeds before the histogram is emptied
			var r := RandomNumberGenerator.new()
			r.randomize()
			sample_seed = r.randi_range(10000, 99999)
			_rng = null
			_clear_samples()
		if _stand_root == null:
			_build_cabinet()
		_update_readout()
	elif _stand_root != null:
		_lift_shipped(-CAB_H)
		_stand_root.get_parent().remove_child(_stand_root)
		_stand_root.queue_free()
		_stand_root = null
		_stand_panel = null
		_readout = null
		_ghost_mm = null
		_ghost_mmi = null


## Every shipped child up onto the cabinet top (or back down), the keypad onto the shoulder.
func _lift_shipped(dy: float) -> void:
	for c in get_children():
		if c == _stand_root or not (c is Node3D):
			continue
		if c == _control_panel:
			continue
		(c as Node3D).position.y += dy
	if _control_panel != null:
		if dy > 0.0:
			_control_panel.position = Vector3(-0.55, SHOULDER_Y + 0.055, CAB_FACE + 0.076)
			_control_panel.rotation_degrees = Vector3(-32, 0, 0)
		else:
			_control_panel.position = Vector3(0, -0.08, 0.15)
			_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	# under the cabinet the shipped side plate (n, μ, σ from bin centres, at font 12 on a
	# bracket) says less than the housed readout's fourth line and was "hard to decipher"
	# from the operating view (Astra's visual review, 12 September): it goes dark there
	if _stats_plate != null:
		_stats_plate.visible = dy <= 0.0
	if _stats_label != null:
		_stats_label.visible = dy <= 0.0


func _build_cabinet() -> void:
	var pal: Dictionary = HangarKit.finish_palette("terminal")
	var col_body: Color = pal["body"]
	var shell: StandardMaterial3D = HangarKit.finish_body("terminal", col_body, 0.10)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var accent: StandardMaterial3D = HangarKit.emissive(pal["accent"], 2.2)
	_stand_root = Node3D.new()
	_stand_root.name = "Cabinet"
	_stand_root.set_meta("housing", true)
	add_child(_stand_root)
	# the body: one solid the walker meets, a hand rests on
	var body := StaticBody3D.new()
	body.name = "Body"
	_stand_root.add_child(body)
	var box: MeshInstance3D = HangarKit.box(Vector3(0, CAB_H * 0.5, CAB_FACE - CAB_D * 0.5), Vector3(CAB_W, CAB_H, CAB_D), shell)
	box.name = "Shell"
	body.add_child(box)
	var cap: MeshInstance3D = HangarKit.box(Vector3(0, CAB_H - 0.018, CAB_FACE - CAB_D * 0.5), Vector3(CAB_W + 0.045, 0.036, CAB_D + 0.045), steel)
	cap.name = "Cap"
	body.add_child(cap)
	body.add_child(HangarKit.box(Vector3(0, CAB_H - 0.046, CAB_FACE + 0.006), Vector3(CAB_W * 0.98, 0.007, 0.006), accent))
	var col := CollisionShape3D.new()
	col.name = "Collider"
	var shape := BoxShape3D.new()
	shape.size = Vector3(CAB_W + 0.045, CAB_H, CAB_D + 0.045)
	col.shape = shape
	col.position = Vector3(0, CAB_H * 0.5, CAB_FACE - CAB_D * 0.5)
	body.add_child(col)
	var sign: MeshInstance3D = HangarKit.stencil("DISTRIBUTION SAMPLER", Vector2(0.72, 0.030), (pal["accent"] as Color).lightened(0.35))
	if sign:
		sign.position = Vector3(0, 0.30, CAB_FACE + 0.004)
		_stand_root.add_child(sign)
	# the shoulder: a wedge across the front carrying the keypad and the second panel
	var shoulder: MeshInstance3D = HangarKit.wedge(CAB_W * 0.92, 0.11, 0.15, 0.05, steel)
	if shoulder:
		shoulder.position = Vector3(0.0, SHOULDER_Y, CAB_FACE - 0.002)
		_stand_root.add_child(shoulder)
	# the shipped nodes up; the keypad onto the shoulder
	_lift_shipped(CAB_H)
	# the readout: under the histogram, on the front face, leaning back so a standing eye reads it
	var plate_root := Node3D.new()
	plate_root.name = "Readout"
	plate_root.set_meta("em_local_instrument", true)
	plate_root.position = Vector3(0, CAB_H - 0.118, CAB_FACE + 0.012)   # its top edge under the cap's lip
	plate_root.rotation_degrees = Vector3(-12, 0, 0)
	_stand_root.add_child(plate_root)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.8
	var plate: MeshInstance3D = HangarKit.box(Vector3.ZERO, Vector3(0.62, 0.150, 0.014), dark)
	plate.name = "Plate"
	plate_root.add_child(plate)
	# the headline: the law, the landed N, the bins and the clipped count at a size the
	# operating view reads; the six lines follow, smaller (12 September: "prioritise law,
	# landed N, bins and edge clipping at readable size")
	_headline = Label3D.new()
	_headline.name = "Headline"
	_headline.pixel_size = 0.00095
	_headline.font_size = 21
	_headline.outline_size = 0
	_headline.modulate = Color(0.95, 0.97, 1.0)
	_headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_headline.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_headline.position = Vector3(-0.29, 0.068, 0.010)
	plate_root.add_child(_headline)
	_readout = Label3D.new()
	_readout.name = "Text"
	_readout.pixel_size = 0.00095
	_readout.font_size = 11
	_readout.outline_size = 0
	_readout.line_spacing = 0.3
	_readout.modulate = Color(0.80, 0.90, 0.98)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_readout.position = Vector3(-0.29, 0.040, 0.010)
	plate_root.add_child(_readout)
	# the second panel: BATCH · PAUSE / NEW SEED · BINS, beside the keypad on the shoulder
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl != null:
		_stand_panel = RackTpl.create_panel("", [
			[{"type": "button", "label": "BATCH"}, {"type": "button", "label": "PAUSE"}],
			[{"type": "button", "label": "NEW SEED"}, {"type": "button", "label": "BINS"}],
		], true)
		_stand_panel.name = "StandPanel"
		_stand_panel.set_meta("em_local_instrument", true)
		_stand_panel.position = Vector3(0.55, SHOULDER_Y + 0.055, CAB_FACE + 0.076)
		_stand_panel.rotation_degrees = Vector3(-32, 0, 0)
		_stand_root.add_child(_stand_panel)
		var actions := {"Btn_0": func(): batch(batch_size), "Btn_1": func(): set_running(not auto_sample), "Btn_2": func(): new_seed(), "Btn_3": func(): cycle_bins()}
		for btn_name in actions.keys():
			var btn: Node = _stand_panel.find_child(btn_name, true, false)
			if btn == null:
				continue
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area != null and area.has_signal("button_pressed"):
				var action: Callable = actions[btn_name]
				area.button_pressed.connect(func(_b): action.call())
	_build_ghosts()


## The expected count of every bin at the present N, as pale frames behind the bars.
func _build_ghosts() -> void:
	if _ghost_mmi != null and is_instance_valid(_ghost_mmi):
		remove_child(_ghost_mmi)
		_ghost_mmi.queue_free()
	var bar_width := display_width / float(num_bins)
	var box := BoxMesh.new()
	box.size = Vector3(bar_width * BAR_FILL_RATIO + 0.004, BAR_HEIGHT_MIN, BAR_DEPTH * 0.5)
	_ghost_mm = MultiMesh.new()
	_ghost_mm.transform_format = MultiMesh.TRANSFORM_3D
	_ghost_mm.mesh = box
	_ghost_mm.instance_count = num_bins
	_ghost_mmi = MultiMeshInstance3D.new()
	_ghost_mmi.name = "Ghosts"
	_ghost_mmi.multimesh = _ghost_mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.86, 0.55, 0.42)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mmi.material_override = mat
	_ghost_mmi.position = Vector3(0, CAB_H, -0.006)
	add_child(_ghost_mmi)
	_update_bars()


func _update_ghosts(max_count: int) -> void:
	var exp_counts: Array[float] = expected_counts()
	for i in range(num_bins):
		var e: float = exp_counts[i] if i < exp_counts.size() else 0.0
		var height: float = e / float(maxi(max_count, 1)) * display_height * BAR_FILL_RATIO + BAR_HEIGHT_MIN
		var xf := Transform3D()
		xf.basis = Basis.IDENTITY.scaled(Vector3(1.0, height / BAR_HEIGHT_MIN, 1.0))
		xf.origin = Vector3(_bar_x_positions[i], height / 2.0, 0.0)
		_ghost_mm.set_instance_transform(i, xf)


## Φ, the standard normal's distribution function (Abramowitz–Stegun 7.1.26, |error| < 1.5e-7).
static func normal_cdf(x: float) -> float:
	var t: float = 1.0 / (1.0 + 0.3275911 * absf(x) / sqrt(2.0))
	var y: float = 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * exp(-x * x / 2.0)
	return 0.5 * (1.0 + y) if x >= 0.0 else 0.5 * (1.0 - y)


## The probability the present law puts in each bin of the display — with the mass the clamp
## folds onto the edges counted in the first and last bin — so the ghosts and the bars are the
## same kind of thing: counts at this N. Sums to 1.
func bin_probabilities() -> Array[float]:
	var out: Array[float] = []
	out.resize(num_bins)
	for i in range(num_bins):
		var lo: float = float(i) / float(num_bins)
		var hi: float = float(i + 1) / float(num_bins)
		var p: float = 0.0
		match distribution:
			DistType.UNIFORM:
				p = 1.0 / float(num_bins)
			DistType.GAUSSIAN:
				var sd: float = maxf(gaussian_std, 0.0001)
				var a: float = 0.0 if i == 0 else normal_cdf((lo - gaussian_mean) / sd)
				var b: float = 1.0 if i == num_bins - 1 else normal_cdf((hi - gaussian_mean) / sd)
				p = b - a
			DistType.POISSON:
				# the draw is X / (3λ), X ~ Poisson(λ); X at or past 3λ lands on the last bin
				var scale: float = maxf(poisson_lambda * 3.0, 0.0001)
				var pk: float = exp(-poisson_lambda)
				var k: int = 0
				while k < 200:
					var v: float = float(k) / scale
					var j: int = clampi(int(v * num_bins), 0, num_bins - 1)
					if v >= 1.0:
						j = num_bins - 1
					if j == i:
						p += pk
					if pk < 1e-12 and k > poisson_lambda:
						break
					k += 1
					pk *= poisson_lambda / float(k)
			DistType.EXPONENTIAL:
				# the draw is t / 2 with t ~ Exp(rate); t past 2 lands on the last bin
				var r: float = maxf(exponential_rate, 0.0001)
				var a: float = exp(-r * 2.0 * lo)
				var b: float = 0.0 if i == num_bins - 1 else exp(-r * 2.0 * hi)
				p = a - b
		out[i] = p
	return out


func expected_counts() -> Array[float]:
	var probs: Array[float] = bin_probabilities()
	var out: Array[float] = []
	out.resize(num_bins)
	for i in range(num_bins):
		out[i] = probs[i] * float(_total_samples)
	return out


## Land `n` draws at once, without the rain: the same _sample_distribution, binned directly.
func batch(n: int) -> void:
	var count: int = mini(n, max_samples - _total_samples)
	for _i in range(count):
		var value: float = _sample_distribution()
		var bin_idx: int = clampi(int(value * num_bins), 0, num_bins - 1)
		_bins[bin_idx] += 1
		_total_samples += 1
		_values.append(value)
	if count > 0:
		_update_bars()
	_update_readout()


func set_running(on: bool) -> void:
	auto_sample = on
	_update_readout()


## Another named seed from a private generator; the histogram restarts under it.
func new_seed() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	var next: int = r.randi_range(10000, 99999)
	while next == sample_seed:
		next = r.randi_range(10000, 99999)
	set_sample_seed(next)


## A seed by hand; -1 returns to the global stream. CLEAR follows.
func set_sample_seed(value: int) -> void:
	sample_seed = value
	_rng = null
	_clear_samples()


## The same landed draws in another number of bins: nothing is redrawn, only re-binned.
## The bars are rebuilt for the new count; the falling markers land into the new bins.
func set_bins(n: int) -> void:
	n = clampi(n, 2, 200)
	if n == num_bins:
		return
	num_bins = n
	_bins.clear()
	_bins.resize(num_bins)
	for i in range(num_bins):
		_bins[i] = 0
	for v in _values:
		_bins[clampi(int(v * num_bins), 0, num_bins - 1)] += 1
	if _bar_mmi != null and is_instance_valid(_bar_mmi):
		var y: float = _bar_mmi.position.y
		remove_child(_bar_mmi)          # leaves the tree now; a queued node keeps its name for a frame
		_bar_mmi.queue_free()
		_create_bars()
		_bar_mmi.position.y = y
	if _ghost_mm != null:
		_build_ghosts()
	_update_bars()
	_update_readout()


func cycle_bins() -> void:
	var i: int = BIN_CHOICES.find(num_bins)
	set_bins(BIN_CHOICES[(i + 1) % BIN_CHOICES.size()] if i >= 0 else BIN_CHOICES[0])


func _law_line() -> String:
	match distribution:
		DistType.UNIFORM:
			return "UNIFORM · one draw, no transform"
		DistType.GAUSSIAN:
			return "GAUSS · μ %.2f σ %.2f · Box-Muller" % [gaussian_mean, gaussian_std]
		DistType.POISSON:
			return "POISSON · λ %.0f · X/(3λ)" % poisson_lambda
		_:
			return "EXPON · rate %.0f · t/2" % exponential_rate


## Beads still falling: a landed bead stays in the list until the next frame sweeps it.
func in_flight() -> int:
	var n: int = 0
	for smp in _falling_samples:
		if not smp.landed:
			n += 1
	return n


func readout_lines() -> Array[String]:
	var first: int = _bins[0] if _bins.size() > 0 else 0
	var last: int = _bins[num_bins - 1] if _bins.size() >= num_bins else 0
	var mean: float = 0.0
	var sd: float = 0.0
	if _total_samples > 0:
		var sum := 0.0
		var sum_sq := 0.0
		var bw := 1.0 / float(num_bins)
		for i in range(num_bins):
			var x := (i + 0.5) * bw
			sum += x * _bins[i]
			sum_sq += x * x * _bins[i]
		mean = sum / _total_samples
		sd = sqrt(maxf(sum_sq / _total_samples - mean * mean, 0.0))
	var seed_line: String = "seed %d · CLEAR replays it" % sample_seed if sample_seed >= 0 \
		else "seed: the global stream · CLEAR: new draws"
	var cadence: String = ("running · %d draws/s · BATCH lands %d" % [int(samples_per_second), batch_size]) if auto_sample \
		else "paused · BATCH lands %d" % batch_size
	return [_law_line(),
		"landed %d · in flight %d · cap %d" % [_total_samples, in_flight(), max_samples],
		"clipped %d of %d drawn · first bin %d · last %d" % [_clipped, _drawn, first, last],
		"bins %d · mean %.3f · σ %.3f (binned)" % [num_bins, mean, sd],
		seed_line, cadence]


func _update_readout() -> void:
	if _readout == null:
		return
	var lines: Array[String] = readout_lines()
	_readout.text = "\n".join(lines)
	if _headline != null:
		var first: int = _bins[0] if _bins.size() > 0 else 0
		var last: int = _bins[num_bins - 1] if _bins.size() >= num_bins else 0
		_headline.text = "%s · N %d · %d bins · clipped %d · edges %d|%d" % [str(lines[0]).get_slice(" ", 0), _total_samples, num_bins, _clipped, first, last]

func headline_text() -> String:
	return _headline.text if _headline != null else ""


func landed_values() -> PackedFloat32Array:
	return _values


func get_stand_state() -> Dictionary:
	return {"stand": stand, "law": int(distribution), "law_name": ["UNIFORM", "GAUSS", "POISSON", "EXPON"][int(distribution)],
		"landed": _total_samples, "in_flight": in_flight(), "drawn": _drawn, "clipped": _clipped, "bins": num_bins,
		"counts": Array(_bins), "seed": sample_seed, "replay": sample_seed >= 0, "running": auto_sample, "batch_size": batch_size,
		"max_samples": max_samples, "expected": expected_counts(), "lines": readout_lines(), "values": _values.size()}

